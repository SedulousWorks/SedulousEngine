namespace Sedulous.GUI;

using System;
using Sedulous.Core.Mathematics;

/// Toggle checkbox with text label.
public class CheckBox : View
{
	/// Whether the checkbox is checked.
	public Property<bool> IsChecked = new .(false) ~ delete _;

	/// Text label next to the checkbox.
	public Property<String> Text = new .(null) ~ { if (_.Value != null) delete _.Value; delete _; };

	/// Override font size for the label text.
	public Property<float?> FontSize = new .(null) ~ delete _;

	/// Override text color for the label text.
	public Property<Color?> TextColor = new .(null, .Visual) ~ delete _;

	/// Fired when checked state changes.
	public Event<delegate void(CheckBox, bool)> OnCheckedChanged ~ _.Dispose();

	public this()
	{
		IsChecked.SetOwner(this, .Visual);
		Text.SetOwner(this);
		FontSize.SetOwner(this);
		TextColor.SetOwner(this, .Visual);

		IsChecked.Changed.Add(new (val) => { OnCheckedChanged(this, val); });

		IsFocusable = true; IsTabStop = true; Cursor = .Hand;
	}
	public this(StringView text) : this() { Text.SetSilent(new String(text)); }
	public this(StringView text, bool isChecked) : this(text) { IsChecked.SetSilent(isChecked); }

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let boxSize = ResolvePartFloat("box", .Width, GetControlState(), 18);
		let spacing = ResolveStyleFloat(.Spacing, 6);
		let fontSize = FontSize.Value ?? ResolveStyleFloat(.FontSize, 16);

		float textW = 0, textH = 0;
		if (Text.Value != null && !Text.Value.IsEmpty)
		{
			let font = Context?.FontService?.GetFont(fontSize);
			if (font != null)
			{
				textW = font.Font.MeasureString(Text.Value);
				textH = font.Font.Metrics.LineHeight;
			}
		}

		let totalW = boxSize + ((textW > 0) ? spacing + textW : 0);
		let totalH = Math.Max(boxSize, textH);

		MeasuredSize = .(constraints.ConstrainWidth(totalW), constraints.ConstrainHeight(totalH));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		var state = GetControlState();
		if (IsChecked.Value) state |= .Checked;
		let boxSize = ResolvePartFloat("box", .Width, state, 18);
		let spacing = ResolveStyleFloat(.Spacing, 6);
		let fontSize = FontSize.Value ?? ResolveStyleFloat(.FontSize, 16);

		// Box position (vertically centered)
		let boxY = (Height - boxSize) * 0.5f;
		let boxRect = RectangleF(0, boxY, boxSize, boxSize);

		// Draw box background (checked state selects checked-specific rule via cascade)
		let boxDrawable = ResolvePartDrawable("box", .Background, state);
		if (boxDrawable != null)
		{
			boxDrawable.Draw(ctx, boxRect, state);
			// Draw checkmark icon when checked
			if (IsChecked.Value)
			{
				let checkIcon = ResolvePartDrawable("checkmark", .Background, state);
				if (checkIcon != null)
					checkIcon.Draw(ctx, boxRect);
			}
		}
		else if (IsChecked.Value)
			DrawFallbackChecked(ctx, boxRect, boxSize);
		else
			DrawFallbackUnchecked(ctx, boxRect);

		// Text label
		if (Text.Value != null && !Text.Value.IsEmpty)
		{
			let font = ctx.FontService?.GetFont(fontSize);
			if (font != null)
			{
				var textColor = TextColor.Value ?? ResolveStyleColor(.TextColor, .(220, 225, 235, 255));
				if (!IsEffectivelyEnabled)
					textColor = Palette.ComputeDisabled(textColor);

				let textX = boxSize + spacing;
				let textRect = RectangleF(textX, 0, Width - textX, Height);
				ctx.VG.DrawText(Text.Value, font, textRect, .Left, .Middle, textColor);
			}
		}
	}

	/// Fallback unchecked box when no theme is set.
	private void DrawFallbackUnchecked(UIDrawContext ctx, RectangleF boxRect)
	{
		ctx.VG.FillRect(boxRect, .(30, 32, 42, 255));
		ctx.VG.StrokeRect(boxRect, .(100, 105, 120, 255), 1);
	}

	/// Fallback checked box when no theme is set.
	private void DrawFallbackChecked(UIDrawContext ctx, RectangleF boxRect, float boxSize)
	{
		// Accent fill
		ctx.VG.FillRect(boxRect, .(80, 150, 240, 255));

		// White checkmark
		let cx = boxRect.X + boxSize * 0.5f;
		let cy = boxRect.Y + boxSize * 0.5f;
		let s = boxSize * 0.3f;
		ctx.VG.BeginPath();
		ctx.VG.MoveTo(cx - s, cy);
		ctx.VG.LineTo(cx - s * 0.3f, cy + s * 0.7f);
		ctx.VG.LineTo(cx + s, cy - s * 0.5f);
		ctx.VG.Stroke(.(255, 255, 255, 255), 2);
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled) return;
		if (e.Button == .Left)
		{
			IsChecked.Value = !IsChecked.Value;
			e.Handled = true;
		}
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEffectivelyEnabled) return;
		if (e.Key == .Space || e.Key == .Return)
		{
			IsChecked.Value = !IsChecked.Value;
			e.Handled = true;
		}
	}

	public override void OnActivate()
	{
		if (!IsEffectivelyEnabled) return;
		IsChecked.Value = !IsChecked.Value;
	}
}
