using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Content;
using Sedulous.Run;
using Sedulous.Scene.Resource;
using Sedulous.Settings;
using Sedulous.Graphics;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.Shell;
using Sedulous.GUI;
using Sedulous.Engine.Scene;
using Sedulous.Engine.GameInstance;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Engine.Project;
using Sedulous.Render;
using Sedulous.VFS;
using Sedulous.Resource;
using Sedulous.Engine.Render;
using Sedulous.Core.Serialization;
using Sedulous.Engine.DefaultApp;

namespace Sedulous.Editor.Play.Tests;

/// A native game for a Game tab's run: what the run tells it, written into its factory's log.
class PieProbeGame : IGameHooks
{
	/// BORROWED: the factory that made it, declared before the bed, so it outlives every game.
	public PieProbeFactory Factory;

	public ~this()
	{
		Factory.Deleted++;
	}

	public void Launch()
	{
		Factory.Log.Append("launch ");
	}

	public void Update(float dt) {}

	public void SceneActivated(Sedulous.Scene.Scene scene)
	{
		Factory.Log.AppendF("scene:{} ", scene.Name);
	}

	public void Exit()
	{
		Factory.Log.Append("exit ");
	}
}

/// What a Game tab's run launches: a PieProbeGame each time, and the record its games write.
class PieProbeFactory : IGameFactory
{
	public String Log = new .() ~ delete _;
	public int Made = 0;
	public int Deleted = 0;

	public IGameHooks CreateGame(GameInstance instance)
	{
		Made++;
		let game = new PieProbeGame();
		game.Factory = this;
		return game;
	}
}

