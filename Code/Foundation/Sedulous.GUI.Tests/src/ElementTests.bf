using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Elements by weak reference: a freed slot taken again answers under a new generation only, and
/// each GUI keeps a table of its own, its references gone with it. (Raptor's registry and markup
/// tests here come with the script surface and markup.)
class ElementTests
{
	[Test]
	public static void AFreedSlotTakenByANewElementDoesNotAnswerToTheOldReference()
	{
		let gui = SceneFixtures.NewScene();
		defer gui.ReleaseRef();
		let first = new Label();
		gui.AddChild(first);
		let old = scope Element<Label>(first);
		let firstRef = first.TakeElementRef();
		gui.RemoveChild(first);
		first.ReleaseRef();

		let second = new Label();
		defer second.ReleaseRef();
		gui.AddChild(second);
		let fresh = scope Element<Label>(second);
		let secondRef = second.TakeElementRef();
		Test.Assert(secondRef.Slot == firstRef.Slot); // the slot is reused...
		Test.Assert(secondRef.Generation != firstRef.Generation); // ...under a new generation
		Test.Assert(!old.IsValid);
		Test.Assert(fresh.Get() == second);
	}

	[Test]
	public static void TwoGUIsKeepTheirOwnTablesAndAGUIGoingLeavesItsReferencesGone()
	{
		var a = SceneFixtures.NewScene();
		let b = SceneFixtures.NewScene();
		defer b.ReleaseRef();
		Test.Assert(a.ElementTable != b.ElementTable);
		let inA = new Label();
		defer inA.ReleaseRef();
		let inB = new Label();
		defer inB.ReleaseRef();
		a.AddChild(inA);
		b.AddChild(inB);
		let weakA = scope Element<Label>(inA);
		let weakB = scope Element<Label>(inB);
		Test.Assert(inA.TakeElementRef().Table == a.ElementTable);
		Test.Assert(inB.TakeElementRef().Table == b.ElementTable);

		// A's GUI goes while its label lives on elsewhere and a reference to it is held: the table
		// closes (held alive by the reference), so the reference reads as gone; B is untouched.
		a.ReleaseRef();
		a = null;
		Test.Assert(!weakA.IsValid);
		Test.Assert(weakB.Get() == inB);
	}
}
