// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :input_filter partition
//
// What a text field lets in, one character at a time: everything, digits, hex digits, or a
// predicate of its own. Typed and pasted text both pass through it.
//
// Copied from foundation.ui's :input_filter (E4 of Specs/gui-lab-evolution.md), and the GUI's own
// from then on.

module;
#include "Core/Prelude.h"

export module foundation.gui:input_filter;

import foundation.core; // Function, Move

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    enum class InputFilterMode
    {
        None,
        Digits,
        HexDigits,
        Custom
    };

    class InputFilter
    {
    public:
        InputFilter() = default;

        [[nodiscard]] InputFilterMode Mode() const noexcept { return m_mode; }
        void SetMode(InputFilterMode mode) noexcept { m_mode = mode; }

        /// A predicate of its own (the mode becomes Custom).
        void SetCustomFilter(core::Function<bool(char32_t)> predicate)
        {
            m_customPredicate = Move(predicate);
            m_mode = InputFilterMode::Custom;
        }

        /// Whether it lets `c` in.
        [[nodiscard]] bool Accept(char32_t c) const
        {
            switch (m_mode)
            {
            case InputFilterMode::None:
                return true;
            case InputFilterMode::Digits:
                return c >= U'0' && c <= U'9';
            case InputFilterMode::HexDigits:
                return (c >= U'0' && c <= U'9') || (c >= U'a' && c <= U'f') || (c >= U'A' && c <= U'F');
            case InputFilterMode::Custom:
                return m_customPredicate ? m_customPredicate(c) : true;
            }
            return true;
        }

        [[nodiscard]] static InputFilter Digits()
        {
            InputFilter f;
            f.m_mode = InputFilterMode::Digits;
            return f;
        }
        [[nodiscard]] static InputFilter HexDigits()
        {
            InputFilter f;
            f.m_mode = InputFilterMode::HexDigits;
            return f;
        }

    private:
        InputFilterMode m_mode = InputFilterMode::None;
        core::Function<bool(char32_t)> m_customPredicate;
    };
}
