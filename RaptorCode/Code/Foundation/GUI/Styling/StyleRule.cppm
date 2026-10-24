// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :style_rule partition
//
// StyleProperty + StyleRule: a CSS declaration block. Ported from eepp's
// css/StyleSheetProperty + StyleSheetStyle. A StyleRule pairs one StyleSelector with a list
// of name/value declarations: the value as written, and its longhands parsed into typed values
// once, by the first cascade that reaches it (a value with var() is parsed at each).

module;
#include "Core/Prelude.h"

export module foundation.gui:style_rule;

import foundation.core; // String, StringView, Array, i64, Move
import :style_selector;
import :media_query;
import :style_properties; // StyleValue

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    /// One longhand a declaration sets, with its value parsed (Kind None when it does not parse).
    struct StyleLonghandValue
    {
        core::String Name;
        core::String Text;
        StyleValue Value;
    };

    struct StyleProperty
    {
        core::String Name;
        core::String Value;
        bool Important = false;
        // The longhands this declaration sets, parsed once (a declaration without var(): its
        // value cannot change); filled by the first cascade that reaches it (StyleSheet).
        mutable bool Cached = false;
        mutable bool CacheValid = false;
        mutable Array<StyleLonghandValue> Longhands;

        StyleProperty() = default;
        StyleProperty(core::StringView name, core::StringView value, bool important = false)
            : Name(name), Value(value), Important(important)
        {
        }
    };

    class StyleRule
    {
    public:
        StyleRule() = default;
        explicit StyleRule(StyleSelector selector) : m_selector(core::Move(selector)) {}
        explicit StyleRule(core::StringView selector) : m_selector(selector) {}

        [[nodiscard]] const StyleSelector& Selector() const noexcept { return m_selector; }
        [[nodiscard]] i64 Specificity() const noexcept { return m_selector.Specificity(); }

        // Set (or override) a declaration.
        void SetProperty(core::StringView name, core::StringView value, bool important = false)
        {
            for (StyleProperty& p : m_properties)
                if (p.Name == name)
                {
                    p.Value = value;
                    p.Important = important;
                    p.Cached = false; // re-expanded and re-parsed on the next cascade
                    p.CacheValid = false;
                    p.Longhands.Clear();
                    return;
                }
            m_properties.PushBack(StyleProperty(name, value, important));
        }

        [[nodiscard]] const Array<StyleProperty>& Properties() const noexcept
        {
            return m_properties;
        }
        [[nodiscard]] usize PropertyCount() const noexcept { return m_properties.Size(); }

        /// Where it was written: its selector as written and its line in its sheet (0: not from a sheet).
        void SetSource(core::StringView selectorText, u32 line)
        {
            m_selectorText = core::String(selectorText);
            m_line = line;
        }
        [[nodiscard]] core::StringView SelectorText() const noexcept { return m_selectorText.AsView(); }
        [[nodiscard]] u32 Line() const noexcept { return m_line; }

        // The @media condition this rule is nested in (empty = always active).
        void SetMedia(MediaQuery media) { m_media = core::Move(media); }
        [[nodiscard]] const MediaQuery& Media() const noexcept { return m_media; }

    private:
        StyleSelector m_selector;
        Array<StyleProperty> m_properties;
        MediaQuery m_media;
        core::String m_selectorText;
        u32 m_line = 0;
    };
}
