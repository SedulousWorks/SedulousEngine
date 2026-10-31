using System;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.UI;

namespace Samples.UISandbox;

/// A drop target that takes the dropped chip's colour and says so.
///
/// Its caption tracks the drag STATE rather than only the drop, which is how a target shows it
/// will accept before the button comes up.
class ColorDropBox : View, IDropTarget
{
	private String mText = new .("Drop here") ~ delete _;
	private Color mBackground = Color.Rgb(50, 55, 65);

	public override IDropTarget AsDropTarget() => this;

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = Rectangle(0, 0, Width, Height);
		ctx.VG.FillRoundedRect(bounds, 4.0f, mBackground);
		ctx.VG.StrokeRoundedRect(bounds, 4.0f, Color.Rgb(70, 75, 85), 1.0f);

		if (ctx.FontService == null)
			return;

		let family = scope String();
		ResolveStyleFontFamily(family);

		let font = ctx.FontService.GetFont(family, 12.0f);
		if (font == null)
			return;

		ctx.VG.DrawText(mText, font, bounds, TextAlignment.Center, VerticalAlignment.Middle,
			Color.Rgb(220, 225, 235));
	}

	public DragDropEffects CanAcceptDrop(DragData data, float localX, float localY) =>
		(data.Format == "demo/chip") ? .Copy : .None;

	public void OnDragEnter(DragData data, float localX, float localY)
	{
		mText.Set("Release!");
		Invalidate();
	}

	public void OnDragOver(DragData data, float localX, float localY) {}

	public void OnDragLeave(DragData data)
	{
		mText.Set("Drop here");
		Invalidate();
	}

	public DragDropEffects OnDrop(DragData data, float localX, float localY)
	{
		if (data.Format != "demo/chip")
			return .None;

		mBackground = ((ChipDragData)data).SourceChip.Color.Value;
		mText.Set("Dropped!");
		Invalidate();
		return .Copy;
	}

	protected override void OnMeasure(BoxConstraints constraints) =>
		MeasuredSize = .(constraints.ConstrainWidth(constraints.MaxWidth),
			constraints.ConstrainHeight(30));
}
