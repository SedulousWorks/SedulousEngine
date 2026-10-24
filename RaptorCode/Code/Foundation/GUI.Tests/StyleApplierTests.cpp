// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - CSS value parsers + typed property application: parse value strings into
// Color/length/bool/Thickness, and apply a resolved (or parsed) stylesheet onto a widget.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    template <typename T>
    core::RefPtr<T> Make()
    {
        return core::MakeRef<T>(core::DefaultAllocator());
    }
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    core::RefPtr<UIWidget> Widget(const char8_t* tag)
    {
        auto w = Make<UIWidget>();
        w->SetTag(SV(tag));
        return w;
    }
}

// === value parsers ===

TEST_CASE("style-applier: text-align / vertical-align reach a label")
{
    StyleSheet sheet =
        CSSParser::Parse(SV(u8"label { text-align: center; vertical-align: bottom; }"));
    auto l = Make<Label>(); // Label's ctor tags it "label"
    ApplyStyle(*l.Get(), sheet.Resolve(*l.Get(), MediaContext{}, /*applyPseudo*/ false));
    CHECK(l->GetTextAlignH() == TextHAlign::Center);
    CHECK(l->GetTextAlignV() == TextVAlign::Bottom);

    StyleSheet right = CSSParser::Parse(SV(u8"label { text-align: right; }"));
    ApplyStyle(*l.Get(), right.Resolve(*l.Get(), MediaContext{}, false));
    CHECK(l->GetTextAlignH() == TextHAlign::Right);
    CHECK(l->GetTextAlignV() == TextVAlign::Middle); // no longer set: the label's own again
}

