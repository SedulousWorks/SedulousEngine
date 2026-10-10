using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.Editor.App;

/// A settings dialog's tabs, one per category: the column a category's fields go in, made the
/// first time the category is named, so fields naming the same category share its tab and the
/// tabs follow the order the categories first appear. Each column is padded and sits in its own
/// vertical scroll, so a long page scrolls inside the dialog without spilling over its buttons.
/// Preferences and Project Settings both build on it, so the two read alike.
class CategoryTabs
{
	/// A category's tab and the column its fields go in (the tab view owns the views).
	private class Page
	{
		public String Category = new .() ~ delete _;
		public FlexLayout Column;
	}

	/// Created here and handed to the dialog's content by View, which consumes this reference.
	private TabView mTabs;
	private List<Page> mPages = new .() ~ DeleteContainerAndItems!(_);

	public this()
	{
		mTabs = new TabView();
		mTabs.TabsClosable.Value = false;
	}

	/// The tab view, for the dialog's content (SetContent takes the reference this made).
	/// Borrowed once it is set.
	public TabView View => mTabs;

	/// The column of `category`'s tab, made (as the last tab) the first time it is named.
	public FlexLayout Column(StringView category)
	{
		for (let page in mPages)
		{
			if (page.Category == category)
				return page.Column;
		}
		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 8;
		column.Padding = .(12, 10);
		let scroll = new ScrollView();
		scroll.VScrollBarPolicy.Value = .Auto;
		scroll.HScrollBarPolicy.Value = .Never;
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		scroll.AddView(column, match);
		mTabs.AddTab(category, scroll);
		let page = new Page();
		page.Category.Set(category);
		page.Column = column;
		mPages.Add(page);
		return column;
	}

	/// The tab of `category`, or -1.
	public int32 IndexOf(StringView category)
	{
		for (int i < mPages.Count)
		{
			if (mPages[i].Category == category)
				return (int32)i;
		}
		return -1;
	}

	/// A quiet line of explanation in a page.
	public static void AddNote(FlexLayout column, StringView text)
	{
		let note = new Label(text);
		note.FontSize.Value = 11.0f;
		note.WordWrap.Value = true;
		note.TextColor.Value = Color(0.55f, 0.55f, 0.55f, 1.0f);
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		column.AddView(note, match);
	}
}
