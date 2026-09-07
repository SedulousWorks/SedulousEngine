namespace Sedulous.RHI;

/// How a swap chain hands finished images to the display.
///
/// Fifo is the only one every backend must support; the rest are requests. Immediate
/// tears, Mailbox replaces an undisplayed image rather than blocking, and FifoRelaxed
/// tears only when a frame arrives late.
enum PresentMode : uint32
{
	Immediate,
	Mailbox,
	Fifo,
	FifoRelaxed
}
