using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// The collapsible strip along the bottom of an editor: a tab bar that is ALWAYS visible, with
/// a content region above it that appears only while a tab is expanded.
///
/// Clicking the active tab collapses back to just the bar; clicking another switches to it and
/// expands. The same gesture both selects and toggles, which is what makes a one tab dock feel
/// like a single show and hide button.
///
/// The dock does NOT resize itself. It reports the change through OnExpandedChanged, and the
/// host, which usually places the dock as one pane of a [[SplitView]], collapses that pane. The
/// split keeps its ratio, so expanding again gives the user back the height they chose.
///
/// A tab's content is BORROWED, so the same view can live elsewhere in the tree or outlive the
/// dock.
class BottomDock : FlexLayout
{
	private const float BarHeight = 26.0f;

	private struct Tab
	{
		/// OWNED.
		public String Id = null;
		/// OWNED.
		public String Label = null;
		/// BORROWED: the caller owns it.
		public View Content = null;
		/// BORROWED: the tab bar owns it.
		public Button Button = null;

		public this() {}
	}

	/// Fired when the expanded state changes. The host wires this to its split view.
	public Event<delegate void(bool)> OnExpandedChanged ~ _.Dispose();

	/// BORROWED: the child list owns both.
	private FlexLayout mContentHost = null;
	private FlexLayout mTabBar = null;

	private List<Tab> mTabs = new .() ~ ReleaseTabs!(_);
	private int32 mActiveIndex = -1;
	private bool mExpanded = false;

	public this()
	{
		BuildChrome();
	}

	private static mixin ReleaseTabs(var tabs)
	{
		for (let tab in tabs)
		{
			delete tab.Id;
			delete tab.Label;
		}
		delete tabs;
	}

	public bool IsExpanded => mExpanded;

	public int TabCount => mTabs.Count;

	public StringView ActiveTabId =>
		((mActiveIndex >= 0) && (mActiveIndex < mTabs.Count))
			? StringView(mTabs[mActiveIndex].Id) : default;

	/// Registers a tab. The content is BORROWED and starts hidden; only the active tab's
	/// content is shown, and only while expanded.
	public void AddTab(StringView id, StringView label, View content)
	{
		let button = new Button(label);
		button.FontSize.Value = 11.0f;

		let index = (int32)mTabs.Count;
		button.OnClick.Add(new (sender) => { OnTabClicked(index); });

		LayoutStyle buttonStyle = .();
		buttonStyle.Width = SizeSpec.Fixed(Unit.Dp(96.0f));
		buttonStyle.Height = SizeSpec.Match();
		mTabBar.AddView(button, buttonStyle);

		if (content != null)
		{
			content.Visibility = .Gone;

			LayoutStyle contentStyle = .();
			contentStyle.Width = SizeSpec.Match();
			contentStyle.FlexGrow = 1.0f;
			// BORROWED, so the dock takes a reference of its own and the caller keeps theirs.
			content.AddRef();
			mContentHost.AddView(content, contentStyle);
		}

		Tab tab = .();
		tab.Id = new String(id);
		tab.Label = new String(label);
		tab.Content = content;
		tab.Button = button;
		mTabs.Add(tab);
	}

	/// Drives a tab's toggle by id, exactly as clicking its button would. Unknown ids are a
	/// no op.
	public void ClickTab(StringView id)
	{
		let index = IndexOf(id);
		if (index >= 0)
			OnTabClicked(index);
	}

	/// Switches to a tab and expands. Unknown ids are a no op.
	public void ActivateTab(StringView id)
	{
		let index = IndexOf(id);
		if (index < 0)
			return;

		mActiveIndex = index;
		SetExpanded(true);
	}

	/// Collapses to just the bar, or expands the active tab, falling back to the first when
	/// nothing is active yet.
	public void SetExpanded(bool expanded)
	{
		if (expanded && (mActiveIndex < 0) && !mTabs.IsEmpty)
			mActiveIndex = 0;

		if (mExpanded == expanded)
		{
			// Still SYNC: ActivateTab can switch the active tab while already expanded, and
			// the old tab's content has to go away even though the state did not change.
			SyncContent();
			return;
		}

		mExpanded = expanded;
		if (mContentHost != null)
			mContentHost.Visibility = expanded ? .Visible : .Gone;

		SyncContent();
		Invalidate();
		OnExpandedChanged(mExpanded);
	}

	// ---- Internals ------------------------------------------------------------------------------

	private void BuildChrome()
	{
		Direction = .Vertical;
		Spacing = 0.0f;

		// The content region is added FIRST so it sits above the bar, which stays pinned to the
		// bottom edge whether or not anything is expanded.
		mContentHost = new FlexLayout();
		mContentHost.Direction = .Vertical;
		mContentHost.Visibility = .Gone;

		LayoutStyle contentStyle = .();
		contentStyle.Width = SizeSpec.Match();
		contentStyle.FlexGrow = 1.0f;
		AddView(mContentHost, contentStyle);

		mTabBar = new FlexLayout();
		mTabBar.Direction = .Horizontal;
		mTabBar.Spacing = 2.0f;
		mTabBar.Padding = .(4, 2);

		LayoutStyle barStyle = .();
		barStyle.Width = SizeSpec.Match();
		barStyle.Height = SizeSpec.Fixed(Unit.Dp(BarHeight));
		AddView(mTabBar, barStyle);
	}

	private int32 IndexOf(StringView id)
	{
		for (int i < mTabs.Count)
		{
			if (StringView(mTabs[i].Id) == id)
				return (int32)i;
		}
		return -1;
	}

	private void OnTabClicked(int32 index)
	{
		if ((index < 0) || (index >= mTabs.Count))
			return;

		if (mExpanded && (mActiveIndex == index))
		{
			SetExpanded(false);
			return;
		}

		mActiveIndex = index;
		SetExpanded(true);
	}

	/// Only the active tab's content is visible, and only while expanded.
	private void SyncContent()
	{
		for (int i < mTabs.Count)
		{
			let content = mTabs[i].Content;
			if (content == null)
				continue;

			content.Visibility = (mExpanded && (i == mActiveIndex)) ? .Visible : .Gone;
		}
	}
}
