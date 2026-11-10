using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// Event + EventType + EventCallback: the typed events nodes listen for. Derived from eepp's
// Scene::Event / Event::EventType. Input events (pointer, wheel, keys, text) travel a route: from
// the root down to the target (the capture phase), at the target, and back up (the bubble phase);
// a handler marking one Handled ends its route. The rest (geometry, focus, change) go to the one
// node they are about.
//
// Events are classes: a listener is given the base and casts to the type its EventType names. The
// dispatcher makes them for the length of a dispatch, so the text they carry is a view of the
// dispatcher's. What a drag carries (DragPayload) and what is asked of a drop target (DropQuery)
// own their text.

/// What a drop does with what is dragged.
enum DropEffect : uint8
{
	None,
	Copy,
	Move,
	Link,
}

static
{
	/// The effects a drag's source allows, as flags.
	public const uint8 DropEffectsNone = 0;
	public const uint8 DropEffectsCopy = 1 << 0;
	public const uint8 DropEffectsMove = 1 << 1;
	public const uint8 DropEffectsLink = 1 << 2;
	public const uint8 DropEffectsAll = DropEffectsCopy | DropEffectsMove | DropEffectsLink;

	public static uint8 DropEffectFlag(DropEffect effect)
	{
		return (effect == .Copy) ? DropEffectsCopy : (effect == .Move) ? DropEffectsMove
			: (effect == .Link) ? DropEffectsLink : DropEffectsNone;
	}
}

/// What a drag carries: a type that targets choose by (`text`, `files`, `gui/tab`), a value (a
/// string, a number, a list, a weak node handle), a label for the preview and for accessibility,
/// and the effects its source allows. It owns its text and its value (disposed with it).
class DragPayload
{
	public String Type = new .() ~ delete _;
	public System.Variant Value ~ _.Dispose();
	public String Label = new .() ~ delete _;
	public uint8 Allowed = DropEffectsAll;

	public void Set(DragPayload other)
	{
		if (other === this)
			return;
		Type.Set(other.Type);
		Value.Dispose();
		Value = CopyVariant(other.Value);
		Label.Set(other.Label);
		Allowed = other.Allowed;
	}

	/// Empty again, as a fresh payload is.
	public void Reset()
	{
		Type.Clear();
		Value.Dispose();
		Value = default;
		Label.Clear();
		Allowed = DropEffectsAll;
	}
}

static
{
	/// A `files` payload's paths (an OS drop: its value a list of strings), added to `outPaths`;
	/// the caller owns the strings added.
	public static void DroppedPaths(DragPayload payload, List<String> outPaths)
	{
		if (!payload.Value.HasValue || (payload.Value.VariantType != typeof(List<System.Variant>)))
			return;
		let list = payload.Value.Get<List<System.Variant>>();
		if (list == null)
			return;
		for (let item in list)
		{
			if (IsText(item))
				outPaths.Add(new String(TextOf(item)));
		}
	}
}

