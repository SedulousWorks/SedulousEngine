using Sedulous.Core;
using Sedulous.UI;

namespace Samples.UISandbox;

/// A row of chips that accepts one of its own back and reorders by SWAPPING colours.
///
/// Swapping rather than moving views keeps the demo about drag and drop instead of about
/// reparenting: the chips never leave the container.
class ChipReorderContainer : FlexLayout, IDropTarget
{
	public override IDropTarget AsDropTarget() => this;

	public DragDropEffects CanAcceptDrop(DragData data, float localX, float localY) =>
		(data.Format == "demo/chip") ? .Move : .None;

	public void OnDragEnter(DragData data, float localX, float localY) {}
	public void OnDragOver(DragData data, float localX, float localY) {}
	public void OnDragLeave(DragData data) {}

	public DragDropEffects OnDrop(DragData data, float localX, float localY)
	{
		if (data.Format != "demo/chip")
			return .None;

		let source = ((ChipDragData)data).SourceChip;

		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if ((localX < child.Bounds.X) || (localX >= (child.Bounds.X + child.Width)))
				continue;

			if (let target = child as DragChip)
			{
				if (target != source)
				{
					let swapped = source.Color.Value;
					source.Color.Value = target.Color.Value;
					target.Color.Value = swapped;
				}
			}

			return .Move;
		}

		return .None;
	}
}
