using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Shell.Tests;

/// GuiInputBridge: synthetic platform InputEvents translated into EventDispatcher injections
/// (hover, click, key, text, pad, touch, drops), the enums mapped, a ContentFit applied; and
/// ShellClipboard over a shell's clipboard.
class BridgeTests
{
	private static bool Near(float a, float b) => BridgeFixtures.Near(a, b);

	[Test]
	public static void MouseMoveDrivesHover()
	{
		let root = BridgeFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let child = BridgeFixtures.NewPanel(.(10.0f, 10.0f), .(50.0f, 50.0f));
		defer child.ReleaseRef();
		root.AddChild(child);
		let bridge = scope GuiInputBridge(root.EventDispatcher);

		int enter = 0;
		child.AddEventListener(.MouseEnter, new [&] (e) => { enter++; });

		Test.Assert(!bridge.Dispatch(BridgeFixtures.MouseMove(20.0f, 20.0f))); // a bare panel leaves the pointer to the game
		Test.Assert(root.EventDispatcher.OverNode == child);
		Test.Assert(enter == 1);
	}

	[Test]
	public static void LeftPressAndReleaseBecomeAClickButtonMappingIsExplicit()
	{
		let root = BridgeFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let child = BridgeFixtures.NewPanel(.(0.0f, 0.0f), .(100.0f, 100.0f));
		defer child.ReleaseRef();
		child.TabFocusable = true; // a click focuses what takes focus
		root.AddChild(child);
		let bridge = scope GuiInputBridge(root.EventDispatcher);

		int clicks = 0;
		Sedulous.GUI.MouseButton downButton = .Left;
		child.AddEventListener(.MouseClick, new [&] (e) => { clicks++; });
		child.AddEventListener(.MouseDown, new [&] (e) => { downButton = ((MouseEvent)e).Button; });

		// Only the left button activates (right/middle deliver Down/Up for context menus but never
		// click).
		bridge.Dispatch(BridgeFixtures.ButtonEvent(.MouseButtonDown, 20.0f, 20.0f, .Left));
		bridge.Dispatch(BridgeFixtures.ButtonEvent(.MouseButtonUp, 20.0f, 20.0f, .Left));
		Test.Assert(clicks == 1);
		Test.Assert(root.EventDispatcher.FocusNode == child);

		// The shell's Middle (index 1) maps to the GUI's Middle (index 2) - explicitly, not by value.
		bridge.Dispatch(BridgeFixtures.ButtonEvent(.MouseButtonDown, 20.0f, 20.0f, .Middle));
		Test.Assert(downButton == .Middle);
		bridge.Dispatch(BridgeFixtures.ButtonEvent(.MouseButtonUp, 20.0f, 20.0f, .Middle));
		Test.Assert(clicks == 1); // still 1: the middle press did not add a click
	}

	[Test]
	public static void KeyAndTextRouteToTheFocusNodeWithMappedModifiers()
	{
		let root = BridgeFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let child = BridgeFixtures.NewPanel(.(0.0f, 0.0f), .(100.0f, 100.0f));
		defer child.ReleaseRef();
		root.AddChild(child);
		let bridge = scope GuiInputBridge(root.EventDispatcher);
		root.EventDispatcher.FocusNode = child;

		uint32 seenMods = 0;
		// A copy of the text: the event's Text views the dispatched InputEvent's buffer.
		let seenText = scope String();
		child.AddEventListener(.KeyDown, new [&] (e) => { seenMods = ((KeyEvent)e).Modifiers; });
		child.AddEventListener(.TextInput, new [&] (e) => { seenText.Set(((TextInputEvent)e).Text); });

		bridge.Dispatch(BridgeFixtures.Key(.KeyDown, .A, .LeftCtrl));
		bridge.Dispatch(BridgeFixtures.TextEvent("hi"));
		Test.Assert((seenMods & KeyModCtrl) != 0);
		Test.Assert(seenText == "hi");
	}

