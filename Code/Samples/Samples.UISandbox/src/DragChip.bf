using Sedulous.Core;
using Sedulous.UI;

namespace Samples.UISandbox;

/// A coloured square that can be picked up.
///
/// It fades while it is being dragged, so the chip under the cursor reads as the one in flight
/// rather than as a duplicate.
class DragChip : ColorView, IDragSource
{
	public this(Color color) : base(color, 30.0f, 30.0f) {}

	public override IDragSource AsDragSource() => this;

	public DragData CreateDragData() => new ChipDragData(this);

	public View CreateDragVisual(DragData data)
	{
		let panel = new Panel();
		panel.Padding = .(6, 2);
		panel.SetStyle(.Background, new ColorDrawable(Color.Value));

		let label = new Label();
		label.SetText("chip");
		panel.AddView(label);
		return panel;
	}

	public void OnDragStarted(DragData data) => Opacity = 0.4f;

	public void OnDragCompleted(DragData data, DragDropEffects effect, bool cancelled) =>
		Opacity = 1.0f;
}
