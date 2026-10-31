using Sedulous.UI;

namespace Samples.UISandbox;

/// The drag payload the chips produce, carrying the chip it came from.
///
/// The drop targets match on the FORMAT and then cast, which is safe because nothing else in
/// the sandbox produces this format.
class ChipDragData : DragData
{
	/// BORROWED: the chip is in the view tree and outlives the drag.
	public DragChip SourceChip = null;

	public this(DragChip source) : base("demo/chip")
	{
		SourceChip = source;
	}
}
