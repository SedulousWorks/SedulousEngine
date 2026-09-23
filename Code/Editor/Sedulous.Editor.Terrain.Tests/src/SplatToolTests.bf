using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.VFS;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Heightfield;
using Sedulous.Terrain.Resource;
using Sedulous.Terrain.Pipeline;
using Sedulous.Pipeline.Core;
using Sedulous.Engine.Terrain;
using Sedulous.Editor.Core;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Terrain.Tests;

/// The splat brush over a headless scene: a stroke stamps the chosen layer along the
/// drag, stamps are distance spaced unless airbrushing, spacing sets the density, one
/// command restores both rasters, the eraser and smooth modes, the lock, and a persist
/// that converts an imported splatmap to embedded and survives a re-cook.
class SplatToolTests
{
	private static void Stroke(TerrainSplatTool tool, float x0, float z0, float x1, float z1)
	{
		tool.Update(TerrainFixture.Press(x0, z0));
		if ((x1 != x0) || (z1 != z0))
			tool.Update(TerrainFixture.Drag(x1, z1));
		tool.Update(TerrainFixture.Release(x1, z1));
	}

	[Test]
	public static void AStrokeStampsTheSelectedPaletteLayerAlongTheDrag()
	{
		let fx = scope TerrainFixture();
		let commands = scope EditorCommandStack();
		let sink = scope FakeAssetEditSink();
		let tool = scope TerrainSplatTool(fx.Scene, commands, sink);
		Test.Assert(tool.Id == "terrain.splat");
		tool.SetPaletteIndex(1); // palette layer 1 over the implicit base
		Test.Assert(tool.IsAvailable);
		Test.Assert(fx.Weights.BaseWeight(16, 16) == 255); // pure base before painting
		Test.Assert(fx.Weights.WeightOfLayer(16, 16, 1) == 0);
		let v0 = fx.Weights.Version;

		Test.Assert(tool.Update(TerrainFixture.Press())); // consumed: the brush owns the click
		Test.Assert(fx.Weights.WeightOfLayer(16, 16, 1) == 255);
		Test.Assert(fx.Weights.BaseWeight(16, 16) == 0);
		Test.Assert(fx.Weights.Version > v0); // the paint bumped the version (GPU re-upload)

		Test.Assert(tool.Update(TerrainFixture.Drag(8.0f, 0.0f))); // 8 world units right = texel ~20
		Test.Assert(fx.Weights.WeightOfLayer(18, 16, 1) > 200); // mid path
		Test.Assert(fx.Weights.WeightOfLayer(19, 16, 1) > 200);

		tool.Update(TerrainFixture.Release(8.0f, 0.0f));
		Test.Assert(commands.CanUndo);
		Test.Assert(sink.Count == 1);
		Test.Assert(sink.LastId == TerrainFixture.WeightsId);
		Test.Assert(sink.HasPersist);
	}

	[Test]
	public static void StampsAreDistanceSpacedHoldingStillAddsNothingScrubbingBuilds()
	{
		let fx = scope TerrainFixture();
		let commands = scope EditorCommandStack();
		let tool = scope TerrainSplatTool(fx.Scene, commands, null);
		tool.SetPaletteIndex(2);
		tool.SetStrength(0.5f); // one stamp is half coverage; build up needs MOVEMENT
		tool.Update(TerrainFixture.Press());
		let afterPress = fx.Weights.WeightOfLayer(16, 16, 2);
		Test.Assert(afterPress >= 126); // about half coverage from the press stamp
		Test.Assert(afterPress <= 129);

		for (int i < 10)
			tool.Update(TerrainFixture.Drag());
		Test.Assert(fx.Weights.WeightOfLayer(16, 16, 2) == afterPress); // held still: nothing

		tool.Update(TerrainFixture.Drag(2.0f, 0.0f));
		tool.Update(TerrainFixture.Drag());
		Test.Assert(fx.Weights.WeightOfLayer(16, 16, 2) > afterPress + 40); // scrubbed back over
		tool.Update(TerrainFixture.Release());
	}

