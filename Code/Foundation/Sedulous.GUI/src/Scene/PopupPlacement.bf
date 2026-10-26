using System;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// Where a popup goes: one helper every popup places itself with, a combo box's list, a menu and
// its submenus, a tooltip and a context menu. A size goes against an anchor rectangle on a
// preferred side (below, above, or at the anchor's inline end or start), aligned along that side
// (start, centre or end) and a gap away; when it does not fit there it flips to the other side if
// that side has more room, shrinks to the room on the side it goes (a list then scrolls), and is
// clamped into the bounds (the root's), all in the root's units. The sides across the line and
// the alignment along it are logical: in right to left the inline end is the left, and a
// dropdown's start lines up the right edges, as CSS's logical properties and Godot's and eepp's
// right-to-left menus place them.
// After Godot's popup clamping, GPUI's `anchored` and foundation.ui's PopupPositioner.

/// The side of the anchor a popup goes on: below or above it, or at its inline end or start
/// (right or left in left to right, left or right in right to left).
enum PopupSide : uint8
{
	Below,
	Above,
	InlineEnd,
	InlineStart,
}

/// How a popup lines up along the side it goes on: its start with the anchor's start (a
/// dropdown's inline-start edges, a submenu's tops), centred on it, or its end with the
/// anchor's end.
enum PopupAlign : uint8
{
	Start,
	Center,
	End,
}

struct PopupPlacement
{
	public PopupSide Side = .Below;
	public PopupAlign Align = .Start;
	/// Between the anchor and the popup.
	public float Gap = 0.0f;
	/// Made smaller to fit the room on its side, rather than covering the anchor.
	public bool Shrink = true;
	/// Along its side's line, from where its alignment puts it, toward the line's end (down
	/// beside a side, toward the inline end below or above).
	public float Shift = 0.0f;
	/// Lined up by its content's edge rather than its box's: moved back along the line by its
	/// own padding and border as they are when it is placed (a submenu's first row level with
	/// the row that opened it).
	public bool AlignContent = false;

	public this() { }
}

/// Where it went, and on which side (after a flip, the other one).
struct PlacedPopup
{
	public Float2 Position = .(0.0f, 0.0f);
	/// What it was given, its own or shrunk to fit.
	public Float2 Size = .(0.0f, 0.0f);
	public PopupSide Side = .Below;

	public this() { }
}

/// What PopupPlacement.bf keeps out of the public surface: the sides as the screen has them.
internal static class PopupPlacementDetail
{
	/// The sides as they fall on the screen.
	public enum ScreenSide : uint8
	{
		Below,
		Above,
		Right,
		Left,
	}

	public static ScreenSide OnScreen(PopupSide side, bool rightToLeft)
	{
		switch (side)
		{
		case .Below: return .Below;
		case .Above: return .Above;
		case .InlineEnd: return rightToLeft ? .Left : .Right;
		default: return rightToLeft ? .Right : .Left;
		}
	}

	/// The room between the anchor and the bounds' edge on `side`.
	public static float RoomOn(ScreenSide side, Rect anchor, Rect bounds, float gap)
	{
		switch (side)
		{
		case .Below: return bounds.Y + bounds.Height - (anchor.Y + anchor.Height) - gap;
		case .Above: return anchor.Y - bounds.Y - gap;
		case .Right: return bounds.X + bounds.Width - (anchor.X + anchor.Width) - gap;
		default: return anchor.X - bounds.X - gap;
		}
	}

	/// Lined up along a side: from `start` (the anchor's) over `length`, a popup `extent` long.
	public static float Aligned(PopupAlign align, float start, float length, float extent)
	{
		switch (align)
		{
		case .Center: return start + (length - extent) * 0.5f;
		case .End: return start + length - extent;
		default: return start;
		}
	}

	/// Into [low, low + room]: a popup longer than the room starts at its low edge.
	public static float Clamped(float at, float extent, float low, float room)
	{
		var at;
		if (at + extent > low + room)
			at = low + room - extent;
		return (at < low) ? low : at;
	}
}

static
{
	public static PopupSide OppositeSide(PopupSide side)
	{
		switch (side)
		{
		case .Below: return .Above;
		case .Above: return .Below;
		case .InlineEnd: return .InlineStart;
		default: return .InlineEnd;
		}
	}

	/// Places `size` against `anchor` within `bounds` as `placement` prefers, its logical side and
	/// alignment taken in the direction `rightToLeft` says (the anchor's).
	public static PlacedPopup PlacePopup(Rect anchor, Float2 size, Rect bounds, PopupPlacement placement, bool rightToLeft)
	{
		var size;
		PopupSide side = placement.Side;
		let vertical = (side == .Below) || (side == .Above);
		let need = vertical ? size.Y : size.X;
		let room = PopupPlacementDetail.RoomOn(PopupPlacementDetail.OnScreen(side, rightToLeft), anchor, bounds, placement.Gap);
		if ((room < need) &&
			(PopupPlacementDetail.RoomOn(PopupPlacementDetail.OnScreen(OppositeSide(side), rightToLeft), anchor, bounds, placement.Gap) > room))
			side = OppositeSide(side);
		let screen = PopupPlacementDetail.OnScreen(side, rightToLeft);

		PlacedPopup result = .();
		result.Side = side;
		// Shrunk to the room on its side (along it) and to the bounds (across).
		if (placement.Shrink)
		{
			let sideRoom = Math.Max(0.0f, PopupPlacementDetail.RoomOn(screen, anchor, bounds, placement.Gap));
			if (vertical)
			{
				size.Y = Math.Min(size.Y, sideRoom);
				size.X = Math.Min(size.X, bounds.Width);
			}
			else
			{
				size.X = Math.Min(size.X, sideRoom);
				size.Y = Math.Min(size.Y, bounds.Height);
			}
		}
		result.Size = size;
		let gap = placement.Gap;
		switch (screen)
		{
		case .Below: result.Position.Y = anchor.Y + anchor.Height + gap;
		case .Above: result.Position.Y = anchor.Y - gap - size.Y;
		case .Right: result.Position.X = anchor.X + anchor.Width + gap;
		case .Left: result.Position.X = anchor.X - gap - size.X;
		}
		if (vertical)
		{
			// Along the line: the start is the right in right to left.
			PopupAlign align = placement.Align;
			if (rightToLeft && (align != .Center))
				align = (align == .Start) ? .End : .Start;
			result.Position.X = PopupPlacementDetail.Aligned(align, anchor.X, anchor.Width, size.X) + (rightToLeft ? -placement.Shift : placement.Shift);
		}
		else
			result.Position.Y = PopupPlacementDetail.Aligned(placement.Align, anchor.Y, anchor.Height, size.Y) + placement.Shift;
		result.Position.X = PopupPlacementDetail.Clamped(result.Position.X, size.X, bounds.X, bounds.Width);
		result.Position.Y = PopupPlacementDetail.Clamped(result.Position.Y, size.Y, bounds.Y, bounds.Height);
		return result;
	}

	/// A popup at a point (a context menu at the pointer): below it and toward the inline end,
	/// above it where it does not fit below, slid back in from the edges.
	public static PlacedPopup PlaceAtPoint(Float2 point, Float2 size, Rect bounds, bool rightToLeft)
	{
		return PlacePopup(.(point.X, point.Y, 0.0f, 0.0f), size, bounds, .(), rightToLeft);
	}
}
