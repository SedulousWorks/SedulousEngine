using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A bridge that keeps what it is told to say, and how.
class ToastNarrator : IAccessibilityBridge
{
	public List<String> Said = new .() ~ DeleteContainerAndItems!(_);
	public List<AnnouncePriority> Priorities = new .() ~ delete _;

	public bool IsListening => true;

	public void Update(AccessTreeUpdate update)
	{
	}

	public void Announce(StringView text, AnnouncePriority priority)
	{
		Said.Add(new String(text));
		Priorities.Add(priority);
	}
}

/// A toast host over an 800 by 600 root, its announcements told to a narrator. The root, the host
/// and the narrator go with it.
class ToastBed
{
	public SceneRoot Root = SceneFixtures.NewScene(800.0f, 600.0f) ~ _.ReleaseRef();
	public ToastHost Host = new .() ~ _.ReleaseRef();
	public ToastNarrator Narrator = new .() ~ delete _;

	public this()
	{
		Root.AddChild(Host);
		Root.Context.AccessibilityBridge = Narrator;
		Frame(0.0f);
	}

	public ~this()
	{
		Root.Context.AccessibilityBridge = null;
	}

	public void Frame(float seconds = 0.016f)
	{
		Root.Context.Update(SceneFixtures.Seconds(seconds));
		Root.UpdateLayout();
	}

	public EventDispatcher D => Root.EventDispatcher;

	/// `request` as a text toast of `severity` (its title `title`).
	public static ToastRequest Text(ToastRequest request, StringView message, ToastSeverity severity = .Info, StringView title = "")
	{
		request.Message.Set(message);
		request.Title.Set(title);
		request.Severity = severity;
		return request;
	}

	public static Float2 Middle(Node node)
	{
		let r = node.ScreenBounds;
		return .(r.X + r.Width * 0.5f, r.Y + r.Height * 0.5f);
	}
}

