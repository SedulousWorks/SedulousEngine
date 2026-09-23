using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Heightfield;
using Sedulous.Heightfield.Pipeline;
using Sedulous.Heightfield.Resource;
using Sedulous.Pipeline.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.VFS;
using Sedulous.Engine.Terrain;
using Sedulous.Editor.Core;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Terrain.Tests;

/// The Cut Holes brush: a hard edged disc over the hole plane, one command per stroke, and a
/// save that writes BOTH sidecars so an imported heightfield keeps its image born heights.
class HoleToolTests
{
	/// A press and a release over one spot, which is one whole stroke.
	private static void Stroke(TerrainHoleTool tool, float x, float z)
	{
		tool.Update(TerrainFixture.Press(x, z));
		tool.Update(TerrainFixture.Release(x, z));
	}

	[Test]
	public static void AStrokeCutsAHardEdgedDiscAndOneCommandUndoesAndRedoesIt()
	{
		let fx = scope TerrainFixture();
		let commands = scope EditorCommandStack();
		let sink = scope FakeAssetEditSink();
		let tool = scope TerrainHoleTool(fx.Scene, commands, sink);

		Test.Assert(tool.IsAvailable);
		Test.Assert(tool.Id == "terrain.hole");
		tool.SetRadius(3.0f);

		let before = fx.Grid.Version;
		Test.Assert(tool.Update(TerrainFixture.Press()), "the brush owns the click");

		// A HARD edge: inside is cut, the rim is not, with nothing in between.
		Test.Assert(fx.Grid.IsHole(32, 32));
		Test.Assert(fx.Grid.IsHole(34, 32), "two metres out is inside");
		Test.Assert(!fx.Grid.IsHole(35, 32), "three metres out is the rim, and not cut");
		Test.Assert(fx.Grid.Version > before);

		tool.Update(TerrainFixture.Release());
		Test.Assert(commands.CanUndo);
		Test.Assert(sink.Count == 1);
		Test.Assert(sink.LastId == TerrainFixture.HeightfieldId);

		let cut = fx.Grid.HoleCount;
		Test.Assert(cut > 0);
		let stroked = fx.Grid.Version;

		commands.Undo();
		Test.Assert(fx.Grid.HoleCount == 0);
		Test.Assert(fx.Grid.Version > stroked, "the consumers re-read on the undo too");

		commands.Redo();
		Test.Assert(fx.Grid.HoleCount == cut);
		Test.Assert(tool.StatusText.Contains("CUT"));
	}

	[Test]
	public static void FillRestoresACutFromInsideItAndAFillOverSolidGroundIsNoCommand()
	{
		let fx = scope TerrainFixture();
		let commands = scope EditorCommandStack();
		let tool = scope TerrainHoleTool(fx.Scene, commands, null);
		tool.SetRadius(3.0f);
		Stroke(tool, 0.0f, 0.0f);
		Test.Assert(fx.Grid.HasHoles);

		// The brush picks the hole PLANE, so the fill lands inside the cut at the same spot
		// and the same radius: no dance around the rim.
		tool.SetMode(.Fill);
		Test.Assert(tool.StatusText.Contains("FILL"));
		Stroke(tool, 0.0f, 0.0f);
		Test.Assert(!fx.Grid.HasHoles);
		Test.Assert(commands.CanUndo);

		// A fill over solid ground changes nothing and pushes nothing.
		let quiet = scope EditorCommandStack();
		let still = scope TerrainHoleTool(fx.Scene, quiet, null);
		still.SetMode(.Fill);
		Stroke(still, 10.0f, 10.0f);
		Test.Assert(!quiet.CanUndo);
	}

	[Test]
	public static void ARayStraightIntoACutFindsThePlaneAndACutOverACutIsNoCommand()
	{
		let fx = scope TerrainFixture();
		let commands = scope EditorCommandStack();

		let cutter = scope TerrainHoleTool(fx.Scene, commands, null);
		cutter.SetRadius(3.0f);
		Stroke(cutter, 0.0f, 0.0f);
		Test.Assert(fx.Grid.HasHoles);
		let cutCount = fx.Grid.HoleCount;

		// The plane is under the cursor, so the brush is live over a hole and the stroke
		// begins; cutting what is already cut then changes nothing and pushes no command.
		let again = scope EditorCommandStack();
		let over = scope TerrainHoleTool(fx.Scene, again, null);
		over.SetRadius(1.0f);
		Test.Assert(over.Update(TerrainFixture.Press()));
		over.Update(TerrainFixture.Release());
		Test.Assert(fx.Grid.HoleCount == cutCount);
		Test.Assert(!again.CanUndo);
	}

