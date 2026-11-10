using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.VFS;
using Sedulous.Xml.Serialization;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Project;

/// One of the project's quality levels as the editor offers it: its id and its asset's path.
class ProjectQualityLevel
{
	public Guid Id;
	public String Name = new .() ~ delete _;
}

/// An opened project: the manifest, and the source and cooked content databases mounted
/// over its fixed layout.
///
/// The layout is the engine's (ProjectLayout), so the player and the editor cannot
/// disagree about where anything lives; what is here is the editor's and the tools' way
/// in: the manifest read, the generated directories recreated, the two databases scanned.
/// The cooker, the exporter and the headless MCP host open a project through this without
/// an editor around it.
///
/// The project's explicit "Always Export" set is a separate committed sidecar,
/// export_roots.xml, loaded on Open: absent is the empty set, the common case, and a present
/// but unreadable file leaves the set empty rather than blocking the open, so an export then
/// over includes, which is safe, never mis-prunes.
class EditorProject
{
	private String mDirectory = new .() ~ delete _;
	private ProjectSettings mSettings ~ delete _;
	private ExportRootsSet mExportRoots = new .() ~ delete _;
	private NativeFileSystem mContentMount ~ delete _;
	private NativeFileSystem mCookedMount ~ delete _;
	private SerializerFactory mSourceFactory ~ delete _;
	private SerializerFactory mCookedFactory ~ delete _;
	private ContentDatabase mSourceDb ~ delete _;
	private ContentDatabase mCookedDb ~ delete _;
	/// The cooked database over the sources, for the resources (ResourceDb).
	private LayeredContentDatabase mResourceDb ~ delete _;
	/// The paths written through the Content/ mount while a watcher listens (RecordContentWrites),
	/// from whichever thread wrote, until it takes them (TakeContentWrites). The project holds
	/// them, not the watcher: a write on a worker can land while the watcher goes, and the
	/// mount's hook must never reach a freed listener.
	private Monitor mContentWritesLock = new .() ~ delete _;
	private List<String> mContentWrites = new .() ~ DeleteContainerAndItems!(_);
	private bool mRecordContentWrites = false;

	/// Scaffolds a new project at `directory`, created when absent, its PARENT existing:
	/// the manifest and the fixed subdirectories (ProjectScaffold.Create). AlreadyExists when a
	/// manifest is there.
	public static Result<void, ErrorCode> Create(StringView directory, StringView name) => ProjectScaffold.Create(directory, name);

	/// Opens an existing project: reads the manifest, ensures the fixed subdirectories exist
	/// and mounts and scans both databases. Null when there is no readable manifest; a
	/// present but unreadable one is logged, since the caller's shell may only show a
	/// status line.
	public static EditorProject Open(StringView directory)
	{
		let root = scope NativeFileSystem(directory);
		let settings = new ProjectSettings();
		if (ProjectManifest.Load(root, settings) case .Err)
		{
			delete settings;
			if (root.Exists(ProjectLayout.ManifestFile))
				GlobalLog(.Error, scope $"Project: '{directory}/{ProjectLayout.ManifestFile}' exists but failed to parse (an old or corrupt format?); the project was not opened");
			return null;
		}
		// The generated directories may be missing on a fresh checkout, Cooked, Editor and
		// .cache being ignored by version control: recreated so mounts and state saves
		// always have a target.
		if (!ProjectScaffold.EnsureDirectories(directory))
		{
			delete settings;
			return null;
		}
		if (!settings.EngineVersion.IsEmpty && (settings.EngineVersion != EngineVersion.String))
		{
			// Informational today; a launcher routing projects to their engine version and
			// driving a migration is planned.
			GlobalLog(.Warning, scope $"Project: last saved by engine {settings.EngineVersion}, this is {EngineVersion.String}");
		}
		// Read from the manifest here: a copy of the settings carries no count (it is never
		// written).
		let msaaBeforeLevels = settings.MsaaSamplesBeforeLevels;
		let project = new EditorProject(directory, settings);
		if ((msaaBeforeLevels != 0) && settings.QualityLevelIds.IsEmpty)
			ProjectSeed.UpgradeToQualityLevels(project, msaaBeforeLevels);
		return project;
	}