/// Toasts: a host's cards, by severity, staying their time on the GUI's clock (an error until
/// closed), paused while hovered; a key replacing and counting; four shown and the rest waiting; a
/// widget's content, or bare; actions; posts from another thread waiting for the host's frame;
/// each shown toast announced.
class ToastTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	[Test]
	public static void ACardWithItsTitleMessageAndSeverityAtTheBottomEndAnnouncedItsCloseButtonTakesItAway()
	{
		let bed = scope ToastBed();
		let posted = scope List<ToastId>();
		let gone = scope List<String>();
		defer { ClearAndDeleteItems!(gone); }
		bed.Host.SetOnPosted(new [&] (id, card) => { posted.Add(id); });
		bed.Host.SetOnDismissed(new [&] (id, byUser) => { gone.Add(new String()..AppendF("{} {}", id, byUser ? "user" : "time")); });
		let id = bed.Host.Post(ToastBed.Text(scope ToastRequest(), "Saved the scene", .Success, "Saved"));
		bed.Frame();
		let card = bed.Host.GetCard(id);
		Test.Assert(card != null);
		Test.Assert(card.HasClass("success"));
		Test.Assert(card.TitlePart != null);
		Test.Assert(card.TitlePart.Text == "Saved");
		Test.Assert(card.MessagePart.Text == "Saved the scene");
		Test.Assert(card.CountPart == null);
		Test.Assert(posted.Count == 1);
		Test.Assert(posted[0] == id);
		Test.Assert(bed.Narrator.Said.Count == 1);
		Test.Assert(bed.Narrator.Said[0] == "Saved: Saved the scene");
		Test.Assert(bed.Narrator.Priorities[0] == .Polite);
		// At the bottom end, inside its padding; the host itself lets the pointer through.
		let at = card.ScreenBounds;
		Test.Assert(Near(at.Right, 800.0f - 16.0f));
		Test.Assert(Near(at.Bottom, 600.0f - 16.0f));
		Test.Assert(!bed.Host.HitTestVisible);

		Test.Assert(card.CloseButton != null);
		let close = ToastBed.Middle(card.CloseButton);
		bed.D.InjectMouseMove(close);
		bed.D.InjectMouseDown(close, .Left);
		bed.D.InjectMouseUp(close, .Left);
		Test.Assert(!bed.Host.IsShown(id));
		Test.Assert(gone.Count == 1);
		Test.Assert(gone[0] == scope String()..AppendF("{} user", id));
		Test.Assert(card.IsLeaving); // still a child, never taken off inside the click that closed it
		Test.Assert(card.Parent == bed.Host);
		bed.Frame(0.2f);
		Test.Assert(card.Parent == null);
	}

	[Test]
	public static void EachSeverityStaysItsTimeOnTheGUIsClockAnErrorUntilClosedHoveringAToastPausesThem()
	{
		let bed = scope ToastBed();
		let info = bed.Host.Post(ToastBed.Text(scope ToastRequest(), "Info"));
		let warning = bed.Host.Post(ToastBed.Text(scope ToastRequest(), "Careful", .Warning));
		let error = bed.Host.Post(ToastBed.Text(scope ToastRequest(), "Broken", .Error));
		let rich = ToastBed.Text(scope ToastRequest(), "the [b]fur[/b] material", .Info, "Missing");
		rich.Rich = true;
		let richId = bed.Host.Post(rich);
		Test.Assert(bed.Narrator.Said.Back == "Missing: the fur material"); // said without its markup
		Test.Assert(bed.Host.GetCard(richId).MessagePart.Rich);
		let brief = ToastBed.Text(scope ToastRequest(), "Brief");
		brief.Duration = 2.0f;
		let shortOne = bed.Host.Post(brief);
		Test.Assert(bed.Narrator.Priorities.Back == .Polite);
		Test.Assert(bed.Narrator.Priorities[2] == .Assertive); // the error interrupts
		bed.Frame(2.5f);
		Test.Assert(!bed.Host.IsShown(shortOne));
		bed.Frame(2.6f); // 5.1 s
		Test.Assert(!bed.Host.IsShown(info));
		Test.Assert(bed.Host.IsShown(warning));
		bed.Frame(3.0f); // 8.1 s
		Test.Assert(!bed.Host.IsShown(warning));
		bed.Frame(100.0f);
		Test.Assert(bed.Host.IsShown(error));
		Test.Assert(bed.Narrator.Said[2] == "Broken");

		// The pointer on a toast: none of them counts down.
		bed.Host.SetDefaultDuration(.Info, 1.0f);
		Test.Assert(Near(bed.Host.GetDefaultDuration(.Info), 1.0f));
		let next = bed.Host.Post(ToastBed.Text(scope ToastRequest(), "Next"));
		bed.Frame();
		bed.D.InjectMouseMove(ToastBed.Middle(bed.Host.GetCard(error)));
		Test.Assert(bed.Host.IsPaused);
		bed.Frame(5.0f);
		Test.Assert(bed.Host.IsShown(next));
		bed.D.InjectMouseMove(.(10.0f, 10.0f));
		Test.Assert(!bed.Host.IsPaused);
		bed.Frame(1.5f);
		Test.Assert(!bed.Host.IsShown(next));
	}

	[Test]
	public static void APostWithTheKeyOfOneShownReplacesItAndCountsItItsTimeAgain()
	{
		let bed = scope ToastBed();
		let first = ToastBed.Text(scope ToastRequest(), "Cooking 10%");
		first.Key.Set("cook");
		let id = bed.Host.Post(first);
		bed.Frame(4.0f);
		let again = ToastBed.Text(scope ToastRequest(), "Cooking 60%");
		again.Key.Set("cook");
		let second = bed.Host.Post(again);
		Test.Assert(second != id);
		bed.Frame();
		Test.Assert(bed.Host.ShownCount == 1);
		let card = bed.Host.GetCard(id);
		Test.Assert(card != null);
		Test.Assert(card.Count == 2);
		Test.Assert(card.MessagePart.Text == "Cooking 60%");
		Test.Assert(card.CountPart != null);
		Test.Assert(card.CountPart.Text == "×2");
		bed.Frame(4.0f); // 4 s after the replacement: still there
		Test.Assert(bed.Host.IsShown(id));
	}

	[Test]
	public static void FourShownAtOnceTheRestWaitingTheirTurnAWaitingOneReplacedByItsKeyToo()
	{
		let bed = scope ToastBed();
		bed.Host.MaxShown = 2;
		let a = bed.Host.Post(ToastBed.Text(scope ToastRequest(), "a", .Error));
		let b = bed.Host.Post(ToastBed.Text(scope ToastRequest(), "b", .Error));
		let c1 = ToastBed.Text(scope ToastRequest(), "c1", .Error);
		c1.Key.Set("c");
		let c = bed.Host.Post(c1);
		let c2 = ToastBed.Text(scope ToastRequest(), "c2", .Error);
		c2.Key.Set("c");
		bed.Host.Post(c2);
		Test.Assert(bed.Host.ShownCount == 2);
		Test.Assert(bed.Host.WaitingCount == 1);
		Test.Assert(bed.Host.IsWaiting(c));
		Test.Assert(bed.Narrator.Said.Count == 2); // the waiting one is said when it shows
		Test.Assert(bed.Host.Dismiss(a));
		bed.Frame();
		Test.Assert(bed.Host.IsShown(b));
		let card = bed.Host.GetCard(c);
		Test.Assert(card != null);
		Test.Assert(card.MessagePart.Text == "c2");
		Test.Assert(card.Count == 2);
		Test.Assert(bed.Host.WaitingCount == 0);
		// Newest at the bottom.
		Test.Assert(card.ScreenBounds.Y > bed.Host.GetCard(b).ScreenBounds.Y);
		Test.Assert(!bed.Host.Dismiss(a));
		bed.Host.DismissAll();
		Test.Assert(bed.Host.ShownCount == 0);
	}

	[Test]
	public static void AWidgetForItsContentInTheCardOrBareActionsRunAndCloseItTwoAtMost()
	{
		let bed = scope ToastBed();
		let content = new Label();
		defer content.ReleaseRef();
		content.Text = "rich";
		content.AccessLabel = "Export finished";
		let rich = scope ToastRequest();
		rich.Content = content;
		let withContent = bed.Host.Post(rich);
		var card = bed.Host.GetCard(withContent);
		Test.Assert(card != null);
		Test.Assert(card.Content == content);
		Test.Assert(card.MessagePart == null);
		Test.Assert(card.CloseButton != null);
		Test.Assert(card.Announcement == "Export finished");

		let banner = new Label();
		defer banner.ReleaseRef();
		let bare = scope ToastRequest();
		bare.Content = banner;
		bare.Bare = true;
		bare.Announcement.Set("Achievement: first steps");
		let bareId = bed.Host.Post(bare);
		card = bed.Host.GetCard(bareId);
		Test.Assert(card != null);
		Test.Assert(card.HasClass("bare"));
		Test.Assert(card.CloseButton == null);
		Test.Assert(card.ChildCount == 1);
		Test.Assert(bed.Narrator.Said.Back == "Achievement: first steps");

		let pressed = scope List<String>();
		defer { ClearAndDeleteItems!(pressed); }
		let withActions = ToastBed.Text(scope ToastRequest(), "Exported", .Success);
		withActions.Actions.Add(new ToastAction("reveal", "Reveal", ""));
		withActions.Actions.Add(new ToastAction("open", "Open", ""));
		withActions.Actions.Add(new ToastAction("third", "Third", ""));
		let acted = bed.Host.Post(withActions, new [&] (action) => { pressed.Add(new String(action.Id)); });
		// A script's `activate`, bubbling from the action's button with its id.
		let activated = scope List<String>();
		defer { ClearAndDeleteItems!(activated); }
		bed.Host.AddEventListener(.ItemActivate, new [&] (e) =>
			{
				if (let from = e.Target as UIWidget)
					activated.Add(new String(from.Id));
			});
		card = bed.Host.GetCard(acted);
		Test.Assert(card != null);
		Test.Assert(card.ActionCount == 2);
		Test.Assert(card.ActionAt(0).Text == "Reveal");
		bool byUser = false;
		bed.Host.SetOnDismissed(new [&] (id, user) => { byUser = user; });
		Test.Assert(card.ActionAt(0).Id == "reveal");
		card.ActionAt(0).HandleActivate();
		Test.Assert(pressed.Count == 1);
		Test.Assert(pressed[0] == "reveal");
		Test.Assert(activated.Count == 1);
		Test.Assert(activated[0] == "reveal");
		Test.Assert(!bed.Host.IsShown(acted));
		Test.Assert(byUser);
	}

	[Test]
	public static void PostedFromAnotherThreadItWaitsForTheHostsFrameItsWidgetMadeOnTheGUIsThread()
	{
		let bed = scope ToastBed();
		let gui = Thread.CurrentThreadId;
		int madeOn = 0;
		ToastId id = 0;
		let worker = scope Thread(new [&] () =>
			{
				let request = scope ToastRequest();
				request.Severity = .Warning;
				request.Announcement.Set("Cook finished with warnings");
				id = bed.Host.PostFromAnyThread(request, new [&] () =>
					{
						madeOn = Thread.CurrentThreadId;
						return new Label();
					});
			});
		worker.Start(false);
		worker.Join();
		Test.Assert(id != 0);
		Test.Assert(!bed.Host.IsShown(id));
		Test.Assert(madeOn == 0);
		bed.Frame();
		let card = bed.Host.GetCard(id);
		Test.Assert(card != null);
		Test.Assert(card.Content != null);
		Test.Assert(madeOn == gui);
		Test.Assert(card.HasClass("warning"));
	}

	[Test]
	public static void UnderTheThemeItsTextWrapsAtTheCardsWidthAPathLongerThanALineBrokenInsideIt()
	{
		let bed = scope ToastBed();
		let font = scope CachedFont(new MockFont(), null);
		let id = bed.Host.Post(ToastBed.Text(scope ToastRequest(), "Content/Models/Characters/Fox/Hoooooooooooooooooooo is not in the asset tree, so the bar stays where it was.",
			.Warning, "No such folder"));
		let card = bed.Host.GetCard(id);
		Test.Assert(card != null);
		let styles = scope StyleManager(); // the theme says how a toast's text wraps
		WidgetFixtures.UseSheet(styles, Theme.DefaultThemeCSS);
		styles.ApplyTree(bed.Root);
		card.EditLayoutStyle(scope (s) => { s.Width = LayoutLength.Px(240.0f); });
		card.MessagePart.Font = font;
		card.TitlePart.Font = font;
		bed.Frame();
		let message = card.MessagePart;
		Test.Assert(message.ScreenBounds.Right <= card.ScreenBounds.Right + 0.5f);
		Test.Assert(message.Size.Y >= 36.0f); // three lines and more, not one running past the card
		card.MessagePart.Font = null;
		card.TitlePart.Font = null;
	}

	[Test]
	public static void ItEntersEnteringAndFadesInThroughTheSheetsTransitionARequestsClassChoosesHow()
	{
		let bed = scope ToastBed();
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, Theme.DefaultThemeCSS);
		styles.ApplyTree(bed.Root); // a style pass runs over this GUI: a toast plays its entrance
		let request = ToastBed.Text(scope ToastRequest(), "Hello");
		request.Classes.Set("pop celebrate");
		request.Key.Set("hello");
		let id = bed.Host.Post(request);
		let card = bed.Host.GetCard(id);
		Test.Assert(card != null);
		Test.Assert(card.HasClass("pop"));
		Test.Assert(card.HasClass("celebrate"));
		Test.Assert(card.IsEntering);
		// Styled so by the theme: unseen, its transition's start.
		styles.ApplyTree(bed.Root);
		Test.Assert(Near(card.Alpha, 0.0f));
		bed.Root.Context.Update(TimeSpan(0)); // its first style shown: :entering goes
		Test.Assert(!card.IsEntering);
		// Restyled, it fades in over the theme's 0.15 s, from where it was.
		styles.ApplyTree(bed.Root);
		Test.Assert(Near(card.Alpha, 0.0f));
		bed.Root.Context.Update(SceneFixtures.Seconds(0.07));
		Test.Assert(card.Alpha > 0.05f);
		Test.Assert(card.Alpha < 0.95f);
		bed.Root.Context.Update(SceneFixtures.Seconds(0.2));
		Test.Assert(Near(card.Alpha, 1.0f));

		// Replaced by its key with another class: the old ones go.
		let again = ToastBed.Text(scope ToastRequest(), "Hello again");
		again.Key.Set("hello");
		again.Classes.Set("still");
		bed.Host.Post(again);
		Test.Assert(card.HasClass("still"));
		Test.Assert(!card.HasClass("pop"));
		Test.Assert(!card.HasClass("celebrate"));
	}

	[Test]
	public static void DismissedItFadesOutThroughTheSheetsTransitionAndGoesWhenThatEndsAStillOneAtTheNextUpdate()
	{
		let bed = scope ToastBed();
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, Theme.DefaultThemeCSS);
		styles.ApplyTree(bed.Root);
		void Frame(double seconds)
		{
			bed.Root.Context.Update(SceneFixtures.Seconds(seconds));
			styles.ApplyTree(bed.Root);
		}
		let id = bed.Host.Post(ToastBed.Text(scope ToastRequest(), "Fading"));
		let card = bed.Host.GetCard(id); // held: the host lets it go when it has left
		Test.Assert(card != null);
		card.AddRef();
		defer card.ReleaseRef();
		for (int i = 0; i < 4; ++i)
			Frame(0.1); // in, and settled
		Test.Assert(Near(card.Alpha, 1.0f));
		Test.Assert(bed.Host.Dismiss(id));
		Test.Assert(card.IsLeaving);
		Test.Assert(bed.Host.ShownCount == 0);
		Frame(0.0); // :leaving shown: the fade starts
		Frame(0.07);
		Test.Assert(card.Parent == bed.Host); // still fading
		Test.Assert(card.Alpha < 0.95f);
		Frame(0.2);
		Test.Assert(card.Parent == null);

		let still = ToastBed.Text(scope ToastRequest(), "Still");
		still.Classes.Set("still");
		let quiet = bed.Host.Post(still);
		let quietCard = bed.Host.GetCard(quiet);
		Test.Assert(quietCard != null);
		quietCard.AddRef();
		defer quietCard.ReleaseRef();
		Frame(0.0);
		Frame(0.0);
		Test.Assert(bed.Host.Dismiss(quiet));
		Frame(0.0); // nothing moves it: the style pass lets it go
		Frame(0.0);
		Test.Assert(quietCard.Parent == null);
	}
}
