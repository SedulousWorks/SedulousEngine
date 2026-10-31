using System;

namespace Sedulous.UI;

/// The ONE per child placement record.
///
/// Every view carries a LayoutStyle value; every container reads the fields it understands
/// and ignores the rest. That is what lets a child keep its intent across reparenting, and it
/// is why no container needs a parameter subclass of its own.
///
/// Container OWNED data stays on the container: grid tracks, flex direction and justification,
/// dock's last-child-fill. Only what belongs to the CHILD lives here.
struct LayoutStyle
{
	// ---- Every container ---------------------------------------------------------------------

	/// Defaults to Wrap, fitting the content.
	public Declared<SizeSpec> Width = .(SizeSpec.Wrap(), false);
	public Declared<SizeSpec> Height = .(SizeSpec.Wrap(), false);
	/// Space between this view and its siblings and parent.
	public Declared<Thickness> Margin = .();
	/// Clamps applied AFTER the Width and Height spec. A zero unit is no clamp.
	public Declared<Unit> MinWidth = .();
	public Declared<Unit> MinHeight = .();
	public Declared<Unit> MaxWidth = .();
	public Declared<Unit> MaxHeight = .();
	/// In the container's flow, or placed by the insets below.
	public Declared<Position> Position = .(.Static, false);
	/// Draw order among siblings, ascending, with ties keeping child order. Hit testing walks
	/// the same order front to back.
	public Declared<int32> ZIndex = .();

	// ---- FlexLayout --------------------------------------------------------------------------

	/// The share of leftover main axis space this child absorbs.
	public Declared<float> FlexGrow = .();
	/// How much this child gives up when there is not enough space.
	///
	/// Defaults to NOUGHT rather than CSS's one, and FlexLayout does not read it yet, so a
	/// nowrap overflow still runs past the edge.
	public Declared<float> FlexShrink = .();
	/// The main axis starting size before growing. A zero unit means auto: the content size,
	/// or nought for a growing child, which is what the `flex: <grow>` shorthand means.
	public Declared<Unit> FlexBasis = .();
	/// Cross axis override. Unset falls back to the parent's AlignItems, or the sheet.
	public Align? AlignSelf = null;

	// ---- FrameLayout, FlowLayout, and the FlexLayout cross axis -------------------------------

	/// Where this child sits in the cell the container hands it.
	public Gravity Gravity = .None;

	// ---- DockLayout --------------------------------------------------------------------------

	public Dock Dock = .Left;

	// ---- AbsoluteLayout, and Position.Absolute in any container -------------------------------

	/// Offset from the container's content box.
	///
	/// AbsoluteLayout reads Left and Top only. An absolute child in any container honours all
	/// four: Right and Bottom anchor the far edges, and declaring both Left and Right makes
	/// the width the remainder between them.
	public Declared<float> Left = .();
	public Declared<float> Top = .();
	public Declared<float> Right = .();
	public Declared<float> Bottom = .();

	// ---- GridLayout --------------------------------------------------------------------------

	/// Minus one is auto flow: the grid assigns the next free cell and the intent STAYS minus
	/// one, so reordering the children re-flows them rather than freezing the first result.
	public int32 GridRow = -1;
	public int32 GridColumn = -1;
	public int32 GridRowSpan = 1;
	public int32 GridColumnSpan = 1;

	public this() {}

	[Commutable]
	public static bool operator==(LayoutStyle a, LayoutStyle b) =>
		(a.Width == b.Width) && (a.Height == b.Height) && (a.Margin == b.Margin)
		&& (a.MinWidth == b.MinWidth) && (a.MinHeight == b.MinHeight)
		&& (a.MaxWidth == b.MaxWidth) && (a.MaxHeight == b.MaxHeight)
		&& (a.Position == b.Position) && (a.ZIndex == b.ZIndex)
		&& (a.FlexGrow == b.FlexGrow) && (a.FlexShrink == b.FlexShrink)
		&& (a.FlexBasis == b.FlexBasis) && (a.AlignSelf == b.AlignSelf)
		&& (a.Gravity == b.Gravity) && (a.Dock == b.Dock)
		&& (a.Left == b.Left) && (a.Top == b.Top) && (a.Right == b.Right)
		&& (a.Bottom == b.Bottom)
		&& (a.GridRow == b.GridRow) && (a.GridColumn == b.GridColumn)
		&& (a.GridRowSpan == b.GridRowSpan) && (a.GridColumnSpan == b.GridColumnSpan);
}
