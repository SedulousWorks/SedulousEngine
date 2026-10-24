// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - ComboBox tests: item management, opening/closing the dropdown popup, picking
// an item through the dropdown, and dismissal (outside click / Escape) via the dispatcher's
// popup support.
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

    core::RefPtr<ComboBox> MakeCombo(SceneRoot* root)
    {
        auto cb = core::MakeRef<ComboBox>(core::DefaultAllocator());
        cb->SetSize(core::Float2{120.0f, 26.0f});
        cb->SetItemHeight(24.0f);
        cb->AddItem(core::StringView(u8"Red"));
        cb->AddItem(core::StringView(u8"Green"));
        cb->AddItem(core::StringView(u8"Blue"));
        root->AddChild(cb.Get());
        return cb;
    }
}

TEST_CASE("combobox: new items drop the old selection's text; the selection binds and a pick reports a change")
{
    auto cb = Make<ComboBox>();
    cb->SetItemsText(core::String(u8"Low|High"));
    cb->SetSelectedIndex(1);
    CHECK(cb->GetSelectedText() == core::StringView(u8"High"));
    cb->SetItemsText(core::String(u8"A|B|C"));
    CHECK(cb->GetSelectedIndex() == -1);
    CHECK(cb->GetSelectedText().Size() == 0u);

    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 300.0f});
    auto combo = MakeCombo(root.Get());
    DataModel& data = root->GetContext().GetData();
    data.Set(core::StringView(u8"pick"), core::Variant::From<core::i32>(1));
    REQUIRE(combo->BindData(core::StringView(u8"selected"), root->GetContext().GetDataRef(), core::StringView(u8"pick")));
    root->GetContext().Update(core::Duration::FromSeconds(1.0 / 60.0));
    CHECK(combo->GetSelectedIndex() == 1); // the data's
    int changes = 0;
    (void)combo->AddEventListener(EventType::Changed, [&changes](const Event&) { ++changes; });
    combo->SelectByUser(2);
    root->GetContext().Update(core::Duration::FromSeconds(1.0 / 60.0));
    CHECK(changes == 1);
    const core::Variant back = data.Get(core::StringView(u8"pick"));
    REQUIRE(back.TryGet<core::i32>() != nullptr);
    CHECK(*back.TryGet<core::i32>() == 2); // written back
    combo->SetSelectedIndex(0);
    CHECK(changes == 1); // code's change is no user's
}
