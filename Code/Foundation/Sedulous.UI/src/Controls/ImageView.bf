namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Images;

/// How an ImageView scales its source to fit its bounds.
public enum ScaleType
{
	/// Draw at natural size, top-left aligned. No scaling.
	None,
	/// Scale to fit within bounds, centered, maintain aspect ratio.
	FitCenter,
	/// Stretch to fill bounds exactly. Does not maintain aspect ratio.
	FillBounds,
	/// Scale to fill bounds, crop overflow, centered. Maintains aspect ratio.
	CenterCrop
}

/// Displays an IImageData with configurable scaling.
/// Does not own the IImageData — caller manages image lifetime.
public class ImageView : View
{
	private IImageData mImage;
	private ScaleType mScaleType = .FillBounds;
	private Color? mTint;

	public IImageData Image
	{
		get => mImage;
		set { mImage = value; InvalidateLayout(); }
	}

	public ScaleType ScaleType
	{
		get => mScaleType;
		set { mScaleType = value; InvalidateVisual(); }
	}

	public Color Tint
	{
		get => mTint ?? .White;
		set => mTint = value;
	}

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		float w = (mImage != null) ? mImage.Width : 0;
		float h = (mImage != null) ? mImage.Height : 0;
		MeasuredSize = .(wSpec.Resolve(w), hSpec.Resolve(h));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		if (mImage == null) return;

		let bounds = RectangleF(0, 0, Width, Height);
		let tint = Tint;
		let srcRect = RectangleF(0, 0, mImage.Width, mImage.Height);

		RectangleF destRect;
		var drawSrc = srcRect;
		switch (mScaleType)
		{
		case .None:
			destRect = .(0, 0, mImage.Width, mImage.Height);
		case .FitCenter:
			destRect = FitCenter(bounds, mImage.Width, mImage.Height);
		case .FillBounds:
			destRect = bounds;
		case .CenterCrop:
			destRect = bounds;
			drawSrc = CenterCropSource(bounds, mImage.Width, mImage.Height);
		}

		ctx.VG.DrawImage(mImage, destRect, drawSrc, tint);
	}

	private static RectangleF FitCenter(RectangleF bounds, uint32 imgW, uint32 imgH)
	{
		if (imgW == 0 || imgH == 0) return bounds;

		float aspect = (float)imgW / (float)imgH;
		float boundsAspect = bounds.Width / bounds.Height;

		float w, h;
		if (aspect > boundsAspect)
		{
			w = bounds.Width;
			h = w / aspect;
		}
		else
		{
			h = bounds.Height;
			w = h * aspect;
		}

		return .(bounds.X + (bounds.Width - w) * 0.5f,
				 bounds.Y + (bounds.Height - h) * 0.5f, w, h);
	}

	/// Compute the source rect that, when drawn into bounds, fills the
	/// bounds completely while preserving aspect ratio. The excess is
	/// cropped symmetrically from the source.
	private static RectangleF CenterCropSource(RectangleF bounds, uint32 imgW, uint32 imgH)
	{
		if (imgW == 0 || imgH == 0) return .(0, 0, imgW, imgH);

		float imgAspect = (float)imgW / (float)imgH;
		float boundsAspect = bounds.Width / bounds.Height;

		float srcW, srcH;
		if (imgAspect > boundsAspect)
		{
			// Image is wider than bounds — crop sides.
			srcH = imgH;
			srcW = srcH * boundsAspect;
		}
		else
		{
			// Image is taller than bounds — crop top/bottom.
			srcW = imgW;
			srcH = srcW / boundsAspect;
		}

		let srcX = ((float)imgW - srcW) * 0.5f;
		let srcY = ((float)imgH - srcH) * 0.5f;
		return .(srcX, srcY, srcW, srcH);
	}
}