enum EventType : uint32
{
	// Geometry / tree (fired now)
	PositionChanged,
	SizeChanged,
	VisibilityChanged,
	EnabledChanged,
	ParentChanged,
	Close,
	// Input
	MouseDown,
	MouseUp,
	MouseMove,
	MouseEnter,
	MouseLeave,
	MouseClick,
	MouseWheel,
	KeyDown,
	KeyUp,
	TextInput,
	FocusGained,
	FocusLost,
	// Drag and drop (DragEvents): a drag starting and ending at its source, entering, over,
	// leaving and dropped on its target.
	DragEnter,
	DragOver,
	DragLeave,
	Drop,
	DragStart,
	DragEnd,
	// Asked what a drop here would do (a DragEvent): a listener that takes it takes the drop.
	DragQuery,
	// A widget's value changed (a check box, a slider; a text field's committed value).
	Changed,
	// A text field's text changed with an edit (each one; Changed waits for the commit).
	Input,
	// A text field's Return: its value submitted.
	Submit,
	// A node lost the pointer it had captured (released, taken by another, or the node left).
	PointerCaptureLost,
	// The press in progress was cancelled (a scroller began panning under a finger): no
	// release and no click follow; a widget drops what the press started.
	PointerCancel,
	// A rich text's link was clicked (a LinkEvent, its id).
	Link,
	// An IME's composition so far, at the focused node (a CompositionEvent; empty text: it ended).
	Composition,
	// A popup opened or closed (a ToggleEvent, at the popup; it bubbles to its owner).
	Toggle,
	// A context menu asked for (a MouseEvent): a right release, a long press, Shift+F10.
	ContextMenu,
	// A scroll container's offset moved (its own listeners hear it; it does not bubble).
	Scroll,
	// A tab asked to close (a TabEvent, at its bar or view): unless a listener takes it, it goes.
	TabClose,
	// An item view's row was activated (an ItemEvent): a double-click, Return, the pad's South.
	ItemActivate,
	// Two fingers (or a trackpad's pinch) over a node whose touch-action leaves pinch-zoom out
	// (a GestureEvent): begun, moved (scale, rotation, translation), ended, or cancelled (a
	// finger the platform took back, the node gone).
	GestureStart,
	GestureChange,
	GestureEnd,
	GestureCancel,
	// A sheet's transition of one property ended, or a keyframe animation ran its last
	// iteration (a MotionEndEvent): told to the node it moved, not routed. One replaced or
	// stopped before its end is not told.
	TransitionEnd,
	AnimationEnd,
	// The input kind changed, told to the GUI's root, not routed: its input kind says which.
	InputKindChanged,
	// An event a library names for itself (a NamedEvent: a gamekit screen's `screenenter`),
	// told to the node it is about, not routed; a handler listens for it by its name (Node.On).
	Named,
	// A node's entrance ended (Node.Enter), told to it, not routed.
	Entered,
}

static
{
	/// What a finger may do that the GUI does itself (CSS's touch-action): pan across, pan up and
	/// down (a scroller's), and pinch, turn and pan with two (a gesture). What a node leaves out
	/// comes to it instead: a one-finger move along an axis it does not leave to the GUI goes on as
	/// the pointer (its own drag), and two fingers over a node that does not leave pinch-zoom make a
	/// gesture.
	public const uint8 cTouchPanX = 1;
	public const uint8 cTouchPanY = 2;
	public const uint8 cTouchPinchZoom = 4;
	public const uint8 cTouchAuto = cTouchPanX | cTouchPanY | cTouchPinchZoom;

	/// touch-action's value: auto, none, manipulation, or any of pan-x, pan-y and pinch-zoom; none
	/// for a word it does not know (the declaration is dropped, as CSS drops it).
	public static uint8? TouchActionsNamed(StringView text)
	{
		let k = ParseUtil.Trim(text);
		if ((k == "auto") || (k == "manipulation"))
			return cTouchAuto;
		if (k == "none")
			return (uint8)0;
		uint8 bits = 0;
		int at = 0;
		while (at < k.Length)
		{
			while ((at < k.Length) && (k[at] == ' '))
				at++;
			int end = at;
			while ((end < k.Length) && (k[end] != ' '))
				end++;
			let word = k.Substring(at, end - at);
			if (word == "pan-x")
				bits |= cTouchPanX;
			else if (word == "pan-y")
				bits |= cTouchPanY;
			else if (word == "pinch-zoom")
				bits |= cTouchPinchZoom;
			else if (word.Length != 0)
				return null;
			at = end;
		}
		if (bits == 0)
			return null;
		return bits;
	}

	/// touch-action's text for `bits`, appended to `outText`.
	public static void TouchActionsName(uint8 bits, String outText)
	{
		if (bits == cTouchAuto)
		{
			outText.Append("auto");
			return;
		}
		if (bits == 0)
		{
			outText.Append("none");
			return;
		}
		bool any = false;
		void Add(StringView word)
		{
			if (any)
				outText.Append(" ");
			outText.Append(word);
			any = true;
		}
		if ((bits & cTouchPanX) != 0)
			Add("pan-x");
		if ((bits & cTouchPanY) != 0)
			Add("pan-y");
		if ((bits & cTouchPinchZoom) != 0)
			Add("pinch-zoom");
	}
}

