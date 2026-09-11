using System;
using Sedulous.Core;
using Sedulous.Shell;
using Sedulous.Shell.Null;
using Sedulous.UI;
using Sedulous.UI.Shell;

namespace Sedulous.UI.Shell.Tests;

/// The platform input bridge: synthetic shell events driven into a real UIContext.
class UIInputBridgeTests
{
	/// Records the last key it was given, so the mapping can be observed from the UI side
	/// rather than by inspecting the translation directly.
	private class KeyProbe : View
	{
		public Sedulous.UI.KeyCode Last = .Unknown;

		public this()
		{
			IsFocusable = true;
		}

		public override void OnKeyDown(KeyEventArgs e)
		{
			Last = e.Key;
			e.Handled = true;
		}
	}

	/// A window that only records whether text input is running.
	private class MockWindow : IWindow
	{
		public bool TextInputRunning = false;

		public uint32 Id => 1;
		public uint32 Width => 800;
		public uint32 Height => 600;
		public int32 X => 0;
		public int32 Y => 0;
		public float ContentScale => 1.0f;
		public bool IsOpen => true;
		public bool IsMinimized => false;
		public NativeWindow Native => .();

		public void SetPosition(int32 x, int32 y) {}
		public void SetSize(uint32 width, uint32 height) {}
		public void Close() {}

