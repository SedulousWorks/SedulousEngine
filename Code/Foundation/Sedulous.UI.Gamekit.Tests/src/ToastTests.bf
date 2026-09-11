using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Gamekit;

namespace Sedulous.UI.Gamekit.Tests;

/// The toast host's behaviour contract: Show tracks a card, timed toasts expire on Update,
/// sticky ones persist until dismissed, and an action toast fires its callback and then closes.
class ToastTests
{
	private static ToastHost Attach(WidgetBed bed)
	{
		let host = new ToastHost();
		bed.Root.AddView(host);
		return host;
	}

	[Test]
	public static void ShowAddsACardThatCountAndContainsTrack()
	{
		let bed = scope WidgetBed();
		let host = Attach(bed);

		Test.Assert(host.ToastCount == 0);

		let id = host.Show(ToastRequest("Saved"));

		Test.Assert(host.ToastCount == 1);
		Test.Assert(host.Contains(id));
		Test.Assert(host.ChildCount == 1, "the card view");
	}

	[Test]
	public static void ATimedToastExpiresAfterItsDuration()
	{
		let bed = scope WidgetBed();
		let host = Attach(bed);

		var request = ToastRequest("Hi");
		request.DurationSeconds = 1.0f;
		let id = host.Show(request);

		host.Update(0.5f);
		Test.Assert(host.Contains(id), "still alive mid duration");

		host.Update(0.6f); // 1.1s total, past the duration
		Test.Assert(!host.Contains(id));
		Test.Assert(host.ToastCount == 0);
		Test.Assert(host.ChildCount == 0);
	}

	[Test]
	public static void AStickyToastPersistsUntilDismissed()
	{
		let bed = scope WidgetBed();
		let host = Attach(bed);

		var request = ToastRequest("Error", .Error);
		request.DurationSeconds = 0.0f; // sticky
		let id = host.Show(request);

		host.Update(100.0f); // a sticky toast ignores time, however much of it passes
		Test.Assert(host.Contains(id));

		host.Dismiss(id);
		host.Update(0.0f); // removed on the next update, never mid dispatch
		Test.Assert(!host.Contains(id));
	}

	[Test]
	public static void AnActionToastFiresItsCallbackAndThenCloses()
	{
		let bed = scope WidgetBed();
		let host = Attach(bed);

		var fired = false;
		var request = ToastRequest("Deleted");
		request.DurationSeconds = 0.0f;
		request.ActionLabel = "Undo";
		request.OnAction = new [&]() => { fired = true; };
		let id = host.Show(request);

		// The card lays out as message, action, close.
		let card = host.GetChildAt(0) as ViewGroup;
		Test.Assert(card != null);
		Test.Assert(card.ChildCount == 3);
		let action = card.GetChildAt(1) as ButtonBase;
		Test.Assert(action != null);

		action.FireClick();
		Test.Assert(fired);

		host.Update(0.0f); // the action marked it closing
		Test.Assert(!host.Contains(id));
	}

	/// The NEWEST card sits nearest the corner and older ones stack upward, so a new toast never
	/// pushes the one being read out from under the cursor.
	[Test]
	public static void CardsStackUpwardFromTheBottomRight()
	{
		let bed = scope WidgetBed();
		let host = Attach(bed);

		var older = ToastRequest("older");
		older.DurationSeconds = 0.0f;
		host.Show(older);

		var newest = ToastRequest("newest");
		newest.DurationSeconds = 0.0f;
		host.Show(newest);

		host.Measure(BoxConstraints.Tight(800.0f, 600.0f));
		host.Layout(0, 0, 800.0f, 600.0f);
		Test.Assert(host.Width == 800.0f, "the host fills the viewport");

		let olderCard = host.GetChildAt(0);
		let newestCard = host.GetChildAt(1);

		Test.Assert(Abs(olderCard.Bounds.X - (800.0f - host.CornerMargin - host.ToastWidth)) <= 0.01f);
		Test.Assert(Abs(newestCard.Bounds.X - olderCard.Bounds.X) <= 0.01f);
		Test.Assert(newestCard.Bounds.Y > olderCard.Bounds.Y);
		Test.Assert(Abs((newestCard.Bounds.Y + newestCard.Height) - (600.0f - host.CornerMargin))
			<= 0.01f);
	}
}