/// What drives the pointer: the mouse, or a finger (the first one down).
enum PointerType : uint8
{
	Mouse,
	Touch,
}

/// The pointer's look over a node (CSS `cursor`). Auto takes the look of the node around it,
/// as CSS's inherited cursor does; the host shows the dispatcher's answer.
enum Cursor : uint8
{
	Auto,
	Default,
	Pointer,
	Text,
	Move,
	Grab,
	Grabbing,
	NotAllowed,
	Wait,
	Progress,
	Crosshair,
	Help,
	EwResize,
	NsResize,
	NwseResize,
	NeswResize,
	/// A drop would copy.
	Copy,
	/// A drop would link.
	Alias,
	/// Nothing here takes the drag.
	NoDrop,
	/// No cursor shows (a pad in use hides it; CSS's `none`).
	None,
}

static
{
	/// By Cursor.
	public static String[20] sCursorNames = .(
		"auto", "default", "pointer", "text", "move", "grab", "grabbing", "not-allowed",
		"wait", "progress", "crosshair", "help", "ew-resize", "ns-resize", "nwse-resize",
		"nesw-resize", "copy", "alias", "no-drop", "none");

	/// The cursor CSS names `name`; Auto for an unknown name.
	public static Cursor CursorNamed(StringView name)
	{
		for (int i = 0; i < sCursorNames.Count; i++)
		{
			if (sCursorNames[i] == name)
				return (Cursor)i;
		}
		return .Auto;
	}

	public static StringView CursorName(Cursor cursor) => sCursorNames[(int)cursor];
}

/// What the player drives the GUI with now: the pointer (a mouse, a finger), the keyboard or a
/// pad. A host that tracks it (Sedulous.Input's InputKindTracker, through GUI.Shell's bridge)
/// gives it; without one the dispatcher follows what it is given: a press, a key, a pad button
/// or direction.
enum InputKind : uint8
{
	Pointer,
	Keyboard,
	Pad,
}

static
{
	/// "pointer", "keyboard" or "pad": what a sheet's `@media (input: ...)` and code name it.
	public static StringView InputKindName(InputKind kind)
	{
		switch (kind)
		{
		case .Keyboard: return "keyboard";
		case .Pad: return "pad";
		case .Pointer: break;
		}
		return "pointer";
	}
}

/// Where on its route an input event is: going down from the root (Capture), at the node it
/// is for (Target), or coming back up (Bubble).
enum EventPhase : uint8
{
	Capture,
	Target,
	Bubble,
}

enum MouseButton : uint32
{
	Left,
	Right,
	Middle,
	X1,
	X2
}

