using Sedulous.Core;

namespace Sedulous.UI;

/// A square button that draws an SVG icon over the themed button background.
///
/// For toolbars, row actions, and anything icon only. Themed like the text controls: the
/// background and its states come from the style, the icon inset from the padding, and the
/// tint from the text colour, so an icon button dims with everything else when disabled.
///
/// The icon is BORROWED, typically from an icon set that outlives every button using it.
class IconButton : ButtonBase
{
	private SVGDrawable mIcon = null;
	private float mSize = 20.0f;

	public this(SVGDrawable icon, float size = 20.0f)
	{
		mIcon = icon;
		mSize = size;
	}

	/// Borrowed; may be null.
	public SVGDrawable Icon => mIcon;

	public void SetIcon(SVGDrawable icon)
	{
		mIcon = icon;
		Invalidate();
	}

	/// The ICON's size, not the button's: the chrome is added on top of it.
	public float Size
	{
		get => mSize;
		set
		{
			mSize = value;
			Invalidate();
		}
	}

	protected override Thickness DefaultStylePadding() => .(3, 3);

	/// CONTENT only. The size is the icon's, and the base adds the chrome: measuring the whole
	/// button as mSize would let the padding eat into the icon instead of growing the button.
	protected override Float2 OnMeasureContent(BoxConstraints contentConstraints)
	{
		return .(contentConstraints.ConstrainWidth(mSize), contentConstraints.ConstrainHeight(mSize));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = Rectangle(0, 0, Width, Height);
		let state = GetControlState();
		DrawButtonBackground(ctx, bounds, state);

		if (mIcon == null)
			return;

		let chrome = ResolveBoxMetrics().Chrome;
		var tint = ResolveStyleColor(.TextColor, Color(220 / 255.0f, 225 / 255.0f, 235 / 255.0f, 1.0f));
		if (state.HasFlag(.Disabled))
			tint = Palette.ComputeDisabled(tint);

		// The drawable is SHARED with the icon set, so the tint is put back: leaving it set
		// would recolour the icon everywhere else it is drawn.
		let previous = mIcon.TintColor;
		mIcon.TintColor = tint;
		mIcon.Draw(ctx, .(chrome.Left, chrome.Top, Width - chrome.TotalHorizontal,
			Height - chrome.TotalVertical));
		mIcon.TintColor = previous;
	}
}
