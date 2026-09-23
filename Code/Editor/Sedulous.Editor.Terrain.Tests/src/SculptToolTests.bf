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
using Sedulous.Heightfield.Resource;
using Sedulous.Heightfield.Pipeline;
using Sedulous.Pipeline.Core;
using Sedulous.Engine.Terrain;
using Sedulous.Editor.Core;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Terrain.Tests;

/// The sculpt brush over a headless scene: a stroke raises the shared grid and registers
/// one persist, undo and redo replay the region, the lock refuses edits, and a persist
/// converts an imported heightfield to embedded and survives a re-cook.
class SculptToolTests
{
	[Test]
	public static void APressDragReleaseStrokeRaisesTheSharedHeightfield()
	{
		let fx = scope TerrainFixture();
		let commands = scope EditorCommandStack();
		let sink = scope FakeAssetEditSink();
		let tool = scope TerrainSculptTool(fx.Scene, commands, sink);
		Test.Assert(tool.Id == "terrain.sculpt");
		Test.Assert(tool.IsAvailable);
		Test.Assert(fx.Grid.GetSample(32, 32) == 0);

		Test.Assert(tool.Update(TerrainFixture.Press(0, 0, 0.1f))); // consumed: the brush owns the click
		let afterDab = fx.Grid.GetSample(32, 32);
		Test.Assert(afterDab > 0);
		Test.Assert(fx.Grid.Version > 1); // the sculpt bumped the version (GPU re-upload)
		Test.Assert(tool.IsStroking);

		Test.Assert(tool.Update(TerrainFixture.Drag(0, 0, 0.1f)));
		Test.Assert(fx.Grid.GetSample(32, 32) > afterDab);

		tool.Update(TerrainFixture.Release(0, 0, 0.1f));
		Test.Assert(!tool.IsStroking);
		Test.Assert(commands.CanUndo);
		Test.Assert(sink.Count == 1);
		Test.Assert(sink.LastId == TerrainFixture.HeightfieldId);
		Test.Assert(sink.HasPersist);
	}

	[Test]
	public static void OneCommandPerStrokeUndoesAndRedoesTheWholeRegion()
	{
		let fx = scope TerrainFixture();
		let commands = scope EditorCommandStack();
		let sink = scope FakeAssetEditSink();
		let tool = scope TerrainSculptTool(fx.Scene, commands, sink);
		tool.Update(TerrainFixture.Press(0, 0, 0.2f));
		tool.Update(TerrainFixture.Release(0, 0, 0.2f));
		let raised = fx.Grid.GetSample(32, 32);
		Test.Assert(raised > 0);
		let versionAfterStroke = fx.Grid.Version;

		commands.Undo();
		Test.Assert(fx.Grid.GetSample(32, 32) == 0); // the region restored to the before state
		Test.Assert(fx.Grid.Version > versionAfterStroke); // undo bumps the version too
		commands.Redo();
		Test.Assert(fx.Grid.GetSample(32, 32) == raised); // redo replays the after state
	}

	[Test]
	public static void ModesLowerSmoothAndFlattenEachTouchTheGrid()
	{
		let fx = scope TerrainFixture();
		let commands = scope EditorCommandStack();
		let tool = scope TerrainSculptTool(fx.Scene, commands, null);
		tool.SetMode(.Raise);
		tool.Update(TerrainFixture.Press());
		tool.Update(TerrainFixture.Drag(0, 0, 0.5f));
		tool.Update(TerrainFixture.Release());
		let raised = fx.Grid.GetSample(32, 32);
		Test.Assert(raised > 0);

		tool.SetMode(.Lower);
		Test.Assert(tool.Mode == .Lower);
		tool.Update(TerrainFixture.Press());
		tool.Update(TerrainFixture.Release());
		Test.Assert(fx.Grid.GetSample(32, 32) < raised);

		tool.SetMode(.Smooth);
		let beforeSmooth = fx.Grid.GetSample(32, 32);
		tool.Update(TerrainFixture.Press(0, 0, 0.5f));
		tool.Update(TerrainFixture.Release());
		Test.Assert(fx.Grid.GetSample(32, 32) < beforeSmooth); // the peak sinks toward its neighbours

		// Ctrl+click picks the flatten target from the surface and switches the mode.
		var pick = TerrainFixture.Press(8.0f, 0.0f);
		pick.Ctrl = true;
		Test.Assert(tool.Update(pick));
		Test.Assert(tool.Mode == .Flatten);
		Test.Assert(!tool.IsStroking); // a Ctrl click never opens a stroke
		tool.Update(TerrainFixture.Press());
		tool.Update(TerrainFixture.Drag(0, 0, 2.0f));
		tool.Update(TerrainFixture.Release());
		Test.Assert(fx.Grid.GetSample(32, 32) < 64); // pulled down to the flat target
		Test.Assert(commands.CanUndo);
	}

	[Test]
	public static void UnavailableWithNoTerrainAndRefusesEditsWhileLocked()
	{
		let empty = scope Scene();
		TerrainScene.AddTerrainSceneManagers(empty);
		empty.Start();
		let commandsA = scope EditorCommandStack();
		let bare = scope TerrainSculptTool(empty, commandsA, null);
		Test.Assert(!bare.IsAvailable);
		Test.Assert(!bare.Update(TerrainFixture.Press()));

		let fx = scope TerrainFixture();
		let commands = scope EditorCommandStack();
		let tool = scope TerrainSculptTool(fx.Scene, commands, null);
		var locked = TerrainFixture.Press(0, 0, 0.1f);
		locked.EditingLocked = true;
		tool.Update(locked);
		Test.Assert(fx.Grid.GetSample(32, 32) == 0); // no edit under the lock
		Test.Assert(!commands.CanUndo);
		Test.Assert(tool.HasHover); // the cursor still reads the surface
	}

