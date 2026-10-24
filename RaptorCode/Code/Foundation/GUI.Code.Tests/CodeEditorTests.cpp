// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Code - the view (C1 of Specs/gui-lab-evolution-3.md): typing at every caret, one undo step that
// puts them back; the keymap's moves (smart Home, a goal across for Up and Down), selections and
// deletes at each caret; Return keeping the indent, Tab to a stop, tabs shown to their stops and hit
// by their places; the clipboard (several copied, as many pasted; a line with no selection); the
// mouse (a click, Shift, a double and a triple click, Alt adding a caret, a drag); scrolling to the
// caret; Escape leaving one caret; markup. A mock font: 6px a byte, 12px a line.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.fonts;
import foundation.gui;
import foundation.gui.code;

using namespace foundation::gui;
namespace core = foundation::core;
namespace fonts = foundation::fonts;
using core::f32;
using core::u32;
using core::usize;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }
    CodePosition At(u32 line, u32 column) { return CodePosition{line, column}; }

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

    class MemoryClipboard : public IClipboard
    {
    public:
        [[nodiscard]] bool HasText() const override { return m_text.Size() != 0; }
        [[nodiscard]] core::String GetText() const override { return m_text; }
        void SetText(core::StringView text) override { m_text = core::String(text); }

    private:
        core::String m_text;
    };

    // An editor 400 by 120 (ten lines of 12) at the root's top-left, focused.
    struct Bed
    {
        fonts::CachedFont font{core::DefaultAllocator(), core::DefaultAllocator().New<SixFont>(), nullptr, nullptr};
        MemoryClipboard clipboard;
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<CodeEditor> editor = core::MakeRef<CodeEditor>(core::DefaultAllocator());

        explicit Bed(const char8_t* text = u8"")
        {
            BindCodeEditorKeys(root->GetContext().GetKeymap()); // the host's, once for its GUI
            root->SetSize(core::Float2{800.0f, 600.0f});
            root->EditLayoutStyle([](LayoutStyle& s) { s.AlignItems = Align::Start; });
            editor->EditLayoutStyle([](LayoutStyle& s)
            {
                s.Width = LayoutLength::Px(400.0f);
                s.Height = LayoutLength::Px(120.0f);
            });
            editor->SetFont(&font);
            root->AddChild(editor.Get());
            D().SetClipboard(&clipboard);
            editor->SetText(SV(text));
            Frame();
            editor->RequestFocus();
        }
        ~Bed() { D().SetClipboard(nullptr); }
        EventDispatcher& D() { return *root->GetEventDispatcher(); }
        void Frame(f32 seconds = 0.016f)
        {
            root->GetContext().Update(core::Duration::FromSeconds(seconds));
            (void)root->UpdateLayout();
        }
        [[nodiscard]] core::String Text() const { return editor->GetText(); }
        [[nodiscard]] CodePosition Caret() const { return editor->GetPrimary().Head; }
        // A point over a position: its caret's middle (screen space, the editor at the origin).
        [[nodiscard]] core::Float2 Over(CodePosition at) const
        {
            const Rect caret = editor->CaretRect(at);
            return core::Float2{caret.x + 1.0f, caret.y + caret.height * 0.5f};
        }
        void Click(core::Float2 at, core::u32 modifiers = 0)
        {
            D().InjectMouseMove(at, modifiers);
            D().InjectMouseDown(at, MouseButton::Left, modifiers);
            D().InjectMouseUp(at, MouseButton::Left, modifiers);
        }
        void Pause() { Frame(1.0f); }
        bool Run(TextEditCommand command) { return editor->Run(command); }
    };
}