/// Platform-agnostic key identity for the navigation/editing keys the GUI interprets (printable
/// characters arrive as TextInput, not here). The GUI.Shell bridge maps platform key codes to
/// these explicitly; a KeyEvent carries the value as a uint32, so handlers compare against
/// (uint32)KeyCode.X. Only the letter keys that back editing shortcuts (Ctrl+A/C/V/X for
/// select-all/copy/paste/cut) came first; other printable characters still arrive as TextInput.
enum KeyCode : uint32
{
	Unknown = 0,
	Return,
	Escape,
	Backspace,
	Tab,
	Space,
	Delete,
	Insert,
	Home,
	End,
	PageUp,
	PageDown,
	Left,
	Right,
	Up,
	Down,
	A,
	C,
	V,
	X,
	// The rest of the keyboard bindings name, after the first set so its values hold.
	B, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, W, Y, Z,
	Num0, Num1, Num2, Num3, Num4, Num5, Num6, Num7, Num8, Num9,
	F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12,
	// The rest of the keyboard: punctuation, the keypad with codes of its own (a game binds
	// Numpad 5 apart from 5), the lock and system keys, and the modifier keys themselves (a game
	// binds Left Shift to sprint).
	F13, F14, F15, F16, F17, F18, F19, F20, F21, F22, F23, F24,
	Minus, Equals, LeftBracket, RightBracket, Backslash, Semicolon, Apostrophe, Grave, Comma, Period, Slash,
	CapsLock, ScrollLock, NumLock, PrintScreen, Pause, Menu,
	Keypad0, Keypad1, Keypad2, Keypad3, Keypad4, Keypad5, Keypad6, Keypad7, Keypad8, Keypad9,
	KeypadDivide, KeypadMultiply, KeypadMinus, KeypadPlus, KeypadEnter, KeypadDecimal,
	LeftCtrl, LeftShift, LeftAlt, LeftSuper, RightCtrl, RightShift, RightAlt, RightSuper,
	// The back button: a phone's, or a keyboard's or a browser's Back key (the `back` command by
	// default, as Escape is).
	Back,
}

static
{
	/// The letter keys in alphabetical order (their codes are not contiguous: A, C, V and X came first).
	public static KeyCode[26] sLetterKeys = .(
		.A, .B, .C, .D, .E, .F, .G, .H, .I,
		.J, .K, .L, .M, .N, .O, .P, .Q, .R,
		.S, .T, .U, .V, .W, .X, .Y, .Z);

	/// Key modifier bits, OR-ed into a KeyEvent's Modifiers.
	public const uint32 KeyModNone = 0;
	public const uint32 KeyModShift = 1 << 0;
	public const uint32 KeyModCtrl = 1 << 1;
	public const uint32 KeyModAlt = 1 << 2;
	public const uint32 KeyModSuper = 1 << 3;

	/// Whether a key types a character (a letter, a digit, punctuation, the keypad's digits and
	/// signs): what a widget that takes typed text (type-ahead) claims, so a binding of the bare
	/// key does not take it from under the text.
	public static bool KeyTypesText(KeyCode key)
	{
		for (int i = 0; i < sLetterKeys.Count; i++)
		{
			if (sLetterKeys[i] == key)
				return true;
		}
		let k = (uint32)key;
		return ((k >= (uint32)KeyCode.Num0) && (k <= (uint32)KeyCode.Num9)) ||
			((k >= (uint32)KeyCode.Minus) && (k <= (uint32)KeyCode.Slash)) ||
			((k >= (uint32)KeyCode.Keypad0) && (k <= (uint32)KeyCode.KeypadDecimal) && (key != .KeypadEnter));
	}

	/// The modifier a modifier key is (Left Shift: Shift), else none: pressed alone, the key is
	/// itself, not Shift plus itself.
	public static uint32 ModifierOfKey(KeyCode key)
	{
		switch (key)
		{
		case .LeftShift, .RightShift: return KeyModShift;
		case .LeftCtrl, .RightCtrl: return KeyModCtrl;
		case .LeftAlt, .RightAlt: return KeyModAlt;
		case .LeftSuper, .RightSuper: return KeyModSuper;
		default: return KeyModNone;
		}
	}
}

/// Base event. A listener registered for a given EventType may cast to the matching subclass
/// below (the dispatcher always constructs the payload type that matches the EventType).
class Event
{
	public EventType Type;
	public EventPhase Phase = .Target;
	/// Set by a handler that used the event: its route ends there. A key a widget leaves
	/// unhandled goes on to the keymap and navigation.
	public bool Handled = false;
	/// The node the event is for (the hovered or pressed node, the focus). Not owned.
	public Node Target = null;
	/// The node whose handlers are running now, on the event's route. Not owned.
	public Node CurrentTarget = null;

	public this(EventType type, Node target = null)
	{
		Type = type;
		Target = target;
		CurrentTarget = target;
	}
}

