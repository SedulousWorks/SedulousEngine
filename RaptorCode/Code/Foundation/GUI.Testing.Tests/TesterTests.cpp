// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Testing - the tester (E8f of Specs/gui-lab-evolution.md): finders by selector and text,
// within a scope, hidden ones only when asked; a finder expecting one that finds none or several
// fails with what it found and the tree; the user's actions reach what they aim at, or fail when
// something covers it; the clock steps a frame after each.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;
import foundation.gui.testing;
import foundation.image;

using namespace foundation::gui;
using foundation::gui::testing::Finder;
using foundation::gui::testing::Tester;
namespace core = foundation::core;
using core::f32;
using core::usize;
using core::u32;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    template <typename T>
    core::RefPtr<T> Add(Node& parent, const char8_t* id, f32 x, f32 y, f32 w, f32 h)
    {
        auto node = core::MakeRef<T>(core::DefaultAllocator());
        node->SetId(SV(id));
        node->SetPosition(core::Float2{x, y});
        node->SetSize(core::Float2{w, h});
        parent.AddChild(node.Get());
        return node;
    }

    // A form: a "Show" button, a field, a dialog with its own "OK" beside the form's "OK", and a
    // hidden "Secret" label.
    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<Button> show;
        core::RefPtr<TextField> field;
        core::RefPtr<Panel> dialog;
        core::RefPtr<Button> ok;
        core::RefPtr<Button> dialogOk;
        core::RefPtr<Label> secret;
        int clicks = 0;

        Bed()
        {
            root->SetSize(core::Float2{400.0f, 300.0f});
            show = Add<Button>(*root.Get(), u8"show", 10.0f, 10.0f, 80.0f, 30.0f);
            show->SetText(SV(u8"Show"));
            show->SetOnClick([this]() { ++clicks; });
            field = Add<TextField>(*root.Get(), u8"field", 10.0f, 50.0f, 150.0f, 30.0f);
            ok = Add<Button>(*root.Get(), u8"ok", 10.0f, 90.0f, 80.0f, 30.0f);
            ok->SetText(SV(u8"OK"));
            dialog = Add<Panel>(*root.Get(), u8"dialog", 200.0f, 10.0f, 180.0f, 150.0f);
            dialogOk = Add<Button>(*dialog.Get(), u8"dialog-ok", 10.0f, 10.0f, 80.0f, 30.0f);
            dialogOk->SetText(SV(u8"OK"));
            secret = Add<Label>(*root.Get(), u8"secret", 10.0f, 200.0f, 80.0f, 20.0f);
            secret->SetText(SV(u8"Secret"));
            secret->SetVisible(false);
        }
    };
}

TEST_CASE("testing: finders by selector and by text, within a scope, hidden ones only when asked")
{
    Bed bed;
    Tester t(*bed.root.Get());
    CHECK(t.One(Finder::Selector(SV(u8"#show"))) == bed.show.Get());
    CHECK(t.One(Finder::Text(SV(u8"Show"))) == bed.show.Get()); // the button, not its label part too
    CHECK(t.One(Finder::TextContaining(SV(u8"Sho"))) == bed.show.Get());
    CHECK(t.One(Finder::Text(SV(u8"OK")).Within(Finder::Selector(SV(u8"#dialog")))) == bed.dialogOk.Get());
    CHECK_FALSE(t.Exists(Finder::Text(SV(u8"Secret"))));
    CHECK(t.One(Finder::Text(SV(u8"Secret")).IncludingHidden()) == bed.secret.Get());
    CHECK(t.Failures().IsEmpty());
    CHECK(Finder::Parse(SV(u8"text=OK")).Within(Finder::Parse(SV(u8"#dialog"))).Describe() == SV(u8"text=OK within selector #dialog"));
}

TEST_CASE("testing: expecting one and finding several or none fails, naming what it found, with the tree")
{
    Bed bed;
    Tester t(*bed.root.Get());
    core::Array<core::String> seen;
    t.SetFailureHandler([&seen](core::StringView message) { seen.PushBack(core::String(message)); });
    CHECK(t.One(Finder::Text(SV(u8"OK"))) == nullptr);
    REQUIRE(seen.Size() == 1u);
    const core::StringView message = seen[0].AsView();
    CHECK(message.StartsWith(SV(u8"text=OK found 2 nodes, expected one")));
    CHECK(message.ContainsIgnoreCase(SV(u8"found: Button #ok")));
    CHECK(message.ContainsIgnoreCase(SV(u8"Button #dialog-ok \"OK\""))); // the tree, with texts
    CHECK(t.One(Finder::Selector(SV(u8"#nothing"))) == nullptr);
    CHECK(t.Failures().Size() == 2u);
}

