// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// TextArea (E4 of Specs/gui-lab-evolution.md): the multiline field over the editing model. Return
// breaks a line, its text wraps at its width, up and down move by the lines it shows, keeping their
// column, page keys move a page, Home and End stop at a shown line's ends, it scrolls down to keep
// the caret in view, and it is `rows` lines tall. A mock font: 6px a byte, 12px a line, no shaper.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.fonts;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
namespace fonts = foundation::fonts;

namespace
{
    using SV = core::StringView;

    class SixFont : public fonts::IFont
    {
    public:
        core::StringView FamilyName() const override { return SV(u8"six"); }
        core::Span<const core::u8> SourceData() const override { return {}; }
        fonts::FontMetrics Metrics() const override
        {
            fonts::FontMetrics m;
            m.ascent = 10.0f;
            m.descent = -2.0f;
            m.lineHeight = 12.0f;
            m.pixelHeight = 10.0f;
            m.scale = 1.0f;
            return m;
        }
        core::f32 PixelHeight() const override { return 10.0f; }
        fonts::GlyphInfo GetGlyphInfo(core::i32 cp) const override
        {
            fonts::GlyphInfo g;
            g.codepoint = cp;
            g.advanceWidth = 6.0f;
            return g;
        }
        core::f32 GetKerning(core::i32, core::i32) const override { return 0.0f; }
        bool HasGlyph(core::i32) const override { return true; }
        core::f32 MeasureString(core::StringView text) const override { return static_cast<core::f32>(text.Size()) * 6.0f; }
        core::f32 MeasureString(core::StringView text, core::Array<fonts::GlyphPosition>&) const override { return MeasureString(text); }
    };

    core::u32 Key(KeyCode k) { return static_cast<core::u32>(k); }

    // A focused area 54 wide (nine characters a line) and 36 tall (three lines).
    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<TextArea> area = core::MakeRef<TextArea>(core::DefaultAllocator());
        fonts::CachedFont font{core::DefaultAllocator(), core::DefaultAllocator().New<SixFont>(), nullptr, nullptr};

        explicit Bed(SV text)
        {
            root->SetSize(core::Float2{400.0f, 300.0f});
            area->SetSize(core::Float2{54.0f, 36.0f});
            area->SetFont(&font);
            root->AddChild(area.Get());
            area->SetText(text);
            area->RequestFocus();
        }
        EventDispatcher* d() { return root->GetEventDispatcher(); }
    };
}

TEST_CASE("text area: markup and scripts make one by its element name")
{
    RegisterGuiElements();
    CHECK(ElementTypes::Find(u8"TextArea") == &TextArea::StaticType());
    CHECK(ElementTypes::Find(u8"RichText") == &RichText::StaticType());
}
