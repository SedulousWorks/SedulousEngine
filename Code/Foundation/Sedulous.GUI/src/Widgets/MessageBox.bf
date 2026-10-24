using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// MessageBox: a modal dialog with a message and a row of standard buttons (OK / OK-Cancel /
// Yes-No). Modeled on eepp's UIMessageBox (role only) - a Window subclass whose content is a
// word-wrapped message plus bottom-right buttons. Pressing a button calls the result callback
// and closes the dialog. Shown via Window.OpenModal, a modal popup: what is behind it is inert
// and its backdrop dims it. Its default button (the rightmost, OK or Yes) has focus when it
// opens, so Return or a pad's South picks it; `back` (Escape, a pad's East) picks the cancel one
// (Cancel, No, or OK when it is the only one), as its close button does. Its message wraps and
// its height fits it; it is not resizable unless asked.

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
		mMessage.AddClass("dialogmessage"); // white-space inherits under a sheet: the theme wraps it
		using (StyleWriteScope(mMessage)) // its own values, which a sheet returns to
		{
			mMessage.WhiteSpace = .Normal; // a message wraps
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
		// Open, the default button takes focus.
		AddEventListener(.Toggle, new (e) =>
			{
				if ((e.Target == this) && ((ToggleEvent)e).Open && !mButtons.IsEmpty)
					mButtons.Back.RequestFocus();
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

	/// Adds a button of its own after the standard ones: `text` its label, `resultName` what
	/// ResultName reads (and the change event reports) when it is pressed.
	public void AddButton(StringView text, StringView resultName)
	{
		let button = MakeButton(resultName);
		button.Text = text;
		LayoutContent();
	}

	public void SetMessageColor(Color color)
	{
		mMessage.TextColor = color;
	}

	// === Markup ===
	// `<MessageBox id="confirm" title="Delete?" text="..." buttons="ok-cancel"/>` waits in its
	// page, unseen, until shown (Show, a script's show()); answered, it goes back there, its
	// `result` the answer, reported as `change`.
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
			BuildButtons((v == "ok-cancel") ? .OkCancel : (v == "yes-no") ? .YesNo : .Ok);
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
		let home = Parent;
		if (home != null)
		{
			home.AddRef();
			if (mHome != null)
				mHome.ReleaseRef();
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

	// Its close button and `back` (Escape, a pad's East) pick the cancel button's result: the
	// leftmost, Cancel or No, or the only one.
	public override bool AnswersBack => true;

	public override void RequestClose()
	{
		if (mResults.IsEmpty)
			Close();
		else
			Finish(mResults[0]);
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

	private void BuildButtons(Buttons buttons)
	{
		for (let b in mButtons)
		{
			b.RemoveFromParent();
			b.ReleaseRef();
		}
		mButtons.Clear();
		ClearAndDeleteItems!(mResults);

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

	// A standard button, its label in English.
	private void AddStandard(Result result)
	{
		let i = (int)result;
		let button = MakeButton(MessageBoxDetail.sNames[i]);
		button.Text = MessageBoxDetail.sEnglish[i];
	}

	private Button MakeButton(StringView resultName)
	{
		let button = new Button();
		ShareTextStyle(button, false);
		button.AddClass("dialogbutton");
		let name = new String(resultName);
		mResults.Add(name);
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
		Close();
		SendEvent(scope Event(.Changed, this));
	}

	// Shown from a page: back there, unseen.
	protected override void OnWindowClosed()
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
}