	[Test]
	public static void RadiusAndStrengthClampAndTheWheelSizesTheBrush()
	{
		let fx = scope TerrainFixture();
		let commands = scope EditorCommandStack();
		let tool = scope TerrainSculptTool(fx.Scene, commands, null);
		tool.SetRadius(1000.0f);
		Test.Assert(tool.Radius == TerrainSculptTool.cMaxRadius);
		tool.SetRadius(0.0f);
		Test.Assert(tool.Radius == TerrainSculptTool.cMinRadius);
		tool.SetStrength(-1.0f);
		Test.Assert(tool.Strength == 0.0f);
		tool.SetStrength(500.0f);
		Test.Assert(tool.Strength == TerrainSculptTool.cMaxStrength);

		tool.SetRadius(10.0f);
		float reported = 0.0f;
		tool.OnRadiusChanged = new [&reported](r) => { reported = r; };
		var wheel = TerrainFixture.RayAt(0, 0);
		wheel.WheelDelta = 1.0f;
		wheel.Shift = true;
		tool.Update(wheel);
		Test.Assert(tool.Radius > 10.0f);
		Test.Assert(reported == tool.Radius);
		Test.Assert(tool.StatusText.StartsWith("Sculpt [Raise]"));
		tool.OnDeactivate(); // drops the panel's callback
		Test.Assert(tool.OnRadiusChanged == null);
	}

	/// A save persists to the SOURCE asset: the imported file name is cleared, the sidecar
	/// becomes the truth, and the builder cooks the sculpted grid back out of it.
	[Test]
	public static void ASavePersistsToTheSourceAssetAndSurvivesAReCook()
	{
		const String dbDir = "scratch_sculpt_persist_db";
		const String cookedDir = "scratch_sculpt_persist_cooked";
		RemoveDirectoryRecursive(dbDir);
		RemoveDirectoryRecursive(cookedDir);
		CreateDirectory(dbDir);
		CreateDirectory(cookedDir);
		defer { RemoveDirectoryRecursive(dbDir); RemoveDirectoryRecursive(cookedDir); }
		HeightfieldPipeline.RegisterAll();
		HeightfieldResources.RegisterAll();

		let mount = scope NativeFileSystem(dbDir);
		let cookedMount = scope NativeFileSystem(cookedDir);
		SerializerFactory serializers = scope (stream, mode) => new BinarySerializerContext(stream, mode);

		Guid id;
		{
			let db = scope ContentDatabase(mount, serializers, "rasset");
			let inst = db.RootGroup.CreateInstance("hf", typeof(HeightfieldAsset).GetFullName(.. scope .()));
			Test.Assert(inst != null);
			id = inst.Id;
			let src = scope HeightfieldAsset();
			src.Size = 65;
			src.WorldSize = .(64.0f, 64.0f);
			src.MinY = 0.0f;
			src.MaxY = 10.0f;
			src.FileName.Set("legacy.png"); // imported style
			Test.Assert(inst.WriteObject(src) case .Ok);
		}

		let fx = scope TerrainFixture();
		fx.Resource.Heightfield.SetId(id);
		let sink = scope FakeAssetEditSink();
		let commands = scope EditorCommandStack();
		let tool = scope TerrainSculptTool(fx.Scene, commands, sink);
		tool.Update(TerrainFixture.Press(0, 0, 0.1f));
		tool.Update(TerrainFixture.Release(0, 0, 0.0f));
		Test.Assert(sink.HasPersist);
		Test.Assert(sink.LastId == id);
		let sculpted = fx.Grid.GetSample(32, 32);
		Test.Assert(sculpted > 0);

		{
			let db = scope ContentDatabase(mount, serializers, "rasset");
			Test.Assert(sink.LastPersist(db) case .Ok);
			let inst = db.GetInstance(id);
			Test.Assert(inst != null);
			let object = inst.ReadObject();
			defer delete object;
			let asset = object as HeightfieldAsset;
			Test.Assert(asset != null); // the envelope is STILL a HeightfieldAsset
			Test.Assert(asset.FileName.IsEmpty); // converted to embedded: the sidecar is the truth
			Test.Assert(asset.Size == 65);

			let cookedDb = scope ContentDatabase(cookedMount, serializers, "rasset");
			let cookedInst = cookedDb.RootGroup.CreateInstanceWithId(id, "hf", "Sedulous.Heightfield.Resource.HeightfieldSource");
			Test.Assert(cookedInst != null);
			let context = scope AssetBuildContext();
			context.Sources = mount;
			context.Source = inst;
			context.Output = cookedInst;
			Test.Assert(scope HeightfieldAssetBuilder().Build(asset, context) case .Ok);
		}
		{
			let cookedDb = scope ContentDatabase(cookedMount, serializers, "rasset");
			let manager = scope ResourceManager(cookedDb, null);
			let factory = scope HeightfieldFactory();
			manager.AddFactory(factory);
			let cooked = manager.Bind<Heightfield>(id);
			Test.Assert(cooked.Get != null);
			Test.Assert(cooked.Get.GetSample(32, 32) == sculpted);
		}
	}
	/// SHIFT and the wheel resizes the brush; the bare wheel belongs to the camera, so it can
	/// dolly while a brush is active.
	[Test]
	public static void TheWheelResizesTheBrushOnlyWithShift()
	{
		let fx = scope TerrainFixture();
		let commands = scope EditorCommandStack();
		let tool = scope TerrainSculptTool(fx.Scene, commands, null);
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
