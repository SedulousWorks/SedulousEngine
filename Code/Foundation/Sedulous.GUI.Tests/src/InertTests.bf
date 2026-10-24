using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

// Inert subtrees (HTML's `inert`): an inert node and what it holds draw but take no pointer, focus,
// navigation, keys or commands, and let go of what the dispatcher held in them; made live again,
// they take input again.

/// A "lower" screen with a button, and an "upper" button beside it. The root and the tree go with
/// it.
class InertBed
{
	public SceneRoot Root = SceneFixtures.NewScene(400.0f, 300.0f) ~ _.ReleaseRef();
	public UIWidget Lower = new .() ~ _.ReleaseRef();
	public Button LowerButton = new .() ~ _.ReleaseRef();
	public Button UpperButton = new .() ~ _.ReleaseRef();

	public this()
	{
		Lower.Size = .(200.0f, 300.0f);
		Root.AddChild(Lower);
		LowerButton.Size = .(80.0f, 30.0f);
		Lower.AddChild(LowerButton);
		UpperButton.Position = .(0.0f, 100.0f);
		UpperButton.Size = .(80.0f, 30.0f);
		Root.AddChild(UpperButton);
		Root.UpdateLayout();
	}

	public EventDispatcher D => Root.EventDispatcher;
}

/// Inert: no pointer, focus, navigation or commands in it, and what was held there let go.
class InertTests
{
	[Test]
	public static void WhatItHoldsTakesNoPointerFocusOrNavigationAndLetsGoOfTheFocusAndAPress()
	{
		let bed = scope InertBed();
		bed.D.FocusNode = bed.LowerButton;
		bed.D.InjectMouseDown(.(10.0f, 10.0f), .Left); // a press held on it
		int clicks = 0;
		bed.LowerButton.SetOnClick(new [&] () => { clicks++; });
		bed.Lower.SetInert(true);
		Test.Assert(bed.LowerButton.IsTreeInert);
		Test.Assert(bed.D.FocusNode == null);
		bed.D.InjectMouseUp(.(10.0f, 10.0f), .Left);
		Test.Assert(clicks == 0); // the press it held was let go
		Test.Assert(bed.Root.OverFind(.(10.0f, 10.0f)) != bed.LowerButton);
		bed.LowerButton.RequestFocus();
		Test.Assert(bed.D.FocusNode == null);
		bed.D.MoveFocus(.Down);
		Test.Assert(bed.D.FocusNode == bed.UpperButton); // navigation finds only what is live
		bed.D.MoveFocus(.Up);
		Test.Assert(bed.D.FocusNode == bed.UpperButton);

		bed.Lower.SetInert(false);
		bed.D.InjectMouseDown(.(10.0f, 10.0f), .Left);
		bed.D.InjectMouseUp(.(10.0f, 10.0f), .Left);
		Test.Assert(clicks == 1);
	}

	[Test]
	public static void CommandsAndBindingsOnTheFocusPathSkipIt()
	{
		let bed = scope InertBed();
		int ran = 0;
		bed.Lower.OnCommand("test.cmd", new [&] (command) => { ran++; });
		bed.D.FocusNode = bed.LowerButton;
		Test.Assert(bed.Root.RunCommand("test.cmd"));
		Test.Assert(ran == 1);
		bed.Lower.SetInert(true);
		Test.Assert(!bed.Root.RunCommand("test.cmd"));
		Test.Assert(ran == 1);
	}
}
