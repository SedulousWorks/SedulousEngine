using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Render;
using Sedulous.Heightfield;
using Sedulous.UI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Vegetation.Tests;

/// The prop brush, headless: a scripted stroke places a deterministic set of props inside
/// its footprint, the layer's rules and the collision query reject, the eraser takes back
/// what is under the brush, one command per stroke, and what the brush refuses.
class VegetationScatterToolTests
{
	[Test]
	public static void AScriptedStrokePlacesInsideItsFootprintAndOneCommandUndoesIt()
	{
		let fx = scope ScatterFixture();
		let commands = scope EditorCommandStack();
		let tool = scope VegetationScatterTool(fx.Scene, commands);
		Test.Assert(tool.IsAvailable);
		Test.Assert(tool.Id == "vegetation.scatter");
		tool.SetLayer(1);
		tool.SetRadius(6.0f);
		tool.SetDensity(0.5f);
		tool.SetSpacing(0.0f);

		fx.Stroke(tool, -20.0f, 10.0f, 20.0f, 10.0f);
		let placed = scope List<Float4x4>();
		placed.AddRange(fx.Rocks);
		Test.Assert(placed.Count > 50);
		for (let m in placed)
		{
			// Inside the swept footprint, which is the drag grown by the radius, and on the
			// surface.
			Test.Assert(m.M[3][0] >= -26.0f);
			Test.Assert(m.M[3][0] <= 26.0f);
			Test.Assert(Math.Abs(m.M[3][2] - 10.0f) <= (6.0f + 0.001f));
			Test.Assert(Math.Abs(m.M[3][1] - 2.0f) < 0.01f);
		}
		Test.Assert(commands.CanUndo);
		Test.Assert(!tool.StatusText.IsEmpty);

		// They draw as per chunk sets on the next extraction.
		let snapshot = scope ExtractedScene();
		fx.Vegetation.ExtractRenderData(snapshot);
		Test.Assert(!snapshot.Items.IsEmpty);

		// The same scripted stroke on a fresh scene places the same props.
		let again = scope ScatterFixture();
		let commands2 = scope EditorCommandStack();
		let tool2 = scope VegetationScatterTool(again.Scene, commands2);
		tool2.SetLayer(1);
		tool2.SetRadius(6.0f);
		tool2.SetDensity(0.5f);
		tool2.SetSpacing(0.0f);
		again.Stroke(tool2, -20.0f, 10.0f, 20.0f, 10.0f);
		Test.Assert(ScatterFixture.SameInstances(again.Rocks, placed));

		// One undo empties the layer and the redo puts every prop back.
		commands.Undo();
		Test.Assert(fx.Rocks.IsEmpty);
		commands.Redo();
		Test.Assert(ScatterFixture.SameInstances(fx.Rocks, placed));

		// The eraser takes what is under the brush and nothing else. The layer stays
		// selected, erasing being per layer, and the status names both.
		tool.SetEraser(true);
		tool.SetLayer(1);
		Test.Assert(tool.IsEraser);
		Test.Assert(tool.StatusText.Contains("ERASE layer 1"));
		fx.Stroke(tool, -20.0f, 10.0f, -10.0f, 10.0f, 4);
		Test.Assert(fx.Rocks.Count < placed.Count);
		for (let m in fx.Rocks)
			Test.Assert(m.M[3][0] > (-10.0f - 6.0f));
		commands.Undo();
		Test.Assert(ScatterFixture.SameInstances(fx.Rocks, placed));

		// A stroke that changes nothing pushes no command, so the next undo is the one before.
		fx.Stroke(tool, 60.0f, -60.0f, 60.0f, -60.0f, 1);
		Test.Assert(ScatterFixture.SameInstances(fx.Rocks, placed));
		commands.Undo();
		Test.Assert(fx.Rocks.IsEmpty);
	}

