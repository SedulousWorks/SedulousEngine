using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// Callback for render pass execution - receives an IRenderPassEncoder
public delegate void RenderPassExecuteCallback(IRenderPassEncoder encoder);

/// Callback for compute pass execution - receives an IComputePassEncoder
public delegate void ComputePassExecuteCallback(IComputePassEncoder encoder);

/// Callback for copy pass execution - receives an ICommandEncoder
public delegate void CopyPassExecuteCallback(ICommandEncoder encoder);
