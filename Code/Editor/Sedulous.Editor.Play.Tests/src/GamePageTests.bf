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
/// phone kept with the project, and the debugger beside the game in a split by its toggle, its share kept.
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

		/// `withRun` gives the tab a run of its own and the host a scene subsystem, which a Play
		/// needs to start.
		public this(bool withRun = false)
		{
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
			Page = new GameEditorPage(Context, Host, services, null, TabRun, "game-page");
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

	/// A native game in a Game tab: Play launches it before the default scene loads, so it hears of
	/// that scene as it becomes current, once a play; Stop ends it, its exit run; a startup script
	/// beside it is not started, and a warning says so; the next Play makes a fresh one.
	[Test]
	public static void PlayLaunchesTheNativeGameBeforeItsSceneStopEndsItAScriptBesideItIsNotStarted()
	{
		// Before the bed: they outlive the page and the run.
		let factory = scope PieProbeFactory();
		let warnings = scope String();
		let bed = scope Bed(true);
		bed.TabRun.Register<IGameFactory>(factory);
		bed.AddDefaultScene("Level", false);
		bed.Project.Settings.StartupScriptId = Guid.Create();
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
		Test.Assert(!bed.TabRun.ScriptRunning, "the startup script is not started");
		Test.Assert(warnings.Contains("the startup script is not started"), warnings);
		bed.Page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(factory.Made == 1, "launched once a play");
		Test.Assert(factory.Log == "launch scene:Level ", factory.Log);

		bed.Page.Stop();
		Test.Assert(!bed.Page.IsRunning);
		Test.Assert(factory.Log == "launch scene:Level exit ", factory.Log);
		Test.Assert((factory.Deleted == 1) && !bed.TabRun.HasNativeGame, "the stop ends it");

		// No startup script: no warning; a fresh game.
		bed.Project.Settings.StartupScriptId = .Empty;
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

	/// A default scene that does not load abandons the play: the native game it launched first
	/// ends, its exit run, and no session starts.
	[Test]
	public static void ADefaultSceneThatFailsToLoadEndsTheNativeGameItLaunched()
	{
		let factory = scope PieProbeFactory();
		let bed = scope Bed(true);
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
	/// level active gives no value and no reason (a probe then reads the level script); a stopped
	/// tab has no game.
	[Test]
	public static void TheTabReadsItsNativeGameAndActiveLevelFieldsAndNamesTheGame()
	{
		let factory = scope PieArcadeFactory();
		let bed = scope Bed(true);
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

	/// The Game tab draws at the project's scene pass MSAA, its look untouched: the player sets
	/// the project's MSAA for every view, and the tab drew at 1x, so a playtest did not show the
	/// game the player shows.
	[Test]
	public static void TheGameTabDrawsAtTheProjectsMsaa()
	{
		let settings = scope ProjectSettings();
		settings.RenderMsaaSamples = 4;
		let post = GameEditorPage.GameViewPost(settings);
		Test.Assert(post.MsaaOverride == 4);
		// Nothing of the game's own post processing is stripped.
		Test.Assert(!post.DisablePost);
		Test.Assert(!post.DisableBloom);
		Test.Assert(!post.DisableAo);
		Test.Assert(!post.DisableSsr);
		Test.Assert(!post.DisableAa);
		Test.Assert(!post.DisableSsgi);
		Test.Assert(!post.DisableCulling);

		// Off, as the project asks.
		settings.RenderMsaaSamples = 1;
		Test.Assert(GameEditorPage.GameViewPost(settings).MsaaOverride == 1);
	}
}
