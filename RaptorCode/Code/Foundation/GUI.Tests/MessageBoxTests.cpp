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

TEST_CASE("window: OpenModal centers it as a modal popup of its owner")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 400.0f});
    EventDispatcher* d = root->GetEventDispatcher();

    auto window = Make<Window>();
    window->SetSize(core::Float2{200.0f, 100.0f});
    window->OpenModal(*root.Get());

    CHECK(window->IsOpen());
    CHECK(window->IsModal());
    CHECK(window->GetParent() == root.Get());
    CHECK(d->TopPopup() == window.Get());
    CHECK(window->GetPosition().x == doctest::Approx(100.0f)); // (400-200)/2
    CHECK(window->GetPosition().y == doctest::Approx(150.0f)); // (400-100)/2
    CHECK(root->ChildCount() == 1);                            // the window (its backdrop is the top layer's)
}

TEST_CASE("window: a modal swallows clicks on the background")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 400.0f});
    EventDispatcher* d = root->GetEventDispatcher();

    int backgroundClicks = 0;
    auto background = Make<Button>();
    background->SetSize(core::Float2{100.0f, 40.0f});
    background->SetPosition(core::Float2{0.0f, 0.0f}); // top-left corner
    background->SetOnClick([&] { ++backgroundClicks; });
    root->AddChild(background.Get());

    auto window = Make<Window>();
    window->SetSize(core::Float2{200.0f, 100.0f}); // centered -> covers (100,150)-(300,250)
    window->OpenModal(*root.Get());

    // Click the background button (outside the modal) -> swallowed.
    d->InjectMouseDown(core::Float2{50.0f, 20.0f}, MouseButton::Left);
    d->InjectMouseUp(core::Float2{50.0f, 20.0f}, MouseButton::Left);
    CHECK(backgroundClicks == 0);
    CHECK(d->GetFocusNode() != background.Get());
}

TEST_CASE("window: Close takes the modal popup down and fires onClose")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 400.0f});
    EventDispatcher* d = root->GetEventDispatcher();

    int closed = 0;
    auto window = Make<Window>();
    window->SetSize(core::Float2{200.0f, 100.0f});
    window->SetOnClose([&] { ++closed; });
    window->OpenModal(*root.Get());
    REQUIRE(root->ChildCount() == 1);

    window->Close();
    CHECK_FALSE(window->IsOpen());
    CHECK(window->GetParent() == nullptr);
    CHECK(d->PopupCount() == 0u);
    CHECK(root->ChildCount() == 0); // the window removed (its backdrop is the top layer's)
    CHECK(closed == 1);
}

TEST_CASE("window: non-modal Open adds no scrim and no modal root")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{400.0f, 400.0f});
    EventDispatcher* d = root->GetEventDispatcher();

    auto window = Make<Window>();
    window->SetSize(core::Float2{200.0f, 100.0f});
    window->Open(*root.Get());
    CHECK(window->IsOpen());
    CHECK_FALSE(window->IsModal());
    CHECK(d->PopupCount() == 0u);
    CHECK(root->ChildCount() == 1); // just the window
}

TEST_CASE("messagebox: Configure shows the right buttons per style")
{
    auto ok = Make<MessageBox>();
    ok->Configure(core::StringView(u8"Hi"), core::StringView(u8"All good."),
                  MessageBox::Buttons::Ok);
    CHECK(ok->ButtonCount() == 1);
    CHECK(ok->GetMessage() == core::StringView(u8"All good."));

    auto okCancel = Make<MessageBox>();
    okCancel->Configure(core::StringView(u8"?"), core::StringView(u8"Proceed?"),
                        MessageBox::Buttons::OkCancel);
    CHECK(okCancel->ButtonCount() == 2);

    auto yesNo = Make<MessageBox>();
    yesNo->Configure(core::StringView(u8"?"), core::StringView(u8"Save?"),
                     MessageBox::Buttons::YesNo);
    CHECK(yesNo->ButtonCount() == 2);
}

TEST_CASE("messagebox: pressing a button reports the result and closes")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{500.0f, 500.0f});
    EventDispatcher* d = root->GetEventDispatcher();

    MessageBox::Result got = MessageBox::Result::Cancel;
    int results = 0;
    auto box = Make<MessageBox>();
    box->Configure(core::StringView(u8"Confirm"), core::StringView(u8"Delete it?"),
                   MessageBox::Buttons::OkCancel);
    box->SetOnResult(
        [&](MessageBox::Result r)
        {
            got = r;
            ++results;
        });
    box->OpenModal(*root.Get());
    (void)root->UpdateLayout(); // its content flows: its buttons are placed by the layout pass

    // Buttons: [Cancel, OK] (OK rightmost). Click OK.
    Button* okButton = box->ButtonAt(1);
    REQUIRE(okButton != nullptr);
    const core::Float2 center = WorldCenter(okButton);
    d->InjectMouseDown(center, MouseButton::Left);
    d->InjectMouseUp(center, MouseButton::Left);

    CHECK(results == 1);
    CHECK(got == MessageBox::Result::Ok);
    CHECK_FALSE(box->IsOpen()); // closed after the result
    CHECK(d->PopupCount() == 0u);
}

