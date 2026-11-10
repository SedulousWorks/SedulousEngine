using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Graphics;
using Sedulous.Run;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.Settings;
using Sedulous.Shell;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Engine.Scene;
using Sedulous.Engine.Render; // LightComponent, InstanceMemberComponent
using Sedulous.Engine.Composition; // the full scene composition
using Sedulous.Engine.Physics;
using Sedulous.Engine.Navigation;
using Sedulous.Engine.Script;
using Sedulous.Script.Resource;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;
using Sedulous.Editor.Scene;
using Sedulous.Editor.Camera;
using Sedulous.Editor.ViewportTools;
using Sedulous.Render; // DebugDraw
using Sedulous.PropertyAnimation;
using Sedulous.PropertyAnimation.Pipeline;
using Sedulous.Editor.PropertyAnimation;
using Sedulous.Engine.Animation; // PropertyAnimatorComponent (New Clip gives it the clip)

namespace Sedulous.Editor.Scene.Tests;

/// The scene page on the GUI, headless: a scratch project,
/// a runtime context with a scene subsystem and no renderer, the page's own markup. It opens its
/// scene into a scene of its own with the viewport in its pane; its bar's Save follows its own
/// page; a scene that did not load says so on the page and is not saved over; a prefab is marked
/// and refused a second root; Simulate locks the edits and gives the scene back; where the scene
/// was left (the camera, the selection, the panes, the overlays) comes back when it opens again.
/// And the parts: the panes' weights against the prefs' nested ratios, and a prefab's own instance
/// refused. And its hierarchy: the scene its top row, its entities nesting, what opens; the
/// selection both ways; the search; a rename; drops; the menus and the add button as the scene's
/// actions. And its inspector: nothing selected says so; an entity's head and sections;
/// Add Component; a transform's and a component's edits, each one undo step; several entities
/// edited at once; a header's verbs; read only while the page simulates; an entity reference's
/// slot; a component's extras (a rigid body's notice, a zone's Bake); a script component's
/// behaviours; the scene's settings with the scene selected, the physics block's collision groups
/// and the level script's properties. And its bar's editing controls: the page's actions,
/// Select, the space's icon, Snap and its increments. Its HUD: the chips, the stats, the
/// view gizmo, the zoom readout and the tool's status. Its viewport tools: each an action, on the bar
/// by category, the active one's panel under the chips, moved, kept and put back. A reference set
/// in the inspector binds at once. Its scene's file changed outside the editor reloads a clean page
/// and warns a dirty one; deleted, the page stays and its save writes the file back; its own save
/// is never taken for an outside change, and a prefab's reloads its loaded prefab.
class ScenePageTests
{
	/// A host whose subsystem manager has the scene and script subsystems and nothing else: no
	/// renderer, no window.
	class SceneHost : IApplicationHost
	{
		public SubsystemManager Subsystems { get; } = new .() ~ delete _;

		public this()
		{
			// The engine's full composition, so a scene's entities take its components.
			Subsystems.AddSubsystem<SceneSubsystem>().SetComposition(EngineSceneComposition.Build());
			Subsystems.AddSubsystem<ScriptSubsystem>(); // binds a scene's behaviours to its run's host
			Subsystems.Startup();
		}

		public ~this()
		{
			Subsystems.Shutdown();
		}

		public IShell Shell => null;
		public GraphicsDevice Graphics => null;
		public RenderWindow MainRenderWindow => null;

		public RenderWindow OpenWindow(WindowSettings windowSettings, RenderWindowDesc renderDesc) => null;
		public void CloseWindow(RenderWindow window) {}
		public void RequestExit(int code = 0) {}
	}

	/// The repository's Data, found up from the working directory.
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

	static T FindId<T>(Node node, StringView id) where T : Node
	{
		if (let widget = node as UIWidget)
		{
			if (widget.Id == id)
				return node as T;
		}
		for (int i < node.ChildCount)
		{
			if (let found = FindId<T>(node.GetChildAt(i), id))
				return found;
		}
		return null;
	}

	/// A project with a scene ("Level", a Crate in it), a prefab ("Barrel") and a scene whose
	/// source is not a scene ("Broken").
	class Bed
	{
		public String Dir = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_scene_page_project", .. new .()) ~ delete _;
		public EditorProject Project ~ delete _;
		/// The project's editor settings.
		public Settings Store = new .() ~ delete _;
		public EditorContext Context = new .() ~ delete _;
		public SceneHost Host = new .() ~ delete _;
		public Instance Level;
		public Instance Barrel;
		public Instance Broken;
		public Guid Crate;
		public const String cJunk = "this is not a scene";

		public this()
		{
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			SceneResources.RegisterAll();
			SceneEditorSerializables.RegisterAll();
			Context.ProjectEditorSettings = Store;
			SceneActions.Register(Context);
			// The bar's Save, Undo and Redo, as the editor registers them.
			let file = new FileActions();
			file.Save = new (page) => { page.Save().IgnoreError(); };
			EditorAppActions.RegisterFileActions(Context.Actions, file);
			EditorAppActions.RegisterEditActions(Context.Actions, new EditActions());
			let top = Project.SourceDb.RootGroup;
			Level = top.CreateInstance("Level", typeof(SceneDocument).GetFullName(.. scope .()));
			Barrel = top.CreateInstance("Barrel", typeof(PrefabDocument).GetFullName(.. scope .()));
			Broken = top.CreateInstance("Broken", typeof(SceneDocument).GetFullName(.. scope .()));
			Test.Assert((Level != null) && (Barrel != null) && (Broken != null));
			{
				let authored = scope Sedulous.Scene.Scene("authored");
				let e = authored.CreateEntity("Crate");
				Crate = authored.GetEntityId(e);
				Test.Assert(SceneStorage.SaveScene(authored, Level) case .Ok);
			}
			Test.Assert(Broken.WriteData("scene", Span<uint8>((uint8*)cJunk.Ptr, cJunk.Length), .Text) case .Ok);
		}

		public ~this()
		{
			Context.ProjectEditorSettings = null;
			Context.SetProject(null);
			DeleteAndNullify!(Project);
			RemoveDirectoryRecursive(Dir);
		}

		/// The page over `instance`; the caller's.
		/// What the page last asked its picker to show; the bed's.
		public PickerRequest Picked = null ~ delete _;

		public SceneEditorPage Open(Instance instance, RunRegistry runs = null)
		{
			let services = new SceneEditorPageServices();
			services.Host = Host;
			services.Runs = runs;
			services.LoadMarkup = new (path) => LoadMarkup(path);
			services.Pick = new [=this] (request) =>
				{
					delete Picked;
					Picked = request;
				};
			return new SceneEditorPage(Context, services, instance);
		}
	}

	[Test]
	public static void ItsSceneOpenedIntoASceneOfItsOwnTheViewportInItsPaneItsBarsSaveFollowingItsOwnPage()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		Test.Assert(page.ScenePtr != null);
		Test.Assert(page.ScenePtr.FindEntity(bed.Crate).IsAssigned);
		Test.Assert(!page.LoadFailed);
		Test.Assert(!page.IsPrefab);
		let content = page.Content;
		Test.Assert(content != null);
		let pane = FindId<Node>(content, "scene-viewport");
		Test.Assert(pane != null);
		Test.Assert(pane.GetChildAt(0) === page.Viewport.View, "the viewport first in its pane");
		Test.Assert(!FindId<UIWidget>(content, "scene-state").Displayed);
		Test.Assert(!FindId<UIWidget>(content, "scene-kind").Displayed);

