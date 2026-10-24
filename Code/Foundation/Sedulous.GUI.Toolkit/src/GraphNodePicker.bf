using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// The node picker of a graph view: the kinds of node a source makes, under their categories, with a
// search over their names. A graph view opens it from its menu over nothing and when a link is
// dropped on nothing (then only the kinds with a pin that fits). Typing filters it; Up and Down move
// along it, Enter or a click chooses.

/// A row of a node picker: a kind of node, or a category's heading.
[GuiReflect]
class GraphPickerRow : UIWidget
{
	// The picker that holds it.
	private GraphNodePicker mPicker;
	private Sedulous.GUI.Label mLabel ~ _.ReleaseRef();
	private int32 mShown = -1;

	public this(GraphNodePicker picker)
	{
		mPicker = picker;
		Tag = "graphpickerrow";
		using (StyleWriteScope(this))
		{
			EditLayoutStyle(scope (s) =>
				{
					s.Direction = .Row;
					s.AlignItems = .Center;
					s.MinHeight = LayoutLength.Px(20.0f);
					s.Shrink = 0.0f;
				});
			Padding = Thickness(12.0f, 1.0f, 8.0f, 1.0f);
		}
		mLabel = new Sedulous.GUI.Label();
		mLabel.HitTestVisible = false;
		AddChild(mLabel);
	}

	public void Show(StringView text, int32 shown)
	{
		mShown = shown;
		mLabel.Text = text;
		if (shown < 0)
			AddClass("category");
		else
			RemoveClass("category");
	}

	/// Its place among the kinds shown; -1 for a heading.
	public int32 Shown => mShown;
	public Sedulous.GUI.Label Label => mLabel;

	protected override void OnMouseEnter(MouseEvent e)
	{
		if (mShown >= 0)
			mPicker.Current = mShown;
	}

	protected override void OnMouseClick(MouseEvent e)
	{
		if ((mShown < 0) || (e.Button != .Left))
			return;
		e.Handled = true;
		mPicker.Choose(mShown);
	}
}

[GuiReflect]
class GraphNodePicker : UIWidget
{
	public const float cWidth = 240.0f;
	public const float cListHeight = 280.0f;

	private TextField mSearch ~ _.ReleaseRef();
	private UIWidget mList ~ _.ReleaseRef();
	private List<GraphPickerRow> mRows = new .() ~ { for (let row in _) row.ReleaseRef(); delete _; };
	private List<GraphNodeType> mTypes = new .() ~ DeleteContainerAndItems!(_);
	// The kinds shown, by their place in mTypes.
	private List<int> mShown = new .() ~ delete _;
	private int32 mCurrent = -1;
	private delegate void(GraphNodeType type) mOnChosen ~ delete _;

	public this()
	{
		Tag = "graphnodepicker";
		using (StyleWriteScope(this))
		{
			Padding = Thickness(6.0f, 6.0f, 6.0f, 6.0f);
			EditLayoutStyle(scope (s) =>
				{
					s.Direction = .Column;
					s.RowGap = 4.0f;
					s.Width = LayoutLength.Px(cWidth);
				});
		}
		mSearch = new TextField();
		mSearch.Placeholder = "Search";
		mSearch.SetOnTextChanging(new (text) => { Filter(text); });
		AddChild(mSearch);
		mList = new UIWidget();
		mList.Tag = "graphpickerlist";
		using (StyleWriteScope(mList))
		{
			mList.EditLayoutStyle(scope (s) =>
				{
					s.Direction = .Column;
					s.MaxHeight = LayoutLength.Px(cListHeight);
					s.OverflowY = .Auto;
				});
		}
		AddChild(mList);
		// Up, Down and Enter before the search field takes them.
		AddEventListener(.KeyDown, new (e) =>
			{
				let key = (KeyEvent)e;
				let code = (KeyCode)key.KeyCode;
				if (key.Modifiers != 0)
					return;
				if ((code == .Down) || (code == .Up))
				{
					Step((code == .Down) ? 1 : -1);
					e.Handled = true;
				}
				else if ((code == .Return) || (code == .KeypadEnter))
				{
					ChooseCurrent();
					e.Handled = true;
				}
			}, true);
	}

