using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Settings;
using Sedulous.Fonts.Resource;
using Sedulous.Runtime.Client;
using Sedulous.Pipeline.Core;
using Sedulous.Engine.DefaultApp;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.Mcp;

namespace Sedulous.Editor.App;

/// What an EditorSession works over. The services are borrowed for its life; the delegates are
/// its own.
class EditorSessionServices
{
	public EditorContext Context = null;
	public EditorCookService Cook = null;
	public EditorJobService Jobs = null;
	public BuilderRegistry Builders = null;
	public ThumbnailService Thumbnails = null;
	/// The per-user editor settings, saved after an open is recorded. Null: not saved.
	public Settings UserSettings = null;
	/// The user's project registry an open is recorded in. Null: not recorded.
	public ProjectManagerController Projects = null;
	/// The embedded runtime the project's resources attach to; both null until the application
	/// starts it (SetEmbedded), and a headless session runs without one.
	public IApplicationHost EmbeddedHost = null;
	public DefaultApplication EmbeddedApp = null;
	// Raptor's Services carries the runtime context and the EditorNativeModule here: Sedulous's
	// editor does not handle a project's native code (RaptorSync.md, "Standing differences").
	/// Seeds a new project's starter content (the executable composes it); null: none. Owned.
	public delegate void(EditorContext context, EditorProject project) SeedNewProject ~ delete _;
	/// The project opened, its services up: the application brings its views up (the MCP host,
	/// the pages, the layout). Owned.
	public delegate void(EditorProject project) OnOpened ~ delete _;
	/// The project is about to close, its services still up: the views go first, the pages and
	/// the layout captured into the store, which the close then saves. Owned.
	public delegate void() OnClosing ~ delete _;
	/// A cook finished (its summary on the cook service), the products reloaded and the game
	/// UI bound again: the views refresh, the user hears. Owned.
	public delegate void() OnCookFinished ~ delete _;
	/// The project's settings were saved, the game UI's defaults applied again: the views that
	/// show the settings refresh (the Project page). Owned.
	public delegate void() OnSettingsChanged ~ delete _;
}

/// What an Open may do besides open.
struct EditorSessionOpenOptions
{
	/// A folder with no project becomes one (the command line's fallback; the manager scaffolds
	/// only through its New Project flow).
	public bool Scaffold = false;
	public StringView ScaffoldName = "Untitled";
	/// Seed the starter content into a project this open created.
	public bool Seed = false;

	public this()
	{
	}
}

/// The project the editor has open, out of the application (Raptor's editor-gui spec, 5.1,
/// layer 3). Opening one (or, from the command line, scaffolding a bare folder into one) sets up
/// what lives as long as it does: the context's project, the per-project editor store (dock
/// layout, favourites, open pages), the resources over its cooked database attached to the
/// embedded runtime, the cook service and the hooks the context runs it through, the
/// thumbnails, and the game UI's defaults; it records the open in the user's project registry
/// and seeds a new project's starter content. Closing takes them down in the reverse order and
/// saves the store. What the views do at those moments (the pages, the layout, the MCP host)
/// goes through the hooks the application gives it.
///
/// The store's section types must be registered (EditorAppSerializables) before an open:
/// a section it cannot make aborts the load, and a later save would drop what was left out.
class EditorSession
{
	private EditorSessionServices mServices ~ delete _;
	private EditorProject mProject = null ~ delete _;
	private Settings mStore = null ~ delete _;
	private ResourceManager mResources = null ~ delete _;

	/// TAKES OWNERSHIP of the services.
	public this(EditorSessionServices services)
	{
		mServices = services;
	}

	/// The project closes with the session; the fields then have nothing left to free.
	public ~this()
	{
		Close();
	}

