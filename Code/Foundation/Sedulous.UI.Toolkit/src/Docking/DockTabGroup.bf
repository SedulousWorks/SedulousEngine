using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// Several [[DockablePanel]]s sharing one region and one tab strip.
///
/// The panels are BORROWED here and owned by the child list, and only the selected one is
/// visible; the rest are Gone, so they cost neither layout nor draw. A panel added to a group
/// loses its own header, because the tab has taken over both naming it and being the handle it
/// is dragged by.
///
/// Dragging a tab REMOVES its panel from the group immediately, so the strip closes up under the
/// cursor and the drag is visibly in progress. A cancelled drag puts it back where it was.
class DockTabGroup : ViewGroup, IDragSource
{
	private const float CloseButtonSize = 10.0f;
	private const float CloseButtonPadding = 6.0f;
	private const float CloseButtonWidth = CloseButtonSize + (CloseButtonPadding * 2.0f);

	/// Fired whenever the selection changes, by a click or otherwise.
	public Event<delegate void(DockablePanel)> OnTabSelected ~ _.Dispose();

	/// BORROWED: the child list owns the panels.
	private List<DockablePanel> mPanels = new .() ~ delete _;
	private int32 mSelectedIndex = -1;
	private float mTabHeight = 24.0f;

	/// How far the strip is scrolled. There is no room for a scroll bar in a strip this tall,
	/// so the wheel does the scrolling and a selection change brings its tab into view.
	private float mTabScroll = 0.0f;
	private bool mTabOverflow = false;
	private bool mScrollSelectedIntoView = false;
	private int32 mHoveredTabIndex = -1;

	/// Rebuilt every draw, and REUSED for hit testing, which is what keeps clicks aligned with
	/// what is on screen through any amount of scrolling for free.
	private List<Rectangle> mTabRects = new .() ~ delete _;
	private List<Rectangle> mCloseRects = new .() ~ delete _;

	private int32 mDragTabIndex = -1;
	/// BORROWED: held out of the tree for the duration of a drag.
	private DockablePanel mDraggedPanel = null;
	private int32 mDragOriginalIndex = -1;

	public this() {}

	public int32 SelectedIndex => mSelectedIndex;

	public int32 PanelCount => (int32)mPanels.Count;

	public float TabHeight
	{
		get => mTabHeight;
		set
		{
			mTabHeight = Max(16.0f, value);
			Invalidate();
		}
	}

	/// BORROWED.
	public DockablePanel SelectedPanel =>
		((mSelectedIndex >= 0) && (mSelectedIndex < mPanels.Count)) ? mPanels[mSelectedIndex]
			: null;

	/// BORROWED.
	public DockablePanel GetPanel(int32 index) =>
		((index >= 0) && (index < mPanels.Count)) ? mPanels[index] : null;

	public void SetSelectedIndex(int32 value)
	{
		if ((value == mSelectedIndex) || (value < -1) || (value >= mPanels.Count))
			return;

		// The outgoing panel goes Gone HERE rather than waiting for the next layout, so a
		// selection change made between frames never leaves two panels visible at once.
		if ((mSelectedIndex >= 0) && (mSelectedIndex < mPanels.Count))
			mPanels[mSelectedIndex].Visibility = .Gone;

		mSelectedIndex = value;
		// The strip may be scrolled away from the tab just selected, so the next draw brings it
		// back into view.
		mScrollSelectedIntoView = true;

		if ((mSelectedIndex >= 0) && (mSelectedIndex < mPanels.Count))
			mPanels[mSelectedIndex].Visibility = .Visible;

		Invalidate();

		let panel = SelectedPanel;
		OnTabSelected(panel);

		// The manager is told too, because being its group's selected tab is not the same as
		// being the application's active panel when two groups sit side by side.
		if (let manager = FindManager())
			manager.OnPanelActivated(panel);
	}

	/// The dock manager above this group, if there is one. A group can be used on its own.
	private DockManager FindManager()
	{
		var current = Parent;
		while (current != null)
		{
			if (let manager = current as DockManager)
				return manager;

			current = current.Parent;
		}

		return null;
	}

	// ---- Membership -----------------------------------------------------------------------------

