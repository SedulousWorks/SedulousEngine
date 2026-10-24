using System;
using Sedulous.Core;

namespace Sedulous.GUI;

// The code editor's find, replace and go-to-line bar, of the core's widgets (foundation.ui's editor
// drew its own and took its keys before the editor did): a field for what to find, toggles for
// matching case and whole words, how many matches and which, the previous and next, a close;
// replacing, a second field and Replace and Replace all; going to a line, one field (`line` or
// `line:column`). Return finds the next (Shift+Return the previous), replaces, or goes; Escape
// closes it, the focus back in the editor. The editor does the searching.

[GuiReflect]
class CodeFindBar : UIWidget
{
	public enum Mode : uint8
	{
		Find,
		Replace,
		GoToLine,
	}

	private Mode mMode = .Find;
	private bool mShiftHeld = false;
	// Its rows, fields, buttons and count: its children, a reference of its own held to each.
	private UIWidget mFindRow ~ _?.ReleaseRef();
	private UIWidget mReplaceRow ~ _?.ReleaseRef();
	private UIWidget mLineRow ~ _?.ReleaseRef();
	private TextField mQuery ~ _?.ReleaseRef();
	private TextField mReplacement ~ _?.ReleaseRef();
	private TextField mLine ~ _?.ReleaseRef();
	private Button mCase ~ _?.ReleaseRef();
	private Button mWord ~ _?.ReleaseRef();
	private Button mPrevious ~ _?.ReleaseRef();
	private Button mNext ~ _?.ReleaseRef();
	private Button mClose ~ _?.ReleaseRef();
	private Button mReplaceOne ~ _?.ReleaseRef();
	private Button mReplaceAll ~ _?.ReleaseRef();
	private Label mCount ~ _?.ReleaseRef();
	private delegate void() mOnChanged ~ delete _;
	private delegate void(bool backwards) mOnNext ~ delete _;
	private delegate void(bool all) mOnReplace ~ delete _;
	private delegate void(StringView text) mOnGoTo ~ delete _;
	private delegate void() mOnClose ~ delete _;

	public this()
	{
		Tag = "codefindbar";
		using (StyleWriteScope(this))
		{
			EditLayoutStyle(scope (s) =>
				{
					s.Placement = .Absolute; // over the editor, which places it
					s.Direction = .Column;
					s.RowGap = 4.0f;
				});
			Padding = .(6.0f, 4.0f, 6.0f, 4.0f);
		}
		mFindRow = Row();
		mQuery = Field(mFindRow, "query", "Find", 180.0f);
		mQuery.SetOnTextChanging(new (text) => { Changed(); });
		mCase = Toggle(mFindRow, "case", "Aa", "Match case");
		mWord = Toggle(mFindRow, "word", "W", "Whole word");
		mCount = new Label();
		mCount.AddClass("count");
		mFindRow.AddChild(mCount);
		mPrevious = Action(mFindRow, "previous", "Prev", "Previous match (Shift+F3)", new () => { Next(true); });
		mNext = Action(mFindRow, "next", "Next", "Next match (F3)", new () => { Next(false); });
		mClose = Action(mFindRow, "close", "\u{00D7}", "Close (Escape)", new () => { Close(); });
		mReplaceRow = Row();
		mReplacement = Field(mReplaceRow, "replacement", "Replace", 180.0f);
		mReplaceOne = Action(mReplaceRow, "replace", "Replace", "Replace this match", new () => { Replace(false); });
		mReplaceAll = Action(mReplaceRow, "replace-all", "All", "Replace every match", new () => { Replace(true); });
		mLineRow = Row();
		mLine = Field(mLineRow, "line", "Line, or line:column", 180.0f);
		Action(mLineRow, "close", "\u{00D7}", "Close (Escape)", new () => { Close(); }).ReleaseRef(); // the row keeps it
		mQuery.SetOnSubmit(new (text) => { Next(mShiftHeld); });
		mReplacement.SetOnSubmit(new (text) => { Replace(false); });
		mLine.SetOnSubmit(new (text) =>
			{
				if (mOnGoTo != null)
					mOnGoTo(text);
			});
		// Return with Shift finds the previous; Escape closes, from any of its fields.
		AddEventListener(.KeyDown, new (e) =>
			{
				let key = (KeyEvent)e;
				mShiftHeld = (key.Modifiers & KeyModShift) != 0;
				if (((KeyCode)key.KeyCode == .Escape) && (key.Modifiers == 0))
				{
					Close();
					e.Handled = true;
				}
			}, true);
		Show(.Find, default);
		Displayed = false;
	}

