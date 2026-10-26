using System;
using System.Collections;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// Bindings from keys and gamepad buttons to commands, after GPUI's keymap
// (`zed/crates/gpui/src/keymap.rs`, `keymap/context.rs`). A binding names a keystroke or a chord
// ("ctrl-s", "ctrl-k ctrl-c", "escape", "pad-east"), a command (empty: the keystroke is unbound
// there) and, optionally, the contexts it applies in as a small predicate over the key contexts
// the focus path declares ("menu", "editor && mode == insert", "!modal"). Each node on the focus
// path may declare a context (Node.KeyContext: "editor mode=insert"); a binding matches at the
// deepest depth whose contexts, root to there, satisfy it. Of the bindings for a keystroke, the
// deepest match wins, then the later binding, so a screen's binding beats the GUI's and a later
// one overrides an earlier.
//
// A context layer owns its text and is copied (a stack repeats its ancestors'), so it is a class
// with a deep Set; a stack is a span of them, root first.

/// A gamepad's buttons as keystrokes take them (the d-pad moves focus, not through bindings).
enum PadButton : uint32
{
	/// A / Cross: activates when unbound.
	South,
	/// B / Circle.
	East,
	West,
	North,
	Start,
	Back,
	LeftShoulder,
	RightShoulder,
}

static
{
	/// The key context menus and menu bars declare, and the commands their keys run there: the
	/// arrows by default, which a game rebinds like any key. Each widget gives a direction its
	/// meaning (Left closes a submenu, moves along a bar, and right to left the bar runs the other
	/// way).
	public const String cMenuKeyContext = "menu";
	public const String cMenuUpCommand = "menu.up";
	public const String cMenuDownCommand = "menu.down";
	public const String cMenuLeftCommand = "menu.left";
	public const String cMenuRightCommand = "menu.right";
	/// Runs the focused item of an open menu (Return and Space by default).
	public const String cMenuActivateCommand = "menu.activate";
	/// Back out of where one is: Escape and the pad's East by default. The topmost auto popup
	/// answers it by closing, a modal dialog as its close button does, then whatever handles it on
	/// the focus path (a game's screen).
	public const String cBackCommand = "back";
}

/// One key with its modifiers, or one gamepad button.
struct Keystroke : IEquatable<Keystroke>
{
	/// A KeyCode, or a PadButton when Pad.
	public uint32 Code = 0;
	public uint32 Modifiers = 0;
	public bool Pad = false;

	public this() { }

	public this(uint32 code, uint32 modifiers, bool pad)
	{
		Code = code;
		Modifiers = modifiers;
		Pad = pad;
	}

	public bool Equals(Keystroke other) => this == other;

	[Commutable]
	public static bool operator==(Keystroke a, Keystroke b) => (a.Code == b.Code) && (a.Modifiers == b.Modifiers) && (a.Pad == b.Pad);
}

/// What Keymap.bf keeps out of the public surface: the names keys and pad buttons go by.
internal static class KeymapDetail
{
	public struct NamedCode
	{
		public String Name;
		public uint32 Code;

		public this(String name, uint32 code)
		{
			Name = name;
			Code = code;
		}
	}

	/// Every key with a name of its own: what a binding writes ("pageup", "numpad5") and what a
	/// menu shows ("PgUp", "Numpad 5"). Letters, digits and F1 to F24 are named by rule.
	public struct NamedKey
	{
		public KeyCode Code;
		public String Name;
		public String Text;

		public this(KeyCode code, String name, String text)
		{
			Code = code;
			Name = name;
			Text = text;
		}
	}