	[Test]
	public static void UnavailableWithNoTerrainAndNoEditsWhileLocked()
	{
		let empty = scope Scene("empty");
		TerrainScene.AddTerrainSceneManagers(empty);
		empty.Start();

		let bareCommands = scope EditorCommandStack();
		let bare = scope TerrainHoleTool(empty, bareCommands, null);
		Test.Assert(!bare.IsAvailable);
		Test.Assert(!bare.UnavailableReason.IsEmpty);

		let fx = scope TerrainFixture();
		let commands = scope EditorCommandStack();
		let tool = scope TerrainHoleTool(fx.Scene, commands, null);

		// Simulate: the collider is shared with the running world, so nothing is edited.
		var locked = TerrainFixture.Press();
		locked.EditingLocked = true;
		tool.Update(locked);
		Test.Assert(!fx.Grid.HasHoles);
		Test.Assert(!commands.CanUndo);
	}

	/// The save writes BOTH sidecars, so a cut survives a re-cook and so do the heights an
	/// imported heightfield was born with, which clearing the file name would otherwise lose.
	[Test]
	public static void ASaveWritesBothSidecarsAndTheCutAndHeightsSurviveARecook()
	{
		let dbRoot = "scratch_hole_persist_db";
		let cookedRoot = "scratch_hole_persist_cooked";
		RemoveDirectoryRecursive(dbRoot);
		RemoveDirectoryRecursive(cookedRoot);
		CreateDirectory(dbRoot);
		CreateDirectory(cookedRoot);
		defer
		{
			RemoveDirectoryRecursive(dbRoot);
			RemoveDirectoryRecursive(cookedRoot);
		}

		HeightfieldPipeline.RegisterAll();
		HeightfieldResources.RegisterAll();

		let mount = scope NativeFileSystem(dbRoot);
		let cookedMount = scope NativeFileSystem(cookedRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);

		let database = scope ContentDatabase(mount, serializers, "rasset");
		let instance = database.RootGroup.CreateInstance("hf",
			"Sedulous.Heightfield.Pipeline.HeightfieldAsset");
		Test.Assert(instance != null);
		let id = instance.Id;
		{
			let authored = scope HeightfieldAsset();
			authored.Size = 65;
			authored.WorldSize = .(64.0f, 64.0f);
			authored.MinY = 0.0f;
			authored.MaxY = 10.0f;
			// An IMPORTED heightfield: its heights came from an image.
			authored.FileName.Set("legacy.png");
			Test.Assert(instance.WriteObject(authored) case .Ok);
		}

		// The runtime grid carries heights the save has to keep.
		let fx = scope TerrainFixture();
		for (int32 z = 0; z < 65; z++)
			for (int32 x = 0; x < 65; x++)
				fx.Grid.SetSample(x, z, 32768);
		fx.Resource.Heightfield.SetId(id);

		let sink = scope FakeAssetEditSink();
		let commands = scope EditorCommandStack();
		let tool = scope TerrainHoleTool(fx.Scene, commands, sink);
		tool.SetRadius(3.0f);
		Stroke(tool, 0.0f, 0.0f);

		Test.Assert(sink.HasPersist);
		Test.Assert(sink.LastId == id);
		let cut = fx.Grid.HoleCount;
		Test.Assert(cut > 0);

		// Drain the save, then cook what it wrote.
		Test.Assert(sink.LastPersist(database) case .Ok);
		let object = instance.ReadObject();
		defer delete object;
		let asset = object as HeightfieldAsset;
		Test.Assert(asset != null);
		Test.Assert(asset.FileName.IsEmpty, "the sidecars are the truth now");

		let cookedDb = scope ContentDatabase(cookedMount, serializers, "rasset");
		let cookedInstance = cookedDb.RootGroup.CreateInstanceWithId(id, "hf",
			"Sedulous.Heightfield.Resource.HeightfieldSource");
		Test.Assert(cookedInstance != null);

		let sourceMount = scope NativeFileSystem(dbRoot);
		let context = scope AssetBuildContext();
		context.Sources = sourceMount;
		context.Source = instance;
		context.Output = cookedInstance;
		Test.Assert(scope HeightfieldAssetBuilder().Build(asset, context) case .Ok);

		let manager = scope ResourceManager(cookedDb, null);
		let factory = scope HeightfieldFactory();
		manager.AddFactory(factory);
		let cooked = manager.Bind<Heightfield>(id).Get;
		Test.Assert(cooked != null);
		Test.Assert(cooked.HoleCount == cut, "the cut survived");
		Test.Assert(cooked.IsHole(32, 32));
		Test.Assert(cooked.GetSample(10, 10) == 32768, "and so did the heights");
	}
	/// SHIFT and the wheel resizes the brush; the bare wheel belongs to the camera, so it can
	/// dolly while a brush is active.
	[Test]
	public static void TheWheelResizesTheBrushOnlyWithShift()
	{
		let fx = scope TerrainFixture();
		let commands = scope EditorCommandStack();
		let tool = scope TerrainHoleTool(fx.Scene, commands, null);
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
