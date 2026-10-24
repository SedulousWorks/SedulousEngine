// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - EditableLabel (E6): a double-click or F2 edits it in place; Return and focus leaving
// commit, Escape cancels; a validator keeps it editing or puts the old text back.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.vg;
import foundation.fonts;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

namespace
{
    namespace fonts = foundation::fonts;

    // A mock font: 6px a byte, 12px a line.
    class SixFont : public fonts::IFont
    {
    public:
        core::StringView FamilyName() const override { return core::StringView(u8"six"); }
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

    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<EditableLabel> label = core::MakeRef<EditableLabel>(core::DefaultAllocator());
        core::RefPtr<Panel> other = core::MakeRef<Panel>(core::DefaultAllocator());
        int commits = 0, changeEvents = 0;
        Bed()
        {
            root->SetSize(core::Float2{300.0f, 200.0f});
            root->EditLayoutStyle([](LayoutStyle& s) { s.AlignItems = Align::Start; });
            label->SetText(core::StringView(u8"layer 1"));
            label->EditLayoutStyle([](LayoutStyle& s)
            {
                s.Width = LayoutLength::Px(120.0f);
                s.Height = LayoutLength::Px(24.0f);
            });
            root->AddChild(label.Get());
            other->SetTabFocusable(true);
            other->EditLayoutStyle([](LayoutStyle& s) { s.Width = LayoutLength::Px(20.0f); s.Height = LayoutLength::Px(20.0f); });
            root->AddChild(other.Get());
            (void)root->UpdateLayout();
            label->SetOnTextCommitted([this](core::StringView) { ++commits; });
            (void)label->AddEventListener(EventType::Changed, [this](const Event&) { ++changeEvents; });
        }
        EventDispatcher& D() { return *root->GetEventDispatcher(); }
        void Key(KeyCode k) { D().InjectKeyDown(static_cast<core::u32>(k)); }
        void Retype(const char8_t* text)
        {
            label->GetEditor()->GetModel().SelectAll();
            D().InjectText(core::StringView(text));
        }
    };
}

TEST_CASE("editable label: a double-click edits it in place, all selected; Return commits")
{
    Bed b;
    b.D().InjectMouseDown(core::Float2{20.0f, 12.0f}, MouseButton::Left);
    b.D().InjectMouseUp(core::Float2{20.0f, 12.0f}, MouseButton::Left);
    CHECK_FALSE(b.label->IsEditing()); // one click: no
    b.D().InjectMouseDown(core::Float2{20.0f, 12.0f}, MouseButton::Left);
    b.D().InjectMouseUp(core::Float2{20.0f, 12.0f}, MouseButton::Left);
    REQUIRE(b.label->IsEditing());
    TextEditBase* editor = b.label->GetEditor();
    CHECK(editor->IsFocused());
    CHECK(editor->GetText() == core::StringView(u8"layer 1"));
    (void)b.root->UpdateLayout();
    CHECK(editor->GetSize().x == doctest::Approx(120.0f)); // over its whole box

    b.D().InjectText(core::StringView(u8"sky")); // all selected: replaced
    b.Key(KeyCode::Return);
    CHECK_FALSE(b.label->IsEditing());
    CHECK(b.label->GetText() == core::StringView(u8"sky"));
    CHECK(b.label->IsFocused()); // the label keeps the focus
    CHECK(b.commits == 1);
    CHECK(b.changeEvents == 1);
}

TEST_CASE("editable label: its field's text lies where the label's was, the field's padding reaching past it")
{
    Bed b;
    b.label->SetPadding(Thickness{2.0f, 3.0f, 2.0f, 3.0f});
    b.label->BeginEdit();
    TextEditBase* editor = b.label->GetEditor();
    REQUIRE(editor != nullptr);
    editor->SetPadding(Thickness{6.0f, 6.0f, 6.0f, 6.0f});
    (void)b.root->UpdateLayout();
    // A label 24 tall, its content 18: the field's content as tall, not 24 less its padding.
    const Rect content = b.label->GetContentBounds();
    const Rect field = editor->GetContentBounds();
    CHECK(editor->GetPosition().x + field.x == doctest::Approx(content.x));
    CHECK(editor->GetPosition().y + field.y == doctest::Approx(content.y));
    CHECK(field.width == doctest::Approx(content.width));
    CHECK(field.height == doctest::Approx(18.0f));
    CHECK(editor->GetSize().y == doctest::Approx(30.0f));
}

TEST_CASE("editable label: its field's context menu keeps it editing, the selection there to cut")
{
    Bed b;
    b.label->BeginEdit();
    TextEditBase* editor = b.label->GetEditor();
    REQUIRE(editor != nullptr);
    editor->GetModel().Select(TextRange{0, 5}); // "layer"
    b.D().InjectMouseDown(core::Float2{20.0f, 12.0f}, MouseButton::Right);
    b.D().InjectMouseUp(core::Float2{20.0f, 12.0f}, MouseButton::Right);
    REQUIRE(editor->GetContextMenu() != nullptr);
    REQUIRE(editor->GetContextMenu()->IsOpen());
    CHECK(b.label->IsEditing());
    CHECK(editor->SelectedText() == core::StringView(u8"layer"));
    CHECK(b.commits == 0);
    // Cut, from the menu: the field has the focus back, still editing.
    MenuItem* cut = core::Cast<MenuItem>(editor->GetContextMenu()->GetChildAt(0));
    REQUIRE(cut != nullptr);
    (void)cut->HandleActivate();
    CHECK_FALSE(editor->GetContextMenu()->IsOpen());
    CHECK(b.label->IsEditing());
    CHECK(editor->IsFocused());
    CHECK(editor->GetText() == core::StringView(u8" 1"));
}

