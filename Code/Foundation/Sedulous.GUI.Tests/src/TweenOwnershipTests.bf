using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Who holds a tween: the caller alone once made, the manager beside it while it runs, the caller
/// alone again once it ends.
class TweenOwnershipTests
{
	[Test]
	public static void ACreatedTweenIsTheCallersARunningOneTheManagersTooUntilItEnds()
	{
		let bed = scope TweenBed("box { opacity: 1; }");

		// Made: the caller's reference alone.
		let tween = bed.Widget.CreateTween("opacity", "0", 1.0f, "linear");
		defer tween.ReleaseRef();
		Test.Assert(tween.RefCount == 1);
		bed.Widget.RunAction(tween);
		Test.Assert(tween.RefCount == 2); // and the manager's, while it runs
		bed.Frame(0.5);
		Test.Assert(tween.RefCount == 2);
		bed.Frame(0.5);
		Test.Assert(tween.IsDone);
		Test.Assert(tween.RefCount == 1); // the manager's went at its end

		// Animate hands back a running one; a spring taking its property replaces it, and the
		// manager lets go of it at the next frame.
		let animated = bed.Widget.Animate("opacity", "0.5", 1.0f);
		defer animated.ReleaseRef();
		Test.Assert(animated.RefCount == 2);
		let spring = bed.Widget.SpringTo("opacity", "0");
		defer spring.ReleaseRef();
		Test.Assert(spring.RefCount == 2);
		bed.Frame(0.0);
		Test.Assert(animated.IsDone);
		Test.Assert(animated.RefCount == 1);
		// A spring already moving is handed back again, a reference for each caller.
		let again = bed.Widget.SpringTo("opacity", "1");
		Test.Assert(again == spring);
		Test.Assert(spring.RefCount == 3);
		again.ReleaseRef();
		Test.Assert(spring.RefCount == 2);

		// Play: the caller keeps its reference, the manager takes its own until the group ends.
		let group = new TweenSequence();
		defer group.ReleaseRef();
		bed.Widget.Play(group);
		Test.Assert(group.RefCount == 2);
		bed.Frame(0.0); // no steps: it ends at its first frame
		Test.Assert(group.IsDone);
		Test.Assert(group.RefCount == 1);
	}
}
