using Sedulous.RHI;

namespace Sedulous.Engine.Particles;

/// One cached pipeline, with what it was built for.
///
/// The format and the shader version are BOTH compared on a hit: a target format change and a
/// hot reload each invalidate a pipeline, and neither is visible from the pipeline itself.
struct ParticlePipelineEntry
{
	public IRenderPipeline Pso = null;
	public TextureFormat Format = .Undefined;
	public uint64 ShaderVersion = 0;

	public this() {}
}
