using System;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A root 400 by 300 with a red box at (20, 30), 50 by 40, and a blue one at (200, 200), 60 by 20.
/// The root (and its tree) goes with it.
class DamageScreen
{
	public SceneRoot Root = SceneFixtures.NewScene(400.0f, 300.0f) ~ _.ReleaseRef();
	public UIWidget Box = new .() ~ _.ReleaseRef();
	public UIWidget Other = new .() ~ _.ReleaseRef();

	public this()
	{
		Box.Position = .(20.0f, 30.0f);
		Box.Size = .(50.0f, 40.0f);
		Box.SetBox(FilledBox(.(1.0f, 0.0f, 0.0f, 1.0f), scope NodeBox()));
		Other.Position = .(200.0f, 200.0f);
		Other.Size = .(60.0f, 20.0f);
		Other.SetBox(FilledBox(.(0.0f, 0.0f, 1.0f, 1.0f), scope NodeBox()));
		Root.AddChild(Box);
		Root.AddChild(Other);
	}

	/// A frame: laid out and drawn; the bounds of what it damaged.
	public Rect Frame()
	{
		Root.UpdateLayout();
		let canvas = scope VGContext();
		let dc = scope DrawContext(canvas);
		Root.DrawFrame(dc);
		return Root.LastDamageBounds;
	}
}

/// Damage: a frame notes the area it changed, in device pixels, for a host that presents part of
/// a frame: all of it at first, nothing when nothing changed, a box's area when it changes, both
/// places when a box moves, and where a box showed when it is removed or hidden.
class DamageTests
{
	private static bool Covers(Rect outer, Rect inner) =>
		(outer.X <= inner.X) && (outer.Y <= inner.Y) && (outer.Right >= inner.Right) && (outer.Bottom >= inner.Bottom);

	[Test]
	public static void AllAtFirstNothingWhenNothingChangedABoxsAreaWhenItChanges()
	{
		let w = scope DamageScreen();
		let first = w.Frame();
		Test.Assert(Covers(first, .(0.0f, 0.0f, 400.0f, 300.0f)));
		w.Frame();
		Test.Assert(w.Root.LastDamage.IsEmpty);

		w.Box.SetBox(FilledBox(.(0.0f, 1.0f, 0.0f, 1.0f), scope NodeBox())); // a colour: its own box alone
		let changed = w.Frame();
		Test.Assert(Covers(changed, .(20.0f, 30.0f, 50.0f, 40.0f)));
		Test.Assert(changed.Width <= 51.0f);
		Test.Assert(changed.Height <= 41.0f);
	}

	[Test]
	public static void ABoxMovedDamagesWhereItWasAndWhereItIsOneRemovedOrHiddenWhereItWas()
	{
		let w = scope DamageScreen();
		w.Frame();
		w.Box.Position = .(120.0f, 30.0f);
		let moved = w.Frame();
		Test.Assert(Covers(moved, .(20.0f, 30.0f, 50.0f, 40.0f)));
		Test.Assert(Covers(moved, .(120.0f, 30.0f, 50.0f, 40.0f)));
		Test.Assert(!Covers(moved, .(200.0f, 200.0f, 60.0f, 20.0f))); // the other box is not

		w.Other.Visible = false;
		let hidden = w.Frame();
		Test.Assert(Covers(hidden, .(200.0f, 200.0f, 60.0f, 20.0f)));
		Test.Assert(hidden.X >= 199.0f);

		w.Root.RemoveChild(w.Box);
		let removed = w.Frame();
		Test.Assert(Covers(removed, .(120.0f, 30.0f, 50.0f, 40.0f)));
	}

	[Test]
	public static void InDevicePixelsAtTheDisplaysScale()
	{
		let w = scope DamageScreen();
		w.Root.DisplayScale = 2.0f;
		w.Frame();
		w.Box.SetBox(FilledBox(.(0.0f, 1.0f, 0.0f, 1.0f), scope NodeBox()));
		let changed = w.Frame();
		Test.Assert(Covers(changed, .(40.0f, 60.0f, 100.0f, 80.0f)));
	}
}
