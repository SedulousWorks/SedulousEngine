namespace Sedulous.RHI;

/// How a render pass's draws are supplied.
///
/// Inline records draws directly into the pass and is the default.
/// SecondaryCommandBuffers means the body comes from executed render bundles ONLY, with no
/// inline draws: Vulkan opens the rendering scope with the secondary command buffer flag,
/// while DX12 and WebGPU ignore it because they allow bundles in any pass.
enum RenderPassContents : uint32
{
	Inline,
	SecondaryCommandBuffers
}
