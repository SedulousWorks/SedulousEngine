namespace Sedulous.RHI;

/// An immutable, pre-recorded sequence of draw commands, replayable into any
/// compatible render pass (matching attachment formats) via
/// IRenderPassEncoder.ExecuteBundles. Valid until its owning command pool is
/// reset. Recorded off the main thread for parallel command recording.
interface IRenderBundle
{
}
