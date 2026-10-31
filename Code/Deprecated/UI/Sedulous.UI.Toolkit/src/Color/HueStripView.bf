using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// The rainbow down the side: hue at full saturation and value.
class HueStripView : HSVDragSurface
{
	private const int32 Steps = 36;

	public this(IHSVSource source) : base(source) {}

	public override void OnDraw(UIDrawContext ctx)
	{
		let cellHeight = Height / Steps;
		for (int32 i = 0; i < Steps; i++)
		{
			let hue = ((float)i / (Steps - 1)) * 360.0f;
			ctx.VG.FillRect(.(0, i * cellHeight, Width, cellHeight + 1),
				ColorPicker.HSVToRGB(hue, 1, 1));
		}

		DrawStripMarker(ctx, (mSource.Hue / 360.0f) * Height);
		DrawBorder(ctx);
	}

	protected override void UpdateFromMouse(float x, float y)
	{
		mSource.Hue = Clamp(y / Height, 0.0f, 1.0f) * 360.0f;
		mSource.OnHSVChangedBySurface();
	}
}