	public static NamedKey[57] sKeyNames = .(
		.(.Return, "enter", "Enter"),
		.(.Return, "return", "Enter"),
		.(.Escape, "escape", "Esc"),
		.(.Backspace, "backspace", "Backspace"),
		.(.Tab, "tab", "Tab"),
		.(.Space, "space", "Space"),
		.(.Delete, "delete", "Del"),
		.(.Insert, "insert", "Ins"),
		.(.Home, "home", "Home"),
		.(.End, "end", "End"),
		.(.PageUp, "pageup", "PgUp"),
		.(.PageDown, "pagedown", "PgDn"),
		.(.Left, "left", "Left"),
		.(.Right, "right", "Right"),
		.(.Up, "up", "Up"),
		.(.Down, "down", "Down"),
		.(.Minus, "minus", "-"),
		.(.Equals, "equals", "="),
		.(.LeftBracket, "leftbracket", "["),
		.(.RightBracket, "rightbracket", "]"),
		.(.Backslash, "backslash", "\\"),
		.(.Semicolon, "semicolon", ";"),
		.(.Apostrophe, "apostrophe", "'"),
		.(.Grave, "grave", "`"),
		.(.Comma, "comma", ","),
		.(.Period, "period", "."),
		.(.Slash, "slash", "/"),
		.(.CapsLock, "capslock", "Caps Lock"),
		.(.ScrollLock, "scrolllock", "Scroll Lock"),
		.(.NumLock, "numlock", "Num Lock"),
		.(.PrintScreen, "printscreen", "Print Screen"),
		.(.Pause, "pause", "Pause"),
		.(.Menu, "menu", "Menu"),
		.(.Keypad0, "numpad0", "Numpad 0"),
		.(.Keypad1, "numpad1", "Numpad 1"),
		.(.Keypad2, "numpad2", "Numpad 2"),
		.(.Keypad3, "numpad3", "Numpad 3"),
		.(.Keypad4, "numpad4", "Numpad 4"),
		.(.Keypad5, "numpad5", "Numpad 5"),
		.(.Keypad6, "numpad6", "Numpad 6"),
		.(.Keypad7, "numpad7", "Numpad 7"),
		.(.Keypad8, "numpad8", "Numpad 8"),
		.(.Keypad9, "numpad9", "Numpad 9"),
		.(.KeypadDivide, "numpaddivide", "Numpad /"),
		.(.KeypadMultiply, "numpadmultiply", "Numpad *"),
		.(.KeypadMinus, "numpadminus", "Numpad -"),
		.(.KeypadPlus, "numpadplus", "Numpad +"),
		.(.KeypadEnter, "numpadenter", "Numpad Enter"),
		.(.KeypadDecimal, "numpaddecimal", "Numpad ."),
		.(.LeftCtrl, "leftctrl", "Left Ctrl"),
		.(.LeftShift, "leftshift", "Left Shift"),
		.(.LeftAlt, "leftalt", "Left Alt"),
		.(.LeftSuper, "leftsuper", "Left Super"),
		.(.RightCtrl, "rightctrl", "Right Ctrl"),
		.(.RightShift, "rightshift", "Right Shift"),
		.(.RightAlt, "rightalt", "Right Alt"),
		.(.RightSuper, "rightsuper", "Right Super"));

	/// F1 to F24's place: 1 to 24, or 0 for a key that is none of them.
	public static uint32 FunctionKeyNumber(KeyCode key)
	{
		let k = (uint32)key;
		if ((k >= (uint32)KeyCode.F1) && (k <= (uint32)KeyCode.F12))
			return k - (uint32)KeyCode.F1 + 1;
		if ((k >= (uint32)KeyCode.F13) && (k <= (uint32)KeyCode.F24))
			return k - (uint32)KeyCode.F13 + 13;
		return 0;
	}

	public static KeyCode FunctionKey(uint32 number)
	{
		return (number <= 12) ? (KeyCode)((uint32)KeyCode.F1 + number - 1)
			: (KeyCode)((uint32)KeyCode.F13 + number - 13);
	}

	public static NamedCode[8] sPadNames = .(
		.("south", (uint32)PadButton.South), .("east", (uint32)PadButton.East),
		.("west", (uint32)PadButton.West), .("north", (uint32)PadButton.North),
		.("start", (uint32)PadButton.Start), .("back", (uint32)PadButton.Back),
		.("lb", (uint32)PadButton.LeftShoulder), .("rb", (uint32)PadButton.RightShoulder));

