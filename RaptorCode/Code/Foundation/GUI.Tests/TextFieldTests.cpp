// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - TextField tests: the keyboard/text-input path end-to-end. Text arrives via
// the EventDispatcher's InjectText (routed to the focused node), editing keys via InjectKeyDown.
// A mock font (6px/byte advance) drives caret-placement measurement.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.fonts;
import foundation.vg;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;
namespace fonts = foundation::fonts;
namespace vg = foundation::vg;

namespace
{
    template <typename T>
    core::RefPtr<T> Make()
    {
        return core::MakeRef<T>(core::DefaultAllocator());
    }

    // 6px advance per byte, 12px line height (mirrors the Text-test mock).
    class MockFont : public fonts::IFont
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
        core::f32 MeasureString(core::StringView text) const override
        {
            return static_cast<core::f32>(text.Size()) * 6.0f;
        }
        core::f32 MeasureString(core::StringView text,
                                core::Array<fonts::GlyphPosition>& out) const override
        {
            (void)out;
            return static_cast<core::f32>(text.Size()) * 6.0f;
        }
    };

    MockFont* NewMock() { return core::DefaultAllocator().New<MockFont>(); }

    // u32 view of a gui::KeyCode, since InjectKeyDown takes a raw code.
    core::u32 Key(KeyCode k) { return static_cast<core::u32>(k); }

    // In-memory clipboard so the cut/copy/paste path is testable without a shell.
    class MemClipboard : public IClipboard
    {
    public:
        bool HasText() const override { return m_text.Size() > 0; }
        core::String GetText() const override { return m_text; }
        void SetText(core::StringView text) override { m_text = core::String(text); }

    private:
        core::String m_text;
    };
}

TEST_CASE("textfield: typed text is inserted at the caret and the caret advances")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 100.0f});
    auto f = Make<TextField>();
    f->SetSize(core::Float2{100.0f, 24.0f});
    root->AddChild(f.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    // Focus the field (text only routes to the focused node).
    f->RequestFocus();
    CHECK(f->IsFocused());

    d->InjectText(core::StringView(u8"Hi"));
    CHECK(f->GetText() == core::StringView(u8"Hi"));
    CHECK(f->GetCaret() == 2);

    // Move the caret to the start and insert there.
    d->InjectKeyDown(Key(KeyCode::Home));
    CHECK(f->GetCaret() == 0);
    d->InjectText(core::StringView(u8"Oh "));
    CHECK(f->GetText() == core::StringView(u8"Oh Hi"));
    CHECK(f->GetCaret() == 3);
}

TEST_CASE("textfield: text only reaches a focused field")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 100.0f});
    auto f = Make<TextField>();
    f->SetSize(core::Float2{100.0f, 24.0f});
    root->AddChild(f.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    d->InjectText(core::StringView(u8"nope")); // not focused -> dropped
    CHECK(f->GetText().Size() == 0);
}

TEST_CASE("textfield: backspace and delete remove whole codepoints (UTF-8)")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 100.0f});
    auto f = Make<TextField>();
    f->SetSize(core::Float2{100.0f, 24.0f});
    root->AddChild(f.Get());
    EventDispatcher* d = root->GetEventDispatcher();
    f->RequestFocus();

    f->SetText(core::StringView(u8"aé")); // 'a'(1) + 'é'(2 bytes), caret at end (3)
    CHECK(f->GetCaret() == 3);

    d->InjectKeyDown(Key(KeyCode::Backspace)); // removes the whole 'é'
    CHECK(f->GetText() == core::StringView(u8"a"));
    CHECK(f->GetCaret() == 1);

    d->InjectKeyDown(Key(KeyCode::Home));
    d->InjectKeyDown(Key(KeyCode::Delete)); // removes 'a' at the front
    CHECK(f->GetText().Size() == 0);
    CHECK(f->GetCaret() == 0);

    // Backspace at the start and delete at the end are no-ops.
    d->InjectKeyDown(Key(KeyCode::Backspace));
    d->InjectKeyDown(Key(KeyCode::Delete));
    CHECK(f->GetText().Size() == 0);
}

