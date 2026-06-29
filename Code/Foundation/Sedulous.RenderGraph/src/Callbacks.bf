using System.Collections;
using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// Callback for render pass execution - receives an IRenderPassEncoder
public delegate void RenderPassExecuteCallback(IRenderPassEncoder encoder);

/// Callback for compute pass execution - receives an IComputePassEncoder
public delegate void ComputePassExecuteCallback(IComputePassEncoder encoder);

/// Callback for copy pass execution - receives an ICommandEncoder
public delegate void CopyPassExecuteCallback(ICommandEncoder encoder);

/// Callback for a render pass whose body is executed render bundles.
/// Called with the encoder still in recording state (before BeginRenderPass)
/// so the callback can create bundle encoders. The callback fills the out-list
/// with finished bundles that the graph will execute into the pass.
public delegate void RenderBundlePassCallback(ICommandEncoder encoder, List<IRenderBundle> outBundles);