	/// Use Create and Open. Takes the settings the manifest read produced.
	private this(StringView directory, ProjectSettings settings)
	{
		mDirectory.Set(directory);
		mSettings = settings;

		mContentMount = new NativeFileSystem(PathJoin(directory, ProjectLayout.ContentDir, .. scope .()));
		mContentMount.OnWritten = new (path) => NoteContentWrite(path);
		mCookedMount = new NativeFileSystem(PathJoin(directory, ProjectLayout.CookedDir, .. scope .()));
		mSourceFactory = XmlSerializerFactory();
		mCookedFactory = new (stream, mode) => new BinarySerializerContext(stream, mode);
		mSourceDb = new ContentDatabase(mContentMount, mSourceFactory, ProjectLayout.SourceAssetExtension);
		mCookedDb = new ContentDatabase(mCookedMount, mCookedFactory, ProjectLayout.CookedAssetExtension);
		mResourceDb = new LayeredContentDatabase(mCookedDb, mSourceDb);

		let root = scope NativeFileSystem(directory);
		ExportRootsFile.Load(root, mExportRoots).IgnoreError();
	}

	/// The "Always Export" roots; the export driver seeds from these.
	public ExportRootsSet ExportRoots => mExportRoots;

	/// Persists the export roots to <project>/export_roots.xml; the editor calls this after
	/// a right click "Always Export" toggle.
	public Result<void, ErrorCode> SaveExportRoots()
	{
		let root = scope NativeFileSystem(mDirectory);
		return ExportRootsFile.Save(root, mExportRoots);
	}

	public StringView Name => mSettings.Name;
	public StringView Directory => mDirectory;
	public ProjectSettings Settings => mSettings;

	/// What a file cannot hold in its name, on any platform the project is opened on.
	public const String cRefusedNameCharacters = "/\\:*?\"<>|";

	/// Why `name` cannot name an asset (empty, a character a file cannot hold, a space at an end,
	/// a dot at its end), appended to `outWhy`; nothing when it can. The one rule for a name a file
	/// takes.
	public static void AssetNameRefusal(StringView name, String outWhy)
	{
		if (name.IsEmpty)
		{
			outWhy.Append("Enter a name.");
			return;
		}
		for (let c in name)
		{
			if (cRefusedNameCharacters.Contains(c))
			{
				outWhy.AppendF("A name cannot hold {}.", c);
				return;
			}
		}
		if ((name[0] == ' ') || (name[name.Length - 1] == ' ') || (name[name.Length - 1] == '.'))
			outWhy.Append("A name cannot start or end with a space, or end with a dot.");
	}

	/// Renames the asset `id` within its group, its guid kept (everything binds by guid): the
	/// source instance, its cooked product's name, and the default scene's path mirror. True when
	/// it was renamed (or already had the name), else false with why not appended to `outWhy`: no
	/// such asset, a name the rule refuses, one taken in its group, or a failed write.
	public bool RenameAsset(Guid id, StringView name, String outWhy)
	{
		let instance = mSourceDb.GetInstance(id);
		if (instance == null)
		{
			outWhy.AppendF("no asset with guid {}", id);
			return false;
		}
		if (instance.Name == name)
			return true;
		let start = outWhy.Length;
		AssetNameRefusal(name, outWhy);
		if (outWhy.Length != start)
			return false;
		if (instance.OwningGroup.GetInstance(name) != null)
		{
			outWhy.AppendF("an asset named '{}' already exists in '{}'", name, instance.OwningGroup.GetPath(.. scope .()));
			return false;
		}
		let oldPath = instance.GetPath(.. scope .());
		if (mSourceDb.RenameInstance(id, name) case .Err(let error))
		{
			GlobalLog(.Warning, "Project: the rename of '{}' failed ({})", oldPath, error);
			outWhy.Append("the rename failed (the log says why)");
			return false;
		}
		// Its product keeps step; a product not cooked yet has none.
		mCookedDb.RenameInstance(id, name).IgnoreError();
		// The manifest's default scene is the guid; its path the readable mirror. The path's
		// compare covers a manifest with no guid, which then takes it.
		if ((mSettings.DefaultSceneId == id) || (mSettings.DefaultScene == oldPath))
		{
			mSettings.DefaultSceneId = id;
			instance.GetPath(mSettings.DefaultScene..Clear());
			SaveSettings().IgnoreError();
		}
		return true;
	}

