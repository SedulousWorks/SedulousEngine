using System;
using Sedulous.Core;

namespace Sedulous.GUI;

// EditableLabel: a label that becomes a field in place, a layer's name or a file's in a list. A
// double-click, or F2 while it is focused, edits it: a text field over its text, all of it
// selected. Return commits, as does focus leaving; Escape cancels. A multiline one (a comment)
// edits in a text area, where Return breaks a line and Ctrl+Return commits, its box growing and
// shrinking with the lines typed. Its field's context menu (cut, copy, paste) keeps it editing. A
// validator may refuse what was typed: Return then keeps it editing (the field marked
// `.invalid`), and focus leaving puts the old text back. A committed change reports `change`.

[GuiReflect(true)]
class EditableLabel : Label
{
	// The field it edits in (its child); a reference held.
	private TextEditBase mEditor = null ~ _?.ReleaseRef();
	private bool mEditing = false;
	private bool mMultiline = false;
	private delegate bool(StringView text) mValidator ~ delete _;
	private delegate void(StringView text) mOnCommitted ~ delete _;

	public this()
	{
		Tag = "editablelabel";
		TabFocusable = true;
	}

	/// Whether it edits in a text area (Return breaks a line, Ctrl+Return commits) rather than a
	/// field; its text keeps its line breaks and wraps (white-space: pre-wrap, unless a sheet says),
	/// read from its top, where the text area puts it: a box shorter than its text cuts its end. Set
	/// while it is not editing.
	public bool IsMultiline
	{
		get => mMultiline;
		set
		{
			if ((value == mMultiline) || mEditing)
				return;
			mMultiline = value;
			using (StyleWriteScope(this))
			{
				WhiteSpace = value ? TextWhiteSpace.PreWrap : TextWhiteSpace.Normal;
				SetTextAlignment(TextAlignH, value ? TextVAlign.Top : TextVAlign.Middle);
			}
			if (mEditor != null)
			{
				RemoveChild(mEditor);
				mEditor.ReleaseRef();
				mEditor = null;
			}
		}
	}

	/// Starts editing (as a double-click or F2 does).
	public void BeginEdit()
	{
		if (mEditing || !IsTreeEnabled)
			return;
		EnsureEditor();
		mEditing = true;
		mEditor.Text = Text;
		mEditor.RemoveClass("invalid");
		mEditor.Displayed = true;
		mEditor.Model.SelectAll();
		mEditor.RequestFocus();
		RequestLayout();
		Invalidate();
	}

	/// Ends editing: commits what was typed (if the validator takes it) or puts it back. False when
	/// the validator refused and it is still editing.
	public bool EndEdit(bool commit)
	{
		if (!mEditing)
			return true;
		let typed = scope String(mEditor.Text);
		if (commit && (mValidator != null) && !mValidator(typed))
		{
			mEditor.AddClass("invalid");
			return false;
		}
		mEditing = false;
		let hadFocus = mEditor.IsFocused;
		mEditor.Displayed = false;
		if (hadFocus)
			RequestFocus(); // the label keeps the focus the field had
		RequestLayout(); // its box is its own text's again
		if (commit && (typed != Text))
		{
			Text = typed;
			if (mOnCommitted != null)
				mOnCommitted(typed);
			SendEvent(scope Event(.Changed, this));
		}
		Invalidate();
		return true;
	}

	public bool IsEditing => mEditing;
	/// The field it edits in, a text area when multiline (null until it first edits).
	public TextEditBase Editor => mEditor;

	/// Decides whether typed text may be committed (false: it stays editing). OWNERSHIP of
	/// `validator` transfers.
	public void SetValidator(delegate bool(StringView text) validator)
	{
		delete mValidator;
		mValidator = validator;
	}

	/// A change the user committed. OWNERSHIP of `callback` transfers.
	public void SetOnTextCommitted(delegate void(StringView text) callback)
	{
		delete mOnCommitted;
		mOnCommitted = callback;
	}

	protected override void OnMouseDown(MouseEvent e)
	{
		if ((e.Button == .Left) && (e.ClickCount == 2) && (e.Target == this))
		{
			BeginEdit();
			e.Handled = true;
		}
	}

	protected override void OnKeyDown(KeyEvent e)
	{
		let key = (KeyCode)e.KeyCode;
		if ((e.Target == this) && (key == .F2) && (e.Modifiers == 0))
		{
			BeginEdit();
			e.Handled = true;
		}
		else if (mEditing && (e.Target == mEditor) && (key == .Escape))
		{
			EndEdit(false);
			e.Handled = true;
		}
	}

	// While it edits, the field draws the text; the label draws its box alone.
	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		if (!mEditing)
			base.OnDraw(ctx, localBounds);
	}

	// Its field writes in its font and colour.
	protected override void OnTextStyleChange()
	{
		base.OnTextStyleChange();
		if (mEditor != null)
			ShareTextStyle(mEditor);
	}

	// While a text area edits it, its box is the typed text's, so it grows with the lines.
	public override Float2 MeasureContent(Float2 available)
	{
		if (mEditing && mMultiline)
			return ((TextArea)mEditor).MeasureText(available.X);
		return base.MeasureContent(available);
	}

	// The field's text lies where the label's was: its content box on the label's, its padding and
	// border reaching past the label's box. Over the whole box alone, a field's padding would leave
	// a label one line tall no room to show what is typed.
	public override void OnLayout()
	{
		if (mEditor == null)
			return;
		let content = ContentBounds;
		let chrome = mEditor.Chrome;
		mEditor.Arrange(.(content.X - chrome.Left, content.Y - chrome.Top, content.Width + chrome.TotalHorizontal,
			content.Height + chrome.TotalVertical));
	}

	private void EnsureEditor()
	{
		if (mEditor != null)
			return;
		if (mMultiline)
		{
			let area = new TextArea();
			area.SetOnTextChanging(new (text) => { RequestLayout(); });
			mEditor = area;
		}
		else
		{
			mEditor = new TextField();
		}
		mEditor.AddClass("editor");
		ShareTextStyle(mEditor);
		mEditor.SetOnSubmit(new (text) => { EndEdit(true); });
		mEditor.AddEventListener(.FocusLost, new (e) =>
			{
				// Focus went elsewhere: committed if it may be, else put back. Not to the field's own
				// context menu, which gives it back when it closes (a cut of what was selected).
				let menu = mEditor.ContextMenu;
				if ((menu != null) && menu.IsOpen)
					return;
				if (mEditing && !EndEdit(true))
					EndEdit(false);
			});
		AddChild(mEditor);
	}
}
