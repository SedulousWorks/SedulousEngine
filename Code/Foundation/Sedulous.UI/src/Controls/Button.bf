namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Fonts;
using Sedulous.VG;

/// Button with a background drawable and a text label.
/// Uses theme for defaults; per-instance overrides take priority.
public class Button : View
{
	public String Text ~ delete _;
	public Drawable Background ~ delete _;

	// Nullable per-instance overrides — null = use theme.
	private Color? mTextColor;
	private float? mFontSize;
	private Thickness? mPadding;

	public Color TextColor
	{
		get => mTextColor ?? Context?.Theme?.GetColor("Button.Foreground") ?? .(240, 240, 245, 255);
		set => mTextColor = value;
	}

	public float FontSize
	{
		get => mFontSize ?? Context?.Theme?.GetDimension("Button.FontSize", 16) ?? 16;
		set { mFontSize = value; InvalidateLayout(); }
	}

	public Thickness Padding
	{
		get => mPadding ?? Context?.Theme?.GetPadding("Button.Padding", .(12, 8)) ?? .(12, 8);
		set { mPadding = value; InvalidateLayout(); }
	}

	// Visual state flags (set by InputManager).
	public bool IsHovered;
	public bool IsPressed;

	// Click event.
	public Event<delegate void(Button)> OnClick ~ _.Dispose();

	public this()
	{
		IsFocusable = true;
	}

	public void SetText(StringView text)
	{
		if (Text == null)
			Text = new String(text);
		else
			Text.Set(text);
		InvalidateLayout();
	}

	public ControlState GetControlState()
	{
		if (!IsEffectivelyEnabled) return .Disabled;
		if (IsPressed) return .Pressed;
		if (IsFocused) return .Focused;
		if (IsHovered) return .Hover;
		return .Normal;
	}

	public void FireClick()
	{
		OnClick(this);
	}

	/// Build a default StateListDrawable background from the theme.
	/// Called when Background is null and a theme is available.
	private void DrawDefaultBackground(UIDrawContext ctx, RectangleF bounds, ControlState state)
	{
		let theme = ctx.Theme;
		if (theme == null) return;

		let radius = theme.GetDimension("Button.CornerRadius", 4);
		let stateKey = scope String();

		switch (state)
		{
		case .Hover:    stateKey.Set("Button.Background.Hover");
		case .Pressed:  stateKey.Set("Button.Background.Pressed");
		case .Disabled: stateKey.Set("Button.Background.Disabled");
		default:        stateKey.Set("Button.Background");
		}

		let color = theme.GetColor(stateKey, theme.GetColor("Button.Background", theme.Palette.Primary));

		if (radius > 0)
			ctx.VG.FillRoundedRect(bounds, radius, color);
		else
			ctx.VG.FillRect(bounds, color);
	}

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		let fontSize = FontSize;
		let padding = Padding;
		float textW = 0, textH = fontSize;

		if (Text != null && Text.Length > 0 && Context?.FontService != null)
		{
			let font = Context.FontService.GetFont(fontSize);
			if (font != null)
			{
				textW = font.Font.MeasureString(Text);
				textH = font.Font.Metrics.LineHeight;
			}
		}

		let w = textW + padding.TotalHorizontal;
		let h = textH + padding.TotalVertical;
		MeasuredSize = .(wSpec.Resolve(w), hSpec.Resolve(h));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);
		let state = GetControlState();
		let padding = Padding;

		// Draw background.
		if (Background != null)
			Background.Draw(ctx, bounds, state);
		else
			DrawDefaultBackground(ctx, bounds, state);

		// Draw label.
		if (Text != null && Text.Length > 0 && ctx.FontService != null)
		{
			let font = ctx.FontService.GetFont(FontSize);
			if (font != null)
			{
				let contentBounds = RectangleF(
					padding.Left, padding.Top,
					Width - padding.TotalHorizontal,
					Height - padding.TotalVertical);
				ctx.VG.DrawText(Text, font, contentBounds, .Center, .Middle, TextColor);
			}
		}

		// Focus ring from theme — matches button corner radius.
		if (IsFocused)
		{
			let ringColor = ctx.Theme?.GetColor("Focus.Ring", .(100, 160, 255, 180)) ?? .(100, 160, 255, 180);
			let radius = ctx.Theme?.GetDimension("Button.CornerRadius", 4) ?? 4;
			if (radius > 0)
				ctx.VG.StrokeRoundedRect(.(-1, -1, Width + 2, Height + 2), radius + 1, ringColor, 2.0f);
			else
				ctx.VG.StrokeRect(.(-1, -1, Width + 2, Height + 2), ringColor, 2.0f);
		}
	}
}