	/// By PadButton: what a menu shows.
	public static String[8] sPadTexts = .("South", "East", "West", "North", "Start", "Back", "LB", "RB");

	/// Appends F1 to F24's number.
	public static void AppendNumber(uint32 n, String outText)
	{
		if (n >= 10)
			outText.Append((char8)((uint32)'0' + n / 10));
		outText.Append((char8)((uint32)'0' + n % 10));
	}
}

static
{
	/// "ctrl-shift-s", "escape", "pad-east": modifiers (ctrl, shift, alt, super) then a key, joined
	/// by '-'; "pad-" names a gamepad button. Empty on an unknown name.
	public static Keystroke? ParseKeystroke(StringView text)
	{
		Keystroke stroke = .();
		StringView rest = ParseUtil.Trim(text);
		if ((rest.Length > 4) && (rest.Substring(0, 4) == "pad-"))
		{
			let name = rest.Substring(4, rest.Length - 4);
			for (int i = 0; i < KeymapDetail.sPadNames.Count; i++)
			{
				if (name == KeymapDetail.sPadNames[i].Name)
					return Keystroke(KeymapDetail.sPadNames[i].Code, 0, true);
			}
			return null;
		}
		while (true)
		{
			int dash = rest.Length;
			for (int i = 0; i < rest.Length; i++)
			{
				if (rest[i] == '-')
				{
					dash = i;
					break;
				}
			}
			if (dash == rest.Length)
				break;
			let modifier = rest.Substring(0, dash);
			if (modifier == "ctrl")
				stroke.Modifiers |= KeyModCtrl;
			else if (modifier == "shift")
				stroke.Modifiers |= KeyModShift;
			else if (modifier == "alt")
				stroke.Modifiers |= KeyModAlt;
			else if (modifier == "super")
				stroke.Modifiers |= KeyModSuper;
			else
				return null;
			rest = rest.Substring(dash + 1, rest.Length - dash - 1);
		}
		for (int i = 0; i < KeymapDetail.sKeyNames.Count; i++)
		{
			if (rest == KeymapDetail.sKeyNames[i].Name)
			{
				stroke.Code = (uint32)KeymapDetail.sKeyNames[i].Code;
				return stroke;
			}
		}
		// A letter, a digit, or f1 to f24.
		if ((rest.Length == 1) && (rest[0] >= 'a') && (rest[0] <= 'z'))
		{
			stroke.Code = (uint32)sLetterKeys[(int)rest[0] - (int)'a'];
			return stroke;
		}
		if ((rest.Length == 1) && (rest[0] >= '0') && (rest[0] <= '9'))
		{
			stroke.Code = (uint32)KeyCode.Num0 + (uint32)((int)rest[0] - (int)'0');
			return stroke;
		}
		if ((rest.Length >= 2) && (rest.Length <= 3) && (rest[0] == 'f'))
		{
			uint32 n = 0;
			for (int i = 1; i < rest.Length; i++)
			{
				if ((rest[i] < '0') || (rest[i] > '9'))
					return null;
				n = n * 10 + (uint32)((int)rest[i] - (int)'0');
			}
			if ((n >= 1) && (n <= 24))
			{
				stroke.Code = (uint32)KeymapDetail.FunctionKey(n);
				return stroke;
			}
		}
		return null;
	}

	/// A keystroke as a binding writes it ("ctrl-shift-s", "numpad5", "pad-north"), appended to
	/// `outText`: what ParseKeystroke reads back (a rebinding screen saves what it captured).
	/// Nothing for a code with no name.
	public static void KeystrokeName(Keystroke stroke, String outText)
	{
		if (stroke.Pad)
		{
			for (int i = 0; i < KeymapDetail.sPadNames.Count; i++)
			{
				if (KeymapDetail.sPadNames[i].Code == stroke.Code)
				{
					outText.Append("pad-");
					outText.Append(KeymapDetail.sPadNames[i].Name);
				}
			}
			return;
		}
		let key = (KeyCode)stroke.Code;
		let name = scope String();
		for (int i = 0; i < KeymapDetail.sKeyNames.Count; i++)
		{
			let n = KeymapDetail.sKeyNames[i];
			if ((n.Code == key) && (n.Code != .Return))
			{
				name.Set(n.Name);
				break;
			}
		}
		if (key == .Return)
			name.Set("enter");
		for (int i = 0; (i < 26) && (name.Length == 0); i++)
		{
			if (sLetterKeys[i] == key)
				name.Append((char8)((int)'a' + i));
		}
		if ((name.Length == 0) && (stroke.Code >= (uint32)KeyCode.Num0) && (stroke.Code <= (uint32)KeyCode.Num9))
			name.Append((char8)((uint32)'0' + (stroke.Code - (uint32)KeyCode.Num0)));
		let number = KeymapDetail.FunctionKeyNumber(key);
		if ((name.Length == 0) && (number != 0))
		{
			name.Append('f');
			KeymapDetail.AppendNumber(number, name);
		}
		if (name.Length == 0)
			return;
		if ((stroke.Modifiers & KeyModCtrl) != 0)
			outText.Append("ctrl-");
		if ((stroke.Modifiers & KeyModShift) != 0)
			outText.Append("shift-");
		if ((stroke.Modifiers & KeyModAlt) != 0)
			outText.Append("alt-");
		if ((stroke.Modifiers & KeyModSuper) != 0)
			outText.Append("super-");
		outText.Append(name);
	}

	/// A keystroke as a menu shows it, appended to `outText`: "Ctrl+Shift+S", "F10", "Enter",
	/// "Pad East".
	public static void KeystrokeText(Keystroke stroke, String outText)
	{
		if (stroke.Pad)
		{
			outText.Append("Pad ");
			if (stroke.Code < (uint32)KeymapDetail.sPadTexts.Count)
				outText.Append(KeymapDetail.sPadTexts[(int)stroke.Code]);
			return;
		}
		if ((stroke.Modifiers & KeyModCtrl) != 0)
			outText.Append("Ctrl+");
		if ((stroke.Modifiers & KeyModAlt) != 0)
			outText.Append("Alt+");
		if ((stroke.Modifiers & KeyModShift) != 0)
			outText.Append("Shift+");
		if ((stroke.Modifiers & KeyModSuper) != 0)
			outText.Append("Super+");
		let key = (KeyCode)stroke.Code;
		for (int i = 0; i < KeymapDetail.sKeyNames.Count; i++)
		{
			if (KeymapDetail.sKeyNames[i].Code == key)
			{
				outText.Append(KeymapDetail.sKeyNames[i].Text);
				return;
			}
		}
		for (int i = 0; i < 26; i++)
		{
			if (sLetterKeys[i] == key)
			{
				outText.Append((char8)((int)'A' + i));
				return;
			}
		}
		let number = KeymapDetail.FunctionKeyNumber(key);
		if ((stroke.Code >= (uint32)KeyCode.Num0) && (stroke.Code <= (uint32)KeyCode.Num9))
			outText.Append((char8)((uint32)'0' + (stroke.Code - (uint32)KeyCode.Num0)));
		else if (number != 0)
		{
			outText.Append('F');
			KeymapDetail.AppendNumber(number, outText);
		}
	}
}