	/// The quality levels the manifest lists, in its order, each named by its asset's path (by
	/// its id when the asset is gone), for the menus that offer them. Appends to `outLevels`;
	/// the caller owns what it appends.
	public void QualityLevels(List<ProjectQualityLevel> outLevels)
	{
		for (let id in mSettings.QualityLevelIds)
		{
			let level = new ProjectQualityLevel();
			level.Id = id;
			let instance = mSourceDb.GetInstance(id);
			if (instance != null)
				instance.GetPath(level.Name);
			else
				id.ToString(level.Name);
			outLevels.Add(level);
		}
	}

	/// The authored source database, XML envelopes: what the editor edits.
	public ContentDatabase SourceDb => mSourceDb;
	/// The cooked output database, binary envelopes: what the runtime loads.
	public ContentDatabase CookedDb => mCookedDb;
	/// What the editor's resources read: the cooked products first, and beneath them the
	/// sources, for the authored records the cook never builds (a prefab). It lives with the two
	/// databases it borrows. Nothing falls through until a resource manager gives it its
	/// predicate (LayeredContentDatabase.SetFallthrough), and whoever gives it clears it before
	/// that manager goes.
	public LayeredContentDatabase ResourceDb => mResourceDb;

	/// The Content/ mount the source database reads and writes through: what the Content/
	/// watcher sweeps.
	public NativeFileSystem ContentMount => mContentMount;

	/// Starts or stops keeping the paths written through the Content/ mount, for the watcher
	/// that must not take the editor's own writes for outside changes. Stopping drops what was
	/// kept; starting begins empty. Any thread.
	public void RecordContentWrites(bool record)
	{
		using (mContentWritesLock.Enter())
		{
			mRecordContentWrites = record;
			ClearAndDeleteItems!(mContentWrites);
		}
	}

	/// Moves the paths written since the last take into `outPaths`, the caller's to delete. Any
	/// thread.
	public void TakeContentWrites(List<String> outPaths)
	{
		using (mContentWritesLock.Enter())
		{
			outPaths.AddRange(mContentWrites);
			mContentWrites.Clear();
		}
	}

	private void NoteContentWrite(StringView path)
	{
		using (mContentWritesLock.Enter())
		{
			if (mRecordContentWrites)
				mContentWrites.Add(new String(path));
		}
	}

	/// Raw import sources, mounted as the build context's sources at cook time.
	public void SourcesRoot(String outPath) => PathJoin(mDirectory, ProjectLayout.SourcesDir, outPath);
	/// Per user editor state: the dock layout, the open pages.
	public void EditorStateRoot(String outPath) => PathJoin(mDirectory, ProjectLayout.EditorDir, outPath);
	/// The picture the project manager shows a project by (ProjectThumbnail.PathOf).
	public static void ThumbnailPath(StringView projectDirectory, String outPath) => ProjectThumbnail.PathOf(projectDirectory, outPath);

	/// Thumbnails and cook hashes.
	public void CacheRoot(String outPath) => PathJoin(mDirectory, ProjectLayout.CacheDir, outPath);

	/// Persists the manifest after the editor changed the settings.
	public Result<void, ErrorCode> SaveSettings()
	{
		let root = scope NativeFileSystem(mDirectory);
		return ProjectManifest.Save(root, mSettings);
	}
}
