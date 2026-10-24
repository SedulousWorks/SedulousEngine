using System;
using Sedulous.Core;

namespace Sedulous.GUI;

// Tooltip: a small text panel, what a node's tooltip shows by default (Node.CreateTooltipContent).
// The dispatcher shows it: the nearest tooltip text up the parent chain from the hovered node,
// after a delay on the GUI's clock, as a hint popup placed by the pointer; any press or key hides
// it. Styled as `tooltip`.

class Tooltip : UIWidget
{
	private Sedulous.GUI.Text mText = new .() ~ delete _;
	private Color mBgColor = .(0.10f, 0.11f, 0.14f, 0.96f);

	public this()
	{
		Tag = "tooltip";
		HitTestVisible = false; // never steals pointer events
		using (StyleWriteScope(this)) // its own values, which a sheet returns to
		{
			Padding = .(6.0f, 3.0f, 6.0f, 3.0f);
			SetBox(FilledBox(mBgColor, scope NodeBox())); // its own face, which a sheet's (a theme's) replaces
		}
		mText.SetAlignment(.Start, .Middle);
	}

	public StringView Text
	{
		get => mText.GetString();
		set
		{
			mText.SetString(value);
			Invalidate();
		}
	}

	/// Natural size for the text plus padding.
	public Float2 MeasureText()
	{
		let t = mText.Measure();
		let pad = Padding;
		return .(t.X + pad.TotalHorizontal, t.Y + pad.TotalVertical);
	}

	/// Its text on one line (its padding is added around it).
	public override Float2 MeasureContent(Float2 available) => mText.Measure();

	// Its text draws in its text style.
	protected override void OnTextStyleChange()
	{
		let style = GetTextStyle();
		mText.Font = Font;
		mText.SetFontSelection(FontService, style.FontFamily, style.Selection);
		mText.Direction = TextDirectionFor();
		mText.Color = TextColor;
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		mText.Draw(ctx, ContentBounds);
	}
}