	[Test]
	public static void TheSlopeRuleTheCollisionQueryAndTheSpacingReject()
	{
		// A ramp climbing 64 metres over 128, which is 26.6 degrees, under a limit of ten:
		// nothing lands, and nothing changed means no command.
		let steep = scope ScatterFixture(true, 64.0f);
		steep.Vegetation.Get(steep.Terrain).Layers[1].MaxSlopeDegrees = 10.0f;
		let commands = scope EditorCommandStack();
		let tool = scope VegetationScatterTool(steep.Scene, commands);
		tool.SetLayer(1);
		tool.SetRadius(6.0f);
		tool.SetDensity(1.0f);
		steep.Stroke(tool, -10.0f, 0.0f, 10.0f, 0.0f);
		Test.Assert(steep.Rocks.IsEmpty);
		Test.Assert(!commands.CanUndo);

		// The collision query, which in the editor is the physics world's overlap: nothing to
		// the right of the origin.
		let flat = scope ScatterFixture();
		let commands2 = scope EditorCommandStack();
		let blocked = scope VegetationScatterTool(flat.Scene, commands2);
		blocked.SetLayer(1);
		blocked.SetRadius(6.0f);
		blocked.SetDensity(1.0f);
		blocked.SetSpacing(0.0f);
		blocked.SetBlockedQuery(new (world, radius) => world.X > 0.0f);
		flat.Stroke(blocked, -10.0f, 0.0f, 10.0f, 0.0f);
		Test.Assert(!flat.Rocks.IsEmpty);
		for (let m in flat.Rocks)
			Test.Assert(m.M[3][0] <= 0.0f);

		// Spacing: a one metre cube has a radius near 0.87, so at a spacing of two no two
		// props sit within about 1.7 metres.
		let spaced = scope ScatterFixture();
		let commands3 = scope EditorCommandStack();
		let sparse = scope VegetationScatterTool(spaced.Scene, commands3);
		sparse.SetLayer(1);
		sparse.SetRadius(8.0f);
		sparse.SetDensity(4.0f);
		sparse.SetSpacing(2.0f);
		spaced.Stroke(sparse, 0.0f, 0.0f, 0.0f, 0.0f, 1);
		let props = spaced.Rocks;
		Test.Assert(props.Count > 3);
		let reach = 2.0f * Length(spaced.Mesh.Bounds.Extents());
		for (int i < props.Count)
		{
			for (int j = i + 1; j < props.Count; j++)
			{
				let dx = props[i].M[3][0] - props[j].M[3][0];
				let dz = props[i].M[3][2] - props[j].M[3][2];
				Test.Assert(((dx * dx) + (dz * dz)) >= ((reach * reach) - 0.001f));
			}
		}
	}

	[Test]
	public static void UnavailableWithoutAScatteredLayerAndNoEditsUnderSimulate()
	{
		let bare = scope ScatterFixture(false);
		let commands = scope EditorCommandStack();
		let none = scope VegetationScatterTool(bare.Scene, commands);
		Test.Assert(!none.IsAvailable);
		// The toolbar's refusal notice names what the scene lacks.
		Test.Assert(!none.UnavailableReason.IsEmpty);

		let fx = scope ScatterFixture();
		let tool = scope VegetationScatterTool(fx.Scene, commands);
		// The Uniform grass layer is not one this brush writes into.
		tool.SetLayer(0);
		fx.Stroke(tool, 0.0f, 0.0f, 5.0f, 0.0f, 2);
		Test.Assert(!commands.CanUndo);

		tool.SetLayer(1);
		var locked = VegetationFixture.Press(0.0f, 0.0f);
		locked.EditingLocked = true;
		tool.Update(locked);
		Test.Assert(fx.Rocks.IsEmpty);
		Test.Assert(!commands.CanUndo);

		// A deactivation mid stroke closes the gesture with its command rather than losing it.
		tool.Update(VegetationFixture.Press(0.0f, 0.0f));
		tool.OnDeactivate();
		Test.Assert(commands.CanUndo);
		Test.Assert(!fx.Rocks.IsEmpty);
	}

	[Test]
	public static void ThePropPanelRegistersAndBuilds()
	{
		VegetationEditor.RegisterToolPanels();
		let provider = ViewportToolPanelRegistry.Global.FindByToolId("vegetation.scatter");
		Test.Assert(provider != null);
		Test.Assert(provider.Placement == .Float);

		let fx = scope ScatterFixture();
		let commands = scope EditorCommandStack();
		let tool = scope VegetationScatterTool(fx.Scene, commands);
		tool.SetLayer(1);
		var context = ViewportToolHostContext();
		context.Scene = fx.Scene;
		context.Commands = commands;

		let panel = provider.CreatePanel(tool, context);
		Test.Assert(panel != null);
		defer panel.ReleaseRef();
		Test.Assert(tool.Layer == 1);

		// Wheel sizing feeds the radius row back, which is what the panel wired up.
		Test.Assert(tool.OnRadiusChanged != null);
		tool.SetRadius(9.0f);
		Test.Assert(tool.Radius == 9.0f);
	}

