using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// Opaque at the top down to clear at the bottom, over a CHECKERBOARD so clear reads as
/// transparent rather than as whatever happens to sit behind the dialog.
class AlphaStripView : HSVDragSurface
{
	private const float CheckSize = 5.0f;
	private const int32 Steps = 20;

	public this(IHSVSource source) : base(source) {}

	public override void OnDraw(UIDrawContext ctx)
	{
		DrawCheckerboard(ctx);

		let baseColor = ColorPicker.HSVToRGB(mSource.Hue, mSource.Saturation, mSource.Value);
		let cellHeight = Height / Steps;
		for (int32 i = 0; i < Steps; i++)
		{
			let alpha = 1.0f - ((float)i / (Steps - 1));
			ctx.VG.FillRect(.(0, i * cellHeight, Width, cellHeight + 1),
				.(baseColor.R, baseColor.G, baseColor.B, alpha));
		}

		DrawStripMarker(ctx, (1.0f - mSource.Alpha) * Height);
		DrawBorder(ctx);
	}

	private void DrawCheckerboard(UIDrawContext ctx)
	{
		let light = Color.Rgb(200, 200, 200);
		let dark = Color.Rgb(128, 128, 128);
		let columns = (int32)Ceil(Width / CheckSize);
		let rows = (int32)Ceil(Height / CheckSize);

		for (int32 row = 0; row < rows; row++)
		{
			for (int32 column = 0; column < columns; column++)
			{
				// The last row and column are CLIPPED to the strip, so the pattern does not
				// spill out from under the border drawn over it.
				ctx.VG.FillRect(.(column * CheckSize, row * CheckSize,
					Min(CheckSize, Width - (column * CheckSize)),
					Min(CheckSize, Height - (row * CheckSize))),
					(((row + column) % 2) == 0) ? light : dark);
			}
		}
	}

	protected override void UpdateFromMouse(float x, float y)
	{
		mSource.Alpha = Clamp(1.0f - (y / Height), 0.0f, 1.0f);
		mSource.OnHSVChangedBySurface();
	}
}
