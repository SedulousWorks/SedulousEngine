// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - tabs (E6): a TabBar of real tab elements and a TabView pairing it with pages. Selection by
// the press, the keys and Ctrl+Tab; closing as a request with a display policy; reordering by a
// drag across a neighbour's midpoint; an overflowing strip that scrolls and lists every tab (or
// always lists them), and a part that closes them all; pages kept alive, or built on first show;
// markup's pages.
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

    core::RefPtr<SceneRoot> MakeRoot(float width = 400.0f)
    {
        auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        root->SetSize(core::Float2{width, 300.0f});
        return root;
    }

    // Tabs of a known width (the tests have no font to size their text).
    Tab* AddSizedTab(TabBar& bar, const char8_t* text, float width = 80.0f)
    {
        Tab* tab = bar.AddTab(core::StringView(text));
        tab->EditLayoutStyle([width](LayoutStyle& s)
        {
            s.Width = LayoutLength::Px(width);
            s.Height = LayoutLength::Px(24.0f);
        });
        return tab;
    }

    core::Float2 CentreOf(const Node& node)
    {
        const Rect r = node.GetScreenBounds();
        return core::Float2{r.x + r.width * 0.5f, r.y + r.height * 0.5f};
    }

    void Press(EventDispatcher& d, core::Float2 at, MouseButton button = MouseButton::Left)
    {
        d.InjectMouseDown(at, button);
        d.InjectMouseUp(at, button);
    }
}

TEST_CASE("tabview: markup's pages are its children, with title, icon and closable; its bar's settings are attributes")
{
    RegisterGuiElements();
    static const ElementSet elements = ElementSet::All();
    MarkupLoader loader(elements, core::DefaultAllocator());
    auto tree = loader.LoadFromString(core::StringView(u8R"(<TabView close-display="hover" reorderable="true" selected="1" list-display="always" close-all="true">
        <TabPage title="General"><Label text="one"/></TabPage>
        <TabPage title="Advanced" closable="false" icon="ui/icons/gear.png"/>
    </TabView>)"));
    REQUIRE(tree.Get() != nullptr);
    auto* view = core::Cast<TabView>(tree.Get());
    REQUIRE(view != nullptr);
    CHECK(view->GetPageCount() == 2);
    CHECK(view->GetBar()->GetTab(0)->GetText() == core::StringView(u8"General"));
    CHECK_FALSE(view->GetBar()->GetTab(1)->IsClosable());
    CHECK(view->GetBar()->GetTab(1)->GetIconSource() == core::StringView(u8"ui/icons/gear.png"));
    CHECK(view->GetBar()->GetCloseDisplay() == TabCloseDisplay::Hover);
    CHECK(view->IsReorderable());
    CHECK(view->GetSelectedIndex() == 1);
    CHECK(view->GetBar()->GetListDisplay() == TabListDisplay::Always);
    CHECK(view->HasCloseAll());

    // A bar alone: markup's children are its tabs.
    auto barTree = loader.LoadFromString(core::StringView(u8R"(<TabBar><Tab text="One"/><Tab text="Two" icon="a.png"/></TabBar>)"));
    auto* bar = core::Cast<TabBar>(barTree.Get());
    REQUIRE(bar != nullptr);
    CHECK(bar->GetTabCount() == 2);
    CHECK(bar->GetSelectedIndex() == 0);
    CHECK(bar->GetTab(1)->GetIconSource() == core::StringView(u8"a.png"));
}

namespace
{
    core::RefPtr<TabBar> BarAt(SceneRoot& root, float y, const char8_t* group)
    {
        auto bar = Make<TabBar>();
        bar->EditLayoutStyle([y](LayoutStyle& s)
        {
            s.Placement = Position::Absolute;
            s.Left = LayoutLength::Px(10.0f);
            s.Top = LayoutLength::Px(y);
            s.Width = LayoutLength::Px(380.0f);
        });
        bar->SetReorderable(true);
        bar->SetGroup(core::String(group));
        root.AddChild(bar.Get());
        return bar;
    }
}
