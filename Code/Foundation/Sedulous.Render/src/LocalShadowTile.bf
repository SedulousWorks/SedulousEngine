using Sedulous.Core;

namespace Sedulous.Render;

/// One local light's tile in the shadow atlas: where it sits, what it looks along, and the
/// sphere its casters are culled against.
struct LocalShadowTile
{
	public Float4x4 ViewProjection = .Identity();
	public uint32 X = 0;
	public uint32 Y = 0;
	public uint32 Width = 0;
	public uint32 Height = 0;

	/// The light's own position and reach, which is what a caster is tested against.
	public Float3 CullCenter = .(0, 0, 0);
	public float CullRadius = 0.0f;

	public this() {}
}
