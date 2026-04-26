namespace Sedulous.UI.Toolkit;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Property inspector grid. Displays a list of PropertyEditors grouped
/// by category into Expanders. Each property shown as a label + editor row.
public class PropertyGrid : ViewGroup
{
	private ScrollView mScrollView;
	private LinearLayout mContent;
	private List<PropertyEditor> mEditors = new .() ~ {
		for (let e in _) delete e;
		delete _;
	};
	private bool mNeedsRebuild = true;

	/// Ratio of label width to total width (0.1 - 0.9).
	public float LabelWidthRatio = 0.4f;

	/// Height of each property row.
	public float RowHeight = 26;

	public this()
	{
		mScrollView = new ScrollView();
		mScrollView.VScrollPolicy = .Auto;
		mScrollView.HScrollPolicy = .Never;
		mScrollView.BarMode = .Reserved;
		AddView(mScrollView);

		mContent = new LinearLayout();
		mContent.Orientation = .Vertical;
		mContent.Spacing = 1;
		mScrollView.AddView(mContent, new LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent });
	}

	/// Add a property editor.
	public void AddProperty(PropertyEditor editor)
	{
		mEditors.Add(editor);
		mNeedsRebuild = true;
		InvalidateLayout();
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
				InvalidateLayout();
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
		InvalidateLayout();
	}

	/// Number of properties.
	public int PropertyCount => mEditors.Count;

	// === Layout ===

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		if (mNeedsRebuild)
			RebuildLayout();

		mScrollView.Measure(wSpec, hSpec);
		MeasuredSize = .(wSpec.Resolve(mScrollView.MeasuredSize.X),
						 hSpec.Resolve(mScrollView.MeasuredSize.Y));
	}

	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		mScrollView.Layout(0, 0, right - left, bottom - top);
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		if (!ctx.TryDrawDrawable("PropertyGrid.Background", .(0, 0, Width, Height), .Normal))
		{
			let bgColor = ctx.Theme?.GetColor("PropertyGrid.Background") ?? ctx.Theme?.Palette.Surface ?? .(42, 44, 54, 255);
			ctx.VG.FillRect(.(0, 0, Width, Height), bgColor);
		}
		DrawChildren(ctx);
	}

	// === Rebuild ===

	private void RebuildLayout()
	{
		mNeedsRebuild = false;

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

			let catContent = new LinearLayout();
			catContent.Orientation = .Vertical;
			catContent.Spacing = 1;

			if (categories.TryGetValue(catName, let editors))
			{
				for (let editor in editors)
					AddEditorRowTo(catContent, editor, false);
			}

			expander.SetContent(catContent, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent });
			mContent.AddView(expander, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent });
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

	private void AddEditorRowTo(LinearLayout container, PropertyEditor editor, bool alt)
	{
		let row = new LinearLayout();
		row.Orientation = .Horizontal;

		// Label.
		let label = new Label();
		label.SetText(editor.Name);
		label.FontSize = 12;
		label.VAlign = .Middle;
		row.AddView(label, new LinearLayout.LayoutParams() {
			Width = Sedulous.UI.LayoutParams.MatchParent,
			Height = Sedulous.UI.LayoutParams.MatchParent,
			Weight = LabelWidthRatio
		});

		// Editor view.
		let editorView = editor.EditorView;
		if (editorView != null)
		{
			row.AddView(editorView, new LinearLayout.LayoutParams() {
				Width = Sedulous.UI.LayoutParams.MatchParent,
				Height = Sedulous.UI.LayoutParams.MatchParent,
				Weight = 1.0f - LabelWidthRatio
			});
		}

		container.AddView(row, new LinearLayout.LayoutParams() {
			Width = Sedulous.UI.LayoutParams.MatchParent,
			Height = Sedulous.UI.LayoutParams.WrapContent
		});
	}
}