	/// Opens the project in `directory`, closing the one open first: false (said on the status
	/// line) when there is none there and none may be made.
	public bool Open(StringView directory, EditorSessionOpenOptions options = .())
	{
		let context = mServices.Context;
		if (directory.IsEmpty)
		{
			context.SetStatus("No project directory - pass one on the command line.");
			return false;
		}
		Close();
		bool seed = false;
		mProject = EditorProject.Open(directory);
		if ((mProject == null) && options.Scaffold)
		{
			if (EditorProject.Create(directory, options.ScaffoldName) case .Ok)
			{
				mProject = EditorProject.Open(directory);
				seed = (mProject != null) && options.Seed;
			}
		}
		if (mProject == null)
		{
			context.SetStatus(scope $"Failed to open project: {directory}");
			return false;
		}
		let project = mProject;
		context.SetProject(project);
		ConfigureThumbnails();
		{
			// What the open-time header scans cost (the parse volume decides the partial-parse work).
			let source = project.SourceDb.LastScanStats;
			let cooked = project.CookedDb.LastScanStats;
			GlobalLog(.Information, "Editor: project open scan: sources {} envelopes / {} KB parsed, cooked {} envelopes / {} KB parsed",
				source.Envelopes, source.BytesOpened / 1024, cooked.Envelopes, cooked.BytesOpened / 1024);
		}
		OpenProjectStore();
		AttachResources();
		// Raptor loads the project's native module here: not in Sedulous's editor (RaptorSync.md,
		// "Standing differences").
		let app = mServices.EmbeddedApp;
		if (app != null)
			app.SetContentDatabase(project.SourceDb); // scripted scene loads read the sources
		ApplyGameUiDefaults();
		if ((app != null) && (app.UI != null) && !project.Settings.DefaultUiFontId.IsSet && HasFontAssets(project.SourceDb.RootGroup))
		{
			// A project with fonts and no default renders no game-UI text: the fix is named.
			GlobalLog(.Warning, "UI: game UI has no default font, set Project Settings > Default UI font (the project has fonts, but none is the default, so game-UI text will not render)");
		}
		delete context.OnProjectSettingsChanged;
		context.OnProjectSettingsChanged = new () =>
			{
				ApplyGameUiDefaults();
				if (mServices.OnSettingsChanged != null)
					mServices.OnSettingsChanged();
			};
		StartCook();

		if (mServices.OnOpened != null)
			mServices.OnOpened(project);
		if (mServices.Projects != null)
		{
			// The open records in the per-user registry, most recent first.
			mServices.Projects.NoteOpened(directory, project.Name, project.Settings.EngineVersion);
			if (mServices.UserSettings != null)
				EditorSettingsStore.SaveToUserData(mServices.UserSettings).IgnoreError();
		}
		if (seed && (mServices.SeedNewProject != null))
		{
			// Once, before the first cook picks everything up; the assets view shows the new
			// rows when that cook finishes (its hook).
			mServices.SeedNewProject(context, project);
			project.SaveSettings().IgnoreError(); // the seed set the manifest's defaults
			mServices.Cook.RequestCook(false);
			context.SetStatus("Project created with starter content.");
		}
		// Sedulous's order: the project's line follows the starter content's, always.
		context.SetStatus(scope $"Project: {project.Name}  ({project.Directory})");
		return true;
	}

	/// Closes the project: the views first (the hook), then the cook, the thumbnails, the store
	/// saved, the resources, the store, the project last. Nothing when none is open.
	public void Close()
	{
		if (mProject == null)
			return;
		let context = mServices.Context;
		if (mServices.OnClosing != null)
			mServices.OnClosing();
		mServices.Cook.Shutdown(); // joins a cook in flight before the databases go
		DeleteAndNullify!(mServices.Cook.OnCookFinished); // it reaches this session
		mServices.Thumbnails.Reset(); // in-flight slots outlive harmlessly; the entries drop
		SaveStore(); // what the views captured into it, the layout and the open pages
		DeleteAndNullify!(context.OnCookRequested);
		DeleteAndNullify!(context.CookBusy);
		DeleteAndNullify!(context.OnFavoritesChanged);
		DeleteAndNullify!(context.OnProjectSettingsChanged);
		// Raptor unloads the project's native module here: not in Sedulous's editor.
		if (let app = mServices.EmbeddedApp)
		{
			// The resources detach before they go; the runtime's consumers are null-tolerant
			// between projects.
			app.AttachResourceManager(null, mServices.EmbeddedHost);
			app.SetContentDatabase(null); // the sources go with the project
			if (app.UI != null)
				app.UI.SetDefaultTheme(null);
		}
		context.Resources = null;
		DeleteAndNullify!(mResources);
		context.ProjectEditorSettings = null;
		DeleteAndNullify!(context.OnProjectEditorSettingsSaveRequested);
		DeleteAndNullify!(mStore);
		context.SetProject(null);
		DeleteAndNullify!(mProject);
		context.SetStatus("Project closed.");
	}

