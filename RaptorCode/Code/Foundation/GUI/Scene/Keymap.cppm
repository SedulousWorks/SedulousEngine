// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :keymap partition
//
// Bindings from keys and gamepad buttons to commands (G7 of Specs/vg-and-gui-lab.md), after GPUI's
// keymap (`zed/crates/gpui/src/keymap.rs`, `keymap/context.rs`). A binding names a keystroke or a
// chord ("ctrl-s", "ctrl-k ctrl-c", "escape", "pad-east"), a command (empty: the keystroke is
// unbound there) and, optionally, the contexts it applies in as a small predicate over the key
// contexts the focus path declares ("menu", "editor && mode == insert", "!modal"). Each node on the
// focus path may declare a context (Node::SetKeyContext: "editor mode=insert"); a binding matches at
// the deepest depth whose contexts, root to there, satisfy it. Of the bindings for a keystroke, the
// deepest match wins, then the later binding, so a screen's binding beats the GUI's and a later one
// overrides an earlier.

module;
#include "Core/Prelude.h"

export module foundation.gui:keymap;

import foundation.core; // String, Array, Optional, Span
import :event;          // KeyCode, KeyModifier
import :style_value;    // SplitTopLevel
import :reactive;       // Observable (who shows a shortcut follows its bindings)

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    /// A gamepad's buttons as keystrokes take them (the d-pad moves focus, not through bindings).
    enum class PadButton : u32
    {
        South, // A / Cross: activates when unbound
        East,  // B / Circle
        West,
        North,
        Start,
        Back,
        LeftShoulder,
        RightShoulder,
    };

    /// One key with its modifiers, or one gamepad button.
    /// The key context menus and menu bars declare, and the commands their keys run there (E12
    /// of Specs/gui-lab-evolution-2.md): the arrows by default, which a game rebinds like any key.
    /// Each widget gives a direction its meaning (Left closes a submenu, moves along a bar, and
    /// right to left the bar runs the other way).
    inline constexpr const char8_t* kMenuKeyContext = u8"menu";
    inline constexpr const char8_t* kMenuUpCommand = u8"menu.up";
    inline constexpr const char8_t* kMenuDownCommand = u8"menu.down";
    inline constexpr const char8_t* kMenuLeftCommand = u8"menu.left";
    inline constexpr const char8_t* kMenuRightCommand = u8"menu.right";
    /// Back out of where one is (K1 of Specs/gui-lab-evolution-3.md): Escape and the pad's East by
    /// default. The topmost auto popup answers it by closing, a modal dialog as its close button
    /// does, then whatever handles it on the focus path (a game's screen).
    inline constexpr const char8_t* kBackCommand = u8"back";

    struct Keystroke
    {
        u32 Code = 0; ///< a KeyCode, or a PadButton when Pad
        u32 Modifiers = 0;
        bool Pad = false;

        [[nodiscard]] bool operator==(const Keystroke&) const noexcept = default;
    };

    namespace detail
    {
        struct NamedCode
        {
            const char8_t* Name;
            u32 Code;
        };
        /// Every key with a name of its own: what a binding writes ("pageup", "numpad5") and what a
        /// menu shows ("PgUp", "Numpad 5"). Letters, digits and F1 to F24 are named by rule.
        struct NamedKey
        {
            KeyCode Code;
            const char8_t* Name;
            const char8_t* Text;
        };
        inline constexpr NamedKey kKeyNames[] = {
            {KeyCode::Return, u8"enter", u8"Enter"},
            {KeyCode::Return, u8"return", u8"Enter"},
            {KeyCode::Escape, u8"escape", u8"Esc"},
            {KeyCode::Backspace, u8"backspace", u8"Backspace"},
            {KeyCode::Tab, u8"tab", u8"Tab"},
            {KeyCode::Space, u8"space", u8"Space"},
            {KeyCode::Delete, u8"delete", u8"Del"},
            {KeyCode::Insert, u8"insert", u8"Ins"},
            {KeyCode::Home, u8"home", u8"Home"},
            {KeyCode::End, u8"end", u8"End"},
            {KeyCode::PageUp, u8"pageup", u8"PgUp"},
            {KeyCode::PageDown, u8"pagedown", u8"PgDn"},
            {KeyCode::Left, u8"left", u8"Left"},
            {KeyCode::Right, u8"right", u8"Right"},
            {KeyCode::Up, u8"up", u8"Up"},
            {KeyCode::Down, u8"down", u8"Down"},
            {KeyCode::Minus, u8"minus", u8"-"},
            {KeyCode::Equals, u8"equals", u8"="},
            {KeyCode::LeftBracket, u8"leftbracket", u8"["},
            {KeyCode::RightBracket, u8"rightbracket", u8"]"},
            {KeyCode::Backslash, u8"backslash", u8"\\"},
            {KeyCode::Semicolon, u8"semicolon", u8";"},
            {KeyCode::Apostrophe, u8"apostrophe", u8"'"},
            {KeyCode::Grave, u8"grave", u8"`"},
            {KeyCode::Comma, u8"comma", u8","},
            {KeyCode::Period, u8"period", u8"."},
            {KeyCode::Slash, u8"slash", u8"/"},
            {KeyCode::CapsLock, u8"capslock", u8"Caps Lock"},
            {KeyCode::ScrollLock, u8"scrolllock", u8"Scroll Lock"},
            {KeyCode::NumLock, u8"numlock", u8"Num Lock"},
            {KeyCode::PrintScreen, u8"printscreen", u8"Print Screen"},
            {KeyCode::Pause, u8"pause", u8"Pause"},
            {KeyCode::Menu, u8"menu", u8"Menu"},
            {KeyCode::Keypad0, u8"numpad0", u8"Numpad 0"},
            {KeyCode::Keypad1, u8"numpad1", u8"Numpad 1"},
            {KeyCode::Keypad2, u8"numpad2", u8"Numpad 2"},
            {KeyCode::Keypad3, u8"numpad3", u8"Numpad 3"},
            {KeyCode::Keypad4, u8"numpad4", u8"Numpad 4"},
            {KeyCode::Keypad5, u8"numpad5", u8"Numpad 5"},
            {KeyCode::Keypad6, u8"numpad6", u8"Numpad 6"},
            {KeyCode::Keypad7, u8"numpad7", u8"Numpad 7"},
            {KeyCode::Keypad8, u8"numpad8", u8"Numpad 8"},
            {KeyCode::Keypad9, u8"numpad9", u8"Numpad 9"},
            {KeyCode::KeypadDivide, u8"numpaddivide", u8"Numpad /"},
            {KeyCode::KeypadMultiply, u8"numpadmultiply", u8"Numpad *"},
            {KeyCode::KeypadMinus, u8"numpadminus", u8"Numpad -"},
            {KeyCode::KeypadPlus, u8"numpadplus", u8"Numpad +"},
            {KeyCode::KeypadEnter, u8"numpadenter", u8"Numpad Enter"},
            {KeyCode::KeypadDecimal, u8"numpaddecimal", u8"Numpad ."},
            {KeyCode::LeftCtrl, u8"leftctrl", u8"Left Ctrl"},
            {KeyCode::LeftShift, u8"leftshift", u8"Left Shift"},
            {KeyCode::LeftAlt, u8"leftalt", u8"Left Alt"},
            {KeyCode::LeftSuper, u8"leftsuper", u8"Left Super"},
            {KeyCode::RightCtrl, u8"rightctrl", u8"Right Ctrl"},
            {KeyCode::RightShift, u8"rightshift", u8"Right Shift"},
            {KeyCode::RightAlt, u8"rightalt", u8"Right Alt"},
            {KeyCode::RightSuper, u8"rightsuper", u8"Right Super"},
        };
        /// F1 to F24's place: 1 to 24, or 0 for a key that is none of them.
        [[nodiscard]] constexpr u32 FunctionKeyNumber(KeyCode key) noexcept
        {
            if (key >= KeyCode::F1 && key <= KeyCode::F12)
                return static_cast<u32>(key) - static_cast<u32>(KeyCode::F1) + 1;
            if (key >= KeyCode::F13 && key <= KeyCode::F24)
                return static_cast<u32>(key) - static_cast<u32>(KeyCode::F13) + 13;
            return 0;
        }
        [[nodiscard]] constexpr KeyCode FunctionKey(u32 number) noexcept
        {
            return number <= 12 ? static_cast<KeyCode>(static_cast<u32>(KeyCode::F1) + number - 1)
                                : static_cast<KeyCode>(static_cast<u32>(KeyCode::F13) + number - 13);
        }
        inline constexpr NamedCode kPadNames[] = {
            {u8"south", static_cast<u32>(PadButton::South)},   {u8"east", static_cast<u32>(PadButton::East)},
            {u8"west", static_cast<u32>(PadButton::West)},     {u8"north", static_cast<u32>(PadButton::North)},
            {u8"start", static_cast<u32>(PadButton::Start)},   {u8"back", static_cast<u32>(PadButton::Back)},
            {u8"lb", static_cast<u32>(PadButton::LeftShoulder)}, {u8"rb", static_cast<u32>(PadButton::RightShoulder)},
        };
    }

    /// "ctrl-shift-s", "escape", "pad-east": modifiers (ctrl, shift, alt, super) then a key, joined
    /// by '-'; "pad-" names a gamepad button. Empty on an unknown name.
    [[nodiscard]] inline Optional<Keystroke> ParseKeystroke(core::StringView text)
    {
        Keystroke stroke;
        core::StringView rest = Trim(text);
        if (rest.Size() > 4 && rest.SubStr(0, 4) == core::StringView(u8"pad-"))
        {
            const core::StringView name = rest.SubStr(4, rest.Size() - 4);
            for (const detail::NamedCode& pad : detail::kPadNames)
                if (name == core::StringView(pad.Name))
                    return Keystroke{pad.Code, 0, true};
            return {};
        }
        for (;;)
        {
            usize dash = rest.Size();
            for (usize i = 0; i < rest.Size(); ++i)
                if (rest[i] == u8'-')
                {
                    dash = i;
                    break;
                }
            if (dash == rest.Size())
                break;
            const core::StringView modifier = rest.SubStr(0, dash);
            if (modifier == core::StringView(u8"ctrl"))
                stroke.Modifiers |= KeyModCtrl;
            else if (modifier == core::StringView(u8"shift"))
                stroke.Modifiers |= KeyModShift;
            else if (modifier == core::StringView(u8"alt"))
                stroke.Modifiers |= KeyModAlt;
            else if (modifier == core::StringView(u8"super"))
                stroke.Modifiers |= KeyModSuper;
            else
                return {};
            rest = rest.SubStr(dash + 1, rest.Size() - dash - 1);
        }
        for (const detail::NamedKey& key : detail::kKeyNames)
            if (rest == core::StringView(key.Name))
            {
                stroke.Code = static_cast<u32>(key.Code);
                return stroke;
            }
        // A letter, a digit, or f1 to f24.
        if (rest.Size() == 1 && rest[0] >= u8'a' && rest[0] <= u8'z')
        {
            stroke.Code = static_cast<u32>(kLetterKeys[rest[0] - u8'a']);
            return stroke;
        }
        if (rest.Size() == 1 && rest[0] >= u8'0' && rest[0] <= u8'9')
        {
            stroke.Code = static_cast<u32>(KeyCode::Num0) + static_cast<u32>(rest[0] - u8'0');
            return stroke;
        }
        if (rest.Size() >= 2 && rest.Size() <= 3 && rest[0] == u8'f')
        {
            u32 n = 0;
            for (usize i = 1; i < rest.Size(); ++i)
            {
                if (rest[i] < u8'0' || rest[i] > u8'9')
                    return {};
                n = n * 10 + static_cast<u32>(rest[i] - u8'0');
            }
            if (n >= 1 && n <= 24)
            {
                stroke.Code = static_cast<u32>(detail::FunctionKey(n));
                return stroke;
            }
        }
        return {};
    }

    /// A keystroke as a binding writes it ("ctrl-shift-s", "numpad5", "pad-north"): what ParseKeystroke
    /// reads back (E12: a rebinding screen saves what it captured). Empty for a code with no name.
    [[nodiscard]] inline core::String KeystrokeName(const Keystroke& stroke)
    {
        core::String out;
        if (stroke.Pad)
        {
            for (const detail::NamedCode& pad : detail::kPadNames)
                if (pad.Code == stroke.Code)
                {
                    out.Append(core::StringView(u8"pad-"));
                    out.Append(core::StringView(pad.Name));
                }
            return out;
        }
        const KeyCode key = static_cast<KeyCode>(stroke.Code);
        core::String name;
        for (const detail::NamedKey& n : detail::kKeyNames)
            if (n.Code == key && n.Code != KeyCode::Return)
            {
                name = core::String(core::StringView(n.Name));
                break;
            }
        if (key == KeyCode::Return)
            name = core::String(core::StringView(u8"enter"));
        for (usize i = 0; i < 26 && name.Size() == 0; ++i)
            if (kLetterKeys[i] == key)
                name.PushBack(static_cast<char8_t>(u8'a' + i));
        if (name.Size() == 0 && key >= KeyCode::Num0 && key <= KeyCode::Num9)
            name.PushBack(static_cast<char8_t>(u8'0' + (stroke.Code - static_cast<u32>(KeyCode::Num0))));
        if (const u32 n = detail::FunctionKeyNumber(key); name.Size() == 0 && n != 0)
        {
            name.PushBack(u8'f');
            if (n >= 10)
                name.PushBack(static_cast<char8_t>(u8'0' + n / 10));
            name.PushBack(static_cast<char8_t>(u8'0' + n % 10));
        }
        if (name.Size() == 0)
            return out;
        if ((stroke.Modifiers & KeyModCtrl) != 0)
            out.Append(core::StringView(u8"ctrl-"));
        if ((stroke.Modifiers & KeyModShift) != 0)
            out.Append(core::StringView(u8"shift-"));
        if ((stroke.Modifiers & KeyModAlt) != 0)
            out.Append(core::StringView(u8"alt-"));
        if ((stroke.Modifiers & KeyModSuper) != 0)
            out.Append(core::StringView(u8"super-"));
        out.Append(name.AsView());
        return out;
    }

    /// A keystroke as a menu shows it: "Ctrl+Shift+S", "F10", "Enter", "Pad East".
    [[nodiscard]] inline core::String KeystrokeText(const Keystroke& stroke)
    {
        core::String out;
        if (stroke.Pad)
        {
            out.Append(core::StringView(u8"Pad "));
            static constexpr const char8_t* kPad[] = {u8"South", u8"East", u8"West", u8"North", u8"Start", u8"Back", u8"LB", u8"RB"};
            if (stroke.Code < sizeof(kPad) / sizeof(kPad[0]))
                out.Append(core::StringView(kPad[stroke.Code]));
            return out;
        }
        if ((stroke.Modifiers & KeyModCtrl) != 0)
            out.Append(core::StringView(u8"Ctrl+"));
        if ((stroke.Modifiers & KeyModAlt) != 0)
            out.Append(core::StringView(u8"Alt+"));
        if ((stroke.Modifiers & KeyModShift) != 0)
            out.Append(core::StringView(u8"Shift+"));
        if ((stroke.Modifiers & KeyModSuper) != 0)
            out.Append(core::StringView(u8"Super+"));
        const KeyCode key = static_cast<KeyCode>(stroke.Code);
        for (const detail::NamedKey& n : detail::kKeyNames)
            if (n.Code == key)
            {
                out.Append(core::StringView(n.Text));
                return out;
            }
        for (usize i = 0; i < 26; ++i)
            if (kLetterKeys[i] == key)
            {
                out.PushBack(static_cast<char8_t>(u8'A' + i));
                return out;
            }
        if (key >= KeyCode::Num0 && key <= KeyCode::Num9)
            out.PushBack(static_cast<char8_t>(u8'0' + (stroke.Code - static_cast<u32>(KeyCode::Num0))));
        else if (const u32 n = detail::FunctionKeyNumber(key); n != 0)
        {
            out.PushBack(u8'F');
            if (n >= 10)
                out.PushBack(static_cast<char8_t>(u8'0' + n / 10));
            out.PushBack(static_cast<char8_t>(u8'0' + n % 10));
        }
        return out;
    }

    /// What one node's key context declares: identifiers ("menu") and key=value pairs
    /// ("mode=insert"), separated by spaces. A layer of the stack the focus path builds holds the
    /// declarations of every node from the root to there, a deeper value replacing an outer one.
    struct KeyContextLayer
    {
        Array<core::String> Keys;
        Array<core::String> Values; ///< parallel to Keys; empty for a bare identifier

        void Declare(core::StringView declaration)
        {
            for (const core::StringView word : SplitTopLevel(declaration, u8' '))
            {
                core::StringView key = word, value{};
                for (usize i = 0; i < word.Size(); ++i)
                    if (word[i] == u8'=')
                    {
                        key = word.SubStr(0, i);
                        value = word.SubStr(i + 1, word.Size() - i - 1);
                        break;
                    }
                bool replaced = false;
                for (usize k = 0; k < Keys.Size(); ++k)
                    if (Keys[k].AsView() == key)
                    {
                        Values[k] = core::String(value);
                        replaced = true;
                    }
                if (!replaced)
                {
                    Keys.PushBack(core::String(key));
                    Values.PushBack(core::String(value));
                }
            }
        }
        [[nodiscard]] const core::String* Find(core::StringView key) const
        {
            for (usize k = 0; k < Keys.Size(); ++k)
                if (Keys[k].AsView() == key)
                    return &Values[k];
            return nullptr;
        }
    };

    /// A context predicate: identifiers, `a == b`, `a != b`, `!p`, `p && q`, `p || q`, parentheses,
    /// and `p > q` (lowest precedence, after GPUI's): q holds here, inside a context where p held
    /// that q did not (a text input inside a menu: "menu > textinput").
    class ContextPredicate
    {
    public:
        /// Parses `text`; false (and matching nothing) when it does not parse. Empty text matches
        /// everywhere.
        bool Parse(core::StringView text)
        {
            m_nodes.Clear();
            m_tokens.Clear();
            m_root = -1;
            if (Trim(text).Size() == 0)
                return true;
            if (!Tokenize(text))
                return false;
            usize at = 0;
            m_root = ParseInside(at);
            if (m_root < 0 || at != m_tokens.Size())
            {
                m_root = -2; // malformed: matches nothing
                return false;
            }
            return true;
        }
        [[nodiscard]] bool IsEmpty() const noexcept { return m_root == -1; }
        /// Whether it holds at layer `depth` of `stack` (root first).
        [[nodiscard]] bool Eval(Span<const KeyContextLayer> stack, usize depth) const
        {
            if (m_root == -1)
                return true;
            return m_root >= 0 && depth < stack.Size() && EvalNode(m_root, stack, depth);
        }
        /// Whether it holds in one layer alone (nothing around it).
        [[nodiscard]] bool Eval(const KeyContextLayer& layer) const { return Eval(Span<const KeyContextLayer>(&layer, 1), 0); }

    private:
        enum class Op : u8
        {
            Identifier,
            Equal,
            NotEqual,
            Not,
            And,
            Or,
            Inside, // Left > Right
        };
        struct PNode
        {
            Op Kind;
            core::String A, B; // an identifier; or the key and value of a comparison
            i32 Left = -1, Right = -1;
        };
        Array<PNode> m_nodes;
        Array<core::String> m_tokens;
        i32 m_root = -1;

        bool Tokenize(core::StringView text)
        {
            for (usize i = 0; i < text.Size();)
            {
                const char8_t c = text[i];
                if (c == u8' ' || c == u8'\t')
                {
                    ++i;
                    continue;
                }
                const auto two = [&](const char8_t* op) { return i + 1 < text.Size() && text[i] == op[0] && text[i + 1] == op[1]; };
                if (two(u8"&&") || two(u8"||") || two(u8"==") || two(u8"!="))
                {
                    m_tokens.PushBack(core::String(text.SubStr(i, 2)));
                    i += 2;
                    continue;
                }
                if (c == u8'!' || c == u8'(' || c == u8')' || c == u8'>')
                {
                    m_tokens.PushBack(core::String(text.SubStr(i, 1)));
                    ++i;
                    continue;
                }
                const usize start = i;
                while (i < text.Size() &&
                       ((text[i] >= u8'a' && text[i] <= u8'z') || (text[i] >= u8'A' && text[i] <= u8'Z') ||
                        (text[i] >= u8'0' && text[i] <= u8'9') || text[i] == u8'_' || text[i] == u8'-' || text[i] == u8'.'))
                    ++i;
                if (i == start)
                    return false;
                m_tokens.PushBack(core::String(text.SubStr(start, i - start)));
            }
            return true;
        }
        [[nodiscard]] bool Is(usize at, const char8_t* token) const
        {
            return at < m_tokens.Size() && m_tokens[at].AsView() == core::StringView(token);
        }
        i32 Add(PNode node)
        {
            m_nodes.PushBack(Move(node));
            return static_cast<i32>(m_nodes.Size() - 1);
        }
        i32 ParseInside(usize& at)
        {
            i32 left = ParseOr(at);
            while (left >= 0 && Is(at, u8">"))
            {
                ++at;
                const i32 right = ParseOr(at);
                if (right < 0)
                    return -1;
                left = Add(PNode{Op::Inside, {}, {}, left, right});
            }
            return left;
        }
        i32 ParseOr(usize& at)
        {
            i32 left = ParseAnd(at);
            while (left >= 0 && Is(at, u8"||"))
            {
                ++at;
                const i32 right = ParseAnd(at);
                if (right < 0)
                    return -1;
                left = Add(PNode{Op::Or, {}, {}, left, right});
            }
            return left;
        }
        i32 ParseAnd(usize& at)
        {
            i32 left = ParseUnary(at);
            while (left >= 0 && Is(at, u8"&&"))
            {
                ++at;
                const i32 right = ParseUnary(at);
                if (right < 0)
                    return -1;
                left = Add(PNode{Op::And, {}, {}, left, right});
            }
            return left;
        }
        i32 ParseUnary(usize& at)
        {
            if (Is(at, u8"!"))
            {
                ++at;
                const i32 inner = ParseUnary(at);
                return inner < 0 ? -1 : Add(PNode{Op::Not, {}, {}, inner, -1});
            }
            if (Is(at, u8"("))
            {
                ++at;
                const i32 inner = ParseInside(at);
                if (inner < 0 || !Is(at, u8")"))
                    return -1;
                ++at;
                return inner;
            }
            if (at >= m_tokens.Size() || Is(at, u8")") || Is(at, u8"&&") || Is(at, u8"||") || Is(at, u8"==") || Is(at, u8"!=") ||
                Is(at, u8">"))
                return -1;
            core::String name = m_tokens[at++];
            if (Is(at, u8"==") || Is(at, u8"!="))
            {
                const Op op = Is(at, u8"==") ? Op::Equal : Op::NotEqual;
                ++at;
                if (at >= m_tokens.Size())
                    return -1;
                return Add(PNode{op, Move(name), m_tokens[at++], -1, -1});
            }
            return Add(PNode{Op::Identifier, Move(name), {}, -1, -1});
        }
        [[nodiscard]] bool EvalNode(i32 index, Span<const KeyContextLayer> stack, usize depth) const
        {
            const PNode& n = m_nodes[static_cast<usize>(index)];
            const KeyContextLayer& layer = stack[depth];
            switch (n.Kind)
            {
            case Op::Identifier: return layer.Find(n.A.AsView()) != nullptr;
            case Op::Equal:
            {
                const core::String* v = layer.Find(n.A.AsView());
                return v != nullptr && v->AsView() == n.B.AsView();
            }
            case Op::NotEqual:
            {
                const core::String* v = layer.Find(n.A.AsView());
                return v == nullptr || v->AsView() != n.B.AsView();
            }
            case Op::Not: return !EvalNode(n.Left, stack, depth);
            case Op::And: return EvalNode(n.Left, stack, depth) && EvalNode(n.Right, stack, depth);
            case Op::Or: return EvalNode(n.Left, stack, depth) || EvalNode(n.Right, stack, depth);
            case Op::Inside:
                // The inner holds here, and an outer layer has the outer context without the inner.
                if (!EvalNode(n.Right, stack, depth))
                    return false;
                for (usize outer = depth; outer-- > 0;)
                    if (EvalNode(n.Left, stack, outer) && !EvalNode(n.Right, stack, outer))
                        return true;
                return false;
            }
            return false;
        }
    };

    enum class KeymapMatch : u8
    {
        None,    ///< no binding: the keystroke goes on (to navigation)
        Pending, ///< the start of a chord: wait for the next keystroke
        Matched, ///< a command to run (or an unbinding: an empty command)
    };

    class Keymap
    {
    public:
        /// Binds `keys` (a keystroke, or a chord of them separated by spaces) to `command` where
        /// `context` holds (empty: everywhere); an empty command unbinds the keys there. False when
        /// the keys or the context do not parse.
        bool Bind(core::StringView keys, core::StringView command, core::StringView context = {})
        {
            KeyBinding binding;
            for (const core::StringView part : SplitTopLevel(keys, u8' '))
            {
                const Optional<Keystroke> stroke = ParseKeystroke(part);
                if (!stroke.HasValue())
                    return false;
                binding.Sequence.PushBack(stroke.Value());
            }
            if (binding.Sequence.IsEmpty() || !binding.Context.Parse(context))
                return false;
            binding.Command = core::String(command);
            m_bindings.PushBack(Move(binding));
            m_changed.Notify();
            return true;
        }
        /// Binds one keystroke (made, not parsed: from an input map) to `command` where `context`
        /// holds; false when the context does not parse.
        bool Bind(const Keystroke& stroke, core::StringView command, core::StringView context = {})
        {
            KeyBinding binding;
            binding.Sequence.PushBack(stroke);
            if (!binding.Context.Parse(context))
                return false;
            binding.Command = core::String(command);
            m_bindings.PushBack(Move(binding));
            m_changed.Notify();
            return true;
        }
        [[nodiscard]] usize BindingCount() const noexcept { return m_bindings.Size(); }

        /// The keys bound to `command` as a menu shows them ("Ctrl+S", a chord's strokes spaced),
        /// from the latest binding to it (the one that wins a tie); empty when none. A read a
        /// binding follows: a rebinding changes it.
        [[nodiscard]] core::String ShortcutText(core::StringView command) const
        {
            return ShortcutText(command, Span<const KeyContextLayer>{});
        }
        /// The keys that run `command` where the context `stack` holds (root first; a menu item's
        /// own): the binding a keystroke there would match, so a shortcut shown is one that works
        /// there. With an empty stack, any binding, the last first.
        [[nodiscard]] core::String ShortcutText(core::StringView command, Span<const KeyContextLayer> stack) const
        {
            m_changed.Track();
            const KeyBinding* chosen = nullptr;
            i32 bestDepth = -2;
            for (usize i = m_bindings.Size(); i-- > 0;)
            {
                const KeyBinding& b = m_bindings[i];
                if (b.Command.AsView() != command)
                    continue;
                const i32 depth = stack.Size() == 0 ? -1 : MatchDepth(b, stack);
                if (depth > bestDepth) // deeper wins; at a tie, the later binding (met first here)
                {
                    bestDepth = depth;
                    chosen = &b;
                }
            }
            if (chosen != nullptr)
            {
                const KeyBinding& b = *chosen;
                core::String text;
                for (usize k = 0; k < b.Sequence.Size(); ++k)
                {
                    if (k > 0)
                        text.PushBack(u8' ');
                    text.Append(KeystrokeText(b.Sequence[k]).AsView());
                }
                return text;
            }
            return {};
        }
        /// The binding `typed` is whole for in `stack` (none longer considered): what a chord cut
        /// short (timed out, or broken off by a key that continues no binding) runs. False when none.
        [[nodiscard]] bool MatchWhole(Span<const Keystroke> typed, Span<const KeyContextLayer> stack, core::String& command) const
        {
            i32 bestDepth = -2;
            const KeyBinding* best = nullptr;
            for (const KeyBinding& binding : m_bindings)
            {
                if (binding.Sequence.Size() != typed.Size())
                    continue;
                bool same = true;
                for (usize i = 0; i < typed.Size() && same; ++i)
                    same = binding.Sequence[i] == typed[i];
                if (!same)
                    continue;
                const i32 depth = MatchDepth(binding, stack);
                if (depth >= -1 && depth >= bestDepth)
                {
                    bestDepth = depth;
                    best = &binding;
                }
            }
            if (best == nullptr || best->Command.Size() == 0)
                return false;
            command = best->Command;
            return true;
        }

        /// Matches what was typed (a chord so far) against the bindings in the context `stack`
        /// (root first). On Matched, `command` is the winner's (empty for an unbinding).
        [[nodiscard]] KeymapMatch Match(Span<const Keystroke> typed, Span<const KeyContextLayer> stack,
                                        core::String& command) const
        {
            i32 bestDepth = -2;
            const KeyBinding* best = nullptr;
            bool pending = false;
            for (const KeyBinding& binding : m_bindings)
            {
                if (binding.Sequence.Size() < typed.Size())
                    continue;
                bool prefix = true;
                for (usize i = 0; i < typed.Size(); ++i)
                    if (!(binding.Sequence[i] == typed[i]))
                    {
                        prefix = false;
                        break;
                    }
                if (!prefix)
                    continue;
                const i32 depth = MatchDepth(binding, stack);
                if (depth < -1)
                    continue; // its context does not hold at the focus
                if (binding.Sequence.Size() > typed.Size())
                {
                    pending = true;
                    continue;
                }
                if (depth >= bestDepth) // deeper wins; at a tie, the later binding
                {
                    bestDepth = depth;
                    best = &binding;
                }
            }
            if (pending && (best == nullptr || bestDepth < 0))
                return KeymapMatch::Pending; // a chord may follow (a contextual full match still wins)
            if (best == nullptr)
                return KeymapMatch::None;
            command = best->Command;
            return KeymapMatch::Matched;
        }

    private:
        struct KeyBinding
        {
            Array<Keystroke> Sequence;
            core::String Command;
            ContextPredicate Context;
        };
        Array<KeyBinding> m_bindings;
        Observable m_changed; // a binding added: shortcut text follows

        // How deep the binding's context sits: it must hold at the focus (the deepest layer, which
        // carries every context declared above it), and its depth is the shallowest layer from
        // which it holds all the way down. A layer repeats its ancestors' contexts, so "game" set
        // on the screen holds at the menu's layer too, yet it sits at the screen's depth and the
        // menu's own bindings outrank it. -1 for a binding with no context (the least specific);
        // -2 when its context does not hold at the focus.
        [[nodiscard]] static i32 MatchDepth(const KeyBinding& binding, Span<const KeyContextLayer> stack)
        {
            if (binding.Context.IsEmpty())
                return -1;
            if (stack.Size() == 0 || !binding.Context.Eval(stack, stack.Size() - 1))
                return -2;
            usize depth = stack.Size() - 1;
            while (depth > 0 && binding.Context.Eval(stack, depth - 1))
                --depth;
            return static_cast<i32>(depth);
        }
    };
}