TEST_CASE("testing: clicks reach what they aim at, and fail when something lies over it")
{
    Bed bed;
    Tester t(*bed.root.Get());
    CHECK(t.Click(Finder::Text(SV(u8"Show"))));
    CHECK(bed.clicks == 1);
    u32 most = 0;
    (void)bed.show->AddEventListener(EventType::MouseClick, [&most](const Event& e)
    {
        most = core::Max(most, static_cast<const MouseEvent&>(e).ClickCount);
    });
    t.Advance(core::Duration::FromSeconds(1.0)); // the click before is no part of it
    CHECK(t.DoubleClick(Finder::Selector(SV(u8"#show"))));
    CHECK(most == 2u);
    // A panel laid over the button: the click would land on it.
    auto cover = Add<Panel>(*bed.root.Get(), u8"cover", 0.0f, 0.0f, 120.0f, 60.0f);
    t.Frame();
    const int before = bed.clicks;
    CHECK_FALSE(t.Click(Finder::Selector(SV(u8"#show"))));
    CHECK(bed.clicks == before);
    REQUIRE_FALSE(t.Failures().IsEmpty());
    CHECK(t.Failures()[t.Failures().Size() - 1].AsView().ContainsIgnoreCase(SV(u8"covered at its middle by Panel #cover")));
}

TEST_CASE("testing: typing goes to the focus, keys move it, and a held arrow repeats")
{
    Bed bed;
    Tester t(*bed.root.Get());
    CHECK(t.Click(Finder::Selector(SV(u8"#field"))));
    t.Type(SV(u8"hello"));
    CHECK(bed.field->GetText() == SV(u8"hello"));
    CHECK(t.Press(SV(u8"tab")));
    CHECK(bed.root->GetEventDispatcher()->GetFocusNode() != bed.field.Get());
    CHECK_FALSE(t.Press(SV(u8"no-such-key")));

    // A column of buttons: Down held for a second walks focus down several of them.
    auto column = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    column->SetSize(core::Float2{200.0f, 600.0f});
    core::Array<core::RefPtr<Button>> buttons;
    for (int i = 0; i < 12; ++i)
    {
        char8_t id[4] = {u8'b', static_cast<char8_t>(u8'a' + i), 0, 0};
        buttons.PushBack(Add<Button>(*column.Get(), id, 10.0f, 10.0f + 40.0f * static_cast<f32>(i), 80.0f, 30.0f));
    }
    Tester c(*column.Get());
    column->GetEventDispatcher()->SetFocusNode(buttons[0].Get());
    c.HoldDirection(NavDirection::Down, core::Duration::FromSeconds(1.0));
    usize at = 0;
    for (usize i = 0; i < buttons.Size(); ++i)
        if (column->GetEventDispatcher()->GetFocusNode() == buttons[i].Get())
            at = i;
    CHECK(at >= 3u);
}

TEST_CASE("testing: a drag presses on one node, moves in steps and releases over another")
{
    Bed bed;
    Tester t(*bed.root.Get());
    int moves = 0;
    core::Float2 released{};
    (void)bed.show->AddEventListener(EventType::MouseMove, [&moves](const Event&) { ++moves; });
    (void)bed.show->AddEventListener(EventType::MouseUp, [&released](const Event& e) { released = static_cast<const MouseEvent&>(e).Position; });
    CHECK(t.DragTo(Finder::Selector(SV(u8"#show")), Finder::Selector(SV(u8"#ok"))));
    CHECK(moves >= 8);                                  // the press captures the pointer: every step reaches it
    CHECK(released.y == doctest::Approx(105.0f));       // over the OK button's middle
}

TEST_CASE("testing: a picture matches its reference within a tolerance on all but a share of its pixels")
{
    namespace image = foundation::image;
    const auto picture = [](core::u8 shade, usize changed, core::u8 to)
    {
        core::Array<core::u8> rgba;
        rgba.Resize(100u * 100u * 4u);
        for (usize i = 0; i < rgba.Size(); ++i)
            rgba[i] = (i % 4 == 3) ? core::u8{255} : shade;
        for (usize p = 0; p < changed; ++p)
            rgba[p * 4] = to;
        return image::Image(100, 100, image::PixelFormat::RGBA8, core::Span<const core::u8>{rgba.Data(), rgba.Size()});
    };
    using foundation::gui::testing::CompareImages;
    const image::Image reference = picture(100, 0, 0);
    CHECK(CompareImages(picture(108, 0, 0), reference).Matches);       // every channel within 8
    CHECK_FALSE(CompareImages(picture(109, 0, 0), reference).Matches); // past it everywhere
    CHECK(CompareImages(picture(100, 10, 200), reference).Matches);    // 10 of 10,000: within 0.1%
    image::Image diff;
    const auto far = CompareImages(picture(100, 11, 200), reference, 8, 0.001, &diff); // 11: past it
    CHECK_FALSE(far.Matches);
    CHECK(far.Differing == 11u);
    CHECK(far.LargestDelta == 100u);
    CHECK(diff.GetPixel(0, 0).r == 255u); // a differing pixel shows red
    CHECK(diff.GetPixel(50, 50).g == diff.GetPixel(50, 50).r); // an equal one grey
    CHECK_FALSE(CompareImages(image::Image(10, 10, image::PixelFormat::RGBA8), reference).SameSize);
}

