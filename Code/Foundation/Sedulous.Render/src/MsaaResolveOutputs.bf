using Sedulous.RenderGraph;

namespace Sedulous.Render;

/// The single sampled depth and auxiliary targets the post stack consumes when a view is
/// multisampled.
struct MsaaResolveOutputs
{
	public RGHandle Depth = .Invalid;
	public RGHandle Normal = .Invalid;
	public RGHandle Velocity = .Invalid;
	public RGHandle Material = .Invalid;

	public this() {}

	public bool Valid => Depth.IsValid;
}
