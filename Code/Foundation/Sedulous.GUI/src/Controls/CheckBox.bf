namespace Sedulous.GUI;

using System;
using Sedulous.Core.Mathematics;

/// Toggle checkbox with text label.
public class CheckBox : View
{
	private bool mIsChecked;
	private String mText ~ delete _;

	/// Whether the checkbox is checked.
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

	/// Text label next to the checkbox.
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

	/// Override font size for the label text.
	public float? FontSize;

	/// Override text color for the label text.
	public Color? TextColor;

	/// Fired when checked state changes.
	public Event<delegate void(CheckBox, bool)> OnCheckedChanged ~ _.Dispose();

	public this() { IsFocusable = true; IsTabStop = true; Cursor = .Hand; }
	public this(StringView text) : this() { mText = new String(text); }
	public this(StringView text, bool isChecked) : this(text) { mIsChecked = isChecked; }

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let boxSize = ResolveStyleFloat(.BoxSize, 18);
		let spacing = ResolveStyleFloat(.Spacing, 6);
		let fontSize = FontSize ?? ResolveStyleFloat(.FontSize, 16);

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

		let totalW = boxSize + ((textW > 0) ? spacing + textW : 0);
		let totalH = Math.Max(boxSize, textH);

		MeasuredSize = .(constraints.ConstrainWidth(totalW), constraints.ConstrainHeight(totalH));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let boxSize = ResolveStyleFloat(.BoxSize, 18);
		let spacing = ResolveStyleFloat(.Spacing, 6);
		let fontSize = FontSize ?? ResolveStyleFloat(.FontSize, 16);
		let state = GetControlState();

		// Box position (vertically centered)
		let boxY = (Height - boxSize) * 0.5f;
		let boxRect = RectangleF(0, boxY, boxSize, boxSize);

		// Draw the appropriate drawable for checked/unchecked state.
		if (mIsChecked)
		{
			let checkedDrawable = ResolveStyleDrawable(.CheckedBackground);
			if (checkedDrawable != null)
			{
				checkedDrawable.Draw(ctx, boxRect, state);
				// Draw checkmark icon on top of checked background
				let checkIcon = ResolveStyleDrawable(.CheckmarkIcon);
				if (checkIcon != null)
					checkIcon.Draw(ctx, boxRect);
			}
			else
				DrawFallbackChecked(ctx, boxRect, boxSize);
		}
		else
		{
			let boxDrawable = ResolveStyleDrawable(.BoxDrawable);
			if (boxDrawable != null)
				boxDrawable.Draw(ctx, boxRect, state);
			else
				DrawFallbackUnchecked(ctx, boxRect);
		}

		// Text label
		if (mText != null && !mText.IsEmpty)
		{
			let font = ctx.FontService?.GetFont(fontSize);
			if (font != null)
			{
				var textColor = TextColor ?? ResolveStyleColor(.TextColor, .(220, 225, 235, 255));
				if (!IsEffectivelyEnabled)
					textColor = Palette.ComputeDisabled(textColor);

				let textX = boxSize + spacing;
				let textRect = RectangleF(textX, 0, Width - textX, Height);
				ctx.VG.DrawText(mText, font, textRect, .Left, .Middle, textColor);
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
			IsChecked = !mIsChecked;
			e.Handled = true;
		}
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEffectivelyEnabled) return;
		if (e.Key == .Space || e.Key == .Return)
		{
			IsChecked = !mIsChecked;
			e.Handled = true;
		}
	}
}
