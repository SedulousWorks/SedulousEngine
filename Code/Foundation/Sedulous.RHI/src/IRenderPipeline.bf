namespace Sedulous.RHI;

/// A compiled rasterization pipeline.
interface IRenderPipeline
{
	/// The layout it was built against. A bind group is valid here only if its layout
	/// matches the corresponding slot of this one.
	IPipelineLayout Layout { get; }
}
