using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// Toasts: short notices that leave by themselves, one host for a game and an editor alike
// (foundation.ui wrote the same toast twice, its toolkit's and a copy in its gamekit, for a module
// rule; no reference keeps them apart). A ToastHost is a widget the application places over a
// window: only its cards take the pointer, and a toast never takes the focus. A request is a
// message (and a title), or a widget for its content in the host's card, or `Bare`, the
// application's card alone; a severity (info, success, warning, error: colour and icon the
// sheet's), up to two actions, a duration and a key. Info and success stay 5 s, a warning 8 s, an
// error until closed, each the host's to change; hovering or focusing a toast pauses them all. A
// post with the key of one shown replaces it and counts it ("×12": a burst of one error, or a
// progress toast updated), four show at once and the rest wait. Posts may come from any thread:
// they wait in the host until its next frame (Godot, zed, Zero), a widget made there by a
// function, since widgets do not cross threads. A card enters and leaves through the core's Enter
// and Leave (`:entering`, `:leaving`), so the sheet's transitions play and a dismissed card goes
// once its exit has ended; a request's classes choose how (the theme's slide, `pop`, `still`, a
// game's own; reduced motion only fades). Each shown toast is announced, an error interrupting.
// The host keeps no history: it tells the application each toast posted and gone, for a log or a
// bell. A request is a value (no callbacks in it), which code fills in and posts; an action's
// button sends `activate` with the action's id, as a menu item does, beside the callback code
// may pass with the post.

enum ToastSeverity : uint8
{
	Info,
	Success,
	Warning,
	Error,
}

static
{
	public static StringView ToastSeverityName(ToastSeverity severity)
	{
		switch (severity)
		{
		case .Success: return "success";
		case .Warning: return "warning";
		case .Error: return "error";
		default: return "info";
		}
	}
}

/// A button on a toast. Pressed, it closes the toast, runs its command (if it names one), calls
/// the post's callback with it, and sends `activate` with its id from its button. A
/// class: it owns its text; Set copies another.
class ToastAction
{
	public String Id = new .() ~ delete _;
	public String Text = new .() ~ delete _;
	public String Command = new .() ~ delete _;

	public this() { }

	public this(StringView id, StringView text, StringView command)
	{
		Id.Set(id);
		Text.Set(text);
		Command.Set(command);
	}

	public void Set(ToastAction other)
	{
		if (other === this)
			return;
		Id.Set(other.Id);
		Text.Set(other.Text);
		Command.Set(other.Command);
	}
}

typealias ToastId = uint64;

/// What a toast shows and how long. A class: it owns its text and its actions; Set copies another
/// deeply. Its maker owns it plainly (`scope`, or `new` and `delete`).
class ToastRequest
{
	private String mTitle = new .() ~ delete _;
	private String mMessage = new .() ~ delete _;
	private String mAnnouncement = new .() ~ delete _;
	private String mKey = new .() ~ delete _;
	private String mClasses = new .() ~ delete _;

	public StringView Title { get => mTitle; set => mTitle.Set(value); }
	public StringView Message { get => mMessage; set => mMessage.Set(value); }
	/// The message is the core's rich text.
	public bool Rich = false;
	/// No card: the content alone, its lifetime and place still the host's (a game's banner).
	public bool Bare = false;
	/// Said to a screen reader; empty: the title and message, else the content's name.
	public StringView Announcement { get => mAnnouncement; set => mAnnouncement.Set(value); }
	public ToastSeverity Severity = .Info;
	/// Two at most (the rest are not shown).
	public List<ToastAction> Actions = new .() ~ DeleteContainerAndItems!(_);
	/// Seconds it stays; below 0: its severity's default; 0: until closed.
	public float Duration = -1.0f;
	/// A post with the key of one shown or waiting replaces it and counts it; empty: none.
	public StringView Key { get => mKey; set => mKey.Set(value); }
	/// Classes on its card (space-separated): how it comes and goes, as the sheet says (the
	/// theme's `pop` and `still`, a game's own), or any look the sheet gives them.
	public StringView Classes { get => mClasses; set => mClasses.Set(value); }

	private UIWidget mContent = null ~ _?.ReleaseRef();

	/// Its content instead of the title and message, in the host's card (the GUI's thread only; a
	/// post from another thread passes a function that makes it). It holds a reference of its
	/// own: the caller keeps its.
	public UIWidget Content
	{
		get => mContent;
		set
		{
			if (value != null)
				value.AddRef();
			if (mContent != null)
				mContent.ReleaseRef();
			mContent = value;
		}
	}

