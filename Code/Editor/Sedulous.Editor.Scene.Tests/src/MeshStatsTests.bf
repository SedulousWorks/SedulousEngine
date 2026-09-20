using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Geometry;
using Sedulous.Settings;
using Sedulous.Xml.Serialization;

namespace Sedulous.Editor.Scene.Tests;

/// The mesh page's stat lines and its preview material preference.
class MeshStatsTests
{
	private static bool HasPrefix(List<String> lines, StringView prefix)
	{
		for (let line in lines)
		{
			if (line.StartsWith(prefix))
				return true;
		}
		return false;
	}

	private static bool Has(List<String> lines, StringView exact)
	{
		for (let line in lines)
		{
			if (line == exact)
				return true;
		}
		return false;
	}

	[Test]
	public static void StatLinesReportCountsBoundsSkinningAndPerSubmeshRows()
	{
		let cube = Primitives.Cube(2.0f);
		defer delete cube;
		let lines = scope List<String>();
		defer { ClearAndDeleteItems!(lines); }
		MeshStats.Lines(cube, lines);

		Test.Assert(lines.Count >= 6 + cube.SubMeshes.Count);
		Test.Assert(HasPrefix(lines, "Name:"));
		Test.Assert(HasPrefix(lines, "Vertices:"));
		Test.Assert(HasPrefix(lines, "Indices:"));
		Test.Assert(HasPrefix(lines, "Submeshes:"));
		Test.Assert(HasPrefix(lines, "Bounds:"));
		Test.Assert(HasPrefix(lines, "Skinned: no"));
		Test.Assert(Has(lines, "Bounds: 2.000 x 2.000 x 2.000"));

		int submeshRows = 0;
		for (let line in lines)
		{
			if (line.StartsWith("  ["))
				submeshRows++;
		}
		Test.Assert(submeshRows == cube.SubMeshes.Count);
		Test.Assert(submeshRows >= 1);
	}

	[Test]
	public static void StatLineCountsMatchTheMeshGeometry()
	{
		let sphere = Primitives.Sphere(0.5f, 16, 12);
		defer delete sphere;
		Test.Assert((sphere.VertexCount > 0) && (sphere.IndexCount > 0));
		let lines = scope List<String>();
		defer { ClearAndDeleteItems!(lines); }
		MeshStats.Lines(sphere, lines);
		Test.Assert(Has(lines, scope $"Vertices: {sphere.VertexCount}"));
		Test.Assert(Has(lines, scope $"Indices: {sphere.IndexCount}"));
	}

	[Test]
	public static void StatLinesReportTheLodChain()
	{
		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		cube.LodCount = 2;
		cube.LodSubMeshes.Add(SubMesh(0, 12, 0, .Triangles));
		cube.LodCoverage.Add(1.0f);
		cube.LodCoverage.Add(0.25f);

		let lines = scope List<String>();
		defer { ClearAndDeleteItems!(lines); }
		MeshStats.Lines(cube, lines);
		Test.Assert(Has(lines, "LOD levels: 2"));
		Test.Assert(Has(lines, "  LOD 0: 12 triangles")); // cube: 36 indices = 12 triangles
		Test.Assert(Has(lines, "  LOD 1: 4 triangles  |  below 0.250 coverage")); // 12 indices

		// A one level mesh has no LOD section at all.
		let plain = Primitives.Cube(1.0f);
		defer delete plain;
		let plainLines = scope List<String>();
		defer { ClearAndDeleteItems!(plainLines); }
		MeshStats.Lines(plain, plainLines);
		Test.Assert(!HasPrefix(plainLines, "LOD"));
	}

	[Test]
	public static void ThePreviewMaterialRoundTripsThroughTheSettingsStore()
	{
		SceneEditorSerializables.RegisterAll();
		let meshA = Guid(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2);
		let meshB = Guid(3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4);
		let mat = Guid(5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6);

		let store = scope Settings();
		Test.Assert(MeshPreviewPrefs.Load(store, meshA).IsNil);
		Test.Assert(MeshPreviewPrefs.Save(store, meshA, mat));
		Test.Assert(MeshPreviewPrefs.Save(store, meshB, .()));
		Test.Assert(!MeshPreviewPrefs.Save(store, Guid(), mat));
		Test.Assert(!MeshPreviewPrefs.Save(null, meshA, mat));
		Test.Assert(MeshPreviewPrefs.Load(store, meshA) == mat);
		Test.Assert(MeshPreviewPrefs.Load(store, meshB).IsNil);

		// Back to the default updates in place.
		Test.Assert(MeshPreviewPrefs.Save(store, meshA, .()));
		Test.Assert(store.Section<MeshPreviewSettings>().Prefs.Count == 2);
		Test.Assert(MeshPreviewPrefs.Load(store, meshA).IsNil);
		Test.Assert(MeshPreviewPrefs.Save(store, meshA, mat));

		let factory = XmlSerializerFactory();
		defer delete factory;
		let buffer = scope MemoryStream();
		Test.Assert(store.Save(buffer, factory) case .Ok);
		buffer.Seek(0, .Begin);
		let loaded = scope Settings();
		Test.Assert(loaded.Load(buffer, factory) case .Ok);
		Test.Assert(MeshPreviewPrefs.Load(loaded, meshA) == mat);
	}
}
