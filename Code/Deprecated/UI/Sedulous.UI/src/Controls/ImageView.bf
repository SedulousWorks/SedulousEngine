using System;
using Sedulous.Core;
using Sedulous.VG;
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
	/// Rounds the picture's corners: the drawn picture's own rect, the fitted rect under
	/// FitCenter, the view under CenterCrop and FillBounds. Zero: square corners.
	public Property<CornerRadii> CornerRadius = new .(.()) ~ delete _;
	/// What to show, named by a string the context's resource provider resolves (the engine
	/// takes an asset id: a texture, or a render texture a camera draws into). Resolved when
	/// the view is measured or drawn in a context that has a provider; until the provider
	/// answers (an asset still loading), the view shows nothing and asks again. Empty: the
	/// image SetImage gave. Set it through SetSource.
	public Property<String> Source = new .(new String()) ~ delete _;

	private ImageData mImage;
	/// The Source mImage answers.
	private String mResolvedSource = new .() ~ delete _;

	public this()
	{
		ScaleType.SetOwner(this, .Visual);
		Tint.SetOwner(this, .Visual);
		CornerRadius.SetOwner(this, .Visual);
	}

	public ~this()
	{
		delete Source.Value;
	}

	/// Names what to show (see Source); the view lays out again.
	public void SetSource(StringView source)
	{
		if (Source.Value == source)
			return;
		Source.Value.Set(source);
		Invalidate();
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

	/// Asks the context's provider for the image Source names, once per name.
	private void ResolveSource()
	{
		let source = Source.Value;
		if (source.IsEmpty)
		{
			if (!mResolvedSource.IsEmpty) // the source was cleared: so is its image
			{
				mResolvedSource.Clear();
				mImage = null;
				Invalidate();
			}
			return;
		}
		if (mResolvedSource == source)
			return;
		let provider = (Context != null) ? Context.ResourceProvider : null;
		let image = (provider != null) ? provider.LoadImage(source) : null;
		if (image == null)
		{
			mImage = null;
			InvalidateVisual(); // not there yet (a loading asset): ask again next frame
			return;
		}
		mImage = image;
		mResolvedSource.Set(source);
		Invalidate(); // the image's size is the view's natural size: lay out again
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		ResolveSource();
		if (mImage != null)
			MeasuredSize = .(constraints.ConstrainWidth((float)mImage.Width),
				constraints.ConstrainHeight((float)mImage.Height));
		else
			MeasuredSize = .(constraints.ConstrainWidth(0.0f), constraints.ConstrainHeight(0.0f));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		ResolveSource();
		if (mImage == null)
			return;

		let iw = (float)mImage.Width;
		let ih = (float)mImage.Height;
		let srcRect = Rectangle(0, 0, iw, ih);
		let dstRect = Rectangle(0, 0, Width, Height);

		switch (ScaleType.Value)
		{
		case .None:
			Blit(ctx, .(0, 0, iw, ih), srcRect);
		case .FillBounds:
			Blit(ctx, dstRect, srcRect);
		case .FitCenter:
			// Scale by the TIGHTER axis, so the whole image lands inside the bounds.
			let scale = Min(Width / iw, Height / ih);
			let fitW = iw * scale;
			let fitH = ih * scale;
			Blit(ctx, .((Width - fitW) * 0.5f, (Height - fitH) * 0.5f, fitW, fitH), srcRect);
		case .CenterCrop:
			// Scale by the LOOSER axis and crop the source instead, so the bounds are covered.
			let scale = Max(Width / iw, Height / ih);
			let cropW = Width / scale;
			let cropH = Height / scale;
			Blit(ctx, dstRect, .((iw - cropW) * 0.5f, (ih - cropH) * 0.5f, cropW, cropH));
		}
	}

	private void Blit(UIDrawContext ctx, Rectangle dst, Rectangle src)
	{
		ctx.VG.DrawImageRounded(mImage, dst, src, CornerRadius.Value, Tint.Value);
	}
}
