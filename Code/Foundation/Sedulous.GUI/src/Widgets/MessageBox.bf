using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// MessageBox: a modal dialog with a message and a row of buttons: standard ones (OK / OK-Cancel /
// Yes-No) or verbs of the caller's own ("Delete", "Create"). Modeled on eepp's UIMessageBox (role
// only) - a Window subclass whose content is a word-wrapped message plus bottom-right buttons.
// Pressing a button calls the result callback and closes the dialog. Shown via Window.OpenModal,
// a modal popup: what is behind it is inert and its backdrop dims it.
//
// Each button has a role, as Qt's button roles and GTK's responses do, and a class of the same
// name for the sheet: `primary` (the default: focused when it opens, so Return or a pad's South
// picks it), `cancel` (what `back`, Escape or a pad's East, and its close button pick) and
// `destructive` (it destroys something: styled so, and never focused on its own, so Return alone
// cannot destroy). With no primary, the last button that destroys nothing has the focus; with no
// cancel, `back` picks the first. Its message wraps and its height fits it; it is not resizable
// unless asked.

/// What a dialog's button does, beyond its answer: the sheet styles each by a class of its name.
enum DialogRole : uint8
{
	case Normal;
	/// The default: focused when the dialog opens.
	case Primary;
	/// What `back` (Escape) and the close button answer.
	case Cancel;
	/// Destroys something: never the default on its own.
	case Destructive;

	/// Its class name: "primary", "cancel", "destructive" or "normal".
	public StringView Name
	{
		get
		{
			switch (this)
			{
			case .Primary: return "primary";
			case .Cancel: return "cancel";
			case .Destructive: return "destructive";
			default: return "normal";
			}
		}
	}

	/// The role of that name; Normal for any other.
	public static DialogRole Named(StringView name)
	{
		if (name == "primary")
			return .Primary;
		if (name == "cancel")
			return .Cancel;
		if (name == "destructive")
			return .Destructive;
		return .Normal;
	}
}

[GuiReflect(true)]
class MessageBox : Window
{
	public enum Buttons
	{
		Ok,
		OkCancel,
		YesNo,
	}

	public enum Result
	{
		Ok,
		Cancel,
		Yes,
		No,
	}

	private const float cPad = 16.0f;
	private const float cGap = 14.0f;
	private const float cWidth = 380.0f;
	private const float cButtonWidth = 84.0f;
	private const float cButtonHeight = 30.0f;
	private const float cButtonGap = 10.0f;

	private Label mMessage = null ~ _?.ReleaseRef();
	private Panel mButtonRow = null ~ _?.ReleaseRef();
	// A reference each.
	private List<Button> mButtons = new .() ~ { for (let b in _) b.ReleaseRef(); delete _; };
	// Each button's result name, in order.
	private List<String> mResults = new .() ~ DeleteContainerAndItems!(_);
	// And its role.
	private List<DialogRole> mRoles = new .() ~ delete _;
	private delegate void(Result result) mOnResult ~ delete _;
	private String mResultName = new .() ~ delete _;
	// The page it was shown from, while it is open (a reference held).
	private Node mHome = null ~ _?.ReleaseRef();
	private int mHomeIndex = 0;

