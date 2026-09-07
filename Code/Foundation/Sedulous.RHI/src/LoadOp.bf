namespace Sedulous.RHI;

/// What a render pass does with an attachment's existing contents when it begins.
///
/// DontCare is not a free Load: it lets the driver discard, so anything not written by the
/// pass is undefined afterwards. On a tiler it is the difference between reading the whole
/// attachment back into tile memory and not.
enum LoadOp : uint32
{
	Load,
	Clear,
	DontCare
}