	public this()
	{
	}

	/// Adds an action, made here from its parts. An empty command: none.
	public void AddAction(StringView id, StringView text, StringView command)
	{
		Actions.Add(new ToastAction(id, text, command));
	}

	public void Set(ToastRequest other)
	{
		if (other === this)
			return;
		mTitle.Set(other.mTitle);
		mMessage.Set(other.mMessage);
		Rich = other.Rich;
		Content = other.Content;
		Bare = other.Bare;
		mAnnouncement.Set(other.mAnnouncement);
		Severity = other.Severity;
		ClearAndDeleteItems!(Actions);
		for (let action in other.Actions)
		{
			let copy = new ToastAction();
			copy.Set(action);
			Actions.Add(copy);
		}
		Duration = other.Duration;
		mKey.Set(other.mKey);
		mClasses.Set(other.mClasses);
	}
}

/// Told the action pressed on a toast.
typealias ToastActionCallback = delegate void(ToastAction action);
/// Makes a toast's content, on the GUI's thread; the caller holds the reference it returns.
typealias ToastContentMaker = delegate UIWidget();

/// One toast (`toast`, with its severity's class): a card holding its parts, or bare. Its host
/// fills it.
class ToastCard : UIWidget
{
	internal Sedulous.GUI.ToastId mToastId = 0;
	internal ToastSeverity mSeverity = .Info;
	internal String mKey = new .() ~ delete _;
	internal String mAnnouncement = new .() ~ delete _;
	internal uint32 mCount = 1;
	internal float mRemaining = 0.0f;
	// Taken off the stack: leaving (the core's Leave), gone once its exit ends.
	internal bool mDismissed = false;
	// Its request's.
	internal String mRequestClasses = new .() ~ delete _;
	// Its parts: a reference each.
	internal UIWidget mBody = null ~ _?.ReleaseRef();
	internal Label mTitle = null ~ _?.ReleaseRef();
	internal Label mMessage = null ~ _?.ReleaseRef();
	internal Label mCountPart = null ~ _?.ReleaseRef();
	internal UIWidget mContent = null ~ _?.ReleaseRef();
	internal UIWidget mActionRow = null ~ _?.ReleaseRef();
	internal List<Button> mActions = new .() ~ { for (let b in _) b.ReleaseRef(); delete _; };
	internal List<ToastAction> mActionItems = new .() ~ DeleteContainerAndItems!(_);
	internal ToastActionCallback mOnAction ~ delete _;
	internal Button mClose = null ~ _?.ReleaseRef();

	public this()
	{
		Tag = "toast";
		using (StyleWriteScope(this))
		{
			EditLayoutStyle(scope (s) =>
				{
					s.Direction = .Row;
					s.AlignItems = .Start;
					s.ColumnGap = 8.0f;
					s.Shrink = 0.0f;
				});
		}
	}

	public Sedulous.GUI.ToastId ToastId => mToastId;
	public ToastSeverity Severity => mSeverity;
	public StringView Key => mKey;
	/// How many posts it stands for (1, then each one its key replaced).
	public uint32 Count => mCount;
	/// Seconds left (0 or less with a duration: going; below 0 when it stays until closed).
	public float Remaining => mRemaining;
	public Label TitlePart => mTitle;
	public Label MessagePart => mMessage;
	public Label CountPart => mCountPart;
	public UIWidget Content => mContent;
	public Button CloseButton => mClose;
	public int ActionCount => mActions.Count;

	public Button ActionAt(int index) => mActions[index];

	/// What it says to a screen reader.
	public StringView Announcement => mAnnouncement;
}

[GuiReflect(true)]
class ToastHost : UIWidget
{
	public const int cMaxActions = 2;

	private class Incoming
	{
		public ToastId Id = 0;
		public ToastRequest Request = new .() ~ delete _;
		public ToastContentMaker MakeContent ~ delete _;
		public ToastActionCallback OnAction ~ delete _;
	}

	private class Waiting
	{
		public ToastId Id = 0;
		public ToastRequest Request = new .() ~ delete _;
		public uint32 Count = 1;
		public ToastActionCallback OnAction ~ delete _;
	}