	public this()
	{
		Tag = "messagebox";
		AccessRoleName = "dialog"; // what a screen reader takes it for

		// The content flows: the message (wrapping) above a row of buttons at the right.
		let content = (UIWidget)Content;
		using (StyleWriteScope(content))
		{
			content.EditLayoutStyle(scope (st) =>
				{
					st.Direction = .Column;
					st.AlignItems = .Stretch;
					st.RowGap = cGap;
				});
			content.Padding = .(cPad);
		}
		mMessage = new Label();
		mMessage.AddClass("dialogmessage"); // white-space inherits under a sheet: the theme wraps it, keeping its lines
		using (StyleWriteScope(mMessage)) // its own values, which a sheet returns to
		{
			mMessage.WhiteSpace = .PreWrap; // a message wraps, and keeps the lines it is written in (a list)
			mMessage.SetTextAlignment(.Start, .Top);
			mMessage.EditLayoutStyle(scope (st) => { st.Grow = 1.0f; });
		}
		content.AddChild(mMessage);
		mButtonRow = new Panel();
		mButtonRow.Tag = "dialogbuttons";
		using (StyleWriteScope(mButtonRow))
		{
			mButtonRow.EditLayoutStyle(scope (st) =>
				{
					st.Direction = .Row;
					st.JustifyContent = .End;
					st.ColumnGap = cButtonGap;
					st.Shrink = 0.0f;
				});
		}
		content.AddChild(mButtonRow);

		using (StyleWriteScope(this)) // its own values, which a sheet returns to
		{
			Resizable = false;
			Size = .(cWidth, 180.0f);
			LayoutContent();
		}
		// Open, the default button takes focus (else the cancel one: never a destructive one alone).
		AddEventListener(.Toggle, new (e) =>
			{
				if ((e.Target != this) || !((ToggleEvent)e).Open)
					return;
				let focus = DefaultButton;
				if (focus != null)
					focus.RequestFocus();
				else
				{
					let cancel = ButtonAt(CancelIndex);
					if (cancel != null)
						cancel.RequestFocus();
				}
			});
	}

	/// Sets the title, message, and which buttons to show.
	public void Configure(StringView title, StringView message, Buttons buttons)
	{
		Title = title;
		mMessage.Text = message;
		BuildButtons(buttons);
		LayoutContent();
	}

	/// OWNERSHIP of `callback` transfers.
	public void SetOnResult(delegate void(Result result) callback)
	{
		delete mOnResult;
		mOnResult = callback;
	}

	/// Adds a button of its own after the standard ones: `text` its label (a verb: "Delete"),
	/// `resultName` what ResultName reads (and the change event reports) when it is pressed, `role`
	/// what else it does (the default, the cancel, a destructive one). Borrowed: the box keeps it.
	public Button AddButton(StringView text, StringView resultName, DialogRole role = .Normal)
	{
		let button = MakeButton(resultName, role);
		button.Text = text;
		LayoutContent();
		return button;
	}

	/// Its buttons, none: for a dialog of the caller's own verbs (AddButton).
	public void ClearButtons()
	{
		for (let b in mButtons)
		{
			b.RemoveFromParent();
			b.ReleaseRef();
		}
		mButtons.Clear();
		ClearAndDeleteItems!(mResults);
		mRoles.Clear();
		LayoutContent();
	}

	public DialogRole GetButtonRole(int index) => ((index >= 0) && (index < mRoles.Count)) ? mRoles[index] : .Normal;

	/// The button focused when it opens: the primary one, else the last that destroys nothing.
	/// Null with none (only destructive buttons).
	public Button DefaultButton
	{
		get
		{
			for (int i = 0; i < mRoles.Count; i++)
			{
				if (mRoles[i] == .Primary)
					return mButtons[i];
			}
			for (int i = mRoles.Count - 1; i >= 0; i--)
			{
				if (mRoles[i] != .Destructive)
					return mButtons[i];
			}
			return null;
		}
	}

	public void SetMessageColor(Color color)
	{
		mMessage.TextColor = color;
	}