/// What one node's key context declares: identifiers ("menu") and key=value pairs
/// ("mode=insert"), separated by spaces. A layer of the stack the focus path builds holds the
/// declarations of every node from the root to there, a deeper value replacing an outer one.
class KeyContextLayer
{
	public List<String> Keys = new .() ~ DeleteContainerAndItems!(_);
	/// Parallel to Keys; empty for a bare identifier.
	public List<String> Values = new .() ~ DeleteContainerAndItems!(_);

	public void Set(KeyContextLayer other)
	{
		if (other === this)
			return;
		ClearAndDeleteItems!(Keys);
		ClearAndDeleteItems!(Values);
		for (let k in other.Keys)
			Keys.Add(new String(k));
		for (let v in other.Values)
			Values.Add(new String(v));
	}

	public void Declare(StringView declaration)
	{
		let words = scope List<StringView>();
		SplitTopLevel(declaration, ' ', words);
		for (let word in words)
		{
			StringView key = word;
			StringView value = default;
			for (int i = 0; i < word.Length; i++)
			{
				if (word[i] == '=')
				{
					key = word.Substring(0, i);
					value = word.Substring(i + 1, word.Length - i - 1);
					break;
				}
			}
			bool replaced = false;
			for (int k = 0; k < Keys.Count; k++)
			{
				if (Keys[k] == key)
				{
					Values[k].Set(value);
					replaced = true;
				}
			}
			if (!replaced)
			{
				Keys.Add(new String(key));
				Values.Add(new String(value));
			}
		}
	}