TEST_CASE("testing: right clicks, hover and leave, pad presses and file drops reach what they aim at")
{
    Bed bed;
    Tester tester(*bed.root.Get());
    int menus = 0;
    (void)bed.show->AddEventListener(EventType::ContextMenu, [&](const Event&) { ++menus; });
    CHECK(tester.RightClick(Finder::Text(SV(u8"Show"))));
    CHECK(menus == 1);
    CHECK(bed.clicks == 0); // a right click is not a click

    CHECK(tester.Hover(Finder::Selector(SV(u8"#ok"))));
    CHECK(bed.ok->IsHovered());
    tester.Leave();
    CHECK_FALSE(bed.ok->IsHovered());

    bed.show->RequestFocus();
    tester.PadPress(PadButton::South); // the pad's A activates the focus
    CHECK(bed.clicks == 1);

    bed.dialog->SetDropTypes(core::String(u8"files"));
    core::Array<core::String> dropped;
    (void)bed.dialog->AddEventListener(EventType::Drop, [&](const Event& e)
    { dropped = DroppedPaths(static_cast<const DragEvent&>(e).Payload); });
    core::Array<core::String> paths;
    paths.PushBack(core::String(u8"/tmp/level.map"));
    CHECK(tester.DropFiles(Finder::Selector(SV(u8"#dialog")), paths));
    REQUIRE(dropped.Size() == 1u);
    CHECK(dropped[0] == SV(u8"/tmp/level.map"));
}

TEST_CASE("testing: two fingers pinch, turn and pan what takes gestures")
{
    Bed bed;
    auto pad = Add<Panel>(*bed.root.Get(), u8"pad", 200.0f, 10.0f, 200.0f, 200.0f);
    pad->SetTouchActions(0); // its fingers its own
    f32 scale = 0.0f, rotation = 0.0f;
    core::Float2 moved{0.0f, 0.0f};
    (void)pad->AddEventListener(EventType::GestureEnd, [&](const Event& e)
                                {
                                    const auto& g = static_cast<const GestureEvent&>(e);
                                    scale = g.Scale;
                                    rotation = g.Rotation;
                                    moved = g.Translation;
                                });
    Tester tester(*bed.root.Get());
    CHECK(tester.Pinch(Finder::Selector(SV(u8"#pad")), 60.0f, 120.0f));
    CHECK(scale == doctest::Approx(2.0f));
    CHECK(tester.Rotate(Finder::Selector(SV(u8"#pad")), 0.5f));
    CHECK(rotation == doctest::Approx(0.5f).epsilon(0.01));
    CHECK(tester.TwoFingerPan(Finder::Selector(SV(u8"#pad")), core::Float2{30.0f, -10.0f}));
    CHECK(moved.x == doctest::Approx(30.0f));
    CHECK(moved.y == doctest::Approx(-10.0f));
}

TEST_CASE("testing: the wheel and a finger scroll what they are over, and a tap clicks")
{
    Bed bed;
    auto list = Add<Panel>(*bed.root.Get(), u8"list", 10.0f, 130.0f, 150.0f, 60.0f);
    list->EditLayoutStyle([](LayoutStyle& style) { style.OverflowY = Overflow::Scroll; });
    auto tall = Add<Panel>(*list.Get(), u8"tall", 0.0f, 0.0f, 150.0f, 600.0f);
    Tester tester(*bed.root.Get());

    CHECK(tester.Scroll(Finder::Selector(SV(u8"#list")), core::Float2{0.0f, -3.0f})); // toward the user: down
    const f32 wheeled = list->GetScrollOffset().y;
    CHECK(wheeled > 0.0f);
    CHECK(tester.Swipe(Finder::Selector(SV(u8"#list")), core::Float2{0.0f, -40.0f})); // a finger up pans down
    CHECK(list->GetScrollOffset().y > wheeled);

    CHECK(tester.Tap(Finder::Text(SV(u8"Show"))));
    CHECK(bed.clicks == 1);
}

TEST_CASE("testing: a failure is handed to the capture with a name, so a host with a device saves the screen")
{
    Bed bed;
    Tester tester(*bed.root.Get());
    core::Array<core::String> captured;
    tester.SetFailureCapture([&](core::StringView name) { captured.PushBack(core::String(name)); });
    CHECK(tester.One(Finder::Text(SV(u8"Nowhere"))) == nullptr);
    CHECK_FALSE(tester.Click(Finder::Text(SV(u8"Also nowhere"))));
    REQUIRE(captured.Size() == 2u);
    CHECK(captured[0] == SV(u8"failure-1"));
    CHECK(captured[1] == SV(u8"failure-2"));
    CHECK(tester.Failures().Size() == 2u);
}