TEST_CASE("editable label: F2 edits it; Escape cancels; focus leaving commits")
{
    Bed b;
    b.label->RequestFocus();
    b.Key(KeyCode::F2);
    REQUIRE(b.label->IsEditing());
    b.Retype(u8"gone");
    b.Key(KeyCode::Escape);
    CHECK_FALSE(b.label->IsEditing());
    CHECK(b.label->GetText() == core::StringView(u8"layer 1"));
    CHECK(b.commits == 0);

    b.Key(KeyCode::F2);
    b.Retype(u8"kept");
    b.other->RequestFocus();
    CHECK_FALSE(b.label->IsEditing());
    CHECK(b.label->GetText() == core::StringView(u8"kept"));
    CHECK(b.other->IsFocused()); // focus stays where it went
    CHECK(b.commits == 1);
}

TEST_CASE("editable label: a validator keeps Return editing, and focus leaving puts the old text back")
{
    Bed b;
    b.label->SetValidator([](core::StringView text) { return text.Size() != 0; });
    b.label->BeginEdit();
    b.Retype(u8"");
    b.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Delete)); // empty it
    b.Key(KeyCode::Return);
    CHECK(b.label->IsEditing());
    CHECK(b.label->GetEditor()->HasClass(core::StringView(u8"invalid")));
    b.other->RequestFocus();
    CHECK_FALSE(b.label->IsEditing());
    CHECK(b.label->GetText() == core::StringView(u8"layer 1"));
    CHECK(b.commits == 0);
}

TEST_CASE("editable label: multiline, it edits in a text area; Return breaks a line, Ctrl+Return commits, its box following the lines")
{
    core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    core::RefPtr<EditableLabel> label = core::MakeRef<EditableLabel>(core::DefaultAllocator());
    fonts::CachedFont font{core::DefaultAllocator(), core::DefaultAllocator().New<SixFont>(), nullptr, nullptr};
    root->SetSize(core::Float2{300.0f, 200.0f});
    root->EditLayoutStyle([](LayoutStyle& s) { s.AlignItems = Align::Start; });
    label->SetFont(&font);
    label->SetMultiline(true);
    CHECK(label->GetTextStyle().WhiteSpace == TextWhiteSpace::PreWrap);
    CHECK(label->GetTextAlignV() == TextVAlign::Top);
    label->SetText(core::StringView(u8"note"));
    label->EditLayoutStyle([](LayoutStyle& s) { s.Width = LayoutLength::Px(120.0f); });
    root->AddChild(label.Get());
    core::String committed;
    label->SetOnTextCommitted([&committed](core::StringView text) { committed = core::String(text); });
    (void)root->UpdateLayout();
    CHECK(label->GetSize().y == doctest::Approx(12.0f));

    label->BeginEdit();
    REQUIRE(core::Cast<TextArea>(label->GetEditor()) != nullptr);
    EventDispatcher& d = *root->GetEventDispatcher();
    label->GetEditor()->GetModel().SelectAll();
    d.InjectText(core::StringView(u8"one"));
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Return));
    d.InjectText(core::StringView(u8"two"));
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Return));
    CHECK(label->IsEditing());
    CHECK(label->GetText() == core::StringView(u8"note")); // the label's text until it commits
    (void)root->UpdateLayout();
    // Three lines typed (the last empty), the box and the area's text as tall.
    CHECK(label->GetSize().y == doctest::Approx(36.0f));
    CHECK(label->GetEditor()->GetContentBounds().height == doctest::Approx(36.0f));

    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Return), static_cast<core::u32>(KeyModCtrl));
    CHECK_FALSE(label->IsEditing());
    CHECK(label->GetText() == core::StringView(u8"one\ntwo\n"));
    CHECK(committed == core::String(u8"one\ntwo\n"));
    (void)root->UpdateLayout();
    CHECK(label->GetSize().y == doctest::Approx(36.0f));

    // Escape puts it back, the box shrinking to the old lines.
    label->BeginEdit();
    label->GetEditor()->SetText(core::StringView(u8"a\nb\nc\nd"));
    (void)root->UpdateLayout();
    CHECK(label->GetSize().y == doctest::Approx(48.0f));
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    CHECK_FALSE(label->IsEditing());
    (void)root->UpdateLayout();
    CHECK(label->GetSize().y == doctest::Approx(36.0f));

    // A text area alone submits on Ctrl+Return too.
    core::RefPtr<TextArea> area = core::MakeRef<TextArea>(core::DefaultAllocator());
    root->AddChild(area.Get());
    int submits = 0;
    area->SetOnSubmit([&submits](core::StringView) { ++submits; });
    area->RequestFocus();
    d.InjectKeyDown(static_cast<core::u32>(KeyCode::Return), static_cast<core::u32>(KeyModCtrl));
    CHECK(submits == 1);
    CHECK(area->GetText().Size() == 0);
}
