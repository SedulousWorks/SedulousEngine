using System;
using Sedulous.UI;

namespace Sedulous.Editor.App;

/// The List and Grid pair over a view of assets (the asset browser, the asset picker): two
/// icon toggles, one checked, with the words as their tooltips. The owner shows the list or the
/// grid; the pair only says which and reports a change.
///
/// A segmented toggle, so a radio pair by the checked state rather than the click: a toggle
/// flips on a click and on Space alike, and pressing the checked one leaves it checked.
class ViewModeToggles : SegmentedToggle
{
	/// Called with the mode a press asked for (true is grid), only when it changes; never by
	/// SetGridMode. Owned.
	public delegate void(bool grid) OnModeChanged ~ delete _;

	private bool mGrid = false;

	public this()
	{
		Spacing = 2.0f;
		Build(2,
			new (index) =>
			{
				// The shared icon, with a reference taken for the view; null before the icons
				// are initialised (tests).
				let icon = (index == 0) ? EditorIcons.ViewList : EditorIcons.ViewGrid;
				if (icon != null)
					icon.AddRef();
				let glyph = new DrawableView(icon, 16.0f, 16.0f);
				glyph.KeepAspect = true;
				return glyph;
			},
			new [=this](index) =>
			{
				let grid = index == 1;
				if (grid == mGrid)
					return;
				mGrid = grid;
				if (OnModeChanged != null)
					OnModeChanged(grid);
			},
			new [=this]() => mGrid ? 1 : 0,
			new (index, outTooltip) => { outTooltip.Set((index == 0) ? "List" : "Grid"); });
		for (int i < ChildCount)
			GetChildAt(i).SetStyle(.Padding, Thickness(4.0f, 3.0f));
	}

	/// Checks the toggle for `grid` and unchecks the other, without calling back.
	public void SetGridMode(bool grid)
	{
		mGrid = grid;
		Refresh();
	}

	public bool GridMode => mGrid;
	public ToggleButton ListToggle => GetChildAt(0) as ToggleButton;
	public ToggleButton GridToggle => GetChildAt(1) as ToggleButton;
}