TEST_CASE("textfield: caret navigation steps by codepoint and clamps")
{
    auto f = Make<TextField>();
    f->SetSize(core::Float2{100.0f, 24.0f});
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->AddChild(f.Get());
    EventDispatcher* d = root->GetEventDispatcher();
    f->RequestFocus();

    f->SetText(core::StringView(u8"é€")); // 2 bytes + 3 bytes = 5 bytes, caret at 5
    d->InjectKeyDown(Key(KeyCode::Home));
    CHECK(f->GetCaret() == 0);
    d->InjectKeyDown(Key(KeyCode::Right)); // over 'é'
    CHECK(f->GetCaret() == 2);
    d->InjectKeyDown(Key(KeyCode::Right)); // over '€'
    CHECK(f->GetCaret() == 5);
    d->InjectKeyDown(Key(KeyCode::Right)); // clamp at end
    CHECK(f->GetCaret() == 5);
    d->InjectKeyDown(Key(KeyCode::Left)); // back over '€'
    CHECK(f->GetCaret() == 2);
    d->InjectKeyDown(Key(KeyCode::End));
    CHECK(f->GetCaret() == 5);
}

TEST_CASE("textfield: each edit is an input; Return and leaving commit a change; Return submits")
{
    auto f = Make<TextField>();
    f->SetSize(core::Float2{100.0f, 24.0f});
    auto other = Make<TextField>();
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->AddChild(f.Get());
    root->AddChild(other.Get());
    EventDispatcher* d = root->GetEventDispatcher();
    f->RequestFocus();

    int inputs = 0, changes = 0, submits = 0, inputEvents = 0, changeEvents = 0, submitEvents = 0;
    core::String last;
    f->SetOnTextChanging([&](core::StringView v) { ++inputs; last = core::String(v); });
    f->SetOnTextChanged([&](core::StringView) { ++changes; });
    f->SetOnSubmit([&](core::StringView) { ++submits; });
    (void)f->AddEventListener(EventType::Input, [&](const Event&) { ++inputEvents; });
    (void)f->AddEventListener(EventType::Changed, [&](const Event&) { ++changeEvents; });
    (void)f->AddEventListener(EventType::Submit, [&](const Event&) { ++submitEvents; });

    d->InjectText(core::StringView(u8"x"));
    CHECK(inputs == 1);
    CHECK(last.AsView() == core::StringView(u8"x"));
    d->InjectKeyDown(Key(KeyCode::Backspace));
    CHECK(inputs == 2);
    CHECK(last.Size() == 0);
    d->InjectKeyDown(Key(KeyCode::Home)); // a move is no edit
    CHECK(inputs == 2);
    CHECK(inputEvents == 2);
    CHECK(changes == 0); // nothing committed yet (and the value is back where it was)

    d->InjectText(core::StringView(u8"go"));
    d->InjectKeyDown(Key(KeyCode::Return));
    CHECK(changes == 1);
    CHECK(submits == 1);
    CHECK(changeEvents == 1);
    CHECK(submitEvents == 1);
    d->InjectKeyDown(Key(KeyCode::Return)); // the same value: submitted again, not changed again
    CHECK(changes == 1);
    CHECK(submits == 2);

    d->InjectText(core::StringView(u8"!"));
    other->RequestFocus(); // leaving commits the new value
    CHECK(changes == 2);
    CHECK(submits == 2);

    f->SetText(core::StringView(u8"from code")); // code's value reports nothing
    CHECK(inputs == 4);
    CHECK(changes == 2);
}

TEST_CASE("textfield: mouse press focuses and places the caret at the nearest boundary")
{
    fonts::CachedFont cf(core::DefaultAllocator(), NewMock(), nullptr, nullptr); // 6px/byte
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 100.0f});
    auto f = Make<TextField>();
    f->SetSize(core::Float2{100.0f, 24.0f});
    f->SetFont(&cf);
    f->SetText(core::StringView(u8"abcd")); // widths at boundaries: 0,6,12,18,24
    root->AddChild(f.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    // Click near x=13 (content x, no padding) -> closest boundary is offset 2 (width 12).
    d->InjectMouseDown(core::Float2{13.0f, 12.0f}, MouseButton::Left);
    CHECK(f->IsFocused());
    CHECK(f->GetCaret() == 2);

    // Click past the end -> caret at end.
    d->InjectMouseDown(core::Float2{90.0f, 12.0f}, MouseButton::Left);
    CHECK(f->GetCaret() == 4);

    // Click at the far left -> caret at start.
    d->InjectMouseDown(core::Float2{0.0f, 12.0f}, MouseButton::Left);
    CHECK(f->GetCaret() == 0);
}