	[Test]
	public static void AirbrushModeBuildsUpWhileHoldingStill()
	{
		let fx = scope TerrainFixture();
		let commands = scope EditorCommandStack();
		let tool = scope TerrainSplatTool(fx.Scene, commands, null);
		tool.SetPaletteIndex(4);
		tool.SetStrength(0.5f);
		tool.SetAirbrush(true);
		Test.Assert(tool.IsAirbrush);
		tool.Update(TerrainFixture.Press());
		let afterPress = fx.Weights.WeightOfLayer(16, 16, 4);
		Test.Assert(afterPress >= 126);

		for (int i < 12) // a fifth of a second at sixty hertz
			tool.Update(TerrainFixture.Drag());
		let shortHold = fx.Weights.WeightOfLayer(16, 16, 4);
		Test.Assert(shortHold > afterPress); // it DOES build while held
		Test.Assert(shortHold <= afterPress + 20); // but gently, on the time cadence

		for (int i < 108)
			tool.Update(TerrainFixture.Drag());
		Test.Assert(fx.Weights.WeightOfLayer(16, 16, 4) > afterPress + 40);
		tool.Update(TerrainFixture.Release());
	}

	private static uint8 StrokeAndMeasure(float spacing)
	{
		let fx = scope TerrainFixture();
		let commands = scope EditorCommandStack();
		let tool = scope TerrainSplatTool(fx.Scene, commands, null);
		tool.SetPaletteIndex(6);
		tool.SetStrength(0.3f);
		tool.SetSpacing(spacing);
		Test.Assert(Math.Abs(tool.Spacing - spacing) < 1e-6f);
		Stroke(tool, 0.0f, 0.0f, 8.0f, 0.0f);
		return fx.Weights.WeightOfLayer(18, 16, 6); // the mid path texel, world x = +4
	}

	[Test]
	public static void SpacingControlsStampDensityAlongTheStroke()
	{
		let tight = StrokeAndMeasure(0.05f);
		let wide = StrokeAndMeasure(1.0f);
		Test.Assert(tight > wide + 30); // denser stamps: visibly more build up on the same path
		Test.Assert(wide > 0); // but the wide stroke still covers the path, no gap
	}

	[Test]
	public static void OneCommandPerStrokeUndoesAndRedoesBothRasters()
	{
		let fx = scope TerrainFixture();
		let commands = scope EditorCommandStack();
		let sink = scope FakeAssetEditSink();
		let tool = scope TerrainSplatTool(fx.Scene, commands, sink);
		tool.SetPaletteIndex(2);
		Stroke(tool, 0, 0, 0, 0);
		let painted = fx.Weights.WeightOfLayer(16, 16, 2);
		Test.Assert(painted > 0);
		var hasIndex2 = false;
		for (uint32 k < SplatWeights.SlotCount)
			hasIndex2 = hasIndex2 || (fx.Weights.SlotIndex(16, 16, k) == 2);
		Test.Assert(hasIndex2);

		commands.Undo();
		Test.Assert(fx.Weights.WeightOfLayer(16, 16, 2) == 0); // the weights restored
		Test.Assert(fx.Weights.BaseWeight(16, 16) == 255); // pure base again
		for (uint32 k < SplatWeights.SlotCount)
			Test.Assert(fx.Weights.SlotIndex(16, 16, k) == 0); // the index raster restored too
		commands.Redo();
		Test.Assert(fx.Weights.WeightOfLayer(16, 16, 2) == painted); // redo replays the after state
	}

	[Test]
	public static void TheEraserFadesPaintBackToTheBase()
	{
		let fx = scope TerrainFixture();
		let commands = scope EditorCommandStack();
		let tool = scope TerrainSplatTool(fx.Scene, commands, null);
		tool.SetPaletteIndex(3);
		tool.SetStrength(1.0f);
		Stroke(tool, 0, 0, 0, 0);
		Test.Assert(fx.Weights.WeightOfLayer(16, 16, 3) == 255);

		tool.SetEraser(true);
		Test.Assert(tool.IsEraser);
		Stroke(tool, 0, 0, 0, 0);
		Test.Assert(fx.Weights.WeightOfLayer(16, 16, 3) == 0);
		Test.Assert(fx.Weights.BaseWeight(16, 16) == 255);

		tool.SetEraser(false);
		Stroke(tool, 0, 0, 0, 0);
		Test.Assert(fx.Weights.WeightOfLayer(16, 16, 3) == 255);

		tool.SetEraser(true);
		tool.SetStrength(0.5f);
		Stroke(tool, 0, 0, 0, 0);
		let faded = fx.Weights.WeightOfLayer(16, 16, 3);
		Test.Assert(faded > 100); // half remains
		Test.Assert(faded < 160);
		Test.Assert(fx.Weights.BaseWeight(16, 16) > 90);
	}

