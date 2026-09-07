namespace Sedulous.RHI;

struct PrimitiveState
{
	public PrimitiveTopology Topology = .TriangleList;
	public FrontFace FrontFace = .CCW;
	public CullMode CullMode = .None;
	public FillMode FillMode = .Solid;
	/// When false, geometry outside the depth range is CLAMPED rather than clipped, which
	/// is what a shadow caster past the near plane needs. Requires the depth clamp feature.
	public bool DepthClipEnabled = true;

	public this() {}
}