		// Clean: Save is off; an edit makes it dirty and the bar follows on its next frame.
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		let save = FindId<ToolButton>(content, "scene-save");
		Test.Assert(save != null);
		Test.Assert(save.TooltipText.StartsWith("Save"));
		Test.Assert(!save.Enabled);
		page.EditContext.CreateEntity("Barrel");
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(page.IsDirty);
		Test.Assert(save.Enabled);
		Test.Assert(page.Save() case .Ok);
		Test.Assert(!page.IsDirty);
		page.OnClose();
	}

	/// The animation panel under the viewport: shown and hidden, an animator's clip
	/// opened in it, its clip asked about apart from the scene, the scene saved as it is and not as
	/// the panel posed it.
	[Test]
	public static void TheAnimationPanelUnderTheViewportItsClipItsOwnTheSceneSavedAsItIsAndNotAsPosed()
	{
		let bed = scope Bed();
		PropertyAnimationPipeline.RegisterAll();
		let clip = PropertyAnimationCreators.CreateClip(bed.Project.SourceDb.RootGroup, "Bounce");
		Test.Assert(clip != null);
		let page = bed.Open(bed.Level);
		defer delete page;
		let panel = page.AnimationPanel;
		Test.Assert(panel != null);
		let center = FindId<Splitter>(page.Content, "scene-center");
		Test.Assert(center != null);
		Test.Assert(center.PaneCount == 1, "hidden: the viewport takes it all");
		Test.Assert(!page.AnimationPanelShown);
		page.SetAnimationPanelShown(true);
		Test.Assert(center.PaneCount == 2);
		page.SetAnimationPanelShown(false);
		Test.Assert(center.PaneCount == 1);

		// An animator's Edit Clip: shown, the clip opened, the entity bound.
		page.EditAnimationClip(clip.Id, bed.Crate);
		Test.Assert(page.AnimationPanelShown);
		Test.Assert(panel.Document.ClipId == clip.Id);
		Test.Assert(panel.BoundEntity == bed.Crate);

		// A track posing the crate at x 5: the clip unsaved, never the scene.
		{
			let offered = scope List<AnimatablePropertyInfo>();
			defer { ClearAndDeleteItems!(offered); }
			panel.OfferedTracks(offered);
			AnimatablePropertyInfo position = null;
			for (let seed in offered)
			{
				if (seed.PropertyPath == "Position")
					position = seed;
			}
			Test.Assert(position != null);
			panel.AddTrack(position);
		}
		panel.Document.Edit("test", scope (c) => { c.Tracks[0].Channels[0].Keys[0].Value = 5.0f; });
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		let crate = page.ScenePtr.FindEntity(bed.Crate);
		Test.Assert(Math.Abs(page.ScenePtr.GetLocalTransform(crate).Position.X - 5.0f) < 1e-3f);
		Test.Assert(!page.IsDirty);
		{
			let besides = scope List<String>();
			defer { ClearAndDeleteItems!(besides); }
			page.ListUnsavedBesides(besides);
			Test.Assert(besides.Count == 1);
			Test.Assert(besides[0] == "The clip 'Bounce'");
		}
		Test.Assert(page.HasUnsavedWork);

		// Saved: the scene as it is (x 0), the crate posed again after.
		page.EditContext.CreateEntity("Barrel");
		Test.Assert(page.Save() case .Ok);
		Test.Assert(Math.Abs(page.ScenePtr.GetLocalTransform(crate).Position.X - 5.0f) < 1e-3f);
		{
			let stored = scope Sedulous.Scene.Scene("stored");
			Test.Assert(SceneStorage.LoadScene(bed.Level, stored) case .Ok);
			Test.Assert(Math.Abs(stored.GetLocalTransform(stored.FindEntity(bed.Crate)).Position.X) < 1e-3f);
		}
		Test.Assert(page.SaveBesides() case .Ok);
		Test.Assert(!page.HasUnsavedBesides);

		// Hidden from its own Close: what it posed goes back.
		Test.Assert(panel.RequestClose != null);
		panel.RequestClose();
		Test.Assert(!page.AnimationPanelShown);
		Test.Assert(Math.Abs(page.ScenePtr.GetLocalTransform(crate).Position.X) < 1e-3f);

		// New on an entity whose animator has no clip: the clip made in Animations and given to it,
		// one step of the scene's; an animator playing a clip keeps it.
		page.EditContext.AddComponent(bed.Crate, typeof(PropertyAnimatorComponent));
		Test.Assert(panel.RequestNewClip != null);
		panel.RequestNewClip();
		let animators = page.ScenePtr.GetSystem<PropertyAnimatorComponentManager>();
		Test.Assert(animators != null);
		let made = animators.Get(crate).Clip.Id;
		Test.Assert(made != .Empty);
		Test.Assert(panel.Document.ClipId == made);
		Test.Assert(panel.Document.Name == "Crate Clip");
		page.EditContext.Commands.Undo();
		Test.Assert(animators.Get(crate).Clip.Id == .Empty);
		page.EditContext.Commands.Redo();
		panel.RequestNewClip(); // another: the animator keeps the first
		Test.Assert(animators.Get(crate).Clip.Id == made);
		Test.Assert(panel.Document.ClipId != made);
		page.OnClose();
	}

	[Test]
	public static void ASceneThatDidNotLoadSaysSoOnThePageAndIsNotSavedOver()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Broken);
		defer delete page;
		Test.Assert(page.LoadFailed);
		Test.Assert(FindId<UIWidget>(page.Content, "scene-state").Displayed);
		page.EditContext.CreateEntity("Lost");
		Test.Assert(page.Save() case .Err(.NotSupported));
		// The source is as it was.
		let stream = bed.Broken.ReadData("scene");
		Test.Assert(stream != null);
		defer delete stream;
		Test.Assert(stream.Size() == Bed.cJunk.Length);
		page.OnClose();
	}

	[Test]
	public static void APrefabIsMarkedAsOneAndRefusedASecondRoot()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Barrel);
		defer delete page;
		Test.Assert(page.IsPrefab);
		Test.Assert(FindId<UIWidget>(page.Content, "scene-kind").Displayed);
		page.EditContext.CreateEntity("Hoop");
		Test.Assert(page.Save() case .Ok, "one root");
		page.EditContext.CreateEntity("Lid");
		// The page says why, before the storage's own refusal.
		let said = scope String();
		bed.Context.OnNotice = new [&said](kind, message) => { said.Set(message); };
		Test.Assert(page.Save() case .Err(.InvalidArgument));
		Test.Assert(said.StartsWith("A prefab needs exactly one root"));
		let why = scope String();
		Test.Assert(PrefabFlows.SaveRefusal(page.ScenePtr, bed.Barrel.Id, why));
		Test.Assert(why.StartsWith("A prefab needs exactly one root"));
		page.OnClose();
	}

	[Test]
	public static void SimulateLocksTheEditsAndGivesTheSceneBackAsItWas()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		let before = page.ScenePtr.EntityCount;
		page.StartSimulation();
		Test.Assert(page.IsSimulating);
		Test.Assert(page.EditContext.CreateEntity("Refused").IsNil, "the stack is locked");
		page.ScenePtr.CreateEntity("Spawned by the run");
		page.PauseSimulation(true);
		Test.Assert(page.IsPaused);
		page.StopSimulation();
		Test.Assert(!page.IsSimulating);
		Test.Assert(page.ScenePtr.EntityCount == before);
		Test.Assert(page.ScenePtr.FindEntity(bed.Crate).IsAssigned);
		Test.Assert(!page.EditContext.CreateEntity("Allowed").IsNil);
		page.OnClose();
	}

	/// What the runs announce, counted.
	class RunsHeard : IRunListener
	{
		public int Started = 0;
		public int Paused = 0;
		public int Stopping = 0;
		public int Destroyed = 0;

		public void OnRunStarted(IRun run) { Started++; }
		public void OnRunPaused(IRun run, bool paused) { Paused++; }
		public void OnRunStopping(IRun run) { Stopping++; }
		public void OnRunDestroyed(IRun run) { Destroyed++; }
	}

	/// The page is a run, which joins the live runs: its scene carries it, its behaviours bind to
	/// its own script host, and each Simulate is one session of it, paused with it and ended at Stop
	/// or at a close mid run. Another page is another run, with a host of its own; the run leaves
	/// with its page.
	[Test]
	public static void ThePageIsARunItsSceneCarriesItAndItsScriptHostAndEachSimulateIsOneSession()
	{
		let bed = scope Bed();
		let heard = scope RunsHeard();
		let runs = scope RunRegistry();
		runs.Subscribe(heard);
		let page = bed.Open(bed.Level, runs);
		let run = page.ScenePtr.Run;
		Test.Assert(run != null);
		Test.Assert(runs.Count == 1);
		Test.Assert((Object)runs.Find(run.Id) === (Object)run);
		Test.Assert(run.Name == "Level");
		Test.Assert(run.State == .Idle, "editing is between sessions");
		let host = RunServices.Get<ScriptRunHost>(run);
		Test.Assert(host != null);
		Test.Assert((Object)host.OwningRun === (Object)run);
		Test.Assert(page.ScenePtr.GetSystem<ScriptSceneSystem>().Host === host);
		Test.Assert(page.ScenePtr.Events === run.Events, "the scene's bus is the run's");

		page.StartSimulation();
		Test.Assert(run.State == .Running);
		page.PauseSimulation(true);
		Test.Assert(run.State == .Paused);
		page.PauseSimulation(false);
		page.StopSimulation();
		Test.Assert(run.State == .Idle);
		Test.Assert(heard.Started == 1);
		Test.Assert(heard.Paused == 2);
		Test.Assert(heard.Stopping == 1);

		// Another page is another run, with a host of its own.
		let other = bed.Open(bed.Barrel, runs);
		let otherRun = other.ScenePtr.Run;
		Test.Assert(otherRun != null);
		Test.Assert((Object)otherRun !== (Object)run);
		Test.Assert(RunServices.Get<ScriptRunHost>(otherRun) !== host);
		Test.Assert(runs.Count == 2);

		// Closed mid Simulate, the session ends with the close; the run leaves with the page.
		page.StartSimulation();
		page.OnClose();
		Test.Assert(heard.Stopping == 2);
		delete page;
		Test.Assert(heard.Destroyed == 1);
		Test.Assert(runs.Count == 1);
		other.OnClose();
		delete other;
		Test.Assert(runs.Count == 0);
		runs.Unsubscribe(heard);
	}

	/// Simulate makes the page's run the focused one, the one heard, as Play does for its tab; Stop
	/// keeps it, as a stopped Game tab keeps it, and it goes with the page's run.
	[Test]
	public static void SimulateMakesThePagesRunTheFocusedOneAsPlayDoesForItsTab()
	{
		let bed = scope Bed();
		let runs = scope RunRegistry();
		let game = scope RunBase("Game 1"); // a Game tab's run, focused by its Play
		runs.Add(game);
		runs.SetFocused(game);
		let page = bed.Open(bed.Level, runs);
		Test.Assert((Object)runs.Focused === game, "opening a page takes nothing");
		page.StartSimulation();
		Test.Assert((Object)runs.Focused === (Object)page.ScenePtr.Run);
		page.StopSimulation();
		Test.Assert((Object)runs.Focused === (Object)page.ScenePtr.Run, "kept");
		page.OnClose();
		delete page;
		Test.Assert(runs.Focused == null, "its run gone, nothing is focused");
	}

	/// A scene's thumbnail is taken from where its page left the camera, so the page saving its
	/// view drops the cached picture: the next one asked for takes the new view.
	[Test]
	public static void ThePageSavingItsViewDropsTheScenesCachedThumbnail()
	{
		let bed = scope Bed();
		let tasks = scope TaskPool(1);
		let thumbnails = scope ThumbnailService();
		// Nothing resolves, so a Get caches a negative at once: an entry to drop.
		thumbnails.Configure(bed.Dir, new (id) => null, tasks, tasks.CreateLane("Light"), new (id) => 0, bed.Dir);
		bed.Context.Thumbnails = thumbnails;
		defer { bed.Context.Thumbnails = null; }
		let page = bed.Open(bed.Level);
		defer delete page;
		Test.Assert(thumbnails.Get(bed.Level.Id) == null);
		let cached = thumbnails.CachedCount;
		Test.Assert(cached >= 1);
		page.OnClose();
		Test.Assert(thumbnails.CachedCount == cached - 1);
	}

	[Test]
	public static void WhereTheSceneWasLeftComesBackWhenItOpensAgain()
	{
		let bed = scope Bed();
		{
			let page = bed.Open(bed.Level);
			defer delete page;
			page.Viewport.Camera.Position = .(4.0f, 5.0f, 6.0f);
			var crate = bed.Crate;
			page.EditContext.EntitySelection.Set(Span<Guid>(&crate, 1));
			page.Overlays.Settings.ShowFps = true;
			let body = FindId<Splitter>(page.Content, "scene-body");
			Test.Assert(body != null);
			var weights = float[3](0.3f, 0.5f, 0.2f);
			body.SetWeights(weights);
			page.OnClose();
		}
		let again = bed.Open(bed.Level);
		defer delete again;
		Test.Assert(Math.Abs(again.Viewport.Camera.Position.X - 4.0f) < 0.001f);
		Test.Assert(again.EditContext.EntitySelection.Contains(bed.Crate));
		Test.Assert(again.Overlays.Settings.ShowFps);
		let weights = scope List<float>();
		FindId<Splitter>(again.Content, "scene-body").GetWeights(weights);
		Test.Assert(weights.Count == 3);
		let total = weights[0] + weights[1] + weights[2];
		Test.Assert(Math.Abs(weights[0] / total - 0.3f) < 0.001f);
		Test.Assert(Math.Abs(weights[2] / total - 0.2f) < 0.001f);
		again.OnClose();
	}

	[Test]
	public static void ASceneIsFramedWholeInPerspectiveFromAboveAndNothingMeasuredLeavesTheCamera()
	{
		let camera = scope EditorCamera();
		let before = camera.Position;
		Test.Assert(!SceneViewState.FrameWhole(AABB.Empty(), camera));
		Test.Assert(camera.Position == before);

		let bounds = AABB(.(90.0f, 0.0f, 90.0f), .(110.0f, 10.0f, 110.0f));
		camera.SetOrthographic(true);
		Test.Assert(SceneViewState.FrameWhole(bounds, camera));
		Test.Assert(!camera.Orthographic);
		let toCenter = bounds.Center() - camera.Position;
		let distance = Length(toCenter);
		Test.Assert(Math.Abs(Dot(toCenter / distance, camera.Forward) - 1.0f) < 0.001f, "it looks at the middle");
		Test.Assert(camera.Position.Y > bounds.Center().Y, "from above");
		Test.Assert(distance * Sin(0.5f * camera.FovY) >= Length(bounds.Extents()) - 0.01f, "the bounds fit its view");
		Test.Assert(Math.Abs(camera.FocusDistance - distance) < 0.01f, "an orbit turns about it");
		Test.Assert(camera.FarZ > distance + Length(bounds.Extents()));
		Test.Assert(camera.NearZ == scope EditorCamera().NearZ, "the near plane is the camera's own, so zooming in does not clip");
	}

	/// A scene built away from the origin (a terrain) opened on the sky; one with no saved view
	/// now opens showing what is in it, and once its view is saved, opens where it was left.
	[Test]
	public static void ASceneWithNoSavedViewOpensShowingWhatIsInItNotTheOrigin()
	{
		let bed = scope Bed();
		var shown = Float3.Zero;
		{
			let page = bed.Open(bed.Level);
			defer delete page;
			let opened = page.Viewport.Camera.Position;
			// The crate measured far from the origin, as a domain would.
			page.ScenePtr.AddSystem<FarBox>();
			page.OnUpdate(bed.Host, 1.0f / 60.0f);
			let camera = page.Viewport.Camera;
			Test.Assert(camera.Position != opened);
			let toCenter = FarBox.Box.Center() - camera.Position;
			Test.Assert(Math.Abs(Dot(Normalized(toCenter), camera.Forward) - 1.0f) < 0.001f);
			shown = camera.Position;
			page.OnClose();
		}
		// Its view was saved as it closed: the next open keeps it, framing nothing again.
		let again = bed.Open(bed.Level);
		defer delete again;
		let kept = again.Viewport.Camera.Position;
		again.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(again.Viewport.Camera.Position == kept);
		Test.Assert(Math.Abs(kept.X - shown.X) < 0.001f);
		again.OnClose();
	}

	[Test]
	public static void ThePanesWeightsAndThePrefsNestedRatiosConvertBothWays()
	{
		let weights = SceneViewState.WeightsFromSplits(0.2f, 0.72f);
		Test.Assert(Math.Abs(weights.Hierarchy - 0.2f) < 0.0001f);
		Test.Assert(Math.Abs(weights.Viewport - 0.8f * 0.72f) < 0.0001f);
		Test.Assert(Math.Abs(weights.Inspector - 0.8f * 0.28f) < 0.0001f);
		SceneViewState.SplitsFromWeights(.(2.0f, 6.0f, 2.0f), let hierarchy, let inspector); // any scale
		Test.Assert(Math.Abs(hierarchy - 0.2f) < 0.0001f);
		Test.Assert(Math.Abs(inspector - 0.75f) < 0.0001f);
	}

	[Test]
	public static void APrefabsPageRefusesAnInstanceOfItselfSayingSo()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Barrel);
		defer delete page;
		let services = new PrefabFlowServices();
		services.Context = bed.Context;
		services.Edit = page.EditContext;
		let self = bed.Barrel.Id;
		services.PageAsset = new () => self;
		let flows = scope PrefabFlows(services);
		// Saved once, the prefab has content: it is refused for what it is, not for being empty.
		page.EditContext.CreateEntity("Hoop");
		Test.Assert(page.Save() case .Ok);
		let said = scope String();
		bed.Context.OnNotice = new [&said](kind, message) => { said.Set(message); };
		Test.Assert(!flows.Spawn(self, .()));
		Test.Assert(said.StartsWith("A prefab cannot contain an instance of itself"));
		said.Clear();
		Test.Assert(!flows.Spawn(.(), .()), "nothing picked");
		Test.Assert(said.IsEmpty, "nothing picked is no warning");
		page.OnClose();
	}

	/// A writer outside the editor over the bed's Content/ (a pull, another tool): a database on a
	/// mount of its own, whose writes the project never hears of.
	class OutsideWriter
	{
		public Sedulous.VFS.NativeFileSystem Mount;
		public ContentDatabase Database;

		public this(Bed bed)
		{
			Mount = new .(PathJoin(bed.Dir, Sedulous.Engine.Project.ProjectLayout.ContentDir, .. scope .()));
			Database = new .(Mount, bed.Project.SourceDb.Serializers, bed.Project.SourceDb.Extension);
		}

		public ~this()
		{
			delete Database;
			delete Mount;
		}
	}

	/// The watcher looks twice (seen, then settled), the database takes the change in, and the
	/// context tells the pages, as the editor's cook service and session do.
	static void TakeInOutsideChange(Bed bed, ContentWatcher watcher, ContentChanges changes)
	{
		Test.Assert(!watcher.Poll(changes), "seen once: it may still be being written");
		Test.Assert(watcher.Poll(changes), "settled");
		bed.Context.ApplyContentChanges(changes, watcher.RemovedRecords);
	}

	[Test]
	public static void AScenesFileReplacedOutsideReloadsItsCleanPageAndADirtyOneWarnsKeepingItsEdits()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		bed.Context.AdoptPage(page); // the context's now, as an opened page is
		let levelId = bed.Level.Id;
		let outside = scope OutsideWriter(bed);
		let watcher = scope ContentWatcher(bed.Project);
		let changes = scope ContentChanges();
		let said = scope String();
		bed.Context.OnNotice = new [&said](kind, message) => { said.Set(message); };

		// Clean: what came from outside is read in, the history before it gone.
		Guid lamp;
		{
			let pulled = scope Sedulous.Scene.Scene("pulled");
			lamp = pulled.GetEntityId(pulled.CreateEntity("Lamp"));
			Test.Assert(SceneStorage.SaveScene(pulled, outside.Database.GetInstance(levelId)) case .Ok);
		}
		TakeInOutsideChange(bed, watcher, changes);
		// By name: a fresh scene's first entity gets the same id in every scene, so the pulled
		// Lamp has the Crate's.
		Test.Assert(page.ScenePtr.FindEntity(lamp).IsAssigned, "reloaded");
		Test.Assert(page.ScenePtr.FindEntityByName("Lamp").IsAssigned);
		Test.Assert(!page.ScenePtr.FindEntityByName("Crate").IsAssigned, "the old content gone");
		Test.Assert(!page.IsDirty);

		// Dirty: its edits kept, the user warned.
		let mine = page.EditContext.CreateEntity("Mine");
		Test.Assert(page.IsDirty);
		{
			let again = scope Sedulous.Scene.Scene("pulled again");
			again.CreateEntity("Lamp");
			again.CreateEntity("Post");
			Test.Assert(SceneStorage.SaveScene(again, outside.Database.GetInstance(levelId)) case .Ok);
		}
		TakeInOutsideChange(bed, watcher, changes);
		Test.Assert(page.ScenePtr.FindEntity(mine).IsAssigned && page.IsDirty, "its edits kept");
		Test.Assert(said.Contains("unsaved edits"), said);
		page.OnClose();
		bed.Context.ClosePage(page);
	}

	[Test]
	public static void AScenesFileDeletedOutsideLeavesItsPageOpenToldAndItsSaveWritesItBack()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		bed.Context.AdoptPage(page);
		let levelId = bed.Level.Id;
		let outside = scope OutsideWriter(bed);
		let watcher = scope ContentWatcher(bed.Project);
		let changes = scope ContentChanges();
		let said = scope String();
		bed.Context.OnNotice = new [&said](kind, message) => { said.Set(message); };

		// Its envelope and its scene stream go; the bed's Level record goes with them.
		Test.Assert(outside.Database.DeleteInstance(levelId) case .Ok);
		TakeInOutsideChange(bed, watcher, changes);
		Test.Assert(bed.Project.SourceDb.GetInstance(levelId) == null);
		Test.Assert(bed.Context.OpenPages.Contains(page), "never closed under the user");
		Test.Assert(page.IsAssetDeleted && page.IsDirty);
		Test.Assert(page.ScenePtr.FindEntity(bed.Crate).IsAssigned, "what it shows is kept");
		Test.Assert(said.Contains("deleted on disk"), said);

		// Saved: the record back at its place with its identity, the scene written whole.
		Test.Assert(bed.Context.SavePage(page) case .Ok);
		Test.Assert(!page.IsAssetDeleted && !page.IsDirty);
		let back = bed.Project.SourceDb.GetInstance(levelId);
		Test.Assert((back != null) && (back.Name == "Level"));
		{
			let stored = scope Sedulous.Scene.Scene("stored");
			Test.Assert(SceneStorage.LoadScene(back, stored) case .Ok);
			Test.Assert(stored.FindEntity(bed.Crate).IsAssigned);
		}
		Test.Assert(!watcher.Poll(changes) && !watcher.Poll(changes) && changes.IsEmpty, "the save is the editor's own write");
		page.OnClose();
		bed.Context.ClosePage(page);
	}

	[Test]
	public static void APagesOwnSaveIsNotTakenForAnOutsideChangeSoItsHistoryStays()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		bed.Context.AdoptPage(page);
		let watcher = scope ContentWatcher(bed.Project);
		let changes = scope ContentChanges();

		page.EditContext.CreateEntity("Barrel");
		Test.Assert(bed.Context.SavePage(page) case .Ok);
		Test.Assert(!page.IsDirty && page.Commands.CanUndo);
		for (int i < 3)
		{
			Test.Assert(!watcher.Poll(changes) && changes.IsEmpty);
			bed.Context.ApplyContentChanges(changes, watcher.RemovedRecords);
		}
		Test.Assert(watcher.PendingCount == 0);
		Test.Assert(page.Commands.CanUndo, "not reloaded: its history stays");
		page.OnClose();
		bed.Context.ClosePage(page);
	}

	/// The name of the root a loaded prefab spawns, read from its payload alone.
	static void SpawnedRootName(PrefabResource prefab, String outName)
	{
		Test.Assert(prefab != null);
		let scene = scope Sedulous.Scene.Scene("spawned");
		let payload = prefab.OpenPayload();
		defer delete payload;
		let root = PrefabSpawn.Spawn(scene, payload, prefab.Id);
		Test.Assert(root.IsAssigned);
		outName.Set(scene.GetEntityName(root));
	}

	/// A prefab page's own save is not an outside change, so nothing else tells the loaded prefab:
	/// the save reloads it, and the next spawn of a running game is what was saved.
	[Test]
	public static void APrefabPagesSaveReloadsTheLoadedPrefab()
	{
		let bed = scope Bed();
		// The editor's resources: the cooked database over the sources, a prefab falling through.
		let prefabs = scope PrefabFactory();
		let resources = scope Sedulous.Resource.ResourceManager(bed.Project.ResourceDb);
		resources.AddFactory(prefabs);
		bed.Project.ResourceDb.SetFallthrough(new [=resources] (storedTypeName) => resources.ReadsAuthoredRecord(storedTypeName));
		bed.Context.Resources = resources;
		defer
		{
			bed.Context.Resources = null;
			bed.Project.ResourceDb.SetFallthrough(null);
		}
		Test.Assert(bed.Project.ResourceDb.GetInstance(bed.Barrel.Id) == bed.Barrel, "the sources answer for a prefab");
		Test.Assert(bed.Project.ResourceDb.GetInstance(bed.Level.Id) == null, "and not for a scene");

		let page = bed.Open(bed.Barrel);
		defer delete page;
		page.EditContext.CreateEntity("Hoop");
		Test.Assert(page.Save() case .Ok);
		let proxy = resources.Bind<PrefabResource>(bed.Barrel.Id);
		Test.Assert(SpawnedRootName(proxy.Get, .. scope .()) == "Hoop");

		let hoop = page.ScenePtr.FindEntityByName("Hoop");
		Test.Assert(hoop.IsAssigned);
		page.ScenePtr.SetEntityName(hoop, "Ring");
		Test.Assert(page.Save() case .Ok);
		Test.Assert(proxy.State == .Ready);
		Test.Assert(SpawnedRootName(proxy.Get, .. scope .()) == "Ring", "the saved prefab, not the one loaded before");
		page.OnClose();
	}

	/// The page laid out in a GUI of its own under the editor's sheet, for its hierarchy's rows to
	/// be pressed where they show.
	class Shown
	{
		public SceneRoot Root;
		private Node mContent;
		private EditorResources mResources ~ delete _;
		private StyleManager mStyles ~ delete _;

		public this(SceneEditorPage page)
		{
			let data = scope String();
			Test.Assert(DataRoot(data));
			mResources = new .(data, EditorWindow.cEditorFolder); // the editor's folder alone, as the window watches
			let look = scope EditorLook();
			look.Density.Set("default");
			let text = EditorWindow.SheetFor(mResources, look, .. scope String());
			let sheet = scope StyleSheet();
			CSSParser.Parse(text, EditorWindow.cSheetPath, sheet);
			mStyles = new .(sheet);
			mStyles.ResourceProvider = mResources;
			let context = new GUIContext();
			Root = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Root.Size = .(1200.0f, 700.0f);
			mContent = page.Content;
			Root.AddChild(mContent);
			mStyles.ApplyTree(Root);
			Root.UpdateLayout();
		}

		/// The sheet over the tree again, for nodes added after it was applied.
		public void Restyle() => mStyles.ApplyTree(Root);

		public ~this()
		{
			Root.RemoveChild(mContent);
			Root.ReleaseRef();
		}

		/// A press and release in the middle of `node`.
		public void Click(Node node)
		{
			Root.UpdateLayout();
			let bounds = node.ScreenBounds;
			let at = Float2(bounds.X + bounds.Width * 0.5f, bounds.Y + bounds.Height * 0.5f);
			Root.EventDispatcher.InjectMouseMove(at);
			Root.EventDispatcher.InjectMouseDown(at, .Left);
			Root.EventDispatcher.InjectMouseUp(at, .Left);
		}

		/// A press and release in the middle of the row showing `item`.
		public void Click(TreeView tree, int32 item, uint32 modifiers = 0)
		{
			Root.UpdateLayout();
			let row = tree.RowForItem(item);
			Test.Assert(row != null, "realised");
			let bounds = row.ScreenBounds;
			let at = Float2(bounds.X + bounds.Width * 0.5f, bounds.Y + bounds.Height * 0.5f);
			Root.EventDispatcher.InjectMouseMove(at);
			Root.EventDispatcher.InjectMouseDown(at, .Left, modifiers);
			Root.EventDispatcher.InjectMouseUp(at, .Left, modifiers);
		}

		/// A key pressed on what has the focus.
		public void Key(Sedulous.GUI.KeyCode key) => Root.EventDispatcher.InjectKeyDown((uint32)key);
	}

	static bool RowsAre(SceneHierarchyView tree, StringView expected)
	{
		let rows = tree.Rows(.. scope .());
		return rows == expected;
	}

	[Test]
	public static void TheHierarchyShowsTheSceneOnTopItsEntitiesNestingAndSharesTheSelection()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		let tree = page.Hierarchy;
		Test.Assert(tree != null);
		let lid = page.EditContext.CreateEntity("Lid", bed.Crate);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(RowsAre(tree, "Level |   Crate |     Lid"), "Crate gained a child: it opens");
		let knob = page.EditContext.CreateEntity("Knob", lid);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(RowsAre(tree, "Level |   Crate |     Lid |       Knob"));
		tree.Tree.CollapseItem(tree.ItemOf(lid)); // closed by the user: it stays closed
		page.EditContext.CreateEntity("Spring", lid);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(RowsAre(tree, "Level |   Crate |     Lid"));
		Test.Assert(!knob.IsNil);

		// The page's selection (a viewport pick) shows in the tree; a click on a row is the page's.
		page.EditContext.EntitySelection.Set(bed.Crate);
		Test.Assert(tree.Tree.IsItemSelected(tree.ItemOf(bed.Crate)));
		{
			let shown = scope Shown(page);
			shown.Click(tree.Tree, tree.ItemOf(lid));
			Test.Assert(page.EditContext.EntitySelection.Contains(lid));
			Test.Assert(!page.EditContext.EntitySelection.Contains(bed.Crate));
			shown.Click(tree.Tree, tree.ItemOf(bed.Crate), KeyModCtrl); // several
			Test.Assert(page.EditContext.EntitySelection.Count == 2);
			shown.Click(tree.Tree, 0); // the scene's row: no entity
			Test.Assert(tree.Tree.SelectionCount == 1);
			Test.Assert(tree.Tree.IsItemSelected(0));
			Test.Assert(page.EditContext.EntitySelection.IsEmpty);
		}

		// An entity that is not active dims; the model says so for its row.
		page.EditContext.SetEntityActive(lid, false);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		let classes = tree.Tree.Model.Data(tree.IndexOf(lid), .RowClass);
		Test.Assert(classes.AsString == "inactive");
		page.OnClose();
	}

	[Test]
	public static void TheHierarchysSearchKeepsAMatchsWayAWholeGuidSelectsAndARenameIsOneUndo()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		let tree = page.Hierarchy;
		Test.Assert(tree != null);
		let lid = page.EditContext.CreateEntity("Lid", bed.Crate);
		page.EditContext.CreateEntity("Barrel");
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		tree.Search("lid");
		Test.Assert(RowsAre(tree, "Level |   Crate |     Lid"));
		page.EditContext.EntitySelection.Clear();
		tree.Search(lid.ToString(.. scope .(), 'D'));
		Test.Assert(page.EditContext.EntitySelection.Contains(lid));
		tree.Search("");
		Test.Assert(RowsAre(tree, "Level |   Crate |     Lid |   Barrel"));

		Test.Assert(tree.Tree.Model.SetData(tree.IndexOf(lid), .("Hatch")));
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(RowsAre(tree, "Level |   Crate |     Hatch |   Barrel"));
		page.Commands.Undo();
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(RowsAre(tree, "Level |   Crate |     Lid |   Barrel"));
		page.OnClose();
	}

	[Test]
	public static void AHierarchyRowDroppedGoesUnderBetweenOrToTheRootsNeverInsideItself()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		let tree = page.Hierarchy;
		Test.Assert(tree != null);
		let barrel = page.EditContext.CreateEntity("Barrel");
		let lid = page.EditContext.CreateEntity("Lid", bed.Crate);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		let model = tree.Tree.Model;
		ItemId[1] moving = default;
		ModelDrop Drop(Guid moved, Guid onto, DropPlace place)
		{
			moving[0] = model.IdOf(tree.IndexOf(moved));
			var drop = ModelDrop();
			drop.Source = model;
			drop.Ids = .(&moving[0], 1);
			drop.Index = tree.IndexOf(onto);
			drop.Place = place;
			return drop;
		}

		Test.Assert(tree.Take(Drop(barrel, bed.Crate, .On)));
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(RowsAre(tree, "Level |   Crate |     Lid |     Barrel"));
		Test.Assert(tree.Take(Drop(barrel, lid, .Before)));
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(RowsAre(tree, "Level |   Crate |     Barrel |     Lid"));
		Test.Assert(tree.Take(Drop(lid, .(), .On)), "onto the scene's row");
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(RowsAre(tree, "Level |   Crate |     Barrel |   Lid"));
		Test.Assert(!tree.CanTake(Drop(bed.Crate, barrel, .On)), "inside itself");
		Test.Assert(!tree.CanTake(Drop(.(), barrel, .On)), "the scene stays");

		// A drag carries its entities, for an entity slot.
		let payload = scope DragPayload();
		var one = lid;
		tree.DragOf(.(&one, 1), payload);
		let carried = scope List<Guid>();
		Test.Assert(EntityDrag.Read(payload, carried));
		Test.Assert((carried.Count == 1) && (carried[0] == lid));
		Test.Assert(payload.Label == "Lid");
		page.OnClose();
	}

	[Test]
	public static void APrefabDroppedIsSpawnedUnderTheRowAndTheMenusAndAddAreTheScenesActions()
	{
		let bed = scope Bed();
		{
			// The prefab needs content: one root.
			let authored = scope Sedulous.Scene.Scene("barrel");
			authored.CreateEntity("Barrel");
			Test.Assert(SceneStorage.SavePrefab(authored, bed.Barrel) case .Ok);
		}
		let page = bed.Open(bed.Level);
		defer delete page;
		let tree = page.Hierarchy;
		Test.Assert(tree != null);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		let prefabType = typeof(PrefabDocument).GetFullName(.. scope .());
		let asset = scope DragPayload();
		AssetDrag.Payload(bed.Barrel.Id, prefabType, "Barrel", asset);
		var drop = ModelDrop();
		drop.Payload = asset;
		drop.Index = tree.IndexOf(bed.Crate);
		drop.Place = .On;
		Test.Assert(tree.Take(drop));
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(RowsAre(tree, "Level |   Crate |     Barrel"));
		let level = scope DragPayload();
		AssetDrag.Payload(bed.Level.Id, typeof(SceneDocument).GetFullName(.. scope .()), "Level", level);
		drop.Payload = level;
		Test.Assert(!tree.CanTake(drop), "only a prefab goes in");

		// A row's menu: its actions over the page.
		{
			scope Shown(page); // the page under the editor's sheet until the test ends
			tree.ShowMenu(tree.ItemOf(bed.Crate), .(10.0f, 10.0f));
			let menu = tree.OpenMenu;
			Test.Assert(menu != null);
			Test.Assert(page.EditContext.EntitySelection.Contains(bed.Crate), "the row it was asked over");
			var hasDelete = false;
			for (int i < menu.ChildCount)
			{
				if (let item = menu.GetChildAt(i) as MenuItem)
					hasDelete = hasDelete || (item.Text == "Delete");
			}
			Test.Assert(hasDelete);
			menu.Close();
		}

		let add = FindId<ToolButton>(page.Content, "hierarchy-add");
		Test.Assert(add != null);
		Test.Assert(add.Enabled);
		Test.Assert(add.TooltipText.StartsWith("Create Entity"));
		page.StartSimulation();
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(!add.Enabled, "refused visibly while it simulates");
		page.StopSimulation();
		page.OnClose();
	}

	/// The GUI's clipboard, in memory.
	class TestClipboard : Sedulous.GUI.IClipboard
	{
		public String Stored = new .() ~ delete _;

		public bool HasText => !Stored.IsEmpty;
		public void GetText(String outText) { outText.Append(Stored); }
		public void SetText(StringView text) { Stored.Set(text); }
	}

	static MenuItem ItemNamed(Node menu, StringView text)
	{
		for (int i < menu.ChildCount)
		{
			let node = menu.GetChildAt(i);
			if (let item = node as MenuItem)
			{
				if (item.Text == text)
					return item;
			}
			if (let found = ItemNamed(node, text))
				return found;
		}
		return null;
	}

	[Test]
	public static void AHierarchyRowsCopyIdPutsTheEntitysGuidOnTheClipboardAndSaysSoWithNoClipboardItWarns()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		let tree = page.Hierarchy;
		Test.Assert(tree != null);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		NoticeKind kind = .Info;
		let notice = scope String();
		bed.Context.OnNotice = new [&] (k, message) =>
			{
				kind = k;
				notice.Set(message);
			};
		let shown = scope Shown(page);
		let clipboard = scope TestClipboard();
		shown.Root.EventDispatcher.Clipboard = clipboard;
		defer { shown.Root.EventDispatcher.Clipboard = null; }

		// The scene's row has no id to copy.
		tree.ShowMenu(0, .(10.0f, 10.0f));
		Test.Assert(tree.OpenMenu != null);
		Test.Assert(ItemNamed(tree.OpenMenu, "Copy ID") == null);
		tree.OpenMenu.Close();

		tree.ShowMenu(tree.ItemOf(bed.Crate), .(10.0f, 10.0f));
		Test.Assert(tree.OpenMenu != null);
		var copy = ItemNamed(tree.OpenMenu, "Copy ID");
		Test.Assert(copy != null);
		Test.Assert(copy.HandleActivate());
		Test.Assert(clipboard.Stored == bed.Crate.ToString(.. scope .(), 'D')); // the guid as the scene file spells it
		Test.Assert(clipboard.Stored.Length == 36);
		Test.Assert(kind == .Success);
		Test.Assert(notice == "Copied entity ID");

		shown.Root.EventDispatcher.Clipboard = null;
		tree.ShowMenu(tree.ItemOf(bed.Crate), .(10.0f, 10.0f));
		Test.Assert(tree.OpenMenu != null);
		copy = ItemNamed(tree.OpenMenu, "Copy ID");
		Test.Assert(copy != null);
		copy.HandleActivate();
		Test.Assert(kind == .Warning);
		Test.Assert(notice == "Could not copy entity ID to the clipboard");
		page.OnClose();
	}

	[Test]
	public static void AHierarchyRowDoubleClickedFramesItsEntityEasedAndStartsNoRenameOneClickFramesNothing()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		let tree = page.Hierarchy;
		Test.Assert(tree != null);
		let lantern = page.EditContext.CreateEntity("Lantern");
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		let camera = page.ViewportCamera;
		Test.Assert(camera != null);
		let shown = scope Shown(page);

		// The scene's row: no entity, nothing framed.
		shown.Click(tree.Tree, 0);
		shown.Click(tree.Tree, 0);
		Test.Assert(!camera.IsGliding);

		let item = tree.ItemOf(lantern);
		Test.Assert(item >= 0);
		shown.Click(tree.Tree, item);
		Test.Assert(page.EditContext.EntitySelection.Contains(lantern));
		Test.Assert(!camera.IsGliding, "one click selects");
		shown.Click(tree.Tree, item);
		Test.Assert(camera.IsGliding, "the second frames, eased");
		Test.Assert(!tree.Tree.IsEditing);

		// Once the glide is done, the pivot is on the entity (at the origin).
		camera.Advance(1.0f);
		let pivot = camera.Position + camera.Forward * camera.FocusDistance;
		Test.Assert(Length(pivot) < 0.01f);
		page.OnClose();
	}

	[Test]
	public static void TheHierarchysArrowKeysMoveTheTreesSelectionTheScenesFollowsUpOntoTheScenesRowClearsIt()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		let tree = page.Hierarchy;
		Test.Assert(tree != null);
		let barrel = page.EditContext.CreateEntity("Barrel");
		let lantern = page.EditContext.CreateEntity("Lantern");
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(RowsAre(tree, "Level |   Crate |   Barrel |   Lantern"));
		let shown = scope Shown(page);

		shown.Click(tree.Tree, tree.ItemOf(bed.Crate)); // the tree has the keys now
		Test.Assert(page.EditContext.EntitySelection.Contains(bed.Crate));
		shown.Key(.Down);
		Test.Assert(page.EditContext.EntitySelection.Contains(barrel));
		Test.Assert(page.EditContext.EntitySelection.Count == 1);
		shown.Key(.Down);
		Test.Assert(page.EditContext.EntitySelection.Contains(lantern));
		shown.Key(.Up);
		shown.Key(.Up);
		Test.Assert(page.EditContext.EntitySelection.Contains(bed.Crate));
		shown.Key(.Up);
		Test.Assert(page.EditContext.EntitySelection.IsEmpty, "the scene's row: no entity");
		Test.Assert(tree.SceneSelected);
		page.OnClose();
	}

	[Test]
	public static void InspectorASceneSettingsSectionIsTitledWithItsTypesDisplayNameElseItsNameLessSettings()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		let inspector = page.Inspector;
		Test.Assert(inspector != null);
		let shown = scope Shown(page);
		shown.Click(page.Hierarchy.Tree, 0); // the scene's row
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(inspector.Kind == "Scene");
		let edit = page.EditContext;
		Test.Assert(edit.FindSystemBySettingsType(typeof(EnvironmentSettings)) != null);
		Test.Assert(inspector.SettingsOf("Environment") != null);
		Test.Assert(edit.FindSystemBySettingsType(typeof(PostProcessSettings)) != null);
		Test.Assert(inspector.SettingsOf("Post Processing") != null);
		Test.Assert(edit.FindSystemBySettingsType(typeof(PhysicsSceneSettings)) != null);
		Test.Assert(inspector.SettingsOf("Physics") != null);
		Test.Assert(edit.FindSystemBySettingsType(typeof(NavigationSceneSettings)) != null);
		Test.Assert(inspector.SettingsOf("Navigation") != null);
		Test.Assert(edit.FindSystemBySettingsType(typeof(SceneScriptSettings)) != null);
		Test.Assert(inspector.SettingsOf("Scene Script") != null);
		// No type name reads through.
		let titles = inspector.SectionTitles(.. scope .());
		Test.Assert(!titles.Contains("PostProcess", true));
		Test.Assert(!titles.Contains("PhysicsScene", true));
		Test.Assert(!titles.Contains("Settings", true));
		page.OnClose();
	}

	[Test]
	public static void AHierarchyOpensWithItsTopLevelShownWhatIsUnderAnEntityWaiting()
	{
		let bed = scope Bed();
		{
			let page = bed.Open(bed.Level);
			defer delete page;
			page.EditContext.CreateEntity("Lid", bed.Crate);
			Test.Assert(page.Save() case .Ok);
			page.OnClose();
		}
		let page = bed.Open(bed.Level);
		defer delete page;
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(RowsAre(page.Hierarchy, "Level |   Crate"));
		page.OnClose();
	}

	/// The inspector's section titles, by " | ".
	static bool TitlesAre(SceneInspectorView inspector, StringView expected)
	{
		let titles = inspector.SectionTitles(.. scope String());
		if (titles != expected)
		{
			Console.WriteLine("the sections: \"{}\"", titles);
			return false;
		}
		return true;
	}

	/// The scene's light on `entity`.
	static LightComponent* LightOf(SceneEditorPage page, Guid entity)
	{
		let manager = page.EditContext.FindManager(typeof(LightComponent));
		Test.Assert(manager != null);
		return (LightComponent*)manager.GetComponentAddress(page.ScenePtr.FindEntity(entity));
	}

	/// An edit of `path` through the inspector's sections to `value`, as the grid makes one, and a
	/// frame.
	static void Commit(SceneEditorPage page, Bed bed, StringView path, double value)
	{
		let write = PropertyWrite(Sedulous.GUI.Variant(value));
		page.Inspector.Sections.BeginEdit(path);
		page.Inspector.Sections.CommitEdit(path, write);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
	}

	[Test]
	public static void InspectorNothingSelectedSaysSoAnEntityShowsItsHeadEntityTransformAndEachComponentAddComponentAndItsUndo()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		let inspector = page.Inspector;
		Test.Assert(inspector != null);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		let content = page.Content;
		Test.Assert(FindId<Node>(content, "inspector-state").Displayed);
		Test.Assert(!inspector.Grid.Displayed);

		page.EditContext.EntitySelection.Set(bed.Crate);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(!FindId<Node>(content, "inspector-state").Displayed);
		Test.Assert(FindId<TextField>(content, "inspector-name").Text == "Crate");
		Test.Assert(inspector.Kind == "Entity");
		Test.Assert(TitlesAre(inspector, "Entity | Transform"));

		let addable = scope List<String>();
		defer { ClearAndDeleteItems!(addable); }
		inspector.AddableComponents(addable);
		var light = false;
		for (let name in addable)
			light = light || (name == "LightComponent");
		Test.Assert(light);
		Test.Assert(inspector.AddComponent("LightComponent"));
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(TitlesAre(inspector, "Entity | Transform | Light"));
		page.Commands.Undo(); // one step
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(TitlesAre(inspector, "Entity | Transform"));
		page.OnClose();
	}

	[Test]
	public static void InspectorATransformEditAndAComponentEditAreEachOneUndoStepTwoEditsOfOneRowAreTwo()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		let inspector = page.Inspector;
		page.EditContext.EntitySelection.Set(bed.Crate);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(inspector.AddComponent("LightComponent"));
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		let scene = page.ScenePtr;

		Commit(page, bed, inspector.PathOf("Transform", "Position.x", .. scope String()), 4.0);
		Test.Assert(scene.GetLocalTransform(scene.FindEntity(bed.Crate)).Position.X == 4.0f);
		let intensity = inspector.PathOf("Light", "Intensity", .. scope String());
		Commit(page, bed, intensity, 7.0);
		Commit(page, bed, intensity, 9.0);
		Test.Assert(LightOf(page, bed.Crate).Intensity == 9.0f);
		page.Commands.Undo();
		Test.Assert(LightOf(page, bed.Crate).Intensity == 7.0f); // the second edit alone
		page.Commands.Undo();
		Test.Assert(LightOf(page, bed.Crate).Intensity != 7.0f);
		page.Commands.Redo();
		Test.Assert(LightOf(page, bed.Crate).Intensity == 7.0f);
		page.Commands.Undo();
		page.Commands.Undo(); // the transform
		Test.Assert(scene.GetLocalTransform(scene.FindEntity(bed.Crate)).Position.X == 0.0f);
		page.OnClose();
	}

	/// A frame where nothing moved costs the grid no layout; a value moved from outside reaches it.
	[Test]
	public static void InspectorAFrameWhereNothingMovedCostsTheGridNoLayoutAValueMovedFromOutsideReachesIt()
	{
		BuiltinInspectorExtras.Register(); // the extras look every frame too
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		let shown = scope Shown(page);
		let inspector = page.Inspector;

		// An entity selected: the inspector looks at it every frame.
		page.EditContext.EntitySelection.Set(bed.Crate);
		Settle(page, bed, shown);
		Frame(page, bed, shown);
		Test.Assert(!Waiting(shown), "the inspector found nothing new, so nothing is laid out again");

		let scene = page.ScenePtr;
		let crate = scene.FindEntity(bed.Crate);
		var moved = scene.GetLocalTransform(crate);
		moved.Position.X = 12.5f; // moved from outside the inspector (a gizmo's drag, a simulation)
		scene.SetLocalTransform(crate, moved);
		Frame(page, bed, shown);
		Test.Assert(Waiting(shown), "the grid heard of it and shows it");
		shown.Root.UpdateLayout();
		var shownX = inspector.Grid.ReadPropertyValue(inspector.PathOf("Transform", "Position.x", .. scope String()), .Float);
		defer shownX.Dispose();
		Test.Assert(Math.Abs(shownX.Value.AsFloat - 12.5) < 1e-4);

		// The scene selected: its settings, and their extras (the physics block's collision groups),
		// are looked at every frame the same way.
		shown.Click(page.Hierarchy.Tree, 0);
		Settle(page, bed, shown);
		let rows = scope List<Sedulous.GUI.PropertyInfo>();
		defer { ClearAndDeleteItems!(rows); }
		inspector.Sections.GetProperties("", rows);
		var groups = false;
		for (let row in rows)
			groups = groups || (row.DisplayName == "Collision Groups");
		Test.Assert(groups, "the extras show");
		Frame(page, bed, shown);
		Test.Assert(!Waiting(shown));
		page.OnClose();
	}

	// One frame of the page, the sheet over what it changed.
	private static void Frame(SceneEditorPage page, Bed bed, Shown shown)
	{
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		shown.Restyle();
	}

	// A few frames, each laid out.
	private static void Settle(SceneEditorPage page, Bed bed, Shown shown)
	{
		for (int i < 4)
		{
			Frame(page, bed, shown);
			shown.Root.UpdateLayout();
		}
	}

	// Whether anything waits to be laid out again.
	private static bool Waiting(Shown shown) => shown.Root.IsLayoutDirty || shown.Root.HasLayoutDirtyDescendant;

	[Test]
	public static void InspectorSeveralEntitiesEditedAtOnceAComponentsHeaderHasItsVerbsReadOnlyWhileThePageSimulates()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		let inspector = page.Inspector;
		let lamp = page.EditContext.CreateEntity("Lamp");
		Guid[2] both = .(bed.Crate, lamp);
		page.EditContext.EntitySelection.Set(Span<Guid>(&both[0], 2));
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(inspector.Kind == "2 entities");
		Test.Assert(inspector.AddComponent("LightComponent")); // to both
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(TitlesAre(inspector, "Entity | Transform | Light"));
		let intensity = inspector.PathOf("Light", "Intensity", .. scope String());
		Commit(page, bed, intensity, 3.0);
		Test.Assert(LightOf(page, lamp).Intensity == 3.0f);
		Test.Assert(LightOf(page, bed.Crate).Intensity == 3.0f);

		// The header's verbs: Remove Component takes it from both, one undo brings it back.
		scope Shown(page); // the page under the editor's sheet until the test ends
		Test.Assert(inspector.OpenHeaderMenu("#Light"));
		let menu = inspector.Grid.RowMenu;
		Test.Assert(menu != null);
		Sedulous.GUI.MenuItem remove = null;
		for (int i < menu.ChildCount)
		{
			if (let item = menu.GetChildAt(i) as Sedulous.GUI.MenuItem)
			{
				if (item.Text == "Remove Component")
					remove = item;
			}
		}
		Test.Assert(remove != null);
		remove.HandleActivate();
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(TitlesAre(inspector, "Entity | Transform"));
		page.Commands.Undo();
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(TitlesAre(inspector, "Entity | Transform | Light"));

		// Simulating: read only, and said.
		page.StartSimulation();
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(inspector.Sections.ReadOnly);
		Test.Assert(FindId<Node>(page.Content, "inspector-note").Displayed);
		let addComponent = FindId<Sedulous.GUI.Button>(page.Content, "inspector-add");
		Test.Assert(addComponent != null);
		Test.Assert(!addComponent.Enabled, "Add Component is off too, not refused without a word");
		let write = PropertyWrite(Sedulous.GUI.Variant(5.0));
		inspector.Sections.BeginEdit(intensity);
		inspector.Sections.CommitEdit(intensity, write);
		Test.Assert(LightOf(page, lamp).Intensity == 3.0f);
		page.StopSimulation();
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(!inspector.Sections.ReadOnly);
		Test.Assert(addComponent.Enabled);
		page.OnClose();
	}

	[Test]
	public static void InspectorAnEntityReferenceIsASlotOverTheScenesEntitiesItsNameAPickFromTheEntityPickerADraggedEntityOneUndoEach()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		let inspector = page.Inspector;
		let lamp = page.EditContext.CreateEntity("Lamp");
		page.EditContext.EntitySelection.Set(bed.Crate);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(inspector.AddComponent("InstanceMemberComponent"));
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		let shown = scope Shown(page);
		let path = inspector.PathOf("Instance Member", "InstancedMesh", .. scope String());
		Test.Assert(!path.IsEmpty);
		var slot = inspector.Grid.FindEditor(path) as EntityRefEditor;
		Test.Assert(slot != null); // the entity slot, not the asset one
		Test.Assert(slot.Slot.ShownName == "Not set");

		// The pick: the entity picker, the scene as the hierarchy shows it; a search keeps a match.
		let before = page.Commands.UndoIndex;
		Test.Assert(page.PickEntity(slot.Request()));
		let picker = page.EntityPicker;
		Test.Assert(picker != null);
		Test.Assert(picker.IsOpen);
		Test.Assert(picker.Rows(.. scope .()) == page.Hierarchy.Rows(.. scope .()), "the same tree");
		Test.Assert(picker.Rows(.. scope .()) == "Level |   Crate |   Lamp");
		Test.Assert(picker.LitName(.. scope .()).IsEmpty, "nothing current");
		Test.Assert(picker.Hint == "Enter picks, Esc closes");
		picker.Step(-1); // the scene's row: no pick
		picker.PickLit();
		Test.Assert(picker.IsOpen);
		picker.Search("la");
		Test.Assert(picker.Rows(.. scope .()) == "Level |   Lamp");
		Test.Assert(picker.LitName(.. scope .()) == "Lamp", "the first match");
		picker.Search("nothing like it");
		Test.Assert(picker.State == "No entity matches \"nothing like it\".");
		picker.Search("la");
		picker.PickLit();
		Test.Assert(!picker.IsOpen);
		Test.Assert(page.Commands.UndoIndex > before);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		shown.Root.UpdateLayout();
		let manager = page.EditContext.FindManager(typeof(InstanceMemberComponent));
		Test.Assert(manager != null);
		InstanceMemberComponent* Member() => (InstanceMemberComponent*)manager.GetComponentAddress(page.ScenePtr.FindEntity(bed.Crate));
		Test.Assert(Member().InstancedMesh.Id == lamp);
		slot = inspector.Grid.FindEditor(path) as EntityRefEditor;
		Test.Assert(slot != null);
		Test.Assert(slot.Slot.ShownName == "Lamp");
		// Again: the current entity lit, the foot saying Esc keeps it; its close writes nothing (no
		// None to slip onto: the slot's own clear sets nothing).
		let picked = page.Commands.UndoIndex;
		Test.Assert(page.PickEntity(slot.Request()));
		Test.Assert(picker.LitName(.. scope .()) == "Lamp");
		Test.Assert(picker.Hint == "Enter picks, Esc keeps Lamp");
		Test.Assert(picker.CloseButton != null);
		Test.Assert(picker.CloseButton.HandleActivate());
		Test.Assert(!picker.IsOpen);
		Test.Assert(page.Commands.UndoIndex == picked);
		page.Commands.Undo(); // one step (the index counts a group's markers too)
		Test.Assert(page.Commands.UndoIndex == before);
		Test.Assert(Member().InstancedMesh.IsNil);

		// A dragged entity, as from the hierarchy; a clear.
		let dragged = scope DragPayload();
		Guid[1] crate = .(bed.Crate);
		EntityDrag.Payload(crate, "Crate", dragged);
		Test.Assert(slot.Take(dragged));
		Test.Assert(Member().InstancedMesh.Id == bed.Crate);
		slot.Assign(.Empty);
		Test.Assert(Member().InstancedMesh.IsNil);
		page.OnClose();
	}

	[Test]
	public static void InspectorABoneNamePicksFromTheSkeletonOfTheAnimatorAboveANameItLacksSaidSoWithNoneText()
	{
		// Before the page: the scene borrows it until the page goes.
		let skeleton = scope Sedulous.Animation.Skeleton(3);
		StringView[3] names = .("Thigh", "Shin", "Foot");
		for (int32 i < 3)
		{
			let bone = skeleton.Bones[i];
			bone.Index = i;
			bone.Name.Set(names[i]);
			bone.ParentIndex = i - 1;
		}
		skeleton.BuildNameMap();
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		let inspector = page.Inspector;
		let edit = page.EditContext;
		let scene = page.ScenePtr;
		let rider = edit.CreateEntity("Rider");
		let leg = edit.CreateEntity("LegIk", rider);
		let clips = scene.GetSystem<SkeletalAnimationComponentManager>();
		let legs = scene.GetSystem<TwoBoneIkComponentManager>();
		Test.Assert((clips != null) && (legs != null));
		clips.Add(scene.FindEntity(rider)).Skeleton.SetDirect(skeleton);
		let added = legs.Add(scene.FindEntity(leg));
		if (added.MidBone == null)
			added.MidBone = new String();
		added.MidBone.Set("Knee");
		TwoBoneIkComponent* Live() => legs.Get(scene.FindEntity(leg));

		edit.EntitySelection.Set(leg);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		let shown = scope Shown(page);
		let startPath = inspector.PathOf("Two Bone IK", "StartBone", .. scope String());
		Test.Assert(!startPath.IsEmpty);
		let start = inspector.Grid.FindEditor(startPath) as BoneNameEditor;
		Test.Assert(start != null);
		Test.Assert(start.ListsBones);
		let choices = start.ComboBox;
		Test.Assert(choices.ItemCount == 4);
		Test.Assert(choices.ItemsText == "(none)|Thigh|Shin|Foot");
		Test.Assert(choices.SelectedIndex == 0);
		let before = page.Commands.UndoIndex;
		choices.SelectByUser(1);
		Test.Assert((Live().StartBone != null) && (Live().StartBone == "Thigh"));
		Test.Assert(page.Commands.UndoIndex > before); // one step (the index counts a group's markers too)
		page.Commands.Undo();
		Test.Assert(page.Commands.UndoIndex == before);
		Test.Assert((Live().StartBone == null) || Live().StartBone.IsEmpty);

		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		shown.Root.UpdateLayout();
		let mid = inspector.Grid.FindEditor(inspector.PathOf("Two Bone IK", "MidBone", .. scope String())) as BoneNameEditor;
		Test.Assert(mid != null);
		Test.Assert(mid.ComboBox.ItemCount == 5);
		Test.Assert(mid.ComboBox.ItemsText.EndsWith("|Knee (not in the skeleton)"));
		Test.Assert(mid.ComboBox.SelectedIndex == 4);

		// With no animator above, the text field.
		let stray = edit.CreateEntity("Stray");
		legs.Add(scene.FindEntity(stray));
		edit.EntitySelection.Set(stray);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		shown.Root.UpdateLayout();
		let text = inspector.Grid.FindEditor(inspector.PathOf("Two Bone IK", "StartBone", .. scope String())) as BoneNameEditor;
		Test.Assert(text != null);
		Test.Assert(!text.ListsBones);
		page.OnClose();
	}

	[Test]
	public static void SceneBarTheAnimationPanelsToggleShowsItCheckedWhileItShows()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		let shown = scope Shown(page);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		let animation = FindId<ButtonBase>(page.Content, "scene-animation-panel");
		Test.Assert(animation != null);
		Test.Assert(!animation.Checked);
		shown.Click(animation);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(page.AnimationPanelShown);
		Test.Assert(animation.Checked);
		shown.Click(animation);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(!page.AnimationPanelShown);
		page.OnClose();
	}

	[Test]
	public static void TheAnimationPanelBindsAnEntityPickedFromTheSceneAClipOpenedWhileThePageShowsGoesIntoIt()
	{
		let bed = scope Bed();
		PropertyAnimationPipeline.RegisterAll();
		let clip = PropertyAnimationCreators.CreateClip(bed.Project.SourceDb.RootGroup, "Swing");
		Test.Assert(clip != null);
		let page = bed.Open(bed.Level);
		defer delete page;
		let panel = page.AnimationPanel;
		Test.Assert(panel != null);
		let door = page.EditContext.CreateEntity("Door");
		page.OnUpdate(bed.Host, 1.0f / 60.0f);

		// Off screen, a clip's open is not the page's: it opens as an asset would.
		Test.Assert(!page.IsOnScreen);
		Test.Assert(!bed.Context.TryInterceptOpenAsset(clip));

		scope Shown(page); // the page under the editor's sheet until the test ends
		Test.Assert(page.IsOnScreen);
		page.EditContext.EntitySelection.Set(bed.Crate);
		Test.Assert(bed.Context.TryInterceptOpenAsset(clip));
		Test.Assert(page.AnimationPanelShown);
		Test.Assert(panel.Document.ClipId == clip.Id);
		Test.Assert(panel.BoundEntity == bed.Crate); // the selection, as Edit Clip binds it
		Test.Assert(!bed.Context.TryInterceptOpenAsset(bed.Barrel)); // a prefab is not a clip

		// Pick: the entity picker, the bound entity lit; a pick binds, None keeps it.
		panel.PickEntity();
		let picker = page.EntityPicker;
		Test.Assert(picker != null);
		Test.Assert(picker.IsOpen);
		Test.Assert(picker.LitName(.. scope .()) == "Crate");
		picker.Search("door");
		picker.PickLit();
		Test.Assert(panel.BoundEntity == door);
		page.OnClose();
		Test.Assert(!bed.Context.TryInterceptOpenAsset(clip)); // closed: it let go
	}

	[Test]
	public static void InspectorPasteComponentPutsTheCopiedComponentOnTheSelectionOneUndoOverOneItHasItAsksFirst()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		let inspector = page.Inspector;
		let edit = page.EditContext;
		let lamp = edit.CreateEntity("Lamp");
		edit.EntitySelection.Set(bed.Crate);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(inspector.AddComponent("InstanceMemberComponent"));
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		scope Shown(page); // the page under the editor's sheet until the test ends
		Test.Assert(!inspector.CanPasteComponent); // nothing copied
		let blob = scope List<uint8>();
		edit.CopyComponent(bed.Crate, typeof(InstanceMemberComponent), blob);
		Test.Assert(!blob.IsEmpty);
		bed.Context.CopyToEditorClipboard("component", blob, "component");

		// Onto an entity without one: pasted at once, one step.
		edit.EntitySelection.Set(lamp);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(inspector.CanPasteComponent);
		let scene = page.ScenePtr;
		let manager = edit.FindManager(typeof(InstanceMemberComponent));
		Test.Assert(manager != null);
		Test.Assert(!manager.HasComponent(scene.FindEntity(lamp)));
		let before = page.Commands.UndoIndex;
		Test.Assert(inspector.PasteComponent());
		Test.Assert(inspector.PasteConfirm == null);
		Test.Assert(manager.HasComponent(scene.FindEntity(lamp)));
		page.Commands.Undo(); // one step (the index counts a group's markers too)
		Test.Assert(page.Commands.UndoIndex == before);
		Test.Assert(!manager.HasComponent(scene.FindEntity(lamp)));

		// Onto one that has it: asked; Cancel leaves it, Overwrite pastes.
		edit.EntitySelection.Set(bed.Crate);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		let asked = page.Commands.UndoIndex;
		Test.Assert(inspector.PasteComponent());
		Test.Assert(inspector.PasteConfirm != null);
		Test.Assert(page.Commands.UndoIndex == asked); // nothing yet
		inspector.PasteConfirm.Close();
		Test.Assert(inspector.PasteComponentNow());
		Test.Assert(page.Commands.UndoIndex > asked);
		page.Commands.Undo(); // one step
		Test.Assert(page.Commands.UndoIndex == asked);
		page.OnClose();
	}

	[Test]
	public static void InspectorAComponentsExtrasUnderItsHeaderARigidBodysNoticeWhileItHasNoColliderAZonesBake()
	{
		BuiltinInspectorExtras.Register();
		let bed = scope Bed();
		let said = scope String();
		bed.Context.OnNotice = new [&] (kind, message) => { said.Set(message); };
		let page = bed.Open(bed.Level);
		defer delete page;
		let inspector = page.Inspector;
		page.EditContext.EntitySelection.Set(bed.Crate);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(inspector.AddComponent("RigidBodyComponent"));
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(inspector.ExtraText("Rigid Body", "Collision", .. scope String()).IsEmpty); // a box: it has its collider

		// Cooked with no shape: said, and gone again once it is a box (a value edit, not a rebuild).
		let bodies = page.ScenePtr.GetSystem<RigidBodyComponentManager>();
		Test.Assert(bodies != null);
		bodies.Get(page.ScenePtr.FindEntity(bed.Crate)).Shape = .Cooked;
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(inspector.ExtraText("Rigid Body", "Collision", .. scope String()) == BuiltinInspectorExtras.cNoColliderText);
		bodies.Get(page.ScenePtr.FindEntity(bed.Crate)).Shape = .Box;
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(inspector.ExtraText("Rigid Body", "Collision", .. scope String()).IsEmpty);

		// A zone's Bake: its button, and with no asset assigned it says what to do.
		Test.Assert(inspector.AddComponent("NavMeshZoneComponent"));
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(inspector.ExtraText("Nav Mesh Zone", "Navigation", .. scope String()) == "Bake Navigation");
		Test.Assert(inspector.RunExtra("Nav Mesh Zone", "Navigation"));
		Test.Assert(said == "Assign a Navigation Zone asset to this zone before baking.");
		page.OnClose();
	}

	[Test]
	public static void ScriptBehaviorsAListOfBehavioursEachItsScriptEnabledAndIntervalEveryEditOneUndoStepARevertItsDefault()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		let edit = page.EditContext;
		edit.AddComponent(bed.Crate, typeof(ScriptComponent));
		Guid[1] crate = .(bed.Crate);
		let source = scope ScriptBehaviorsSource(edit, bed.Context, crate);
		let manager = page.ScenePtr.GetSystem<ScriptComponentManager>();
		Test.Assert(manager != null);
		ScriptComponent* Component() => manager.Get(page.ScenePtr.FindEntity(bed.Crate));

		let top = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(top); }
		source.GetProperties(default, top);
		Test.Assert(top.Count == 1);
		Test.Assert(top[0].Kind == .List);
		Test.Assert(source.GetValue("behaviors", 0).AsInt == 0);

		let insert = scope ListEdit();
		insert.Kind = .Insert;
		insert.Index = 0;
		Test.Assert(source.EditList("behaviors", insert));
		Test.Assert(Component().Behaviors.Count == 1);
		let elements = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(elements); }
		source.GetProperties("behaviors", elements);
		Test.Assert(elements.Count == 1);
		Test.Assert(elements[0].DisplayName == "Behavior 1");
		let rows = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(rows); }
		source.GetProperties("behaviors.0", rows);
		Test.Assert(rows.Count == 3); // no script yet: its own rows only
		Test.Assert(rows[0].Kind == .Reference);
		Test.Assert(rows[0].ReferenceType == typeof(ScriptClass));
		// By its name, what the asset picker asks the builders for.
		Test.Assert(rows[0].ReferenceType.GetName(.. scope .()) == "ScriptClass");

		source.CommitEdit("behaviors.0.enabled", PropertyWrite(Sedulous.GUI.Variant(false)));
		Test.Assert(!Component().Behaviors[0].Enabled);
		source.CommitEdit("behaviors.0.interval", PropertyWrite(Sedulous.GUI.Variant(0.5)));
		Test.Assert(Component().Behaviors[0].UpdateInterval == 0.5f);
		page.Commands.Undo(); // the interval alone
		Test.Assert(Component().Behaviors[0].UpdateInterval == 0.0f);
		Test.Assert(!Component().Behaviors[0].Enabled);
		Test.Assert(source.Revert("behaviors.0.enabled"));
		Test.Assert(Component().Behaviors[0].Enabled);
		page.Commands.Undo(); // the revert
		page.Commands.Undo(); // the edit
		Test.Assert(Component().Behaviors[0].Enabled);
		page.Commands.Undo(); // the insert
		Test.Assert(Component().Behaviors.IsEmpty);
		page.OnClose();
	}

	[Test]
	public static void InspectorTheSceneSelectedShowsItsSettingsABlockASectionAnEditLandsInTheScenesBlockOneUndoStep()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		let inspector = page.Inspector;
		let shown = scope Shown(page);
		shown.Click(page.Hierarchy.Tree, 0); // the scene's row
		Test.Assert(page.Hierarchy.SceneSelected);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(inspector.Kind == "Scene");
		Test.Assert(FindId<TextField>(page.Content, "inspector-name").Text == "Level");
		Test.Assert(!FindId<Node>(page.Content, "inspector-add").Displayed); // no components to add
		let environment = inspector.SettingsOf("Environment");
		Test.Assert(environment != null);

		let system = page.EditContext.FindSystemBySettingsType(typeof(EnvironmentSettings));
		Test.Assert(system != null);
		float Turbidity() => ((EnvironmentSettings*)page.EditContext.SettingsEditTarget(typeof(EnvironmentSettings), .Empty)).Turbidity;
		let before = Turbidity();
		environment.BeginEdit("Turbidity");
		environment.CommitEdit("Turbidity", PropertyWrite(Sedulous.GUI.Variant(7.5)));
		Test.Assert(Turbidity() == 7.5f);
		page.Commands.Undo();
		Test.Assert(Turbidity() == before);
		page.Commands.Redo();
		Test.Assert(Turbidity() == 7.5f);

		// A block that can use a profile offers to make one while it uses its own values.
		if (system.SettingsProfileType != null)
		{
			Test.Assert(inspector.ShowsProfileAction("Environment", "Make Profile"));
			Test.Assert(!inspector.ShowsProfileAction("Environment", "Open Profile"));
		}

		// An entity selected again: its inspector, not the scene's.
		page.EditContext.EntitySelection.Set(bed.Crate);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(inspector.Kind == "Entity");
		page.OnClose();
	}

	[Test]
	public static void InspectorThePhysicsBlocksCollisionGroupsDefaultFirstANewGroupCollidesWithAllAPairBothWaysOnlyTheLastRemoved()
	{
		BuiltinInspectorExtras.Register(); // the groups block is an extra; run alone, nothing else registered it
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		let inspector = page.Inspector;
		let shown = scope Shown(page);
		shown.Click(page.Hierarchy.Tree, 0); // the scene's row
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		let groups = inspector.ExtraSource("Physics", 0);
		Test.Assert(groups != null);
		Test.Assert(!inspector.PathOf("Physics", "groups", .. scope String()).IsEmpty);
		PhysicsSceneSettings Settings() => (PhysicsSceneSettings)Internal.UnsafeCastToObject(page.EditContext.FindSystemBySettingsType(typeof(PhysicsSceneSettings)).SettingsInstance);
		int64 IntOf(StringView path) => groups.GetValue(path, 0).AsInt;

		// None stored: one, Default.
		Test.Assert(IntOf("groups") == 1);
		var name = groups.GetValue("groups.0.name", 0);
		Test.Assert(name.AsString == "Default");
		name.Dispose();
		let add = scope ListEdit();
		add.Kind = .Insert;
		add.Index = 0; // at the end whatever the place
		Test.Assert(groups.EditList("groups", add));
		Test.Assert(Settings().GroupNames.Count == 2);
		Test.Assert(Settings().GroupNames[0] == "Default");
		Test.Assert(Settings().GroupNames[1] == "Group 1");
		Test.Assert(IntOf("groups.1.collides") == 3);
		let rows = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(rows); }
		groups.GetProperties("groups.1", rows);
		Test.Assert(rows.Count == 1, "its name; which pairs collide is the matrix's");
		Test.Assert(rows[0].Name == "name");
		ClearAndDeleteItems!(rows);
		groups.GetProperties("", rows);
		Test.Assert(rows.Count == 2);
		Test.Assert(rows[1].Hint == "CollisionMatrix");
		Test.Assert(IntOf("matrix") == 2);

		// The grid: a row and a column a group, a box at each pair; a click is the pair's write.
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		let matrixPath = inspector.PathOf("Physics", "matrix", .. scope String());
		Test.Assert(!matrixPath.IsEmpty);
		let matrixRow = inspector.Grid.FindRow(matrixPath);
		Test.Assert(matrixRow >= 0);
		inspector.Grid.ScrollToItem(matrixRow); // under the fold
		shown.Root.UpdateLayout();
		let matrix = inspector.Grid.FindEditor(matrixPath) as CollisionMatrixEditor;
		Test.Assert(matrix != null);
		Test.Assert(matrix.Count == 2);
		// Its grid row is as tall as the headers and a line per group, so the last line's boxes lie
		// in the row, not over the rows below it.
		Test.Assert(matrix.Parent != null);
		let rowBounds = matrix.Parent.ScreenBounds;
		Test.Assert(rowBounds.Height >= 3.0f * CollisionMatrixEditor.cCell, scope $"{rowBounds.Height}");
		Test.Assert(matrix.Box(1, 1) != null);
		let lastBox = matrix.Box(1, 1).ScreenBounds;
		Test.Assert(lastBox.Y + lastBox.Height <= rowBounds.Y + rowBounds.Height + 0.5f);
		Test.Assert(matrix.Box(1, 0) != null);
		Test.Assert(matrix.Box(0, 1) == null, "above the diagonal: the same pair as (1, 0)");
		Test.Assert(matrix.Box(1, 0).Checked);
		Test.Assert(matrix.Box(1, 0).HandleActivate()); // off: both ways
		Test.Assert((Settings().GroupCollides[1] & 1) == 0);
		Test.Assert((Settings().GroupCollides[0] & 2) == 0);
		page.Commands.Undo();
		Test.Assert((Settings().GroupCollides[1] & 1) != 0);

		// Group 1 no longer collides with Default: both rows say so.
		var off = PropertyWrite(Sedulous.GUI.Variant((int64)2));
		off.Mask = 1;
		groups.CommitEdit("groups.1.collides", off);
		Test.Assert((Settings().GroupCollides[1] & 1) == 0);
		Test.Assert((Settings().GroupCollides[0] & 2) == 0);
		Test.Assert(IntOf("groups.0.collides") == 1);
		groups.CommitEdit("groups.1.name", PropertyWrite(Sedulous.GUI.Variant("Players")));
		Test.Assert(Settings().GroupNames[1] == "Players");
		page.Commands.Undo(); // the rename alone
		Test.Assert(Settings().GroupNames[1] == "Group 1");
		Test.Assert((Settings().GroupCollides[0] & 2) == 0);

		// Only the last: the others keep their bodies' indices.
		let remove = scope ListEdit();
		remove.Kind = .Remove;
		remove.Index = 0;
		Test.Assert(!groups.EditList("groups", remove));
		remove.Index = 1;
		Test.Assert(groups.EditList("groups", remove));
		Test.Assert(IntOf("groups") == 1);
		// With one group fewer, the row is a line shorter.
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		inspector.Grid.ScrollToItem(inspector.Grid.FindRow(matrixPath));
		shown.Root.UpdateLayout();
		let shorter = inspector.Grid.FindEditor(matrixPath) as CollisionMatrixEditor;
		Test.Assert(shorter != null);
		Test.Assert(shorter.Count == 1);
		let shorterHeight = shorter.Parent.ScreenBounds.Height;
		Test.Assert(shorterHeight < rowBounds.Height - CollisionMatrixEditor.cCell * 0.5f, scope $"{shorterHeight}");
		remove.Index = 0;
		Test.Assert(!groups.EditList("groups", remove)); // Default stays
		page.Commands.Undo(); // the remove
		Test.Assert(IntOf("groups") == 2);

		// The physics world's cap: the list says its most, and an add past it is refused.
		ClearAndDeleteItems!(rows);
		groups.GetProperties("", rows);
		Test.Assert(rows[0].MaxCount == (uint32)Sedulous.Physics.PhysicsWorldSettings.CollisionGroupCount);
		while (IntOf("groups") < Sedulous.Physics.PhysicsWorldSettings.CollisionGroupCount)
			Test.Assert(groups.EditList("groups", add));
		Test.Assert(!groups.EditList("groups", add));
		Test.Assert(IntOf("groups") == Sedulous.Physics.PhysicsWorldSettings.CollisionGroupCount);
		page.OnClose();
	}

	[Test]
	public static void LevelScriptTheLevelClasssPropertiesAsRowsAnEditAnOverrideOnTheScenesBlockOneUndoStepARevertDropsIt()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		let edit = page.EditContext;
		SceneScriptSettings Settings() => (SceneScriptSettings)Internal.UnsafeCastToObject(edit.FindSystemBySettingsType(typeof(SceneScriptSettings)).SettingsInstance);
		let source = scope LevelScriptSource(edit, bed.Context);
		let none = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(none); }
		source.GetProperties(default, none);
		Test.Assert(none.IsEmpty); // no Level class: nothing to author

		let level = scope ScriptClass();
		level.ClassName.Set("Level");
		let speed = new ScriptPropertyDesc();
		speed.Name.Set("speed");
		speed.Hash = 41;
		speed.Type = .Float;
		speed.Default = ScriptPropertyValue.Float(2.0);
		level.Properties.Add(speed);
		let spawn = new ScriptPropertyDesc();
		spawn.Name.Set("spawn");
		spawn.Hash = 42;
		spawn.Type = .Vec3;
		spawn.Default = ScriptPropertyValue.Vec3(.(0, 0, 0));
		level.Properties.Add(spawn);
		Settings().Script.SetDirect(level);
		source.Refresh();

		let rows = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(rows); }
		source.GetProperties(default, rows);
		Test.Assert(rows.Count == 2);
		Test.Assert(rows[0].DisplayName == "speed");
		Test.Assert(rows[0].Kind == .Float);
		Test.Assert(rows[1].Kind == .Group);
		let parts = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(parts); }
		source.GetProperties(rows[1].Name, parts);
		Test.Assert(parts.Count == 3);
		Test.Assert(source.GetValue("p41", 0).AsFloat == 2.0);

		source.CommitEdit("p41", PropertyWrite(Sedulous.GUI.Variant(5.0)));
		Test.Assert(Settings().FindOverride(41) != null);
		Test.Assert(source.GetValue("p41", 0).AsFloat == 5.0);
		source.CommitEdit("p42.y", PropertyWrite(Sedulous.GUI.Variant(3.0)));
		Test.Assert(Settings().FindOverride(42) != null);
		Test.Assert(Settings().FindOverride(42).Value.Vector.Y == 3.0f);
		page.Commands.Undo(); // the part alone
		Test.Assert(Settings().FindOverride(42) == null);
		Test.Assert(Settings().FindOverride(41) != null);
		Test.Assert(source.Revert("p41"));
		Test.Assert(Settings().FindOverride(41) == null);
		Test.Assert(source.GetValue("p41", 0).AsFloat == 2.0);
		page.Commands.Undo(); // the revert
		Test.Assert(Settings().FindOverride(41) != null);
		Settings().Script.SetDirect(null); // the test's class goes before the scene
		page.OnClose();
	}

	[Test]
	public static void SceneBarTheEditingControlsAreThePagesActionsSelectTheSpacesIconSnapAndItsIncrements()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		let shown = scope Shown(page);
		let bar = page.Bar;
		Test.Assert(bar != null);
		Test.Assert(bar.Bound == 16); // save, undo, redo, discard, four transform, space, snap, vertex snap, Simulate's three, frame, the animation panel
		let gizmos = page.Gizmos;
		Test.Assert(gizmos != null);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);

		let select = FindId<ButtonBase>(page.Content, "scene-select");
		let move = FindId<ButtonBase>(page.Content, "scene-move");
		Test.Assert(select != null);
		Test.Assert(move != null);
		Test.Assert(move.Checked);
		Test.Assert(!select.Checked);
		Test.Assert(select.TooltipText == "Select (Q)");
		shown.Click(select);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(!gizmos.HandlesShown);
		Test.Assert(select.Checked);
		Test.Assert(!move.Checked);
		shown.Click(move);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(gizmos.HandlesShown);
		Test.Assert(gizmos.Mode == .Translate);

		// The space's icon is the space it is in.
		let space = FindId<ButtonBase>(page.Content, "scene-space");
		Test.Assert(space != null);
		Test.Assert(space.Icon == "Editor/Icons/world.svg");
		shown.Click(space);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(gizmos.Space == .Local);
		Test.Assert(space.Icon == "Editor/Icons/local.svg");

		// Snap, and its increments: a fixed step, then the grid's cell where the camera is.
		let snap = FindId<ToolMenuButton>(page.Content, "scene-snap");
		Test.Assert(snap != null);
		Test.Assert(!gizmos.SnapMode);
		Test.Assert(bed.Context.Actions.Execute(SceneActionIds.GizmoSnap, page) case .Ok);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(gizmos.SnapMode);
		Test.Assert(snap.Checked);
		bar.PickIncrement(.Rotate, 2);
		Test.Assert(gizmos.Gizmo.RotateSnapDegrees == 45.0f);
		bar.PickIncrement(.Move, 1);
		Test.Assert(gizmos.Gizmo.TranslateSnap == 0.25f);
		Test.Assert(!gizmos.MoveSnapsToGrid);
		bar.PickIncrement(.Move, 5); // the grid's cell
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(gizmos.MoveSnapsToGrid);
		Test.Assert(gizmos.Gizmo.TranslateSnap > 0.0f);
		page.OnClose();
	}

	[Test]
	public static void SceneHudTheChipsSayWhatIsOnAndChangeItTheStatsTheViewGizmoTheZoomReadoutAndTheToolsStatus()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		let shown = scope Shown(page);
		let hud = page.Hud;
		Test.Assert(hud != null);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		let camera = page.ViewportCamera;

		// Projection: the chip names it, an axis view by its name, in the accent off perspective.
		Test.Assert(hud.ChipText("chip-projection") == "Perspective");
		Test.Assert(!hud.ChipOn("chip-projection"));
		hud.SetProjection(.Orthographic);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(camera.Orthographic);
		Test.Assert(hud.ChipText("chip-projection") == "Orthographic");
		Test.Assert(hud.ChipOn("chip-projection"));
		hud.LookAlong(.(0, 1, 0));
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(hud.ChipText("chip-projection") == "Top");

		// Shading: Unlit is the albedo term; a texture names itself; Lit is the default, not marked.
		Test.Assert(hud.ChipText("chip-shading") == "Lit");
		hud.SetShading(.Albedo);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(hud.ChipText("chip-shading") == "Unlit");
		Test.Assert(hud.ChipOn("chip-shading"));
		hud.ShowTexture("ssgi.filtered");
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(hud.ChipText("chip-shading") == "ssgi.filtered");
		hud.SetShading(.Off);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(hud.ChipText("chip-shading") == "Lit");
		Test.Assert(!hud.ChipOn("chip-shading"));

		// The menus are built, their checks following the state.
		Test.Assert(hud.ChipMenu("chip-overlays") != null);
		Test.Assert(!hud.StatsShown);
		page.Overlays.Settings.ShowFps = true;
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(hud.StatsShown);

		// The view gizmo's centre switches the projection; a knob looks along its axis.
		let gizmo = hud.Gizmo;
		Test.Assert(gizmo != null);
		shown.Root.UpdateLayout();
		hud.SetProjection(.Perspective);
		camera.Yaw = 0.3f;
		camera.Pitch = -0.3f;
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		shown.Root.UpdateLayout();
		Test.Assert(gizmo.PressAt(gizmo.Layout.Center));
		Test.Assert(camera.Orthographic);
		let layout = gizmo.Layout;
		var plusX = -1;
		for (int i < 6)
		{
			if (layout.Poles[i].Positive && (layout.Poles[i].Axis.X > 0.5f))
				plusX = i;
		}
		Test.Assert(plusX >= 0);
		Test.Assert(gizmo.PressAt(layout.Poles[plusX].Screen));
		Test.Assert(Dot(camera.Forward, .(-1, 0, 0)) > 0.999f); // looking down -X, from +X

		// The zoom readout shows after a wheel zoom, then fades.
		Test.Assert(!hud.ZoomShown);
		hud.Zoomed();
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(hud.ZoomShown);
		for (int i < 4)
			page.OnUpdate(bed.Host, 1.0f);
		Test.Assert(!hud.ZoomShown);

		// The select tool's status in parts: its mode, space, snap and what is selected.
		page.EditContext.EntitySelection.Set(bed.Crate);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(hud.StatusText(.. scope String()) == "Move | World | Crate");
		page.Gizmos.SnapMode = true;
		page.Gizmos.Gizmo.TranslateSnap = 0.5f;
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(hud.StatusText(.. scope String()) == "Move | World | Snap 0.5 m | Crate");
		page.Gizmos.SetHandlesShown(false);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(hud.StatusText(.. scope String()) == "Select | Crate");
		page.OnClose();
	}

	// Two brushes of one category, one with a panel; the second available only when told.
	class FakeBrush : IViewportTool
	{
		private String mId = new .() ~ delete _;
		private String mName = new .() ~ delete _;
		private bool* mAvailable;

		public this(StringView id, StringView name, bool* available)
		{
			mId.Set(id);
			mName.Set(name);
			mAvailable = available;
		}

		public StringView Id => mId;
		public StringView DisplayName => mName;
		public StringView Category => "Brushes";
		public StringView Icon => "Editor/Icons/cube.svg";
		public bool IsAvailable => (mAvailable == null) || *mAvailable;
		public StringView UnavailableReason => "Paint needs something to paint.";
		public void OnActivate() {}
		public void OnDeactivate() {}
		public bool Update(in ViewportToolInput input) => false;
		public void Draw(DebugDraw drawList) {}
		public StringView StatusText => "";
	}

	static bool sPaintAvailable = false;

	class FakeBrushes : IViewportToolProvider
	{
		public void CreateTools(ViewportToolManager manager, in ViewportToolHostContext context)
		{
			manager.Add(new FakeBrush("test.sculpt", "Sculpt", null));
			manager.Add(new FakeBrush("test.paint", "Paint", &sPaintAvailable));
		}
	}

	class FakeSculptPanel : IViewportToolPanelProvider
	{
		public StringView ToolId => "test.sculpt";

		public Node CreatePanel(IViewportTool tool, in ViewportToolHostContext context)
		{
			let body = new Panel();
			let radius = new Label();
			radius.Text = "Radius";
			body.AddChild(radius);
			radius.ReleaseRef(); // the body's keeps it
			return body;
		}
	}

	static FakeBrushes sBrushes = new .() ~ delete _;
	static FakeSculptPanel sSculptPanel = new .() ~ delete _;

	[Test]
	public static void SceneToolsEachToolAnActionAndOnTheBarByCategoryItsPanelUnderTheChipsMovedKeptPutBack()
	{
		ViewportToolProviderRegistry.Register(sBrushes);
		ViewportToolPanelRegistry.Global.Register(sSculptPanel);
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		let shown = scope Shown(page);
		let tools = page.ToolsView;
		Test.Assert(tools != null);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);

		// The actions: Paint disabled, saying why.
		let actions = bed.Context.Actions;
		let sculpt = SceneTools.ActionOf("test.sculpt", .. scope String());
		let paint = SceneTools.ActionOf("test.paint", .. scope String());
		Test.Assert(actions.Find(sculpt) != null);
		Test.Assert(actions.Find(sculpt).MenuPath == "Scene/Tools/Brushes/Sculpt");
		Test.Assert(actions.IsEnabled(sculpt, page));
		Test.Assert(!actions.IsEnabled(paint, page));
		Test.Assert(actions.DisabledReason(paint, page, .. scope String()) == "Paint needs something to paint.");

		// On the bar: the category one menu, its items as the actions are.
		let category = tools.CategoryButton("Brushes");
		Test.Assert(category != null);
		Test.Assert(category.Icon == "Editor/Icons/cube.svg");
		Test.Assert(!category.Checked);

		// Sculpt on: the category lit, its panel under the chips in the tool's chrome.
		Test.Assert(actions.Execute(sculpt, page) case .Ok);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(category.Checked);
		Test.Assert(actions.IsChecked(sculpt, page));
		Test.Assert(tools.Panel != null);
		Test.Assert(tools.PanelTitle == "Sculpt");
		Test.Assert(!tools.Place.HasValue);

		// Under the chips until moved; dragged by its head anywhere in the view, kept inside it.
		shown.Restyle(); // the panel came after the sheet was applied
		shown.Root.UpdateLayout();
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		shown.Root.UpdateLayout();
		let chips = FindId<Node>(page.Content, "hud-top-start").ScreenBounds;
		let viewport = FindId<Node>(page.Content, "scene-viewport").ScreenBounds;
		let under = Float2(tools.Panel.ScreenBounds.X - viewport.X, tools.Panel.ScreenBounds.Y - viewport.Y);
		Test.Assert(Math.Abs(tools.Panel.ScreenBounds.Y - (chips.Y + chips.Height)) < 0.5f); // under the chips
		let head = tools.Head;
		Test.Assert(head != null);
		let bounds = head.ScreenBounds;
		let grab = Float2(bounds.X + 10.0f, bounds.Y + bounds.Height * 0.5f);
		let d = shown.Root.EventDispatcher;
		d.InjectMouseMove(grab);
		d.InjectMouseDown(grab, .Left);
		d.InjectMouseMove(grab + Float2(120.0f, 80.0f));
		d.InjectMouseUp(grab + Float2(120.0f, 80.0f), .Left);
		Test.Assert(tools.Place.HasValue);
		let place = tools.Place.Value;
		Test.Assert(Math.Abs(place.X - (under.X + 120.0f)) < 0.5f);
		Test.Assert(Math.Abs(place.Y - (under.Y + 80.0f)) < 0.5f);
		d.InjectMouseDown(grab + Float2(120.0f, 80.0f), .Left);
		d.InjectMouseMove(grab + Float2(-5000.0f, 9000.0f)); // far outside: kept inside the view
		d.InjectMouseUp(grab + Float2(-5000.0f, 9000.0f), .Left);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		shown.Root.UpdateLayout();
		Test.Assert(tools.Place.HasValue);
		Test.Assert(Math.Abs(tools.Place.Value.X) < 0.5f);
		let pane = FindId<Node>(page.Content, "scene-viewport").Size;
		Test.Assert(tools.Place.Value.Y <= pane.Y - tools.Panel.Size.Y + 0.5f);

		// Folded to its head, and back.
		tools.SetFolded(true);
		Test.Assert(tools.Folded);
		tools.SetFolded(false);

		// Put back under the chips: no place.
		tools.SetPlace(null);
		Test.Assert(!tools.Place.HasValue);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		shown.Root.UpdateLayout();
		Test.Assert(Math.Abs(tools.Panel.ScreenBounds.X - viewport.X - under.X) < 0.5f);

		// Sculpt again: back to Select, no panel. Paint refused while unavailable, then taken.
		Test.Assert(actions.Execute(sculpt, page) case .Ok);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(tools.Panel == null);
		Test.Assert(!category.Checked);
		sPaintAvailable = true;
		Test.Assert(actions.Execute(paint, page) case .Ok);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(actions.IsChecked(paint, page));
		Test.Assert(tools.Panel == null); // Paint has no panel
		sPaintAvailable = false;
		page.OnClose();
	}

	// A mesh for any instance: what the inspector's mesh slot binds to.
	class AnyMesh : Sedulous.Resource.IResourceFactory
	{
		public uint64 ProductTypeId => Sedulous.Resource.ResourceManager.ProductTypeIdOf<Sedulous.Geometry.StaticMesh>();
		public Type CookedType => typeof(Sedulous.Geometry.StaticMesh);
		public Object Create(Sedulous.Resource.ResourceManager manager, Instance instance) => new Sedulous.Geometry.StaticMesh();
	}

	[Test]
	public static void InspectorAReferenceSetInTheGridBindsAtOnceItsUndoLetsItGo()
	{
		let bed = scope Bed();
		let factory = scope AnyMesh();
		let resources = scope Sedulous.Resource.ResourceManager(bed.Project.SourceDb);
		resources.AddFactory(factory);
		bed.Context.Resources = resources;
		defer { bed.Context.Resources = null; }
		let rock = bed.Project.SourceDb.RootGroup.CreateInstance("Rock", typeof(SceneDocument).GetFullName(.. scope .()));
		Test.Assert(rock != null);
		let page = bed.Open(bed.Level);
		defer delete page;
		let inspector = page.Inspector;
		page.EditContext.AddComponent(bed.Crate, typeof(MeshComponent));
		page.EditContext.EntitySelection.Set(bed.Crate);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		let meshes = page.ScenePtr.GetSystem<MeshComponentManager>();
		Test.Assert(meshes != null);
		MeshComponent* Mesh() => meshes.Get(page.ScenePtr.FindEntity(bed.Crate));
		Test.Assert(Mesh().Mesh.Get == null);

		let path = inspector.PathOf("Mesh", "Mesh", .. scope String());
		Test.Assert(!path.IsEmpty);
		let id = rock.Id.ToString(.. scope String());
		inspector.Sections.BeginEdit(path);
		inspector.Sections.CommitEdit(path, PropertyWrite(Sedulous.GUI.Variant(id)));
		Test.Assert(Mesh().Mesh.Id == rock.Id);
		Test.Assert(Mesh().Mesh.Get != null); // bound now: it draws without a reopen
		page.Commands.Undo();
		Test.Assert(Mesh().Mesh.Id.IsNil);
		Test.Assert(Mesh().Mesh.Get == null); // and let go on undo
		page.OnClose();
	}

	[Test]
	public static void InspectorAddComponentsPickerListsEachComponentByItsDisplayNameUnderItsCategoryTheCategoriesTogether()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		page.EditContext.EntitySelection.Set(bed.Crate);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		page.Inspector.OpenAddComponent();
		Test.Assert((bed.Picked != null) && !bed.Picked.Items.IsEmpty);
		let items = bed.Picked.Items;
		PickerItem light = null;
		for (let item in items)
		{
			if (item.Key == "LightComponent")
				light = item;
		}
		Test.Assert(light != null);
		Test.Assert(light.Name == "Light"); // its display name, not its type's name
		Test.Assert(light.Section == "Rendering"); // its category
		Test.Assert(!light.Description.IsEmpty); // its description, for the foot while lit
		Test.Assert(light.Detail.IsEmpty); // not on its row, where a sentence overran the name
		// Each category's rows together, so a section shows once.
		for (int i = 2; i < items.Count; i++)
		{
			if (items[i].Section == items[i - 1].Section)
				continue;
			for (int j = 0; j + 1 < i; j++)
				Test.Assert(items[j].Section != items[i].Section);
		}
		page.OnClose();
	}

	// The first `T` in `node`'s tree, itself first.
	static T FirstOf<T>(Node node) where T : Node
	{
		// One return: with T as Node itself the node always matches, and an early return would
		// leave the loop unreachable in that instance.
		T found = node as T;
		for (int i = 0; (found == null) && (i < node.ChildCount); i++)
			found = FirstOf<T>(node.GetChildAt(i));
		return found;
	}

	[Test]
	public static void InspectorAValueTypedIntoTheGridStaysFramesOnNotPutBack()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		let inspector = page.Inspector;
		let shown = scope Shown(page);
		page.EditContext.AddComponent(bed.Crate, typeof(LightComponent));
		page.EditContext.EntitySelection.Set(bed.Crate);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		shown.Restyle();
		shown.Root.UpdateLayout();

		let grid = inspector.Grid;
		Test.Assert(grid != null);
		let path = inspector.PathOf("Light", "Intensity", .. scope String());
		let item = grid.FindRow(path);
		Test.Assert(item >= 0);
		grid.ScrollToItem(item);
		shown.Root.UpdateLayout();
		let row = grid.RowForItem(item);
		Test.Assert(row != null);
		let field = FirstOf<NumberField>(row);
		Test.Assert(field != null);

		// Typed: click into it, select all, type, Return; then frames go by.
		let d = shown.Root.EventDispatcher;
		let bounds = field.ScreenBounds;
		let at = Float2(bounds.X + bounds.Width * 0.5f, bounds.Y + bounds.Height * 0.5f);
		d.InjectMouseMove(at);
		d.InjectMouseDown(at, .Left);
		d.InjectMouseUp(at, .Left);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		d.InjectKeyDown((uint32)Sedulous.GUI.KeyCode.A, KeyModCtrl);
		d.InjectText("7.5");
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		d.InjectKeyDown((uint32)Sedulous.GUI.KeyCode.Return);
		for (int i < 5)
		{
			page.OnUpdate(bed.Host, 1.0f / 60.0f);
			shown.Root.UpdateLayout();
		}
		Test.Assert(LightOf(page, bed.Crate).Intensity == 7.5f);
		page.OnClose();
	}

	[Test]
	public static void CameraPreviewTheSelectedCamerasViewTitledWithItsNameAtItsAspectAPinKeepsItAStalePinClears()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		let preview = page.CameraPreview;
		Test.Assert(preview != null);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(!preview.IsShown, "no camera selected");

		// A camera selected: shown, titled with it, at its aspect.
		let eye = page.EditContext.CreateEntity("Eye");
		page.EditContext.EntitySelection.Set(eye);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(page.Inspector.AddComponent("CameraComponent"));
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(preview.IsShown);
		Test.Assert(preview.Target == eye);
		Test.Assert(preview.Title == "Eye");
		Test.Assert(preview.PictureSize.X == SceneCameraPreview.cPictureWidth);
		Test.Assert(preview.PictureSize.Y == 109.0f, "16:9");
		let scene = page.ScenePtr;
		let cameras = scene.GetSystem<CameraComponentManager>();
		Test.Assert(cameras != null);
		cameras.Get(scene.FindEntity(eye)).Aspect = 1.0f;
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(preview.PictureSize.Y == SceneCameraPreview.cPictureWidth, "square");

		// Another entity selected: hidden, unless the camera is pinned.
		page.EditContext.EntitySelection.Set(bed.Crate);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(!preview.IsShown);
		page.EditContext.EntitySelection.Set(eye);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		preview.TogglePin();
		Test.Assert(preview.Pinned == eye);
		page.EditContext.EntitySelection.Set(bed.Crate);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(preview.IsShown);
		Test.Assert(preview.Target == eye);
		preview.TogglePin(); // unpinned: the selection's again
		Test.Assert(preview.Pinned.IsNil);
		Test.Assert(!preview.IsShown);
		page.EditContext.EntitySelection.Set(eye);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		preview.TogglePin();

		// The pinned camera deleted: the pin clears and the preview goes.
		page.EditContext.DestroyEntity(eye);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(preview.Pinned.IsNil);
		Test.Assert(!preview.IsShown);
		page.OnClose();
	}

	[Test]
	public static void SceneBarSimulatePauseAndStopAreThePagesActionsItsStateNamedBesideThemWhileItRuns()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Level);
		defer delete page;
		let shown = scope Shown(page);
		let bar = page.Bar;
		Test.Assert(bar != null);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		let simulate = FindId<ButtonBase>(page.Content, "scene-simulate");
		let pause = FindId<ButtonBase>(page.Content, "scene-pause");
		let stop = FindId<ButtonBase>(page.Content, "scene-stop");
		Test.Assert((simulate != null) && (pause != null) && (stop != null));
		Test.Assert(simulate.TooltipText.StartsWith("Simulate"));
		Test.Assert(simulate.Enabled);
		Test.Assert(!pause.Enabled);
		Test.Assert(!stop.Enabled);
		Test.Assert(bar.State.IsEmpty);
		// The buttons are centred beside the state: it keeps its place and one width whatever it
		// says, so they never move as the scene starts, pauses or stops.
		float PauseAt()
		{
			shown.Root.UpdateLayout();
			return pause.ScreenBounds.X;
		}
		let resting = PauseAt();

		shown.Click(simulate);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(page.IsSimulating);
		Test.Assert(bar.State == "Simulating");
		Test.Assert(!simulate.Enabled);
		Test.Assert(stop.Enabled);
		Test.Assert(Math.Abs(PauseAt() - resting) < 1e-3f);
		shown.Click(pause);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(page.IsPaused);
		Test.Assert(bar.State == "Paused");
		Test.Assert(pause.Checked);
		Test.Assert(Math.Abs(PauseAt() - resting) < 1e-3f);
		shown.Click(stop);
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(!page.IsSimulating);
		Test.Assert(bar.State.IsEmpty);
		Test.Assert(Math.Abs(PauseAt() - resting) < 1e-3f);
		page.OnClose();
	}

	/// A keyboard holding the key it is given.
	private class HeldKeys : IKeyboard
	{
		public Sedulous.Shell.KeyCode Held = .Unknown;
		public bool IsKeyDown(Sedulous.Shell.KeyCode key) => key == Held;
		public bool IsKeyPressed(Sedulous.Shell.KeyCode key) => false;
		public bool IsKeyReleased(Sedulous.Shell.KeyCode key) => false;
		public KeyModifiers Modifiers => .None;
	}

	[Test]
	public static void ShiftIsReadWithThePointerSoABrushsShiftWheelWorksWhileItsPanelHasTheKeys()
	{
		let device = scope HeldKeys();
		device.Held = .LeftShift;
		let focusedUp = scope HeldKeys(); // the view focused, Shift not held
		// The view focused: its own keyboard says.
		Test.Assert(SceneViewport.ShiftHeldOver(device, device, false));
		Test.Assert(!SceneViewport.ShiftHeldOver(focusedUp, device, true));
		// Not focused (the brush's panel has the keys): the device's Shift while the pointer is over it.
		Test.Assert(SceneViewport.ShiftHeldOver(null, device, true));
		Test.Assert(!SceneViewport.ShiftHeldOver(null, device, false)); // the pointer elsewhere
		device.Held = .RightShift;
		Test.Assert(SceneViewport.ShiftHeldOver(null, device, true));
		Test.Assert(!SceneViewport.ShiftHeldOver(null, null, true));
	}
}