	[Test]
	public static void SmoothModeFeathersAHardSeamAndRidesTheStrokeUndo()
	{
		let fx = scope TerrainFixture();
		let commands = scope EditorCommandStack();
		let tool = scope TerrainSplatTool(fx.Scene, commands, null);
		// A hard seam: the left half pure layer 1, the right half pure base.
		for (int32 y < 32)
		{
			for (int32 x < 16)
			{
				let at = fx.Weights.TexelOffset(x, y);
				fx.Weights.Indices[at] = 1;
				fx.Weights.Weights[at] = 255;
			}
		}
		tool.SetSmooth(true);
		Test.Assert(tool.IsSmooth);
		Test.Assert(!tool.IsEraser);
		tool.SetEraser(true);
		Test.Assert(!tool.IsSmooth); // the modes exclude each other
		tool.SetSmooth(true);
		tool.SetStrength(1.0f);
		Stroke(tool, 0, 0, 0, 0);
		let edge = fx.Weights.WeightOfLayer(15, 16, 1);
		let bled = fx.Weights.WeightOfLayer(16, 16, 1);
		Test.Assert(edge < 255);
		Test.Assert(edge > 0);
		Test.Assert(bled > 0);
		Test.Assert(bled < edge);

		commands.Undo();
		Test.Assert(fx.Weights.WeightOfLayer(15, 16, 1) == 255);
		Test.Assert(fx.Weights.WeightOfLayer(16, 16, 1) == 0);
		tool.SetPaletteIndex(2);
		Test.Assert(!tool.IsSmooth); // picking a layer leaves smooth mode
	}

	[Test]
	public static void UnavailableWithNoWeightsAndRefusesEditsWhileLocked()
	{
		let bare = scope TerrainFixture(false); // a heightfield but no weights
		let commandsA = scope EditorCommandStack();
		let bareTool = scope TerrainSplatTool(bare.Scene, commandsA, null);
		Test.Assert(!bareTool.IsAvailable);

		let fx = scope TerrainFixture();
		let commands = scope EditorCommandStack();
		let tool = scope TerrainSplatTool(fx.Scene, commands, null);
		tool.SetPaletteIndex(1);
		var locked = TerrainFixture.Press();
		locked.EditingLocked = true;
		tool.Update(locked);
		Test.Assert(fx.Weights.WeightOfLayer(16, 16, 1) == 0); // no edit under the lock
		Test.Assert(!commands.CanUndo);
	}

	[Test]
	public static void RadiusStrengthAndSpacingClampAndTheStatusNamesTheMode()
	{
		let fx = scope TerrainFixture();
		let commands = scope EditorCommandStack();
		let tool = scope TerrainSplatTool(fx.Scene, commands, null);
		tool.SetRadius(1000.0f);
		Test.Assert(tool.Radius == TerrainSplatTool.cMaxRadius);
		tool.SetStrength(2.0f);
		Test.Assert(tool.Strength == 1.0f);
		tool.SetSpacing(0.0f);
		Test.Assert(tool.Spacing == 0.05f);
		tool.SetPaletteIndex(1000);
		Test.Assert(tool.PaletteIndex == 255); // what an eight bit index holds
		tool.SetPaletteIndex(3);
		tool.Update(TerrainFixture.RayAt(0, 0));
		Test.Assert(tool.StatusText.StartsWith("Paint Splat [layer 3]"));
		tool.SetEraser(true);
		tool.Update(TerrainFixture.RayAt(0, 0));
		Test.Assert(tool.StatusText.StartsWith("Paint Splat [ERASER]"));
		tool.SetSmooth(true);
		tool.Update(TerrainFixture.RayAt(0, 0));
		Test.Assert(tool.StatusText.StartsWith("Paint Splat [SMOOTH]"));
		Test.Assert(tool.HasHover);
	}