		public void StartTextInput() => TextInputRunning = true;
		public void StopTextInput() => TextInputRunning = false;
		public bool IsTextInputActive => TextInputRunning;
	}

	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		root.ViewportSize = .(800, 600);
		context.AddRootView(root);
	}

	private static void LayoutPass(UIContext context, RootView root)
	{
		context.BeginFrame(0.016f);
		context.UpdateRootView(root);
	}

	private static InputEvent KeyDown(Sedulous.Shell.KeyCode key)
	{
		var e = InputEvent();
		e.Kind = .KeyDown;
		e.Key = key;
		return e;
	}

	// ---- Routing ------------------------------------------------------------------------------

	/// A click focuses what it hits, and the text that follows reaches it: the whole path from
	/// a platform event to a character in a field.
	[Test]
	public static void AClickFocusesAndTypingReachesTheField()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let edit = new EditText();
		root.AddView(edit);
		LayoutPass(context, root);

		let bridge = scope UIInputBridge(context);

		var click = InputEvent();
		click.Kind = .MouseButtonDown;
		click.Button = .Left;
		click.X = 10;
		click.Y = 10;
		Test.Assert(bridge.Dispatch(click));
		Test.Assert(context.WantsTextInput(), "an editable field took focus");

		var text = InputEvent();
		text.Kind = .TextInput;
		text.Text[0] = 'h';
		text.Text[1] = 'i';
		text.Text[2] = 0;
		Test.Assert(bridge.Dispatch(text));

		Test.Assert(edit.Text == "hi");
	}

	/// What the UI does not use is NOT routed, and says so, so a caller can pass the event on
	/// to whatever else wants it.
	[Test]
	public static void WhatTheUIDoesNotUseIsNotRouted()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let bridge = scope UIInputBridge(context);

		var pad = InputEvent();
		pad.Kind = .GamepadButtonDown;

		Test.Assert(!bridge.Dispatch(pad));
	}

	// ---- Text input follows focus ---------------------------------------------------------

	/// The platform's text input follows FOCUS, which is the only thing that knows when it
	/// should be running. A read-only field does not want it, and neither does nothing at all.
	[Test]
	public static void ThePlatformsTextInputFollowsFocus()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let readOnly = new EditText();
		readOnly.IsReadOnly.Value = true;
		root.AddView(readOnly);

		let editable = new EditText();
		root.AddView(editable);
		LayoutPass(context, root);

		let window = scope MockWindow();
		let bridge = scope UIInputBridge(context);
		bridge.SetTextInputTarget(window);

		context.GetFocusManager().SetFocus(editable);
		bridge.SyncTextInput();
		Test.Assert(window.TextInputRunning);

		context.GetFocusManager().SetFocus(readOnly);
		bridge.SyncTextInput();
		Test.Assert(!window.TextInputRunning, "read only wants no composition");

		context.GetFocusManager().SetFocus(editable);
		bridge.SyncTextInput();
		Test.Assert(window.TextInputRunning);

		context.GetFocusManager().ClearFocus();
		bridge.SyncTextInput();
		Test.Assert(!window.TextInputRunning, "nothing focused wants none either");
	}

	/// With no target window the sync is simply inert, so a host that never wired one up is
	/// not a crash.
	[Test]
	public static void WithNoTargetWindowTheSyncIsInert()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let bridge = scope UIInputBridge(context);
		bridge.SyncTextInput();
	}

	// ---- Key mapping --------------------------------------------------------------------------

	/// The contiguous ranges map arithmetically, so a gap in one of them would show here.
	///
	/// A REGRESSION GATE: the function keys were once unmapped and answered Unknown, so F2 to
	/// rename never reached the UI at all.
	[Test]
	public static void TheFunctionKeysAndTheDigitRowMapThrough()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let probe = new KeyProbe();
		root.AddView(probe);
		context.GetFocusManager().SetFocus(probe);

		let bridge = scope UIInputBridge(context);

		bridge.Dispatch(KeyDown(.F2));
		Test.Assert(probe.Last == .F2);

		bridge.Dispatch(KeyDown(.F12));
		Test.Assert(probe.Last == .F12);

		bridge.Dispatch(KeyDown(.F24));
		Test.Assert(probe.Last == .F24);

		// The digit row runs 1 to 9 then 0, which is the keyboard's order not the number's.
		bridge.Dispatch(KeyDown(.Num5));
		Test.Assert(probe.Last == .Num5);

		bridge.Dispatch(KeyDown(.Num0));
		Test.Assert(probe.Last == .Num0);

		bridge.Dispatch(KeyDown(.A));
		Test.Assert(probe.Last == .A);

		bridge.Dispatch(KeyDown(.Z));
		Test.Assert(probe.Last == .Z);

		bridge.Dispatch(KeyDown(.Delete));
		Test.Assert(probe.Last == .Delete);
	}

	/// The keypad's enter is the same as the main one: both mean CONFIRM to a control, and a
	/// field committing on one but not the other would be baffling.
	[Test]
	public static void TheKeypadsEnterIsAnEnter()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let probe = new KeyProbe();
		root.AddView(probe);
		context.GetFocusManager().SetFocus(probe);

		let bridge = scope UIInputBridge(context);
		bridge.Dispatch(KeyDown(.KeypadEnter));

		Test.Assert(probe.Last == .Return);
	}

	/// The punctuation row maps, because editors bind chords on it.
	[Test]
	public static void ThePunctuationRowMapsForChords()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let probe = new KeyProbe();
		root.AddView(probe);
		context.GetFocusManager().SetFocus(probe);

		let bridge = scope UIInputBridge(context);

		bridge.Dispatch(KeyDown(.Slash));
		Test.Assert(probe.Last == .Slash, "Ctrl and slash is comment toggle");

		bridge.Dispatch(KeyDown(.LeftBracket));
		Test.Assert(probe.Last == .LeftBracket);

		bridge.Dispatch(KeyDown(.Grave));
		Test.Assert(probe.Last == .Grave);
	}

	// ---- Clipboard ----------------------------------------------------------------------------

	[Test]
	public static void TheClipboardBridgesThePlatforms()
	{
		let shell = scope NullShell();
		let clipboard = scope ShellClipboard(shell);

		Test.Assert(!clipboard.HasText);
		Test.Assert(clipboard.SetText("hello") case .Ok);
		Test.Assert(clipboard.HasText);

		let text = scope String();
		Test.Assert(clipboard.GetText(text) case .Ok);
		Test.Assert(text == "hello");
	}

	/// No shell fails gracefully rather than crashing: a UI with no platform wired is a normal
	/// state during startup and in tests.
	[Test]
	public static void TheClipboardWithNoShellIsGraceful()
	{
		let clipboard = scope ShellClipboard(null);

		Test.Assert(!clipboard.HasText);
		Test.Assert(clipboard.SetText("x") case .Err);

		let text = scope String();
		Test.Assert(clipboard.GetText(text) case .Err);
	}
}
