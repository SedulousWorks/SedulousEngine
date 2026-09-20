using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.Editor.App;

/// A generic list-of-asset-slots PropertyEditor: one property-grid row whose editor view is a
/// header (the add icon, top right) over a column of slot rows, each an AssetPickerSlot that
/// fills plus move-up, move-down and remove icon buttons. Fully callback-driven, no
/// reflection or component coupling: the consumer wires OnAdd, OnPickSlot, OnRemoveSlot and
/// OnMoveSlot and sets SlotNames before the row builds. Shared, so the scene inspector's
/// material and container lists and the bespoke asset pages compose the identical widget.
class ContainerListEditor : PropertyEditor
{
	/// Pick or assign the asset in slot i. Owned.
	public delegate void(int index) OnPickSlot ~ delete _;
	/// Remove slot i. Owned.
	public delegate void(int index) OnRemoveSlot ~ delete _;
	/// Reorder slot i; true is up. Owned.
	public delegate void(int index, bool up) OnMoveSlot ~ delete _;
	/// Append a new, empty slot. Owned.
	public delegate void() OnAdd ~ delete _;
	/// Per-slot display text, set before the row builds.
	public List<String> SlotNames = new .() ~ DeleteContainerAndItems!(_);

	public this(StringView name, StringView category) : base(name, category) {}

	public override void RefreshView() {}

	protected override View CreateEditorView()
	{
		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 2.0f;

		// The header: a spacer that grows plus the add icon pinned to the right.
		{
			let header = new FlexLayout();
			header.Direction = .Horizontal;
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			header.AddView(new FlexLayout(), grow);
			let add = new IconButton(EditorIcons.Add);
			add.OnClick.Add(new (b) => { if (OnAdd != null) OnAdd(); });
			header.AddView(add);
			column.AddView(header, RowStyle());
		}

		// The slot rows: a picker slot that fills plus move-up, move-down and remove.
		for (int i < SlotNames.Count)
		{
			let row = new FlexLayout();
			row.Direction = .Horizontal;
			row.Spacing = 4.0f;

			let slot = new AssetPickerSlot(SlotNames[i]);
			slot.SetFontSize(12.0f);
			slot.OnPick = new [=i, =this]() => { if (OnPickSlot != null) OnPickSlot(i); };
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			row.AddView(slot, grow);

			let up = new IconButton(EditorIcons.MoveUp);
			up.IsEnabled = i > 0;
			up.OnClick.Add(new [=i, =this](b) => { if (OnMoveSlot != null) OnMoveSlot(i, true); });
			row.AddView(up);
			let down = new IconButton(EditorIcons.MoveDown);
			down.IsEnabled = i + 1 < SlotNames.Count;
			down.OnClick.Add(new [=i, =this](b) => { if (OnMoveSlot != null) OnMoveSlot(i, false); });
			row.AddView(down);
			let remove = new IconButton(EditorIcons.Remove);
			remove.OnClick.Add(new [=i, =this](b) => { if (OnRemoveSlot != null) OnRemoveSlot(i); });
			row.AddView(remove);

			column.AddView(row, RowStyle());
		}
		return column;
	}

	private static LayoutStyle RowStyle()
	{
		var style = LayoutStyle();
		style.Width = SizeSpec.Match();
		style.Height = SizeSpec.Fixed(Unit.Dp(22.0f));
		return style;
	}
}
