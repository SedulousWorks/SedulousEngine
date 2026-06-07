namespace Sedulous.GUI;

using System;
using Sedulous.Core.Mathematics;

/// iOS-style toggle switch with track and knob.
public class ToggleSwitch : View
{
	private bool mIsChecked;
	private String mText ~ delete _;

	public float TrackWidth = 44;
	public float TrackHeight = 24;
	public float KnobSize = 20;
	private static float TextSpacing = 8;

	public bool IsChecked
	{
		get => mIsChecked;
		set
		{
			if (mIsChecked == value) return;
			mIsChecked = value;
			Invalidate();
			OnCheckedChanged(this, mIsChecked);
		}
	}

	public StringView Text
	{
		get => (mText != null) ? StringView(mText) : StringView();
		set
		{
			if (mText == null) mText = new String(value);
			else mText.Set(value);
			Invalidate();
		}
	}

	public Event<delegate void(ToggleSwitch, bool)> OnCheckedChanged ~ _.Dispose();

	public this() { IsFocusable = true; IsTabStop = true; Cursor = .Hand; }
	public this(StringView text) : this() { mText = new String(text); }

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let fontSize = ResolveStyleFloat(.FontSize, 16);
		float textW = 0, textH = 0;

		if (mText != null && !mText.IsEmpty)
		{
			let font = Context?.FontService?.GetFont(fontSize);
			if (font != null)
			{
				textW = font.Font.MeasureString(mText);
				textH = font.Font.Metrics.LineHeight;
			}
		}

		let totalW = TrackWidth + ((textW > 0) ? TextSpacing + textW : 0);
		let totalH = Math.Max(TrackHeight, textH);

		MeasuredSize = .(constraints.ConstrainWidth(totalW), constraints.ConstrainHeight(totalH));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let fontSize = ResolveStyleFloat(.FontSize, 16);
		let trackY = (Height - TrackHeight) * 0.5f;
		let trackRect = RectangleF(0, trackY, TrackWidth, TrackHeight);

		// Track - use drawable if available, fallback to squared rect
		let trackDrawable = mIsChecked ? ResolveStyleDrawable(.TrackOnDrawable) : ResolveStyleDrawable(.TrackDrawable);
		if (trackDrawable != null)
			trackDrawable.Draw(ctx, trackRect);
		else
		{
			// Fallback: fill + border
			ctx.VG.FillRect(trackRect, mIsChecked ? Color(80, 150, 240, 255) : Color(42, 44, 54, 255));
			let borderColor = ResolveStyleColor(.BorderColor, .(65, 70, 85, 255));
			ctx.VG.StrokeRect(trackRect, borderColor, 1);
		}

		// Knob
		let knobPad = (TrackHeight - KnobSize) * 0.5f;
		let knobX = mIsChecked ? (TrackWidth - KnobSize - knobPad) : knobPad;
		let knobY = trackY + knobPad;
		let knobRect = RectangleF(knobX, knobY, KnobSize, KnobSize);
		let knobDrawable = ResolveStyleDrawable(.KnobDrawable);
		if (knobDrawable != null)
			knobDrawable.Draw(ctx, knobRect);
		else
			ctx.VG.FillRect(knobRect, .(230, 230, 235, 255));

		// Text
		if (mText != null && !mText.IsEmpty)
		{
			let font = ctx.FontService?.GetFont(fontSize);
			if (font != null)
			{
				var textColor = ResolveStyleColor(.TextColor, .(220, 225, 235, 255));
				if (!IsEffectivelyEnabled) textColor = Palette.ComputeDisabled(textColor);
				let textX = TrackWidth + TextSpacing;
				ctx.VG.DrawText(mText, font, .(textX, 0, Width - textX, Height), .Left, .Middle, textColor);
			}
		}
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled) return;
		if (e.Button == .Left) { IsChecked = !mIsChecked; e.Handled = true; }
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEffectivelyEnabled) return;
		if (e.Key == .Space || e.Key == .Return) { IsChecked = !mIsChecked; e.Handled = true; }
	}
}
