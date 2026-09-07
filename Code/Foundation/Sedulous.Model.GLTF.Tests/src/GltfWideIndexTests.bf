using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Model;
using Sedulous.Model.IO;
using Sedulous.Model.GLTF;

namespace Sedulous.Model.GLTF.Tests;

/// The wide index path, and the external buffer path.
///
/// A mesh crosses into 32 bit indices on the TOTAL across its primitives, not on any one
/// of them, so the fixture uses two primitives of three vertices with thirty three thousand
/// indices each: the counts cross the threshold while the buffer stays small.
///
/// The buffer is a real file beside the document rather than a data URI, which is how a
/// normal glTF export ships and is otherwise not exercised.
class GltfWideIndexTests
{
	private const int32 cVertexCount = 3;
	private const int32 cIndexCount = 33000;

	private const String cDocument = """
{"asset":{"version":"2.0"},"buffers":[{"byteLength":132072,"uri":"scratch_gltf_wide.bin"}],"bufferViews":[{"buffer":0,"byteOffset":0,"byteLength":36},{"buffer":0,"byteOffset":36,"byteLength":36},{"buffer":0,"byteOffset":72,"byteLength":66000},{"buffer":0,"byteOffset":66072,"byteLength":66000}],"accessors":[{"bufferView":0,"componentType":5126,"count":3,"type":"VEC3"},{"bufferView":1,"componentType":5126,"count":3,"type":"VEC3"},{"bufferView":2,"componentType":5123,"count":33000,"type":"SCALAR"},{"bufferView":3,"componentType":5123,"count":33000,"type":"SCALAR"}],"meshes":[{"name":"wide","primitives":[{"attributes":{"POSITION":0},"indices":2},{"attributes":{"POSITION":1},"indices":3}]}],"nodes":[{"name":"wideNode","mesh":0}],"scenes":[{"nodes":[0]}],"scene":0}
""";

	/// Positions for both primitives, then both index runs, matching the byte offsets the
	/// document declares.
	private static void WriteBuffer(StringView path)
	{
		let bytes = scope List<uint8>();

		void AppendFloat(float value)
		{
			var v = value;
			let raw = (uint8*)&v;
			for (int i < 4)
				bytes.Add(raw[i]);
		}

		// Primitive A at the origin, primitive B shifted along X so the two are still
		// telling apart once merged.
		for (int primitive < 2)
		{
			let shift = (float)primitive * 10.0f;
			AppendFloat(shift + 0); AppendFloat(0); AppendFloat(0);
			AppendFloat(shift + 1); AppendFloat(0); AppendFloat(0);
			AppendFloat(shift + 0); AppendFloat(1); AppendFloat(0);
		}

		for (int run < 2)
		{
			for (int32 i = 0; i < cIndexCount; i++)
			{
				let index = (uint16)(i % cVertexCount);
				bytes.Add((uint8)(index & 0xFF));
				bytes.Add((uint8)(index >> 8));
			}
		}

		File.WriteAll(scope String(path), bytes).IgnoreError();
	}

	[Test]
	public static void ManyIndicesWidenToThirtyTwoBitAndStillRemap()
	{
		let documentPath = scope String("scratch_gltf_wide.gltf");
		let bufferPath = scope String("scratch_gltf_wide.bin");
		File.WriteAllText(documentPath, cDocument).IgnoreError();
		WriteBuffer(bufferPath);
		// Braced, because `defer a.B().C()` in Beef runs a.B() immediately.
		defer { File.Delete(documentPath).IgnoreError(); }
		defer { File.Delete(bufferPath).IgnoreError(); }

		let model = scope ModelData();
		let loader = scope GltfLoader();
		Test.Assert(loader.Load(documentPath, model) == .Ok,
			"the external .bin resolves relative to the document");

		Test.Assert(model.Meshes.Length == 1);
		let mesh = model.Meshes[0];
		Test.Assert(mesh.VertexCount == cVertexCount * 2);
		Test.Assert(mesh.IndexCount == cIndexCount * 2);
		Test.Assert(mesh.Use32BitIndices, "sixty six thousand indices do not fit in sixteen bits");
		Test.Assert(mesh.Parts.Length == 2);
		Test.Assert(mesh.Parts[1].IndexStart == cIndexCount);

		let indices = (uint32*)mesh.IndexData;

		// The first primitive is not shifted.
		Test.Assert(indices[0] == 0);
		Test.Assert(indices[1] == 1);
		Test.Assert(indices[2] == 2);

		// The second is shifted by where its vertices landed, on the WIDE path.
		Test.Assert(indices[cIndexCount + 0] == 3, scope $"got {indices[cIndexCount + 0]}");
		Test.Assert(indices[cIndexCount + 1] == 4);
		Test.Assert(indices[cIndexCount + 2] == 5);

		// Every index is inside the merged vertex buffer, which is what a remap that went
		// wrong would break.
		for (int32 i = 0; i < cIndexCount * 2; i++)
			Test.Assert(indices[i] < (uint32)mesh.VertexCount, scope $"index {i} out of range");

		// And the second primitive's vertices really are the shifted ones.
		let fourth = *(Float3*)(mesh.VertexData + 3 * mesh.VertexStride);
		Test.Assert(Abs(fourth.X - 10.0f) < 0.001f, scope $"got {fourth.X}");
	}
}
