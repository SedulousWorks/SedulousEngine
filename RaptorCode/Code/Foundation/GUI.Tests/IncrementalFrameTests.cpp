// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - incremental frames (G4 of Specs/vg-and-gui-lab.md): a frame restyles only the widgets
// that changed and their subtrees, lays out only the containers that asked, once per frame, and
// an idle GUI needs no frame at all.
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
    // A node whose drawing marks another node (one drawn before it) dirty, once.
    class Toucher : public Node
    {
    public:
        Node* Touches = nullptr;
        bool Done = false;

    protected:
        void OnDraw(DrawContext&, const Rect&) override
        {
            if (Touches != nullptr && !Done)
            {
                Done = true;
                Touches->Invalidate();
            }
        }
    };

    template <typename T>
    core::RefPtr<T> Make()
    {
        return core::MakeRef<T>(core::DefaultAllocator());
    }
    core::StringView SV(const char8_t* s) { return core::StringView(s); }
    core::Duration Sec(double s) { return core::Duration::FromSeconds(s); }

    core::RefPtr<UIWidget> Widget(const char8_t* tag)
    {
        auto w = Make<UIWidget>();
        w->SetTag(SV(tag));
        w->SetSize(core::Float2{40.0f, 20.0f});
        return w;
    }

    // One host frame: styles, ticks, lays out and draws, as a sample does.
    void Frame(SceneRoot& root, StyleManager& styles)
    {
        styles.ApplyTree(root);
        root.GetContext().Update(Sec(0.016));
        vg::VGContext canvas;
        DrawContext dc{canvas};
        root.Draw(dc);
    }
}

TEST_CASE("incremental: a list's insert above and a click's selection each ask for a frame")
{
    StringListModel model; // outlives the scene, whose list is its client
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{300.0f, 300.0f});
    for (int i = 0; i < 50; ++i)
        model.AddItem(core::Format(u8"row {}", i).AsView());
    auto list = Make<ListView>();
    list->SetSize(core::Float2{200.0f, 100.0f});
    list->SetRowHeight(20.0f);
    root->AddChild(list.Get());
    list->SetModel(&model);
    StyleManager styles(CSSParser::Parse(SV(u8"listview { opacity: 1; }")));
    Frame(*root.Get(), styles);
    list->ScrollTo(core::Float2{0.0f, 400.0f}, ScrollBehavior::Instant);
    Frame(*root.Get(), styles);
    list->ScrollTo(core::Float2{0.0f, 0.0f}, ScrollBehavior::Instant); // rows released and taken again
    Frame(*root.Get(), styles);
    Frame(*root.Get(), styles);
    CHECK_FALSE(root->NeedsFrame());

    model.InsertItem(0, SV(u8"inserted"));
    root->GetContext().Update(Sec(0.016));
    (void)root->UpdateLayout();
    CHECK(root->NeedsFrame());
    Frame(*root.Get(), styles);
    Frame(*root.Get(), styles);
    CHECK_FALSE(root->NeedsFrame());

    root->GetEventDispatcher()->InjectMouseDown(core::Float2{50.0f, 30.0f}, MouseButton::Left);
    root->GetEventDispatcher()->InjectMouseUp(core::Float2{50.0f, 30.0f}, MouseButton::Left);
    styles.ApplyTree(*root.Get());
    (void)root->UpdateLayout();
    CHECK(root->NeedsFrame());
}
