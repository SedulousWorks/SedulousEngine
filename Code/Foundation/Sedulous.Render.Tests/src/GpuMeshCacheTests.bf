using System;
using Sedulous.Geometry;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// The mesh upload cache: a mesh's streams reach the GPU once and are reused after.
class GpuMeshCacheTests
{
	private class Harness
	{
		public IBackend Backend ~ delete _;
		public IDevice Device;

		public this()
		{
			Backend = NullRhi.CreateBackend();
			Device = Backend.EnumerateAdapters()[0].CreateDevice(.()).Value;
		}
	}

	[Test]
	public static void AMeshUploadsOnceAndIsReusedAfter()
	{
		let harness = scope Harness();
		let cache = scope GpuMeshCache(harness.Device);

		let cube = Primitives.Cube(1.0f);
		defer delete cube;

		Test.Assert(cache.GetOrUpload(cube) case .Ok(let uploaded));
		Test.Assert(uploaded.VertexBuffer != null);
		Test.Assert(uploaded.IndexBuffer != null);
		Test.Assert(uploaded.IndexCount == cube.IndexCount);
		Test.Assert(cache.Size == 1);

		// The SAME entry comes back, rather than the streams being sent again.
		Test.Assert(cache.GetOrUpload(cube) case .Ok(let again));
		Test.Assert(again.VertexBuffer == uploaded.VertexBuffer);
		Test.Assert(again.VertexOffset == uploaded.VertexOffset);
		Test.Assert(again.IndexOffset == uploaded.IndexOffset);
		Test.Assert(cache.Size == 1);
	}

	/// Two meshes are two entries, and they land at DIFFERENT places in the pooled buffers:
	/// the pool is shared, so an offset collision would draw one mesh's indices over the
	/// other's vertices.
	[Test]
	public static void ASecondMeshIsItsOwnEntry()
	{
		let harness = scope Harness();
		let cache = scope GpuMeshCache(harness.Device);

		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let sphere = Primitives.Sphere(1.0f, 8, 4);
		defer delete sphere;

		Test.Assert(cache.GetOrUpload(cube) case .Ok(let first));
		Test.Assert(cache.GetOrUpload(sphere) case .Ok(let second));

		Test.Assert(second.IndexCount == sphere.IndexCount);
		Test.Assert(cache.Size == 2);
		Test.Assert((first.VertexBuffer != second.VertexBuffer)
			|| (first.VertexOffset != second.VertexOffset));
	}

	[Test]
	public static void ClearingFreesEverything()
	{
		let harness = scope Harness();
		let cache = scope GpuMeshCache(harness.Device);

		let cube = Primitives.Cube(1.0f);
		defer delete cube;

		Test.Assert(cache.GetOrUpload(cube) case .Ok);
		Test.Assert(cache.Size == 1);

		cache.Clear();
		Test.Assert(cache.Size == 0);

		// And it still works after, rather than being left in a torn down state.
		Test.Assert(cache.GetOrUpload(cube) case .Ok);
		Test.Assert(cache.Size == 1);
	}

	/// NO MESH is a normal state and uploads nothing. A mesh with an empty stream is not
	/// normal, but the draw path is indexed only, so it would draw nothing anyway: it is
	/// refused rather than cached as a draw of no triangles.
	[Test]
	public static void NothingAndAnEmptyMeshUploadNothing()
	{
		let harness = scope Harness();
		let cache = scope GpuMeshCache(harness.Device);

		Test.Assert(cache.GetOrUpload(null) case .Err);

		let empty = scope StaticMesh();
		Test.Assert(cache.GetOrUpload(empty) case .Err);
		Test.Assert(cache.Size == 0);
	}
}
