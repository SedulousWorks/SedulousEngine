using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.Editor.App;

/// A fixed size icon tinted with the current text colour, the content of a mode toggle.
class IconGlyph : View
{
	/// Borrowed: EditorIcons owns it and outlives the panel.
	private SVGDrawable mIcon;
	private float mSize;

	public this(SVGDrawable icon, float size)
	{
		mIcon = icon;
		mSize = size;
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(mSize), constraints.ConstrainHeight(mSize));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		if (mIcon == null)
			return;
		let tint = ResolveStyleColor(.TextColor, .(0.88f, 0.9f, 0.94f, 1.0f));
		let previous = mIcon.TintColor;
		mIcon.TintColor = tint;
		mIcon.Draw(ctx, .(0, 0, Width, Height));
		mIcon.TintColor = previous;
	}
}
