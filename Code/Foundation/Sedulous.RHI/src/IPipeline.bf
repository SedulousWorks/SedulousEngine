namespace Sedulous.RHI;

using System;

/// Defines the overall resource binding layout for a pipeline.
/// Combines bind group layouts (one per set index) and push constant ranges.
/// The same pipeline layout can be shared across multiple pipelines.
/// Destroyed via IDevice.DestroyPipelineLayout().
///
/// Example:
/// ```
/// // set 0 = per-frame data, set 1 = per-material data
/// var pipelineLayout = device.CreatePipelineLayout(.() {
///     BindGroupLayouts = .(perFrameLayout, perMaterialLayout),
///     PushConstantRanges = .(
///         .() { Stages = .Vertex, Offset = 0, Size = 64 }
///     )
/// }).Value;
/// defer device.DestroyPipelineLayout(ref pipelineLayout);
///
/// // Use in pipeline creation:
/// var pipeline = device.CreateRenderPipeline(.() {
///     Layout = pipelineLayout,
///     Vertex = .() { Shader = .(vs, "main" ), Buffers = default },
///     // ...
/// }).Value;
/// ```
interface IPipelineLayout
{
}

/// Caches compiled pipeline state for faster creation on subsequent runs.
/// Vulkan: VkPipelineCache. DX12: ID3D12PipelineLibrary.
/// Destroyed via IDevice.DestroyPipelineCache().
interface IPipelineCache
{
	/// Returns the size needed for GetData().
	uint GetDataSize();

	/// Retrieves the cache blob for serialization to disk.
	/// The buffer must be at least GetDataSize() bytes.
	/// Returns the number of bytes written, or .Err if the buffer is too small.
	Result<int> GetData(Span<uint8> outData);
}

/// A compiled render (graphics) pipeline.
/// Destroyed via IDevice.DestroyRenderPipeline().
interface IRenderPipeline
{
	/// The pipeline layout.
	IPipelineLayout Layout { get; }
}

/// A compiled compute pipeline.
/// Destroyed via IDevice.DestroyComputePipeline().
interface IComputePipeline
{
	/// The pipeline layout.
	IPipelineLayout Layout { get; }
}
