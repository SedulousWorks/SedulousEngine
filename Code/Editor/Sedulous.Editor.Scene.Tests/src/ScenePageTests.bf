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
using Sedulous.Editor.ViewportTools;
using Sedulous.Render; // DebugDraw

namespace Sedulous.Editor.Scene.Tests;

/// The scene page on the GUI (Raptor's editor-gui spec, 5.3, layer 2), headless: a scratch project,
/// a runtime context with a scene subsystem and no renderer, the page's own markup. It opens its
/// scene into a scene of its own with the viewport in its pane; its bar's Save follows its own
/// page; a scene that did not load says so on the page and is not saved over; a prefab is marked
/// and refused a second root; Simulate locks the edits and gives the scene back; where the scene
/// was left (the camera, the selection, the panes, the overlays) comes back when it opens again.
/// And the parts: the panes' weights against the prefs' nested ratios, and a prefab's own instance
/// refused. And its hierarchy (layer 3): the scene its top row, its entities nesting, what opens; the
/// selection both ways; the search; a rename; drops; the menus and the add button as the scene's
/// actions. And its inspector (layer 4): nothing selected says so; an entity's head and sections;
/// Add Component; a transform's and a component's edits, each one undo step; several entities
/// edited at once; a header's verbs; read only while the page simulates; an entity reference's
/// slot; a component's extras (a rigid body's notice, a zone's Bake); a script component's
/// behaviours; the scene's settings with the scene selected, the physics block's collision groups
/// and the level script's properties. And its bar's editing controls (layer 5): the page's actions,
/// Select, the space's icon, Snap and its increments. Its HUD (layer 5): the chips, the stats, the
/// view gizmo, the zoom readout and the tool's status. Its viewport tools: each an action, on the bar
/// by category, the active one's panel under the chips, moved, kept and put back.
class ScenePageTests
{
	/// A host whose context has a scene subsystem and nothing else: no renderer, no window.
	class SceneHost : IApplicationHost
	{
		public Context Context { get; } = new .() ~ delete _;

		public this()
		{
			// The engine's full composition, so a scene's entities take its components.
			Context.AddSubsystem<SceneSubsystem>().SetComposition(EngineSceneComposition.Build());
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
			mResources = new .(data);
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
			let shown = scope Shown(page);
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
		let shown = scope Shown(page);
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
		let write = PropertyWrite(Sedulous.GUI.Variant(5.0));
		inspector.Sections.BeginEdit(intensity);
		inspector.Sections.CommitEdit(intensity, write);
		Test.Assert(LightOf(page, lamp).Intensity == 3.0f);
		page.StopSimulation();
		page.OnUpdate(bed.Host, 1.0f / 60.0f);
		Test.Assert(!inspector.Sections.ReadOnly);
		page.OnClose();
	}

	[Test]
	public static void InspectorAnEntityReferenceIsASlotOverTheScenesEntitiesItsNameAPickFromTheTreeADraggedEntityOneUndoEach()
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
		Test.Assert(slot.Slot.ShownName == "None");

		// The pick: the scene's entities as a tree, None allowed.
		let before = page.Commands.UndoIndex;
		let request = slot.Request();
		defer delete request;
		Test.Assert(request.Tree);
		Test.Assert(request.AllowNone);
		Test.Assert(request.Items.Count == 2);
		Test.Assert(request.Items[1].Name == "Lamp");
		request.OnPicked(request.Items[1].Key);
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
		Test.Assert(rows.Count == 2);
		Test.Assert(rows[1].Kind == .Flags);
		Test.Assert(rows[1].Choices.Count == 2);
		Test.Assert(rows[1].Choices[1].Name == "Group 1");

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
		remove.Index = 0;
		Test.Assert(!groups.EditList("groups", remove)); // Default stays
		page.Commands.Undo(); // the remove
		Test.Assert(IntOf("groups") == 2);
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
		Test.Assert(bar.Bound == 11); // save, undo, redo, four transform, space, snap, vertex snap, frame
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
}
