// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - damage (E15 of Specs/gui-lab-evolution-2.md): a frame notes the area it changed, in device
// pixels, for a host that presents part of a frame: all of it at first, nothing when nothing
// changed, a label's box when its text changes, both places when a box moves, and where a box
// showed when it is removed or hidden.
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
    struct Screen
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<UIWidget> box = core::MakeRef<UIWidget>(core::DefaultAllocator());
        core::RefPtr<UIWidget> other = core::MakeRef<UIWidget>(core::DefaultAllocator());

        Screen()
        {
            root->SetSize(core::Float2{400.0f, 300.0f});
            box->SetPosition(core::Float2{20.0f, 30.0f});
            box->SetSize(core::Float2{50.0f, 40.0f});
            box->SetBox(FilledBox(core::Color{1.0f, 0.0f, 0.0f, 1.0f}));
            other->SetPosition(core::Float2{200.0f, 200.0f});
            other->SetSize(core::Float2{60.0f, 20.0f});
            other->SetBox(FilledBox(core::Color{0.0f, 0.0f, 1.0f, 1.0f}));
            root->AddChild(box.Get());
            root->AddChild(other.Get());
        }
        const Rect& Frame()
        {
            (void)root->UpdateLayout();
            vg::VGContext canvas;
            DrawContext dc{canvas};
            root->DrawFrame(dc);
            return root->GetLastDamageBounds();
        }
    };

    bool Covers(const Rect& outer, const Rect& inner)
    {
        return outer.x <= inner.x && outer.y <= inner.y && outer.Right() >= inner.Right() && outer.Bottom() >= inner.Bottom();
    }
}

TEST_CASE("damage: all at first, nothing when nothing changed, a box's area when it changes")
{
    Screen w;
    const Rect first = w.Frame();
    CHECK(Covers(first, Rect{0.0f, 0.0f, 400.0f, 300.0f}));
    w.Frame();
    CHECK(w.root->GetLastDamage().IsEmpty());

    w.box->SetBox(FilledBox(core::Color{0.0f, 1.0f, 0.0f, 1.0f})); // a colour: its own box alone
    const Rect changed = w.Frame();
    CHECK(Covers(changed, Rect{20.0f, 30.0f, 50.0f, 40.0f}));
    CHECK(changed.width <= 51.0f);
    CHECK(changed.height <= 41.0f);
}

TEST_CASE("damage: a box moved damages where it was and where it is; one removed or hidden where it was")
{
    Screen w;
    w.Frame();
    w.box->SetPosition(core::Float2{120.0f, 30.0f});
    const Rect moved = w.Frame();
    CHECK(Covers(moved, Rect{20.0f, 30.0f, 50.0f, 40.0f}));
    CHECK(Covers(moved, Rect{120.0f, 30.0f, 50.0f, 40.0f}));
    CHECK_FALSE(Covers(moved, Rect{200.0f, 200.0f, 60.0f, 20.0f})); // the other box is not

    w.other->SetVisible(false);
    const Rect hidden = w.Frame();
    CHECK(Covers(hidden, Rect{200.0f, 200.0f, 60.0f, 20.0f}));
    CHECK(hidden.x >= 199.0f);

    w.root->RemoveChild(w.box.Get());
    const Rect removed = w.Frame();
    CHECK(Covers(removed, Rect{120.0f, 30.0f, 50.0f, 40.0f}));
}

TEST_CASE("damage: in device pixels, at the display's scale")
{
    Screen w;
    w.root->SetDisplayScale(2.0f);
    w.Frame();
    w.box->SetBox(FilledBox(core::Color{0.0f, 1.0f, 0.0f, 1.0f}));
    const Rect changed = w.Frame();
    CHECK(Covers(changed, Rect{40.0f, 60.0f, 100.0f, 80.0f}));
}
