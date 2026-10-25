using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.GUI;

// ToggleSwitch: the button core as a toggle with a track and a knob for its indicator, its text
// beside it: a check box for a setting that takes effect at once. Its parts: switch::track (filled
// when it is on) and ::knob.

[GuiReflect(true), Scriptable]
class ToggleSwitch : ButtonBase
{
	private Color mTrackOff = .(0.32f, 0.35f, 0.40f, 1.0f);
	private Color mTrackOn = .(0.31f, 0.63f, 0.85f, 1.0f);
	private Color mKnobColor = .(0.94f, 0.96f, 0.98f, 1.0f);

	public this()
	{
		Tag = "switch";
		AccessRoleName = "switch"; // what a screen reader takes it for
		using (StyleWriteScope(this))
		{
			SetTextAlignment(.Start, .Middle); // its text beside its indicator
		}
		IsToggle = true;
		MakeIndicator();
	}

	public void SetTrackColor(Color off, Color on)
	{
		mTrackOff = off;
		mTrackOn = on;
		Invalidate();
	}

	public void SetKnobColor(Color color)
	{
		mKnobColor = color;
		Invalidate();
	}

	// Theming parts: switch::track / ::knob.
	public override void CollectStyleParts(List<StringView> outParts)
	{
		outParts.Add("track");
		outParts.Add("knob");
	}

	protected override Float2 IndicatorSize => .(36.0f, 20.0f);

	protected override void DrawIndicator(DrawContext ctx, Rect area)
	{
		let on = Checked;
		let r = area.Height * 0.5f;
		GetPartStyle("track").Draw(ctx, area, FilledBox(on ? mTrackOn : mTrackOff, CornerRadii(r), scope NodeBox()));
		let knobR = Math.Max(0.0f, r - 3.0f);
		// On at the inline end.
		let cx = Rect.MirroredX(on ? area.X + area.Width - r : area.X + r, area, IsRightToLeft);
		let cy = area.Y + r;
		GetPartStyle("knob").Draw(ctx, .(cx - knobR, cy - knobR, knobR * 2.0f, knobR * 2.0f),
			FilledBox(mKnobColor, CornerRadii(knobR), scope NodeBox()));
	}
}