class MouseEvent : Event
{
	public Float2 Position;
	public MouseButton Button;
	public uint32 Modifiers;
	/// 1 for a press, 2 for the second of a double press, 3 for a triple (near in time and
	/// place, the same button): a press, its release and its click carry the same count.
	public uint32 ClickCount = 1;
	public PointerType Pointer = .Mouse;
	/// The finger, for touch.
	public uint64 PointerId = 0;

	public this(EventType type, Node target, Float2 position, MouseButton button = .Left, uint32 modifiers = 0) : base(type, target)
	{
		Position = position;
		Button = button;
		Modifiers = modifiers;
	}
}

class WheelEvent : Event
{
	public Float2 Position;
	public Float2 Delta;
	/// Shift turns a vertical wheel to the other axis.
	public uint32 Modifiers = 0;

	public this(Node target, Float2 position, Float2 delta, uint32 modifiers = 0) : base(.MouseWheel, target)
	{
		Position = position;
		Delta = delta;
		Modifiers = modifiers;
	}
}

/// A two-finger gesture: pinch, turn and pan as one, as Safari's and aui's are. Each value is the
/// total since it began and the change since the last event; the translation is in the GUI's
/// units (the root's, not a node's own, which its gesture may turn), about the fingers' middle
/// (`Focus`, device pixels, as positions come).
class GestureEvent : Event
{
	public Float2 Focus = .(0.0f, 0.0f);
	/// The fingers' span over their span when it began.
	public float Scale = 1.0f;
	/// Radians the line between them has turned, clockwise.
	public float Rotation = 0.0f;
	public Float2 Translation = .(0.0f, 0.0f);
	/// This event's factor (the totals multiply up from them).
	public float ScaleDelta = 1.0f;
	public float RotationDelta = 0.0f;
	public Float2 TranslationDelta = .(0.0f, 0.0f);
	/// Touch, or the mouse's trackpad.
	public PointerType Pointer = .Touch;

	public this(EventType type, Node target) : base(type, target)
	{
	}
}

class KeyEvent : Event
{
	public uint32 KeyCode;
	public uint32 Modifiers;

	public this(EventType type, Node target, uint32 keyCode, uint32 modifiers = 0) : base(type, target)
	{
		KeyCode = keyCode;
		Modifiers = modifiers;
	}
}

class TextInputEvent : Event
{
	public StringView Text;

	public this(Node target, StringView text) : base(.TextInput, target)
	{
		Text = text;
	}
}

/// Why a popup closed: code closed it, Escape, a press outside it, another popup opening that it
/// does not hold, or its owner leaving the tree.
enum PopupCloseReason : uint8
{
	Code,
	Escape,
	OutsidePress,
	Replaced,
	OwnerRemoved,
}

static
{
	public static StringView PopupCloseReasonName(PopupCloseReason reason)
	{
		switch (reason)
		{
		case .Escape: return "escape";
		case .OutsidePress: return "outside-press";
		case .Replaced: return "replaced";
		case .OwnerRemoved: return "owner-removed";
		default: return "code";
		}
	}
}

/// A popup opened, or closed and why (the web's `toggle`).
class ToggleEvent : Event
{
	public bool Open = false;
	/// When closed.
	public PopupCloseReason Reason = .Code;

	public this(Node target, bool open, PopupCloseReason reason) : base(.Toggle, target)
	{
		Open = open;
		Reason = reason;
	}
}

/// About one tab of a bar or a view: which, by index.
class TabEvent : Event
{
	public int32 Index = -1;

	public this(EventType type, Node target, int32 index) : base(type, target)
	{
		Index = index;
	}
}

/// About one row of an item view: its item (the view's row number) and its model index.
class ItemEvent : Event
{
	public int32 Item = -1;
	public ModelIndex Index;

	public this(EventType type, Node target, int32 item, ModelIndex index) : base(type, target)
	{
		Item = item;
		Index = index;
	}
}