TEST_CASE("code editor: typing at every caret is one undo step that puts them back")
{
    Bed bed(u8"int a;\nint b;");
    bed.editor->SetCaret(At(0, 0));
    bed.editor->AddCaret(At(1, 0));
    REQUIRE(bed.editor->GetSelections().Size() == 2);
    bed.editor->Type(SV(u8"/"));
    bed.editor->Type(SV(u8"/"));
    CHECK(bed.Text() == core::String(u8"//int a;\n//int b;"));
    CHECK(bed.editor->GetSelections()[0].Head == At(0, 2));
    CHECK(bed.editor->GetSelections()[1].Head == At(1, 2));
    CHECK(bed.editor->GetDocument().UndoCount() == 1u); // typing merged
    REQUIRE(bed.Run(TextEditCommand::Undo));
    CHECK(bed.Text() == core::String(u8"int a;\nint b;"));
    REQUIRE(bed.editor->GetSelections().Size() == 2);
    CHECK(bed.editor->GetSelections()[1].Head == At(1, 0));
    REQUIRE(bed.Run(TextEditCommand::Redo));
    CHECK(bed.Text() == core::String(u8"//int a;\n//int b;"));

    // Typing over a selection replaces it; several carets on one line keep their places.
    const CodeSelection two[] = {CodeSelection{At(0, 2), At(0, 5)}, CodeSelection{At(0, 6), At(0, 6)}};
    bed.editor->SetSelections(two);
    bed.editor->Type(SV(u8"X"));
    CHECK(bed.editor->GetDocument().LineText(0) == SV(u8"//X Xa;"));
    CHECK(bed.editor->GetSelections()[1].Head == At(0, 5));
}

TEST_CASE("code editor: the keymap's moves at each caret: smart Home, words, a goal across for Up and Down")
{
    Bed bed(u8"    long line here\nab\nanother long line");
    bed.editor->SetCaret(At(0, 10));
    bed.Run(TextEditCommand::MoveLineStart);
    CHECK(bed.Caret() == At(0, 4)); // past the indent
    bed.Run(TextEditCommand::MoveLineStart);
    CHECK(bed.Caret() == At(0, 0)); // then the line's start
    bed.Run(TextEditCommand::MoveLineEnd);
    CHECK(bed.Caret() == At(0, 18));
    bed.Run(TextEditCommand::MoveWordLeft);
    CHECK(bed.Caret() == At(0, 14));
    bed.Run(TextEditCommand::MoveRight);
    CHECK(bed.Caret() == At(0, 15));
    // Down through a short line keeps the column it set out from.
    bed.editor->SetCaret(At(0, 12));
    bed.Run(TextEditCommand::MoveDown);
    CHECK(bed.Caret() == At(1, 2));
    bed.Run(TextEditCommand::MoveDown);
    CHECK(bed.Caret() == At(2, 12));
    bed.Run(TextEditCommand::MoveDown); // past the last line: its end
    CHECK(bed.Caret() == At(2, 17));
    // Selecting extends; a move without collapses to the side it goes.
    bed.editor->SetCaret(At(1, 0));
    bed.Run(TextEditCommand::SelectRight);
    bed.Run(TextEditCommand::SelectRight);
    CHECK(bed.editor->GetPrimary().Range() == CodeRange{At(1, 0), At(1, 2)});
    bed.Run(TextEditCommand::MoveLeft);
    CHECK(bed.Caret() == At(1, 0));
    bed.Run(TextEditCommand::SelectAll);
    CHECK(bed.editor->GetPrimary().Range() == CodeRange{At(0, 0), At(2, 17)});
    bed.Run(TextEditCommand::MoveDocumentStart);
    CHECK(bed.Caret() == At(0, 0));
}

TEST_CASE("code editor: deletes at each caret, carets that meet becoming one")
{
    Bed bed(u8"abc\ndef");
    bed.editor->SetCaret(At(0, 2));
    bed.editor->AddCaret(At(1, 2));
    bed.Run(TextEditCommand::DeleteBackward);
    CHECK(bed.Text() == core::String(u8"ac\ndf"));
    bed.Run(TextEditCommand::DeleteBackward);
    CHECK(bed.Text() == core::String(u8"c\nf"));
    bed.Run(TextEditCommand::DeleteBackward); // the second caret joins the lines
    CHECK(bed.Text() == core::String(u8"cf"));
    CHECK(bed.editor->GetSelections().Size() == 2);
    bed.editor->SetText(SV(u8"one two"));
    bed.editor->SetCaret(At(0, 7));
    bed.Run(TextEditCommand::DeleteWordBackward);
    CHECK(bed.Text() == core::String(u8"one "));
    // Two carets on one place are one.
    bed.editor->SetCaret(At(0, 1));
    bed.editor->AddCaret(At(0, 1));
    CHECK(bed.editor->GetSelections().Size() == 1);
}

