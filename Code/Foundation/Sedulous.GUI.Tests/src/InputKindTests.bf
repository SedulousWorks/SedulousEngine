using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

// The input kind: what drives the GUI now (the pointer, the keys, a pad), from what reaches it or a
// host's word; the focus ring, the cursor and a sheet's @media (input: ...) follow it.

/// A GUI with a focused button. The root and the tree go with it.
class KindBed
{
	public SceneRoot Root = SceneFixtures.NewScene(400.0f, 300.0f) ~ _.ReleaseRef();
	public Button Focused = new .() ~ _.ReleaseRef();

	public this()
	{
		Focused.Size = .(80.0f, 30.0f);
		Root.AddChild(Focused);
		Root.UpdateLayout();
		D.FocusNode = Focused;
	}

	public EventDispatcher D => Root.EventDispatcher;

	/// A press and its release at `at`.
	public void Click(Float2 at)
	{
		D.InjectMouseDown(at, .Left);
		D.InjectMouseUp(at, .Left);
	}

	/// A press and its release on the backdrop.
	public void Click() => Click(.(300.0f, 200.0f));
}

/// The input kind, what follows it, and how a sheet reads it.
class InputKindTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	[Test]
	public static void TheKeysUntilThePointerIsUsedAPressAKeyAPadButtonAndAPadDirectionEachSayTheirs()
	{
		let bed = scope KindBed();
		Test.Assert(bed.D.InputKind == .Keyboard);
		Test.Assert(bed.Focused.FocusVisible);
		bed.Click();
		Test.Assert(bed.D.InputKind == .Pointer);
		bed.D.FocusNode = bed.Focused;
		Test.Assert(!bed.Focused.FocusVisible); // the ring hides under the pointer
		bed.D.InjectKeyDown((uint32)KeyCode.Tab);
		Test.Assert(bed.D.InputKind == .Keyboard);
		bed.D.InjectPadButton(.West);
		Test.Assert(bed.D.InputKind == .Pad);
		Test.Assert(bed.D.IsUsingKeyboard); // a pad drives as the keys do
		bed.Click();
		bed.D.PressDirection(.Down);
		bed.D.ReleaseDirection(.Down);
		Test.Assert(bed.D.InputKind == .Pad);
		Test.Assert(bed.Focused.FocusVisible);
	}

	[Test]
	public static void ThePadsEastStandingInForEscapeIsStillThePad()
	{
		let bed = scope KindBed();
		bed.Root.Context.Keymap.Bind("pad-east", ""); // nothing takes it as back
		bed.D.InjectPadButton(.East);
		Test.Assert(bed.D.InputKind == .Pad);
	}

	[Test]
	public static void AHostsWordSetsItTheRootHearsEachChangeOnceAndABindingFollowsIt()
	{
		let bed = scope KindBed();
		let heard = scope List<InputKind>();
		bed.Root.AddEventListener(.InputKindChanged, new [&] (e) => { heard.Add(bed.Root.EventDispatcher.InputKind); });
		let shown = scope String();
		let dispatcher = bed.D;
		bed.Focused.Bind(new [&] () => { shown.Set(InputKindName(dispatcher.ObserveInputKind())); });
		bed.Root.Context.Update(TimeSpan(0));
		Test.Assert(shown == "keyboard");

		bed.D.InputKind = .Pad; // a stick pushed, which reaches no widget
		bed.D.InputKind = .Pad;
		bed.Root.Context.Update(TimeSpan(0));
		Test.Assert(shown == "pad");
		bed.D.InputKind = .Pointer; // a mouse moved
		Test.Assert(heard.Count == 2);
		Test.Assert(heard[0] == .Pad);
		Test.Assert(heard[1] == .Pointer);
		Test.Assert(!bed.Focused.FocusVisible);
	}

	[Test]
	public static void APadHidesTheCursorThePointerBringsItBackCursorNoneHidesItAnywhere()
	{
		let bed = scope KindBed();
		bed.Focused.Cursor = .Pointer;
		bed.D.InjectMouseMove(.(10.0f, 10.0f));
		Test.Assert(bed.D.Cursor == .Pointer);
		bed.D.InputKind = .Pad;
		Test.Assert(bed.D.Cursor == .None);
		bed.D.InputKind = .Pointer;
		Test.Assert(bed.D.Cursor == .Pointer);
		Test.Assert(CursorNamed("none") == .None);
		Test.Assert(CursorName(.None) == "none");
		bed.Focused.CursorName = "none";
		Test.Assert(bed.D.Cursor == .None);
	}

	[Test]
	public static void ASheetReadsItAsMediaInputRestylingWhenItChanges()
	{
		let bed = scope KindBed();
		bed.Focused.AddClass("hint");
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles,
			".hint { opacity: 1; } @media (input: pad) { .hint { opacity: 0.25; } } @media (input: pointer) { .hint { opacity: 0.5; } }");
		void Frame()
		{
			styles.MediaContext = bed.Root.MediaContext;
			styles.ApplyTree(bed.Root);
		}
		Frame();
		Test.Assert(Near(bed.Focused.Alpha, 1.0f)); // the keys: neither
		bed.D.InputKind = .Pad;
		Frame();
		Test.Assert(Near(bed.Focused.Alpha, 0.25f));
		bed.D.InputKind = .Pointer;
		Frame();
		Test.Assert(Near(bed.Focused.Alpha, 0.5f));
		var keys = MediaContext(100.0f, 100.0f, 96.0f);
		keys.Input = .Keyboard;
		let keyboard = scope MediaQuery("(input: keyboard)");
		Test.Assert(keyboard.Evaluate(keys));
		let mouse = scope MediaQuery("(input: mouse)");
		Test.Assert(!mouse.Evaluate(MediaContext())); // a value it does not know matches nothing
	}
}
