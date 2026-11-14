using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Settings;
using Sedulous.Graphics;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.Shell;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Engine.Project;
using Sedulous.Render;
using Sedulous.VFS;
using Sedulous.Resource;
using Sedulous.Engine.Render;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Engine.GameInstance;
using Sedulous.Engine.DefaultApp;

namespace Sedulous.Editor.Play.Tests;

/// The Game tab from its markup (Data/Editor/Game.xml) on a headless host, no game running: the
/// kit's transport (Play while stopped; Pause and Stop while it runs or waits; the state named; a
/// Play waiting for the cook said so and cancelled by Stop), the resolutions in the dropdown, the
/// phone kept with the project, and the debugger beside the game in a split by its toggle, its share kept.
class GamePageTests
{
	/// A host with an empty context: no renderer, no window, no game.
	class BareHost : IApplicationHost
	{
		public SubsystemManager Subsystems { get; } = new .() ~ delete _;

		public IShell Shell => null;
		public GraphicsDevice Graphics => null;
		public RenderWindow MainRenderWindow => null;

		public RenderWindow OpenWindow(WindowSettings windowSettings, RenderWindowDesc renderDesc) => null;
		public void CloseWindow(RenderWindow window) {}
		public void RequestExit(int code = 0) {}
	}

	/// The data root, found up from the working directory.
	static bool DataRoot(String outPath)
	{
		var dir = GetCurrentDirectory(.. scope .());
		for (int i < 8)
		{
			let data = PathJoin(dir, "Data", .. scope .());
			if (DirectoryExists(PathJoin(data, "Editor", .. scope .())))
			{
				outPath.Set(data);
				return true;
			}
			let parent = PathParent(dir, .. scope .());
			if (parent == dir)
				break;
			dir.Set(parent);
		}
		return false;
	}

	/// Markup under the data root: a node with one reference, the caller's.
	static Node LoadMarkup(StringView relative)
	{
		let data = scope String();
		Test.Assert(DataRoot(data));
		let text = scope String();
		Test.Assert(System.IO.File.ReadAllText(PathJoin(data, relative, .. scope .()), text) case .Ok);
		RegisterGuiElements();
		RegisterToolkitElements();
		let elements = ElementSet.All();
		defer delete elements;
		let loader = scope MarkupLoader(elements);
		return loader.LoadFromString(text);
	}

	/// A scratch project in an editor context with a project editor store, and its Game tab.
	class Bed
	{
		public String Dir = new .("scratch_game_page_project") ~ delete _;
		public EditorProject Project;
		public Settings Store = new .() ~ delete _;
		public EditorContext Context = new .() ~ delete _;
		public BareHost Host = new .() ~ delete _;
		public GameEditorPage Page;

		/// `instance` (borrowed, outliving the bed) is the tab's run; none by default.
		public this(GameInstance instance = null)
		{
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			Context.ProjectEditorSettings = Store;
			let services = new GameEditorPageServices();
			services.LoadMarkup = new (path) => LoadMarkup(path);
			Page = new GameEditorPage(Context, Host, services, null, instance, "game-page");
		}

		public ~this()
		{
			Page.OnClose();
			delete Page;
			Context.ProjectEditorSettings = null;
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		public T Find<T>(StringView id) where T : Node => Page.Content.FindElement(id) as T;
	}

	[Test]
	public static void TheKitsTransportOverAStoppedRunAPlayWaitingForTheCookSaysSoAndStopCancelsIt()
	{
		let bed = scope Bed();
		let play = bed.Find<ButtonBase>("game-play");
		let pause = bed.Find<ButtonBase>("game-pause");
		let stop = bed.Find<ButtonBase>("game-stop");
		let state = bed.Find<Sedulous.GUI.Label>("game-state");
		let cook = bed.Find<Sedulous.GUI.Label>("game-cook");
		Test.Assert((play != null) && (pause != null) && (stop != null) && (state != null) && (cook != null));
		Test.Assert(play.Enabled);
		Test.Assert(!pause.Enabled);
		Test.Assert(!stop.Enabled);
		Test.Assert(state.Text == "Stopped");
		Test.Assert(state.HasClass("stopped"));
		Test.Assert(!cook.Displayed);

		// The cook is busy: Play waits for it, and says so.
		bed.Context.CookBusy = new () => true;
		Test.Assert(play.HandleActivate());
		bed.Page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(bed.Page.IsStarting);
		Test.Assert(cook.Displayed);
		Test.Assert(!play.Enabled);
		Test.Assert(stop.Enabled);
		Test.Assert(stop.HandleActivate());
		bed.Page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(!bed.Page.IsStarting);
		Test.Assert(!cook.Displayed);
		Test.Assert(play.Enabled);
		Test.Assert(state.Text == "Stopped");
	}

