using System;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.UI;

/// A sliding on/off switch, with an optional label beside it.
///
/// The same state a checkbox carries, drawn as a track and a knob. Kept separate rather than
/// styled from CheckBox because the geometry is its own: a track, a knob, and the knob's travel
/// between them.
class ToggleSwitch : View
{
	private const float TextSpacing = 8.0f;

	public Property<bool> IsChecked = new .(false) ~ delete _;
	public Property<String> Text = new .(new String()) ~ delete _;
	public Property<float> TrackWidth = new .(44.0f) ~ delete _;
	public Property<float> TrackHeight = new .(24.0f) ~ delete _;
	public Property<float> KnobSize = new .(20.0f) ~ delete _;
	public Event<delegate void(ToggleSwitch, bool)> OnCheckedChanged ~ _.Dispose();

	public this()
	{
		Init();
	}

	public this(StringView text)
	{
		Init();
		Text.Value.Set(text); // reuses the empty String the property was built with
	}

	public ~this()
	{
		delete Text.Value;
	}

	public void SetText(StringView text)
	{
		let replacement = new String(text);
		let previous = Text.Value;
		Text.Value = replacement;
		if (previous != replacement)
			delete previous;
		Invalidate();
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled())
			return;

		if (e.Button == .Left)
		{
			IsChecked.Value = !IsChecked.Value;
			e.Handled = true;
		}
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEffectivelyEnabled())
			return;

		if ((e.Key == .Space) || (e.Key == .Return))
		{
			IsChecked.Value = !IsChecked.Value;
			e.Handled = true;
		}
	}

	public override void OnActivate()
	{
		if (IsEffectivelyEnabled())
			IsChecked.Value = !IsChecked.Value;
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let fontSize = ResolveStyleFloat(.FontSize, 16.0f);
		var textWidth = 0.0f;
		var textHeight = 0.0f;
		let text = Text.Value;

		if (!text.IsEmpty && (Context != null) && (Context.FontService != null))
		{
			let family = scope String();
			ResolveStyleFontFamily(family);
			if (let font = Context.FontService.GetFont(family, fontSize))
			{
				textWidth = font.Font.MeasureString(text);
				textHeight = font.Font.Metrics.LineHeight;
			}
		}

		let totalWidth = TrackWidth.Value + ((textWidth > 0) ? TextSpacing + textWidth : 0);
		let totalHeight = Max(TrackHeight.Value, textHeight);

		MeasuredSize = .(constraints.ConstrainWidth(totalWidth),
			constraints.ConstrainHeight(totalHeight));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let trackY = (Height - TrackHeight.Value) * 0.5f;
		let trackRect = Rectangle(0, trackY, TrackWidth.Value, TrackHeight.Value);

		var state = GetControlState();
		if (IsChecked.Value)
			state |= .Checked;

		DrawTrack(ctx, trackRect, state);
		DrawKnob(ctx, trackY, state);
		DrawText(ctx);
	}

	private void DrawTrack(UIDrawContext ctx, Rectangle trackRect, ControlState state)
	{
		if (let track = ResolvePartDrawable("track", .Background, state))
		{
			track.Draw(ctx, trackRect);
			return;
		}

		ctx.VG.FillRect(trackRect, IsChecked.Value
			? Color(80 / 255.0f, 150 / 255.0f, 240 / 255.0f, 1.0f)
			: Color(42 / 255.0f, 44 / 255.0f, 54 / 255.0f, 1.0f));
		ctx.VG.StrokeRect(trackRect,
			ResolveStyleColor(.BorderColor, Color(65 / 255.0f, 70 / 255.0f, 85 / 255.0f, 1.0f)),
			1.0f);
	}

	private void DrawKnob(UIDrawContext ctx, float trackY, ControlState state)
	{
		// The knob sits the same distance from whichever end it is at, so the travel looks even.
		let knobPad = (TrackHeight.Value - KnobSize.Value) * 0.5f;
		let knobX = IsChecked.Value ? (TrackWidth.Value - KnobSize.Value - knobPad) : knobPad;
		let knobRect = Rectangle(knobX, trackY + knobPad, KnobSize.Value, KnobSize.Value);

		if (let knob = ResolvePartDrawable("knob", .Background, state))
			knob.Draw(ctx, knobRect);
		else
			ctx.VG.FillRect(knobRect, Color(230 / 255.0f, 230 / 255.0f, 235 / 255.0f, 1.0f));
	}

	private void DrawText(UIDrawContext ctx)
	{
		let text = Text.Value;
		if (text.IsEmpty || (ctx.FontService == null))
			return;

		let family = scope String();
		ResolveStyleFontFamily(family);
		let font = ctx.FontService.GetFont(family, ResolveStyleFloat(.FontSize, 16.0f));
		if (font == null)
			return;

		let textColor = ResolveStyleColor(.TextColor,
			Color(220 / 255.0f, 225 / 255.0f, 235 / 255.0f, 1.0f));
		let textX = TrackWidth.Value + TextSpacing;
		ctx.VG.DrawText(text, font, .(textX, 0, Width - textX, Height), .Left, .Middle, textColor);
	}

	private void Init()
	{
		IsChecked.SetOwner(this, .Visual);
		Text.SetOwner(this);
		TrackWidth.SetOwner(this);
		TrackHeight.SetOwner(this);
		KnobSize.SetOwner(this, .Visual);
		IsChecked.Changed.Add(new (val) => { OnCheckedChanged(this, val); });
		IsFocusable = true;
		IsTabStop = true;
		Cursor = .Hand;
	}
}
