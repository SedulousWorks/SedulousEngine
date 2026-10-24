// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Code - editing (C3 of Specs/gui-lab-evolution-3.md), with the sandbox's AngelScript, Luau and
// XML definitions: brackets and quotes closed as typed and typed over, a selection surrounded, an
// empty pair or an indent's spaces deleted back; Return indenting after what opens a block and a
// closing word outdenting; comments toggled by line or by block; lines indented, moved, copied and
// deleted; the next occurrence added and all of them; a caret added below; a column by Alt+drag;
// brackets matched past strings and comments; the document's search. The keys are VS Code's.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
#include <fstream>
#include <sstream>
#include <string>
import foundation.core;
import foundation.fonts;
import foundation.xml;
import foundation.xml.serialization;
import foundation.gui;
import foundation.gui.code;

using namespace foundation::gui;
namespace core = foundation::core;
namespace fonts = foundation::fonts;
namespace xml = foundation::xml;
using core::f32;
using core::u32;
using core::usize;

#define CHECK_TEXT(editor, expected)                                                       \
    do                                                                                     \
    {                                                                                      \
        const core::String text_ = (editor).GetText();                                     \
        INFO(doctest::String(reinterpret_cast<const char*>(text_.CStr())));                \
        CHECK(text_ == core::String(expected));                                            \
    } while (false)

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

    bool LoadSandboxLanguage(const char* id, CodeLanguage& out)
    {
        std::ifstream file(std::string(GUI_CODE_SANDBOX_LANGUAGES) + "/" + id + ".xml", std::ios::binary);
        if (!file)
            return false;
        std::stringstream text;
        text << file.rdbuf();
        const std::string bytes = text.str();
        xml::XmlDocument doc(core::DefaultAllocator());
        if (doc.Parse(core::StringView(reinterpret_cast<const char8_t*>(bytes.data()), bytes.size())) != xml::XmlResult::Ok)
            return false;
        xml::XmlSerializer reader(doc);
        Serialize(reader, out);
        return reader.IsOk() && !out.Contexts.IsEmpty();
    }

    // An editor 400 by 240 in a GUI whose keymap has the code editor's keys, focused, in `language`.
    struct Bed
    {
        fonts::CachedFont font{core::DefaultAllocator(), core::DefaultAllocator().New<SixFont>(), nullptr, nullptr};
        CodeLanguage language;
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<CodeEditor> editor = core::MakeRef<CodeEditor>(core::DefaultAllocator());

        explicit Bed(const char* id, const char8_t* text = u8"")
        {
            REQUIRE(LoadSandboxLanguage(id, language));
            BindCodeEditorKeys(root->GetContext().GetKeymap());
            root->SetSize(core::Float2{800.0f, 600.0f});
            root->EditLayoutStyle([](LayoutStyle& s) { s.AlignItems = Align::Start; });
            editor->EditLayoutStyle([](LayoutStyle& s)
            {
                s.Width = LayoutLength::Px(400.0f);
                s.Height = LayoutLength::Px(240.0f);
            });
            editor->SetFont(&font);
            root->AddChild(editor.Get());
            editor->SetLanguage(&language);
            editor->SetText(SV(text));
            Frame();
            editor->RequestFocus();
        }
        EventDispatcher& D() { return *root->GetEventDispatcher(); }
        void Frame(f32 seconds = 0.016f)
        {
            root->GetContext().Update(core::Duration::FromSeconds(seconds));
            (void)root->UpdateLayout();
        }
        void Type(const char8_t* text)
        {
            for (core::StringView rest(text); rest.Size() != 0;)
            {
                const usize next = NextGrapheme(rest, 0);
                editor->Type(rest.SubStr(0, next));
                rest = rest.SubStr(next, rest.Size() - next);
            }
        }
        void Key(KeyCode key, core::u32 modifiers = 0) { D().InjectKeyDown(static_cast<core::u32>(key), modifiers); }
        [[nodiscard]] CodePosition Caret() const { return editor->GetPrimary().Head; }
    };
}