	[Test]
	public static void NavigationKeysMapPlatformKeyCodeToTheGUIKeyCode()
	{
		let root = BridgeFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let child = BridgeFixtures.NewPanel(.(0.0f, 0.0f), .(100.0f, 100.0f));
		defer child.ReleaseRef();
		root.AddChild(child);
		let bridge = scope GuiInputBridge(root.EventDispatcher);
		root.EventDispatcher.FocusNode = child;

		uint32 seenKey = 0xFFFFFFFF;
		child.AddEventListener(.KeyDown, new [&] (e) => { seenKey = ((KeyEvent)e).KeyCode; });

		bridge.Dispatch(BridgeFixtures.Key(.KeyDown, .Backspace));
		Test.Assert(seenKey == (uint32)KeyCode.Backspace);
		bridge.Dispatch(BridgeFixtures.Key(.KeyDown, .Left));
		Test.Assert(seenKey == (uint32)KeyCode.Left);
		bridge.Dispatch(BridgeFixtures.Key(.KeyDown, .Home));
		Test.Assert(seenKey == (uint32)KeyCode.Home);

		// The editing-shortcut letters map through so Ctrl+A/C/V/X reach widgets.
		bridge.Dispatch(BridgeFixtures.Key(.KeyDown, .A));
		Test.Assert(seenKey == (uint32)KeyCode.A);
		bridge.Dispatch(BridgeFixtures.Key(.KeyDown, .V));
		Test.Assert(seenKey == (uint32)KeyCode.V);

		// Every letter, digit and F1 to F12 maps through, for bindings (ctrl-s, f5); what a key
		// types still arrives as text, not from its code.
		bridge.Dispatch(BridgeFixtures.Key(.KeyDown, .B));
		Test.Assert(seenKey == (uint32)KeyCode.B);
		bridge.Dispatch(BridgeFixtures.Key(.KeyDown, .Num7));
		Test.Assert(seenKey == (uint32)KeyCode.Num7);
		bridge.Dispatch(BridgeFixtures.Key(.KeyDown, .F5));
		Test.Assert(seenKey == (uint32)KeyCode.F5);
		// The rest of the keyboard too: punctuation, the keypad apart from the digits, F13 to F24,
		// the lock keys and the modifier keys themselves.
		Sedulous.Shell.KeyCode[13] fromKeys = .(.F13, .F24, .Minus, .Slash, .Grave, .Keypad5, .KeypadEnter,
			.KeypadDecimal, .CapsLock, .Pause, .Menu, .LeftShift, .RightGui);
		KeyCode[13] toKeys = .(.F13, .F24, .Minus, .Slash, .Grave, .Keypad5, .KeypadEnter,
			.KeypadDecimal, .CapsLock, .Pause, .Menu, .LeftShift, .RightSuper);
		for (int i = 0; i < fromKeys.Count; i++)
		{
			bridge.Dispatch(BridgeFixtures.Key(.KeyDown, fromKeys[i]));
			Test.Assert(seenKey == (uint32)toKeys[i]);
		}
	}

	[Test]
	public static void TextInputTargetFollowsFocusOfAnEditableWidget()
	{
		let root = BridgeFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let field = new TextField();
		defer field.ReleaseRef();
		field.Size = .(100.0f, 24.0f); // covers (0,0)-(100,24)
		root.AddChild(field);

		let window = scope Sedulous.Shell.Null.NullWindow(1, .());
		let bridge = scope GuiInputBridge(root.EventDispatcher);
		bridge.SetTextInputTarget(window);

		Test.Assert(!window.IsTextInputActive);

		// Click the field -> focus -> the bridge enables the window's text input.
		bridge.Dispatch(BridgeFixtures.ButtonEvent(.MouseButtonDown, 10.0f, 10.0f, .Left));
		Test.Assert(root.EventDispatcher.FocusNode == field);
		Test.Assert(window.IsTextInputActive);

		// Click off the field (onto the non-editable root) -> focus leaves -> text input disabled.
		bridge.Dispatch(BridgeFixtures.ButtonEvent(.MouseButtonDown, 150.0f, 150.0f, .Left));
		Test.Assert(root.EventDispatcher.FocusNode != field);
		Test.Assert(!window.IsTextInputActive);
	}

	[Test]
	public static void APasswordFieldStartsSecretTextInputAndAMoveToAPlainFieldSwitchesItBack()
	{
		let root = BridgeFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let password = new TextField();
		defer password.ReleaseRef();
		password.IsPassword = true;
		password.Size = .(100.0f, 24.0f); // covers (0,0)-(100,24)
		let field = new TextField();
		defer field.ReleaseRef();
		field.Position = .(0.0f, 50.0f);
		field.Size = .(100.0f, 24.0f);
		root.AddChild(password);
		root.AddChild(field);

		let window = scope Sedulous.Shell.Null.NullWindow(1, .());
		let bridge = scope GuiInputBridge(root.EventDispatcher);
		bridge.SetTextInputTarget(window);

		bridge.Dispatch(BridgeFixtures.ButtonEvent(.MouseButtonDown, 10.0f, 10.0f, .Left));
		Test.Assert(window.IsTextInputActive);
		Test.Assert(window.ActiveTextInputKind == .Secret); // the IME keeps out
		bridge.Dispatch(BridgeFixtures.ButtonEvent(.MouseButtonDown, 10.0f, 60.0f, .Left));
		Test.Assert(root.EventDispatcher.FocusNode == field);
		Test.Assert(window.IsTextInputActive);
		Test.Assert(window.ActiveTextInputKind == .Text);
	}

