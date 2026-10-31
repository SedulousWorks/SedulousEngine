using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// Saturation across, value up, at the current hue.
///
/// Drawn as a grid of flat cells rather than a real gradient, because the vector context has no
/// two dimensional gradient and thirty steps is below the eye's threshold at this size.
class SVSquareView : HSVDragSurface
{
	private const int32 Steps = 30;

	public this(IHSVSource source) : base(source) {}

	public override void OnDraw(UIDrawContext ctx)
	{
		let cellWidth = Width / Steps;
		let cellHeight = Height / Steps;
		let hue = mSource.Hue;

		for (int32 iy = 0; iy < Steps; iy++)
		{
			let value = 1.0f - ((float)iy / (Steps - 1));
			for (int32 ix = 0; ix < Steps; ix++)
			{
				let saturation = (float)ix / (Steps - 1);
				// One pixel of overlap on each cell, so rounding cannot leave seams.
				ctx.VG.FillRect(.(ix * cellWidth, iy * cellHeight, cellWidth + 1, cellHeight + 1),
					ColorPicker.HSVToRGB(hue, saturation, value));
			}
		}

		// The ring FLIPS against the value beneath it, so it disappears into neither the white
		// corner nor the black one.
		let center = Float2(mSource.Saturation * Width, (1.0f - mSource.Value) * Height);
		ctx.VG.StrokeCircle(center, 5, (mSource.Value > 0.5f) ? Color.Black : Color.White, 2);

		DrawBorder(ctx);
	}

	protected override void UpdateFromMouse(float x, float y)
	{
		mSource.Saturation = Clamp(x / Width, 0.0f, 1.0f);
		mSource.Value = Clamp(1.0f - (y / Height), 0.0f, 1.0f);
		mSource.OnHSVChangedBySurface();
	}
}
