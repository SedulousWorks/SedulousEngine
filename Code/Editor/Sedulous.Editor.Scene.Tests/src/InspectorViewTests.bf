using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Resource;
using Sedulous.Materials;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Engine.Render;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Spline;
using Sedulous.Engine.Vegetation;
using Sedulous.Engine.Script;
using Sedulous.Script.Resource;
using Sedulous.Spline;

namespace Sedulous.Editor.Scene.Tests;

/// The inspector over a scene: rebuilding on selection, the generated component rows, their
/// conditions, editing through them, and the Scene tab's settings rows.
class InspectorViewTests
{
	/// A rebuild asked for by a refresher lands on the next refresh.
	private static void Settle(SceneInspectorView inspector)
	{
		inspector.Refresh();
		inspector.Refresh();
	}

	/// The row `name` in section `category`.
	private static PropertyEditor FindIn(SceneInspectorView inspector, StringView category, StringView name)
	{
		let grid = inspector.Grid;
		for (int i < grid.PropertyCount)
		{
			let editor = grid.PropertyAt(i);
			if ((editor.Name == name) && (editor.Category == category))
				return editor;
		}
		return null;
	}

	private static PropertyEditor Find(SceneInspectorView inspector, StringView name)
	{
		let grid = inspector.Grid;
		for (int i < grid.PropertyCount)
		{
			if (grid.PropertyAt(i).Name == name)
				return grid.PropertyAt(i);
		}
		return null;
	}

	[Test]
	public static void RebuildsWhenTheSelectionSwitchesEntities()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let editor = scope EditorContext();
		let inspector = new SceneInspectorView(editor, edit);
		defer inspector.ReleaseRef();

		let a = edit.CreateEntity("Alpha");
		let b = edit.CreateEntity("Beta");

		edit.EntitySelection.Set(a);
		inspector.Refresh();
		var nameEditor = Find(inspector, "Name") as StringEditor;
		Test.Assert(nameEditor != null);
		Test.Assert(nameEditor.Value == "Alpha");

		edit.EntitySelection.Set(b);
		inspector.Refresh();
		nameEditor = Find(inspector, "Name") as StringEditor;
		Test.Assert(nameEditor != null);
		Test.Assert(nameEditor.Value == "Beta");

		// A rename elsewhere refreshes the row in place.
		edit.RenameEntity(b, "Gamma");
		inspector.Refresh();
		nameEditor = Find(inspector, "Name") as StringEditor;
		Test.Assert(nameEditor.Value == "Gamma");