	/// The value `key` is declared with (empty for a bare identifier), or null when it is not.
	public String Find(StringView key)
	{
		for (int k = 0; k < Keys.Count; k++)
		{
			if (Keys[k] == key)
				return Values[k];
		}
		return null;
	}
}

/// A context predicate: identifiers, `a == b`, `a != b`, `!p`, `p && q`, `p || q`, parentheses,
/// and `p > q` (lowest precedence, after GPUI's): q holds here, inside a context where p held
/// that q did not (a text input inside a menu: "menu > textinput").
class ContextPredicate
{
	private enum Op : uint8
	{
		Identifier,
		Equal,
		NotEqual,
		Not,
		And,
		Or,
		/// Left > Right.
		Inside,
	}

	private class PNode
	{
		public Op Kind;
		/// An identifier; or the key and value of a comparison.
		public String A = new .() ~ delete _;
		public String B = new .() ~ delete _;
		public int32 Left = -1;
		public int32 Right = -1;
	}

	private List<PNode> mNodes = new .() ~ DeleteContainerAndItems!(_);
	/// The text being parsed, cut into tokens: views of it, held only while Parse runs.
	private List<StringView> mTokens = new .() ~ delete _;
	private int32 mRoot = -1;

	/// Parses `text`; false (and matching nothing) when it does not parse. Empty text matches
	/// everywhere.
	public bool Parse(StringView text)
	{
		ClearAndDeleteItems!(mNodes);
		mTokens.Clear();
		mRoot = -1;
		if (ParseUtil.Trim(text).Length == 0)
			return true;
		defer mTokens.Clear();
		if (!Tokenize(text))
			return false;
		int at = 0;
		mRoot = ParseInside(ref at);
		if ((mRoot < 0) || (at != mTokens.Count))
		{
			mRoot = -2; // malformed: matches nothing
			return false;
		}
		return true;
	}

	public bool IsEmpty => mRoot == -1;

	/// Whether it holds at layer `depth` of `stack` (root first).
	public bool Eval(Span<KeyContextLayer> stack, int depth)
	{
		if (mRoot == -1)
			return true;
		return (mRoot >= 0) && (depth < stack.Length) && EvalNode(mRoot, stack, depth);
	}

	/// Whether it holds in one layer alone (nothing around it).
	public bool Eval(KeyContextLayer layer)
	{
		KeyContextLayer[1] one = .(layer);
		return Eval(one, 0);
	}

	private bool Tokenize(StringView text)
	{
		int i = 0;
		bool Two(StringView op) => (i + 1 < text.Length) && (text[i] == op[0]) && (text[i + 1] == op[1]);
		while (i < text.Length)
		{
			let c = text[i];
			if ((c == ' ') || (c == '\t'))
			{
				i++;
				continue;
			}
			if (Two("&&") || Two("||") || Two("==") || Two("!="))
			{
				mTokens.Add(text.Substring(i, 2));
				i += 2;
				continue;
			}
			if ((c == '!') || (c == '(') || (c == ')') || (c == '>'))
			{
				mTokens.Add(text.Substring(i, 1));
				i++;
				continue;
			}
			let start = i;
			while ((i < text.Length) &&
				(((text[i] >= 'a') && (text[i] <= 'z')) || ((text[i] >= 'A') && (text[i] <= 'Z')) ||
				((text[i] >= '0') && (text[i] <= '9')) || (text[i] == '_') || (text[i] == '-') || (text[i] == '.')))
				i++;
			if (i == start)
				return false;
			mTokens.Add(text.Substring(start, i - start));
		}
		return true;
	}