TEST_CASE("code editing: brackets and quotes close as typed, the close typed over; not in a string, not a quote after a name")
{
    Bed bed("angelscript");
    bed.Type(u8"f(");
    CHECK_TEXT(*bed.editor, u8"f()");
    CHECK(bed.Caret() == At(0, 2));
    bed.Type(u8"x)");
    CHECK_TEXT(*bed.editor, u8"f(x)"); // the close typed over the one put
    CHECK(bed.Caret() == At(0, 4));
    bed.Type(u8" = \"");
    CHECK_TEXT(*bed.editor, u8"f(x) = \"\"");
    bed.Type(u8"a(b");
    CHECK_TEXT(*bed.editor, u8"f(x) = \"a(b\""); // in a string: no pair
    bed.editor->SetText(SV(u8"it"));
    bed.editor->SetCaret(At(0, 2));
    bed.Type(u8"'");
    CHECK_TEXT(*bed.editor, u8"it'"); // a quote after a name
    // A selection and an open: surrounded.
    bed.editor->SetText(SV(u8"value"));
    const CodeSelection word{At(0, 0), At(0, 5)};
    bed.editor->SetSelections(core::Span<const CodeSelection>(&word, 1));
    bed.Type(u8"[");
    CHECK_TEXT(*bed.editor, u8"[value]");
}

TEST_CASE("code editing: Backspace takes an empty pair, and an indent's spaces back to the stop before")
{
    Bed bed("angelscript");
    bed.Type(u8"(");
    bed.Key(KeyCode::Backspace);
    CHECK_TEXT(*bed.editor, u8"");
    bed.editor->SetText(SV(u8"      x"));
    bed.editor->SetCaret(At(0, 6));
    bed.Key(KeyCode::Backspace);
    CHECK_TEXT(*bed.editor, u8"    x");
    bed.Key(KeyCode::Backspace);
    CHECK_TEXT(*bed.editor, u8"x");
}

TEST_CASE("code editing: Return indents after what opens a block, the close below; a closing word or mark outdents its line")
{
    Bed bed("angelscript", u8"void f()");
    bed.editor->SetCaret(At(0, 8));
    bed.Type(u8" {");
    CHECK_TEXT(*bed.editor, u8"void f() {}");
    bed.Key(KeyCode::Return);
    CHECK_TEXT(*bed.editor, u8"void f() {\n    \n}");
    CHECK(bed.Caret() == At(1, 4));
    bed.Type(u8"x;");
    bed.Key(KeyCode::Return);
    CHECK_TEXT(*bed.editor, u8"void f() {\n    x;\n    \n}");
    bed.editor->SetText(SV(u8"if (a) {\n    b;\n    "));
    bed.editor->SetCaret(At(2, 4));
    bed.Type(u8"}");
    CHECK_TEXT(*bed.editor, u8"if (a) {\n    b;\n}");

    Bed luau("luau", u8"if x then");
    luau.editor->SetCaret(At(0, 9));
    luau.Key(KeyCode::Return);
    CHECK_TEXT(*luau.editor, u8"if x then\n    ");
    luau.Type(u8"y()");
    luau.Key(KeyCode::Return);
    luau.Type(u8"end");
    CHECK_TEXT(*luau.editor, u8"if x then\n    y()\nend");
}

TEST_CASE("code editing: Ctrl+/ comments lines at their least indent and back; markup by a block")
{
    Bed bed("angelscript", u8"    a;\n        b;\n\n    c;");
    const CodeSelection all{At(0, 0), At(3, 6)};
    bed.editor->SetSelections(core::Span<const CodeSelection>(&all, 1));
    bed.Key(KeyCode::Slash, KeyModCtrl);
    CHECK_TEXT(*bed.editor, u8"    // a;\n    //     b;\n\n    // c;");
    bed.Key(KeyCode::Slash, KeyModCtrl);
    CHECK_TEXT(*bed.editor, u8"    a;\n        b;\n\n    c;");

    Bed markup("xml", u8"  <Panel/>");
    markup.editor->SetCaret(At(0, 3));
    markup.Key(KeyCode::Slash, KeyModCtrl);
    CHECK_TEXT(*markup.editor, u8"  <!-- <Panel/> -->");
    markup.Key(KeyCode::Slash, KeyModCtrl);
    CHECK_TEXT(*markup.editor, u8"  <Panel/>");
}

