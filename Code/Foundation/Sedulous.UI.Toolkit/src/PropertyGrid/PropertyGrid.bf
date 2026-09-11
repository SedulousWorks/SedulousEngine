using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// The inspector: a scrolling list of [[PropertyEditor]] rows, grouped by category into
/// expanders.
///
/// The row tree is REBUILT rather than patched when the set of properties changes, because an
/// inspector's shape changes wholesale, when the selection changes, rather than one row at a
/// time. Two things survive a rebuild deliberately: each editor keeps its own control, so state
/// inside a half typed field is not thrown away, and each category keeps whether the user had
/// it open.
class PropertyGrid : ViewGroup
{
	/// The label column's share of the width, the rest going to the editor.
	public float LabelWidthRatio = 0.4f;
	public float RowHeight = 26.0f;
	public float RowSpacing = 6.0f;

	/// BORROWED: the child tree owns the scroll view, and the scroll view owns the content.
	private ScrollView mScrollView = null;
	private FlexLayout mContent = null;

	/// OWNED.
	private List<PropertyEditor> mEditors = new .() ~ DeleteContainerAndItems!(_);

	/// Parallel: a category name and the widgets pinned to the right of its header. The views
	/// are OWNED, because they outlive the expanders that show them.
	private List<String> mActionCategories = new .() ~ DeleteContainerAndItems!(_);
	private List<View> mActionViews = new .() ~ ReleaseViews!(_);

	/// Categories whose expanders build closed the FIRST time they are seen.
	private List<String> mCollapsedCategories = new .() ~ DeleteContainerAndItems!(_);

	/// Parallel: what the user had open, remembered across rebuilds and keyed by header text.
	private List<String> mExpansionNames = new .() ~ DeleteContainerAndItems!(_);
	private List<bool> mExpansionStates = new .() ~ delete _;

	private bool mNeedsRebuild = true;

	public this()
	{
		mScrollView = new ScrollView();
		mScrollView.VScrollBarPolicy.Value = .Auto;
		mScrollView.HScrollBarPolicy.Value = .Never;
		// RESERVED rather than overlaid: a scroll bar drawn over the rightmost numeric field
		// would sit on the digits.
		mScrollView.ScrollBarMode.Value = .Reserved;
		AddView(mScrollView);

		mContent = new FlexLayout();
		mContent.Direction = .Vertical;

		LayoutStyle contentStyle = .();
		contentStyle.Width = SizeSpec.Match();
		mScrollView.AddView(mContent, contentStyle);
	}

	private static mixin ReleaseViews(var views)
	{
		for (let view in views)
		{
			if (view != null)
				view.ReleaseRef();
		}
		delete views;
	}

	/// Appends a property. CONSUMES the editor.
	public void AddProperty(PropertyEditor editor)
	{
		mEditors.Add(editor);
		mNeedsRebuild = true;
		Invalidate();
	}

	/// Widgets pinned to the right of a category's header, a component's copy and remove icons
	/// being the usual case. CONSUMES the view; null clears.
	///
	/// Registered against the CATEGORY rather than an expander, because the expanders are torn
	/// down and rebuilt and these are not.
	public void SetCategoryHeaderActions(StringView category, View actions)
	{
		for (int i < mActionCategories.Count)
		{
			if (StringView(mActionCategories[i]) != category)
				continue;

			if (mActionViews[i] != null)
				mActionViews[i].ReleaseRef();
			mActionViews[i] = actions;
			mNeedsRebuild = true;
			Invalidate();
			return;
		}

		mActionCategories.Add(new String(category));
		mActionViews.Add(actions);
		mNeedsRebuild = true;
		Invalidate();
	}

	/// Builds a category's expander CLOSED, which costs it no layout and no draw until it is
	/// opened. For bulk sections nobody reads: a generic asset form's per element groups ran to
	/// well over a thousand rows, all measured on every damaged frame.
	///
	/// Only applies the first time a category is seen; what the user did wins after that.
	public void SetCategoryDefaultCollapsed(StringView category)
	{
		for (let existing in mCollapsedCategories)
		{
			if (StringView(existing) == category)
				return;
		}

		mCollapsedCategories.Add(new String(category));
		mNeedsRebuild = true;
		Invalidate();
	}

