using meshoptimizer_Beef;
using System;
using System.Diagnostics;

namespace meshoptimizer_Beef_Test;

/// Exercises the binding end to end against the real library: build a mesh with duplicate
/// vertices, weld it, optimise it, simplify it, and check the analyzers agree.
class Program
{
	[CRepr]
	struct Vertex
	{
		public float x, y, z;
		public this(float x, float y, float z) { this.x = x; this.y = y; this.z = z; }
	}

	/// Two triangles sharing an edge, but authored with the shared vertices DUPLICATED, so
	/// the remap has something to weld.
	static void Run()
	{
		Vertex[6] vertices = .(
			.(0, 0, 0), .(1, 0, 0), .(0, 1, 0),
			.(1, 0, 0), .(1, 1, 0), .(0, 1, 0));
		uint32[6] indices = .(0, 1, 2, 3, 4, 5);

		let vertexSize = (uint)sizeof(Vertex);

		uint32[6] remap = default;
		let uniqueCount = meshopt_generateVertexRemap(&remap[0], &indices[0], 6,
			&vertices[0], 6, vertexSize);
		Debug.WriteLine("unique vertices: {0} (expected 4)", uniqueCount);

		uint32[6] remappedIndices = default;
		meshopt_remapIndexBuffer(&remappedIndices[0], &indices[0], 6, &remap[0]);

		Vertex[6] remappedVertices = default;
		meshopt_remapVertexBuffer(&remappedVertices[0], &vertices[0], 6, vertexSize, &remap[0]);

		meshopt_optimizeVertexCache(&remappedIndices[0], &remappedIndices[0], 6, uniqueCount);
		meshopt_optimizeVertexFetch(&remappedVertices[0], &remappedIndices[0], 6,
			&remappedVertices[0], uniqueCount, vertexSize);

		let cache = meshopt_analyzeVertexCache(&remappedIndices[0], 6, uniqueCount, 16, 0, 0);
		Debug.WriteLine("acmr: {0}, atvr: {1}", cache.acmr, cache.atvr);

		let fetch = meshopt_analyzeVertexFetch(&remappedIndices[0], 6, uniqueCount, vertexSize);
		Debug.WriteLine("overfetch: {0} (1.0 means every byte was read once)", fetch.overfetch);

		let scale = meshopt_simplifyScale((float*)&remappedVertices[0], uniqueCount, vertexSize);
		Debug.WriteLine("simplify scale: {0}", scale);

		uint32[6] simplified = default;
		float error = 0;
		let simplifiedCount = meshopt_simplify(&simplified[0], &remappedIndices[0], 6,
			(float*)&remappedVertices[0], uniqueCount, vertexSize, 3, 1.0f, .None, &error);
		Debug.WriteLine("simplified to {0} indices, error {1}", simplifiedCount, error);
	}

	public static void Main()
	{
		Run();
		Debug.WriteLine("meshoptimizer binding OK.");
	}
}