TEST_CASE("code editor: Return keeps the indent; Tab to the next stop; tabs shown at their stops and hit there")
{
    Bed bed(u8"    if (x)");
    bed.editor->SetCaret(At(0, 10));
    bed.Run(TextEditCommand::InsertNewline);
    CHECK(bed.Text() == core::String(u8"    if (x)\n    "));
    CHECK(bed.Caret() == At(1, 4));
    bed.editor->SetText(SV(u8"ab"));
    bed.editor->SetCaret(At(0, 2));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Tab));
    CHECK(bed.Text() == core::String(u8"ab  ")); // to column 4

    bed.editor->SetText(SV(u8"\tx\ta"));
    bed.Frame();
    const f32 left = bed.editor->TextLeft();
    CHECK(bed.editor->CaretRect(At(0, 1)).x == doctest::Approx(left + 4.0f * 6.0f)); // after the tab: column 4
    CHECK(bed.editor->CaretRect(At(0, 3)).x == doctest::Approx(left + 8.0f * 6.0f)); // x then a tab to 8
    // A point inside a tab's spaces goes to its nearer side.
    const f32 y = bed.editor->CaretRect(At(0, 0)).y + 6.0f;
    CHECK(bed.editor->PositionAt(core::Float2{left + 6.0f, y}) == At(0, 0));
    CHECK(bed.editor->PositionAt(core::Float2{left + 20.0f, y}) == At(0, 1));
}

TEST_CASE("code editor: the clipboard: several copied, as many pasted; with no selection, the caret's line")
{
    Bed bed(u8"alpha\nbeta\ngamma");
    const CodeSelection words[] = {CodeSelection{At(0, 0), At(0, 5)}, CodeSelection{At(1, 0), At(1, 4)}};
    bed.editor->SetSelections(words);
    bed.Run(TextEditCommand::Copy);
    CHECK(bed.clipboard.GetText() == core::String(u8"alpha\nbeta"));
    // Two carets, two lines: one each.
    bed.editor->SetCaret(At(2, 0));
    bed.editor->AddCaret(At(2, 5));
    bed.Run(TextEditCommand::Paste);
    CHECK(bed.editor->GetDocument().LineText(2) == SV(u8"alphagammabeta"));
    // One caret: the whole text there.
    bed.editor->SetCaret(At(0, 0));
    bed.Run(TextEditCommand::Paste);
    CHECK(bed.editor->GetDocument().LineText(0) == SV(u8"alpha"));
    CHECK(bed.editor->GetDocument().LineText(1) == SV(u8"betaalpha"));
    // No selection: copy and cut the caret's line.
    bed.editor->SetText(SV(u8"one\ntwo\nthree"));
    bed.editor->SetCaret(At(1, 1));
    bed.Run(TextEditCommand::Cut);
    CHECK(bed.clipboard.GetText() == core::String(u8"two\n"));
    CHECK(bed.Text() == core::String(u8"one\nthree"));
}

TEST_CASE("code editor: the mouse: a click, Shift, a double and a triple click, Alt adding a caret, a drag")
{
    Bed bed(u8"int value = 42;\nreturn value;");
    bed.Click(bed.Over(At(0, 6)));
    CHECK(bed.Caret() == At(0, 6));
    CHECK(bed.editor->IsFocused());
    bed.Pause();
    bed.Click(bed.Over(At(1, 3)), KeyModShift);
    CHECK(bed.editor->GetPrimary().Range() == CodeRange{At(0, 6), At(1, 3)});
    bed.Pause();
    bed.Click(bed.Over(At(0, 6)));
    bed.Click(bed.Over(At(0, 6))); // the second of a double
    CHECK(bed.editor->GetPrimary().Range() == CodeRange{At(0, 4), At(0, 9)}); // "value"
    bed.Click(bed.Over(At(0, 6))); // the third
    CHECK(bed.editor->GetPrimary().Range() == CodeRange{At(0, 0), At(1, 0)});
    bed.Pause();
    bed.Click(bed.Over(At(0, 2)));
    bed.Pause();
    bed.Click(bed.Over(At(1, 2)), KeyModAlt);
    REQUIRE(bed.editor->GetSelections().Size() == 2);
    CHECK(bed.editor->GetPrimary().Head == At(1, 2));
    // Escape leaves the primary caret alone.
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    CHECK(bed.editor->GetSelections().Size() == 1);
    CHECK(bed.Caret() == At(1, 2));
    // A drag selects from the press to the pointer.
    bed.Pause();
    const core::Float2 from = bed.Over(At(0, 1));
    const core::Float2 to = bed.Over(At(0, 8));
    bed.D().InjectMouseMove(from);
    bed.D().InjectMouseDown(from, MouseButton::Left);
    bed.D().InjectMouseMove(to);
    bed.D().InjectMouseUp(to, MouseButton::Left);
    CHECK(bed.editor->GetPrimary().Range() == CodeRange{At(0, 1), At(0, 8)});
}