TEST_CASE("window: its close button closes it; closable and resizable show or hide its button and grip")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{500.0f, 500.0f});
    auto window = Make<Window>();
    window->SetSize(core::Float2{240.0f, 160.0f});
    window->SetTitle(core::StringView(u8"Tools"));
    window->Open(*root.Get());
    (void)root->UpdateLayout();
    CHECK(window->IsOpen());
    CHECK(window->IsClosable());
    CHECK(window->IsResizable());
    // The close button sits at the title bar's right end.
    const Rect w = window->GetScreenBounds();
    const core::Float2 close{w.x + w.width - 16.0f, w.y + 14.0f};
    EventDispatcher* d = root->GetEventDispatcher();
    d->InjectMouseDown(close, MouseButton::Left);
    d->InjectMouseUp(close, MouseButton::Left);
    CHECK_FALSE(window->IsOpen());

    window->SetClosable(false);
    window->SetResizable(false);
    window->Open(*root.Get());
    (void)root->UpdateLayout();
    d->InjectMouseDown(close, MouseButton::Left);
    d->InjectMouseUp(close, MouseButton::Left);
    CHECK(window->IsOpen()); // no close button there now
    // No grip: a drag from the corner does not resize it.
    const core::Float2 corner{w.x + w.width - 5.0f, w.y + w.height - 5.0f};
    d->InjectMouseDown(corner, MouseButton::Left);
    d->InjectMouseMove(core::Float2{corner.x + 60.0f, corner.y + 60.0f});
    d->InjectMouseUp(core::Float2{corner.x + 60.0f, corner.y + 60.0f}, MouseButton::Left);
    CHECK(window->GetSize().x == doctest::Approx(240.0f));
}

TEST_CASE("messagebox: its message wraps and its height fits it; it is not resizable; its close button answers as Escape")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{800.0f, 600.0f});
    fonts::CachedFont font(core::DefaultAllocator(), core::DefaultAllocator().New<WideFont>(), nullptr, nullptr); // 6 px a byte
    auto box = Make<MessageBox>();
    box->SetFont(&font);
    box->Configure(core::StringView(u8"Confirm"), core::StringView(u8"Short."), MessageBox::Buttons::OkCancel);
    const float shortHeight = box->GetSize().y;
    box->Configure(core::StringView(u8"Confirm"),
                   core::StringView(u8"A much longer message that cannot fit on one line of a dialog this wide, so it wraps onto several lines, and the dialog grows to hold them all."),
                   MessageBox::Buttons::OkCancel);
    CHECK(box->GetSize().y > shortHeight);
    CHECK_FALSE(box->IsResizable());
    MessageBox::Result got = MessageBox::Result::Ok;
    box->SetOnResult([&](MessageBox::Result r) { got = r; });
    box->OpenModal(*root.Get());
    (void)root->UpdateLayout();
    box->RequestClose(); // its close button
    CHECK(got == MessageBox::Result::Cancel);
    CHECK_FALSE(box->IsOpen());
}

TEST_CASE("messagebox: under the theme, its message wraps (styled after it is written) and the window takes the theme's rounded box")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{800.0f, 600.0f});
    fonts::CachedFont font(core::DefaultAllocator(), core::DefaultAllocator().New<WideFont>(), nullptr, nullptr);
    // Written first, as markup does, then styled: the sheet's white-space reaches the message after its box sized itself.
    const auto make = [&](const char8_t* text)
    {
        auto box = Make<MessageBox>();
        box->SetFont(&font);
        box->Configure(core::StringView(u8"Confirm"), core::StringView(text), MessageBox::Buttons::Ok);
        root->AddChild(box.Get());
        return box;
    };
    auto shortBox = make(u8"Short.");
    auto longBox = make(u8"A much longer message that cannot fit on one line of a dialog this wide, so it wraps onto several lines, and the dialog grows to hold them all.");
    StyleManager styles;
    styles.SetUserAgentSheet(CSSParser::Parse(DefaultThemeCSS()));
    styles.ApplyTree(*root.Get());
    (void)root->UpdateLayout();
    CHECK(longBox->GetSize().y >= shortBox->GetSize().y + 24.0f); // three lines of 12 px, not one
    CHECK(longBox->IsBoxFromStyle());
    CHECK_FALSE(longBox->GetBox().Radii.IsZero());
    CHECK_FALSE(longBox->GetBox().Shadows.IsEmpty());
}

TEST_CASE("message box: shown in no GUI it refuses, rather than becoming its own child")
{
    auto box = core::MakeRef<MessageBox>(core::DefaultAllocator());
    CHECK_FALSE(box->Show());
    CHECK(box->GetParent() == nullptr);
    CHECK(box->GetChildIndex(box.Get()) == Node::kInvalidIndex);
    auto window = core::MakeRef<Window>(core::DefaultAllocator());
    window->OpenModal(*window); // inside itself: refused
    CHECK_FALSE(window->IsOpen());
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

TEST_CASE("message box: a button of the caller's own answers with its name")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    auto box = core::MakeRef<MessageBox>(core::DefaultAllocator());
    root->AddChild(box.Get());
    box->Configure(core::StringView(u8"Save?"), core::StringView(u8"Unsaved changes."), MessageBox::Buttons::OkCancel);
    box->AddButton(core::StringView(u8"Discard"), core::StringView(u8"discard"));
    REQUIRE(box->ButtonCount() == 3u);
    bool standard = false;
    box->SetOnResult([&standard](MessageBox::Result) { standard = true; });
    REQUIRE(box->Show());
    CHECK(box->ButtonAt(2)->HandleActivate()); // as Return on it would
    CHECK(box->GetResultName() == core::String(u8"discard"));
    CHECK_FALSE(standard); // no standard result
}