	/// The embedded runtime's host and application, once they are up (the application starts
	/// them after this is made).
	public void SetEmbedded(IApplicationHost host, DefaultApplication app)
	{
		mServices.EmbeddedHost = host;
		mServices.EmbeddedApp = app;
	}

	/// Null with no project.
	public EditorProject Project => mProject;
	/// The per-project editor store (dock layout, favourites, open pages); null with no project.
	public Settings Store => mStore;
	/// The resources over the project's cooked database; null with no project.
	public ResourceManager Resources => mResources;

	/// Writes the per-project store (the views capture the layout and the open pages into it
	/// first).
	public void SaveStore()
	{
		if ((mProject != null) && (mStore != null))
			ProjectEditorSettings.Save(mStore, mProject.EditorStateRoot(.. scope .())).IgnoreError();
	}

	/// Binds the project's default UI theme and fonts (the default and its others) onto the
	/// embedded app's game UI, and the fonts and the project's sheets onto its engine GUI.
	/// Idempotent: at project open, after every finished cook (a fresh checkout's first cook
	/// creates the products the open-time bind missed), and on settings save.
	public void ApplyGameUiDefaults()
	{
		let app = mServices.EmbeddedApp;
		if ((mProject == null) || (mResources == null) || (app == null))
			return;
		// Bound only once cooked: a new project's first open asks before its first cook has
		// made them, and a bind of a product that is not there warns of a broken reference.
		let cooked = mProject.CookedDb;
		bool Ready(Guid id) => id.IsSet && (cooked.GetInstance(id) != null);
		let themeId = mProject.Settings.DefaultUiThemeId;
		if (Ready(themeId) && (app.UI != null))
		{
			let theme = mResources.Bind<Sedulous.UI.Resource.UITheme>(themeId).Get;
			if (theme != null)
				app.UI.SetDefaultTheme(theme);
		}
		let fontId = mProject.Settings.DefaultUiFontId;
		Font defaultFont = null;
		if (Ready(fontId))
		{
			defaultFont = mResources.Bind<Font>(fontId).Get;
			if ((defaultFont != null) && (app.UI != null))
				app.UI.SetDefaultFont(defaultFont);
		}
		// The other UI fonts, each a family beside the default; always set, so one taken off the
		// list leaves the game UI too.
		let extras = scope List<Font>();
		for (let id in mProject.Settings.UiFontIds)
		{
			if (!Ready(id))
				continue;
			if (let font = mResources.Bind<Font>(id).Get)
				extras.Add(font);
		}
		if (app.UI != null)
			app.UI.SetExtraFonts(extras);
		// The engine GUI shares the fonts, and takes the project's sheets in order (a sheet not
		// cooked yet resolves once it is: the cook finished callback lands here again).
		if (app.Gui != null)
		{
			app.Gui.SetFonts(defaultFont, extras);
			app.Gui.SetStyleSheets(mProject.Settings.GuiStyleSheetIds);
		}
	}

	/// Does the source database hold any FontAsset, recursively? Answers "the project has fonts
	/// but none is the default", so the game UI can warn actionably.
	private static bool HasFontAssets(Group group)
	{
		if (group == null)
			return false;
		for (let instance in group.Instances)
		{
			if (instance.TypeName == "FontAsset")
				return true;
		}
		for (let child in group.Groups)
		{
			if (HasFontAssets(child))
				return true;
		}
		return false;
	}