TEST_CASE("code editor: it scrolls to the caret, drawing the lines in view")
{
    core::String text;
    for (int i = 0; i < 100; ++i)
        text.Append(core::Format(u8"line {}\n", i).AsView());
    Bed bed(reinterpret_cast<const char8_t*>(text.CStr()));
    u32 first = 0, last = 0;
    bed.editor->VisibleLines(first, last);
    CHECK(first == 0u);
    CHECK(last <= 10u);
    bed.Run(TextEditCommand::MoveDocumentEnd);
    bed.Frame();
    CHECK(bed.Caret() == At(100, 0));
    bed.editor->VisibleLines(first, last);
    CHECK(last == 100u);
    CHECK(first >= 90u);
    const Rect caret = bed.editor->CaretRect(bed.Caret());
    CHECK(caret.y + caret.height <= bed.editor->GetContentBounds().Bottom() + 0.5f);
    CHECK(bed.editor->GetScrollOffset().y > 0.0f);
    // Typing there lays it out again: it stays where it was scrolled.
    const f32 scrolled = bed.editor->GetScrollOffset().y;
    bed.editor->Type(SV(u8"x"));
    bed.Frame();
    CHECK(bed.editor->GetScrollOffset().y == doctest::Approx(scrolled));
}

TEST_CASE("code editor: its keys come through the keymap; typed text goes in; read only, nothing changes")
{
    Bed bed(u8"abc");
    bed.editor->SetCaret(At(0, 0));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::End));
    CHECK(bed.Caret() == At(0, 3));
    bed.D().InjectText(SV(u8"d"));
    CHECK(bed.Text() == core::String(u8"abcd"));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Backspace));
    CHECK(bed.Text() == core::String(u8"abc"));
    bed.editor->SetReadOnly(true);
    bed.D().InjectText(SV(u8"x"));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Backspace));
    CHECK(bed.Text() == core::String(u8"abc"));
}

TEST_CASE("code editor: two editors over one document see each other's edits")
{
    Bed bed(u8"shared");
    core::RefPtr<CodeEditor> other = core::MakeRef<CodeEditor>(core::DefaultAllocator());
    CodeDocument doc(core::DefaultAllocator());
    doc.SetText(SV(u8"one"));
    bed.editor->SetDocument(&doc);
    other->SetDocument(&doc);
    bed.editor->SetCaret(At(0, 3));
    bed.editor->Type(SV(u8"!"));
    CHECK(other->GetText() == core::String(u8"one!"));
    // Both hear it: the other's caret, after where the text went, moved along with it.
    other->SetCaret(At(0, 3));
    bed.editor->SetCaret(At(0, 0));
    bed.editor->Type(SV(u8">"));
    CHECK(other->GetText() == core::String(u8">one!"));
    CHECK(other->GetPrimary().Head == At(0, 4));
    bed.editor->SetDocument(nullptr); // back to its own
    other->SetDocument(nullptr);
    CHECK(bed.Text() == core::String(u8"shared")); // its own, as it was
}