TEST_CASE("textfield: caret draws only while focused")
{
    fonts::CachedFont cf(core::DefaultAllocator(), NewMock(), nullptr, nullptr);
    auto f = Make<TextField>();
    f->SetSize(core::Float2{100.0f, 24.0f});
    f->SetFont(&cf);

    // Not focused: no caret geometry (empty text, no font-service atlas -> no glyph geometry).
    {
        vg::VGContext ctx;
        DrawContext dc{ctx};
        f->Draw(dc);
        CHECK(ctx.GetBatch().vertices.Size() == 0);
    }

    // Focused (via a coordinator root so RequestFocus routes): caret rect is drawn.
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->AddChild(f.Get());
    f->RequestFocus();
    {
        vg::VGContext ctx;
        DrawContext dc{ctx};
        f->Draw(dc);
        CHECK(ctx.GetBatch().vertices.Size() > 0); // the caret quad
    }
}

TEST_CASE("textfield: WantsTextInput drives the dispatcher's text-input wish by focus")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 100.0f});
    auto f = Make<TextField>();
    f->SetSize(core::Float2{100.0f, 24.0f});
    auto plain = Make<Button>(); // a non-editing widget
    plain->SetSize(core::Float2{100.0f, 24.0f});
    root->AddChild(f.Get());
    root->AddChild(plain.Get());
    EventDispatcher* d = root->GetEventDispatcher();

    CHECK(f->WantsTextInput());           // an editable field wants text input
    CHECK_FALSE(plain->WantsTextInput()); // a button does not

    CHECK_FALSE(d->WantsTextInput()); // nothing focused
    f->RequestFocus();
    CHECK(d->WantsTextInput()); // the field is focused
    plain->RequestFocus();
    CHECK_FALSE(d->WantsTextInput()); // focus moved to a non-editing widget

    // A disabled field does not want text input.
    f->RequestFocus();
    f->SetEnabled(false);
    CHECK_FALSE(f->WantsTextInput());
    CHECK_FALSE(d->WantsTextInput());
}

TEST_CASE("textfield: blink toggles the caret over time while focused")
{
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    auto f = Make<TextField>();
    root->AddChild(f.Get());
    root->SetSize(core::Float2{200.0f, 100.0f});
    root->UpdateLayout();
    f->RequestFocus(); // shown at once
    CHECK(f->IsCaretShown());

    // The field drives its own blink on the GUI's clock: off after half a period, on after
    // another, and the GUI asks for frames meanwhile.
    const auto frames = [&](int n)
    {
        for (int i = 0; i < n; ++i)
            root->GetContext().Update(core::Duration::FromSeconds(0.1));
    };
    frames(3);
    CHECK(f->IsCaretShown());
    CHECK(root->NeedsFrame());
    frames(3); // 0.6 s
    CHECK_FALSE(f->IsCaretShown());
    frames(5); // 1.1 s
    CHECK(f->IsCaretShown());

    // Unfocused: no caret, and the blink stops asking for frames.
    f->ReleaseFocus();
    frames(2);
    CHECK_FALSE(f->IsCaretShown());
    frames(1);
    CHECK_FALSE(root->GetContext().GetActionManager().AnyAction([&](const Action&, Node& n) { return &n == f.Get(); }));
    // Focus again: it blinks again (a new tick), starting shown.
    f->RequestFocus();
    CHECK(f->IsCaretShown());
    frames(6);
    CHECK_FALSE(f->IsCaretShown());
}

// ===================== Selection =====================

namespace
{
    // A focused field holding `value`, wired under a scene so it has a dispatcher.
    struct Fixture
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<TextField> field = Make<TextField>();
        fonts::CachedFont font{core::DefaultAllocator(), NewMock(), nullptr, nullptr};

        explicit Fixture(core::StringView value = {})
        {
            root->SetSize(core::Float2{400.0f, 100.0f});
            field->SetSize(core::Float2{200.0f, 24.0f});
            field->SetFont(&font);
            root->AddChild(field.Get());
            if (value.Size() > 0)
                field->SetText(value);
            field->RequestFocus();
        }
        EventDispatcher* d() { return root->GetEventDispatcher(); }
    };
}

