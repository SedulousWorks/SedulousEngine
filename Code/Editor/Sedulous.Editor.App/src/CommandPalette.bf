using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

// CommandPalette: every action by name. Its frame is
// markup (Data/Editor/CommandPalette.xml: the kit's picker, a search field over a list and a hint),
// its rows the registry's declarations filtered by what is typed (case folded): labels that start
// with it first, then labels that hold it, then a description or id that does. A row shows the
// action's label, its menu path and its chord; one disabled over the active page is dimmed and
// refuses with a line in the hint. Up and Down move along the rows, Enter or a click runs the lit
// one through the registry and closes the palette, Escape, its close button or a press outside
// closes it. It opens as a modal popup near the top of the window, the field focused.

/// One action's row: its label, where it is in the menus, its chord. The pointer over it lights
/// it; a click runs it.
class CommandPaletteRow : UIWidget
{
	/// The palette that holds it.
	private CommandPalette mPalette;
	private int32 mIndex;
	private Sedulous.GUI.Label mLabel ~ _.ReleaseRef();
	private Sedulous.GUI.Label mWhere ~ _.ReleaseRef();
	private Sedulous.GUI.Label mChord ~ _.ReleaseRef();

	public this(CommandPalette palette, int32 index)
	{
		mPalette = palette;
		mIndex = index;
		AddClass("palette-row");
		mLabel = new Sedulous.GUI.Label();
		mLabel.AddClass("row-name");
		mWhere = new Sedulous.GUI.Label();
		mWhere.AddClass("palette-where");
		mChord = new Sedulous.GUI.Label();
		mChord.AddClass("key");
		Sedulous.GUI.Label[3] parts = .(mLabel, mWhere, mChord);
		for (let part in parts)
		{
			part.HitTestVisible = false; // the row takes the pointer, not its parts
			AddChild(part);
		}
	}

	/// Its place among the rows shown.
	public int32 Index => mIndex;
	public Sedulous.GUI.Label LabelPart => mLabel;
	public Sedulous.GUI.Label WherePart => mWhere;
	public Sedulous.GUI.Label ChordPart => mChord;

	public void Show(StringView label, StringView menuPath, StringView chord, bool enabled)
	{
		mLabel.Text = label;
		mWhere.Text = menuPath;
		mChord.Text = chord;
		mChord.Displayed = !chord.IsEmpty;
		if (enabled)
			RemoveClass("disabled");
		else
			AddClass("disabled");
	}

	protected override void OnMouseEnter(MouseEvent e)
	{
		mPalette.Light(mIndex);
	}

	protected override void OnMouseClick(MouseEvent e)
	{
		if (e.Button != .Left)
			return;
		e.Handled = true;
		mPalette.Run(mIndex).IgnoreError();
	}
}

class CommandPalette
{
	/// Its frame's markup, under the data root.
	public const String cMarkupPath = "Editor/CommandPalette.xml";
	/// How far down the window it opens, as a share of its height.
	private const float cTopShare = 0.12f;

	/// BORROWED: the editor context's, outliving this.
	private EditorActionRegistry mActions;
	/// A reference of ours: closed, it leaves the tree, and this keeps it for the next open.
	private Node mContent ~ _?.ReleaseRef();
	// The frame's: the tree holds them.
	private TextField mSearch = null;
	private Node mList = null;
	private Sedulous.GUI.Label mHint = null;
	/// What the hint says while it has nothing else to say: the markup's.
	private String mIdleHint = new .() ~ delete _;
	/// BORROWED: what it opened over, last.
	private SceneRoot mRoot = null;
	/// The actions shown now, in their order. The registry's.
	private List<EditorActionDeclaration> mShown = new .() ~ delete _;
	/// A row per action shown, each a reference of ours (the list holds its own).
	private List<CommandPaletteRow> mRows = new .() ~ { for (let row in _) row.ReleaseRef(); delete _; };
	private int32 mLit = -1;

