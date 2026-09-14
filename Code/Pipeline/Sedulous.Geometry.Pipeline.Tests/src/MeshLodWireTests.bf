using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Geometry;
using Sedulous.VFS;
using Sedulous.Xml.Serialization;

namespace Sedulous.Geometry.Pipeline.Tests;

/// The level of detail chain from the stored record to the runtime mesh.
class MeshLodWireTests
{
	private const String cRoot = "scratch_geometry_lod";
	private const String cAssetType = "Sedulous.Geometry.Pipeline.StaticMeshAsset";

	/// The chain survives the sidecar, and the fill SLICES it: level one draws its own range
	/// and inherits the material and primitive of the submesh it refines.
	[Test]
	public static void TheSidecarCarriesTheChainAndTheFillSlicesIt()
	{
		RemoveDirectoryRecursive(cRoot);
		CreateDirectory(cRoot);
		defer { RemoveDirectoryRecursive(cRoot); }

		GeometryPipeline.RegisterAll();
		GeometryResources.RegisterAll();

		let mount = scope NativeFileSystem(cRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new XmlSerializerContext(stream, mode);

		Guid id;
		{
			let database = scope ContentDatabase(mount, serializers, "xasset");
			let instance = database.RootGroup.CreateInstance("fan", cAssetType);
			Test.Assert(instance != null);
			id = instance.Id;

			let asset = scope StaticMeshAsset();
			MeshSourceFixture.TwoLevelFan(asset.Source);
			Test.Assert(MeshAssetStorage.WriteStatic(instance, asset) case .Ok);
		}

		let database = scope ContentDatabase(mount, serializers, "xasset");
		let instance = database.GetInstance(id);
		Test.Assert(instance != null);

		let object = instance.ReadObject();
		Test.Assert(object != null);
		let asset = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object))
			as StaticMeshAsset;
		Test.Assert(asset != null);
		defer delete asset;
		Test.Assert(MeshAssetStorage.EnsureStaticLoaded(instance, asset) case .Ok);

		Test.Assert(asset.Source.LodCount == 2);
		Test.Assert(asset.Source.LodStart.Count == 1);
		Test.Assert(asset.Source.LodStart[0] == 9);
		Test.Assert(asset.Source.LodIndexCount[0] == 3);
		Test.Assert(asset.Source.LodCoverage.Count == 2);
		Test.Assert(Abs(asset.Source.LodCoverage[1] - 0.25f) < 0.001f);

		let mesh = scope StaticMesh();
		asset.Source.FillStatic(mesh);
		Test.Assert(mesh.LodCount == 2);
		Test.Assert(mesh.SubMeshesForLod(0).Length == 1);
		Test.Assert(mesh.SubMeshesForLod(0)[0].IndexCount == 9);
		Test.Assert(mesh.SubMeshesForLod(1).Length == 1);
		Test.Assert(mesh.SubMeshesForLod(1)[0].StartIndex == 9);
		Test.Assert(mesh.SubMeshesForLod(1)[0].IndexCount == 3);
		Test.Assert(mesh.SubMeshesForLod(1)[0].MaterialIndex == 7);
		// A level past the end CLAMPS to the coarsest rather than reading off the end.
		Test.Assert(mesh.SubMeshesForLod(9)[0].StartIndex == 9);

		// And capturing the mesh back yields the same chain, so an edit round trip is lossless.
		let recaptured = scope StaticMeshSource();
		StaticMeshSource.FromMesh(mesh, recaptured);
		Test.Assert(recaptured.LodCount == 2);
		Test.Assert(recaptured.LodStart.Count == 1);
		Test.Assert(recaptured.LodStart[0] == 9);
		Test.Assert(recaptured.LodCoverage.Count == 2);
	}

	/// A malformed chain COLLAPSES to one level rather than indexing off the end: the mesh
	/// still renders, at its base level, which is what a player needs from broken data.
	[Test]
	public static void AMalformedChainCollapsesToOneLevel()
	{
		let pastTheEnd = scope StaticMeshSource();
		MeshSourceFixture.TwoLevelFan(pastTheEnd);
		pastTheEnd.LodIndexCount[0] = 99;
		let mesh = scope StaticMesh();
		pastTheEnd.FillStatic(mesh);
		Test.Assert(mesh.LodCount == 1);
		Test.Assert(mesh.LodSubMeshes.IsEmpty);
		Test.Assert(mesh.SubMeshesForLod(1)[0].IndexCount == 9); // the base, as a fallback

		let shortCoverage = scope StaticMeshSource();
		MeshSourceFixture.TwoLevelFan(shortCoverage);
		shortCoverage.LodCoverage.PopBack();
		let second = scope StaticMesh();
		shortCoverage.FillStatic(second);
		Test.Assert(second.LodCount == 1);

		let chainless = scope StaticMeshSource();
		MeshSourceFixture.TwoLevelFan(chainless);
		chainless.LodCount = 1;
		chainless.LodStart.Clear();
		chainless.LodIndexCount.Clear();
		chainless.LodCoverage.Clear();
		let third = scope StaticMesh();
		chainless.FillStatic(third);
		Test.Assert(third.LodCount == 1);
		Test.Assert(third.SubMeshesForLod(1).Length == 1); // the base level's view
	}

	[Test]
	public static void TheRecordRoundTripsTheWholeChain()
	{
		let authored = scope StaticMeshSource();
		MeshSourceFixture.TwoLevelFan(authored);

		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializer(buffer, .Write);
			BeginVersionedPayload(writer, StaticMeshSource.TypeId, StaticMeshSource.DataVersion);
			((ISerializable)authored).Serialize(writer);
			EndVersionedPayload(writer);
			Test.Assert(writer.IsPayloadOk);
		}
		buffer.Seek(0, .Begin);

		let loaded = scope StaticMeshSource();
		{
			let reader = scope BinarySerializer(buffer, .Read);
			BeginVersionedPayload(reader, StaticMeshSource.TypeId, StaticMeshSource.DataVersion);
			((ISerializable)loaded).Serialize(reader);
			EndVersionedPayload(reader);
			Test.Assert(reader.IsPayloadOk);
		}

		Test.Assert(loaded.LodCount == 2);
		Test.Assert(loaded.LodStart.Count == 1);
		Test.Assert(loaded.LodStart[0] == 9);
		Test.Assert(loaded.LodIndexCount[0] == 3);
		Test.Assert(loaded.LodCoverage.Count == 2);
	}

	/// The optimiser reorders the BASE without disturbing the levels that follow it in the
	/// same buffer.
	[Test]
	public static void TheOptimiserPreservesEveryLevelOfAChain()
	{
		let source = scope StaticMeshSource();
		MeshSourceFixture.TwoLevelFan(source);

		let levelBefore = scope List<Float3>();
		for (int i < 3)
			levelBefore.Add(MeshSourceFixture.PositionOf(source, source.IndexData[9 + i]));

		MeshOptimizeStats stats = .();
		MeshOptimize.OptimizeStaticMeshSource(source, &stats);

		Test.Assert(source.LodStart[0] == 9);
		Test.Assert(source.LodIndexCount[0] == 3);
		for (let index in source.IndexData)
			Test.Assert(index < 5);

		// The level is ONE triangle, which the cache pass may rotate, so it is compared as a
		// set of corners rather than a sequence.
		let levelAfter = scope List<Float3>();
		for (int i < 3)
			levelAfter.Add(MeshSourceFixture.PositionOf(source, source.IndexData[9 + i]));
		for (let position in levelBefore)
			Test.Assert(levelAfter.Contains(position));
	}
}
