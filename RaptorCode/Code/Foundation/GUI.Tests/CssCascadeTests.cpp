// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - CSS !important + custom-property (variable) tests, end-to-end via the
// parser -> cascade -> resolve (+ typed application for the var-driven background).
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

TEST_CASE("css-vars: end-to-end through the applier")
{
    auto w = Widget(u8"button");
    StyleSheet sheet =
        CSSParser::Parse(SV(u8"button { --bg: #0000ff; background-color: var(--bg); }"));
    ApplyStyle(*w.Get(), sheet.Resolve(*w.Get()));

    CHECK(w->GetBox().BackgroundColor.b == doctest::Approx(1.0f)); // var(--bg) -> #0000ff -> blue
}
