namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Static positioning helpers for popups, tooltips, and menus.
/// Pure calculations - no state. Reusable across all overlay types.
public static class PopupPositioner
{
	/// Position below anchor; if clips bottom, flip above. Clamp horizontally.
	public static (float x, float y) PositionBestFit(RectangleF anchor, Vector2 popupSize, RectangleF screen)
	{
		var x = anchor.X;
		var y = anchor.Y + anchor.Height;

		// Flip above if clipping bottom.
		if (y + popupSize.Y > screen.Y + screen.Height)
			y = anchor.Y - popupSize.Y;

		// Clamp horizontal.
		if (x + popupSize.X > screen.X + screen.Width)
			x = screen.X + screen.Width - popupSize.X;
		if (x < screen.X) x = screen.X;

		// Clamp vertical.
		if (y < screen.Y) y = screen.Y;

		return (x, y);
	}

	/// Position directly below anchor, clamped.
	public static (float x, float y) PositionBelow(RectangleF anchor, Vector2 popupSize, RectangleF screen)
	{
		var x = anchor.X;
		var y = anchor.Y + anchor.Height;
		if (x + popupSize.X > screen.X + screen.Width)
			x = screen.X + screen.Width - popupSize.X;
		if (x < screen.X) x = screen.X;
		return (x, y);
	}

	/// Position directly above anchor, clamped.
	public static (float x, float y) PositionAbove(RectangleF anchor, Vector2 popupSize, RectangleF screen)
	{
		var x = anchor.X;
		var y = anchor.Y - popupSize.Y;
		if (x + popupSize.X > screen.X + screen.Width)
			x = screen.X + screen.Width - popupSize.X;
		if (x < screen.X) x = screen.X;
		if (y < screen.Y) y = screen.Y;
		return (x, y);
	}

	/// Position to the right of parent menu; if clips right, flip left.
	public static (float x, float y) PositionSubmenu(RectangleF parent, Vector2 popupSize, RectangleF screen)
	{
		var x = parent.X + parent.Width;
		var y = parent.Y;

		if (x + popupSize.X > screen.X + screen.Width)
			x = parent.X - popupSize.X;

		if (y + popupSize.Y > screen.Y + screen.Height)
			y = screen.Y + screen.Height - popupSize.Y;
		if (y < screen.Y) y = screen.Y;

		return (x, y);
	}
}