	/// Appends a panel as a tab. CONSUMES the caller's reference.
	public void AddPanel(DockablePanel panel)
	{
		mPanels.Add(panel);
		PrepareForTabbing(panel);
		AddView(panel);

		if (mSelectedIndex < 0)
			SetSelectedIndex(0);
		else
			Invalidate();
	}

	/// Inserts at a position, clamped into range. CONSUMES the caller's reference.
	public void InsertPanel(int32 index, DockablePanel panel)
	{
		let at = Clamp(index, 0, (int32)mPanels.Count);
		mPanels.Insert(at, panel);
		PrepareForTabbing(panel);
		AddView(panel);

		if (mSelectedIndex < 0)
		{
			SetSelectedIndex(0);
			return;
		}

		// Inserting at or before the selection pushes it along, so the SAME panel stays
		// selected rather than the index quietly meaning a different one.
		if (at <= mSelectedIndex)
			mSelectedIndex++;

		Invalidate();
	}

	private void PrepareForTabbing(DockablePanel panel)
	{
		panel.Visibility = .Gone;
		panel.ShowHeader = false;
	}

	/// Takes a panel out. OWNERSHIP transfers to the caller; null when it was not in this group.
	public DockablePanel RemovePanel(DockablePanel panel)
	{
		let index = IndexOfPanel(panel);
		if (index < 0)
			return null;

		mPanels.RemoveAt(index);
		// AddRef'd across the removal, since the child list holds the only reference.
		panel.AddRef();
		RemoveView(panel);
		// Its header comes BACK: outside a group it has to name and carry itself again.
		panel.ShowHeader = true;

		RepairSelectionAfterRemoval(index);
		return panel;
	}

	/// Keeps the selection pointing at a real tab, and as near as possible to the one that left.
	private void RepairSelectionAfterRemoval(int32 removedIndex)
	{
		if (mSelectedIndex >= mPanels.Count)
		{
			SetSelectedIndex((int32)mPanels.Count - 1);
			return;
		}

		if ((removedIndex <= mSelectedIndex) && (mSelectedIndex > 0))
		{
			SetSelectedIndex(mSelectedIndex - 1);
			return;
		}

		Invalidate();
	}

	private int32 IndexOfPanel(DockablePanel panel)
	{
		for (int32 i = 0; i < mPanels.Count; i++)
		{
			if (mPanels[i] == panel)
				return i;
		}
		return -1;
	}

	/// Drops panels that have gone away behind the group's back.
	///
	/// DEFENCE IN DEPTH: a panel queued for deletion, or reparented elsewhere, is no longer this
	/// group's to draw, and measuring one mid teardown is how a stale pointer gets dereferenced.
	private void PurgeDeletedPanels()
	{
		var changed = false;
		for (int i = mPanels.Count - 1; i >= 0; i--)
		{
			if (!mPanels[i].IsPendingDeletion && (mPanels[i].Parent == this))
				continue;

			mPanels.RemoveAt(i);
			changed = true;
		}

		if (changed && (mSelectedIndex >= mPanels.Count))
			mSelectedIndex = (int32)mPanels.Count - 1;
	}

	// ---- Layout ---------------------------------------------------------------------------------

	protected override void OnMeasure(BoxConstraints constraints)
	{
		PurgeDeletedPanels();

		let width = constraints.ConstrainWidth(150);
		let height = constraints.ConstrainHeight(100);

		// ONLY the selected panel is measured. The others are Gone and cost nothing, which is
		// what makes a group of twenty tabs as cheap as one.
		if (let panel = SelectedPanel)
		{
			if (panel.Visibility != .Gone)
				panel.Measure(BoxConstraints.Tight(width, Max(0.0f, height - mTabHeight)));
		}

		MeasuredSize = .(width, height);
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		PurgeDeletedPanels();

		let contentHeight = Max(0.0f, height - mTabHeight);
		for (int32 i = 0; i < mPanels.Count; i++)
		{
			let panel = mPanels[i];
			if (i != mSelectedIndex)
			{
				panel.Visibility = .Gone;
				continue;
			}

			panel.Visibility = .Visible;
			panel.Measure(BoxConstraints.Tight(width, contentHeight));
			panel.Layout(0, mTabHeight, width, contentHeight);
		}
	}
}
