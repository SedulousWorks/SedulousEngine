using Sedulous.Core;
using Sedulous.Heightfield;
using Sedulous.Resource;

namespace Sedulous.Editor.Terrain;

/// Where the sculpt brush's ray met a terrain: the grid it hit, in heightfield local space.
struct SculptPick
{
	/// The heightfield reference as the terrain holds it: the live grid plus the SOURCE
	/// asset guid the stroke persists back to, which may be nil for an in memory grid.
	public Ref<Heightfield> Grid = default;
	public float LocalX = 0.0f;
	public float LocalZ = 0.0f;
	/// The local surface height at the hit, the Ctrl+click flatten target.
	public float LocalY = 0.0f;
	public Float3 WorldHit = .Zero;
	public Float3 WorldNormal = .(0.0f, 1.0f, 0.0f);
	public bool Valid = false;

	public this() {}
}