TEST_CASE("textfield: shift+arrows extend a selection; the selection reports its text")
{
    Fixture fx(u8"hello");
    fx.field->SetCaret(0);
    CHECK_FALSE(fx.field->HasSelection());

    const core::u32 shift = static_cast<core::u32>(KeyModShift);
    fx.d()->InjectKeyDown(Key(KeyCode::Right), shift);
    fx.d()->InjectKeyDown(Key(KeyCode::Right), shift);
    CHECK(fx.field->HasSelection());
    CHECK(fx.field->SelectedText() == core::StringView(u8"he"));
    CHECK(fx.field->GetCaret() == 2);

    // A plain (no-shift) Right collapses the selection to its right edge.
    fx.d()->InjectKeyDown(Key(KeyCode::Right));
    CHECK_FALSE(fx.field->HasSelection());
    CHECK(fx.field->GetCaret() == 2);
}

TEST_CASE("textfield: shift+Home selects to the start; plain Left collapses to selection start")
{
    Fixture fx(u8"hello");
    fx.field->SetCaret(5);
    const core::u32 shift = static_cast<core::u32>(KeyModShift);
    fx.d()->InjectKeyDown(Key(KeyCode::Home), shift);
    CHECK(fx.field->SelectedText() == core::StringView(u8"hello"));

    // Plain Left with a selection jumps the caret to the selection start (offset 0).
    fx.d()->InjectKeyDown(Key(KeyCode::Left));
    CHECK_FALSE(fx.field->HasSelection());
    CHECK(fx.field->GetCaret() == 0);
}

TEST_CASE("textfield: typing over a selection replaces it")
{
    Fixture fx(u8"hello");
    fx.field->SelectAll();
    CHECK(fx.field->SelectedText() == core::StringView(u8"hello"));
    fx.d()->InjectText(core::StringView(u8"X"));
    CHECK(fx.field->GetText() == core::StringView(u8"X"));
    CHECK(fx.field->GetCaret() == 1);
    CHECK_FALSE(fx.field->HasSelection());
}

TEST_CASE("textfield: backspace and delete remove the whole selection")
{
    Fixture fx(u8"hello");
    fx.field->SetCaret(1);
    const core::u32 shift = static_cast<core::u32>(KeyModShift);
    fx.d()->InjectKeyDown(Key(KeyCode::Right), shift);
    fx.d()->InjectKeyDown(Key(KeyCode::Right), shift);
    fx.d()->InjectKeyDown(Key(KeyCode::Right), shift); // "ell" selected
    CHECK(fx.field->SelectedText() == core::StringView(u8"ell"));
    fx.d()->InjectKeyDown(Key(KeyCode::Backspace));
    CHECK(fx.field->GetText() == core::StringView(u8"ho"));
    CHECK(fx.field->GetCaret() == 1);
}

// ===================== Clipboard =====================

TEST_CASE("textfield: Ctrl+C / Ctrl+V copy and paste a selection through the clipboard")
{
    MemClipboard clip;
    Fixture fx(u8"hello");
    fx.d()->SetClipboard(&clip);

    const core::u32 ctrl = static_cast<core::u32>(KeyModCtrl);
    const core::u32 shift = static_cast<core::u32>(KeyModShift);

    fx.field->SetCaret(0);
    fx.d()->InjectKeyDown(Key(KeyCode::Right), shift);
    fx.d()->InjectKeyDown(Key(KeyCode::Right), shift); // select "he"
    fx.d()->InjectKeyDown(Key(KeyCode::C), ctrl);
    CHECK(clip.GetText() == core::StringView(u8"he"));

    // Paste at the end.
    fx.d()->InjectKeyDown(Key(KeyCode::End));
    fx.d()->InjectKeyDown(Key(KeyCode::V), ctrl);
    CHECK(fx.field->GetText() == core::StringView(u8"hellohe"));
}

TEST_CASE("textfield: Ctrl+X cuts the selection to the clipboard")
{
    MemClipboard clip;
    Fixture fx(u8"hello");
    fx.d()->SetClipboard(&clip);

    fx.field->SelectAll();
    const core::u32 ctrl = static_cast<core::u32>(KeyModCtrl);
    fx.d()->InjectKeyDown(Key(KeyCode::X), ctrl);
    CHECK(clip.GetText() == core::StringView(u8"hello"));
    CHECK(fx.field->GetText().Size() == 0);
}