	private bool Is(int at, StringView token) => (at < mTokens.Count) && (mTokens[at] == token);

	private int32 Add(Op kind, StringView a, StringView b, int32 left, int32 right)
	{
		let node = new PNode();
		node.Kind = kind;
		node.A.Set(a);
		node.B.Set(b);
		node.Left = left;
		node.Right = right;
		mNodes.Add(node);
		return (int32)(mNodes.Count - 1);
	}

	private int32 ParseInside(ref int at)
	{
		int32 left = ParseOr(ref at);
		while ((left >= 0) && Is(at, ">"))
		{
			at++;
			let right = ParseOr(ref at);
			if (right < 0)
				return -1;
			left = Add(.Inside, default, default, left, right);
		}
		return left;
	}

	private int32 ParseOr(ref int at)
	{
		int32 left = ParseAnd(ref at);
		while ((left >= 0) && Is(at, "||"))
		{
			at++;
			let right = ParseAnd(ref at);
			if (right < 0)
				return -1;
			left = Add(.Or, default, default, left, right);
		}
		return left;
	}

	private int32 ParseAnd(ref int at)
	{
		int32 left = ParseUnary(ref at);
		while ((left >= 0) && Is(at, "&&"))
		{
			at++;
			let right = ParseUnary(ref at);
			if (right < 0)
				return -1;
			left = Add(.And, default, default, left, right);
		}
		return left;
	}

	private int32 ParseUnary(ref int at)
	{
		if (Is(at, "!"))
		{
			at++;
			let inner = ParseUnary(ref at);
			return (inner < 0) ? -1 : Add(.Not, default, default, inner, -1);
		}
		if (Is(at, "("))
		{
			at++;
			let inner = ParseInside(ref at);
			if ((inner < 0) || !Is(at, ")"))
				return -1;
			at++;
			return inner;
		}
		if ((at >= mTokens.Count) || Is(at, ")") || Is(at, "&&") || Is(at, "||") || Is(at, "==") || Is(at, "!=") || Is(at, ">"))
			return -1;
		let name = mTokens[at++];
		if (Is(at, "==") || Is(at, "!="))
		{
			let op = Is(at, "==") ? Op.Equal : Op.NotEqual;
			at++;
			if (at >= mTokens.Count)
				return -1;
			let value = mTokens[at++];
			return Add(op, name, value, -1, -1);
		}
		return Add(.Identifier, name, default, -1, -1);
	}

	private bool EvalNode(int32 index, Span<KeyContextLayer> stack, int depth)
	{
		let n = mNodes[index];
		let layer = stack[depth];
		switch (n.Kind)
		{
		case .Identifier: return layer.Find(n.A) != null;
		case .Equal:
			let equal = layer.Find(n.A);
			return (equal != null) && (equal == n.B);
		case .NotEqual:
			let other = layer.Find(n.A);
			return (other == null) || (other != n.B);
		case .Not: return !EvalNode(n.Left, stack, depth);
		case .And: return EvalNode(n.Left, stack, depth) && EvalNode(n.Right, stack, depth);
		case .Or: return EvalNode(n.Left, stack, depth) || EvalNode(n.Right, stack, depth);
		case .Inside:
			// The inner holds here, and an outer layer has the outer context without the inner.
			if (!EvalNode(n.Right, stack, depth))
				return false;
			for (int outer = depth - 1; outer >= 0; outer--)
			{
				if (EvalNode(n.Left, stack, outer) && !EvalNode(n.Right, stack, outer))
					return true;
			}
			return false;
		}
	}
}

enum KeymapMatch : uint8
{
	/// No binding: the keystroke goes on (to navigation).
	None,
	/// The start of a chord: wait for the next keystroke.
	Pending,
	/// A command to run (or an unbinding: an empty command).
	Matched,
}

