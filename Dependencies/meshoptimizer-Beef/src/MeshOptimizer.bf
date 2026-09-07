using System;

namespace meshoptimizer_Beef;

/*
 * meshoptimizer - mesh optimisation and simplification.
 *
 * Source: https://github.com/zeux/meshoptimizer
 * Version: MESHOPTIMIZER_VERSION 1020 (v1.2)
 * License: MIT (meshoptimizer/LICENSE.md)
 *
 * TRIMMED VENDORING, following Raptor's: index and vertex optimisation
 * (vcache/overdraw/vfetch plus the remap generators), simplification, and the
 * analyzers. No codecs, clusterizer, meshlets or stripifier.
 *
 * This file declares ONLY what the vendored translation units define. The upstream
 * header declares a great deal more; binding any of it would compile happily and fail
 * at link time on the first call, which is a much worse place to find out. The set
 * below was taken from `nm` over the built archive, not from the header.
 *
 * Sizes are `uint` (size_t) and indices are uint32 throughout, matching the C API.
 */

/// A vertex attribute stream, for the Multi variants: several separate arrays describing
/// the same vertices, rather than one interleaved buffer.
[CRepr]
struct meshopt_Stream
{
	public void* data;
	/// Bytes of THIS attribute per vertex.
	public uint size;
	/// Bytes from one vertex to the next, which is larger than size when the attribute
	/// lives inside an interleaved buffer.
	public uint stride;
}

[CRepr]
struct meshopt_VertexCacheStatistics
{
	public uint32 vertices_transformed;
	public uint32 warps_executed;
	/// Transformed vertices per triangle. Best 0.5, worst 3.0.
	public float acmr;
	/// Transformed vertices per vertex. Best 1.0, worst 6.0; 1.0 means each was
	/// transformed exactly once.
	public float atvr;
}

[CRepr]
struct meshopt_VertexFetchStatistics
{
	public uint32 bytes_fetched;
	/// Fetched bytes over vertex buffer size. Best 1.0.
	public float overfetch;
}

[CRepr]
struct meshopt_OverdrawStatistics
{
	public uint32 pixels_covered;
	public uint32 pixels_shaded;
	/// Shaded over covered. Best 1.0.
	public float overdraw;
}

[CRepr]
struct meshopt_CoverageStatistics
{
	public float[3] coverage;
	/// Viewport size in mesh coordinates.
	public float extent;
}

/// Options for the simplify family, combined as flags.
enum meshopt_SimplifyOptions : uint32
{
	None = 0,
	/// Leave vertices on the topological border where they are. For simplifying part of a
	/// larger mesh, whose seams must still meet the rest of it.
	LockBorder = 1 << 0,
	/// The indices are a sparse subset of the mesh. Faster, but the error becomes relative
	/// to the SUBSET's extents rather than the whole mesh's.
	Sparse = 1 << 1,
	/// Treat the error limit, and the reported error, as absolute rather than relative to
	/// the mesh extents.
	ErrorAbsolute = 1 << 2,
	/// Drop disconnected parts as it goes.
	Prune = 1 << 3,
	/// Prefer regular triangle sizes and shapes, at some cost to geometric and attribute
	/// quality.
	Regularize = 1 << 4,
	/// Experimental. Allow collapses across attribute discontinuities, except at vertices
	/// tagged Protect.
	Permissive = 1 << 5,
	/// Regularize, more gently.
	RegularizeLight = 1 << 6,
}

/// Per vertex flags for the `vertex_lock` arrays.
enum meshopt_SimplifyVertexFlags : uint8
{
	None = 0,
	/// Do not move this vertex.
	Lock = 1 << 0,
}