TEST_CASE("textfield: paste with no clipboard configured is a safe no-op")
{
    Fixture fx(u8"hi");
    const core::u32 ctrl = static_cast<core::u32>(KeyModCtrl);
    fx.d()->InjectKeyDown(Key(KeyCode::V), ctrl); // no clipboard set -> nothing happens
    CHECK(fx.field->GetText() == core::StringView(u8"hi"));
}

TEST_CASE("textfield: pasted line breaks become spaces to keep the value on one line")
{
    MemClipboard clip;
    clip.SetText(core::StringView(u8"a\nb\r\nc"));
    Fixture fx;
    fx.d()->SetClipboard(&clip);
    const core::u32 ctrl = static_cast<core::u32>(KeyModCtrl);
    fx.d()->InjectKeyDown(Key(KeyCode::V), ctrl);
    CHECK(fx.field->GetText() == core::StringView(u8"a b c"));
}

// ===================== Placeholder / max-length =====================

TEST_CASE("textfield: placeholder is stored and reported")
{
    auto f = Make<TextField>();
    f->SetPlaceholder(core::StringView(u8"Search..."));
    CHECK(f->GetPlaceholder() == core::StringView(u8"Search..."));
}

TEST_CASE("textfield: max-length caps typed input and truncates a paste")
{
    Fixture fx;
    fx.field->SetMaxLength(3);
    fx.d()->InjectText(core::StringView(u8"ab"));
    fx.d()->InjectText(core::StringView(u8"cd")); // only 'c' fits (cap of 3)
    CHECK(fx.field->GetText() == core::StringView(u8"abc"));

    // Further input past the cap is dropped.
    fx.d()->InjectText(core::StringView(u8"z"));
    CHECK(fx.field->GetText() == core::StringView(u8"abc"));

    // A paste is likewise truncated to the remaining room (here: none).
    MemClipboard clip;
    clip.SetText(core::StringView(u8"XYZ"));
    fx.d()->SetClipboard(&clip);
    const core::u32 ctrl = static_cast<core::u32>(KeyModCtrl);
    fx.d()->InjectKeyDown(Key(KeyCode::V), ctrl);
    CHECK(fx.field->GetText() == core::StringView(u8"abc"));
}

TEST_CASE("textfield: max-length counts graphemes, not bytes or codepoints")
{
    Fixture fx;
    fx.field->SetMaxLength(2);
    fx.d()->InjectText(core::StringView(u8"ééé")); // three 2-byte 'é'
    CHECK(fx.field->GetText() == core::StringView(u8"éé"));
    Fixture combining;
    combining.field->SetMaxLength(2);
    combining.d()->InjectText(core::StringView(u8"e\u0301e\u0301e\u0301")); // e + a combining acute, three times
    CHECK(combining.field->GetText() == core::StringView(u8"e\u0301e\u0301"));
}

// ===================== Mouse selection =====================

TEST_CASE("textfield: a double-click selects the word under the cursor")
{
    Fixture fx(u8"foo bar baz"); // words at 0-3, 4-7, 8-11 (6px/byte)
    // Two presses at the same spot with no time advance = a double-click. x within "bar".
    const core::Float2 pos{5.0f * 6.0f + 3.0f, 12.0f}; // ~ byte 5, inside "bar"
    fx.d()->InjectMouseDown(pos, MouseButton::Left);
    fx.d()->InjectMouseUp(pos, MouseButton::Left);
    fx.d()->InjectMouseDown(pos, MouseButton::Left);
    CHECK(fx.field->SelectedText() == core::StringView(u8"bar"));
}

TEST_CASE("textfield: dragging the mouse extends the selection")
{
    Fixture fx(u8"hello");
    // Press at the start, move right to ~offset 3, release.
    fx.d()->InjectMouseDown(core::Float2{0.0f, 12.0f}, MouseButton::Left);
    CHECK_FALSE(fx.field->HasSelection());
    fx.d()->InjectMouseMove(core::Float2{3.0f * 6.0f, 12.0f}); // captured by the pressed field
    CHECK(fx.field->HasSelection());
    CHECK(fx.field->SelectedText() == core::StringView(u8"hel"));
    fx.d()->InjectMouseUp(core::Float2{3.0f * 6.0f, 12.0f}, MouseButton::Left);
    // A move after release no longer extends.
    fx.d()->InjectMouseMove(core::Float2{5.0f * 6.0f, 12.0f});
    CHECK(fx.field->SelectedText() == core::StringView(u8"hel"));
}

