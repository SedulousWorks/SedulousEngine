using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.LegacyGUI;

/// Visual feedback overlay during drag operations.
public class DragAdorner
{
	/// Current position of the adorner (mouse position).
	public Vector2 Position;

	/// The current drop effect.
	public DragDropEffects Effect = .None;

	/// Offset from mouse position to adorner origin.
	public Vector2 Offset = .(8, 8);

	/// Size of the adorner visual.
	public Vector2 Size = .(64, 32);

	/// Custom render delegate (optional).
	/// If set, this is called instead of the default rendering.
	public delegate void(DrawContext ctx, Vector2 pos, DragDropEffects effect) CustomRender ~ delete _;

	/// Background color of the drag preview.
	public Color32 BackgroundColor = Color32(50, 50, 50, 220);

	/// Border color of the drag preview.
	public Color32 BorderColor = Color32(100, 100, 100, 255);

	/// Text/icon color.
	public Color32 ForegroundColor = Color32(220, 220, 220, 255);

	/// Error/no-drop icon color.
	public Color32 ErrorColor = Color32(200, 60, 60, 255);

	/// Copy icon color (success).
	public Color32 CopyColor = Color32(60, 180, 60, 255);

	/// Link icon color.
	public Color32 LinkColor = Color32(60, 120, 200, 255);

	/// Optional text label to display.
	public String Label ~ delete _;

	/// Whether the adorner is visible.
	public bool IsVisible = true;

	/// Creates a new DragAdorner.
	public this()
	{
	}

	/// Applies theme colors from a palette.
	public void ApplyTheme(Palette palette)
	{
		BackgroundColor = Color32(palette.Surface.R, palette.Surface.G, palette.Surface.B, 220);
		BorderColor = palette.Border;
		ForegroundColor = palette.Text;
		ErrorColor = palette.Error;
		CopyColor = palette.Success;
		LinkColor = palette.Primary;
	}

	/// Renders the adorner.
	public void Render(DrawContext ctx)
	{
		if (!IsVisible)
			return;

		if (CustomRender != null)
		{
			CustomRender(ctx, Position + Offset, Effect);
			return;
		}

		// Default rendering
		let rect = RectangleF(Position.X + Offset.X, Position.Y + Offset.Y, Size.X, Size.Y);

		// Background
		ctx.FillRoundedRect(rect, 4, BackgroundColor);

		// Border
		ctx.DrawRoundedRect(rect, 4, BorderColor, 1);

		// Effect indicator icon
		RenderEffectIcon(ctx, rect);

		// Label text (if any)
		if (Label != null && !Label.IsEmpty)
		{
			// todo
			// Text would go here - for now just draw the effect icon
		}
	}

	private void RenderEffectIcon(DrawContext ctx, RectangleF rect)
	{
		let iconSize = 16.0f;
		let iconX = rect.X + 8;
		let iconY = rect.Y + (rect.Height - iconSize) / 2;

		switch (Effect)
		{
		case .None:
			// Red circle with slash for no-drop
			let cx = iconX + iconSize / 2;
			let cy = iconY + iconSize / 2;
			let r = iconSize / 2 - 2;
			ctx.DrawCircle(.(cx, cy), r, ErrorColor, 2);
			ctx.DrawLine(.(cx - r * 0.7f, cy - r * 0.7f), .(cx + r * 0.7f, cy + r * 0.7f), ErrorColor, 2);

		case .Copy:
			// Plus sign for copy
			let midX = iconX + iconSize / 2;
			let midY = iconY + iconSize / 2;
			ctx.DrawLine(.(midX, iconY + 2), .(midX, iconY + iconSize - 2), CopyColor, 2);
			ctx.DrawLine(.(iconX + 2, midY), .(iconX + iconSize - 2, midY), CopyColor, 2);

		case .Move:
			// Arrow for move
			let midX = iconX + iconSize / 2;
			ctx.DrawLine(.(midX, iconY + 2), .(midX, iconY + iconSize - 2), ForegroundColor, 2);
			ctx.DrawLine(.(iconX + 4, iconY + 6), .(midX, iconY + 2), ForegroundColor, 2);
			ctx.DrawLine(.(iconX + iconSize - 4, iconY + 6), .(midX, iconY + 2), ForegroundColor, 2);

		case .Link:
			// Chain link icon (two overlapping circles)
			let r = iconSize / 4;
			ctx.DrawCircle(.(iconX + iconSize / 3, iconY + iconSize / 2), r, LinkColor, 2);
			ctx.DrawCircle(.(iconX + iconSize * 2 / 3, iconY + iconSize / 2), r, LinkColor, 2);

		default:
			break;
		}

		// Draw effect text label
		StringView effectText = "";
		switch (Effect)
		{
		case .None: effectText = "No Drop";
		case .Copy: effectText = "Copy";
		case .Move: effectText = "Move";
		case .Link: effectText = "Link";
		default: effectText = "";
		}

		if (!effectText.IsEmpty)
		{
			// todo
			// Simple text rendering (position to the right of icon)
			// The actual text rendering would use the font system
		}
	}

	/// Resets the adorner to default state.
	public void Reset()
	{
		Position = .Zero;
		Effect = .None;
		IsVisible = true;
		delete CustomRender;
		CustomRender = null;
		if (Label != null)
		{
			delete Label;
			Label = null;
		}
		Size = .(64, 32);
		Offset = .(8, 8);
		// Reset colors to defaults
		BackgroundColor = Color32(50, 50, 50, 220);
		BorderColor = Color32(100, 100, 100, 255);
		ForegroundColor = Color32(220, 220, 220, 255);
		ErrorColor = Color32(200, 60, 60, 255);
		CopyColor = Color32(60, 180, 60, 255);
		LinkColor = Color32(60, 120, 200, 255);
	}

	/// Sets a text label for the adorner.
	public void SetLabel(StringView text)
	{
		if (Label == null)
			Label = new String(text);
		else
			Label.Set(text);
	}

	/// Configures the adorner to show a preview of an element.
	public void SetElementPreview(UIElement element, float maxWidth = 100, float maxHeight = 50)
	{
		if (element == null)
			return;

		// Size based on element, clamped to max
		let bounds = element.ArrangedBounds;
		Size = .(Math.Min(bounds.Width, maxWidth), Math.Min(bounds.Height, maxHeight));

		// Offset to show preview near cursor
		Offset = .(8, 8);
	}
}
