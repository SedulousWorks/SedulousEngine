namespace Sedulous.GUI;

using Sedulous.Core.Mathematics;

/// View that renders any Drawable at a given size.
/// Uses DesiredWidth/DesiredHeight if set, otherwise falls back
/// to the drawable's IntrinsicSize, then 0.
public class DrawableView : View
{
	/// The drawable to render. Ownership controlled by OwnsDrawable.
	public Drawable Drawable;

	/// When true, this view deletes the drawable on destruction.
	public bool OwnsDrawable;

	/// Explicit desired width. Overrides intrinsic size.
	public Property<float?> DesiredWidth = new .(null) ~ delete _;

	/// Explicit desired height. Overrides intrinsic size.
	public Property<float?> DesiredHeight = new .(null) ~ delete _;

	public this()
	{
		DesiredWidth.SetOwner(this);
		DesiredHeight.SetOwner(this);
	}

	public this(Drawable drawable, bool ownsDrawable = false) : this()
	{
		Drawable = drawable;
		OwnsDrawable = ownsDrawable;
	}

	public this(Drawable drawable, float width, float height, bool ownsDrawable = false) : this()
	{
		Drawable = drawable;
		DesiredWidth.SetSilent(width);
		DesiredHeight.SetSilent(height);
		OwnsDrawable = ownsDrawable;
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let intrinsic = Drawable?.IntrinsicSize;
		let w = DesiredWidth.Value ?? intrinsic?.X ?? 0;
		let h = DesiredHeight.Value ?? intrinsic?.Y ?? 0;
		MeasuredSize = .(constraints.ConstrainWidth(w), constraints.ConstrainHeight(h));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		if (Drawable != null)
			Drawable.Draw(ctx, .(0, 0, Width, Height), GetControlState());
	}

	public ~this()
	{
		if (OwnsDrawable && Drawable != null)
			delete Drawable;
	}
}
