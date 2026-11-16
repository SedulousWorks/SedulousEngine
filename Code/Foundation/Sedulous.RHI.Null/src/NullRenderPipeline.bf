using Sedulous.RHI;

namespace Sedulous.RHI.Null;

class NullRenderPipeline : IRenderPipeline
{
	public IPipelineLayout Layout { get; set; }
	/// The primitive state the pipeline was created with, so a test can see what a caller asked
	/// for (its culling, whether depth clips).
	public PrimitiveState Primitive;
}
