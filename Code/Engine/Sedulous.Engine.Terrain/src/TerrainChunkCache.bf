using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Terrain;

namespace Sedulous.Engine.Terrain;

/// The chunk model built for one heightfield: the grid, the tree over it, and the bounds that
/// contain the lot.
class TerrainChunkCache
{
	public List<TerrainChunk> Chunks = new .() ~ delete _;
	public TerrainQuadtree Quadtree = new .() ~ delete _;
	public AABB LocalBounds = AABB.Empty();
	public uint64 Version = 0;
}
