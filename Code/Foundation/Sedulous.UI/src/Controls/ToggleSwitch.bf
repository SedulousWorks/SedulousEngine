namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// iOS-style toggle switch with track and knob.
public class ToggleSwitch : View
{
	/// Whether the switch is on.
	public Property<bool> IsChecked = new .(false) ~ delete _;

	/// Text label next to the switch.
	public Property<String> Text = new .(null) ~ { if (_.Value != null) delete _.Value; delete _; };

	public Property<float> TrackWidth = new .(44) ~ delete _;
	public Property<float> TrackHeight = new .(24) ~ delete _;
	public Property<float> KnobSize = new .(20) ~ delete _;
	private static float TextSpacing = 8;

	public Event<delegate void(ToggleSwitch, bool)> OnCheckedChanged ~ _.Dispose();

	public this()
	{
		IsChecked.SetOwner(this, .Visual);
		Text.SetOwner(this);
		TrackWidth.SetOwner(this);
		TrackHeight.SetOwner(this);
		KnobSize.SetOwner(this, .Visual);

		IsChecked.Changed.Add(new (val) => { OnCheckedChanged(this, val); });

		IsFocusable = true; IsTabStop = true; Cursor = .Hand;
	}
	public this(StringView text) : this() { Text.SetSilent(new String(text)); }

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let fontSize = ResolveStyleFloat(.FontSize, 16);
		float textW = 0, textH = 0;

		if (Text.Value != null && !Text.Value.IsEmpty)
		{
			let font = Context?.FontService?.GetFont(ResolveStyleFontFamily(), fontSize);
			if (font != null)
			{
				textW = font.Font.MeasureString(Text.Value);
				textH = font.Font.Metrics.LineHeight;
			}
		}

		let totalW = TrackWidth.Value + ((textW > 0) ? TextSpacing + textW : 0);
		let totalH = Math.Max(TrackHeight.Value, textH);

		MeasuredSize = .(constraints.ConstrainWidth(totalW), constraints.ConstrainHeight(totalH));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let fontSize = ResolveStyleFloat(.FontSize, 16);
		let trackY = (Height - TrackHeight.Value) * 0.5f;
		let trackRect = RectangleF(0, trackY, TrackWidth.Value, TrackHeight.Value);

		// Track - query with Checked state flag when on so checked-specific rules win
		var trackState = GetControlState();
		if (IsChecked.Value) trackState |= .Checked;
		let trackDrawable = ResolvePartDrawable("track", .Background, trackState);
		if (trackDrawable != null)
			trackDrawable.Draw(ctx, trackRect);
		else
		{
			// Fallback: fill + border
			ctx.VG.FillRect(trackRect, IsChecked.Value ? Color32(80, 150, 240, 255) : Color32(42, 44, 54, 255));
			let borderColor = ResolveStyleColor(.BorderColor, .(65, 70, 85, 255));
			ctx.VG.StrokeRect(trackRect, borderColor, 1);
		}

		// Knob
		let knobPad = (TrackHeight.Value - KnobSize.Value) * 0.5f;
		let knobX = IsChecked.Value ? (TrackWidth.Value - KnobSize.Value - knobPad) : knobPad;
		let knobY = trackY + knobPad;
		let knobRect = RectangleF(knobX, knobY, KnobSize.Value, KnobSize.Value);
		let knobDrawable = ResolvePartDrawable("knob", .Background, trackState);
		if (knobDrawable != null)
			knobDrawable.Draw(ctx, knobRect);
		else
			ctx.VG.FillRect(knobRect, .(230, 230, 235, 255));

		// Text
		if (Text.Value != null && !Text.Value.IsEmpty)
		{
			let font = ctx.FontService?.GetFont(ResolveStyleFontFamily(), fontSize);
			if (font != null)
			{
				var textColor = ResolveStyleColor(.TextColor, .(220, 225, 235, 255));
				if (!IsEffectivelyEnabled) textColor = Palette.ComputeDisabled(textColor);
				let textX = TrackWidth.Value + TextSpacing;
				ctx.VG.DrawText(Text.Value, font, .(textX, 0, Width - textX, Height), .Left, .Middle, textColor);
			}
		}
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled) return;
		if (e.Button == .Left) { IsChecked.Value = !IsChecked.Value; e.Handled = true; }
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEffectivelyEnabled) return;
		if (e.Key == .Space || e.Key == .Return) { IsChecked.Value = !IsChecked.Value; e.Handled = true; }
	}

	public override void OnActivate()
	{
		if (!IsEffectivelyEnabled) return;
		IsChecked.Value = !IsChecked.Value;
	}
}