	/// The kinds it offers, in the source's order (a category's kinds together under it); copies
	/// kept.
	public void SetTypes(Span<GraphNodeType> types)
	{
		ClearAndDeleteItems!(mTypes);
		for (let type in types)
		{
			let copy = new GraphNodeType();
			copy.Set(type);
			mTypes.Add(copy);
		}
		mSearch.Text = default;
		Filter(default);
	}

	/// Searches for `text`, as typing it in the field does.
	public void SetQuery(StringView text)
	{
		mSearch.Text = text;
		Filter(text);
	}

	/// Told the kind chosen. OWNERSHIP of `callback` transfers.
	public void SetOnChosen(delegate void(GraphNodeType type) callback)
	{
		delete mOnChosen;
		mOnChosen = callback;
	}

	/// The kinds shown now, in their order, and which is current (lit; Enter's).
	public int ShownCount => mShown.Count;
	public GraphNodeType ShownAt(int index) => mTypes[mShown[index]];

	public int32 Current
	{
		get => mCurrent;
		set
		{
			var shown = value;
			if (mShown.IsEmpty)
				shown = -1;
			else
				shown = Math.Clamp(shown, 0, (int32)mShown.Count - 1);
			mCurrent = shown;
			for (let row in mRows)
			{
				if ((row.Shown >= 0) && (row.Shown == shown))
				{
					row.AddClass("current");
					mList.ScrollIntoView(row);
				}
				else
					row.RemoveClass("current");
			}
		}
	}

	public void Step(int32 by)
	{
		Current = mCurrent + by;
	}

	/// Chooses the current kind; false when none is shown.
	public bool ChooseCurrent() => Choose(mCurrent);

	public bool Choose(int32 shown)
	{
		if ((shown < 0) || (shown >= mShown.Count))
			return false;
		let chosen = scope GraphNodeType();
		chosen.Set(mTypes[mShown[shown]]);
		if (mOnChosen != null)
			mOnChosen(chosen);
		return true;
	}

	public TextField SearchField => mSearch;

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		if (!BoxFills)
			ctx.VG.FillRect(localBounds.ToRectangle(), .(0.18f, 0.20f, 0.25f, 1.0f));
		base.OnDraw(ctx, localBounds);
	}

	// Whether `text` holds `part`, ignoring the case of ASCII letters.
	private static bool Holds(StringView text, StringView part)
	{
		char8 Lower(char8 c) => ((c >= 'A') && (c <= 'Z')) ? (char8)((uint8)c - (uint8)'A' + (uint8)'a') : c;
		if (part.Length == 0)
			return true;
		for (int i = 0; i + part.Length <= text.Length; ++i)
		{
			int n = 0;
			while ((n < part.Length) && (Lower(text[i + n]) == Lower(part[n])))
				++n;
			if (n == part.Length)
				return true;
		}
		return false;
	}

	private void Filter(StringView query)
	{
		mShown.Clear();
		int count = 0;
		void Row(StringView text, int32 shown)
		{
			while (mRows.Count <= count)
			{
				let made = new GraphPickerRow(this);
				mRows.Add(made);
				mList.AddChild(made);
			}
			mRows[count++].Show(text, shown);
		}
		if (query.Length == 0)
		{
			// Under their categories, each once, in the order they first come.
			let categories = scope List<StringView>();
			for (let type in mTypes)
			{
				bool seen = false;
				for (let at in categories)
					seen = seen || (at == type.Category);
				if (!seen)
					categories.Add(type.Category);
			}
			for (let category in categories)
			{
				if (!category.IsEmpty)
					Row(category, -1);
				for (int i = 0; i < mTypes.Count; ++i)
				{
					if (mTypes[i].Category == category)
					{
						Row(mTypes[i].Name, (int32)mShown.Count);
						mShown.Add(i);
					}
				}
			}
		}
		else
		{
			for (int i = 0; i < mTypes.Count; ++i)
			{
				if (Holds(mTypes[i].Name, query))
				{
					Row(mTypes[i].Name, (int32)mShown.Count);
					mShown.Add(i);
				}
			}
		}
		while (mRows.Count > count)
		{
			let last = mRows.Back;
			mList.RemoveChild(last);
			mRows.PopBack();
			last.ReleaseRef();
		}
		mCurrent = -2; // shown again below
		Current = 0;
	}
}
