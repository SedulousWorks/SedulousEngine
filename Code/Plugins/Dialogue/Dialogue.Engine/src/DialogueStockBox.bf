using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.GUI.Resources;
using Sedulous.Engine.GUI;

namespace Dialogue;

/// The plugin's own dialogue box, which a project turns on in the plugin's settings (`StockBox`) so
/// a game has dialogue on screen before it builds a box of its own. It is a screen on the run's
/// screen stack that blocks nothing under it: a portrait, the speaker's name, the line typed out at
/// the settings' speed, and a choice's answers as buttons that the pad, the keys and the mouse all
/// reach. The advance action (the settings', Interact by default) or a press on the box first
/// finishes the typing, then advances; a press on an answer chooses it, and the advance action
/// chooses the focused answer. The box goes when the conversation ends. Its look is a sheet over
/// the box alone: the plugin's own, or the project's (`StockBoxSheet`) in its place, so a game
/// restyles it without building its own. The class names the sheets style: dialogue-screen,
/// dialogue-box (portrait-right with `PortraitOnRight`), dialogue-portrait, dialogue-words,
/// dialogue-name, dialogue-text, dialogue-answers and dialogue-answer.
class DialogueStockBox
{
	/// What the player asked for in a frame.
	public struct Request
	{
		public bool Advance = false;
		public int32 Choose = -1;

		public this() {}
	}

	/// The box's markup.
	public const String cMarkup = """
		<Screen class="dialogue-screen" blocks="false" back="none">
		  <Panel id="dialogue-box" class="dialogue-box">
		    <Image id="dialogue-portrait" class="dialogue-portrait"/>
		    <Panel class="dialogue-words">
		      <Label id="dialogue-name" class="dialogue-name" text=""/>
		      <Label id="dialogue-text" class="dialogue-text" text=""/>
		      <Panel id="dialogue-answers" class="dialogue-answers"/>
		    </Panel>
		  </Panel>
		</Screen>
		""";

	/// The plugin's sheet for it.
	public const String cSheet = """
		.dialogue-screen { flex-grow: 1; flex-direction: column; justify-content: end; align-items: center; padding: 24px; }
		.dialogue-box { flex-direction: row; align-items: start; gap: 18px; width: 100%; max-width: 920px; padding: 18px; background-color: rgba(14, 14, 20, 0.9); border: 2px solid #5A5468; border-radius: 14px; }
		.dialogue-box.portrait-right { flex-direction: row-reverse; }
		.dialogue-portrait { width: 120px; height: 120px; border-radius: 10px; }
		.dialogue-words { flex-direction: column; flex-grow: 1; flex-shrink: 1; min-width: 0px; gap: 8px; }
		.dialogue-name { font-size: 22px; color: #F2D9A6; }
		.dialogue-text { font-size: 21px; color: #F4F0E8; white-space: normal; }
		.dialogue-answers { flex-direction: column; gap: 6px; margin-top: 4px; }
		button.dialogue-answer { height: 40px; font-size: 19px; color: #F4F0E8; background-color: #24222E; border: 2px solid #4A4658; border-radius: 8px; justify-content: start; padding: 0px 14px; }
		button.dialogue-answer:hover { background-color: #302D3C; border: 2px solid #9A92B8; }
		button.dialogue-answer:focus-visible { border: 3px solid #E8D8A8; }
		""";

	private DialogueSettings mSettings; // BORROWED: the plugin's
	/// The box's screen, one reference of ours while it is shown.
	private Screen mScreen;
	// Inside mScreen, BORROWED.
	private Label mName;
	private Label mText;
	private Image mPortrait;
	private UIWidget mBox;
	private UIWidget mAnswerList;
	/// One reference of ours each.
	private List<Button> mAnswers = new .() ~ delete _;
	/// The line's whole text.
	private String mFull = new .() ~ delete _;
	/// Its characters (code points).
	private int mLength = 0;
	/// How many show.
	private float mTyped = 0.0f;
	private bool mBoxPressed = false;
	/// Whether its sheet took: it is set once the box is in the GUI.
	private bool mStyled = false;
	private int32 mAnswerPressed = -1;

	public this(DialogueSettings settings)
	{
		mSettings = settings;
	}

	public ~this()
	{
		Hide();
	}

	/// Shows `notice` in the box on `stack`, styled by `css` (`gui`'s style manager), typing it out
	/// from the start. `speaker` is BORROWED, for the call.
	public void ShowLine(GuiSubsystem gui, ScreenStack stack, StringView css, DialogueLineNotice notice, DialogueSpeaker speaker)
	{
		if (!Ensure(gui, stack, css))
			return;
		ClearAnswers();
		mName.Text = notice.ShownName;
		mName.Displayed = !notice.ShownName.IsEmpty && ((speaker == null) || speaker.Plate);
		mPortrait.Displayed = notice.Portrait != .();
		if (notice.Portrait != .())
			mPortrait.Source = notice.Portrait.ToString(.. scope .());
		mFull.Set(notice.Text);
		mLength = CodePoints(mFull);
		mTyped = (mSettings.TypingSpeed > 0) ? 0.0f : (float)mLength;
		mBoxPressed = false;
		ShowTyped();
	}

	/// Shows the choice's answers under the line shown last, the first focused.
	public void ShowChoice(GuiSubsystem gui, ScreenStack stack, StringView css, DialogueChoiceNotice notice)
	{
		if (!Ensure(gui, stack, css))
			return;
		ClearAnswers();
		mTyped = (float)mLength; // the line above it, whole
		ShowTyped();
		for (int i < notice.Answers.Count)
		{
			let button = new Button();
			button.AddClass("dialogue-answer");
			button.Text = notice.Answers[i];
			let index = (int32)i;
			button.SetOnClick(new [&] () => { mAnswerPressed = index; });
			mAnswerList.AddChild(button);
			mAnswers.Add(button);
		}
		if (!mAnswers.IsEmpty)
			mAnswers[0].FocusElement();
	}