static
{
	public const int32 MESHOPTIMIZER_VERSION = 1020;

	// ---- remapping -------------------------------------------------------------------

	/// Builds a remap table and returns the unique vertex count. `indices` may be null for
	/// an unindexed mesh, in which case the vertices are taken in order.
	[CLink]
	public static extern uint meshopt_generateVertexRemap(uint32* destination, uint32* indices,
		uint index_count, void* vertices, uint vertex_count, uint vertex_size);

	[CLink]
	public static extern uint meshopt_generateVertexRemapMulti(uint32* destination, uint32* indices,
		uint index_count, uint vertex_count, meshopt_Stream* streams, uint stream_count);

	/// The caller decides which vertices count as equal, through the callback. For welding
	/// on a tolerance rather than on exact bytes.
	[CLink]
	public static extern uint meshopt_generateVertexRemapCustom(uint32* destination, uint32* indices,
		uint index_count, float* vertex_positions, uint vertex_count, uint vertex_positions_stride,
		function int32(void* context, uint32 a, uint32 b) callback, void* context);

	[CLink]
	public static extern void meshopt_remapIndexBuffer(uint32* destination, uint32* indices,
		uint index_count, uint32* remap);

	[CLink]
	public static extern void meshopt_remapVertexBuffer(void* destination, void* vertices,
		uint vertex_count, uint vertex_size, uint32* remap);

	// ---- derived index buffers -------------------------------------------------------

	/// Indices that treat vertices with equal POSITION as one, whatever else differs. What
	/// a shadow pass wants: it only needs the silhouette.
	[CLink]
	public static extern void meshopt_generateShadowIndexBuffer(uint32* destination, uint32* indices,
		uint index_count, void* vertices, uint vertex_count, uint vertex_size, uint vertex_stride);

	[CLink]
	public static extern void meshopt_generateShadowIndexBufferMulti(uint32* destination,
		uint32* indices, uint index_count, uint vertex_count, meshopt_Stream* streams,
		uint stream_count);

	/// Six indices per triangle: the three corners plus the three opposite ones, for a
	/// geometry shader that needs the neighbours.
	[CLink]
	public static extern void meshopt_generateAdjacencyIndexBuffer(uint32* destination,
		uint32* indices, uint index_count, float* vertex_positions, uint vertex_count,
		uint vertex_positions_stride);

	/// Twelve indices per triangle, for hardware tessellation with crack free edges.
	[CLink]
	public static extern void meshopt_generateTessellationIndexBuffer(uint32* destination,
		uint32* indices, uint index_count, float* vertex_positions, uint vertex_count,
		uint vertex_positions_stride);

	/// Gives every triangle its own provoking vertex, which is how flat shading gets a
	/// per triangle value without duplicating whole vertices.
	[CLink]
	public static extern uint meshopt_generateProvokingIndexBuffer(uint32* destination,
		uint32* reorder, uint32* indices, uint index_count, uint vertex_count);

	/// A remap that maps vertices with equal positions together.
	[CLink]
	public static extern void meshopt_generatePositionRemap(uint32* destination,
		float* vertex_positions, uint vertex_count, uint vertex_positions_stride);

	/// Keeps only the triangles whose vertices pass, returning the new index count.
	[CLink]
	public static extern uint meshopt_filterIndexBuffer(uint32* destination, uint32* indices,
		uint index_count, void* vertices, uint vertex_count, uint vertex_size, uint vertex_stride);

	[CLink]
	public static extern uint meshopt_filterIndexBufferMulti(uint32* destination, uint32* indices,
		uint index_count, uint vertex_count, meshopt_Stream* streams, uint stream_count);

	// ---- optimisation ----------------------------------------------------------------

	/// Reorders triangles for the post transform vertex cache. The first thing to run, and
	/// the one that matters most.
	[CLink]
	public static extern void meshopt_optimizeVertexCache(uint32* destination, uint32* indices,
		uint index_count, uint vertex_count);

	/// For hardware with a fixed size FIFO cache rather than a modern one.
	[CLink]
	public static extern void meshopt_optimizeVertexCacheFifo(uint32* destination, uint32* indices,
		uint index_count, uint vertex_count, uint32 cache_size);

	/// Optimises for the cache while keeping the mesh strip friendly.
	[CLink]
	public static extern void meshopt_optimizeVertexCacheStrip(uint32* destination, uint32* indices,
		uint index_count, uint vertex_count);

	/// Reorders triangles to reduce overdraw, WITHOUT undoing the cache ordering beyond
	/// the threshold: 1.05 allows a five percent ACMR regression to buy overdraw.
	[CLink]
	public static extern void meshopt_optimizeOverdraw(uint32* destination, uint32* indices,
		uint index_count, float* vertex_positions, uint vertex_count, uint vertex_positions_stride,
		float threshold);

	/// Reorders the VERTEX buffer so it is read front to back, and rewrites the indices in
	/// place. Run last, after the index order is settled.
	[CLink]
	public static extern uint meshopt_optimizeVertexFetch(void* destination, uint32* indices,
		uint index_count, void* vertices, uint vertex_count, uint vertex_size);

	/// The same reordering as a remap table, for a caller that has several parallel vertex
	/// streams to move.
	[CLink]
	public static extern uint meshopt_optimizeVertexFetchRemap(uint32* destination, uint32* indices,
		uint index_count, uint vertex_count);

	// ---- simplification --------------------------------------------------------------

	/// Collapses edges down towards the target index count, stopping early if the error
	/// would exceed target_error. Returns the resulting index count and, through
	/// result_error, what it actually cost.
	[CLink]
	public static extern uint meshopt_simplify(uint32* destination, uint32* indices,
		uint index_count, float* vertex_positions, uint vertex_count, uint vertex_positions_stride,
		uint target_index_count, float target_error, meshopt_SimplifyOptions options,
		float* result_error);

	/// Simplification that also considers vertex attributes, each weighted: a UV seam or a
	/// colour boundary survives that plain geometric simplification would collapse.
	[CLink]
	public static extern uint meshopt_simplifyWithAttributes(uint32* destination, uint32* indices,
		uint index_count, float* vertex_positions, uint vertex_count, uint vertex_positions_stride,
		float* vertex_attributes, uint vertex_attributes_stride, float* attribute_weights,
		uint attribute_count, uint8* vertex_lock, uint target_index_count, float target_error,
		meshopt_SimplifyOptions options, float* result_error);

	/// Simplifies IN PLACE, updating the positions and attributes as it goes rather than
	/// only reindexing.
	[CLink]
	public static extern uint meshopt_simplifyWithUpdate(uint32* indices, uint index_count,
		float* vertex_positions, uint vertex_count, uint vertex_positions_stride,
		float* vertex_attributes, uint vertex_attributes_stride, float* attribute_weights,
		uint attribute_count, uint8* vertex_lock, uint target_index_count, float target_error,
		meshopt_SimplifyOptions options, float* result_error);

	/// Much faster and much less careful: it does not preserve topology, so it is for a
	/// distant LOD rather than the next one down.
	[CLink]
	public static extern uint meshopt_simplifySloppy(uint32* destination, uint32* indices,
		uint index_count, float* vertex_positions, uint vertex_count, uint vertex_positions_stride,
		uint8* vertex_lock, uint target_index_count, float target_error, float* result_error);

	/// Simplifies a POINT cloud rather than a mesh, optionally weighting by colour.
	[CLink]
	public static extern uint meshopt_simplifyPoints(uint32* destination, float* vertex_positions,
		uint vertex_count, uint vertex_positions_stride, float* vertex_colors,
		uint vertex_colors_stride, float color_weight, uint target_vertex_count);

	/// Removes the disconnected parts small enough to be under the error, and nothing else.
	[CLink]
	public static extern uint meshopt_simplifyPrune(uint32* destination, uint32* indices,
		uint index_count, float* vertex_positions, uint vertex_count, uint vertex_positions_stride,
		float target_error);

	/// The scaling factor between the RELATIVE error the simplifier reports and world
	/// units: absolute error is result_error times this.
	[CLink]
	public static extern float meshopt_simplifyScale(float* vertex_positions, uint vertex_count,
		uint vertex_positions_stride);

	// ---- analysis --------------------------------------------------------------------

	[CLink]
	public static extern meshopt_VertexCacheStatistics meshopt_analyzeVertexCache(uint32* indices,
		uint index_count, uint vertex_count, uint32 cache_size, uint32 warp_size,
		uint32 primgroup_size);

	[CLink]
	public static extern meshopt_VertexFetchStatistics meshopt_analyzeVertexFetch(uint32* indices,
		uint index_count, uint vertex_count, uint vertex_size);

	[CLink]
	public static extern meshopt_OverdrawStatistics meshopt_analyzeOverdraw(uint32* indices,
		uint index_count, float* vertex_positions, uint vertex_count, uint vertex_positions_stride);

	[CLink]
	public static extern meshopt_CoverageStatistics meshopt_analyzeCoverage(uint32* indices,
		uint index_count, float* vertex_positions, uint vertex_count, uint vertex_positions_stride);

	// ---- allocator -------------------------------------------------------------------

	/// Replaces the allocator the library uses for its scratch buffers. Set it once at
	/// startup, before anything else here is called.
	[CLink]
	public static extern void meshopt_setAllocator(function void*(uint size) allocate,
		function void(void* block) deallocate);
}
