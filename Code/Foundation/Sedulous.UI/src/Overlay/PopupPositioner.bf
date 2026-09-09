using Sedulous.Core;

namespace Sedulous.UI;

/// Where to put a popup, tooltip or menu. Pure arithmetic, holding no state.
static class PopupPositioner
{
	/// Below the anchor, flipping above when that would clip the bottom, then clamped to the
	/// screen. The general purpose choice.
	public static Float2 BestFit(Rectangle anchor, Float2 popupSize, Rectangle screen)
	{
		var x = anchor.X;
		var y = anchor.Y + anchor.Height;

		if (y + popupSize.Y > screen.Y + screen.Height)
			y = anchor.Y - popupSize.Y;

		if (x + popupSize.X > screen.X + screen.Width)
			x = screen.X + screen.Width - popupSize.X;
		if (x < screen.X)
			x = screen.X;
		if (y < screen.Y)
			y = screen.Y;

		return .(x, y);
	}

	/// Directly below the anchor, clamped horizontally only: the caller has already decided
	/// the popup belongs below.
	public static Float2 Below(Rectangle anchor, Float2 popupSize, Rectangle screen)
	{
		var x = anchor.X;
		let y = anchor.Y + anchor.Height;

		if (x + popupSize.X > screen.X + screen.Width)
			x = screen.X + screen.Width - popupSize.X;
		if (x < screen.X)
			x = screen.X;

		return .(x, y);
	}

	/// Directly above the anchor, clamped to the screen.
	public static Float2 Above(Rectangle anchor, Float2 popupSize, Rectangle screen)
	{
		var x = anchor.X;
		var y = anchor.Y - popupSize.Y;

		if (x + popupSize.X > screen.X + screen.Width)
			x = screen.X + screen.Width - popupSize.X;
		if (x < screen.X)
			x = screen.X;
		if (y < screen.Y)
			y = screen.Y;

		return .(x, y);
	}

	/// To the right of a parent menu, flipping left when that would clip.
	public static Float2 Submenu(Rectangle parent, Float2 popupSize, Rectangle screen)
	{
		// Clears the parent menu's border rather than sitting on top of it.
		const float cGap = 2.0f;

		var x = parent.X + parent.Width + cGap;
		var y = parent.Y;

		if (x + popupSize.X > screen.X + screen.Width)
			x = parent.X - popupSize.X - cGap;
		if (y + popupSize.Y > screen.Y + screen.Height)
			y = screen.Y + screen.Height - popupSize.Y;
		if (y < screen.Y)
			y = screen.Y;

		return .(x, y);
	}

	/// Centred in the screen.
	public static Float2 Center(Float2 popupSize, Rectangle screen) =>
		.(screen.X + (screen.Width - popupSize.X) * 0.5f,
			screen.Y + (screen.Height - popupSize.Y) * 0.5f);
}
