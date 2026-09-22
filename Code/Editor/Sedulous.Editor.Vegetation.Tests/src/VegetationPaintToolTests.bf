using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Vegetation.Resource;
using Sedulous.Engine.Vegetation;
using Sedulous.Editor.Core;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Vegetation.Tests;

/// The vegetation brush over a headless scene: a stroke paints the chosen plane along the
/// drag, a stroke is one undo step that regrows both ways, the eraser and smooth modes, the
/// simulate lock, and the persist that converts an imported mask to embedded.
class VegetationPaintToolTests
{
	[Test]
	public static void AStrokePaintsTheSelectedPlaneAlongTheDrag()
	{
		let fx = scope VegetationFixture();
		let commands = scope EditorCommandStack();
		let sink = scope FakeAssetEditSink();
		let tool = scope VegetationPaintTool(fx.Scene, commands, sink);

		Test.Assert(tool.Id == "vegetation.paint");
		Test.Assert(tool.IsAvailable);
		Test.Assert(fx.Mask.DensityAt(0, 16, 16) == 0); // nothing grows before painting
		let v0 = fx.Mask.Version;

		// The brush owns the click.
		Test.Assert(tool.Update(VegetationFixture.Press()));
		Test.Assert(fx.Mask.DensityAt(0, 16, 16) == 255);
		Test.Assert(fx.Mask.Version > v0); // the paint bumped the version, so the scatter regrows

		// Eight world units right lands around texel twenty.
		Test.Assert(tool.Update(VegetationFixture.Drag(8.0f, 0.0f)));
		Test.Assert(fx.Mask.DensityAt(0, 18, 16) > 200);
		Test.Assert(fx.Mask.DensityAt(0, 19, 16) > 200);

		// The OTHER plane is untouched: a brush paints one layer's mask.
		Test.Assert(fx.Mask.DensityAt(1, 16, 16) == 0);

		tool.Update(VegetationFixture.Release(8.0f, 0.0f));
		Test.Assert(commands.CanUndo);
		Test.Assert(sink.Count == 1);
		Test.Assert(sink.LastId == VegetationFixture.MaskId);
		Test.Assert(sink.HasPersist);
	}

	[Test]
	public static void AStrokeIsOneUndoStepAndTheScatterRegrowsBothWays()
	{
		let fx = scope VegetationFixture();
		let commands = scope EditorCommandStack();
		let tool = scope VegetationPaintTool(fx.Scene, commands, null);
		let manager = fx.Scene.GetSystem<TerrainVegetationComponentManager>();

		tool.Update(VegetationFixture.Press());
		tool.Update(VegetationFixture.Drag(8.0f, 0.0f));
		tool.Update(VegetationFixture.Release(8.0f, 0.0f));
		let painted = fx.Mask.DensityAt(0, 16, 16);
		Test.Assert(painted > 0);
		Test.Assert(commands.Count == 1, "a whole stroke is ONE step");

		// Undo restores the plane AND tells the manager to regrow what changed.
		commands.Undo();
		Test.Assert(fx.Mask.DensityAt(0, 16, 16) == 0);
		Test.Assert(manager.PendingRegionCount > 0, "undo re-notified the region");

		commands.Redo();
		Test.Assert(fx.Mask.DensityAt(0, 16, 16) == painted);
	}

	[Test]
	public static void TheEraserAndSmoothModesWorkOnThePlane()
	{
		let fx = scope VegetationFixture();
		let commands = scope EditorCommandStack();
		let tool = scope VegetationPaintTool(fx.Scene, commands, null);

		// Paint, then erase the same spot back to nothing.
		tool.Update(VegetationFixture.Press());
		tool.Update(VegetationFixture.Release());
		Test.Assert(fx.Mask.DensityAt(0, 16, 16) == 255);

		tool.SetEraser(true);
		Test.Assert(tool.IsEraser);
		tool.Update(VegetationFixture.Press());
		tool.Update(VegetationFixture.Release());
		Test.Assert(fx.Mask.DensityAt(0, 16, 16) == 0);

		// Smooth feathers a hard edge rather than erasing it.
		for (int32 y = 0; y < 32; y++)
			for (int32 x = 0; x < 16; x++)
				fx.Mask.SetDensity(0, x, y, 255);
		tool.SetSmooth(true);
		Test.Assert(tool.IsSmooth);
		Test.Assert(!tool.IsEraser, "smooth leaves the eraser");
		tool.Update(VegetationFixture.Press());
		tool.Update(VegetationFixture.Release());
		Test.Assert(fx.Mask.DensityAt(0, 16, 16) > 0, "the empty side gained");

		// Picking a plane leaves both modes.
		tool.SetPlane(1);
		Test.Assert(!tool.IsSmooth && !tool.IsEraser);
		Test.Assert(tool.Plane == 1);
	}

	[Test]
	public static void SimulateRefusesEditsAndNoMaskMakesTheToolUnavailable()
	{
		let fx = scope VegetationFixture();
		let commands = scope EditorCommandStack();
		let tool = scope VegetationPaintTool(fx.Scene, commands, null);

		var locked = VegetationFixture.Press();
		locked.EditingLocked = true;
		tool.Update(locked);
		Test.Assert(fx.Mask.DensityAt(0, 16, 16) == 0, "a locked page paints nothing");
		Test.Assert(!commands.CanUndo);

		// A component with no mask has nothing to paint.
		let bare = scope VegetationFixture(false);
		let bareTool = scope VegetationPaintTool(bare.Scene, commands, null);
		Test.Assert(!bareTool.IsAvailable);
		bareTool.Update(VegetationFixture.Press());
		Test.Assert(!commands.CanUndo);
	}

	[Test]
	public static void TheBrushSizesAndSpacesItsStamps()
	{
		let fx = scope VegetationFixture();
		let commands = scope EditorCommandStack();
		let tool = scope VegetationPaintTool(fx.Scene, commands, null);

		// The wheel sizes the brush, clamped at both ends.
		let before = tool.Radius;
		var wheel = VegetationFixture.RayAt(0.0f, 0.0f);
		wheel.WheelDelta = 1.0f;
		tool.Update(wheel);
		Test.Assert(tool.Radius > before);
		tool.SetRadius(1000.0f);
		Test.Assert(tool.Radius == VegetationPaintTool.cMaxRadius);
		tool.SetRadius(0.0f);
		Test.Assert(tool.Radius == VegetationPaintTool.cMinRadius);

		tool.SetStrength(5.0f);
		Test.Assert(tool.Strength == 1.0f);
		tool.SetSpacing(0.0f);
		Test.Assert(tool.Spacing >= 0.05f);

		// Holding still adds nothing: stamps are distance spaced.
		tool.SetRadius(6.0f);
		tool.SetStrength(0.25f);
		tool.Update(VegetationFixture.Press());
		let once = fx.Mask.DensityAt(0, 16, 16);
		for (int i < 5)
			tool.Update(VegetationFixture.Drag());
		Test.Assert(fx.Mask.DensityAt(0, 16, 16) == once, "a still pointer stamps once");

		// Airbrush stamps on a time cadence instead.
		tool.SetAirbrush(true);
		Test.Assert(tool.IsAirbrush);
		for (int i < 5)
			tool.Update(VegetationFixture.Drag(0.0f, 0.0f, 0.1f));
		Test.Assert(fx.Mask.DensityAt(0, 16, 16) > once, "airbrush builds while held");
		tool.Update(VegetationFixture.Release());
	}
}