	[Test]
	public static void TheResolutionsInTheDropdownAPickAndThePhoneKeptWithTheProjectTheDebuggerBesideTheGameByItsToggleItsShareKept()
	{
		let bed = scope Bed();
		let resolution = bed.Find<ComboBox>("game-resolution");
		Test.Assert(resolution != null);
		let choices = bed.Page.ResolutionChoices();
		Test.Assert(choices.Count >= 2);
		Test.Assert(resolution.ItemCount == choices.Count);
		Test.Assert(resolution.SelectedText == choices[0].Label, "the project's");
		resolution.SelectByUser(1);
		Test.Assert(bed.Page.ResolutionKey == choices[1].Key);
		let saved = bed.Store.Find<GamePageSettings>();
		Test.Assert(saved != null);
		Test.Assert(saved.ResolutionKey == choices[1].Key);

		// A pick from code shows in the dropdown, its handler staying out.
		Test.Assert(bed.Page.SelectResolution(choices[0].Key));
		Test.Assert(resolution.SelectedIndex == 0);
		Test.Assert(saved.ResolutionKey == choices[0].Key);

		let phone = bed.Find<ButtonBase>("game-phone");
		Test.Assert(phone != null);
		bed.Page.SelectPhonePreview(true);
		Test.Assert(phone.Checked);
		Test.Assert(bed.Page.PhonePreview);
		Test.Assert(bed.Store.Find<GamePageSettings>().PhonePreview);

		// The debugger is out of the split until its toggle puts it beside the game; it comes back at
		// the share it was given.
		let stage = bed.Find<Splitter>("game-stage");
		let toggle = bed.Find<ButtonBase>("game-debugger-toggle");
		Test.Assert((stage != null) && (toggle != null));
		Test.Assert(!bed.Page.DebuggerShown, "it takes room the game wants");
		Test.Assert(stage.PaneCount == 1, "the game alone");
		Test.Assert(bed.Find<Node>("game-debugger") == null);
		Test.Assert(toggle.HandleActivate());
		Test.Assert(toggle.Checked);
		Test.Assert(bed.Page.DebuggerShown);
		Test.Assert(stage.PaneCount == 2);
		let debuggerState = bed.Find<Sedulous.GUI.Label>("game-debugger-state");
		Test.Assert(debuggerState != null);
		Test.Assert(debuggerState.Text == "Not running");
		float[2] given = .(0.6f, 0.4f);
		stage.SetWeights(Span<float>(&given[0], 2));
		Test.Assert(toggle.HandleActivate());
		Test.Assert(!bed.Page.DebuggerShown, "closed again: the game has the room back");
		Test.Assert(stage.PaneCount == 1);
		Test.Assert(toggle.HandleActivate());
		let weights = scope List<float>();
		stage.GetWeights(weights);
		Test.Assert(weights.Count == 2);
		Test.Assert(Math.Abs(weights[1] - 0.4f) < 0.001f, "back at the share it was given");
	}

	/// Tabs side by side are told apart: Game, then Game 2, Game 3.
	[Test]
	public static void TabsSideBySideAreToldApartGameThenGame2Game3()
	{
		Test.Assert(GameEditorPage.TitleFor("game-page", .. scope .()) == "Game");
		Test.Assert(GameEditorPage.TitleFor("game-page-1", .. scope .()) == "Game 2");
		Test.Assert(GameEditorPage.TitleFor("game-page-2", .. scope .()) == "Game 3");
		let bed = scope Bed(); // the bed's tab is the first
		Test.Assert(bed.Page.Title == "Game");
	}

