// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - modal Window + MessageBox tests: OpenModal adds a scrim and confines input to
// the dialog (background clicks are swallowed by the dispatcher's modal root); MessageBox shows
// the right buttons and reports the pressed result, then closes.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.fonts;
import foundation.i18n;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
namespace fonts = foundation::fonts;

namespace
{
    // 6 px a byte, 12 px lines: a message measures (and wraps) without a real font.
    class WideFont : public fonts::IFont
    {
    public:
        core::StringView FamilyName() const override { return core::StringView(u8"mock"); }
        core::Span<const core::u8> SourceData() const override { return {}; }
        fonts::FontMetrics Metrics() const override
        {
            fonts::FontMetrics m;
            m.ascent = 10.0f;
            m.descent = -2.0f;
            m.lineGap = 0.0f;
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
        core::f32 MeasureString(core::StringView text, core::Array<fonts::GlyphPosition>&) const override
        {
            return static_cast<core::f32>(text.Size()) * 6.0f;
        }
    };
    template <typename T>
    core::RefPtr<T> Make()
    {
        return core::MakeRef<T>(core::DefaultAllocator());
    }

    // Sum of a node's positions up to the root, plus half its size = its world-space center
    // (identity transforms, matching the popup/menu model). Used to click a nested button.
    core::Float2 WorldCenter(Node* node)
    {
        core::Float2 p{0.0f, 0.0f};
        for (Node* c = node; c != nullptr && c->GetParent() != nullptr; c = c->GetParent())
            p += c->GetPosition();
        const core::Float2 s = node->GetSize();
        return core::Float2{p.x + s.x * 0.5f, p.y + s.y * 0.5f};
    }
}

TEST_CASE("message box: its buttons' labels follow the GUI's language where a table has them, else English")
{
    foundation::i18n::StringTable table;
    REQUIRE(table.Set(core::StringView(u8"gui.ok"), core::StringView(u8"pt"), core::StringView(u8"Confirmar")));
    foundation::i18n::Localization loc;
    loc.AddTable(&table);
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->GetContext().SetLocalization(&loc);
    auto box = core::MakeRef<MessageBox>(core::DefaultAllocator());
    root->AddChild(box.Get());
    box->Configure(core::StringView(u8"?"), core::StringView(u8"Proceed?"), MessageBox::Buttons::OkCancel);
    root->GetContext().Update(core::Duration::FromSeconds(1.0 / 60.0));
    CHECK(box->ButtonAt(1)->GetText() == core::StringView(u8"OK")); // English: no table has it in English
    CHECK(box->ButtonAt(0)->GetText() == core::StringView(u8"Cancel"));
    loc.SetLanguage(core::StringView(u8"pt"));
    root->GetContext().Update(core::Duration::FromSeconds(1.0 / 60.0));
    CHECK(box->ButtonAt(1)->GetText() == core::StringView(u8"Confirmar"));
    CHECK(box->ButtonAt(0)->GetText() == core::StringView(u8"Cancel")); // no table names it: English
    root->GetContext().SetLocalization(nullptr);
}