	// === Markup ===
	// `<MessageBox id="confirm" title="Delete?" text="..." buttons="ok-cancel"/>` waits in its
	// page, unseen, until shown (Show); answered, it goes back there, its
	// `result` the answer, reported as `change`. `buttons` is ok, ok-cancel or yes-no, or the
	// caller's own verbs, each `Text:result:role` and separated by `|`
	// (`buttons="Cancel:cancel:cancel|Delete:delete:destructive"`); a missing result is the text
	// in lower case, a missing role normal.
	public override bool SetMarkupAttribute(StringView name, StringView value)
	{
		if (name == "text")
		{
			mMessage.Text = value;
			LayoutContent();
			return true;
		}
		if (name == "buttons")
		{
			let v = ParseUtil.Trim(value);
			if ((v == "ok-cancel") || (v == "yes-no") || (v == "ok") || v.IsEmpty)
				BuildButtons((v == "ok-cancel") ? .OkCancel : (v == "yes-no") ? .YesNo : .Ok);
			else
				BuildVerbs(v);
			LayoutContent();
			if (!IsOpen)
				Displayed = false; // written in a page: unseen until shown
			return true;
		}
		return base.SetMarkupAttribute(name, value);
	}

	/// Opens it, modal, in the GUI it is in (it comes back to where it was); false when it is in
	/// none (a box shows over a tree: one with no parent has nothing to show over).
	public bool Show()
	{
		if (IsOpen)
			return true;
		let root = RootNode;
		if ((root == null) || (root == this))
			return false;
		// Shown again while its exit plays, its page is still the one it came from.
		let home = Parent;
		if ((home != null) && (mHome == null))
		{
			home.AddRef();
			mHome = home;
			mHomeIndex = home.GetChildIndex(this);
		}
		Displayed = true;
		OpenModal(root);
		return true;
	}

	/// The last answer: "ok", "cancel", "yes" or "no" (empty: none yet).
	[GuiProperty]
	public StringView ResultName
	{
		get => mResultName;
	}

	public StringView Message => mMessage.Text;
	public int ButtonCount => mButtons.Count;

	public Button ButtonAt(int index) => (index < mButtons.Count) ? mButtons[index] : null;

	// Its close button and `back` (Escape, a pad's East) pick the cancel button's result: the one
	// whose role is cancel (Cancel, No), else the first.
	public override bool AnswersBack => true;

	public override void RequestClose()
	{
		if (mResults.IsEmpty)
			Close();
		else
			Finish(mResults[CancelIndex]);
	}

	// Its title (the window's), message and buttons take its font.
	protected override void OnTextStyleChange()
	{
		base.OnTextStyleChange();
		if ((mMessage == null) || (mButtons == null))
			return; // may run mid-construction
		ShareTextStyle(mMessage, false);
		for (let b in mButtons)
			ShareTextStyle(b, false);
		LayoutContent(); // the font sizes the message
	}

	// The button `back` answers with: the cancel one, else the first.
	private int CancelIndex
	{
		get
		{
			for (int i = 0; i < mRoles.Count; i++)
			{
				if (mRoles[i] == .Cancel)
					return i;
			}
			return 0;
		}
	}

	private void BuildButtons(Buttons buttons)
	{
		ClearButtons();

		switch (buttons)
		{
		case .Ok:
			AddStandard(.Ok);
		case .OkCancel:
			AddStandard(.Cancel);
			AddStandard(.Ok); // primary rightmost
		case .YesNo:
			AddStandard(.No);
			AddStandard(.Yes); // primary rightmost
		}
	}

	// The caller's verbs from markup: `Text:result:role|...`.
	private void BuildVerbs(StringView list)
	{
		ClearButtons();
		for (let entry in list.Split('|'))
		{
			StringView[3] fields = .();
			int field = 0;
			for (let part in entry.Split(':'))
			{
				if (field == 3)
					break;
				fields[field++] = ParseUtil.Trim(part);
			}
			if (fields[0].IsEmpty)
				continue;
			let result = scope String(fields[1]);
			if (result.IsEmpty)
			{
				result.Set(fields[0]);
				result.ToLower();
			}
			AddButton(fields[0], result, DialogRole.Named(fields[2]));
		}
	}

