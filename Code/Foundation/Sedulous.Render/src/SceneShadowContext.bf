using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Render;

/// Every shadow input sourced from ONE scene.
///
/// A frame can render several DISTINCT scenes side by side, and each view reads its own
/// scene's context and never another's: the caster list, the light direction, the atlas tiles
/// and the static cache's signature all live here. Sourcing them from a single primary scene
/// instead bleeds one scene's shadows into the other and never renders the other's at all.
///
/// Pooled, because the graph's execute callbacks capture these, so the addresses have to
/// outlive the frame and must not move when the pool grows.
class SceneShadowContext
{
	/// Borrowed, and the pool's key.
	public ExtractedScene Scene = null;

	/// The camera INDEPENDENT caster list for this scene.
	public List<DrawItem> Casters = new .() ~ delete _;
	/// Aligned to the casters: the centre in the first three and the radius in the fourth.
	/// A compact array so the per cascade cull streams it linearly rather than chasing each
	/// item's own allocation, which is what the cull cost at scale.
	public List<Float4> CasterBounds = new .() ~ delete _;
	/// The skinned casters' world spheres, which is what routes a static tile's refresh.
	public List<BoundingSphere> AnimatedSpheres = new .() ~ delete _;

	/// This scene's tiles in the static layer this frame.
	public List<LocalShadowTile> StaticTiles = new .() ~ delete _;
	/// The subset dirty THIS frame, which is what actually renders.
	public List<LocalShadowTile> StaticRenderTiles = new .() ~ delete _;
	/// A per tile refresh countdown, so a dirtied tile re-renders once per frame in flight
	/// and every slot's copy ends up current.
	public List<uint32> StaticTileDirty = new .() ~ delete _;

	/// The static casters' signature, which is what invalidates the cache.
	public uint64 StaticSignature = 0;
	/// Detects a pool slot being reused by another scene, which dirties everything.
	public ExtractedScene LastStaticScene = null;
	/// This scene's first static tile, so a shift in the atlas layout under it dirties it.
	public uint32 StaticTileBase = 0;

	/// This scene's first entry in the frame's concatenated local shadow buffer.
	public uint32 EntryBase = 0;

	/// This scene's environment products, borrowed from the image based lighting system.
	public IblContext Ibl = null;
}