	// Shown, oldest first (leaving ones among them): a reference each.
	private List<ToastCard> mCards = new .() ~ { for (let c in _) c.ReleaseRef(); delete _; };
	private List<Waiting> mWaiting = new .() ~ DeleteContainerAndItems!(_);
	// Posted from other threads, under mLock.
	private List<Incoming> mIncoming = new .() ~ DeleteContainerAndItems!(_);
	// Guards mIncoming and mLastId.
	private Monitor mLock = new .() ~ delete _;
	private ToastId mLastId = 0;
	private int mMaxShown = 4;
	private float[4] mDefaults = .(5.0f, 5.0f, 8.0f, 0.0f);
	// Its clock's action runs.
	private bool mTicking = false;
	private delegate void(ToastId id, ToastCard card) mOnPosted ~ delete _;
	private delegate void(ToastId id, bool byUser) mOnDismissed ~ delete _;

	public this()
	{
		Tag = "toasthost";
		HitTestVisible = false; // only its cards take the pointer
		using (StyleWriteScope(this))
		{
			EditLayoutStyle(scope (s) =>
				{
					// Over what holds it, its toasts at the bottom end.
					s.Placement = .Absolute;
					s.Left = LayoutLength.Px(0.0f);
					s.Top = LayoutLength.Px(0.0f);
					s.Right = LayoutLength.Px(0.0f);
					s.Bottom = LayoutLength.Px(0.0f);
					s.Direction = .Column;
					s.JustifyContent = .End;
					s.AlignItems = .End;
					s.RowGap = 8.0f;
					s.ZIndex = 1000;
				});
			Padding = .(16.0f, 16.0f, 16.0f, 16.0f);
		}
	}

	/// Shows a toast, or queues it while as many as it shows already do; the GUI's thread.
	/// `onAction` hears the action pressed. The host copies `request` (the caller keeps it);
	/// OWNERSHIP of `onAction` transfers.
	public ToastId Post(ToastRequest request, ToastActionCallback onAction = null)
	{
		ToastId id = 0;
		using (mLock.Enter())
			id = ++mLastId;
		KeepTicking();
		Place(id, request, onAction);
		return id;
	}

	/// Posts from any thread: it waits until the host's next frame. Its content, if any, comes
	/// from `makeContent`, called then on the GUI's thread (the request's `Content` is not taken).
	/// The host copies `request`; OWNERSHIP of `makeContent` and `onAction` transfers.
	public ToastId PostFromAnyThread(ToastRequest request, ToastContentMaker makeContent = null, ToastActionCallback onAction = null)
	{
		let post = new Incoming();
		post.Request.Set(request);
		post.Request.Content = null;
		post.MakeContent = makeContent;
		post.OnAction = onAction;
		using (mLock.Enter())
		{
			post.Id = ++mLastId;
			mIncoming.Add(post);
			return post.Id;
		}
	}

	/// The toast host in `node`'s GUI (its root's subtree), else null.
	public static ToastHost Nearest(Node node)
	{
		let root = node?.RootNode;
		return (root != null) ? FindUnder(root) : null;
	}

	private static ToastHost FindUnder(Node node)
	{
		if (let host = node as ToastHost)
			return host;
		for (int i = 0; i < node.ChildCount; ++i)
		{
			if (let host = FindUnder(node.GetChildAt(i)))
				return host;
		}
		return null;
	}

	/// Takes a toast away (shown or waiting); false when it is not there.
	public bool Dismiss(ToastId id) => Remove(id, false);

	/// Takes every toast away.
	public void DismissAll()
	{
		while (!mWaiting.IsEmpty)
			Remove(mWaiting[0].Id, false);
		for (int i = mCards.Count; i-- > 0;)
		{
			if (!mCards[i].mDismissed)
				Remove(mCards[i].mToastId, false);
		}
	}

	/// The toasts shown now, oldest first (one leaving not among them).
	[GuiProperty]
	public int ShownCount
	{
		get
		{
			int count = 0;
			for (let card in mCards)
				count += !card.mDismissed ? 1 : 0;
			return count;
		}
	}

	/// The toasts waiting.
	[GuiProperty]
	public int WaitingCount
	{
		get => mWaiting.Count;
	}

	/// A shown toast's card (null when it is not shown).
	public ToastCard GetCard(ToastId id)
	{
		for (let card in mCards)
		{
			if ((card.mToastId == id) && !card.mDismissed)
				return card;
		}
		return null;
	}

	public bool IsShown(ToastId id) => GetCard(id) != null;

	public bool IsWaiting(ToastId id)
	{
		for (let waiting in mWaiting)
		{
			if (waiting.Id == id)
				return true;
		}
		return false;
	}

