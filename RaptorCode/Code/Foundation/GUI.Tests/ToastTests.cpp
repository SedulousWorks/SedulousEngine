// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - toasts (T7 of Specs/gui-lab-evolution-3.md): a host's cards, by severity, staying their
// time on the GUI's clock (an error until closed), paused while hovered; a key replacing and
// counting; four shown and the rest waiting; a widget's content, or bare; actions; posts from
// another thread waiting for the host's frame; each shown toast announced.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
#include <thread>
import foundation.core;
import foundation.fonts;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
using core::f32;
using core::usize;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }
    namespace fonts = foundation::fonts;

    // A mock font: 6px a byte, 12px a line.
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

    class Narrator : public IAccessibilityBridge
    {
    public:
        [[nodiscard]] bool IsListening() const override { return true; }
        void Update(const AccessTreeUpdate&) override {}
        void Announce(core::StringView text, AnnouncePriority priority) override
        {
            said.PushBack(core::String(text));
            priorities.PushBack(priority);
        }
        core::Array<core::String> said{core::DefaultAllocator()};
        core::Array<AnnouncePriority> priorities{core::DefaultAllocator()};
    };

    // A host over an 800 by 600 root.
    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<ToastHost> host = core::MakeRef<ToastHost>(core::DefaultAllocator());
        Narrator narrator;

        Bed()
        {
            root->SetSize(core::Float2{800.0f, 600.0f});
            root->AddChild(host.Get());
            root->GetContext().SetAccessibilityBridge(&narrator);
            Frame(0.0f);
        }
        ~Bed() { root->GetContext().SetAccessibilityBridge(nullptr); }
        void Frame(f32 seconds = 0.016f)
        {
            root->GetContext().Update(core::Duration::FromSeconds(seconds));
            (void)root->UpdateLayout();
        }
        EventDispatcher& D() { return *root->GetEventDispatcher(); }
        static ToastRequest Text(const char8_t* message, ToastSeverity severity = ToastSeverity::Info, const char8_t* title = u8"")
        {
            ToastRequest request;
            request.Message = core::String(message);
            request.Title = core::String(title);
            request.Severity = severity;
            return request;
        }
        [[nodiscard]] core::Float2 Middle(const Node& node) const
        {
            const Rect r = node.GetScreenBounds();
            return core::Float2{r.x + r.width * 0.5f, r.y + r.height * 0.5f};
        }
    };
}

TEST_CASE("toast: a host markup places")
{
    RegisterGuiElements();
    static const ElementSet elements = ElementSet::All();
    MarkupLoader loader(elements, core::DefaultAllocator());
    core::RefPtr<foundation::gui::Node> made = loader.LoadFromString(SV(u8R"(<Panel><ToastHost/></Panel>)"));
    REQUIRE(made);
    REQUIRE(made->ChildCount() == 1);
    CHECK(core::Cast<ToastHost>(made->GetChildAt(0)) != nullptr);
}
