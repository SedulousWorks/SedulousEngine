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

/// Displays an image with configurable scaling.
public class ImageView : View
{
	/// The image to display (not owned by this view).
	private IImageData mImage;
	public IImageData Image
	{
		get => mImage;
		set
		{
			if (mImage == value) return;
			mImage = value;
			Invalidate();
		}
	}

	/// How the image is scaled to fit bounds.
	public Property<ScaleType> ScaleType = new .(.FitCenter) ~ delete _;

	/// Tint color applied to the image.
	public Property<Color> Tint = new .(.White) ~ delete _;

	public this()
	{
		ScaleType.SetOwner(this, .Visual);
		Tint.SetOwner(this, .Visual);
	}

	public this(IImageData image) : this()
	{
		Image = image;
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		if (Image != null)
			MeasuredSize = .(constraints.ConstrainWidth(Image.Width), constraints.ConstrainHeight(Image.Height));
		else
			MeasuredSize = .(constraints.ConstrainWidth(0), constraints.ConstrainHeight(0));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		if (Image == null) return;

		let srcRect = RectangleF(0, 0, Image.Width, Image.Height);
		let dstRect = RectangleF(0, 0, Width, Height);

		switch (ScaleType.Value)
		{
		case .None:
			ctx.VG.DrawImage(Image, .(0, 0, Image.Width, Image.Height), srcRect, Tint.Value);

		case .FillBounds:
			ctx.VG.DrawImage(Image, dstRect, srcRect, Tint.Value);

		case .FitCenter:
			let scale = Math.Min(Width / Image.Width, Height / Image.Height);
			let fitW = Image.Width * scale;
			let fitH = Image.Height * scale;
			let fitRect = RectangleF((Width - fitW) * 0.5f, (Height - fitH) * 0.5f, fitW, fitH);
			ctx.VG.DrawImage(Image, fitRect, srcRect, Tint.Value);

		case .CenterCrop:
			let scale = Math.Max(Width / Image.Width, Height / Image.Height);
			let cropW = Width / scale;
			let cropH = Height / scale;
			let cropX = (Image.Width - cropW) * 0.5f;
			let cropY = (Image.Height - cropH) * 0.5f;
			ctx.VG.DrawImage(Image, dstRect, .(cropX, cropY, cropW, cropH), Tint.Value);
		}
	}
}