	/// Whether their timers stand still now (the pointer or the focus on a toast).
	public bool IsPaused
	{
		get
		{
			for (let card in mCards)
			{
				if (card.Hovered || card.IsFocusWithin)
					return true;
			}
			return false;
		}
	}

	/// How many it shows at once (4); the rest wait.
	[GuiProperty]
	public int MaxShown
	{
		get => mMaxShown;
		set => mMaxShown = Math.Max(1, value);
	}

	/// Seconds a severity's toasts stay when a request does not say (0: until closed).
	public void SetDefaultDuration(ToastSeverity severity, float seconds)
	{
		mDefaults[(int)severity] = Math.Max(0.0f, seconds);
	}

	public float GetDefaultDuration(ToastSeverity severity) => mDefaults[(int)severity];

	/// Told each toast posted (once shown or queued; a replacement too), for a log. OWNERSHIP of
	/// `callback` transfers.
	public void SetOnPosted(delegate void(ToastId id, ToastCard card) callback)
	{
		delete mOnPosted;
		mOnPosted = callback;
	}

	/// Told each toast gone: closed by the user (its close button or an action), or not.
	/// OWNERSHIP of `callback` transfers.
	public void SetOnDismissed(delegate void(ToastId id, bool byUser) callback)
	{
		delete mOnDismissed;
		mOnDismissed = callback;
	}

	/// Advances its toasts by `seconds` (the host's frame: the GUI's clock calls it).
	public void Tick(float seconds)
	{
		// What other threads posted, here on the GUI's thread.
		let incoming = scope List<Incoming>();
		using (mLock.Enter())
		{
			incoming.AddRange(mIncoming);
			mIncoming.Clear();
		}
		for (let post in incoming)
		{
			if (post.MakeContent != null)
			{
				let made = post.MakeContent();
				post.Request.Content = made;
				if (made != null)
					made.ReleaseRef(); // the request's reference keeps it
			}
			let onAction = post.OnAction;
			post.OnAction = null; // it moves to the toast
			Place(post.Id, post.Request, onAction);
			delete post;
		}
		let paused = IsPaused;
		for (int i = mCards.Count; i-- > 0;)
		{
			let card = mCards[i];
			if (card.mDismissed)
			{
				if (card.Parent != this) // its exit ended: the core's Leave took it off
				{
					mCards.RemoveAt(i);
					card.ReleaseRef();
				}
				continue;
			}
			if (paused || (card.mRemaining < 0.0f))
				continue;
			card.mRemaining -= seconds;
			if (card.mRemaining <= 0.0f)
				Remove(card.mToastId, false);
		}
		ShowWaiting();
	}

	// Laid out once it is in a GUI: its clock starts there (an action runs only under a root).
	public override void OnLayout()
	{
		base.OnLayout();
		KeepTicking();
	}

	private void KeepTicking()
	{
		if (mTicking || (ActionManager == null))
			return;
		mTicking = true;
		// The host's clock runs for as long as the host, so it asks for no frames itself, or its
		// window would draw every frame with nothing changed. What it does (a card shown or
		// removed) invalidates as any change does.
		let tick = new TickAction(new (elapsed) =>
			{
				Tick((float)elapsed.TotalSeconds);
				return true;
			}, false);
		RunAction(tick);
		tick.ReleaseRef();
	}

	private float DurationOf(ToastRequest request)
	{
		let seconds = (request.Duration < 0.0f) ? mDefaults[(int)request.Severity] : request.Duration;
		return (seconds > 0.0f) ? seconds : -1.0f; // below 0: until closed
	}

	// Shows it, replaces the one with its key, or queues it. `request` is read (the caller keeps
	// it); OWNERSHIP of `onAction` transfers.
	private void Place(ToastId id, ToastRequest request, ToastActionCallback onAction)
	{
		if (!request.Key.IsEmpty)
		{
			for (let card in mCards)
			{
				if (!card.mDismissed && (card.mKey == request.Key))
				{
					let count = card.mCount + 1;
					Fill(card, card.mToastId, request, count, onAction);
					if (mOnPosted != null)
						mOnPosted(card.mToastId, card);
					Announce(card);
					return;
				}
			}
			for (let waiting in mWaiting)
			{
				if (waiting.Request.Key == request.Key)
				{
					waiting.Request.Set(request);
					delete waiting.OnAction;
					waiting.OnAction = onAction;
					++waiting.Count;
					return;
				}
			}
		}
		if (ShownCount >= mMaxShown)
		{
			let waiting = new Waiting();
			waiting.Id = id;
			waiting.Request.Set(request);
			waiting.OnAction = onAction;
			mWaiting.Add(waiting);
			return;
		}
		Show(id, request, 1, onAction);
	}

