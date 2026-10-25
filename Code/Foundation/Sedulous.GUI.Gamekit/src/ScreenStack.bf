using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.GUI;

// A game's screens: a `screens` element (ScreenStack), placed where a game's screens go (any
// number per root), holding `screen` elements on a stack. Push takes a node, or a document loaded
// fresh each time; pop, replace and clear. A screen says whether it covers what is under it (hides
// it), blocks its input (makes it inert, so a press held there is let go) and pauses the game; the
// stack reports the pause (the game decides what pausing means). A screen is a navigation scope and
// remembers its focus, so a pop refocuses the screen now on top; on a push, its `nav-default` or its
// first focusable, else the screen itself (a HUD: `back` still starts there). A press on a screen's
// empty area leaves the focus where it is, so `back` (Escape, the pad's East) still reaches it: the
// top screen hears `back` first (a script's handler may take it; `back="none"` keeps it), else the
// stack pops, never below its last screen and never in the frame that pushed. A screen popped
// leaves through the core's Leave (its sheet's exit plays), out of the stack, its focus and its
// input at once; one pushed enters through the core's Enter (`:entering` while its sheet's entrance
// plays), and a pop during its entrance leaves from where it is. The screens under a covering one
// show again as it starts leaving, not once it has gone. A game that may hitch caps the GUI's clock
// step (GUIContext.MaxClockStep) so an entrance or exit is slowed rather than skipped.
// Lifecycle as named events on the screen: `screenenter`, `screenshown`, `screenleave`,
// `screenhidden` (covered) and `screenrevealed`; the stack tells `pausechange`.

/// One of a game's screens: its content, and how it sits over the screens under it.
[GuiReflect(true), Scriptable]
class Screen : UIWidget
{
	/// The stack it is on, not held (the stack holds it).
	private ScreenStack mStack = null;
	private bool mCovers = false;
	private bool mBlocks = true;
	private bool mPauses = false;
	private bool mPopsOnBack = true;
	private bool mCovered = false;

	public this()
	{
		Tag = "screen";
		NavScope = .Contain; // Tab and the arrows stay in it; it remembers its focus
		KeepsFocus = true; // a press on its empty area keeps the focus (and `back`) here
		// Its entrance over (the core's Enter), it is shown, while it is still on its stack.
		AddEventListener(.Entered, new (e) =>
			{
				if (mStack != null)
					SendNamedEvent("screenshown");
			});
	}

	/// It hides the screens under it (a full-screen menu over the game).
	[GuiProperty("covers"), Scriptable]
	public bool Covers
	{
		get => mCovers;
		set
		{
			mCovers = value;
			if (mStack != null)
				mStack.Settle();
		}
	}

	/// The screens under it take no input (a pause menu); off, they do (a HUD over the game).
	[GuiProperty("blocks"), Scriptable]
	public bool Blocks
	{
		get => mBlocks;
		set
		{
			mBlocks = value;
			if (mStack != null)
				mStack.Settle();
		}
	}

	/// The game pauses while it is on the stack (the stack reports it).
	[GuiProperty("pauses"), Scriptable]
	public bool Pauses
	{
		get => mPauses;
		set
		{
			mPauses = value;
			if (mStack != null)
				mStack.Settle();
		}
	}

	/// What `back` does on it: "pop" (the default) or "none" (it keeps its back: a title screen).
	[GuiProperty("back"), Scriptable]
	public StringView Back
	{
		get => mPopsOnBack ? "pop" : "none";
		set => mPopsOnBack = value != "none";
	}

	public bool PopsOnBack => mPopsOnBack;

	/// The stack it is on, or null (not pushed, or popped and leaving).
	[Scriptable]
	public ScreenStack Stack => mStack;

	/// Hidden by a covering screen above it.
	[Scriptable]
	public bool IsCovered => mCovered;
}

/// A stack of screens: the top one shows, takes the input and hears `back` first.
[GuiReflect(true, "Screens"), Scriptable]
class ScreenStack : UIWidget
{
	/// Bottom first, a reference held to each.
	private List<Screen> mScreens = new .() ~
		{
			for (let screen in _)
			{
				screen.[Friend]mStack = null; // off a stack that is gone
				screen.ReleaseRef();
			}
			delete _;
		};
	private bool mPaused = false;
	private bool mJustPushed = false;
	private bool mAdding = false; // Push adding its screen as a child
	private delegate void(bool paused) mOnPausedChanged ~ delete _;