	/// Takes the box off its stack.
	public void Hide()
	{
		ClearAnswers();
		if (mScreen != null)
		{
			let stack = mScreen.Stack;
			if ((stack != null) && (stack.Top === mScreen))
				stack.Pop();
			else if (stack != null)
				mScreen.Displayed = false; // under a screen the game pushed since: out of sight until it is top
			mScreen.ReleaseRef();
		}
		mScreen = null;
		mStyled = false;
		mBox = null;
		mPortrait = null;
		mName = null;
		mText = null;
		mAnswerList = null;
		mFull.Clear();
		mLength = 0;
		mTyped = 0.0f;
	}

	/// Types on by `deltaTime`; `advancePressed` is the advance action's press this frame. What the
	/// player asked for: an advance (the line typed out already), or an answer.
	public Request Update(float deltaTime, bool advancePressed)
	{
		var request = Request();
		let pressed = advancePressed || mBoxPressed;
		mBoxPressed = false;
		if (mScreen == null)
		{
			mAnswerPressed = -1;
			return request;
		}
		if (!mAnswers.IsEmpty)
		{
			// A press on an answer chooses it; the advance action chooses the focused one (the pad's
			// or the keys' way through the answers), the first when none has the focus.
			request.Choose = mAnswerPressed;
			if ((request.Choose < 0) && advancePressed)
			{
				request.Choose = 0;
				for (int i < mAnswers.Count)
				{
					if (mAnswers[i].IsFocused)
						request.Choose = (int32)i;
				}
			}
			mAnswerPressed = -1;
			return request;
		}
		if (IsTyping)
		{
			mTyped = pressed ? (float)mLength : (mTyped + mSettings.TypingSpeed * deltaTime);
			ShowTyped();
			return request; // a press finishes the typing; the next advances
		}
		request.Advance = pressed;
		return request;
	}

	// === For tests ===

	public bool IsShown => mScreen != null;
	/// Whether its sheet took (it is set once the box is in the GUI).
	public bool IsStyled => mStyled;
	public bool IsTyping => (mScreen != null) && (mTyped < (float)mLength);
	public StringView ShownText => (mText != null) ? mText.Text : "";
	public StringView ShownName => ((mName != null) && mName.Displayed) ? mName.Text : "";
	public int AnswerCount => mAnswers.Count;
	/// Answer `index`'s text; empty past the last.
	public StringView AnswerText(int index) => (index < mAnswers.Count) ? mAnswers[index].Text : "";
	/// Presses answer `index`, as a click on it does.
	public void Press(int index)
	{
		if (index < mAnswers.Count)
			mAnswerPressed = (int32)index;
	}
	/// Focuses answer `index`, as the pad's or the keys' moves do.
	public void Focus(int index)
	{
		if (index < mAnswers.Count)
			mAnswers[index].FocusElement();
	}
	/// Presses the box, as a click on it does.
	public void PressBox() => mBoxPressed = true;
	public Screen ScreenNode => mScreen;

	// Makes the box on `stack` when it is not there, styled by `css`.
	private bool Ensure(GuiSubsystem gui, ScreenStack stack, StringView css)
	{
		if ((mScreen != null) && (mScreen.Stack != null))
			return true;
		Hide();
		let document = scope GuiDocument();
		document.Markup.Set(cMarkup);
		let tree = gui.BuildDocument(document);
		let screen = tree as Screen;
		if (screen == null)
		{
			tree?.ReleaseRef();
			return false;
		}
		mScreen = screen;
		mBox = screen.FindElement("dialogue-box") as UIWidget;
		mPortrait = screen.FindElement("dialogue-portrait") as Image;
		mName = screen.FindElement("dialogue-name") as Label;
		mText = screen.FindElement("dialogue-text") as Label;
		mAnswerList = screen.FindElement("dialogue-answers") as UIWidget;
		if ((mBox == null) || (mPortrait == null) || (mName == null) || (mText == null) || (mAnswerList == null))
		{
			Hide();
			return false;
		}
		if (mSettings.PortraitOnRight)
			mBox.AddClass("portrait-right");
		mBox.AddEventListener(.MouseClick, new [&] (e) => { mBoxPressed = true; });
		stack.Push(screen);
		// Once it is in the GUI: a subtree's sheet is kept by the tree's element reference.
		let sheet = scope StyleSheet();
		CSSParser.Parse(css, sheet);
		mStyled = gui.Styles.SetSubtreeSheet(screen, sheet);
		return true;
	}

	private void ClearAnswers()
	{
		for (let answer in mAnswers)
		{
			answer.RemoveFromParent();
			answer.ReleaseRef();
		}
		mAnswers.Clear();
		mAnswerPressed = -1;
	}

	private void ShowTyped()
	{
		if (mText == null)
			return;
		let shown = Math.Min(mLength, (int)mTyped);
		mText.Text = Prefix(mFull, shown);
	}

	private static int CodePoints(StringView text)
	{
		int count = 0;
		for (let c in text.RawChars)
		{
			if (((uint8)c & 0xC0) != 0x80)
				count++;
		}
		return count;
	}

	// The first `count` code points of `text`.
	private static StringView Prefix(StringView text, int count)
	{
		int seen = 0;
		for (int i < text.Length)
		{
			if (((uint8)text[i] & 0xC0) != 0x80)
			{
				if (seen == count)
					return text.Substring(0, i);
				seen++;
			}
		}
		return text;
	}
}