	/// Shift+F1 gives the keyboard back: the game view lets the focus go, and captures no more
	/// until it is clicked.
	[Test]
	public static void ShiftF1GivesTheKeyboardBackTheViewLetsTheFocusGoAndCapturesNoMore()
	{
		let bed = scope Bed();
		let gui = new GUIContext();
		let root = new SceneRoot(gui);
		gui.ReleaseRef(); // the root's keeps it
		defer root.ReleaseRef();
		root.Size = .(800.0f, 600.0f);
		root.AddChild(bed.Page.Content);
		defer root.RemoveChild(bed.Page.Content);
		root.UpdateLayout();
		let view = bed.Page.View;
		Test.Assert(view != null);
		// As a running game's view is: focused (a click) and capturing every key.
		root.EventDispatcher.FocusNode = view;
		view.CapturesAllKeys = true;
		Test.Assert(view.IsFocused);
		root.EventDispatcher.InjectKeyDown((uint32)Sedulous.GUI.KeyCode.F1, KeyModShift);
		Test.Assert(!view.CapturesAllKeys);
		Test.Assert(!view.IsFocused, "the game reads keys only while its view has the focus");
		// The next frame does not arm it again while the view is not focused.
		bed.Page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(!view.CapturesAllKeys);
	}

	/// RenderQuality in a Game tab: the run offers the project's levels and reads the one the tab
	/// plays at as current; a script's set picks that level in the dropdown, for the session, as
	/// the user would, and the user's pick reaches the scripts.
	[Test]
	public static void ItsRunOffersTheProjectsLevelsToScriptsAScriptsChoiceMovesTheQualityDropdown()
	{
		let root = "scratch_game_page_quality_choice_db";
		RemoveDirectoryRecursive(root);
		CreateDirectory(root);
		defer RemoveDirectoryRecursive(root);
		let serializables = scope SerializableRegistry();
		RenderProfileResources.RegisterAll(serializables);
		let mount = scope NativeFileSystem(root);
		SerializerFactory serializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
		defer delete serializers;
		let database = scope ContentDatabase(mount, serializers, "asset", serializables);
		Guid Write(StringView name)
		{
			let source = scope RenderQualitySource();
			source.Values.Label.Set(name);
			let instance = database.RootGroup.CreateInstance(name, "Sedulous.Engine.Render.RenderQualitySource");
			Test.Assert(instance.WriteObject(source) case .Ok);
			return instance.Id;
		}
		let low = Write("Low");
		let high = Write("High");
		let factory = scope RenderQualityFactory();
		// Declared after the factory and the database, so it goes first.
		let manager = scope ResourceManager(database, null);
		manager.AddFactory(factory);

		// The tab's run, which outlives the tab.
		let run = scope GameInstance();
		{
			let bed = scope Bed(run);
			bed.Context.Resources = manager;
			defer { bed.Context.Resources = null; }
			let settings = bed.Project.Settings;
			settings.QualityLevelIds.Add(low);
			settings.QualityLevelIds.Add(high);
			settings.DefaultQualityId = high;
			let page = bed.Page;
			// What a start offers its scripts: the project's levels as they are then.
			QualityLevels.Offer(run.Quality, settings, manager, .());
			page.OnUpdate(bed.Host, 1.0f / 60.0f);
			Test.Assert(run.Quality.Count() == 2);
			Test.Assert(run.Quality.CurrentId == high, "the dropdown's preset entry: the project's starting level");

			// A script's choice is the dropdown's.
			Test.Assert(run.Quality.Set("Low"));
			Test.Assert(page.QualityKey == low.ToString(.. scope .()));
			page.OnUpdate(bed.Host, 1.0f / 60.0f);
			Test.Assert(run.Quality.CurrentId == low);
			Test.Assert(GameEditorPage.GameQualityLevel(settings, page.PlayedQualityLevel()) == low);

			// The user's pick back to the preset's reaches the scripts.
			Test.Assert(page.SelectQuality(GameResolution.cPresetQualityKey));
			page.OnUpdate(bed.Host, 1.0f / 60.0f);
			Test.Assert(run.Quality.CurrentId == high);
		}
		// The tab is gone: its run offers nothing, and a set reaches no page.
		Test.Assert(run.Quality.Count() == 0);
		Test.Assert(!run.Quality.Set("Low"));
	}