TEST_CASE("code editor: the gutter's marks stay with their lines; a click in their column is the host's")
{
    Bed bed(u8"zero\none\ntwo\nthree");
    const u32 breakpoint = bed.editor->AddMarker(2, SV(u8"breakpoint"));
    const u32 bookmark = bed.editor->AddMarker(3, SV(u8"bookmark"));
    CHECK(bed.editor->HasMarker(2, SV(u8"breakpoint")));
    bed.editor->GetDocument().Insert(At(0, 0), SV(u8"new\n"));
    CHECK(bed.editor->MarkerLine(breakpoint) == 3u);
    // Return at its line's start: the mark goes down with the text.
    bed.editor->SetCaret(At(3, 0));
    bed.Run(TextEditCommand::InsertNewline);
    CHECK(bed.editor->MarkerLine(breakpoint) == 4u);
    bed.editor->RemoveMarker(breakpoint);
    CHECK_FALSE(bed.editor->HasMarker(4, SV(u8"breakpoint")));
    CHECK(bed.editor->MarkerLine(bookmark) == 5u);
    bed.editor->ClearMarkers(SV(u8"bookmark"));
    CHECK(bed.editor->MarkerLine(bookmark) == ~u32(0));

    // A click in the marker column: told its line, the caret staying.
    core::Array<u32> clicked{core::DefaultAllocator()};
    bed.editor->SetOnGutterClick([&clicked](u32 line) { clicked.PushBack(line); });
    bed.editor->SetCaret(At(0, 1));
    const Rect row = bed.editor->CaretRect(At(2, 0));
    bed.Click(core::Float2{bed.editor->GetContentBounds().x + 4.0f, row.y + row.height * 0.5f});
    REQUIRE(clicked.Size() == 1);
    CHECK(clicked[0] == 2u);
    CHECK(bed.Caret() == At(0, 1));
}

TEST_CASE("code editor: diagnostics keep their places through edits; the worst on a line; their messages on hover")
{
    Bed bed(u8"int a = b;\nfloat c;");
    const CodeDiagnostic set[] = {
        CodeDiagnostic{CodeRange{At(0, 8), At(0, 9)}, CodeSeverity::Error, core::String(u8"'b' is not declared")},
        CodeDiagnostic{CodeRange{At(1, 6), At(1, 6)}, CodeSeverity::Warning, core::String(u8"'c' is never used")},
    };
    bed.editor->SetDiagnostics(set);
    CodeSeverity worst = CodeSeverity::Hint;
    REQUIRE(bed.editor->WorstOn(0, worst));
    CHECK(worst == CodeSeverity::Error);
    REQUIRE(bed.editor->WorstOn(1, worst));
    CHECK(worst == CodeSeverity::Warning);
    CHECK_FALSE(bed.editor->WorstOn(2, worst));
    // An edit before them moves them.
    bed.editor->GetDocument().Insert(At(0, 0), SV(u8"// x\n"));
    const core::Array<CodeDiagnostic> moved = bed.editor->GetDiagnostics();
    REQUIRE(moved.Size() == 2);
    CHECK(moved[0].Range == CodeRange{At(1, 8), At(1, 9)});
    CHECK(moved[1].Range.Start == At(2, 6));
    // An empty one marks its word.
    CHECK(bed.editor->DiagnosticsAt(At(2, 7)) == core::String(u8"'c' is never used"));
    CHECK(bed.editor->DiagnosticsAt(At(1, 8)) == core::String(u8"'b' is not declared"));
    CHECK(bed.editor->DiagnosticsAt(At(1, 2)).IsEmpty());
    // The pointer over one: its message for the tooltip; in the gutter, its line's.
    bed.Frame();
    const Rect at = bed.editor->CaretRect(At(1, 8));
    bed.D().InjectMouseMove(core::Float2{at.x + 3.0f, at.y + at.height * 0.5f});
    CHECK(bed.editor->GetTooltipText() == SV(u8"'b' is not declared"));
    bed.D().InjectMouseMove(core::Float2{bed.editor->GetContentBounds().x + 4.0f, bed.editor->CaretRect(At(2, 0)).y + 6.0f});
    CHECK(bed.editor->GetTooltipText() == SV(u8"'c' is never used"));
    // A new set replaces them.
    bed.editor->SetDiagnostics({});
    CHECK(bed.editor->GetDiagnostics().IsEmpty());
}

TEST_CASE("code editor: an element markup places")
{
    RegisterGuiElements();
    RegisterCodeElements();
    static const ElementSet elements = ElementSet::All();
    MarkupLoader loader(elements, core::DefaultAllocator());
    core::RefPtr<foundation::gui::Node> made = loader.LoadFromString(SV(u8R"(<Panel><CodeEditor tab-size="2" read-only="true"/></Panel>)"));
    REQUIRE(made);
    CodeEditor* editor = core::Cast<CodeEditor>(made->GetChildAt(0));
    REQUIRE(editor != nullptr);
    CHECK(editor->GetTabSize() == 2u);
    CHECK(editor->IsReadOnly());
}