	/// Shows it in `mode`, its field holding `text` (all selected) and focused.
	public void Show(Mode mode, StringView text)
	{
		mMode = mode;
		Displayed = true;
		mFindRow.Displayed = mode != .GoToLine;
		mReplaceRow.Displayed = mode == .Replace;
		mLineRow.Displayed = mode == .GoToLine;
		let field = (mode == .GoToLine) ? mLine : mQuery;
		if ((text.Length != 0) || (mode == .GoToLine))
			field.Text = text;
		field.Model.SelectAll();
		field.RequestFocus();
		Changed();
	}

	public new void Close()
	{
		if (!Displayed)
			return;
		Displayed = false;
		if (mOnClose != null)
			mOnClose();
	}

	public Mode GetMode() => mMode;
	public StringView Query => mQuery.Text;
	public StringView Replacement => mReplacement.Text;
	public bool MatchCase => mCase.Checked;
	public bool WholeWord => mWord.Checked;

	/// Shows which match is current (from 1; 0: none) of how many.
	public void SetCount(int current, int total)
	{
		if (mQuery.Text.Length == 0)
			mCount.Text = default;
		else if (total == 0)
			mCount.Text = "No results";
		else
			mCount.Text = scope String()..AppendF("{} of {}", current, total);
	}

	public TextField QueryField => mQuery;
	public TextField ReplacementField => mReplacement;
	public TextField LineField => mLine;
	public Button CaseToggle => mCase;
	public Button WordToggle => mWord;
	public Label CountLabel => mCount;

	// The editor's: what it does for each. OWNERSHIP of each callback transfers.
	public void SetOnChanged(delegate void() callback)
	{
		delete mOnChanged;
		mOnChanged = callback;
	}

	public void SetOnNext(delegate void(bool backwards) callback)
	{
		delete mOnNext;
		mOnNext = callback;
	}

	public void SetOnReplace(delegate void(bool all) callback)
	{
		delete mOnReplace;
		mOnReplace = callback;
	}

	public void SetOnGoTo(delegate void(StringView text) callback)
	{
		delete mOnGoTo;
		mOnGoTo = callback;
	}

	public void SetOnClose(delegate void() callback)
	{
		delete mOnClose;
		mOnClose = callback;
	}

	// A row of it, its last child; the caller holds a reference.
	private UIWidget Row()
	{
		let row = new UIWidget();
		row.AddClass("row");
		row.EditLayoutStyle(scope (s) =>
			{
				s.Direction = .Row;
				s.AlignItems = .Center;
				s.ColumnGap = 4.0f;
			});
		AddChild(row);
		return row;
	}

	private TextField Field(UIWidget row, StringView cls, StringView placeholder, float width)
	{
		let field = new TextField();
		field.AddClass(cls);
		field.Placeholder = placeholder;
		field.EditLayoutStyle(scope (s) => { s.Width = LayoutLength.Px(width); });
		row.AddChild(field);
		return field;
	}

	private Button Toggle(UIWidget row, StringView cls, StringView text, StringView tip)
	{
		let button = new Button();
		button.AddClass(cls);
		button.Text = text;
		button.Tooltip = tip;
		button.IsToggle = true;
		button.SetOnToggled(new (on) => { Changed(); });
		row.AddChild(button);
		return button;
	}

	// OWNERSHIP of `click` transfers.
	private Button Action(UIWidget row, StringView cls, StringView text, StringView tip, delegate void() click)
	{
		let button = new Button();
		button.AddClass(cls);
		button.Text = text;
		button.Tooltip = tip;
		button.SetOnClick(click);
		row.AddChild(button);
		return button;
	}

	private void Changed()
	{
		if (mOnChanged != null)
			mOnChanged();
	}

	private void Next(bool backwards)
	{
		if (mOnNext != null)
			mOnNext(backwards);
	}

	private void Replace(bool all)
	{
		if (mOnReplace != null)
			mOnReplace(all);
	}
}
