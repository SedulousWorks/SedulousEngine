using System;

namespace Sedulous.RHI;

struct RenderPassDesc
{
	public ColorAttachmentList ColorAttachments = .();
	/// Null for a colour only pass.
	public DepthStencilAttachment? DepthStencilAttachment = null;

	/// Timestamps written at pass begin and end. Null for neither.
	public IQuerySet TimestampQuerySet = null;
	public uint32 BeginTimestampIndex = 0;
	public uint32 EndTimestampIndex = 0;

	/// The set BeginOcclusionQuery and EndOcclusionQuery will write into. WebGPU REQUIRES
	/// it declared here at pass begin; Vulkan and DX12 receive the set in the call itself
	/// and need nothing, though the validation layer cross checks the two agree.
	public IQuerySet OcclusionQuerySet = null;

	/// How draws are supplied. Set SecondaryCommandBuffers to execute render bundles into
	/// this pass: Vulkan must know at begin time, and the others ignore it.
	public RenderPassContents Contents = .Inline;
	public StringView Label = default;

	public this() {}
}