	/// The thumbnail cache under the project's gitignored .cache.
	private void ConfigureThumbnails()
	{
		let thumbsDir = scope String();
		PathJoin(mProject.CacheRoot(.. scope .()), "thumbs", thumbsDir);
		CreateDirectory(thumbsDir);
		let project = mProject;
		let cook = mServices.Cook;
		mServices.Thumbnails.Configure(thumbsDir,
			new [=project](id) => project.SourceDb.GetInstance(id),
			mServices.Jobs,
			new [=cook](id) => cook.RecipeHashFor(id),
			mProject.SourcesRoot(.. scope .()));
	}

	/// The per-project store: absent on a fresh project, its sections then read as defaults.
	private void OpenProjectStore()
	{
		let context = mServices.Context;
		mStore = new Settings();
		if (ProjectEditorSettings.Load(mStore, mProject.EditorStateRoot(.. scope .())) case .Err(let error))
		{
			// NotFound is fine; anything else means the store loaded partially, since Settings
			// aborts at the first section it cannot make, and a later save would rewrite the
			// file from what is left, losing the layout, favourites or open pages.
			if (error != .NotFound)
				GlobalLog(.Error, "Editor: editor.project.settings.xml load FAILED (partial store), check for unregistered section types; later saves may drop sections");
		}
		context.ProjectEditorSettings = mStore;
		delete context.OnProjectEditorSettingsSaveRequested;
		context.OnProjectEditorSettingsSaveRequested = new () => { SaveStore(); };
		// The per-user pinned assets; the browser and picker surface them first.
		ProjectEditorSettings.ApplyFavorites(context, mStore);
		delete context.OnFavoritesChanged;
		context.OnFavoritesChanged = new () =>
			{
				if ((mProject != null) && (mStore != null))
				{
					ProjectEditorSettings.CaptureFavorites(mServices.Context, mStore);
					mServices.Context.RequestProjectEditorSettingsSave();
				}
			};
	}

	/// The project's resources over its cooked database, attached to the embedded runtime (which
	/// registers the engine's factories into it), decoding on the global job system when there
	/// is one, null meaning sync.
	private void AttachResources()
	{
		mResources = new ResourceManager(mProject.CookedDb, HasGlobalJobSystem() ? GlobalJobs() : null);
		mServices.Context.Resources = mResources;
		if (mServices.EmbeddedApp != null)
			mServices.EmbeddedApp.AttachResourceManager(mResources, mServices.EmbeddedHost);
	}

	/// The cook over the project, and how the context reaches it.
	private void StartCook()
	{
		let context = mServices.Context;
		let cook = mServices.Cook;
		let jobs = mServices.Jobs;
		let builders = mServices.Builders;
		cook.Initialize(mProject, builders);
		// Pages request re-cooks after saving builder-backed assets.
		delete context.OnCookRequested;
		context.OnCookRequested = new [=cook](rebuild) => { cook.RequestCook(rebuild); };
		// Cook-gated starts (play waits for the cook): anything in flight, or a request still
		// waiting to re-issue.
		delete context.CookBusy;
		context.CookBusy = new [=cook]() => cook.IsReady && !cook.IsIdle;
		delete context.SourceAssetTypesOf;
		context.SourceAssetTypesOf = new [=builders](product, outAssets) => SceneReference.SourceAssetTypesFor(builders, product, outAssets);
		// A background job (an export) reads the databases: mutations and new cooks wait, as
		// during a cook.
		delete cook.ExternalMutationLock;
		cook.ExternalMutationLock = new [=jobs]() => jobs.IsBusy;
		context.Jobs = jobs; // pages submit light work here
		delete cook.OnCookFinished;
		cook.OnCookFinished = new () => { CookFinished(); };
	}

	/// Rebuilt products swap in behind their handles (live scenes see them, no reopen), then the
	/// game UI binds again (a fresh checkout's first cook makes what the open-time bind missed;
	/// AFTER the reload, since the game UI borrows the font product itself).
	private void CookFinished()
	{
		mServices.Thumbnails.InvalidateAll(); // recipe hashes moved; unchanged ones load from disk
		if (mResources != null)
		{
			for (let product in mServices.Cook.LastCookedProducts)
				mResources.Reload(product);
		}
		ApplyGameUiDefaults();
		if (mServices.OnCookFinished != null)
			mServices.OnCookFinished();
	}
}