	[Test]
	public static void ContentFitMapsWindowPositionIntoContentSpace()
	{
		let root = BridgeFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let child = BridgeFixtures.NewPanel(.(10.0f, 10.0f), .(50.0f, 50.0f));
		defer child.ReleaseRef();
		root.AddChild(child);
		let bridge = scope GuiInputBridge(root.EventDispatcher);

		ContentFit fit = .();
		fit.Region = .(0.0f, 0.0f, 400.0f, 400.0f);
		fit.ContentSize = .(200.0f, 200.0f);
		fit.Mode = .Stretch;
		bridge.SetContentFit(fit);

		bridge.Dispatch(BridgeFixtures.MouseMove(40.0f, 40.0f)); // window (40,40) -> content (20,20), inside child
		Test.Assert(root.EventDispatcher.OverNode == child);
		Test.Assert(Near(root.EventDispatcher.MousePosition.X, 20.0f));
	}

	[Test]
	public static void UnroutableEventsReturnFalse()
	{
		let root = BridgeFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let bridge = scope GuiInputBridge(root.EventDispatcher);

		Sedulous.Shell.InputEvent touch = default; // no window size: a finger is not placed
		touch.Kind = .TouchDown;
		Test.Assert(!bridge.Dispatch(touch));
		Sedulous.Shell.InputEvent paddle = default; // a gamepad button the GUI does not take
		paddle.Kind = .GamepadButtonDown;
		paddle.PadButton = .LeftPaddle1;
		Test.Assert(!bridge.Dispatch(paddle));
	}

	[Test]
	public static void ShellClipboardAdaptsTheShellClipboardToTheGUIsIClipboardAndRoundTripsText()
	{
		let shell = scope Sedulous.Shell.Null.NullShell(); // in-memory clipboard backing
		let clipboard = scope ShellClipboard(shell);

		Test.Assert(!clipboard.HasText);
		clipboard.SetText("copied");
		Test.Assert(clipboard.HasText);
		let text = scope String();
		clipboard.GetText(text);
		Test.Assert(text == "copied");
		let inShell = scope String();
		shell.GetClipboardText(inShell);
		Test.Assert(inShell == "copied"); // reached the shell

		// A null shell degrades safely (no crash, empty text).
		let none = scope ShellClipboard(null);
		Test.Assert(!none.HasText);
		let nothing = scope String();
		none.GetText(nothing);
		Test.Assert(nothing.Length == 0);
		none.SetText("ignored");
	}

	[Test]
	public static void PumpFromSurfaceCarriesKeyboardModifiersIntoAClick()
	{
		let root = BridgeFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let child = BridgeFixtures.NewPanel(.(0.0f, 0.0f), .(100.0f, 100.0f));
		defer child.ReleaseRef();
		root.AddChild(child);
		let bridge = scope GuiInputBridge(root.EventDispatcher);

		uint32 seenMods = 0;
		child.AddEventListener(.MouseDown, new [&] (e) => { seenMods = ((MouseEvent)e).Modifiers; });

		let manager = scope MockInputManager();
		manager.KeyboardMock.Mods = .LeftShift;
		manager.MouseMock.LeftPressed = true;

		let surface = scope Sedulous.Shell.InputSurface(manager, 1, ContentFit());
		// Gate the surface active (hovered + focused) with the content cursor over the child.
		surface.ApplyGate(true, true, false, .(10.0f, 10.0f), .(0.0f, 0.0f));

		bridge.PumpFromSurface(surface);
		Test.Assert((seenMods & KeyModShift) != 0); // Shift reached the widget via the poll path
	}

	[Test]
	public static void TheDPadAndTheLeftStickMoveFocusAButtonRunsItsBinding()
	{
		let root = BridgeFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let top = new Button();
		defer top.ReleaseRef();
		let bottom = new Button();
		defer bottom.ReleaseRef();
		top.Size = .(60.0f, 20.0f);
		bottom.Position = .(0.0f, 50.0f);
		bottom.Size = .(60.0f, 20.0f);
		root.AddChild(top);
		root.AddChild(bottom);
		let d = root.EventDispatcher;
		let bridge = scope GuiInputBridge(d);
		d.FocusNode = top;

		Test.Assert(bridge.Dispatch(BridgeFixtures.Pad(.GamepadButtonDown, .DPadDown)));
		Test.Assert(d.FocusNode == bottom);
		Test.Assert(d.IsHoldingDirection);
		Test.Assert(bridge.Dispatch(BridgeFixtures.Pad(.GamepadButtonUp, .DPadDown)));
		Test.Assert(!d.IsHoldingDirection);

		// The stick: past half way holds Up, a resting wobble near the threshold does not chatter.
		Test.Assert(bridge.Dispatch(BridgeFixtures.Stick(.LeftY, -0.8f)));
		Test.Assert(d.FocusNode == top);
		bridge.Dispatch(BridgeFixtures.Stick(.LeftY, -0.45f)); // still held (above release)
		Test.Assert(d.IsHoldingDirection);
		bridge.Dispatch(BridgeFixtures.Stick(.LeftY, -0.1f));
		Test.Assert(!d.IsHoldingDirection);

		// East through a binding.
		bool back = false;
		root.OnCommand("back", new [&] (command) => { back = true; });
		Test.Assert(root.Context.Keymap.Bind("pad-east", "back"));
		Test.Assert(bridge.Dispatch(BridgeFixtures.Pad(.GamepadButtonDown, .East)));
		Test.Assert(back);
	}