	// A standard button: its label translated (gui.ok, ...) where the GUI's tables have it, else
	// English. OK and Yes are the default; Cancel and No what `back` picks.
	private void AddStandard(Result result)
	{
		let i = (int)result;
		let button = MakeButton(MessageBoxDetail.sNames[i], MessageBoxDetail.sRoles[i]);
		button.Text = MessageBoxDetail.sEnglish[i];
		button.BindTranslation("text", MessageBoxDetail.sKeys[i], null, null, Span<Node.TranslationArgument>(), MessageBoxDetail.sEnglish[i]);
	}

	private Button MakeButton(StringView resultName, DialogRole role)
	{
		let button = new Button();
		ShareTextStyle(button, false);
		button.AddClass("dialogbutton");
		if (role != .Normal)
			button.AddClass(role.Name);
		let name = new String(resultName);
		mResults.Add(name);
		mRoles.Add(role);
		button.SetOnClick(new () => { Finish(name); });
		using (StyleWriteScope(button))
		{
			button.EditLayoutStyle(scope (st) =>
				{
					st.MinWidth = LayoutLength.Px(cButtonWidth);
					st.Height = LayoutLength.Px(cButtonHeight);
				});
		}
		mButtonRow.AddChild(button);
		mButtons.Add(button); // the list keeps the reference it was made with
		return button;
	}

	private void Finish(StringView resultName)
	{
		mResultName.Set(resultName);
		for (int i = 0; i < 4; ++i) // a standard one also answers as its Result
		{
			if ((MessageBoxDetail.sNames[i] == resultName) && (mOnResult != null))
				mOnResult((Result)i);
		}
		// Closing lets the popup layer's reference go, which may be the last one: kept alive
		// until its answer has been told.
		AddRef();
		defer ReleaseRef();
		Close();
		SendEvent(scope Event(.Changed, this));
	}

	// Refused as it opened (an unattended run): its cancel's answer, as if it was pressed.
	protected override void OnModalRefused()
	{
		if (mResults.IsEmpty)
		{
			base.OnModalRefused();
			return;
		}
		mResultName.Set(mResults[CancelIndex]);
		for (int i = 0; i < 4; ++i) // a standard one also answers as its Result
		{
			if ((MessageBoxDetail.sNames[i] == mResultName) && (mOnResult != null))
				mOnResult((Result)i);
		}
		SendEvent(scope Event(.Changed, this));
	}

	// Shown from a page: back there, unseen, once its exit has played.
	protected override void OnWindowGone()
	{
		if (mHome == null)
			return;
		let home = mHome;
		mHome = null; // the reference moves to `home`
		AddRef();
		Displayed = false;
		if (Parent != home)
			home.AddChildAt(this, Math.Min(mHomeIndex, home.ChildCount));
		ReleaseRef();
		home.ReleaseRef();
	}

	// Its height fits its message, wrapped at its width, and its buttons (the flow places them).
	private void LayoutContent()
	{
		if ((mMessage == null) || (mButtonRow == null))
			return; // may run mid-construction
		let inner = Math.Max(0.0f, Size.X - 2.0f * cPad);
		let text = mMessage.Measure(LayoutConstraints(.(inner, 0.0f), .(inner, cUnbounded), .(inner, -1.0f), true, false)).Y;
		let height = TitleBarHeight + cPad + text + cGap + cButtonHeight + cPad;
		if (Math.Abs(height - Size.Y) > 0.5f)
		{
			using (StyleWriteScope(this))
			{
				Size = .(Size.X, height);
			}
		}
	}
}

/// What MessageBox.bf keeps out of the public surface: the standard buttons' names and labels,
/// by MessageBox.Result.
internal static class MessageBoxDetail
{
	public static String[4] sNames = .("ok", "cancel", "yes", "no");
	public static String[4] sEnglish = .("OK", "Cancel", "Yes", "No");
	public static String[4] sKeys = .("gui.ok", "gui.cancel", "gui.yes", "gui.no");
	public static DialogRole[4] sRoles = .(.Primary, .Cancel, .Primary, .Cancel);
}