	/// A layer whose mesh does not resolve is NAMED in the status: props would place and
	/// nothing would draw, which is otherwise indistinguishable from a brush that does not
	/// work.
	[Test]
	public static void ALayerWithoutAMeshIsNamedInTheStatus()
	{
		let fx = scope ScatterFixture();
		let commands = scope EditorCommandStack();
		let tool = scope VegetationScatterTool(fx.Scene, commands);
		tool.SetLayer(1);

		// The reference resolves to nothing.
		fx.Vegetation.Get(fx.Terrain).Layers[1].Mesh = .(Guid());
		tool.Update(VegetationFixture.RayAt(0.0f, 0.0f)); // a hover resolves the layer's state
		Test.Assert(tool.StatusText.Contains("no mesh"));

		fx.Vegetation.Get(fx.Terrain).Layers[1].Mesh.SetDirect(fx.Mesh);
		tool.Update(VegetationFixture.RayAt(0.0f, 0.0f));
		Test.Assert(!tool.StatusText.Contains("no mesh"));
	}

	/// The eraser reaches the props left standing over a cut.
	///
	/// A hole hides them rather than deleting them, so the eraser is what takes them away,
	/// and for that the brush has to pick the plane INSIDE the cut: the surface rule alone
	/// passes straight through and the brush would never activate over a hole at all.
	[Test]
	public static void TheEraserReachesThePropsLeftStandingOverACut()
	{
		let fx = scope ScatterFixture();
		let commands = scope EditorCommandStack();
		let tool = scope VegetationScatterTool(fx.Scene, commands);
		tool.SetLayer(1);
		tool.SetRadius(6.0f);
		tool.SetDensity(0.5f);
		tool.SetSpacing(0.0f);

		fx.Stroke(tool, -20.0f, 10.0f, 20.0f, 10.0f);
		let placed = scope List<Float4x4>();
		placed.AddRange(fx.Rocks);
		Test.Assert(placed.Count > 4);

		// How many sit inside the disc the eraser will sweep.
		var underCut = 0;
		for (let m in placed)
		{
			let dx = m.M[3][0];
			let dz = m.M[3][2] - 10.0f;
			if (((dx * dx) + (dz * dz)) < (6.0f * 6.0f))
				underCut++;
		}
		Test.Assert(underCut > 0);

		HeightfieldHoles.Cut(fx.Grid, 0.0f, 10.0f, 12.0f); // 24 across the stroke's middle
		Test.Assert(fx.Grid.HasHoles);
		Test.Assert(fx.Rocks.Count == placed.Count, "the cut itself deletes nothing");

		tool.SetEraser(true);
		fx.Stroke(tool, 0.0f, 10.0f, 0.0f, 10.0f, 1); // a press inside the hole
		Test.Assert((fx.Rocks.Count + underCut) == placed.Count, "exactly those, and no others");
		for (let m in fx.Rocks)
		{
			let dx = m.M[3][0];
			let dz = m.M[3][2] - 10.0f;
			Test.Assert(((dx * dx) + (dz * dz)) >= (6.0f * 6.0f),
				"nothing left under the eraser's disc");
		}

		commands.Undo();
		Test.Assert(ScatterFixture.SameInstances(fx.Rocks, placed));
	}
	/// SHIFT and the wheel resizes the brush; the bare wheel belongs to the camera, so it can
	/// dolly while a brush is active.
	[Test]
	public static void TheWheelResizesTheBrushOnlyWithShift()
	{
		let fx = scope ScatterFixture();
		let commands = scope EditorCommandStack();
		let tool = scope VegetationScatterTool(fx.Scene, commands);
		let before = tool.Radius;

		var wheel = VegetationFixture.RayAt(0.0f, 0.0f);
		wheel.WheelDelta = 1.0f;
		tool.Update(wheel);
		Test.Assert(tool.Radius == before, "the bare wheel is the camera's scroll");

		wheel.Shift = true;
		tool.Update(wheel);
		Test.Assert(tool.Radius > before);

		wheel.WheelDelta = -1.0f;
		tool.Update(wheel);
		Test.Assert(tool.Radius < before * 1.13f, "and it shrinks back down again");
	}
}