	/// The palette over `actions`, its frame `content` (the markup's: `palette-search`,
	/// `palette-list`, `palette-hint` and `palette-close` by id). TAKES OWNERSHIP of a reference to `content`; null
	/// makes a palette that never opens.
	public this(EditorActionRegistry actions, Node content)
	{
		mActions = actions;
		mContent = content;
		if (mContent == null)
			return;
		mSearch = mContent.FindElement("palette-search") as TextField;
		mList = mContent.FindElement("palette-list");
		mHint = mContent.FindElement("palette-hint") as Sedulous.GUI.Label;
		if (mHint != null)
			mIdleHint.Set(mHint.Text);
		if (mSearch != null)
			mSearch.SetOnTextChanging(new (text) => { Filter(text); });
		if (let close = CloseButton)
			close.SetOnClick(new () => { Close(); });
		// Up, Down and Enter before the search field takes them.
		mContent.AddEventListener(.KeyDown, new (e) =>
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
					RunLit().IgnoreError();
					e.Handled = true;
				}
			}, true);
	}

	public ~this()
	{
		Close();
	}

	/// Opens it over `root`, near its top, the query empty and the field focused; false with no
	/// frame, a root in no GUI, or when it is open already.
	public bool Open(SceneRoot root)
	{
		let dispatcher = root.EventDispatcher;
		if ((mContent == null) || (dispatcher == null) || IsOpen)
			return false;
		mRoot = root;
		if (mSearch != null)
			mSearch.Text = default;
		Filter(default);
		let options = new PopupOptions();
		options.Kind = .Auto; // Escape and a press outside close it
		options.Modal = true;
		options.TakesFocus = true;
		options.FitContent = true;
		options.HasAnchorRect = true;
		options.AnchorRect = Rect(0.0f, 0.0f, root.Size.X, root.Size.Y * cTopShare);
		options.Placement.Side = .Below;
		options.Placement.Align = .Center;
		dispatcher.OpenPopup(root, mContent, options);
		if (mSearch != null)
			dispatcher.FocusNode = mSearch;
		return true;
	}

	public void Close()
	{
		if (IsOpen)
			mRoot.EventDispatcher.ClosePopup(mContent);
	}

	public bool IsOpen => (mRoot != null) && (mContent != null) && (mRoot.EventDispatcher != null) && mRoot.EventDispatcher.IsPopupOpen(mContent);

	/// Filters for `text`, as typing it in the field does.
	public void SetQuery(StringView text)
	{
		if (mSearch != null)
			mSearch.Text = text;
		Filter(text);
	}

	/// The actions shown now, in their order. The registry's.
	public List<EditorActionDeclaration> Shown => mShown;
	/// The lit row (Enter's); -1 with none shown.
	public int32 Lit => mLit;
	/// The rows shown, in their order. The palette's.
	public List<CommandPaletteRow> Rows => mRows;
	/// The close button at the search's end. The markup's.
	public Sedulous.GUI.Button CloseButton => (mContent != null) ? mContent.FindElement("palette-close") as Sedulous.GUI.Button : null;

	public void Light(int32 index)
	{
		mLit = mShown.IsEmpty ? -1 : Math.Clamp(index, 0, (int32)mShown.Count - 1);
		for (let row in mRows)
		{
			if (row.Index == mLit)
			{
				row.AddClass("current");
				if (mList != null)
					mList.ScrollIntoView(row);
			}
			else
				row.RemoveClass("current");
		}
	}

	/// Moves the lit row by `by`, clamped at the ends.
	public void Step(int32 by) => Light(mLit + by);

	/// Runs the lit action: the palette closes first (an action may open a dialog of its own).
	/// One disabled over the active page stays, its refusal in the hint; with none lit, nothing.
	public Result<void, ErrorCode> RunLit() => Run(mLit);

	public Result<void, ErrorCode> Run(int32 index)
	{
		if ((index < 0) || (index >= mShown.Count))
			return .Err(.NotFound);
		let action = mShown[index];
		if (!mActions.IsEnabled(action.Id))
		{
			SetHint(scope $"{action.Label} is not available now.");
			return .Err(.NotSupported); // the registry's refusal of a disabled action
		}
		let id = scope String(action.Id); // the registry may change as it runs
		Close();
		return mActions.Execute(id);
	}

	/// What the hint says. The label's.
	public StringView Hint => (mHint != null) ? mHint.Text : "";

	private void Filter(StringView query)
	{
		mShown.Clear();
		let holds = scope List<EditorActionDeclaration>();
		let elsewhere = scope List<EditorActionDeclaration>();
		for (let action in mActions.Actions)
		{
			if (action.Label.Contains(query, true))
			{
				if (query.IsEmpty || action.Label.StartsWith(query, .OrdinalIgnoreCase))
					mShown.Add(action); // a label that starts with it
				else
					holds.Add(action);
			}
			else if (action.Description.Contains(query, true) || action.Id.Contains(query, true))
				elsewhere.Add(action);
		}
		mShown.AddRange(holds);
		mShown.AddRange(elsewhere);
		ShowRows();
		if (mShown.IsEmpty)
			SetHint(scope $"Nothing matches {query}.");
		else
			SetHint(mIdleHint);
		Light(0);
	}

	private void ShowRows()
	{
		if (mList == null)
			return;
		while (mRows.Count < mShown.Count)
		{
			let row = new CommandPaletteRow(this, (int32)mRows.Count);
			mRows.Add(row);
			mList.AddChild(row);
		}
		while (mRows.Count > mShown.Count)
		{
			let last = mRows.PopBack();
			mList.RemoveChild(last);
			last.ReleaseRef();
		}
		for (int i < mShown.Count)
		{
			let action = mShown[i];
			let chord = mActions.Shortcut(action.Id).ToString(.. scope .());
			mRows[i].Show(action.Label, action.MenuPath, chord, mActions.IsEnabled(action.Id));
		}
	}

	private void SetHint(StringView text)
	{
		if (mHint != null)
			mHint.Text = text;
	}
}
