// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - Expander (E6): HTML's <details>. Its header toggles `open` and reports `toggle`; one of a
// name per GUI open at a time; content built on first open; an optional eased height.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.vg;
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

    core::RefPtr<SceneRoot> MakeRoot()
    {
        auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        root->SetSize(core::Float2{300.0f, 400.0f});
        return root;
    }

    core::RefPtr<Expander> AddExpander(SceneRoot& root, float contentHeight)
    {
        auto e = Make<Expander>();
        e->SetTitle(core::StringView(u8"Advanced"));
        auto body = Make<Panel>();
        body->EditLayoutStyle([contentHeight](LayoutStyle& s) { s.Height = LayoutLength::Px(contentHeight); });
        e->GetContent()->AddChild(body.Get());
        root.AddChild(e.Get());
        return e;
    }
}

TEST_CASE("expander: its header toggles it, reporting toggle; closed it takes only its header's height")
{
    auto root = MakeRoot();
    auto e = AddExpander(*root, 80.0f);
    int toggles = 0;
    bool lastOpen = false;
    (void)e->AddEventListener(EventType::Toggle, [&](const Event& ev)
    {
        ++toggles;
        lastOpen = static_cast<const ToggleEvent&>(ev).Open;
    });
    (void)root->UpdateLayout();
    const float closed = e->GetSize().y;
    CHECK(e->GetHeader()->GetText() == core::StringView(u8"Advanced"));
    CHECK_FALSE(e->IsOpen());

    EventDispatcher& d = *root->GetEventDispatcher();
    const Rect header = e->GetHeader()->GetScreenBounds();
    d.InjectMouseDown(core::Float2{header.x + 30.0f, header.y + header.height * 0.5f}, MouseButton::Left);
    d.InjectMouseUp(core::Float2{header.x + 30.0f, header.y + header.height * 0.5f}, MouseButton::Left);
    CHECK(e->IsOpen());
    CHECK(toggles == 1);
    CHECK(lastOpen);
    CHECK((e->GetWidgetStates() & WidgetStateChecked) != 0);
    (void)root->UpdateLayout();
    CHECK(e->GetSize().y == doctest::Approx(closed + 80.0f));

    // The keyboard: the header is a button.
    e->GetHeader()->RequestFocus();
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Return));
    CHECK_FALSE(e->IsOpen());
    CHECK(toggles == 2);
}

TEST_CASE("expander: one of a name in a GUI open at a time; content built on first open")
{
    auto root = MakeRoot();
    auto a = AddExpander(*root, 40.0f);
    auto b = AddExpander(*root, 40.0f);
    a->SetName(core::String(u8"faq"));
    b->SetName(core::String(u8"faq"));
    auto otherRoot = MakeRoot();
    auto elsewhere = AddExpander(*otherRoot, 40.0f);
    elsewhere->SetName(core::String(u8"faq"));
    elsewhere->SetOpen(true);

    a->SetOpen(true);
    b->SetOpen(true);
    CHECK_FALSE(a->IsOpen());
    CHECK(b->IsOpen());
    CHECK(elsewhere->IsOpen()); // another GUI

    int built = 0;
    auto lazy = AddExpander(*root, 10.0f);
    lazy->SetContentFactory([&](Node& content)
    {
        ++built;
        content.AddChild(Make<Panel>().Get());
    });
    CHECK(built == 0);
    lazy->SetOpen(true);
    lazy->SetOpen(false);
    lazy->SetOpen(true);
    CHECK(built == 1);
    CHECK(lazy->GetContent()->ChildCount() == 2);
}

TEST_CASE("expander: animated, its height eases open through a clip and back")
{
    auto root = MakeRoot();
    root->EditLayoutStyle([](LayoutStyle& s) { s.AlignItems = Align::Start; });
    auto e = AddExpander(*root, 100.0f);
    e->SetAnimated(true);
    (void)root->UpdateLayout();
    const float closed = e->GetSize().y;
    GUIContext& gui = root->GetContext();

    e->SetOpen(true);
    (void)root->UpdateLayout();
    gui.Update(core::Duration::FromSeconds(0.09)); // half way: smoothstep(0.5) = 0.5
    (void)root->UpdateLayout();
    CHECK(e->GetSize().y == doctest::Approx(closed + 50.0f).epsilon(0.05));
    gui.Update(core::Duration::FromSeconds(0.2));
    (void)root->UpdateLayout();
    CHECK(e->GetSize().y == doctest::Approx(closed + 100.0f));
    CHECK(e->GetReveal() == doctest::Approx(1.0f));

    e->SetOpen(false);
    gui.Update(core::Duration::FromSeconds(0.3));
    (void)root->UpdateLayout();
    CHECK(e->GetSize().y == doctest::Approx(closed));
}

TEST_CASE("expander: markup's children are its content; open, name, title and animate are attributes")
{
    RegisterGuiElements();
    static const ElementSet elements = ElementSet::All();
    MarkupLoader loader(elements, core::DefaultAllocator());
    auto tree = loader.LoadFromString(core::StringView(u8R"(<Expander title="More" open="true" name="g" animate="true"><Label text="inside"/></Expander>)"));
    REQUIRE(tree.Get() != nullptr);
    auto* e = core::Cast<Expander>(tree.Get());
    REQUIRE(e != nullptr);
    CHECK(e->IsOpen());
    CHECK(e->IsAnimated());
    CHECK(e->GetName() == core::StringView(u8"g"));
    CHECK(e->GetTitle() == core::StringView(u8"More"));
    CHECK(e->GetContent()->ChildCount() == 1);
}
