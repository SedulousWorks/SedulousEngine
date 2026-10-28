using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Graphics;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.Settings;
using Sedulous.Shell;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Engine.Scene;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;
using Sedulous.Editor.Scene;

namespace Sedulous.Editor.Scene.Tests;

/// The scene page on the GUI (Raptor's editor-gui spec, 5.3, layer 2), headless: a scratch project,
/// a runtime context with a scene subsystem and no renderer, the page's own markup. It opens its
/// scene into a scene of its own with the viewport in its pane; its bar's Save follows its own
/// page; a scene that did not load says so on the page and is not saved over; a prefab is marked
/// and refused a second root; Simulate locks the edits and gives the scene back; where the scene
/// was left (the camera, the selection, the panes, the overlays) comes back when it opens again.
/// And the parts: the panes' weights against the prefs' nested ratios, and a prefab's own instance
/// refused.
class ScenePageTests
{
	/// A host whose context has a scene subsystem and nothing else: no renderer, no window.
	class SceneHost : IApplicationHost
	{
		public Context Context { get; } = new .() ~ delete _;

		public this()
		{
			Context.AddSubsystem<SceneSubsystem>();
			Context.Startup();
		}

		public ~this()
		{
			Context.Shutdown();
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
		public SceneEditorPage Open(Instance instance)
		{
			let services = new SceneEditorPageServices();
			services.Host = Host;
			services.LoadMarkup = new (path) => LoadMarkup(path);
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
}