	[Test]
	public static void TheRightStickIsTheDispatchersScrollStickEachAxisAsItMoves()
	{
		let root = BridgeFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let d = root.EventDispatcher;
		let bridge = scope GuiInputBridge(d);
		Test.Assert(bridge.Dispatch(BridgeFixtures.Stick(.RightY, 0.7f)));
		Test.Assert(Near(d.ScrollStick.Y, 0.7f));
		Test.Assert(bridge.Dispatch(BridgeFixtures.Stick(.RightX, -0.3f)));
		Test.Assert(Near(d.ScrollStick.X, -0.3f));
		Test.Assert(Near(d.ScrollStick.Y, 0.7f)); // the other axis kept
		Test.Assert(!d.IsHoldingDirection); // it moves no focus
	}

	[Test]
	public static void AKeymapFilledFromTheGamesInputMapFollowsItsBindings()
	{
		let map = scope Sedulous.Input.InputMap();
		let menu = new Sedulous.Input.ActionSet();
		menu.Name.Set("Menu");
		let backAction = new Sedulous.Input.InputAction();
		backAction.Name.Set("Back");
		Sedulous.Input.Binding escape = .();
		escape.Source = .Key;
		escape.Code = (uint32)Sedulous.Shell.KeyCode.Escape;
		Sedulous.Input.Binding east = .();
		east.Source = .GamepadButton;
		east.Code = (uint32)Sedulous.Shell.GamepadButton.East;
		Sedulous.Input.Binding stick = .(); // an axis: not a keystroke, skipped
		stick.Source = .GamepadAxis;
		backAction.Bindings.Add(escape);
		backAction.Bindings.Add(east);
		backAction.Bindings.Add(stick);
		menu.Actions.Add(backAction);
		map.Sets.Add(menu);

		let root = BridgeFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		InputMapCommand[1] wanted = .(InputMapCommand("Back", "back"));
		Test.Assert(BindFromInputMap(root.Context.Keymap, map, Span<InputMapCommand>(&wanted[0], 1)) == 2);
		int backs = 0;
		root.OnCommand("back", new [&] (command) => { backs++; });
		let d = root.EventDispatcher;
		d.InjectKeyDown((uint32)KeyCode.Escape);
		d.InjectPadButton(.East);
		Test.Assert(backs == 2);
	}

	[Test]
	public static void TheCursorFollowsTheNodeUnderThePointerDispatchSaysWhetherTheGUIUsedIt()
	{
		let root = BridgeFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let field = new TextField();
		defer field.ReleaseRef();
		field.Size = .(100.0f, 24.0f);
		root.AddChild(field);
		field.Cursor = .Text;
		let bridge = scope GuiInputBridge(root.EventDispatcher);
		let mouse = scope MockMouse();
		bridge.SetCursorTarget(mouse);
		Test.Assert(bridge.Dispatch(BridgeFixtures.MouseMove(10.0f, 10.0f))); // over the field: the GUI's
		Test.Assert(mouse.Cursor == .Text);
		Test.Assert(!bridge.Dispatch(BridgeFixtures.MouseMove(150.0f, 150.0f))); // over nothing that takes it
		Test.Assert(mouse.Cursor == .Default);
		let sets = mouse.CursorSets;
		bridge.Dispatch(BridgeFixtures.MouseMove(160.0f, 150.0f));
		Test.Assert(mouse.CursorSets == sets); // unchanged: not set again
		Test.Assert(!bridge.IsPointerOverGui);
	}

