namespace Sedulous.RHI;

/// A compiled mesh shader pipeline, replacing the vertex stages with task and mesh.
interface IMeshPipeline
{
	IPipelineLayout Layout { get; }
}
