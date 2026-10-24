using System;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// Separator and Spacer: the two pieces a row or a column of controls is spaced with. Each takes its
// orientation from its parent's flex direction, so the same element is a vertical rule in a
// toolbar's row and a horizontal one in a menu's column. A separator is a line as thick as its
// `thickness` and the colour of its background (a sheet's `separator { background-color }`, else a
// quiet grey of its own), stretched across the line it is in. A spacer takes the room left
// (flexible, the default) or a fixed `size` along the line.

/// What Separator.bf keeps out of the public surface.
internal static class SeparatorDetail
{
	// Along a row (its parent lays out across): a separator stands up, a spacer runs across.
	public static bool InRow(Node node)
	{
		let parent = node.Parent;
		if (parent == null)
			return false;
		let d = parent.LayoutStyle.Direction;
		return (d == .Row) || (d == .RowReverse);
	}
}

[GuiReflect(true)]
class Separator : UIWidget
{
	private float mThickness = 1.0f;
	private Color mColor = .(0.50f, 0.54f, 0.60f, 0.35f);

	public this()
	{
		Tag = "separator";
		AccessRoleName = "separator"; // what a screen reader takes it for
		HitTestVisible = false;
		using (StyleWriteScope(this)) // its own values, which a sheet returns to
		{
			EditLayoutStyle(scope (s) =>
				{
					s.AlignSelf = .Stretch; // across the whole line, even in a centred row
					s.Shrink = 0.0f;
				});
		}
	}

	/// How thick its line is (the sheet's `thickness`).
	[GuiProperty("thickness")]
	public float Thickness
	{
		get => mThickness;
		set
		{
			mThickness = Math.Max(0.0f, value);
			RequestLayout();
		}
	}

	/// Whether it stands up (in a row) or lies across (in a column).
	public bool IsVertical => SeparatorDetail.InRow(this);

	public override Float2 MeasureContent(Float2 available)
	{
		return IsVertical ? Float2(mThickness, 0.0f) : Float2(0.0f, mThickness);
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		if ((Box.BackgroundColor.A > 0.0f) || !Box.Layers.IsEmpty)
			return; // the sheet's background is the line, drawn as its box
		let line = ContentBounds;
		FilledBox(mColor, scope NodeBox()).DrawUnder(ctx, line);
	}
}

[GuiReflect(true)]
class Spacer : UIWidget
{
	private float mSpace = 0.0f;

	public this()
	{
		Tag = "spacer";
		HitTestVisible = false;
		using (StyleWriteScope(this))
		{
			ApplySize();
		}
	}

	/// A fixed length along the line (0: it takes the room left). Markup's and a sheet's `size`
	/// (Size is the node's own).
	[GuiProperty("size")]
	public float Space
	{
		get => mSpace;
		set
		{
			mSpace = Math.Max(0.0f, value);
			using (StyleWriteScope(this))
			{
				ApplySize();
			}
		}
	}

	public override Float2 MeasureContent(Float2 available)
	{
		return SeparatorDetail.InRow(this) ? Float2(mSpace, 0.0f) : Float2(0.0f, mSpace);
	}

	private void ApplySize()
	{
		let flexible = mSpace <= 0.0f;
		EditLayoutStyle(scope (s) =>
			{
				s.Grow = flexible ? 1.0f : 0.0f;
				s.Shrink = flexible ? 1.0f : 0.0f;
			});
		RequestLayout();
	}
}