/// An IME's composition so far: its text (empty when the composition ended or was committed,
/// the committed text then arriving as TextInput) and the caret within it, in characters.
class CompositionEvent : Event
{
	public StringView Text;
	public int32 Cursor = 0;

	public this(Node target, StringView text, int32 cursor) : base(.Composition, target)
	{
		Text = text;
		Cursor = cursor;
	}
}

/// A rich text's link, clicked: the id its markup gave it ([link=door]).
class LinkEvent : Event
{
	public StringView Link;

	public this(Node target, StringView link) : base(.Link, target)
	{
		Link = link;
	}
}

/// A sheet's motion that ended on its node: the property a transition moved, or the
/// @keyframes an animation ran, and the seconds it ran (its delay not counted).
class MotionEndEvent : Event
{
	public StringView Name;
	public float Elapsed = 0.0f;

	public this(EventType type, Node target, StringView name, float elapsed) : base(type, target)
	{
		Name = name;
		Elapsed = elapsed;
	}
}

/// An event a library names (EventType.Named): its name, which Node.On listens by, and a detail
/// it may carry as text.
class NamedEvent : Event
{
	public StringView Name;
	public StringView Detail;

	public this(Node target, StringView name, StringView detail = default) : base(.Named, target)
	{
		Name = name;
		Detail = detail;
	}
}

/// A drag's events: its payload, the effect a drop would have (or had: none when a drag
/// ended cancelled), where the pointer is (in the root's space) and the modifiers held.
class DragEvent : Event
{
	/// The drag's own (not owned here).
	public DragPayload Payload;
	public DropEffect Effect = .None;
	public Float2 Position = .(0.0f, 0.0f);
	public uint32 Modifiers = 0;
	/// Where in the target, as the target said (an index, a side).
	public int32 Place = 0;

	public this(EventType type, Node target, DragPayload payload) : base(type, target)
	{
		Payload = payload;
	}
}

/// A source asked for a drag: the press, in its space; it fills the payload, and may give a
/// preview and where in the preview the pointer holds it (else it holds it where the press was
/// on the source, or beside a default preview).
class DragRequest
{
	public Float2 Press = .(0.0f, 0.0f);
	public uint32 Modifiers = 0;
	public PointerType Pointer = .Mouse;
	/// `drag.pick` at the focus, not a press.
	public bool FromKeyboard = false;
	public DragPayload Payload = new .() ~ delete _;
	public Float2 GrabOffset = .(0.0f, 0.0f);
	public bool HasGrabOffset = false;
	/// A source that shows itself where the drag is (a window dragged by its title): no preview
	/// is made, and each move of the drag calls this with the pointer in the root's space, before
	/// the drop is asked about (the source keeps itself out of hit tests). Owned: set it once.
	public delegate void(Float2 pointer) Follow ~ delete _;

	private Node mPreview ~ _?.ReleaseRef();

	/// What the drag shows under the pointer (null: a default one). It holds a reference to the
	/// node it is given, letting go of the one before.
	public Node Preview
	{
		get => mPreview;
		set
		{
			if (value != null)
				value.AddRef();
			if (mPreview != null)
				mPreview.ReleaseRef();
			mPreview = value;
		}
	}
}

/// What a drop here would do, asked of the node under the pointer and up its ancestors every
/// move, modifier change and scroll (Godot's walk, Zero's test drop). The node sets the effect
/// (from those the source allows; Preferred is the modifiers' choice), a reason (what it would
/// do, or why not), and a place it draws; one that refuses with a reason ends the walk.
class DropQuery
{
	/// The drag's own (not owned here).
	public DragPayload Payload;
	/// The pointer in the asked node's space.
	public Float2 Local = .(0.0f, 0.0f);
	public uint32 Modifiers = 0;
	public DropEffect Preferred = .Move;
	/// A keyboard drag: the asked node is the focus, Local its centre.
	public bool FromKeyboard = false;
	public DropEffect Effect = .None;
	public String Reason = new .() ~ delete _;
	public bool Refused = false;
	public int32 Place = 0;

