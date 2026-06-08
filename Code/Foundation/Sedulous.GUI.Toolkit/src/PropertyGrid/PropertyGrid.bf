namespace Sedulous.GUI.Toolkit;

using System;
using System.Collections;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

/// Property inspector grid. Displays a list of PropertyEditors grouped
/// by category into Expanders. Each property shown as a label + editor row.
public class PropertyGrid : ViewGroup
{
	private ScrollView mScrollView;
	private FlexLayout mContent;
	private List<PropertyEditor> mEditors = new .() ~ {
		for (let e in _) delete e;
		delete _;
	};
	private bool mNeedsRebuild = true;

	/// Ratio of label width to total width (0.1 - 0.9).
	public float LabelWidthRatio = 0.4f;

	/// Height of each property row.
	public float RowHeight = 26;

	/// Vertical spacing between property rows.
	public float RowSpacing = 6;

	public this()
	{
		mScrollView = new ScrollView();
		mScrollView.VScrollBarPolicy.Value = .Auto;
		mScrollView.HScrollBarPolicy.Value = .Never;
		mScrollView.ScrollBarMode.Value = .Reserved;
		AddView(mScrollView);

		mContent = new FlexLayout();
		mContent.Direction = .Vertical;
		mScrollView.AddView(mContent, new LayoutParams() { Width = .Match });
	}

	/// Add a property editor.
	public void AddProperty(PropertyEditor editor)
	{
		mEditors.Add(editor);
		mNeedsRebuild = true;
		Invalidate();
	}

	/// Remove a property by name.
	public void RemoveProperty(StringView name)
	{
		for (int i = 0; i < mEditors.Count; i++)
		{
			if (mEditors[i].Name == name)
			{
				delete mEditors[i];
				mEditors.RemoveAt(i);
				mNeedsRebuild = true;
				Invalidate();
				return;
			}
		}
	}

	/// Get a property editor by name.
	public PropertyEditor GetProperty(StringView name)
	{
		for (let e in mEditors)
			if (e.Name == name) return e;
		return null;
	}

	/// Remove all properties.
	public void Clear()
	{
		for (let e in mEditors) delete e;
		mEditors.Clear();
		mNeedsRebuild = true;
		Invalidate();
	}

	/// Number of properties.
	public int PropertyCount => mEditors.Count;

	/// Read-only view over the editors currently in the grid. Callers commonly
	/// iterate this after a `DescribeProperties` pass to subscribe to each
	/// editor's `OnEditEnd` / `OnValueChanged` (e.g. for page dirty tracking).
	public Span<PropertyEditor> Properties => .(mEditors.Ptr, mEditors.Count);

	// === Layout ===

	protected override void OnMeasure(BoxConstraints constraints)
	{
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

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		let bgDrawable = ResolveStyleDrawable(.Background);
		if (bgDrawable != null)
			bgDrawable.Draw(ctx, .(0, 0, Width, Height));
		else
		{
			let bgColor = ResolveStyleColor(.Background, .(42, 44, 54, 255));
			ctx.VG.FillRect(.(0, 0, Width, Height), bgColor);
		}
		DrawChildren(ctx);
	}

	// === Rebuild ===

	private void RebuildLayout()
	{
		mNeedsRebuild = false;
		mContent.Spacing = RowSpacing;

		// Clear existing content.
		while (mContent.ChildCount > 0)
			mContent.RemoveView(mContent.GetChildAt(0), true);

		// Group by category.
		let uncategorized = scope List<PropertyEditor>();
		let categories = scope Dictionary<String, List<PropertyEditor>>();
		let categoryOrder = scope List<String>();

		for (let editor in mEditors)
		{
			if (editor.Category.IsEmpty)
			{
				uncategorized.Add(editor);
			}
			else
			{
				let catKey = scope String(editor.Category);
				if (!categories.ContainsKey(catKey))
				{
					let key = new String(editor.Category);
					categories[key] = new List<PropertyEditor>();
					categoryOrder.Add(key);
				}
				let catKeyLookup = scope String(editor.Category);
				categories[catKeyLookup].Add(editor);
			}
		}

		// Add uncategorized first.
		for (let editor in uncategorized)
			AddEditorRow(editor, false);

		// Add categorized in Expanders.
		for (let catName in categoryOrder)
		{
			let expander = new Expander();
			expander.SetHeaderText(catName);

			let catContent = new FlexLayout();
			catContent.Direction = .Vertical;
			catContent.Spacing = RowSpacing;

			if (categories.TryGetValue(catName, let editors))
			{
				for (let editor in editors)
					AddEditorRowTo(catContent, editor, false);
			}

			expander.SetContent(catContent, new FlexLayout.LayoutParams() { Width = .Match });
			mContent.AddView(expander, new FlexLayout.LayoutParams() { Width = .Match });
		}

		// Cleanup temp lists.
		for (let kv in categories)
		{
			delete kv.key;
			delete kv.value;
		}
	}

	private void AddEditorRow(PropertyEditor editor, bool alt)
	{
		AddEditorRowTo(mContent, editor, alt);
	}

	private void AddEditorRowTo(FlexLayout container, PropertyEditor editor, bool alt)
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;

		// Label - editable if editor has OnLabelRenamed set.
		if (editor.OnLabelRenamed != null)
		{
			let editableLabel = new EditableLabel();
			editableLabel.SetText(editor.DisplayName);
			editableLabel.FontSize.Value = 12;
			let renameDelegate = editor.OnLabelRenamed;
			editableLabel.OnRenameCommitted.Add(new (el, newName) => {
				renameDelegate(newName);
			});
			row.AddView(editableLabel, new FlexLayout.LayoutParams() {
				Grow = LabelWidthRatio
			});
		}
		else
		{
			let label = new Label();
			label.SetText(editor.DisplayName);
			label.FontSize.Value = 12;
			label.VAlign.Value = .Middle;
			row.AddView(label, new FlexLayout.LayoutParams() {
				Grow = LabelWidthRatio
			});
		}

		// Editor view.
		let editorView = editor.EditorView;
		if (editorView != null)
		{
			row.AddView(editorView, new FlexLayout.LayoutParams() {
				Grow = 1.0f - LabelWidthRatio
			});
		}

		container.AddView(row, new FlexLayout.LayoutParams() {
			Width = .Match
		});
	}
}
