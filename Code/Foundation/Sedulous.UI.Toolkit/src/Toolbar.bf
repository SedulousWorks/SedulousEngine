namespace Sedulous.UI.Toolkit;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;
using Sedulous.VG;

/// Base class for items in a Toolbar. Any View can be a toolbar item.
public class ToolbarItem : View
{
}

/// Toolbar separator - vertical divider line.
public class ToolbarSeparator : ToolbarItem
{
	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		MeasuredSize = .(wSpec.Resolve(8), hSpec.Resolve(0));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let color = ctx.Theme?.GetColor("Toolbar.Separator", .(80, 85, 100, 255)) ?? .(80, 85, 100, 255);
		let cx = Width * 0.5f;
		let margin = Height * 0.2f;
		ctx.VG.FillRect(.(cx, margin, 1, Height - margin * 2), color);
	}
}

/// Toolbar button - supports text, icon (via custom draw delegate), or both.
public class ToolbarButton : ToolbarItem
{
	private String mText ~ delete _;
	private delegate void(VGContext, RectangleF) mIconDraw ~ delete _;

	public Event<delegate void(ToolbarButton)> OnClick ~ _.Dispose();

	public this()
	{
		IsFocusable = true;
		Cursor = .Hand;
	}

	public void SetText(StringView text)
	{
		if (mText == null) mText = new String(text);
		else mText.Set(text);
		InvalidateLayout();
	}

	/// Set a custom icon draw delegate. Drawn in the icon area before text.
	public void SetIcon(delegate void(VGContext, RectangleF) iconDraw)
	{
		delete mIconDraw;
		mIconDraw = iconDraw;
	}

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		float w = 8; // padding
		float textH = 14;

		if (mIconDraw != null)
			w += 16; // icon area

		if (mText != null && mText.Length > 0)
		{
			if (mIconDraw != null) w += 4; // gap between icon and text
			if (Context?.FontService != null)
			{
				let font = Context.FontService.GetFont(13);
				if (font != null)
				{
					w += font.Font.MeasureString(mText);
					textH = font.Font.Metrics.LineHeight;
				}
			}
		}

		w += 8; // right padding
		MeasuredSize = .(wSpec.Resolve(w), hSpec.Resolve(textH + 8));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);

		// Hover/pressed background.
		if (IsHovered)
		{
			if (!ctx.TryDrawDrawable("ToolbarButton.Background", bounds, .Hover))
			{
				let hoverColor = ctx.Theme?.GetColor("Toolbar.ButtonHover", .(70, 75, 90, 255)) ?? .(70, 75, 90, 255);
				ctx.VG.FillRoundedRect(bounds, 3, hoverColor);
			}
		}

		float x = 8;

		// Icon.
		if (mIconDraw != null)
		{
			let iconRect = RectangleF(x, (Height - 16) * 0.5f, 16, 16);
			mIconDraw(ctx.VG, iconRect);
			x += 16;
		}

		// Text.
		if (mText != null && mText.Length > 0 && ctx.FontService != null)
		{
			if (mIconDraw != null) x += 4;
			let font = ctx.FontService.GetFont(13);
			if (font != null)
			{
				let textColor = ctx.Theme?.Palette.Text ?? .(220, 225, 235, 255);
				ctx.VG.DrawText(mText, font, .(x, 0, Width - x - 8, Height), .Left, .Middle, textColor);
			}
		}

		// Focus ring.
		if (IsFocused)
			ctx.DrawFocusRing(bounds, 3);
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled || e.Button != .Left) return;
		OnClick(this);
		e.Handled = true;
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEffectivelyEnabled) return;
		if (e.Key == .Space || e.Key == .Return)
		{
			OnClick(this);
			e.Handled = true;
		}
	}
}

/// Toolbar toggle button - on/off state with accent background when active.
public class ToolbarToggle : ToolbarButton
{
	private bool mIsChecked;

	public Event<delegate void(ToolbarToggle, bool)> OnCheckedChanged ~ _.Dispose();

	public bool IsChecked
	{
		get => mIsChecked;
		set
		{
			if (mIsChecked != value)
			{
				mIsChecked = value;
				InvalidateVisual();
				OnCheckedChanged(this, value);
			}
		}
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);

		// Active toggle: accent background.
		if (mIsChecked)
		{
			if (!ctx.TryDrawDrawable("ToolbarToggle.CheckedBackground", bounds, .Pressed))
			{
				let onColor = ctx.Theme?.GetColor("Toolbar.ToggleOn", .(40, 80, 160, 255)) ?? .(40, 80, 160, 255);
				ctx.VG.FillRoundedRect(bounds, 3, onColor);
			}
		}

		base.OnDraw(ctx);
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled || e.Button != .Left) return;
		IsChecked = !mIsChecked;
		e.Handled = true;
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

/// Horizontal toolbar container. Draws background with bottom border.
/// Add items via AddItem(), AddButton(), AddSeparator(), AddToggle().
public class Toolbar : LinearLayout
{
	public this()
	{
		Orientation = .Horizontal;
		Spacing = 2;
		Padding = .(4);
	}

	/// Add any ToolbarItem (or View).
	public void AddItem(View item)
	{
		AddView(item, new LinearLayout.LayoutParams() { Height = Sedulous.UI.LayoutParams.MatchParent });
	}

	/// Add a text button. Returns the button for further configuration.
	public ToolbarButton AddButton(StringView text)
	{
		let btn = new ToolbarButton();
		btn.SetText(text);
		AddItem(btn);
		return btn;
	}

	/// Add a separator.
	public ToolbarSeparator AddSeparator()
	{
		let sep = new ToolbarSeparator();
		AddItem(sep);
		return sep;
	}

	/// Add a toggle button. Returns the toggle for further configuration.
	public ToolbarToggle AddToggle(StringView text)
	{
		let toggle = new ToolbarToggle();
		toggle.SetText(text);
		AddItem(toggle);
		return toggle;
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		// Background.
		if (!ctx.TryDrawDrawable("Toolbar.Background", .(0, 0, Width, Height), .Normal))
		{
			let bgColor = ctx.Theme?.GetColor("Toolbar.Background", .(35, 37, 46, 255)) ?? .(35, 37, 46, 255);
			ctx.VG.FillRect(.(0, 0, Width, Height), bgColor);
		}

		// Bottom border.
		let borderColor = ctx.Theme?.GetColor("Toolbar.Border", .(65, 70, 85, 255)) ?? .(65, 70, 85, 255);
		ctx.VG.FillRect(.(0, Height - 1, Width, 1), borderColor);

		DrawChildren(ctx);
	}
}