	[Test]
	public static void TheHostsInputKindTrackerPassesEachChangeOnAndAPadHidesTheCursorItShowsAgain()
	{
		let root = BridgeFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let d = root.EventDispatcher;
		let bridge = scope GuiInputBridge(d);
		let mouse = scope MockMouse();
		bridge.SetCursorTarget(mouse);
		let tracker = scope Sedulous.Input.InputKindTracker(); // the host's, which it updates from its devices
		bridge.SetInputKindTracker(tracker);
		bridge.SyncCursor();
		Test.Assert(d.InputKind == .Keyboard); // its kind when attached is not passed

		tracker.SetKind(.Pad); // a stick pushed
		bridge.SyncCursor();
		Test.Assert(d.InputKind == .Pad);
		Test.Assert(!mouse.Visible);
		d.InjectMouseDown(.(10.0f, 10.0f), .Left); // a press the GUI is given says its own
		Test.Assert(d.InputKind == .Pointer);
		bridge.SyncCursor(); // the tracker has not changed: nothing passed over it
		Test.Assert(d.InputKind == .Pointer);
		Test.Assert(mouse.Visible);

		tracker.SetKind(.Keyboard);
		bridge.Dispatch(BridgeFixtures.MouseMove(20.0f, 20.0f));
		Test.Assert(d.InputKind == .Keyboard);
		Test.Assert(mouse.VisibilitySets == 2); // hidden once, shown once
	}

	[Test]
	public static void TouchEventsTapAButtonPlacedWithTheWindowsSizeSDLsMouseCopiesAreDropped()
	{
		let root = BridgeFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let button = new Button();
		defer button.ReleaseRef();
		button.Position = .(20.0f, 20.0f);
		button.Size = .(80.0f, 40.0f);
		root.AddChild(button);
		int clicks = 0;
		button.SetOnClick(new [&] () => { clicks++; });
		let bridge = scope GuiInputBridge(root.EventDispatcher);
		Test.Assert(!bridge.Dispatch(BridgeFixtures.Finger(.TouchDown, 3, 0.2f, 0.2f))); // no window size yet
		bridge.SetWindowSize(.(200.0f, 200.0f));
		Test.Assert(bridge.Dispatch(BridgeFixtures.Finger(.TouchDown, 3, 0.2f, 0.2f))); // (40, 40)
		// SDL's copy of the finger as the mouse: ignored while it is down...
		Test.Assert(!bridge.Dispatch(BridgeFixtures.ButtonEvent(.MouseButtonDown, 40.0f, 40.0f, .Left)));
		Test.Assert(bridge.Dispatch(BridgeFixtures.Finger(.TouchUp, 3, 0.2f, 0.2f)));
		Test.Assert(clicks == 1);
		// ...and after it, at the finger's last place.
		Test.Assert(!bridge.Dispatch(BridgeFixtures.ButtonEvent(.MouseButtonUp, 40.0f, 40.0f, .Left)));
		Test.Assert(!bridge.Dispatch(BridgeFixtures.MouseMove(40.0f, 40.0f)));
		Test.Assert(!button.Hovered); // no hover left behind by the copy
		Test.Assert(clicks == 1);
		Test.Assert(bridge.Dispatch(BridgeFixtures.MouseMove(60.0f, 50.0f))); // the real mouse, elsewhere
		Test.Assert(button.Hovered);
	}

	[Test]
	public static void PumpFromSurfaceForwardsThePolledFingerDownWhenItAppearsUpWhenItIsGone()
	{
		let root = BridgeFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let button = new Button();
		defer button.ReleaseRef();
		button.Size = .(100.0f, 100.0f);
		root.AddChild(button);
		int clicks = 0;
		button.SetOnClick(new [&] () => { clicks++; });
		let bridge = scope GuiInputBridge(root.EventDispatcher);
		let manager = scope MockInputManager(true);
		let surface = scope Sedulous.Shell.InputSurface(manager, 1,
			ContentFit(.(0.0f, 0.0f, 200.0f, 200.0f), .(200.0f, 200.0f), .Stretch));
		surface.SetWindowSize(.(200.0f, 200.0f));
		manager.TouchMock.Points.Add(Sedulous.Shell.TouchPoint(9, 0.25f, 0.25f, 1.0f, 50.0f, 50.0f));
		bridge.PumpFromSurface(surface);
		Test.Assert(root.EventDispatcher.IsTouchActive);
		Test.Assert(button.Pressed);
		manager.TouchMock.Points.Clear();
		bridge.PumpFromSurface(surface);
		Test.Assert(!root.EventDispatcher.IsTouchActive);
		Test.Assert(clicks == 1);
	}