TEST_CASE("textfield: shift+click extends the selection from the caret")
{
    Fixture fx(u8"hello");
    fx.field->SetCaret(1); // after 'h'
    const core::u32 shift = static_cast<core::u32>(KeyModShift);
    fx.d()->InjectMouseDown(core::Float2{4.0f * 6.0f, 12.0f}, MouseButton::Left, shift);
    CHECK(fx.field->HasSelection());
    CHECK(fx.field->SelectedText() == core::StringView(u8"ell"));
}

TEST_CASE("textfield: a right press keeps the caret and the selection")
{
    Fixture fx(u8"hello");
    fx.field->SetCaret(1);
    const core::u32 shift = static_cast<core::u32>(KeyModShift);
    fx.d()->InjectMouseDown(core::Float2{4.0f * 6.0f, 12.0f}, MouseButton::Left, shift);
    fx.d()->InjectMouseUp(core::Float2{4.0f * 6.0f, 12.0f}, MouseButton::Left);
    REQUIRE(fx.field->SelectedText() == core::StringView(u8"ell"));
    fx.d()->InjectMouseDown(core::Float2{0.0f, 12.0f}, MouseButton::Right); // where a context menu opens
    fx.d()->InjectMouseUp(core::Float2{0.0f, 12.0f}, MouseButton::Right);
    CHECK(fx.field->SelectedText() == core::StringView(u8"ell"));
    CHECK(fx.field->GetCaret() == 4u);
    fx.d()->InjectMouseMove(core::Float2{2.0f * 6.0f, 12.0f}); // and no drag-select began
    CHECK(fx.field->SelectedText() == core::StringView(u8"ell"));
}

TEST_CASE("textfield: what it shows is cut at its padding, not drawn past its box")
{
    // 16 bytes at 6px is 96 wide, in a content box of 52 (60 less 4 each side): the selection
    // drawn behind the whole value is clipped to the content box, with room for a caret.
    fonts::CachedFont cf(core::DefaultAllocator(), NewMock(), nullptr, nullptr);
    auto root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
    root->SetSize(core::Float2{200.0f, 100.0f});
    auto f = Make<TextField>();
    f->SetFont(&cf);
    f->SetPadding(Thickness{4.0f, 0.0f});
    f->SetSize(core::Float2{60.0f, 24.0f});
    f->SetText(core::StringView(u8"abcdefghijklmnop"));
    root->AddChild(f.Get());
    root->UpdateLayout();
    f->RequestFocus();
    f->SelectAll();

    vg::VGContext ctx;
    DrawContext dc{ctx};
    f->Draw(dc);
    REQUIRE_FALSE(ctx.GetBatch().commands.IsEmpty());
    for (const vg::VGCommand& cmd : ctx.GetBatch().commands)
    {
        CHECK(cmd.clipRect.x >= 4.0f - 0.01f);
        CHECK(cmd.clipRect.x + cmd.clipRect.width <= 56.0f + 1.5f + 0.01f);
    }
}

// ===================== The editing model's keys and rules (E4) =====================

TEST_CASE("textfield: the editing keys are commands: word moves, undo, and a binding that overrides one")
{
    Fixture fx(u8"one two three");
    const core::u32 ctrl = static_cast<core::u32>(KeyModCtrl);
    fx.d()->InjectKeyDown(Key(KeyCode::Left), ctrl);
    CHECK(fx.field->GetCaret() == 8u); // before "three"
    fx.d()->InjectKeyDown(Key(KeyCode::Backspace), ctrl);
    CHECK(fx.field->GetText() == core::StringView(u8"one three"));
    fx.d()->InjectKeyDown(Key(KeyCode::Z), ctrl);
    CHECK(fx.field->GetText() == core::StringView(u8"one two three"));
    fx.d()->InjectKeyDown(Key(KeyCode::Y), ctrl);
    CHECK(fx.field->GetText() == core::StringView(u8"one three"));

    // A screen unbinds Ctrl+A in fields: the keystroke does nothing there now.
    fx.field->SetCaret(0);
    REQUIRE(fx.root->GetContext().GetKeymap().Bind(core::StringView(u8"ctrl-a"), core::StringView(), core::StringView(u8"textinput")));
    fx.d()->InjectKeyDown(Key(KeyCode::A), ctrl);
    CHECK_FALSE(fx.field->HasSelection());
    // A menu runs the command by its name along the focus path all the same.
    CHECK(fx.root->RunCommand(core::StringView(u8"text.select-all")));
    CHECK(fx.field->SelectedText() == core::StringView(u8"one three"));
    CHECK(fx.root->IsCommandAvailable(core::StringView(u8"text.paste")));
}

