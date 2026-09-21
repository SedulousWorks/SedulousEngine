using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Engine.Render;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Spline;
using Sedulous.Spline;

namespace Sedulous.Editor.Scene.Tests;

/// The inspector over a scene: rebuilding on selection, the generated component rows, their
/// conditions, editing through them, and the Scene tab's settings rows.
class InspectorViewTests
{
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
}
