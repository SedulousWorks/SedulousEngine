using Sedulous.Core;

namespace Sedulous.UI;

/// A view that renders any Drawable at a given size.
///
/// The size is DesiredWidth/DesiredHeight when set, the drawable's intrinsic size when it has
/// one, and zero otherwise.
///
/// OWNS a reference to the drawable: assigning through SetDrawable consumes the caller's, the
/// way AddView consumes a child's.
class DrawableView : View
{
	private Drawable mDrawable ~ _?.ReleaseRef();

	public Property<float?> DesiredWidth = new .() ~ delete _;
	public Property<float?> DesiredHeight = new .() ~ delete _;

	public this()
	{
		DesiredWidth.SetOwner(this);
		DesiredHeight.SetOwner(this);
	}

	public this(Drawable drawable) : this()
	{
		mDrawable = drawable;
	}

	public this(Drawable drawable, float width, float height) : this()
	{
		mDrawable = drawable;
		DesiredWidth.SetSilent(width);
		DesiredHeight.SetSilent(height);
	}

	/// Borrowed.
	public Drawable Drawable => mDrawable;

	/// CONSUMES the caller's reference, and releases the one held before.
	///
	/// Handing back the drawable already held still consumes: the reference is dropped rather
	/// than the field being rewritten, so the same call is safe either way round. Raptor gets
	/// this from RefPtr's self assignment; here it is spelled out.
	public void SetDrawable(Drawable drawable)
	{
		if (mDrawable == drawable)
		{
			drawable?.ReleaseRef();
			return;
		}

		mDrawable?.ReleaseRef();
		mDrawable = drawable;
		Invalidate();
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		if (mDrawable != null)
			mDrawable.Draw(ctx, .(0, 0, Width, Height), GetControlState());
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let intrinsic = (mDrawable != null) ? mDrawable.IntrinsicSize : null;
		let w = DesiredWidth.Value.HasValue
			? DesiredWidth.Value.Value
			: ((intrinsic != null) ? intrinsic.Value.X : 0.0f);
		let h = DesiredHeight.Value.HasValue
			? DesiredHeight.Value.Value
			: ((intrinsic != null) ? intrinsic.Value.Y : 0.0f);
		MeasuredSize = .(constraints.ConstrainWidth(w), constraints.ConstrainHeight(h));
	}
}