TEST_CASE("textfield: typing keys are the field's; up and down still move focus")
{
    Fixture fx(u8"ab");
    auto below = Make<Button>();
    below->SetPosition(core::Float2{0.0f, 50.0f});
    below->SetSize(core::Float2{100.0f, 24.0f});
    fx.root->AddChild(below.Get());
    fx.root->UpdateLayout();
    CHECK(fx.d()->InjectKeyDown(Key(KeyCode::Space))); // taken: no activation, the text comes as text input
    CHECK(fx.field->IsFocused());
    fx.d()->InjectKeyDown(Key(KeyCode::Down));
    CHECK(below->IsFocused());
}

TEST_CASE("textfield: a read-only field takes no edits from keys, typing or paste, and still copies")
{
    MemClipboard clip;
    clip.SetText(core::StringView(u8"pasted"));
    Fixture fx(u8"fixed");
    fx.d()->SetClipboard(&clip);
    fx.field->SetReadOnly(true);
    const core::u32 ctrl = static_cast<core::u32>(KeyModCtrl);
    fx.d()->InjectText(core::StringView(u8"x"));
    fx.d()->InjectKeyDown(Key(KeyCode::Backspace));
    fx.d()->InjectKeyDown(Key(KeyCode::V), ctrl);
    CHECK(fx.field->GetText() == core::StringView(u8"fixed"));
    fx.field->SelectAll();
    fx.d()->InjectKeyDown(Key(KeyCode::X), ctrl);
    CHECK(clip.GetText() == core::StringView(u8"fixed"));
    CHECK(fx.field->GetText() == core::StringView(u8"fixed"));
}

TEST_CASE("textfield: an input filter lets in only what it accepts")
{
    Fixture fx;
    fx.field->SetInputFilter(InputFilter::Digits());
    fx.d()->InjectText(core::StringView(u8"a1b2"));
    CHECK(fx.field->GetText() == core::StringView(u8"12"));
}

TEST_CASE("textfield: a long value scrolls to keep the caret in view")
{
    Fixture fx; // 200 wide, 6px a byte: 33 characters fit
    fx.d()->InjectText(core::StringView(u8"0123456789012345678901234567890123456789")); // 40: 240px
    CHECK(fx.field->GetScrollX() > 0.0f);
    CHECK(fx.field->GetScrollX() == doctest::Approx(240.0f - (200.0f - 1.5f)));
    fx.d()->InjectKeyDown(Key(KeyCode::Home));
    CHECK(fx.field->GetScrollX() == doctest::Approx(0.0f));
    // A click maps through the scroll: at the right edge after End, the caret is near the end.
    fx.d()->InjectKeyDown(Key(KeyCode::End));
    fx.d()->InjectMouseDown(core::Float2{199.0f, 12.0f}, MouseButton::Left);
    CHECK(fx.field->GetCaret() >= 39u);
}

TEST_CASE("textfield: a short line sits where its alignment puts it, start being the right in right to left")
{
    // 200 wide, 6px a byte: "abcd" is 24px; the view is 198.5 (the caret's width kept clear).
    const auto at = [](TextField& f, core::f32 x) { return f.ConvertToRootSpace(core::Float2{x, 12.0f}); };
    {
        Fixture fx(u8"abcd");
        fx.root->SetLayoutDirection(Node::LayoutDirection::RightToLeft);
        (void)fx.root->UpdateLayout();
        // Against the right edge: the line spans 174.5 to 198.5.
        fx.d()->InjectMouseDown(at(*fx.field, 183.0f), MouseButton::Left);
        fx.d()->InjectMouseUp(at(*fx.field, 183.0f), MouseButton::Left);
        CHECK(fx.field->GetCaret() == 1u); // just past the a
        fx.d()->InjectMouseDown(at(*fx.field, 20.0f), MouseButton::Left);
        fx.d()->InjectMouseUp(at(*fx.field, 20.0f), MouseButton::Left);
        CHECK(fx.field->GetCaret() == 0u); // left of this left-to-right run: its start
    }
    {
        Fixture fx(u8"abcd");
        fx.field->SetTextAlignment(TextHAlign::End, TextVAlign::Middle);
        (void)fx.root->UpdateLayout();
        fx.d()->InjectMouseDown(at(*fx.field, 183.0f), MouseButton::Left);
        fx.d()->InjectMouseUp(at(*fx.field, 183.0f), MouseButton::Left);
        CHECK(fx.field->GetCaret() == 1u);
        fx.field->SetTextAlignment(TextHAlign::Center, TextVAlign::Middle); // 87.25 to 111.25
        fx.d()->InjectMouseDown(at(*fx.field, 99.0f), MouseButton::Left);
        fx.d()->InjectMouseUp(at(*fx.field, 99.0f), MouseButton::Left);
        CHECK(fx.field->GetCaret() == 2u);
    }
}