	// OWNERSHIP of `onAction` transfers.
	private void Show(ToastId id, ToastRequest request, uint32 count, ToastActionCallback onAction)
	{
		let card = new ToastCard();
		Fill(card, id, request, count, onAction);
		AddChild(card);
		card.Enter(); // `:entering` for the sheet's entrance
		mCards.Add(card); // the list keeps the reference it was made with
		if (mOnPosted != null)
			mOnPosted(id, card);
		Announce(card);
	}

	private void ShowWaiting()
	{
		while (!mWaiting.IsEmpty && (ShownCount < mMaxShown))
		{
			let next = mWaiting[0];
			mWaiting.RemoveAt(0);
			let onAction = next.OnAction;
			next.OnAction = null; // it moves to the toast
			Show(next.Id, next.Request, next.Count, onAction);
			delete next;
		}
	}

	// Its parts from the request (a replacement's too, counted). OWNERSHIP of `onAction`
	// transfers.
	private void Fill(ToastCard card, ToastId id, ToastRequest request, uint32 count, ToastActionCallback onAction)
	{
		card.mToastId = id;
		card.mCount = count;
		card.mKey.Set(request.Key);
		card.mRemaining = DurationOf(request);
		card.RemoveClass(ToastSeverityName(card.mSeverity));
		card.mSeverity = request.Severity;
		card.AddClass(ToastSeverityName(card.mSeverity));
		EachClass(card.mRequestClasses, scope (name) => { card.RemoveClass(name); });
		card.mRequestClasses.Set(request.Classes);
		EachClass(card.mRequestClasses, scope (name) => { card.AddClass(name); });
		if (request.Bare)
			card.AddClass("bare");
		else
			card.RemoveClass("bare");
		while (card.ChildCount != 0)
			card.RemoveChild(card.GetChildAt(card.ChildCount - 1));
		ToastHostDetail.Hold(ref card.mTitle, null);
		ToastHostDetail.Hold(ref card.mMessage, null);
		ToastHostDetail.Hold(ref card.mCountPart, null);
		ToastHostDetail.Hold(ref card.mClose, null);
		for (let b in card.mActions)
			b.ReleaseRef();
		card.mActions.Clear();
		ClearAndDeleteItems!(card.mActionItems);
		delete card.mOnAction;
		card.mOnAction = onAction;
		ToastHostDetail.Hold(ref card.mContent, request.Content);
		if (request.Bare && (card.mContent != null))
		{
			card.AddChild(card.mContent);
			card.mAnnouncement.Set(request.Announcement.IsEmpty ? card.mContent.AccessLabel : request.Announcement);
			return;
		}
		// The card: its mark (the sheet's colour and icon), its body, its count and close.
		let mark = new UIWidget();
		mark.Tag = "toastmark";
		mark.HitTestVisible = false;
		card.AddChild(mark);
		mark.ReleaseRef(); // the tree's reference keeps it
		let body = new UIWidget();
		ToastHostDetail.Hold(ref card.mBody, body);
		body.ReleaseRef(); // the card's reference keeps it
		card.mBody.AddClass("body");
		card.mBody.EditLayoutStyle(scope (s) =>
			{
				s.Direction = .Column;
				s.RowGap = 4.0f;
				s.Grow = 1.0f;
				s.Shrink = 1.0f;
				s.MinWidth = LayoutLength.Px(0.0f);
			});
		card.AddChild(card.mBody);
		let said = scope String();
		if (card.mContent != null)
			card.mBody.AddChild(card.mContent);
		else
		{
			if (!request.Title.IsEmpty)
			{
				card.mTitle = new Label();
				card.mTitle.AddClass("title");
				card.mTitle.Text = request.Title;
				card.mBody.AddChild(card.mTitle);
				said.Set(request.Title);
			}
			card.mMessage = new Label();
			card.mMessage.AddClass("message");
			card.mMessage.Rich = request.Rich;
			card.mMessage.Text = request.Message;
			card.mBody.AddChild(card.mMessage);
			if (!said.IsEmpty && !request.Message.IsEmpty)
				said.Append(": ");
			said.Append(card.mMessage.GetTextLayout().PlainText); // a rich message without its markup
		}
		if (!request.Announcement.IsEmpty)
			card.mAnnouncement.Set(request.Announcement);
		else if (card.mContent != null)
			card.mAnnouncement.Set(card.mContent.AccessLabel);
		else
			card.mAnnouncement.Set(said);
		let actions = Math.Min(request.Actions.Count, cMaxActions);
		if (actions > 0)
		{
			let row = new UIWidget();
			ToastHostDetail.Hold(ref card.mActionRow, row);
			row.ReleaseRef(); // the card's reference keeps it
			card.mActionRow.AddClass("actions");
			card.mActionRow.EditLayoutStyle(scope (s) =>
				{
					s.Direction = .Row;
					s.ColumnGap = 6.0f;
				});
			card.mBody.AddChild(card.mActionRow);
			for (int i = 0; i < actions; ++i)
			{
				let action = request.Actions[i];
				let button = new Button();
				button.AddClass("action");
				button.Text = action.Text;
				button.Id = action.Id; // what its `activate` says
				let item = new ToastAction();
				item.Set(action);
				card.mActionItems.Add(item);
				if (!action.Command.IsEmpty)
					button.Command = action.Command;
				let held = card;
				let at = i;
				button.SetOnClick(new () =>
					{
						let toast = held.mToastId;
						if (at >= held.mActionItems.Count)
							return;
						let pressed = scope ToastAction();
						pressed.Set(held.mActionItems[at]);
						let from = held.mActions[at];
						from.AddRef(); // its toast may let it go on the way
						if (held.mOnAction != null)
							held.mOnAction(pressed);
						// The `activate` event, as a menu item's: it bubbles, its id the action's.
						let activated = scope ItemEvent(.ItemActivate, from, (int32)at, ModelIndex());
						from.RouteEvent(activated);
						Remove(toast, true);
						from.ReleaseRef();
					});
				card.mActionRow.AddChild(button);
				card.mActions.Add(button); // the list keeps the reference it was made with
			}
		}
		if (count > 1)
		{
			card.mCountPart = new Label();
			card.mCountPart.AddClass("count");
			card.mCountPart.Text = scope String()..AppendF("×{}", count);
			card.AddChild(card.mCountPart);
		}
		card.mClose = new Button();
		card.mClose.AddClass("close");
		card.mClose.Text = "×";
		card.mClose.AccessLabel = "Close";
		let held = card;
		card.mClose.SetOnClick(new () => { Remove(held.mToastId, true); });
		card.AddChild(card.mClose);
	}