	public this(DragPayload payload)
	{
		Payload = payload;
	}

	/// Takes the drop with the preferred effect, or `effect` where the source allows it.
	public void Accept(DropEffect effect = .None)
	{
		let want = (effect == .None) ? Preferred : effect;
		Effect = ((Payload.Allowed & DropEffectFlag(want)) != 0) ? want : Preferred;
	}

	/// Refuses, saying why (the walk ends here and the reason shows).
	public void Refuse(StringView reason)
	{
		Effect = .None;
		Refused = true;
		Reason.Set(reason);
	}
}

/// How a drag ended, told to its source: the effect (none when cancelled or dropped nowhere)
/// and the node that took it.
struct DragResult
{
	public DropEffect Effect = .None;
	public bool Cancelled = false;
	/// Let go over no root of the GUI: no window of its own there.
	public bool Outside = false;
	/// Screen is known (a host placed the roots).
	public bool ScreenKnown = false;
	/// Where on the screen the pointer was when it ended.
	public Float2 Screen = .();
	/// The node that took it (not owned).
	public Node Target = null;

	public this() { }
}

typealias EventCallback = delegate void(Event e);

/// What Event.bf keeps out of the public surface: the names Node.On and markup use for events.
internal static class EventDetail
{
	public struct NamedEventType
	{
		public String Name;
		public EventType Type;

		public this(String name, EventType type)
		{
			Name = name;
			Type = type;
		}
	}

	/// The names Node.On takes for events (`On("click", ...)`) and the inspector shows.
	public static NamedEventType[39] sEventTypeNames = .(
		.("click", .MouseClick), .("mousedown", .MouseDown),
		.("mouseup", .MouseUp), .("mouseenter", .MouseEnter),
		.("mouseleave", .MouseLeave), .("mousemove", .MouseMove),
		.("wheel", .MouseWheel), .("keydown", .KeyDown),
		.("keyup", .KeyUp), .("textinput", .TextInput),
		.("focus", .FocusGained), .("blur", .FocusLost),
		.("change", .Changed), .("pointercancel", .PointerCancel),
		.("link", .Link), .("input", .Input),
		.("submit", .Submit), .("composition", .Composition),
		.("toggle", .Toggle), .("close", .Close),
		.("contextmenu", .ContextMenu),
		.("scroll", .Scroll),
		.("tabclose", .TabClose),
		.("activate", .ItemActivate),
		.("dragstart", .DragStart), .("dragend", .DragEnd),
		.("dragenter", .DragEnter), .("dragover", .DragOver),
		.("dragleave", .DragLeave), .("drop", .Drop),
		.("dragquery", .DragQuery),
		.("gesturestart", .GestureStart), .("gesturechange", .GestureChange),
		.("gestureend", .GestureEnd), .("gesturecancel", .GestureCancel),
		.("transitionend", .TransitionEnd), .("animationend", .AnimationEnd),
		.("inputkind", .InputKindChanged),
		.("entered", .Entered));
}

static
{
	/// The event type markup and Node.On call `name` ("click", "keydown"); false for one they do
	/// not (`outType` is then the first type, PositionChanged).
	public static bool EventTypeNamed(StringView name, out EventType outType)
	{
		for (int i = 0; i < EventDetail.sEventTypeNames.Count; i++)
		{
			if (EventDetail.sEventTypeNames[i].Name == name)
			{
				outType = EventDetail.sEventTypeNames[i].Type;
				return true;
			}
		}
		outType = default;
		return false;
	}

	/// The name markup and Node.On give `type` (empty for one they have no name for).
	public static StringView EventTypeName(EventType type)
	{
		for (int i = 0; i < EventDetail.sEventTypeNames.Count; i++)
		{
			if (EventDetail.sEventTypeNames[i].Type == type)
				return EventDetail.sEventTypeNames[i].Name;
		}
		return default;
	}
}