TEST_CASE("code editing: Tab and Shift+Tab indent a selection's lines; Alt+Up and Down move them; Shift+Alt+Down copies; Ctrl+Shift+K deletes")
{
    Bed bed("angelscript", u8"a\nb\nc\nd");
    const CodeSelection two{At(1, 0), At(2, 1)};
    bed.editor->SetSelections(core::Span<const CodeSelection>(&two, 1));
    bed.Key(KeyCode::Tab);
    CHECK_TEXT(*bed.editor, u8"a\n    b\n    c\nd");
    bed.Key(KeyCode::Tab, KeyModShift);
    CHECK_TEXT(*bed.editor, u8"a\nb\nc\nd");
    bed.Key(KeyCode::Up, KeyModAlt);
    CHECK_TEXT(*bed.editor, u8"b\nc\na\nd");
    CHECK(bed.editor->GetPrimary().Range() == CodeRange{At(0, 0), At(1, 1)});
    bed.Key(KeyCode::Down, KeyModAlt);
    bed.Key(KeyCode::Down, KeyModAlt);
    CHECK_TEXT(*bed.editor, u8"a\nd\nb\nc");
    bed.Key(KeyCode::Up, KeyModAlt); // back: a b c d with b, c selected
    bed.editor->SetCaret(At(0, 0));
    bed.Key(KeyCode::Down, KeyModShift | KeyModAlt);
    CHECK_TEXT(*bed.editor, u8"a\na\nb\nc\nd");
    CHECK(bed.Caret() == At(1, 0)); // with the copy
    bed.Key(KeyCode::K, KeyModCtrl | KeyModShift);
    CHECK_TEXT(*bed.editor, u8"a\nb\nc\nd");
}

TEST_CASE("code editing: Ctrl+D selects the word, then adds the next match round to the start; Ctrl+Shift+L all; Ctrl+Alt+Down a caret below")
{
    Bed bed("angelscript", u8"int x = x + 1;\nx++;");
    bed.editor->SetCaret(At(0, 4));
    bed.Key(KeyCode::D, KeyModCtrl);
    CHECK(bed.editor->GetPrimary().Range() == CodeRange{At(0, 4), At(0, 5)});
    bed.Key(KeyCode::D, KeyModCtrl);
    REQUIRE(bed.editor->GetSelections().Size() == 2);
    CHECK(bed.editor->GetSelections()[1].Range() == CodeRange{At(0, 8), At(0, 9)});
    bed.Key(KeyCode::D, KeyModCtrl);
    bed.Key(KeyCode::D, KeyModCtrl); // none further
    CHECK(bed.editor->GetSelections().Size() == 3);
    bed.Type(u8"y");
    CHECK_TEXT(*bed.editor, u8"int y = y + 1;\ny++;");
    bed.editor->SetCaret(At(1, 0));
    bed.Key(KeyCode::L, KeyModCtrl | KeyModShift);
    CHECK(bed.editor->GetSelections().Size() == 3);
    bed.editor->SetCaret(At(0, 3));
    bed.Key(KeyCode::Down, KeyModCtrl | KeyModAlt);
    REQUIRE(bed.editor->GetSelections().Size() == 2);
    CHECK(bed.editor->GetSelections()[1].Head == At(1, 3));
}

