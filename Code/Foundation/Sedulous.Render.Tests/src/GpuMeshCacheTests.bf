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

	/// A mesh that is gone gives its streams back once the frames in flight are past, and the
	/// next mesh is placed in what it left.
	[Test]
	public static void AMeshGoneGivesItsStreamsBackAfterTheFramesInFlight()
	{
		let harness = scope Harness();
		let cache = scope GpuMeshCache(harness.Device, 2);

		let keep = Primitives.Cube(1.0f);
		defer delete keep;
		Test.Assert(cache.GetOrUpload(keep) case .Ok);

		let gone = Primitives.Sphere(1.0f, 16, 8);
		Test.Assert(cache.GetOrUpload(gone) case .Ok);
		Test.Assert(cache.Size == 2);
		delete gone;

		cache.Tick();
		Test.Assert(cache.Size == 1);
		Test.Assert(cache.RetiredCount == 1);
		// The frames in flight may still draw it.
		Test.Assert(cache.FreeVertexBytes == 0);
		cache.Tick();
		Test.Assert(cache.RetiredCount == 1);
		cache.Tick();
		Test.Assert(cache.RetiredCount == 0);
		let freed = cache.FreeVertexBytes;
		Test.Assert(freed > 0);

		let next = Primitives.Cube(2.0f);
		defer delete next;
		Test.Assert(cache.GetOrUpload(next) case .Ok);
		// Placed in what the sphere left.
		Test.Assert(cache.FreeVertexBytes < freed);
	}

	/// A mesh rebuilt in place (ContentChanged) uploads again rather than keeping its first
	/// upload.
	[Test]
	public static void AMeshRebuiltInPlaceUploadsAgain()
	{
		let harness = scope Harness();
		let cache = scope GpuMeshCache(harness.Device);

		let mesh = Primitives.Cube(1.0f);
		defer delete mesh;
		Test.Assert(cache.GetOrUpload(mesh) case .Ok(let first));
		// Unchanged: the same upload.
		Test.Assert(cache.GetOrUpload(mesh) case .Ok(let again));
		Test.Assert(again.VertexOffset == first.VertexOffset);

		let bigger = Primitives.Sphere(1.0f, 16, 8);
		defer delete bigger;
		mesh.Vertices.Clear();
		for (let vertex in bigger.Vertices)
			mesh.Vertices.Add(vertex);
		mesh.Indices.Resize(bigger.IndexCount); // sized first: Add writes into the count
		for (uint32 i = 0; i < bigger.IndexCount; i++)
			mesh.Indices.Add(bigger.Indices.Get(i));
		mesh.ContentChanged();

		Test.Assert(cache.GetOrUpload(mesh) case .Ok(let rebuilt));
		// The new geometry, not the cube's.
		Test.Assert(rebuilt.IndexCount == bigger.IndexCount);
		Test.Assert(rebuilt.VertexOffset != first.VertexOffset);
		// The cube's streams wait for the frames in flight.
		Test.Assert(cache.RetiredCount == 1);
		Test.Assert(cache.Size == 1);
	}
}
