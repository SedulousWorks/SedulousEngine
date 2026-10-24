// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :parse_util partition
//
// CSS-specific identifier scanning for the styling parsers. The generic helpers
// (IsWhiteSpace / IsDigit / IsHexDigit / HexValue / Trim) now live in foundation.core
// (:string_util); what remains here is the CSS identifier grammar ([A-Za-z0-9_-], which
// includes '-' for kebab-case names), which is CSS-flavored rather than generic.

module;
#include "Core/Prelude.h"

export module foundation.gui:parse_util;

import foundation.core; // StringView

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    // A CSS identifier character: letters, digits, '-' (kebab-case) and '_'.
    [[nodiscard]] constexpr bool IsIdentChar(char8_t c) noexcept
    {
        return (c >= u8'a' && c <= u8'z') || (c >= u8'A' && c <= u8'Z') ||
               (c >= u8'0' && c <= u8'9') || c == u8'-' || c == u8'_';
    }

    // Read an identifier starting at i, advancing i past it.
    [[nodiscard]] inline core::StringView ReadIdent(core::StringView s, usize& i) noexcept
    {
        const usize start = i;
        while (i < s.Size() && IsIdentChar(s[i]))
            ++i;
        return s.SubStr(start, i - start);
    }
}
