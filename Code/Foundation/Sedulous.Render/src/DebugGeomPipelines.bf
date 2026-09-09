using Sedulous.RHI;

namespace Sedulous.Render;

/// One entry of the debug geometry pipeline cache: the four buckets built for a given pair of
/// target formats.
///
/// Keyed by BOTH formats, because a frame can hold views whose targets differ, and destroying
/// a set on a mismatch would free pipelines an earlier view's recorded commands still refer to.
struct DebugGeomPipelines
{
	public TextureFormat ColorFormat = .Undefined;
	public TextureFormat DepthFormat = .Undefined;
	public IRenderPipeline LineDepth = null;
	public IRenderPipeline LineOverlay = null;
	public IRenderPipeline TriangleDepth = null;
	public IRenderPipeline TriangleOverlay = null;
	/// What the shader's version was when these were built, so a hot reload rebuilds them.
	public uint64 ShaderVersion = 0;

	public this() {}
}
