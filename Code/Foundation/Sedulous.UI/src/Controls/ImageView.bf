namespace Sedulous.UI;

using Sedulous.Core.Mathematics;
using Sedulous.ImageData;

/// Displays an IImageData stretched to fill its bounds.
public class ImageView : View
{
	public IImageData Image;
	public Color Tint = .White;

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		float w = (Image != null) ? Image.Width : 0;
		float h = (Image != null) ? Image.Height : 0;
		MeasuredSize = .(wSpec.Resolve(w), hSpec.Resolve(h));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		if (Image != null)
			ctx.VG.DrawImage(Image, .(0, 0, Width, Height), .(0, 0, Image.Width, Image.Height), Tint);
	}
}