	public this()
	{
		Tag = "screens";
		using (StyleWriteScope(this)) // the sheet may lay it out otherwise
		{
			EditLayoutStyle(scope (s) => { s.Kind = .Stack; }); // each screen fills it
		}
		OnCommand(cBackCommand, new (command) => { Back(); });
	}

	/// A screen markup (or code) adds as a child is pushed, in order: `<Screens>` holding
	/// `<Screen>`s starts with them on its stack, the last on top.
	public override Node AddChild(Node child)
	{
		let screen = ((child != null) && !mAdding) ? (child as Screen) : null;
		if ((screen != null) && (screen.[Friend]mStack == null) && !screen.IsLeaving)
		{
			Push(screen);
			return this;
		}
		return base.AddChild(child);
	}

	/// Pushes `content`: a Screen as it is, anything else in a new screen; it shows on top, takes
	/// the focus (its remembered, its `nav-default`, else its first focusable) and hears
	/// `screenenter`. The screen, or null when `content` is a screen already on a stack.
	/// `PushNode` to a script (its `Push` takes a document's path, as Raptor's does).
	[Scriptable, ScriptName("PushNode")]
	public Screen Push(Node content)
	{
		var screen = content as Screen;
		if ((screen != null) && (screen.[Friend]mStack != null))
			return null;
		if (screen == null)
		{
			screen = new Screen(); // this call's reference
			screen.AddChild(content);
		}
		else
			screen.AddRef(); // this call's reference
		defer screen.ReleaseRef();
		if ((screen.Parent == this) && screen.IsLeaving)
			RemoveChild(screen); // one leaving, pushed again: whole again
		screen.[Friend]mStack = this;
		screen.[Friend]mCovered = false;
		screen.SetInert(false);
		screen.Visible = true;
		screen.AddRef(); // the stack's
		mScreens.Add(screen);
		mAdding = true;
		AddChild(screen);
		mAdding = false;
		NoteJustPushed();
		Settle();
		FocusScreen(screen);
		screen.SendNamedEvent("screenenter");
		screen.Enter(); // :entering for the sheet's entrance; `screenshown` once it has played
		return screen;
	}

	/// Pushes the document at `path` (its markup, loaded fresh through the GUI's resources, its
	/// `{{values}}` bound to the GUI's data). Null when it cannot be read or made. `Push` to a
	/// script.
	[Scriptable, ScriptName("Push")]
	public Screen PushDocument(StringView path)
	{
		let content = LoadDocument(path);
		if (content == null)
			return null;
		defer content.ReleaseRef();
		return Push(content);
	}

	/// Takes the top screen off: it leaves (its exit plays, out of input at once), the screens
	/// under it show and take input as the new top says, and the new top takes the focus it had.
	/// False when the stack is empty.
	[Scriptable]
	public bool Pop()
	{
		if (mScreens.IsEmpty)
			return false;
		TakeOffTop();
		Settle();
		if (let top = Top)
			FocusScreen(top);
		return true;
	}

	/// Swaps the top screen for `content` (pushed as Push does); with none, pushes it.
	/// `ReplaceNode` to a script.
	[Scriptable, ScriptName("ReplaceNode")]
	public Screen Replace(Node content)
	{
		if ((content is Screen) && ((content as Screen).[Friend]mStack != null))
			return null;
		if (!mScreens.IsEmpty)
			TakeOffTop();
		return Push(content);
	}

	/// `Replace` to a script.
	[Scriptable, ScriptName("Replace")]
	public Screen ReplaceDocument(StringView path)
	{
		let content = LoadDocument(path);
		if (content == null)
			return null;
		defer content.ReleaseRef();
		return Replace(content);
	}

	/// Takes every screen off, the top first.
	[Scriptable]
	public void Clear()
	{
		while (!mScreens.IsEmpty)
			TakeOffTop();
		Settle();
	}