TEST_CASE("code editing: Alt+drag across lines selects a column")
{
    Bed bed("angelscript", u8"alpha\nbeta\ngamma\ndelta");
    const auto over = [&bed](CodePosition at)
    {
        const Rect caret = bed.editor->CaretRect(at);
        return core::Float2{caret.x + 1.0f, caret.y + caret.height * 0.5f};
    };
    const core::Float2 from = over(At(0, 1));
    const core::Float2 to = over(At(2, 3));
    bed.D().InjectMouseMove(from, KeyModAlt);
    bed.D().InjectMouseDown(from, MouseButton::Left, KeyModAlt);
    bed.D().InjectMouseMove(to, KeyModAlt);
    bed.D().InjectMouseUp(to, MouseButton::Left, KeyModAlt);
    REQUIRE(bed.editor->GetSelections().Size() == 3);
    CHECK(bed.editor->GetSelections()[0].Range() == CodeRange{At(0, 1), At(0, 3)});
    CHECK(bed.editor->GetSelections()[1].Range() == CodeRange{At(1, 1), At(1, 3)});
    CHECK(bed.editor->GetSelections()[2].Range() == CodeRange{At(2, 1), At(2, 3)});
}

TEST_CASE("code editing: a bracket's match, across lines, past brackets in strings and comments")
{
    Bed bed("angelscript", u8"void f() {\n    s = \"}\"; // }\n    if (a) { b(); }\n}");
    CodeRange bracket, match;
    REQUIRE(bed.editor->FindMatchingBracket(At(0, 9), bracket, match));
    CHECK(bracket == CodeRange{At(0, 9), At(0, 10)});
    CHECK(match == CodeRange{At(3, 0), At(3, 1)});
    REQUIRE(bed.editor->FindMatchingBracket(At(3, 1), bracket, match)); // the one before the caret
    CHECK(match.Start == At(0, 9));
    REQUIRE(bed.editor->FindMatchingBracket(At(2, 7), bracket, match));
    CHECK(match == CodeRange{At(2, 9), At(2, 10)});
    CHECK_FALSE(bed.editor->FindMatchingBracket(At(1, 6), bracket, match)); // the string's
}

TEST_CASE("code document: search by case and whole word, across lines, round to the start")
{
    CodeDocument doc(core::DefaultAllocator());
    doc.SetText(SV(u8"Value value\nvalues end\nx"));
    CodeRange found;
    REQUIRE(doc.Find(SV(u8"value"), At(0, 0), false, false, false, found));
    CHECK(found == CodeRange{At(0, 0), At(0, 5)});
    REQUIRE(doc.Find(SV(u8"value"), At(0, 0), true, false, false, found));
    CHECK(found == CodeRange{At(0, 6), At(0, 11)});
    REQUIRE(doc.Find(SV(u8"value"), At(0, 7), true, true, false, found) == false);
    REQUIRE(doc.Find(SV(u8"value"), At(0, 7), true, false, false, found));
    CHECK(found.Start == At(1, 0)); // in "values"
    REQUIRE(doc.Find(SV(u8"end\nx"), At(0, 0), true, false, false, found));
    CHECK(found == CodeRange{At(1, 7), At(2, 1)});
    REQUIRE(doc.Find(SV(u8"Value"), At(1, 0), true, false, true, found));
    CHECK(found.Start == At(0, 0)); // round to the start
    CHECK_FALSE(doc.Find(SV(u8"Value"), At(1, 0), true, false, false, found));
}