	public void RemoveProperty(StringView name)
	{
		for (int i < mEditors.Count)
		{
			if (mEditors[i].Name != name)
				continue;

			delete mEditors[i];
			mEditors.RemoveAt(i);
			mNeedsRebuild = true;
			Invalidate();
			return;
		}
	}

	/// BORROWED: the grid owns its editors.
	public PropertyEditor GetProperty(StringView name)
	{
		for (let editor in mEditors)
		{
			if (editor.Name == name)
				return editor;
		}
		return null;
	}

	public void Clear()
	{
		ClearAndDeleteItems!(mEditors);
		ClearAndDeleteItems!(mActionCategories);

		for (let view in mActionViews)
		{
			if (view != null)
				view.ReleaseRef();
		}
		mActionViews.Clear();

		ClearAndDeleteItems!(mCollapsedCategories);
		mNeedsRebuild = true;
		Invalidate();
	}

	public int PropertyCount => mEditors.Count;

	/// BORROWED, for iterating to subscribe to each editor's events.
	public PropertyEditor PropertyAt(int index) => mEditors[index];

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = Rectangle(0, 0, Width, Height);

		if (let background = ResolveStyleDrawable(.Background))
			background.Draw(ctx, bounds);
		else
			ctx.VG.FillRect(bounds, ResolveStyleColor(.Background, Color.Rgb(42, 44, 54)));

		DrawChildren(ctx);
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		// Rebuilt HERE rather than when a property is added, so adding fifty properties costs
		// one rebuild rather than fifty.
		if (mNeedsRebuild)
			RebuildLayout();