	/// What `back` does when the top screen did not take it: pops it, unless it keeps its back, it
	/// is the last, or it was pushed this frame (the Back that pushed it). Whether it popped.
	[Scriptable]
	public bool Back()
	{
		let top = Top;
		if ((top == null) || !top.PopsOnBack || (mScreens.Count <= 1) || mJustPushed)
			return false;
		return Pop();
	}

	[Scriptable]
	public Screen Top => mScreens.IsEmpty ? null : mScreens[mScreens.Count - 1];

	[Scriptable]
	public int Count => mScreens.Count;

	public Screen At(int index) => ((index >= 0) && (index < mScreens.Count)) ? mScreens[index] : null;

	/// Whether a screen on the stack pauses the game.
	[Scriptable]
	public bool IsPaused => mPaused;

	/// Whether the game should take the input: no screen on top that blocks it, and the pointer at
	/// `position` (device pixels) over nothing of the GUI that takes it.
	public bool WantsGameInput(Float2 position)
	{
		let top = Top;
		if ((top != null) && top.Blocks)
			return false;
		let dispatcher = EventDispatcher;
		return (dispatcher == null) || !dispatcher.IsPointerOver(position);
	}

	/// Told when the pause starts or ends (as `pausechange` is, with "paused" or "running").
	/// OWNERSHIP of `callback` transfers.
	public void SetOnPausedChanged(delegate void(bool paused) callback)
	{
		delete mOnPausedChanged;
		mOnPausedChanged = callback;
	}

	/// How the screens sit, after one of them changed how it covers, blocks or pauses.
	public void Settle()
	{
		bool blocked = false;
		bool covered = false;
		bool paused = false;
		for (int i = mScreens.Count - 1; i >= 0; i--)
		{
			let screen = mScreens[i];
			screen.SetInert(blocked);
			if (covered != screen.[Friend]mCovered)
			{
				screen.[Friend]mCovered = covered;
				screen.Visible = !covered;
				screen.SendNamedEvent(covered ? "screenhidden" : "screenrevealed");
			}
			blocked = blocked || screen.[Friend]mBlocks;
			covered = covered || screen.[Friend]mCovers;
			paused = paused || screen.[Friend]mPauses;
		}
		if (paused != mPaused)
		{
			mPaused = paused;
			if (mOnPausedChanged != null)
				mOnPausedChanged(paused);
			SendNamedEvent("pausechange", paused ? "paused" : "running");
		}
	}

	// Its remembered focus, its `nav-default` or its first focusable; with nothing focusable (a
	// HUD), the screen itself, so `back` and its commands still start in it.
	private void FocusScreen(Screen screen)
	{
		let dispatcher = EventDispatcher;
		if (dispatcher == null)
			return;
		let target = FocusTargetOf(screen);
		dispatcher.FocusNode = (target != null) ? target : screen;
	}

	// The top screen leaves: off the stack and out of input now, its exit still to play.
	private void TakeOffTop()
	{
		let top = mScreens.PopBack(); // the stack's reference, now this call's
		top.[Friend]mStack = null;
		top.SendNamedEvent("screenleave");
		top.Leave();
		top.ReleaseRef();
	}

	// The frame that pushed may not pop (the Back that pushed it): marked until the GUI's next
	// drain.
	private void NoteJustPushed()
	{
		mJustPushed = true;
		let queue = MutationQueue;
		if (queue == null)
		{
			mJustPushed = false;
			return;
		}
		let self = this;
		AddRef(); // the deferred step's, let go with it
		queue.Enqueue(new () =>
			{
				self.mJustPushed = false;
			}
			~
			{
				self.ReleaseRef();
			});
	}

	// The document at `path`, made through the GUI's elements, resources and fonts, its values
	// bound to the GUI's data; null when there is none. The caller releases what comes back.
	private Node LoadDocument(StringView path)
	{
		let resources = ResourceProvider;
		let elements = ElementSet;
		let text = scope String();
		if ((resources == null) || (elements == null) || !resources.LoadText(path, text))
			return null;
		let loader = scope MarkupLoader(elements, resources, FontService);
		if (let root = SceneRoot)
			loader.SetDataModel(root.Context.Data);
		return loader.LoadFromString(text);
	}
}