	// Each class of a space-separated list.
	private static void EachClass(StringView classes, delegate void(StringView name) each)
	{
		var rest = ParseUtil.Trim(classes);
		while (rest.Length != 0)
		{
			int end = 0;
			while ((end < rest.Length) && (rest[end] != ' '))
				++end;
			each(rest.Substring(0, end));
			rest = ParseUtil.Trim(rest.Substring(end, rest.Length - end));
		}
	}

	private void Announce(ToastCard card)
	{
		if (card.mAnnouncement.IsEmpty)
			return;
		let scene = SceneRoot;
		if (scene != null)
			scene.Context.Announce(card.mAnnouncement, (card.mSeverity == .Error) ? .Assertive : .Polite);
	}

	// Off the stack: a shown one leaves through the core's Leave (out of the pointer at once, a
	// child until its exit has ended, never inside the event that closed it), a waiting one at
	// once.
	private bool Remove(ToastId id, bool byUser)
	{
		for (int i = 0; i < mWaiting.Count; ++i)
		{
			if (mWaiting[i].Id == id)
			{
				delete mWaiting[i];
				mWaiting.RemoveAt(i);
				if (mOnDismissed != null)
					mOnDismissed(id, byUser);
				return true;
			}
		}
		for (let card in mCards)
		{
			if ((card.mToastId == id) && !card.mDismissed)
			{
				card.mDismissed = true;
				card.Leave();
				if (mOnDismissed != null)
					mOnDismissed(id, byUser);
				return true;
			}
		}
		return false;
	}
}

/// What Toast.bf keeps out of the public surface.
internal static class ToastHostDetail
{
	/// `slot` holds a reference to `node` (null: none), letting go of the one it held.
	public static void Hold<T>(ref T slot, T node) where T : Node
	{
		if (node != null)
			node.AddRef();
		if (slot != null)
			slot.ReleaseRef();
		slot = node;
	}
}