class Keymap
{
	private class KeyBinding
	{
		public List<Keystroke> Sequence = new .() ~ delete _;
		public String Command = new .() ~ delete _;
		public ContextPredicate Context = new .() ~ delete _;
		/// As written, so a Rebind finds the bindings it replaces.
		public String ContextText = new .() ~ delete _;
	}

	private List<KeyBinding> mBindings = new .() ~ DeleteContainerAndItems!(_);
	/// A binding added: shortcut text follows.
	private Observable mChanged = new .() ~ delete _;

	/// Binds `keys` (a keystroke, or a chord of them separated by spaces) to `command` where
	/// `context` holds (empty: everywhere); an empty command unbinds the keys there. False when
	/// the keys or the context do not parse.
	public bool Bind(StringView keys, StringView command, StringView context = default)
	{
		let binding = new KeyBinding();
		let parts = scope List<StringView>();
		SplitTopLevel(keys, ' ', parts);
		for (let part in parts)
		{
			let stroke = ParseKeystroke(part);
			if (!stroke.HasValue)
			{
				delete binding;
				return false;
			}
			binding.Sequence.Add(stroke.Value);
		}
		if (binding.Sequence.IsEmpty || !binding.Context.Parse(context))
		{
			delete binding;
			return false;
		}
		binding.Command.Set(command);
		binding.ContextText.Set(ParseUtil.Trim(context));
		mBindings.Add(binding);
		mChanged.Notify();
		return true;
	}

	/// Binds `keys` to `command` where `context` holds in place of the keys bound to it there
	/// before (by a Bind or Rebind with the same context): those keys no longer run it, as a user's
	/// shortcut setting does (a Bind adds, the old key still working). False when the keys or the
	/// context do not parse; nothing changes then.
	public bool Rebind(StringView keys, StringView command, StringView context = default)
	{
		let check = scope ContextPredicate();
		if (!check.Parse(context))
			return false;
		let parts = scope List<StringView>();
		SplitTopLevel(keys, ' ', parts);
		for (let part in parts)
		{
			if (!ParseKeystroke(part).HasValue)
				return false;
		}
		UnbindCommand(command, context);
		return Bind(keys, command, context);
	}

	/// Takes away the keys bound to `command` where `context` holds (by a Bind with the same
	/// context): how many bindings went. Other commands on those keys keep them.
	public int UnbindCommand(StringView command, StringView context = default)
	{
		let contextText = ParseUtil.Trim(context);
		int removed = 0;
		for (int i = mBindings.Count - 1; i >= 0; i--)
		{
			if ((mBindings[i].Command == command) && (mBindings[i].ContextText == contextText))
			{
				delete mBindings[i];
				mBindings.RemoveAt(i);
				removed++;
			}
		}
		if (removed != 0)
			mChanged.Notify();
		return removed;
	}

	/// Binds one keystroke (made, not parsed: from an input map) to `command` where `context`
	/// holds; false when the context does not parse.
	public bool Bind(Keystroke stroke, StringView command, StringView context = default)
	{
		let binding = new KeyBinding();
		binding.Sequence.Add(stroke);
		if (!binding.Context.Parse(context))
		{
			delete binding;
			return false;
		}
		binding.Command.Set(command);
		binding.ContextText.Set(ParseUtil.Trim(context));
		mBindings.Add(binding);
		mChanged.Notify();
		return true;
	}

	public int BindingCount => mBindings.Count;

	/// The keys bound to `command` as a menu shows them ("Ctrl+S", a chord's strokes spaced),
	/// from the latest binding to it (the one that wins a tie), appended to `outText`; nothing
	/// when none. A read a binding follows: a rebinding changes it.
	public void ShortcutText(StringView command, String outText)
	{
		ShortcutText(command, default, outText);
	}