	[Test]
	public static void AFingerCancelledEndsItsGestureTwoPolledFingersMakeOneATrackpadsPinchIsTheMouses()
	{
		let root = BridgeFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let pad = new Panel();
		defer pad.ReleaseRef();
		pad.Size = .(200.0f, 200.0f);
		pad.TouchActions = 0; // its fingers its own
		root.AddChild(pad);
		let seen = scope List<String>();
		defer { ClearAndDeleteItems!(seen); }
		PointerType pointer = .Touch;
		float scale = 0.0f;
		EventType[4] types = .(.GestureStart, .GestureChange, .GestureEnd, .GestureCancel);
		for (let type in types)
		{
			pad.AddEventListener(type, new [&] (e) =>
				{
					seen.Add(new String(EventTypeName(e.Type)));
					pointer = ((GestureEvent)e).Pointer;
					scale = ((GestureEvent)e).Scale;
				});
		}
		let bridge = scope GuiInputBridge(root.EventDispatcher);
		bridge.SetWindowSize(.(200.0f, 200.0f));

		// Two fingers, then one taken back by the platform.
		bridge.Dispatch(BridgeFixtures.Finger(.TouchDown, 1, 0.3f, 0.5f)); // nothing takes the press
		Test.Assert(bridge.Dispatch(BridgeFixtures.Finger(.TouchDown, 2, 0.7f, 0.5f)));
		Test.Assert(seen.Count == 1);
		Test.Assert(seen.Back == "gesturestart");
		Test.Assert(bridge.Dispatch(BridgeFixtures.Finger(.TouchCancel, 2, 0.7f, 0.5f)));
		Test.Assert(seen.Back == "gesturecancel");
		bridge.Dispatch(BridgeFixtures.Finger(.TouchUp, 1, 0.3f, 0.5f));

		// Two fingers polled from a surface, spreading.
		let manager = scope MockInputManager(true);
		let surface = scope Sedulous.Shell.InputSurface(manager, 1,
			ContentFit(.(0.0f, 0.0f, 200.0f, 200.0f), .(200.0f, 200.0f), .Stretch));
		surface.SetWindowSize(.(200.0f, 200.0f));
		manager.TouchMock.Points.Add(Sedulous.Shell.TouchPoint(5, 0.4f, 0.5f, 1.0f, 80.0f, 100.0f));
		manager.TouchMock.Points.Add(Sedulous.Shell.TouchPoint(6, 0.6f, 0.5f, 1.0f, 120.0f, 100.0f));
		bridge.PumpFromSurface(surface);
		Test.Assert(seen.Back == "gesturestart");
		manager.TouchMock.Points[0] = Sedulous.Shell.TouchPoint(5, 0.3f, 0.5f, 1.0f, 60.0f, 100.0f);
		manager.TouchMock.Points[1] = Sedulous.Shell.TouchPoint(6, 0.7f, 0.5f, 1.0f, 140.0f, 100.0f);
		bridge.PumpFromSurface(surface);
		Test.Assert(Near(scale, 2.0f));
		manager.TouchMock.Points.Clear();
		bridge.PumpFromSurface(surface);
		Test.Assert(seen.Back == "gestureend");

		// A trackpad's pinch, at the mouse: the same events, the mouse's.
		bridge.Dispatch(BridgeFixtures.MouseMove(100.0f, 100.0f));
		Sedulous.Shell.InputEvent pinch = default;
		pinch.Kind = .PinchBegin;
		Test.Assert(bridge.Dispatch(pinch));
		pinch.Kind = .PinchUpdate;
		pinch.Value = 1.5f;
		Test.Assert(bridge.Dispatch(pinch));
		Test.Assert(Near(scale, 1.5f));
		Test.Assert(pointer == .Mouse);
		pinch.Kind = .PinchEnd;
		Test.Assert(bridge.Dispatch(pinch));
		Test.Assert(seen.Back == "gestureend");
	}

	[Test]
	public static void AnIMEsCompositionReachesTheFocusedFieldAndTheWindowLearnsWhereItTypes()
	{
		let root = BridgeFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let field = new TextField();
		defer field.ReleaseRef();
		field.Position = .(20.0f, 40.0f);
		field.Size = .(100.0f, 24.0f);
		root.AddChild(field);
		let window = scope Sedulous.Shell.Null.NullWindow(1, .());
		let bridge = scope GuiInputBridge(root.EventDispatcher);
		bridge.SetTextInputTarget(window);
		bridge.Dispatch(BridgeFixtures.ButtonEvent(.MouseButtonDown, 30.0f, 50.0f, .Left));
		Test.Assert(field.IsFocused);
		// Where the field types: its line, in window coordinates.
		Test.Assert(window.LastTextInputArea.x == 20);
		Test.Assert(window.LastTextInputArea.y >= 40);
		Test.Assert(window.LastTextInputArea.y < 64);

		var editing = BridgeFixtures.TextEvent("nihon", .TextEditing);
		editing.EditCursor = 5;
		Test.Assert(bridge.Dispatch(editing));
		Test.Assert(field.Text.Length == 0); // shown, not yet the value

		bridge.Dispatch(BridgeFixtures.TextEvent("\u{65E5}\u{672C}")); // the committed text
		Test.Assert(field.Text == "\u{65E5}\u{672C}");
	}

