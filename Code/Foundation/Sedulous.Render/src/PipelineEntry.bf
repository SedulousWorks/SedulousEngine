using Sedulous.RHI;

namespace Sedulous.Render;

/// One entry of a pass's per format pipeline cache.
struct PipelineEntry
{
	public IRenderPipeline Pipeline = null;
	public TextureFormat Format = .Undefined;
	/// What the shader's version was when this was built, so a hot reload rebuilds it.
	public uint64 ShaderVersion = 0;

	public this() {}
}