		mScrollView.Measure(constraints);
		MeasuredSize = .(constraints.ConstrainWidth(mScrollView.MeasuredSize.X),
			constraints.ConstrainHeight(mScrollView.MeasuredSize.Y));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		mScrollView.Layout(0, 0, width, height);
	}

	// ---- Rebuilding -----------------------------------------------------------------------------

	private void RebuildLayout()
	{
		mNeedsRebuild = false;
		mContent.Spacing = RowSpacing;

		// Remembered BEFORE the expanders are torn down. A rebuild, from an undo or a shape
		// change, must not slam shut a group the user opened, nor reopen one they closed. What
		// is remembered beats the default collapsed list, which applies only to a category
		// being seen for the first time.
		for (int i < mContent.ChildCount)
		{
			if (let expander = mContent.GetChildAt(i) as Expander)
				RememberExpansion(expander.HeaderText, expander.IsExpanded);
		}

		while (mContent.ChildCount > 0)
			mContent.RemoveView(mContent.GetChildAt(0));

		// Grouped by category in FIRST SEEN order, so the inspector's order is the order the
		// properties were registered in rather than an alphabetical one nobody chose.
		let uncategorized = scope List<PropertyEditor>();
		let categoryOrder = scope List<String>();
		let categoryLists = scope List<List<PropertyEditor>>();
		defer
		{
			for (let list in categoryLists)
				delete list;
		}

		for (let editor in mEditors)
		{
			let category = editor.Category;
			if (category.IsEmpty)
			{
				uncategorized.Add(editor);
				continue;
			}

			var categoryIndex = -1;
			for (int c < categoryOrder.Count)
			{
				if (StringView(categoryOrder[c]) == category)
				{
					categoryIndex = c;
					break;
				}
			}

			if (categoryIndex < 0)
			{
				categoryIndex = categoryOrder.Count;
				categoryOrder.Add(scope:: String(category));
				categoryLists.Add(new List<PropertyEditor>());
			}

			categoryLists[categoryIndex].Add(editor);
		}

		// Uncategorized first: those are the object's own identity, above everything grouped.
		for (let editor in uncategorized)
			AddEditorRowTo(mContent, editor);

		for (int c < categoryOrder.Count)
			AddCategory(categoryOrder[c], categoryLists[c]);
	}

	private void AddCategory(String category, List<PropertyEditor> editors)
	{
		let expander = new Expander();
		expander.SetHeaderText(category);

		for (int a < mActionCategories.Count)
		{
			if ((StringView(mActionCategories[a]) != StringView(category))
				|| (mActionViews[a] == null))
				continue;

			// The grid keeps the actions across rebuilds, and SetHeaderActions consumes a
			// reference, so it is handed one of its own.
			mActionViews[a].AddRef();
			expander.SetHeaderActions(mActionViews[a]);
			break;
		}

		let categoryContent = new FlexLayout();
		categoryContent.Direction = .Vertical;
		categoryContent.Spacing = RowSpacing;

		for (let editor in editors)
			AddEditorRowTo(categoryContent, editor);

		LayoutStyle contentStyle = .();
		contentStyle.Width = SizeSpec.Match();
		expander.SetContent(categoryContent, contentStyle);

		var remembered = false;
		for (int k < mExpansionNames.Count)
		{
			if (StringView(mExpansionNames[k]) != StringView(category))
				continue;

			expander.SetIsExpanded(mExpansionStates[k]);
			remembered = true;
			break;
		}

		if (!remembered)
		{
			for (let collapsed in mCollapsedCategories)
			{
				if (StringView(collapsed) != StringView(category))
					continue;

				expander.SetIsExpanded(false);
				break;
			}
		}

		LayoutStyle expanderStyle = .();
		expanderStyle.Width = SizeSpec.Match();
		mContent.AddView(expander, expanderStyle);
	}

	private void AddEditorRowTo(FlexLayout container, PropertyEditor editor)
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 6.0f;

		AddLabelTo(row, editor);

		// The editor OWNS its control, so the row is handed a reference of its own and the
		// control survives this row being torn down on the next rebuild.
		if (let editorView = editor.EditorView)
		{
			LayoutStyle editorStyle = .();
			editorStyle.FlexGrow = 1.0f - LabelWidthRatio;
			editorView.AddRef();
			row.AddView(editorView, editorStyle);
		}

		if (!editor.Tooltip.IsEmpty)
			row.TooltipText.Set(editor.Tooltip);

		editor.SetRowView(row);

		LayoutStyle rowStyle = .();
		rowStyle.Width = SizeSpec.Match();
		container.AddView(row, rowStyle);
	}

	/// An editable label when the editor accepts renames, a plain one otherwise. Both ELLIPSIZE
	/// rather than overflow, so a long property name is cut off instead of running into the
	/// value beside it.
	private void AddLabelTo(FlexLayout row, PropertyEditor editor)
	{
		LayoutStyle labelStyle = .();
		labelStyle.FlexGrow = LabelWidthRatio;

		if (editor.OnLabelRenamed != null)
		{
			let label = new EditableLabel();
			label.SetText(editor.DisplayName);
			label.FontSize.Value = 12.0f;
			label.Ellipsis.Value = true;
			label.OnRenameCommitted.Add(new (sender, newName) =>
				{
					if (editor.OnLabelRenamed != null)
						editor.OnLabelRenamed(newName);
				});
			editor.BindDisplayNameSink(new (text) => { label.SetText(text); });
			row.AddView(label, labelStyle);
			return;
		}

		let label = new Label();
		label.SetText(editor.DisplayName);
		label.FontSize.Value = 12.0f;
		label.VAlign.Value = .Middle;
		label.Ellipsis.Value = true;
		editor.BindDisplayNameSink(new (text) => { label.SetText(text); });
		row.AddView(label, labelStyle);
	}

	private void RememberExpansion(StringView category, bool expanded)
	{
		for (int i < mExpansionNames.Count)
		{
			if (StringView(mExpansionNames[i]) != category)
				continue;

			mExpansionStates[i] = expanded;
			return;
		}

		mExpansionNames.Add(new String(category));
		mExpansionStates.Add(expanded);
	}
}
