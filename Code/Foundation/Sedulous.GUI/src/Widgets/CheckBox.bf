using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.GUI;

// CheckBox: the button core as a toggle with a box for its indicator, its text beside it. It is
// tri-state: checked, unchecked, or indeterminate (a parent of mixed children, CSS's
// :indeterminate), drawn as a dash until it is set or clicked; a click on an indeterminate box
// checks it. Its parts: checkbox::box (the outline) and ::mark (the dash, or the tick's colour).

[GuiReflect(true)]
class CheckBox : ButtonBase
{
	private Color mBoxColor = .(0.60f, 0.65f, 0.72f, 1.0f);
	private Color mCheckColor = .(0.31f, 0.63f, 0.85f, 1.0f);

	public this()
	{
		Tag = "checkbox";
		AccessRoleName = "checkbox"; // what a screen reader takes it for
		using (StyleWriteScope(this))
		{
			SetTextAlignment(.Start, .Middle); // its text beside its indicator
		}
		IsToggle = true;
		MakeIndicator();
	}

	public void Toggle()
	{
		Checked = !Checked;
	}

	/// Neither checked nor unchecked, until it is set or clicked.
	[GuiProperty("indeterminate")]
	public bool Indeterminate
	{
		get => IndeterminateState;
		set => IndeterminateState = value;
	}

	public void SetBoxColor(Color color)
	{
		mBoxColor = color;
		Invalidate();
	}

	public void SetCheckColor(Color color)
	{
		mCheckColor = color;
		Invalidate();
	}

	// Theming parts: checkbox::box (outline) / ::mark (inner fill).
	public override void CollectStyleParts(List<StringView> outParts)
	{
		outParts.Add("box");
		outParts.Add("mark");
	}

	protected override void DrawIndicator(DrawContext ctx, Rect area)
	{
		GetPartStyle("box").Draw(ctx, area, OutlinedBox(mBoxColor, 2.0f, CornerRadii(3.0f), scope NodeBox()));
		if (IndeterminateState)
		{
			let h = Math.Max(2.0f, area.Height * 0.18f);
			let dash = Rect(area.X + 4.0f, area.Y + (area.Height - h) * 0.5f, Math.Max(0.0f, area.Width - 8.0f), h);
			GetPartStyle("mark").Draw(ctx, dash, FilledBox(mCheckColor, CornerRadii(1.0f), scope NodeBox()));
		}
		else if (Checked)
		{
			// A tick, not a filled square, so checked never reads as the mixed state's bar. Its
			// colour is checkbox::mark's background, a sheet's or its own.
			let mark = GetPartStyle("mark");
			var color = mark.HasBackground ? mark.Box.BackgroundColor : mCheckColor;
			color.A *= mark.Opacity;
			let side = Math.Min(area.Width, area.Height);
			let x = area.X + (area.Width - side) * 0.5f;
			let y = area.Y + (area.Height - side) * 0.5f;
			let tick = scope PathBuilder();
			tick.MoveTo(x + side * 0.24f, y + side * 0.52f);
			tick.LineTo(x + side * 0.43f, y + side * 0.70f);
			tick.LineTo(x + side * 0.77f, y + side * 0.31f);
			let path = tick.ToPath();
			ctx.VG.StrokePath(path, color, StrokeStyle(Math.Max(2.0f, side * 0.12f), .Round, .Round));
			delete path;
		}
	}
}
