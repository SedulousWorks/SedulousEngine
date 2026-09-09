using Sedulous.Core;

namespace Sedulous.Render;

/// A spot or point light that should cast a shadow, as extraction leaves it.
///
/// The shadow system assigns it atlas tiles and builds its projections at frame time, once
/// the layout is known, and then patches the light's own shadow index to point at what it
/// built.
struct LocalShadowCaster
{
	/// One is a point light, two a spot, mirroring the light's own type field.
	public uint32 Type = 2;

	public Float3 PositionWS = .(0, 0, 0);
	public Float3 DirectionWS = .(0, -1, 0);
	/// The perspective far plane.
	public float Range = 10.0f;
	/// The spot cone's HALF angle, so the field of view is twice this.
	public float OuterAngle = 0.6f;

	/// A static caster renders into the cached atlas layer rather than the realtime one.
	public bool IsStatic = false;

	public this() {}
}