	[Test]
	public static void OSFileDropsForItsWindowGroupedByWhereTheyLandedGoToTheDispatcherAsDrops()
	{
		let root = BridgeFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let target = BridgeFixtures.NewPanel(.(0.0f, 0.0f), .(200.0f, 200.0f));
		defer target.ReleaseRef();
		target.DropTypes = "files";
		root.AddChild(target);
		let bridge = scope GuiInputBridge(root.EventDispatcher);
		let sizes = scope List<int>();
		target.AddEventListener(.Drop, new [&] (e) =>
			{
				let paths = scope List<String>();
				DroppedPaths(((DragEvent)e).Payload, paths);
				sizes.Add(paths.Count);
				ClearAndDeleteItems!(paths);
			});

		let drops = scope List<Sedulous.Shell.DroppedFile>();
		defer { ClearAndDeleteItems!(drops); }
		drops.Add(BridgeFixtures.Drop(7, 20.0f, 20.0f, "/a"));
		drops.Add(BridgeFixtures.Drop(7, 20.0f, 20.0f, "/b")); // the same drop
		drops.Add(BridgeFixtures.Drop(9, 20.0f, 20.0f, "/other window"));
		drops.Add(BridgeFixtures.Drop(7, 60.0f, 60.0f, "/c")); // another drop
		Test.Assert(bridge.DispatchFileDrops(drops, 7));
		Test.Assert(sizes.Count == 2);
		Test.Assert(sizes[0] == 2);
		Test.Assert(sizes[1] == 1);

		// A drop the OS names no window for is this window's.
		let unnamed = scope List<Sedulous.Shell.DroppedFile>();
		defer { ClearAndDeleteItems!(unnamed); }
		unnamed.Add(BridgeFixtures.Drop(0, 30.0f, 30.0f, "/d"));
		Test.Assert(bridge.DispatchFileDrops(unnamed, 7));
		Test.Assert(sizes.Count == 3);
	}

	// === Behaviour no Raptor test covers ===

	[Test]
	public static void EitherSideOfAModifierPairMapsToItsModifier()
	{
		Test.Assert(GuiInputBridge.MapModifiers(.RightShift) == KeyModShift);
		Test.Assert(GuiInputBridge.MapModifiers(.RightCtrl) == KeyModCtrl);
		Test.Assert(GuiInputBridge.MapModifiers(.LeftAlt) == KeyModAlt);
		Test.Assert(GuiInputBridge.MapModifiers(.RightGui) == KeyModSuper);
		Test.Assert(GuiInputBridge.MapModifiers(.LeftShift | .RightCtrl) == (KeyModShift | KeyModCtrl));
		Test.Assert(GuiInputBridge.MapModifiers(.CapsLock | .NumLock) == 0); // locks are not modifiers
	}

	[Test]
	public static void KeysInsideARunMapByOffsetAndAKeyNoListNamesIsUnknown()
	{
		Test.Assert(GuiInputBridge.MapKey(.KeypadDivide) == (uint32)KeyCode.KeypadDivide);
		Test.Assert(GuiInputBridge.MapKey(.PrintScreen) == (uint32)KeyCode.PrintScreen);
		Test.Assert(GuiInputBridge.MapKey(.RightAlt) == (uint32)KeyCode.RightAlt);
		Test.Assert(GuiInputBridge.MapKey(.Z) == (uint32)KeyCode.Z);
		Test.Assert(GuiInputBridge.MapKey(.Num0) == (uint32)KeyCode.Num0);
		Test.Assert(GuiInputBridge.MapKey(.F12) == (uint32)KeyCode.F12);
		Test.Assert(GuiInputBridge.MapKey(.Unknown) == (uint32)KeyCode.Unknown);
	}

	[Test]
	public static void ThePadsDirectionsAndUnlistedButtonsAreNoKeystrokes()
	{
		PadButton pad = .South;
		Test.Assert(GuiInputBridge.MapPadButton(.North, out pad));
		Test.Assert(pad == .North);
		Test.Assert(GuiInputBridge.MapPadButton(.Back, out pad));
		Test.Assert(pad == .Back);
		Test.Assert(!GuiInputBridge.MapPadButton(.DPadUp, out pad));
		Test.Assert(!GuiInputBridge.MapPadButton(.Guide, out pad));
	}

