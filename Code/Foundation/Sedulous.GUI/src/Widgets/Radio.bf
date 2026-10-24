using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.GUI;

// RadioButton: the button core as a toggle with a ring for its indicator, its text beside it. A
// click checks it and never unchecks it; the radios of one group (a `name` in markup, or a
// ButtonGroup from code) are exclusive, and the arrows move round them. Its parts: radio::ring
// (the outline) and ::dot (the choice).

[GuiReflect(true)]
class RadioButton : ButtonBase
{
	private Color mRingColor = .(0.60f, 0.65f, 0.72f, 1.0f);
	private Color mDotColor = .(0.31f, 0.63f, 0.85f, 1.0f);

	public this()
	{
		Tag = "radio";
		AccessRoleName = "radio"; // what a screen reader takes it for
		using (StyleWriteScope(this))
		{
			SetTextAlignment(.Start, .Middle); // its text beside its indicator
		}
		IsToggle = true;
		SetKeepsChecked(true);
		MakeIndicator();
	}

	public void SetRingColor(Color color)
	{
		mRingColor = color;
		Invalidate();
	}

	public void SetDotColor(Color color)
	{
		mDotColor = color;
		Invalidate();
	}

	// Theming parts: radio::ring (outline) / ::dot (inner fill).
	public override void CollectStyleParts(List<StringView> outParts)
	{
		outParts.Add("ring");
		outParts.Add("dot");
	}

	protected override void DrawIndicator(DrawContext ctx, Rect area)
	{
		let r = Math.Min(area.Width, area.Height) * 0.5f;
		let c = Float2(area.X + area.Width * 0.5f, area.Y + area.Height * 0.5f);
		GetPartStyle("ring").Draw(ctx, .(c.X - r, c.Y - r, r * 2.0f, r * 2.0f), OutlinedBox(mRingColor, 2.0f, CornerRadii(r), scope NodeBox()));
		if (Checked)
		{
			let d = r * 0.5f;
			GetPartStyle("dot").Draw(ctx, .(c.X - d, c.Y - d, d * 2.0f, d * 2.0f), FilledBox(mDotColor, CornerRadii(d), scope NodeBox()));
		}
	}
}
