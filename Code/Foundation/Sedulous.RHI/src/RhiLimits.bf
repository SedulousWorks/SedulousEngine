namespace Sedulous.RHI;

/// Fixed upper bounds the RHI itself imposes, as opposed to a device's reported limits.
static class RhiLimits
{
	/// How many colour attachments one render pass can carry. A fixed bound rather than a
	/// device limit because the attachment lists are inline arrays sized by it.
	public const int32 MaxColorAttachments = 8;
}