	[Test]
	public static void AWheelLandsWhereThePointerLastWasWithItsDeltaAndModifiers()
	{
		let root = BridgeFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let child = BridgeFixtures.NewPanel(.(10.0f, 10.0f), .(50.0f, 50.0f));
		defer child.ReleaseRef();
		root.AddChild(child);
		let bridge = scope GuiInputBridge(root.EventDispatcher);
		int wheels = 0;
		Float2 delta = .(0.0f, 0.0f);
		uint32 mods = 0;
		child.AddEventListener(.MouseWheel, new [&] (e) =>
			{
				wheels++;
				delta = ((WheelEvent)e).Delta;
				mods = ((WheelEvent)e).Modifiers;
			});
		bridge.Dispatch(BridgeFixtures.MouseMove(20.0f, 20.0f));
		Sedulous.Shell.InputEvent wheel = default;
		wheel.Kind = .MouseWheel;
		wheel.X = 0.0f; // the delta, not a place
		wheel.Y = -3.0f;
		wheel.Modifiers = .LeftShift;
		bridge.Dispatch(wheel);
		Test.Assert(wheels == 1);
		Test.Assert(Near(delta.Y, -3.0f));
		Test.Assert((mods & KeyModShift) != 0);

		bridge.Dispatch(BridgeFixtures.MouseMove(150.0f, 150.0f)); // away from it: the wheel follows
		bridge.Dispatch(wheel);
		Test.Assert(wheels == 1);
	}

	[Test]
	public static void ClearingTheContentFitPassesPositionsThroughAgain()
	{
		let root = BridgeFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let bridge = scope GuiInputBridge(root.EventDispatcher);
		ContentFit fit = .(.(0.0f, 0.0f, 400.0f, 400.0f), .(200.0f, 200.0f), .Stretch);
		bridge.SetContentFit(fit);
		bridge.Dispatch(BridgeFixtures.MouseMove(40.0f, 40.0f));
		Test.Assert(Near(root.EventDispatcher.MousePosition.X, 20.0f));
		bridge.ClearContentFit();
		bridge.Dispatch(BridgeFixtures.MouseMove(40.0f, 40.0f));
		Test.Assert(Near(root.EventDispatcher.MousePosition.X, 40.0f));
	}

	[Test]
	public static void AStickPushedFromRestShortOfHalfWayHoldsNothing()
	{
		let root = BridgeFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let d = root.EventDispatcher;
		let bridge = scope GuiInputBridge(d);
		Test.Assert(bridge.Dispatch(BridgeFixtures.Stick(.LeftX, 0.45f))); // between release and press
		Test.Assert(!d.IsHoldingDirection);
		bridge.Dispatch(BridgeFixtures.Stick(.LeftX, 0.6f));
		Test.Assert(d.IsHoldingDirection);
		Sedulous.Shell.InputEvent trigger = BridgeFixtures.Stick(.LeftTrigger, 1.0f); // not a stick the GUI reads
		Test.Assert(!bridge.Dispatch(trigger));
	}

	[Test]
	public static void ACursorTheShellLacksTakesTheNearestItHas()
	{
		let root = BridgeFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let grab = new UIWidget();
		defer grab.ReleaseRef();
		grab.Size = .(100.0f, 100.0f);
		grab.Cursor = .Grab;
		root.AddChild(grab);
		let help = new UIWidget();
		defer help.ReleaseRef();
		help.Position = .(100.0f, 0.0f);
		help.Size = .(100.0f, 100.0f);
		help.Cursor = .Help;
		root.AddChild(help);
		let bridge = scope GuiInputBridge(root.EventDispatcher);
		let mouse = scope MockMouse();
		bridge.SetCursorTarget(mouse);
		bridge.Dispatch(BridgeFixtures.MouseMove(50.0f, 50.0f));
		Test.Assert(mouse.Cursor == .Move); // no grab cursor: the move one
		bridge.Dispatch(BridgeFixtures.MouseMove(150.0f, 50.0f));
		Test.Assert(mouse.Cursor == .Default); // no help cursor
	}

	[Test]
	public static void ABindingInAnotherSetThanTheOneNamedIsNotMade()
	{
		let map = scope Sedulous.Input.InputMap();
		let gameplay = new Sedulous.Input.ActionSet();
		gameplay.Name.Set("Gameplay");
		let action = new Sedulous.Input.InputAction();
		action.Name.Set("Back");
		Sedulous.Input.Binding escape = .();
		escape.Source = .Key;
		escape.Code = (uint32)Sedulous.Shell.KeyCode.Escape;
		action.Bindings.Add(escape);
		gameplay.Actions.Add(action);
		map.Sets.Add(gameplay);

		let root = BridgeFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		InputMapCommand[1] inMenu = .(InputMapCommand("Back", "back", "", "Menu"));
		Test.Assert(BindFromInputMap(root.Context.Keymap, map, Span<InputMapCommand>(&inMenu[0], 1)) == 0);
		InputMapCommand[1] anywhere = .(InputMapCommand("Back", "back"));
		Test.Assert(BindFromInputMap(root.Context.Keymap, map, Span<InputMapCommand>(&anywhere[0], 1)) == 1);
	}
}
