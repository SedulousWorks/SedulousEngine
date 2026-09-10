using Sedulous.Core;
using Sedulous.Image;

namespace Sedulous.UI;

/// Displays an image, scaled by ScaleType.
///
/// The image is BORROWED: an image outlives the views showing it, and several views commonly
/// show the same one.
///
/// The `ScaleType` property shadows the enum type inside this class, so the values are reached
/// through inference rather than by name.
class ImageView : View
{
	public Property<ScaleType> ScaleType = new .(.FitCenter) ~ delete _;
	public Property<Color> Tint = new .(Color.White) ~ delete _;

	private ImageData mImage;

	public this()
	{
		ScaleType.SetOwner(this, .Visual);
		Tint.SetOwner(this, .Visual);
	}

	public this(ImageData img) : this()
	{
		SetImage(img);
	}

	/// Borrowed; may be null.
	public ImageData Image => mImage;

	public void SetImage(ImageData img)
	{
		if (mImage == img)
			return;

		mImage = img;
		Invalidate();
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		if (mImage != null)
			MeasuredSize = .(constraints.ConstrainWidth((float)mImage.Width),
				constraints.ConstrainHeight((float)mImage.Height));
		else
			MeasuredSize = .(constraints.ConstrainWidth(0.0f), constraints.ConstrainHeight(0.0f));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		if (mImage == null)
			return;

		let iw = (float)mImage.Width;
		let ih = (float)mImage.Height;
		let srcRect = Rectangle(0, 0, iw, ih);
		let dstRect = Rectangle(0, 0, Width, Height);

		switch (ScaleType.Value)
		{
		case .None:
			ctx.VG.DrawImage(mImage, .(0, 0, iw, ih), srcRect, Tint.Value);
		case .FillBounds:
			ctx.VG.DrawImage(mImage, dstRect, srcRect, Tint.Value);
		case .FitCenter:
			// Scale by the TIGHTER axis, so the whole image lands inside the bounds.
			let scale = Min(Width / iw, Height / ih);
			let fitW = iw * scale;
			let fitH = ih * scale;
			ctx.VG.DrawImage(mImage, .((Width - fitW) * 0.5f, (Height - fitH) * 0.5f, fitW, fitH),
				srcRect, Tint.Value);
		case .CenterCrop:
			// Scale by the LOOSER axis and crop the source instead, so the bounds are covered.
			let scale = Max(Width / iw, Height / ih);
			let cropW = Width / scale;
			let cropH = Height / scale;
			ctx.VG.DrawImage(mImage, dstRect,
				.((iw - cropW) * 0.5f, (ih - cropH) * 0.5f, cropW, cropH), Tint.Value);
		}
	}
}
