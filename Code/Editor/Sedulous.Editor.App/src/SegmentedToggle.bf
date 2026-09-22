using System;
using System.Collections;
using Sedulous.UI;

namespace Sedulous.Editor.App;

/// A row of toggle buttons where exactly one reads as chosen: each press reports its
/// index and the row re-pulls the current choice, so a choice made elsewhere (a hotkey)
/// shows on the next refresh.
class SegmentedToggle : FlexLayout
{
	/// Owned.
	private delegate void(int32 index) mOnSelect = null ~ delete _;
	private delegate int32() mCurrent = null ~ delete _;

	public this()
	{
		Direction = .Horizontal;
		Spacing = 3.0f;
	}

	/// CONSUMES every delegate. `contentFor` yields the button content, a reference the
	/// button takes; `tooltipFor` may be null.
	public void Build(int32 count, delegate View(int32 index) contentFor, delegate void(int32 index) onSelect,
		delegate int32() current, delegate void(int32 index, String outTooltip) tooltipFor = null)
	{
		defer { delete contentFor; delete tooltipFor; }
		delete mOnSelect;
		mOnSelect = onSelect;
		delete mCurrent;
		mCurrent = current;
		for (int32 i < count)
		{
			let button = new ToggleButton();
			button.SetContent(contentFor(i));
			if (tooltipFor != null)
				tooltipFor(i, button.TooltipText);
			let index = i;
			button.OnCheckedChanged.Add(new [=this, =index](tb, isChecked) => { Choose(index); });
			AddView(button);
		}
		Refresh();
	}

	public void Choose(int32 index)
	{
		if (mOnSelect != null)
			mOnSelect(index);
		Refresh();
	}

	/// Re-pulls the current choice into the buttons, silently.
	public void Refresh()
	{
		let selected = (mCurrent != null) ? mCurrent() : -1;
		for (int k < ChildCount)
		{
			if (let tb = GetChildAt(k) as ToggleButton)
			{
				tb.IsChecked.SetSilent((int32)k == selected);
				tb.Invalidate();
			}
		}
	}
}