/// The Game tab from its markup (Data/Editor/Game.xml) on a headless host, no game running: the
/// kit's transport (Play while stopped; Pause and Stop while it runs or waits; the state named; a
/// Play waiting for the cook said so and cancelled by Stop), the resolutions in the dropdown, the
/// phone kept with the project, and the game alone on the stage.
/// With a run of its own: a native game launched by Play before the default scene, and ended by Stop
/// or by a scene that did not load.
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
		/// The tab's run, when the bed has one: the page borrows it, and goes first.
		public GameInstance TabRun = null ~ delete _;
		public GameEditorPage Page;

		/// `instance` (borrowed, outliving the bed) is the tab's run; none by default. `withScenes`
		/// gives the host a scene subsystem, which a start needs to run at all. `withRun` gives the
		/// tab a run of its own (TabRun) and the host a started scene subsystem, which a Play needs.
		public this(GameInstance instance = null, bool withScenes = false, bool withRun = false)
		{
			if (withScenes && !withRun)
				Host.Subsystems.AddSubsystem<Sedulous.Engine.Scene.SceneSubsystem>();
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			Context.ProjectEditorSettings = Store;
			if (withRun)
			{
				Host.Subsystems.AddSubsystem<SceneSubsystem>();
				Host.Subsystems.Startup();
				TabRun = new GameInstance();
			}
			let services = new GameEditorPageServices();
			services.LoadMarkup = new (path) => LoadMarkup(path);
			Page = new GameEditorPage(Context, Host, services, null, (instance != null) ? instance : TabRun, "game-page");
		}

		public ~this()
		{
			Page.OnClose();
			delete Page;
			if (TabRun != null)
				Host.Subsystems.Shutdown();
			Context.ProjectEditorSettings = null;
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		/// A scene in the project, made its default: one entity, or with `broken` a stream that is
		/// not a scene, so it fails to load.
		public void AddDefaultScene(StringView name, bool broken)
		{
			SceneResources.RegisterAll();
			let instance = Project.SourceDb.RootGroup.CreateInstance(name, typeof(SceneDocument).GetFullName(.. scope .()));
			Test.Assert(instance != null);
			if (broken)
			{
				let junk = "this is not a scene";
				Test.Assert(instance.WriteData("scene", Span<uint8>((uint8*)junk.Ptr, junk.Length), .Text) case .Ok);
			}
			else
			{
				let authored = scope Sedulous.Scene.Scene(name);
				authored.CreateEntity("Crate");
				Test.Assert(SceneStorage.SaveScene(authored, instance) case .Ok);
			}
			Project.Settings.DefaultSceneId = instance.Id;
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
	public static void TheResolutionsInTheDropdownAPickAndThePhoneKeptWithTheProjectTheGameAloneOnTheStage()
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

		// The game has the stage to itself: its view in the pane under the bar, nothing beside it.
		let pane = bed.Find<Node>("game-view-pane");
		Test.Assert(pane != null);
		Test.Assert(bed.Page.View.Parent === pane);
		Test.Assert(pane.ChildCount == 1);
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

	/// A native game in a Game tab: Play launches it before the default scene loads, so it hears of
	/// that scene as it becomes current, once a play, with no warning; Stop ends it, its exit run;
	/// the next Play makes a fresh one.
	[Test]
	public static void PlayLaunchesTheNativeGameBeforeItsSceneStopEndsIt()
	{
		// Before the bed: they outlive the page and the run.
		let factory = scope PieProbeFactory();
		let warnings = scope String();
		let bed = scope Bed(null, false, true);
		bed.TabRun.Register<IGameFactory>(factory);
		bed.AddDefaultScene("Level", false);
		bed.Context.OnNotice = new [=warnings] (kind, message) =>
			{
				if (kind == .Warning)
					warnings.AppendF("{}\n", message);
			};

		bed.Page.Play();
		bed.Page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(bed.Page.IsRunning);
		Test.Assert(factory.Log == "launch scene:Level ", factory.Log);
		Test.Assert(factory.Made == 1);
		Test.Assert(bed.TabRun.HasNativeGame && bed.TabRun.GameRunning);
		Test.Assert(warnings.IsEmpty, warnings);
		bed.Page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(factory.Made == 1, "launched once a play");
		Test.Assert(factory.Log == "launch scene:Level ", factory.Log);

		bed.Page.Stop();
		Test.Assert(!bed.Page.IsRunning);
		Test.Assert(factory.Log == "launch scene:Level exit ", factory.Log);
		Test.Assert((factory.Deleted == 1) && !bed.TabRun.HasNativeGame, "the stop ends it");

		// Again: a fresh game.
		warnings.Clear();
		bed.Page.Play();
		bed.Page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(bed.Page.IsRunning);
		Test.Assert(factory.Made == 2);
		Test.Assert(factory.Log == "launch scene:Level exit launch scene:Level ", factory.Log);
		Test.Assert(warnings.IsEmpty, warnings);
		bed.Page.Stop();
		Test.Assert(factory.Deleted == 2);
	}

	/// What a relaunch reads of the tab and does to it: it runs while a Play waits on the cook and
	/// while a run goes, not once stopped; set running again, it plays from its start, a fresh game.
	[Test]
	public static void ARelaunchReadsWhetherTheTabRunsAndPlaysItAgainFromItsStart()
	{
		let factory = scope PieProbeFactory();
		let bed = scope Bed(null, false, true);
		bed.TabRun.Register<IGameFactory>(factory);
		bed.AddDefaultScene("Level", false);
		Test.Assert(!bed.Page.RelaunchRuns);

		bool busy = true;
		bed.Context.CookBusy = new [&busy] () => busy;
		bed.Page.RunAgain();
		bed.Page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(bed.Page.IsStarting && bed.Page.RelaunchRuns, "a Play waiting on the cook");
		busy = false;
		bed.Page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(bed.Page.IsRunning && bed.Page.RelaunchRuns);
		Test.Assert(factory.Made == 1);

		bed.Page.Stop();
		Test.Assert(!bed.Page.RelaunchRuns);
		bed.Page.RunAgain();
		bed.Page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(bed.Page.IsRunning);
		Test.Assert(factory.Made == 2, "from its start: a fresh game");
		bed.Page.Stop();
		DeleteAndNullify!(bed.Context.CookBusy); // it reads a local of this test
	}

	/// A default scene that does not load abandons the play: the native game it launched first
	/// ends, its exit run, and no session starts.
	[Test]
	public static void ADefaultSceneThatFailsToLoadEndsTheNativeGameItLaunched()
	{
		let factory = scope PieProbeFactory();
		let bed = scope Bed(null, false, true);
		bed.TabRun.Register<IGameFactory>(factory);
		bed.AddDefaultScene("Broken", true);

		bed.Page.Play();
		bed.Page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(!bed.Page.IsRunning);
		Test.Assert(factory.Log == "launch exit ", factory.Log);
		Test.Assert(factory.Deleted == 1, "deleted with it");
		Test.Assert(!bed.TabRun.HasNativeGame && !bed.TabRun.GameRunning);
		Test.Assert(bed.TabRun.State == .Idle, "no session started");
	}

	/// A Game tab reads its native game's fields, public and private, and its scene's active
	/// native level's, for the PIE probes, and names the game for pie_state. A scene with no
	/// level active gives no value and no reason (a probe then says no native level is active); a
	/// stopped tab has no game.
	[Test]
	public static void TheTabReadsItsNativeGameAndActiveLevelFieldsAndNamesTheGame()
	{
		let factory = scope PieArcadeFactory();
		let bed = scope Bed(null, false, true);
		bed.TabRun.Register<IGameFactory>(factory);
		bed.AddDefaultScene("Level", false);
		let reason = scope String();

		Test.Assert(!bed.Page.GetNativeGame(scope .()), "no game before the play");
		Test.Assert(bed.Page.GetGameField("Lives", reason) == null);
		Test.Assert(reason == "no native game runs", reason);

		bed.Page.Play();
		bed.Page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(bed.Page.IsRunning);
		Test.Assert(factory.Made == 1);
		let typeName = scope String();
		Test.Assert(bed.Page.GetNativeGame(typeName));
		Test.Assert(typeName == "PieArcadeGame", typeName);
		{
			let lives = bed.Page.GetGameField("Lives", reason..Clear());
			defer delete lives;
			Test.Assert((lives != null) && (lives.AsNumber() == 3), reason);
			let phase = bed.Page.GetGameField("mPhase", reason..Clear());
			defer delete phase;
			Test.Assert((phase != null) && (phase.AsString() == "Lobby"), "a private enum, by its name");
			let spawn = bed.Page.GetGameField("mSpawn.z", reason..Clear());
			defer delete spawn;
			Test.Assert((spawn != null) && (spawn.AsNumber() == 3), reason);
			Test.Assert(bed.Page.GetGameField("mScore", reason..Clear()) == null);
			Test.Assert(reason.StartsWith("the game 'PieArcadeGame' has no field 'mScore'"), reason);
		}

		Test.Assert(bed.Page.GetLevelField("TimeLimit", reason..Clear()) == null);
		Test.Assert(reason.IsEmpty, reason);
		let arena = bed.Page.RunningScene.AddSystem<PieArena>();
		arena.Active = true;
		bed.Page.OnUpdate(bed.Host, 1.0f / 60.0f);
		{
			let remaining = bed.Page.GetLevelField("mRemaining", reason..Clear());
			defer delete remaining;
			Test.Assert((remaining != null) && (remaining.AsNumber() == 42), reason);
			let limit = bed.Page.GetLevelField("PieArena.TimeLimit", reason..Clear());
			defer delete limit;
			Test.Assert((limit != null) && (limit.AsNumber() == 60), reason);
		}

		{
			let state = JsonValue.MakeObject();
			defer delete state;
			PieMcpTools.WriteState(bed.Page, state);
			let game = state.Get("game");
			Test.Assert(game.Get("kind").AsString() == "native");
			Test.Assert(game.Get("type").AsString() == "PieArcadeGame");
			Test.Assert(game.Get("running").AsBool());
		}

		bed.Page.Stop();
		Test.Assert(!bed.Page.GetNativeGame(scope .()), "the stop ends it");
		Test.Assert(bed.Page.GetGameField("Lives", reason..Clear()) == null);
		Test.Assert(bed.Page.GetLevelField("TimeLimit", reason..Clear()) == null);
		let stopped = JsonValue.MakeObject();
		defer delete stopped;
		PieMcpTools.WriteState(bed.Page, stopped);
		Test.Assert(stopped.Get("game").Get("kind").AsString() == "none");
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

	/// A start whose default scene does not load undoes itself as Stop does: what it made for the
	/// run (its scene) goes with it, so nothing of it reaches the tab once it closes.
	[Test]
	public static void AStartWhoseDefaultSceneDoesNotLoadLeavesNothingWiredToTheTab()
	{
		// The tab's run, which outlives the tab.
		let run = scope GameInstance();
		let bed = scope Bed(run, true);
		// A scene with no scene stream: it does not load.
		let broken = bed.Project.SourceDb.RootGroup.CreateInstance("Broken", "Sedulous.Scene.Resource.SceneDocument");
		Test.Assert(broken != null);
		bed.Project.Settings.DefaultSceneId = broken.Id;

		bed.Page.Play();
		bed.Page.OnUpdate(bed.Host, 1.0f / 60.0f); // the start runs, and fails on the scene
		Test.Assert(!bed.Page.IsRunning);
		Test.Assert(run.Scenes.ActiveScenes.Length == 0, "its scene is undone with the start");
	}
}