		// Clearing the selection empties the grid.
		edit.EntitySelection.Clear();
		inspector.Refresh();
		Test.Assert(inspector.Grid.PropertyCount == 0);
	}

	[Test]
	public static void AnEntityRefListShowsTheReferencedEntitiesNames()
	{
		SceneInspectors.RegisterBuiltin();
		let scene = scope Scene();
		let anims = scene.AddSystem<SkeletalAnimationComponentManager>();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let editor = scope EditorContext();
		let inspector = new SceneInspectorView(editor, edit);
		defer inspector.ReleaseRef();

		let rig = edit.CreateEntity("Rig");
		let body = edit.CreateEntity("Body");
		let a = anims.Add(scene.FindEntity(rig));
		a.MeshEntities.Add(EntityRef(body));
		a.MeshEntities.Add(EntityRef()); // an unset slot
		a.MeshEntities.Add(EntityRef(Guid(0x1234, 0, 0, 0, 0, 0, 0, 0, 0, 0x56, 0x78))); // dangling

		edit.EntitySelection.Set(rig);
		inspector.Refresh();
		let list = Find(inspector, "MeshEntities") as ContainerListEditor;
		Test.Assert(list != null);
		Test.Assert(list.DisplayName == "Mesh Entities");
		Test.Assert(list.SlotNames.Count == 3);
		Test.Assert(list.SlotNames[0] == "Body"); // named, never a placeholder
		Test.Assert(list.SlotNames[1] == "None"); // a nil ref
		Test.Assert(list.SlotNames[2] == "(missing)"); // a guid no entity answers to
	}

	/// A generated asset row and asset list take a dropped asset of their type: the row assigns
	/// it, the list's slot assigns it, the list itself appends it, each as ONE undo step; a
	/// wrong type changes nothing.
	[Test]
	public static void GeneratedAssetRowsTakeDropsAsOneUndoStep()
	{
		SceneInspectors.RegisterBuiltin();
		let scene = scope Scene();
		let meshes = scene.AddSystem<MeshComponentManager>();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let editor = scope EditorContext();
		let inspector = new SceneInspectorView(editor, edit);
		defer inspector.ReleaseRef();

		let a = edit.CreateEntity("Crate");
		meshes.Add(edit.Resolve(a)).Materials.Add(Ref<Material>(Guid()));
		edit.EntitySelection.Set(a);
		inspector.Refresh();

		let meshId = Guid(0x3333, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3);
		let materialId = Guid(0x4444, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4);

		// The mesh row: a drop of its own type is the assignment.
		let row = Find(inspector, "Mesh") as ResourceRefEditor;
		Test.Assert((row != null) && !row.AcceptedTypes.IsEmpty);
		let slot = row.EditorView as AssetPickerSlot;
		let mesh = new AssetDragData(meshId, row.AcceptedTypes[0], "crate");
		defer mesh.ReleaseRef();
		var before = commands.Count;
		Test.Assert(slot.OnDrop(mesh, 0, 0) == .Link);
		Test.Assert(meshes.Get(edit.Resolve(a)).Mesh.Id == meshId);
		Test.Assert(commands.Count == before + 1);

		// The materials list: the wrong type is refused on the slot.
		inspector.Refresh();
		var list = Find(inspector, "Materials") as ContainerListEditor;
		Test.Assert((list != null) && !list.AcceptedTypes.IsEmpty);
		let listView = list.EditorView as ViewGroup;
		let firstSlot = (listView.GetChildAt(1) as ViewGroup).GetChildAt(0) as AssetPickerSlot;
		before = commands.Count;
		Test.Assert(firstSlot.OnDrop(mesh, 0, 0) == .None);
		Test.Assert(commands.Count == before);

		// A material on the slot assigns it.
		let material = new AssetDragData(materialId, list.AcceptedTypes[0], "red");
		defer material.ReleaseRef();
		Test.Assert(firstSlot.OnDrop(material, 0, 0) == .Link);
		Test.Assert(meshes.Get(edit.Resolve(a)).Materials[0].Id == materialId);
		Test.Assert(commands.Count == before + 1);

		// A material on the list appends it.
		inspector.Refresh();
		list = Find(inspector, "Materials") as ContainerListEditor;
		Test.Assert(list.EditorView.AsDropTarget().OnDrop(material, 0, 0) == .Link);
		Test.Assert(meshes.Get(edit.Resolve(a)).Materials.Count == 2);
		Test.Assert(commands.Count == before + 2);

		// Undo takes back the append alone.
		commands.Undo();
		Test.Assert(meshes.Get(edit.Resolve(a)).Materials.Count == 1);
		Test.Assert(meshes.Get(edit.Resolve(a)).Materials[0].Id == materialId);
	}

	/// A script component's behaviours are a section list: the add icon and a dropped script
	/// class append, a section's move icon reorders, each one undo step, and after a move a
	/// section's rows edit the behaviour now in that place.
	[Test]
	public static void BehaviorsAreSectionsWhoseRowsFollowAMove()
	{
		SceneInspectors.RegisterBuiltin();
		let scene = scope Scene();
		let scripts = scene.AddSystem<ScriptComponentManager>();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let editor = scope EditorContext();
		let inspector = new SceneInspectorView(editor, edit);
		defer inspector.ReleaseRef();

		let walker = edit.CreateEntity("Walker");
		let script = scripts.Add(edit.Resolve(walker));
		let first = new ScriptBehavior();
		first.UpdateInterval = 1.0f;
		script.Behaviors.Add(first);
		let second = new ScriptBehavior();
		second.UpdateInterval = 2.0f;
		script.Behaviors.Add(second);
		edit.EntitySelection.Set(walker);
		Settle(inspector);
		ScriptComponent* Live() => scripts.Get(edit.Resolve(walker));

		var list = Find(inspector, "Behaviors") as ContainerListEditor;
		Test.Assert((list != null) && list.ElementsAsSections && (list.SlotNames.Count == 2));
		// Each behaviour's section sits inside the component's.
		let firstSection = SceneInspectorView.ScriptBehaviorSection(0, "(none)", .. scope .());
		Test.Assert(inspector.Grid.CategoryParent(firstSection) == list.Category);

		// The add icon: one behaviour, one undo step.
		let before = commands.Count;
		list.OnAdd();
		Test.Assert((Live().Behaviors.Count == 3) && (commands.Count == before + 1));
		commands.Undo();
		Test.Assert(Live().Behaviors.Count == 2);
		Settle(inspector);

		// A script class dropped on the list appends a behaviour running it.
		list = Find(inspector, "Behaviors") as ContainerListEditor;
		let classId = Guid(0x5555, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5);
		let dropped = new AssetDragData(classId, "ScriptClassAsset", "mover");
		defer dropped.ReleaseRef();
		// (An undo leaves its entry for redo, so from here one step is: one undo reverts it.)
		Test.Assert(list.EditorView.AsDropTarget().OnDrop(dropped, 0, 0) == .Link);
		Test.Assert((Live().Behaviors.Count == 3) && (Live().Behaviors[2].Script.Id == classId));
		commands.Undo();
		Test.Assert(Live().Behaviors.Count == 2);
		Settle(inspector);

		// The first section's move down swaps the two, one undo step.
		let section = SceneInspectorView.ScriptBehaviorSection(0, "(none)", .. scope .());
		let actions = inspector.Grid.GetCategoryHeaderActions(section) as ViewGroup;
		Test.Assert(actions != null, "the section carries its element icons");
		Test.Assert(actions.ChildCount == 3);
		(actions.GetChildAt(1) as IconButton).FireClick();
		Test.Assert((Live().Behaviors[0].UpdateInterval == 2.0f) && (Live().Behaviors[1].UpdateInterval == 1.0f));
		commands.Undo();
		Test.Assert(Live().Behaviors[0].UpdateInterval == 1.0f);
		commands.Redo();
		Test.Assert(Live().Behaviors[0].UpdateInterval == 2.0f);

		// After the rebuild, the first section's rows are the behaviour now first.
		Settle(inspector);
		let interval = FindIn(inspector, section, "Update Interval") as FloatEditor;
		Test.Assert((interval != null) && (interval.Value == 2.0));
		interval.Setter(5.0);
		Test.Assert((Live().Behaviors[0].UpdateInterval == 5.0f) && (Live().Behaviors[1].UpdateInterval == 1.0f));
	}

	/// A hierarchy row dragged onto an entity slot assigns it, as one undo step; an asset, or a
	/// tree row naming nothing, is refused; an entity list takes one on a slot and appends one.
	[Test]
	public static void AHierarchyRowDropsOnAnEntitySlot()
	{
		SceneInspectors.RegisterBuiltin();
		let scene = scope Scene();
		let followers = scene.AddSystem<PathFollowComponentManager>();
		let anims = scene.AddSystem<SkeletalAnimationComponentManager>();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let editor = scope EditorContext();
		let inspector = new SceneInspectorView(editor, edit);
		defer inspector.ReleaseRef();
		let hierarchy = new SceneHierarchyView(edit);
		defer hierarchy.ReleaseRef();

		let cart = edit.CreateEntity("Cart");
		let track = edit.CreateEntity("Track");
		followers.Add(scene.FindEntity(cart));
		hierarchy.Refresh();

		// The hierarchy names the dragged row's entity: Track is the second root.
		let drag = new TreeDragData(1);
		defer drag.ReleaseRef();
		hierarchy.DecorateDrag(drag);
		Test.Assert((drag.ItemKind == "entity") && (drag.ItemId == track) && (drag.ItemName == "Track"));

		edit.EntitySelection.Set(cart);
		inspector.Refresh();
		let row = Find(inspector, "Spline") as ResourceRefEditor;
		let slot = row.EditorView as AssetPickerSlot;

		// An asset is refused, and so is a row that names nothing.
		let asset = new AssetDragData(Guid(0x6666, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6), "MaterialAsset", "red");
		defer asset.ReleaseRef();
		Test.Assert(slot.OnDrop(asset, 0, 0) == .None);
		let bare = new TreeDragData(0);
		defer bare.ReleaseRef();
		Test.Assert(slot.CanAcceptDrop(bare, 0, 0) == .None);
		Test.Assert(followers.Get(scene.FindEntity(cart)).Spline.IsNil);

		// The hierarchy row assigns, and one undo takes it back.
		Test.Assert(slot.OnDrop(drag, 0, 0) == .Link);
		Test.Assert(followers.Get(scene.FindEntity(cart)).Spline.Id == track);
		commands.Undo();
		Test.Assert(followers.Get(scene.FindEntity(cart)).Spline.IsNil);

		// An entity list: a drop on its slot assigns, a drop on the list appends.
		let rig = anims.Add(scene.FindEntity(cart));
		rig.MeshEntities.Add(EntityRef());
		inspector.Refresh();
		inspector.Refresh();
		var list = Find(inspector, "MeshEntities") as ContainerListEditor;
		let first = ((list.EditorView as ViewGroup).GetChildAt(1) as ViewGroup).GetChildAt(0) as AssetPickerSlot;
		Test.Assert(first.OnDrop(drag, 0, 0) == .Link);
		Test.Assert(anims.Get(scene.FindEntity(cart)).MeshEntities[0].Id == track);
		inspector.Refresh();
		list = Find(inspector, "MeshEntities") as ContainerListEditor;
		Test.Assert(list.EditorView.AsDropTarget().OnDrop(drag, 0, 0) == .Link);
		Test.Assert(anims.Get(scene.FindEntity(cart)).MeshEntities.Count == 2);
	}

	/// An entity ref row's refresher runs on every later Refresh, long after the section that
	/// built it went out of scope; it must read the name through the target, not the section.
	[Test]
	public static void AnEntityRefRowFollowsARenameAcrossRefreshes()
	{
		SceneInspectors.RegisterBuiltin();
		let scene = scope Scene();
		let followers = scene.AddSystem<PathFollowComponentManager>();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let editor = scope EditorContext();
		let inspector = new SceneInspectorView(editor, edit);
		defer inspector.ReleaseRef();

		let cart = edit.CreateEntity("Cart");
		let track = edit.CreateEntity("Track");
		followers.Add(scene.FindEntity(cart)).Spline = EntityRef(track);

		edit.EntitySelection.Set(cart);
		inspector.Refresh();
		Test.Assert((Find(inspector, "Spline") as ResourceRefEditor).ValueText == "Track");

		// The rename lands through the refresher, with the building section long gone.
		edit.RenameEntity(track, "Loop");
		inspector.Refresh();
		inspector.Refresh();
		Test.Assert((Find(inspector, "Spline") as ResourceRefEditor).ValueText == "Loop");
	}

	/// The generated rows skip what a hand written section already draws and what only the
	/// runtime holds: a script component's behaviours and their overrides render once, through
	/// the script section, and a mesh's material cache or a sprite's render flag never shows.
	[Test]
	public static void HiddenFieldsGenerateNoRows()
	{
		SceneInspectors.RegisterBuiltin();
		let scene = scope Scene();
		let scripts = scene.AddSystem<ScriptComponentManager>();
		let meshes = scene.AddSystem<MeshComponentManager>();
		let sprites = scene.AddSystem<SpriteComponentManager>();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let editor = scope EditorContext();
		let inspector = new SceneInspectorView(editor, edit);
		defer inspector.ReleaseRef();

		let camera = edit.CreateEntity("Camera");
		let script = scripts.Add(edit.Resolve(camera));
		let behavior = new ScriptBehavior();
		behavior.SetOverride(ScriptPropertyNames.HashOf("target"), .Entity(Guid.Create()));
		script.Behaviors.Add(behavior);
		meshes.Add(edit.Resolve(camera));
		sprites.Add(edit.Resolve(camera));
		edit.EntitySelection.Set(camera);
		inspector.Refresh();

		// The script section's own rows, once.
		Test.Assert(Find(inspector, "Enabled") != null);
		Test.Assert(Find(inspector, "Update Interval") != null);
		// No generated rows for the hidden fields; the behaviours' one row is the section
		// list's header.
		for (let name in StringView[?]("Overrides", "Hash", "MaterialCache", "PostTonemap"))
			Test.Assert(Find(inspector, name) == null, scope $"a generated '{name}' row");
		let behaviors = Find(inspector, "Behaviors") as ContainerListEditor;
		Test.Assert((behaviors != null) && behaviors.ElementsAsSections);
	}

	[Test]
	public static void GeneratedLightRowsCarryRangesLabelsAndConditions()
	{
		SceneInspectors.RegisterBuiltin();
		let scene = scope Scene();
		let lights = scene.AddSystem<LightComponentManager>();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let editor = scope EditorContext();
		let inspector = new SceneInspectorView(editor, edit);
		defer inspector.ReleaseRef();

		let sun = edit.CreateEntity("Sun");
		lights.Add(edit.Resolve(sun)); // directional by default
		edit.EntitySelection.Set(sun);
		inspector.Refresh();

		// The rows are the component's fields, in order, under its display name.
		let intensity = Find(inspector, "Intensity") as RangeEditor;
		Test.Assert(intensity != null); // [Range] makes it a slider
		Test.Assert(intensity.Category == "Light");
		let type = Find(inspector, "Type") as EnumEditor;
		Test.Assert(type != null);
		Test.Assert(type.Value == 0);
		Test.Assert(Find(inspector, "CastsShadows").DisplayName == "Casts Shadows");

		// The spot cone rows hide while the light is directional.
		let range = Find(inspector, "Range");
		let inner = Find(inspector, "InnerAngle");
		Test.Assert((range != null) && (inner != null));
		Test.Assert(!range.RowVisible);
		Test.Assert(!inner.RowVisible);

		// Editing through the enum row goes through the undoable command, and the condition
		// follows on the next refresh.
		let before = commands.Count;
		type.Setter(2); // Spot
		Test.Assert(lights.Get(edit.Resolve(sun)).Type == .Spot);
		Test.Assert(commands.Count == before + 1);
		inspector.Refresh();
		Test.Assert(Find(inspector, "Range").RowVisible);
		Test.Assert(Find(inspector, "InnerAngle").RowVisible);

		// The slider writes the float through its command; undo restores and the row follows.
		(Find(inspector, "Intensity") as RangeEditor).Setter(7.5f);
		Test.Assert(Math.Abs(lights.Get(edit.Resolve(sun)).Intensity - 7.5f) < 1e-5f);
		commands.Undo();
		inspector.Refresh();
		Test.Assert(Math.Abs(lights.Get(edit.Resolve(sun)).Intensity - 1.0f) < 1e-5f);
		Test.Assert(Math.Abs((Find(inspector, "Intensity") as RangeEditor).Value - 1.0f) < 1e-5f);

		// Adding a second component extends the grid on the next refresh.
		let cameras = scene.AddSystem<CameraComponentManager>();
		edit.AddComponent(sun, typeof(CameraComponent));
		inspector.Refresh();
		let fov = Find(inspector, "FovYRadians");
		Test.Assert((fov != null) && (fov.DisplayName == "Field Of View") && (fov.Category == "Camera"));
		Test.Assert(cameras.HasComponent(edit.Resolve(sun)));
	}

	/// A component's computed rows: a [InspectorProperty] getter with a setter is a bool
	/// row written through Mutate as one undo step; one without is read-only text.
	[Test]
	public static void ComputedRowsWriteThroughTheirSetterAndReadOnlyOnesShowText()
	{
		SceneInspectors.RegisterBuiltin();
		let scene = scope Scene();
		let splines = scene.AddSystem<SplineComponentManager>();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let editor = scope EditorContext();
		let inspector = new SceneInspectorView(editor, edit);
		defer inspector.ReleaseRef();

		let path = edit.CreateEntity("Path");
		edit.AddComponent(path, typeof(SplineComponent));
		scene.InitializePendingComponents(); // seeds the two point segment
		edit.EntitySelection.Set(path);
		inspector.Refresh();

		let closed = Find(inspector, "closed") as BoolEditor;
		Test.Assert(closed != null);
		Test.Assert(closed.Category == "Spline");
		Test.Assert(!closed.Value);
		let count = Find(inspector, "pointCount") as ReadOnlyEditor;
		Test.Assert(count != null);
		Test.Assert(count.Value == "2");

		// The write goes through the curve, so the arc length follows, and is one undo step.
		let component = splines.Get(edit.Resolve(path));
		let open = component.Curve.Length;
		let before = commands.Count;
		closed.Setter(true);
		Test.Assert(component.IsClosed());
		Test.Assert(component.Curve.Length > open);
		Test.Assert(commands.Count == before + 1);
		commands.Undo();
		Test.Assert(!component.IsClosed());
		inspector.Refresh();
		Test.Assert(!(Find(inspector, "closed") as BoolEditor).Value);

		// The read-only row follows the data.
		component.Curve.Points.Add(SplinePoint(.(0.0f, 1.0f, 0.0f)));
		inspector.Refresh();
		Test.Assert((Find(inspector, "pointCount") as ReadOnlyEditor).Value == "3");
	}

	[Test]
	public static void AnUnregisteredComponentShowsANoticeAndTheSceneTabShowsSettings()
	{
		SceneInspectors.RegisterBuiltin();
		InspectorRegistry.Register<WindSettings>();
		let scene = scope Scene();
		let widgets = scene.AddSystem<WidgetManager>();
		let wind = scene.AddSystem<WindSystem>();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let editor = scope EditorContext();
		let inspector = new SceneInspectorView(editor, edit);
		defer inspector.ReleaseRef();

		let e = edit.CreateEntity("Thing");
		widgets.Add(edit.Resolve(e));
		edit.EntitySelection.Set(e);
		inspector.Refresh();
		Test.Assert((Find(inspector, "Inspector") as NoticeEditor) != null); // Widget is not registered
		Test.Assert(Find(inspector, "Speed") == null);

		// The Scene tab: the wind block's generated row, edited through the settings command.
		inspector.[Friend]mTabView.SetSelectedIndex(1);
		inspector.Refresh();
		let speed = Find(inspector, "Speed") as FloatEditor;
		Test.Assert(speed != null);
		Test.Assert(speed.Category == "Wind");
		speed.Setter(4.0);
		Test.Assert(wind.Settings.Speed == 4.0f);
		commands.Undo();
		Test.Assert(wind.Settings.Speed == 1.0f);
	}

	/// A list of reflected objects gets a section of the ELEMENT's own rows per slot, so a
	/// layer's fields read, write and undo like a component's. Before this the list showed a
	/// column of type labels and nothing could be edited.
	[Test]
	public static void AListOfReflectedObjectsEditsPerSlot()
	{
		SceneInspectors.RegisterBuiltin();
		let scene = scope Scene();
		VegetationScene.AddVegetationSceneManagers(scene);
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let editor = scope EditorContext();
		let inspector = new SceneInspectorView(editor, edit);
		defer inspector.ReleaseRef();

		let manager = scene.GetSystem<TerrainVegetationComponentManager>();
		Test.Assert(manager != null);

		let terrain = edit.CreateEntity("Terrain");
		edit.AddComponent(terrain, typeof(TerrainVegetationComponent));
		scene.InitializePendingComponents();

		let component = manager.Get(edit.Resolve(terrain));
		Test.Assert(component != null);
		let grass = new ProceduralVegetationLayer();
		grass.Name.Set("Grass");
		grass.Density = 2.0f;
		component.ProceduralLayers.Add(grass);
		let rocks = new ProceduralVegetationLayer();
		rocks.Name.Set("Rocks");
		rocks.Density = 0.5f;
		component.ProceduralLayers.Add(rocks);

		edit.EntitySelection.Set(terrain);
		inspector.Refresh();

		// Each slot's rows are titled by the element's own name.
		let density = Find(inspector, "Density") as FloatEditor;
		Test.Assert(density != null, "a slot field has a row of its own");
		Test.Assert(density.Category.Contains("Grass"), scope $"titled by the name: {density.Category}");

		// Writing a slot field lands on THAT slot and is one undo step.
		let before = commands.Count;
		density.Setter(3.5f);
		Test.Assert(Near(component.ProceduralLayers[0].Density, 3.5f), "the first slot took the write");
		Test.Assert(Near(component.ProceduralLayers[1].Density, 0.5f), "the second slot is untouched");
		Test.Assert(commands.Count == before + 1);

		commands.Undo();
		Test.Assert(Near(component.ProceduralLayers[0].Density, 2.0f), "and it undoes");

		// Consecutive edits of the SAME slot field merge, so a slider drag is ONE undo step:
		// a single undo goes back past the whole drag rather than one frame of it.
		density.Setter(4.0f);
		density.Setter(5.0f);
		density.Setter(6.0f);
		Test.Assert(Near(component.ProceduralLayers[0].Density, 6.0f));
		commands.Undo();
		Test.Assert(Near(component.ProceduralLayers[0].Density, 2.0f), "one undo covers the whole drag");

		// The second slot kept its own value throughout: the slot is part of the merge key,
		// so one slot's drag never absorbs another's edit.
		Test.Assert(Near(component.ProceduralLayers[1].Density, 0.5f));

		// A list inside a slot (a layer's material per mesh slot) is a list editor of its own,
		// and what it adds lands on that slot's list alone.
		inspector.Refresh();
		let materials = Find(inspector, "Materials") as ContainerListEditor;
		Test.Assert(materials != null, "a slot's list has an editor of its own");
		Test.Assert(materials.Category.Contains("Grass"), scope $"in its slot: {materials.Category}");
		Test.Assert(!materials.AcceptedTypes.IsEmpty);
		let material = new AssetDragData(Guid(0x5555, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5), materials.AcceptedTypes[0], "bark");
		defer material.ReleaseRef();
		Test.Assert(materials.EditorView.AsDropTarget().OnDrop(material, 0, 0) == .Link);
		Test.Assert(component.ProceduralLayers[0].Materials.Count == 1);
		Test.Assert(component.ProceduralLayers[1].Materials.Count == 0, "the other slot's list is untouched");
		commands.Undo();
		Test.Assert(component.ProceduralLayers[0].Materials.Count == 0, "and it undoes");
	}

	private static bool Near(float a, float b) => Math.Abs(a - b) <= 0.001f;
}