TEST_CASE("code find: Ctrl+F opens the bar with the selection's text; F3 and Shift+F3 go round the matches, counted")
{
    Bed bed("angelscript", u8"int count = 0;\ncount += 1; // Count\nreturn count;");
    const CodeSelection word{At(0, 4), At(0, 9)};
    bed.editor->SetSelections(core::Span<const CodeSelection>(&word, 1));
    bed.Key(KeyCode::F, KeyModCtrl);
    CodeFindBar& bar = bed.editor->GetFindBar();
    REQUIRE(bar.IsDisplayed());
    CHECK(bar.GetQuery() == SV(u8"count"));
    CHECK(bar.GetQueryField().IsFocused());
    bed.Frame();
    CHECK(bed.editor->GetMatches().Size() == 4); // "Count" too, case folded
    CHECK(bed.editor->CurrentMatch() == 1);
    CHECK(bar.GetCountLabel().GetText() == SV(u8"1 of 4"));
    bed.Key(KeyCode::F3);
    CHECK(bed.editor->GetPrimary().Range() == CodeRange{At(1, 0), At(1, 5)});
    CHECK(bar.GetCountLabel().GetText() == SV(u8"2 of 4"));
    bed.Key(KeyCode::F3, KeyModShift);
    bed.Key(KeyCode::F3, KeyModShift); // round to the last
    CHECK(bed.editor->GetPrimary().Range() == CodeRange{At(2, 7), At(2, 12)});
    // Matching case: "Count" goes; whole words.
    (void)bar.GetCaseToggle().HandleActivate();
    CHECK(bed.editor->GetMatches().Size() == 3);
    bar.GetQueryField().SetText(SV(u8"coun"));
    CHECK(bed.editor->GetMatches().Size() == 3);
    (void)bar.GetWordToggle().HandleActivate();
    CHECK(bed.editor->GetMatches().Size() == 0);
    CHECK(bar.GetCountLabel().GetText() == SV(u8"No results"));
    // Return in the field finds the next; Escape closes, the focus back in the editor.
    (void)bar.GetWordToggle().HandleActivate();
    bed.Key(KeyCode::Return);
    CHECK(bed.editor->CurrentMatch() > 0);
    bed.Key(KeyCode::Escape);
    CHECK_FALSE(bar.IsDisplayed());
    CHECK(bed.editor->IsFocused());
}

TEST_CASE("code find: Ctrl+H replaces this match and goes on; All replaces every one as one undo step")
{
    Bed bed("angelscript", u8"a = old; b = old; c = old;");
    bed.editor->SetCaret(At(0, 0));
    bed.Key(KeyCode::H, KeyModCtrl);
    CodeFindBar& bar = bed.editor->GetFindBar();
    REQUIRE(bar.GetMode() == CodeFindBar::Mode::Replace);
    bar.GetQueryField().SetText(SV(u8"old"));
    bar.GetReplacementField().SetText(SV(u8"new"));
    bed.editor->ReplaceCurrent(); // on no match yet: finds the first
    CHECK(bed.editor->CurrentMatch() == 1);
    bed.editor->ReplaceCurrent();
    CHECK_TEXT(*bed.editor, u8"a = new; b = old; c = old;");
    CHECK(bed.editor->CurrentMatch() == 1); // the next, now the first left
    const usize steps = bed.editor->GetDocument().UndoCount();
    bed.editor->ReplaceAll();
    CHECK_TEXT(*bed.editor, u8"a = new; b = new; c = new;");
    CHECK(bed.editor->GetDocument().UndoCount() == steps + 1);
    CHECK(bar.GetCountLabel().GetText() == SV(u8"No results"));
}

TEST_CASE("code find: Ctrl+G goes to a line, or a line and column; the bar keeps its place as the code scrolls")
{
    core::String text;
    for (int i = 0; i < 80; ++i)
        text.Append(core::Format(u8"line {}\n", i).AsView());
    Bed bed("angelscript", reinterpret_cast<const char8_t*>(text.CStr()));
    bed.Key(KeyCode::G, KeyModCtrl);
    CodeFindBar& bar = bed.editor->GetFindBar();
    REQUIRE(bar.GetMode() == CodeFindBar::Mode::GoToLine);
    CHECK(bar.GetLineField().GetText() == SV(u8"1"));
    bar.GetLineField().GetModel().SelectAll();
    bed.D().InjectText(SV(u8"60:3"));
    bed.Key(KeyCode::Return);
    CHECK(bed.Caret() == At(59, 2));
    CHECK_FALSE(bar.IsDisplayed());
    CHECK(bed.editor->IsFocused());
    bed.Frame();
    CHECK(bed.editor->GetScrollOffset().y > 0.0f);
    // Open again, scrolled: still at the top of the editor's box.
    bed.Key(KeyCode::F, KeyModCtrl);
    bed.Frame();
    CHECK(bar.GetScreenBounds().y == doctest::Approx(bed.editor->GetScreenBounds().y + bed.editor->GetContentBounds().y + 2.0f).epsilon(0.01));
}
