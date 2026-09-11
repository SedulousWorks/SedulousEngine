using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// The toolkit's toast stack. Deliberately parallel to the game kit's suite, because the two
/// hosts are a deliberate duplicate and must stay in step.
class ToastHostTests
{
	private static bool Near(float a, float b, float tolerance = 0.01f) => Abs(a - b) <= tolerance;

	[Test]
	public static void ATimedToastExpiresAndAStickyOneDoesNot()
	{
		let host = new ToastHost();
		defer host.ReleaseRef();

		Test.Assert(!host.IsHitTestVisible, "the host passes input through outside its cards");

		var timed = ToastRequest("Saved");
		timed.DurationSeconds = 1.0f;
		let timedId = host.Show(timed);

		var sticky = ToastRequest("Error", .Error);
		sticky.DurationSeconds = 0.0f;
		let stickyId = host.Show(sticky);

		Test.Assert(host.ToastCount == 2);

		host.Update(0.5f);
		Test.Assert(host.Contains(timedId));

		host.Update(0.6f);
		Test.Assert(!host.Contains(timedId));
		Test.Assert(host.Contains(stickyId), "a sticky toast ignores time entirely");
		Test.Assert(host.ToastCount == 1);

		host.Dismiss(stickyId);
		host.Update(0.0f);
		Test.Assert(!host.Contains(stickyId));
	}

	[Test]
	public static void AnActionToastFiresItsCallbackAndThenCloses()
	{
		let host = new ToastHost();
		defer host.ReleaseRef();

		var fired = false;
		var request = ToastRequest("Deleted");
		request.DurationSeconds = 0.0f;
		request.ActionLabel = "Undo";
		request.OnAction = new [&]() => { fired = true; };
		let id = host.Show(request);

		let card = host.GetChildAt(0) as ViewGroup;
		Test.Assert(card != null);
		Test.Assert(card.ChildCount == 3, "the message, the action and the close cross");

		let action = card.GetChildAt(1) as ButtonBase;
		Test.Assert(action != null);
		action.FireClick();
		Test.Assert(fired);

		host.Update(0.0f);
		Test.Assert(!host.Contains(id));
	}

	[Test]
	public static void TheCloseButtonDismissesWithoutFiringTheAction()
	{
		let host = new ToastHost();
		defer host.ReleaseRef();

		var fired = false;
		var request = ToastRequest("Deleted");
		request.DurationSeconds = 0.0f;
		request.ActionLabel = "Undo";
		request.OnAction = new [&]() => { fired = true; };
		let id = host.Show(request);

		let card = host.GetChildAt(0) as ViewGroup;
		let close = card.GetChildAt(2) as ButtonBase;
		Test.Assert(close != null);
		close.FireClick();

		host.Update(0.0f);
		Test.Assert(!host.Contains(id));
		Test.Assert(!fired, "closing is not undoing");
	}

	/// The NEWEST card sits nearest the corner and older ones stack upward, so a new toast never
	/// pushes the one being read out from under the cursor.
	[Test]
	public static void CardsStackUpwardFromTheBottomRight()
	{
		let host = new ToastHost();
		defer host.ReleaseRef();

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

		Test.Assert(Near(olderCard.Bounds.X, 800.0f - host.CornerMargin - host.ToastWidth));
		Test.Assert(Near(newestCard.Bounds.X, olderCard.Bounds.X));
		Test.Assert(newestCard.Bounds.Y > olderCard.Bounds.Y);
		Test.Assert(Near(newestCard.Bounds.Y + newestCard.Height, 600.0f - host.CornerMargin));
	}
}