	/// A save converts an imported splatmap to embedded: the file name is cleared, the
	/// dimensions sync to the painted raster, and the builder cooks the paint back out of
	/// the sidecars.
	[Test]
	public static void ASaveConvertsAnImportedSplatmapToEmbeddedAndSurvivesAReCook()
	{
		const String dbDir = "scratch_splat_persist_db";
		const String cookedDir = "scratch_splat_persist_cooked";
		RemoveDirectoryRecursive(dbDir);
		RemoveDirectoryRecursive(cookedDir);
		CreateDirectory(dbDir);
		CreateDirectory(cookedDir);
		defer { RemoveDirectoryRecursive(dbDir); RemoveDirectoryRecursive(cookedDir); }
		TerrainPipeline.RegisterAll();
		TerrainResources.RegisterAll();

		let mount = scope NativeFileSystem(dbDir);
		let cookedMount = scope NativeFileSystem(cookedDir);
		SerializerFactory serializers = scope (stream, mode) => new BinarySerializerContext(stream, mode);

		Guid id;
		{
			let db = scope ContentDatabase(mount, serializers, "rasset");
			let inst = db.RootGroup.CreateInstance("splat", typeof(SplatmapAsset).GetFullName(.. scope .()));
			Test.Assert(inst != null);
			id = inst.Id;
			let src = scope SplatmapAsset();
			src.Width = 8; // stale: the import decoded at native size, the envelope never knew
			src.Height = 8;
			src.FileName.Set("weights.png"); // imported style
			Test.Assert(inst.WriteObject(src) case .Ok);
		}

		let fx = scope TerrainFixture();
		fx.Resource.Weights.SetId(id);
		let sink = scope FakeAssetEditSink();
		let commands = scope EditorCommandStack();
		let tool = scope TerrainSplatTool(fx.Scene, commands, sink);
		tool.SetPaletteIndex(1);
		Stroke(tool, 0, 0, 0, 0);
		Test.Assert(sink.HasPersist);
		Test.Assert(sink.LastId == id);
		let painted = fx.Weights.WeightOfLayer(16, 16, 1);
		Test.Assert(painted > 0);

		{
			let db = scope ContentDatabase(mount, serializers, "rasset");
			Test.Assert(sink.LastPersist(db) case .Ok);
			let inst = db.GetInstance(id);
			Test.Assert(inst != null);
			let object = inst.ReadObject();
			defer delete object;
			let asset = object as SplatmapAsset;
			Test.Assert(asset != null); // the envelope is STILL a SplatmapAsset
			Test.Assert(asset.FileName.IsEmpty); // converted to embedded: the sidecars are the truth
			Test.Assert(asset.Width == 32); // the dimensions synced to the painted raster
			Test.Assert(asset.Height == 32);

			let cookedDb = scope ContentDatabase(cookedMount, serializers, "rasset");
			let cookedInst = cookedDb.RootGroup.CreateInstanceWithId(id, "splat", "Sedulous.Terrain.Resource.SplatWeightsSource");
			Test.Assert(cookedInst != null);
			let context = scope AssetBuildContext();
			context.Sources = mount;
			context.Source = inst;
			context.Output = cookedInst;
			Test.Assert(scope SplatmapAssetBuilder().Build(asset, context) case .Ok);
		}
		{
			let cookedDb = scope ContentDatabase(cookedMount, serializers, "rasset");
			let manager = scope ResourceManager(cookedDb, null);
			let factory = scope SplatWeightsFactory();
			manager.AddFactory(factory);
			let cooked = manager.Bind<SplatWeights>(id);
			Test.Assert(cooked.Get != null);
			Test.Assert(cooked.Get.WeightOfLayer(16, 16, 1) == painted);
		}
	}
	/// SHIFT and the wheel resizes the brush; the bare wheel belongs to the camera, so it can
	/// dolly while a brush is active.
	[Test]
	public static void TheWheelResizesTheBrushOnlyWithShift()
	{
		let fx = scope TerrainFixture();
		let commands = scope EditorCommandStack();
		let tool = scope TerrainSplatTool(fx.Scene, commands, null);
		let before = tool.Radius;

		var wheel = TerrainFixture.RayAt(0.0f, 0.0f);
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
