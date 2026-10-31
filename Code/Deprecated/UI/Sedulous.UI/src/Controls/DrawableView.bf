using System;
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
	/// Draws at the desired (else intrinsic) aspect, as large as fits and centred, rather than
	/// stretched to the view's box: an icon in a squeezed row shrinks, it does not squash.
	public bool KeepAspect = false;

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
	/// than the field being rewritten, so the same call is safe either way round, the way a
	/// smart pointer's self assignment would be.
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
		if (mDrawable == null)
			return;
		var rect = Rectangle(0, 0, Width, Height);
		if (KeepAspect)
		{
			let intrinsic = mDrawable.IntrinsicSize;
			let aw = DesiredWidth.Value.HasValue ? DesiredWidth.Value.Value : ((intrinsic != null) ? intrinsic.Value.X : 0.0f);
			let ah = DesiredHeight.Value.HasValue ? DesiredHeight.Value.Value : ((intrinsic != null) ? intrinsic.Value.Y : 0.0f);
			if ((aw > 0.0f) && (ah > 0.0f) && (Width > 0.0f) && (Height > 0.0f))
			{
				let scale = Math.Min(Width / aw, Height / ah);
				let w = aw * scale;
				let h = ah * scale;
				rect = .((Width - w) * 0.5f, (Height - h) * 0.5f, w, h);
			}
		}
		mDrawable.Draw(ctx, rect, GetControlState());
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
