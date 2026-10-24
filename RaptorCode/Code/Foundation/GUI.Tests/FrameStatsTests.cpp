// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - frame stats tests (E8a): what a frame cost and why it was needed, written by the style,
// layout and draw passes and by NeedsFrame.
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

    core::RefPtr<SceneRoot> NewRoot()
    {
        auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        root->SetSize(core::Float2{300.0f, 300.0f});
        return root;
    }
    core::RefPtr<UIWidget> Box(Node& parent, const char8_t* id)
    {
        auto w = Make<UIWidget>();
        w->SetTag(SV(u8"box"));
        w->SetId(SV(id));
        w->SetSize(core::Float2{40.0f, 20.0f});
        parent.AddChild(w.Get());
        return w;
    }
    // A host's frame: style, tick, lay out, ask, draw.
    bool Frame(SceneRoot& root, StyleManager& styles, vg::VGContext& canvas)
    {
        styles.ApplyTree(root);
        root.GetContext().Update(core::Duration::FromSeconds(0.016));
        root.UpdateLayout();
        const bool needed = root.NeedsFrame();
        canvas.Clear();
        DrawContext dc{canvas};
        root.DrawFrame(dc);
        return needed;
    }
}

TEST_CASE("frame-stats: a frame says what it restyled, laid out and drew, and an idle one what asked: nothing")
{
    auto root = NewRoot();
    auto panel = Box(*root.Get(), u8"panel");
    panel->EditLayoutStyle([](LayoutStyle& s) { s.Direction = FlexDirection::Column; });
    auto a = Box(*panel.Get(), u8"a");
    auto b = Box(*panel.Get(), u8"b");
    StyleManager styles(CSSParser::Parse(SV(u8"box { background-color: #336699; }")));
    vg::VGContext canvas;

    CHECK(Frame(*root.Get(), styles, canvas));
    const FrameStats& stats = root->GetLastFrameStats();
    CHECK(stats.Restyled == 3u); // the three boxes (the root is no widget)
    CHECK(stats.LaidOut >= 1u);
    CHECK(stats.NodesDrawn == 4u); // the root and the boxes
    CHECK(stats.Vertices > 0u);    // their backgrounds
    CHECK(stats.Commands > 0u);
    CHECK(stats.FramesDrawn == 1u);

    (void)Frame(*root.Get(), styles, canvas); // what the first frame left settles
    CHECK_FALSE(Frame(*root.Get(), styles, canvas));
    CHECK(stats.Restyled == 0u);
    CHECK(stats.LaidOut == 0u);
    CHECK_FALSE(stats.Reasons.Any());
    CHECK(stats.Describe().AsView().ContainsIgnoreCase(SV(u8"asked by: nothing")));

    b->SetDisplayed(false); // not drawn, not counted
    (void)Frame(*root.Get(), styles, canvas);
    CHECK(stats.NodesDrawn == 3u);
    (void)a;
}

TEST_CASE("frame-stats: an animation that keeps a GUI drawing is named; a change says redraw")
{
    auto root = NewRoot();
    auto bar = Make<ProgressBar>();
    bar->SetId(SV(u8"busy"));
    bar->SetSize(core::Float2{100.0f, 10.0f});
    root->AddChild(bar.Get());
    StyleManager styles(CSSParser::Parse(SV(u8"progressbar { opacity: 1; }")));
    vg::VGContext canvas;
    bar->SetIndeterminate(true);
    (void)Frame(*root.Get(), styles, canvas);
    (void)Frame(*root.Get(), styles, canvas);
    CHECK(Frame(*root.Get(), styles, canvas));
    const FrameStats& stats = root->GetLastFrameStats();
    CHECK(stats.Reasons.Animation);
    CHECK(stats.AnimatedNode.AsView() == SV(u8"ProgressBar #busy"));
    CHECK(stats.Describe().AsView().ContainsIgnoreCase(SV(u8"animation (ProgressBar #busy)")));

    bar->SetIndeterminate(false);
    (void)Frame(*root.Get(), styles, canvas);
    (void)Frame(*root.Get(), styles, canvas);
    REQUIRE_FALSE(Frame(*root.Get(), styles, canvas));
    bar->SetValue(0.5);
    root->UpdateLayout();
    CHECK(root->NeedsFrame());
    CHECK(stats.Reasons.Redraw);
    CHECK_FALSE(stats.Reasons.Animation);
}