TEST_CASE("textfield: a long right-to-left line rests on its start, the right, and scrolls from there")
{
    Fixture fx;
    fx.root->SetLayoutDirection(Node::LayoutDirection::RightToLeft);
    (void)fx.root->UpdateLayout();
    fx.d()->InjectText(core::StringView(u8"0123456789012345678901234567890123456789")); // 240px
    // The caret at the end of this left-to-right run, its right: the right part shows.
    CHECK(fx.field->GetScrollX() == doctest::Approx(0.0f));
    fx.d()->InjectKeyDown(Key(KeyCode::Home)); // the run's start, its left: scrolled from the right
    CHECK(fx.field->GetScrollX() == doctest::Approx(240.0f - (200.0f - 1.5f)));
}

TEST_CASE("textfield: a password shows a mask, keeps carets on its characters, and lets nothing out")
{
    MemClipboard clip;
    Fixture fx;
    fx.d()->SetClipboard(&clip);
    fx.field->SetPassword(true);
    fx.d()->InjectText(core::StringView(u8"s\u00e9cret"));
    CHECK(fx.field->GetText() == core::StringView(u8"s\u00e9cret"));
    // A press after the third mask (each 6px a byte, three bytes a bullet: 18 a character).
    fx.d()->InjectMouseDown(core::Float2{3.0f * 18.0f + 1.0f, 12.0f}, MouseButton::Left);
    CHECK(fx.field->GetCaret() == 4u); // after "s\u00e9c": é is two bytes
    fx.field->SelectAll();
    const core::u32 ctrl = static_cast<core::u32>(KeyModCtrl);
    fx.d()->InjectKeyDown(Key(KeyCode::C), ctrl);
    fx.d()->InjectKeyDown(Key(KeyCode::X), ctrl);
    CHECK_FALSE(clip.HasText());
    CHECK(fx.field->GetText() == core::StringView(u8"s\u00e9cret"));
}

TEST_CASE("textfield: an IME's composition shows in place of the selection until it commits as text")
{
    Fixture fx(u8"ab cd");
    fx.field->SetCaret(3); // after "ab "
    int inputs = 0;
    fx.field->SetOnTextChanging([&](core::StringView) { ++inputs; });
    CHECK(fx.d()->InjectComposition(core::StringView(u8"xyz"), 2));
    CHECK(fx.field->GetText() == core::StringView(u8"ab cd")); // not the value yet
    CHECK(inputs == 0);
    // It types where the composition is, the caret two characters into it (6px a byte).
    Rect area{};
    core::f32 caretX = 0.0f;
    REQUIRE(fx.d()->GetTextInputArea(area, caretX));
    CHECK(area.x == doctest::Approx(18.0f));
    CHECK(area.width == doctest::Approx(18.0f));
    CHECK(caretX == doctest::Approx(12.0f));

    fx.d()->InjectComposition(core::StringView(), 0); // ended
    fx.d()->InjectText(core::StringView(u8"XY"));     // committed
    CHECK(fx.field->GetText() == core::StringView(u8"ab XYcd"));
    CHECK(inputs == 1);

    // Over a selection, the committed text replaces it; leaving drops an unfinished one.
    fx.field->SelectAll();
    fx.d()->InjectComposition(core::StringView(u8"q"), 1);
    fx.field->ReleaseFocus();
    CHECK(fx.field->GetText() == core::StringView(u8"ab XYcd"));
}
