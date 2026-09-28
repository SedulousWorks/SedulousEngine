using System;
using Sedulous.UI;

namespace Sedulous.Editor.App;

/// The header over a navigation list or tree (a graph's layers, a bus layout, an effect's
/// systems): its title, and the add icon on the right, the same icon a ContainerListEditor's
/// header carries. OWNS the add callback.
class ListHeader : FlexLayout
{
	private delegate void() mOnAdd ~ delete _;

	/// The add icon, for a caller that enables it only while there is room.
	public IconButton AddButton { get; private set; }

	/// `onAdd` is CONSUMED.
	public this(StringView title, StringView addTooltip, delegate void() onAdd)
	{
		mOnAdd = onAdd;
		Direction = .Horizontal;
		let label = new Label(title);
		label.FontSize.Value = 12.0f;
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		grow.AlignSelf = .Center;
		AddView(label, grow);
		AddButton = new IconButton(EditorIcons.Add);
		AddButton.TooltipText.Set(addTooltip);
		AddButton.OnClick.Add(new [=this](b) => { mOnAdd(); });
		var center = LayoutStyle();
		center.AlignSelf = .Center;
		AddView(AddButton, center);
	}

	/// The layout a header takes in its column: full width, one row high.
	public static LayoutStyle RowStyle()
	{
		var style = LayoutStyle();
		style.Width = SizeSpec.Match();
		style.Height = SizeSpec.Fixed(Unit.Dp(22.0f));
		return style;
	}
}
