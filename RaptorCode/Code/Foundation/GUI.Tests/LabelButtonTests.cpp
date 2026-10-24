// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - Label / Button control tests: text properties, click handling through the
// dispatcher, control-state reaction, and CSS targeting the default `button` tag.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.vg;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
namespace vg = foundation::vg;

namespace
{
    template <typename T>
    core::RefPtr<T> Make()
    {
        return core::MakeRef<T>(core::DefaultAllocator());
    }
    core::StringView SV(const char8_t* s) { return core::StringView(s); }
}

TEST_CASE("label: text properties")
{
    auto label = Make<Label>();
    label->SetText(SV(u8"Hello"));
    CHECK(label->GetText() == SV(u8"Hello"));
    label->SetTextColor(core::Color::Red);
    CHECK(label->GetTextColor().r == doctest::Approx(1.0f));
    CHECK(label->MeasureText().x == 0.0f); // no font yet -> zero measure
}

TEST_CASE("label: draws its box (text is a no-op without a font)")
{
    auto label = Make<Label>();
    label->SetSize(core::Float2{100.0f, 40.0f});
    label->SetText(SV(u8"Hi"));
    label->SetBox(FilledBox(core::Color::Blue));

    vg::VGContext ctx;
    DrawContext dc{ctx};
    label->Draw(dc);
    CHECK(ctx.GetBatch().vertices.Size() + ctx.GetBatch().boxVertices.Size() > 0); // its fill
}

TEST_CASE("button: defaults - tag and centered text")
{
    auto btn = Make<Button>();
    CHECK(btn->GetTag() == SV(u8"button")); // CSS `button` targets it
    btn->SetText(SV(u8"OK"));
    CHECK(btn->GetText() == SV(u8"OK"));
    CHECK_FALSE(btn->HasOnClick());
}

TEST_CASE("button: click callback fires on press+release")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 200.0f});
    auto btn = Make<Button>();
    btn->SetSize(core::Float2{100.0f, 100.0f});
    root->AddChild(btn.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    int clicks = 0;
    btn->SetOnClick([&clicks]() { ++clicks; });
    CHECK(btn->HasOnClick());

    d->InjectMouseDown(core::Float2{50.0f, 50.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{50.0f, 50.0f}, MouseButton::Left);
    CHECK(clicks == 1);

    // Press on the button, release elsewhere -> not a click.
    d->InjectMouseDown(core::Float2{50.0f, 50.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{300.0f, 300.0f}, MouseButton::Left);
    CHECK(clicks == 1);
}

TEST_CASE("button: its states follow the pointer")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 200.0f});
    auto btn = Make<Button>();
    btn->SetSize(core::Float2{100.0f, 100.0f});
    root->AddChild(btn.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    CHECK_FALSE(btn->IsHovered());
    d->InjectMouseMove(core::Float2{50.0f, 50.0f});
    CHECK(btn->IsHovered());
    d->InjectMouseDown(core::Float2{50.0f, 50.0f}, MouseButton::Left);
    CHECK(btn->IsPressed());
}

TEST_CASE("button: styled by CSS through the default tag")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 200.0f});
    auto btn = Make<Button>();
    btn->SetSize(core::Float2{100.0f, 100.0f});
    root->AddChild(btn.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    StyleManager mgr(
        CSSParser::Parse(SV(u8"button { opacity: 1; } button:hover { opacity: 0.3; }")));
    mgr.ApplyTree(*root.Get());
    CHECK(btn->GetAlpha() == doctest::Approx(1.0f));

    d->InjectMouseMove(core::Float2{50.0f, 50.0f}); // hover
    mgr.ApplyTree(*root.Get());                     // re-resolve -> :hover applies
    CHECK(btn->GetAlpha() == doctest::Approx(0.3f));
}