	/// The Game tab plays at the project's starting quality level, as the player starts at it,
	/// read through the editor's resources; the engine's own highest when the project lists none
	/// or its level does not resolve.
	[Test]
	public static void TheGameTabPlaysAtTheProjectsStartingQualityLevel()
	{
		let root = "scratch_game_page_quality_db";
		RemoveDirectoryRecursive(root);
		CreateDirectory(root);
		defer RemoveDirectoryRecursive(root);
		{
			let serializables = scope SerializableRegistry();
			RenderProfileResources.RegisterAll(serializables);
			let mount = scope NativeFileSystem(root);
			SerializerFactory serializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
			defer delete serializers;
			let database = scope ContentDatabase(mount, serializers, "asset", serializables);
			let low = scope RenderQualitySource();
			low.Values.Label.Set("Low");
			low.Values.MsaaSamples = 1;
			low.Values.Antialiasing = .FXAA;
			low.Values.AmbientOcclusion = .Off;
			let lowInstance = database.RootGroup.CreateInstance("low", "Sedulous.Engine.Render.RenderQualitySource");
			Test.Assert(lowInstance.WriteObject(low) case .Ok);
			let factory = scope RenderQualityFactory();
			// Declared after the factory and the database, so it goes first.
			let manager = scope ResourceManager(database, null);
			manager.AddFactory(factory);

			let quality = scope RenderQualitySettings();
			// No levels: the engine's own highest.
			let settings = scope ProjectSettings();
			quality.MsaaSamples = 2;
			GameEditorPage.GameQuality(settings, manager, quality);
			Test.Assert(quality.MsaaSamples == 4);
			// The project's level, read through the editor's resources.
			settings.QualityLevelIds.Add(lowInstance.Id);
			GameEditorPage.GameQuality(settings, manager, quality);
			Test.Assert(quality.Label == "Low");
			Test.Assert(quality.MsaaSamples == 1);
			Test.Assert(quality.Antialiasing == .FXAA);
			Test.Assert(quality.AmbientOcclusion == .Off);
			// Without the resources, or a level that does not resolve: the engine's own highest.
			GameEditorPage.GameQuality(settings, null, quality);
			Test.Assert((quality.MsaaSamples == 4) && (quality.Label == "High"));
			// A level the tab chose (its dropdown's, or the previewed preset's) while the project
			// lists it; one it does not list is ignored for the project's starting level.
			let other = Guid(0x93, 0x94, 0, 0, 0, 0, 0, 0, 0, 0, 0);
			settings.QualityLevelIds.Add(other);
			GameEditorPage.GameQuality(settings, manager, quality, lowInstance.Id);
			Test.Assert(quality.Label == "Low", "the chosen one, not the list's last");
			GameEditorPage.GameQuality(settings, manager, quality, Guid(0x95, 0x96, 0, 0, 0, 0, 0, 0, 0, 0, 0));
			Test.Assert(quality.Label == "High", "unlisted: the starting level, the list's last, which does not resolve");
			settings.QualityLevelIds.PopBack();
			// With a starting level that resolves, an unlisted choice is ignored for it.
			GameEditorPage.GameQuality(settings, manager, quality, Guid(0x95, 0x96, 0, 0, 0, 0, 0, 0, 0, 0, 0));
			Test.Assert(quality.Label == "Low", "unlisted: the project's starting level");
			GameEditorPage.GameQuality(settings, manager, quality);
			settings.QualityLevelIds[0] = Guid(0x91, 0x92, 0, 0, 0, 0, 0, 0, 0, 0, 0);
			GameEditorPage.GameQuality(settings, manager, quality);
			Test.Assert(quality.MsaaSamples == 4);
		}
	}
}