	/// The keys that run `command` where the context `stack` holds (root first; a menu item's
	/// own), appended to `outText`: the binding a keystroke there would match, so a shortcut shown
	/// is one that works there. With an empty stack, any binding, the last first.
	public void ShortcutText(StringView command, Span<KeyContextLayer> stack, String outText)
	{
		mChanged.Track();
		KeyBinding chosen = null;
		int32 bestDepth = -2;
		for (int i = mBindings.Count - 1; i >= 0; i--)
		{
			let b = mBindings[i];
			if (b.Command != command)
				continue;
			int32 depth = (stack.Length == 0) ? -1 : MatchDepth(b, stack);
			if (depth > bestDepth) // deeper wins; at a tie, the later binding (met first here)
			{
				bestDepth = depth;
				chosen = b;
			}
		}
		if (chosen == null)
			return;
		for (int k = 0; k < chosen.Sequence.Count; k++)
		{
			if (k > 0)
				outText.Append(' ');
			KeystrokeText(chosen.Sequence[k], outText);
		}
	}

	/// The binding `typed` is whole for in `stack` (none longer considered): what a chord cut
	/// short (timed out, or broken off by a key that continues no binding) runs, its command set
	/// into `command`. False when none.
	public bool MatchWhole(Span<Keystroke> typed, Span<KeyContextLayer> stack, String command)
	{
		int32 bestDepth = -2;
		KeyBinding best = null;
		for (let binding in mBindings)
		{
			if (binding.Sequence.Count != typed.Length)
				continue;
			bool same = true;
			for (int i = 0; (i < typed.Length) && same; i++)
				same = binding.Sequence[i] == typed[i];
			if (!same)
				continue;
			let depth = MatchDepth(binding, stack);
			if ((depth >= -1) && (depth >= bestDepth))
			{
				bestDepth = depth;
				best = binding;
			}
		}
		if ((best == null) || (best.Command.Length == 0))
			return false;
		command.Set(best.Command);
		return true;
	}

	/// Matches what was typed (a chord so far) against the bindings in the context `stack`
	/// (root first). On Matched, `command` is set to the winner's (empty for an unbinding).
	public KeymapMatch Match(Span<Keystroke> typed, Span<KeyContextLayer> stack, String command)
	{
		int32 bestDepth = -2;
		KeyBinding best = null;
		bool pending = false;
		for (let binding in mBindings)
		{
			if (binding.Sequence.Count < typed.Length)
				continue;
			bool prefix = true;
			for (int i = 0; i < typed.Length; i++)
			{
				if (!(binding.Sequence[i] == typed[i]))
				{
					prefix = false;
					break;
				}
			}
			if (!prefix)
				continue;
			let depth = MatchDepth(binding, stack);
			if (depth < -1)
				continue; // its context does not hold at the focus
			if (binding.Sequence.Count > typed.Length)
			{
				pending = true;
				continue;
			}
			if (depth >= bestDepth) // deeper wins; at a tie, the later binding
			{
				bestDepth = depth;
				best = binding;
			}
		}
		if (pending && ((best == null) || (bestDepth < 0)))
			return .Pending; // a chord may follow (a contextual full match still wins)
		if (best == null)
			return .None;
		command.Set(best.Command);
		return .Matched;
	}

	/// How deep the binding's context sits: it must hold at the focus (the deepest layer, which
	/// carries every context declared above it), and its depth is the shallowest layer from which
	/// it holds all the way down. A layer repeats its ancestors' contexts, so "game" set on the
	/// screen holds at the menu's layer too, yet it sits at the screen's depth and the menu's own
	/// bindings outrank it. -1 for a binding with no context (the least specific); -2 when its
	/// context does not hold at the focus.
	private static int32 MatchDepth(KeyBinding binding, Span<KeyContextLayer> stack)
	{
		if (binding.Context.IsEmpty)
			return -1;
		if ((stack.Length == 0) || !binding.Context.Eval(stack, stack.Length - 1))
			return -2;
		int depth = stack.Length - 1;
		while ((depth > 0) && binding.Context.Eval(stack, depth - 1))
			depth--;
		return (int32)depth;
	}
}
