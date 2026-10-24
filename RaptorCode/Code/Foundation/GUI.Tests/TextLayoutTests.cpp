// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// The inline formatter over the bundled Roboto faces: mixed sizes share a baseline, a paragraph of
// three colours wraps inside its width, an icon sits on the baseline, breaks and alignment, and bold
// and italic take a face or synthesize one. Copied with the layout from foundation.ui (E4 of
// Specs/gui-lab-evolution.md).
#include <doctest/doctest.h>
#include "Core/Prelude.h"

import foundation.core;
import foundation.vfs;
import foundation.fonts;
import foundation.fonts.truetype;
import foundation.vg;
import foundation.gui;

using namespace foundation::core;
using namespace foundation::gui;
namespace fonts = foundation::fonts;

namespace
{
    // Roboto, and Roboto Bold as its own family (as a project loads a bold face).
    struct RobotoService
    {
        fonts::TrueTypeFontService service{DefaultAllocator()};

        RobotoService()
        {
            fonts::TrueTypeFonts::Initialize();
            const String root = foundation::vfs::FindDataRoot();
            REQUIRE(service.LoadFont(u8"Roboto",
                                     foundation::vfs::DataPath(root.AsView(), u8"Assets/fonts/roboto/Roboto-Regular.ttf")
                                         .AsView()) == fonts::FontLoadResult::Success);
            REQUIRE(service.LoadFont(u8"Roboto Bold",
                                     foundation::vfs::DataPath(root.AsView(), u8"Assets/fonts/roboto/Roboto-Bold.ttf")
                                         .AsView()) == fonts::FontLoadResult::Success);
        }
    };

    // The label's font (Roboto 16), the service for runs that set their own.
    TextLayoutStyle Style(RobotoService& fonts, f32 maxWidth = 0.0f)
    {
        TextLayoutStyle style;
        style.Font = fonts.service.GetFont(u8"Roboto", 16.0f);
        style.Fonts = &fonts.service;
        style.Family = String(u8"Roboto");
        style.Size = 16.0f;
        style.MaxWidth = maxWidth;
        return style;
    }
}

TEST_CASE("label: measures shaped text, and a rich label reports a clicked link")
{
    RobotoService fonts;
    auto context = MakeRef<GUIContext>(DefaultAllocator());
    context->SetFontService(&fonts.service);
    auto root = MakeRef<SceneRoot>(DefaultAllocator(), context);
    root->SetSize(Float2{400.0f, 200.0f});
    fonts::CachedFont* roboto = fonts.service.GetFont(u8"Roboto", 16.0f);

    auto label = MakeRef<Label>(DefaultAllocator());
    label->SetFont(roboto);
    label->SetText(u8"Shaped width");
    CHECK(label->MeasureContent(Float2{kUnbounded, kUnbounded}).x ==
          doctest::Approx(LayOutText(TextDocument::Plain(u8"Shaped width"), Style(fonts)).Width));

    auto rich = MakeRef<RichText>(DefaultAllocator());
    rich->SetFont(roboto);
    rich->SetText(u8"go [link=door]open the door[/link] now");
    rich->SetPosition(Float2{0.0f, 0.0f});
    rich->SetSize(Float2{400.0f, 40.0f});
    root->AddChild(rich.Get());
    String heard;
    (void)rich->AddEventListener(EventType::Link,
                                 [&heard](const Event& e) { heard = String(static_cast<const LinkEvent&>(e).Link); });
    const Rect bounds = rich->GetContentBounds();
    const TextLayout& layout = rich->GetTextLayout().LayoutFor(bounds);
    REQUIRE_FALSE(layout.Links.IsEmpty());
    const Float2 origin = rich->GetTextLayout().Origin(bounds);
    const Float2 onLink{origin.x + layout.Links[0].Rect.x + 2.0f, origin.y + layout.Links[0].Rect.y + layout.Links[0].Rect.height * 0.5f};
    EventDispatcher* d = root->GetEventDispatcher();
    d->InjectMouseDown(onLink, MouseButton::Left);
    d->InjectMouseUp(onLink, MouseButton::Left);
    CHECK(heard == StringView(u8"door"));
    heard.Clear();
    d->InjectMouseDown(Float2{origin.x + 1.0f, onLink.y}, MouseButton::Left); // on "go"
    d->InjectMouseUp(Float2{origin.x + 1.0f, onLink.y}, MouseButton::Left);
    CHECK(heard.IsEmpty());
}

TEST_CASE("text layout: the pointer shows the hand over a rich text's link, and only there")
{
    RobotoService fonts;
    auto context = MakeRef<GUIContext>(DefaultAllocator());
    context->SetFontService(&fonts.service);
    auto root = MakeRef<SceneRoot>(DefaultAllocator(), context);
    root->SetSize(Float2{400.0f, 200.0f});
    auto rich = MakeRef<RichText>(DefaultAllocator());
    rich->SetFont(fonts.service.GetFont(u8"Roboto", 16.0f));
    rich->SetText(u8"go [link=door]open the door[/link] now");
    rich->SetSize(Float2{400.0f, 40.0f});
    root->AddChild(rich.Get());
    const Rect bounds = rich->GetContentBounds();
    const TextLayout& layout = rich->GetTextLayout().LayoutFor(bounds);
    REQUIRE_FALSE(layout.Links.IsEmpty());
    const Float2 origin = rich->GetTextLayout().Origin(bounds);
    const Float2 onLink{origin.x + layout.Links[0].Rect.x + 2.0f, origin.y + layout.Links[0].Rect.y + layout.Links[0].Rect.height * 0.5f};
    EventDispatcher* d = root->GetEventDispatcher();
    d->InjectMouseMove(Float2{origin.x + 1.0f, onLink.y}); // on "go"
    CHECK(d->GetCursor() == Cursor::Default);
    d->InjectMouseMove(onLink);
    CHECK(d->GetCursor() == Cursor::Pointer);
    d->InjectMouseMove(Float2{390.0f, 190.0f}); // off the label
    CHECK(d->GetCursor() == Cursor::Default);
    rich->SetCursor(Cursor::Text); // its own look elsewhere; the hand still over the link
    d->InjectMouseMove(Float2{origin.x + 1.0f, onLink.y});
    CHECK(d->GetCursor() == Cursor::Text);
    d->InjectMouseMove(onLink);
    CHECK(d->GetCursor() == Cursor::Pointer);
}
