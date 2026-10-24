// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Code - folding and soft wrap (C7 of Specs/gui-lab-evolution-3.md), with the sandbox's
// definitions: ranges from brackets past strings, by indentation where the language folds so, from
// regions, or the host's; a folded range's lines hide, one row in the map the carets and the scroll
// share; folding moves carets out, and a caret going in unfolds; folds go with their lines through
// edits and go when their bracket does; the gutter's chevron and the placeholder; VS Code's keys.
// Wrapping, a long line's rows join the same map, so Down, the pointer and folds go by them.
// Whitespace drawn by VS Code's choices.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
#include <fstream>
#include <sstream>
#include <string>
import foundation.core;
import foundation.fonts;
import foundation.vg;
import foundation.xml;
import foundation.xml.serialization;
import foundation.gui;
import foundation.gui.code;

using namespace foundation::gui;
namespace core = foundation::core;
namespace fonts = foundation::fonts;
namespace xml = foundation::xml;
namespace vg = foundation::vg;
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


namespace
{
    constexpr const char8_t* kScript = u8"void f()\n{\n    if (x)\n    {\n        y();\n    }\n    string s = \"{\";\n}\nint z;";

    bool HasRange(const CodeEditor& editor, u32 first, u32 last)
    {
        for (const CodeFoldRange& r : editor.GetFoldRanges())
            if (r.First == first && r.Last == last)
                return true;
        return false;
    }
    void Click(Bed& bed, core::Float2 local)
    {
        const core::Float2 at = bed.editor->ConvertToRootSpace(local);
        bed.D().InjectMouseDown(at, MouseButton::Left);
        bed.D().InjectMouseUp(at, MouseButton::Left);
    }
}

TEST_CASE("code folding: ranges from brackets, a close first on its line left out, past strings")
{
    Bed bed("angelscript", kScript);
    REQUIRE(bed.editor->GetFoldRanges().Size() == 2u);
    CHECK(HasRange(*bed.editor, 1, 6)); // the body, its close's line shown
    CHECK(HasRange(*bed.editor, 3, 4));
}

TEST_CASE("code folding: by indentation where the language says, trailing blank lines left out, and regions")
{
    Bed bed("luau", u8"function f()\n  if x then\n    y()\n  end\n\nend\n--#region setup\nlocal z = 1\n--#endregion");
    CHECK(HasRange(*bed.editor, 0, 3));
    CHECK(HasRange(*bed.editor, 1, 2));
    CHECK(HasRange(*bed.editor, 6, 8)); // through its end's line
    CHECK(bed.editor->GetFoldRanges().Size() == 3u);
    Bed hlsl("hlsl", u8"#pragma region lights\nfloat3 a;\n#pragma endregion");
    CHECK(HasRange(*hlsl.editor, 0, 2));
}

TEST_CASE("code folding: a folded range's lines hide; the rows close up under it; Down steps over it")
{
    Bed bed("angelscript", kScript);
    CHECK(bed.editor->RowCount() == 9u);
    REQUIRE(bed.editor->Fold(1));
    CHECK(bed.editor->IsFolded(1));
    CHECK(bed.editor->RowCount() == 4u); // 2 to 6 hidden
    CHECK(bed.editor->IsLineHidden(2));
    CHECK(bed.editor->IsLineHidden(6));
    CHECK_FALSE(bed.editor->IsLineHidden(7));
    const f32 lh = bed.editor->LineHeight();
    CHECK(bed.editor->CaretRect(At(7, 0)).y - bed.editor->CaretRect(At(0, 0)).y == doctest::Approx(lh * 2.0f));
    bed.editor->SetCaret(At(1, 1));
    bed.Key(KeyCode::Down);
    CHECK(bed.Caret().Line == 7u);
    bed.Key(KeyCode::Up);
    CHECK(bed.Caret().Line == 1u);
    // The line under a point below the fold is the one after it.
    bed.Frame();
    const Rect row = bed.editor->CaretRect(At(7, 0));
    CHECK(bed.editor->PositionAt(core::Float2{bed.editor->TextLeft() + 1.0f, row.y + lh * 0.5f}).Line == 7u);
}

TEST_CASE("code folding: Ctrl+Shift+[ folds the innermost range open at the caret, moving it out; ] unfolds; a caret going in unfolds")
{
    Bed bed("angelscript", kScript);
    bed.editor->SetCaret(At(4, 3));
    bed.Key(KeyCode::LeftBracket, KeyModCtrl | KeyModShift);
    CHECK(bed.editor->IsFolded(3));
    CHECK(bed.Caret() == At(3, 5)); // the end of the line it folds onto
    bed.Key(KeyCode::LeftBracket, KeyModCtrl | KeyModShift);
    CHECK(bed.editor->IsFolded(1)); // the next one out
    CHECK(bed.Caret() == At(1, 1));
    bed.Key(KeyCode::RightBracket, KeyModCtrl | KeyModShift);
    CHECK_FALSE(bed.editor->IsFolded(1));
    CHECK(bed.editor->IsFolded(3)); // only what held the caret
    bed.editor->SetCaret(At(4, 0)); // a match found, a line gone to
    CHECK_FALSE(bed.editor->IsFolded(3));
    CHECK(bed.Caret() == At(4, 0));
}

TEST_CASE("code folding: folds go with their lines through edits, and go when their bracket does")
{
    Bed bed("angelscript", kScript);
    REQUIRE(bed.editor->Fold(3));
    bed.editor->SetCaret(At(0, 0));
    bed.Type(u8"\n");
    CHECK(bed.editor->IsFolded(4));
    CHECK_FALSE(bed.editor->IsFolded(3));
    // The open bracket deleted: no range, no fold.
    const CodeSelection brace{At(4, 4), At(4, 5)};
    bed.editor->SetSelections(core::Span<const CodeSelection>(&brace, 1));
    bed.Key(KeyCode::Delete);
    CHECK_FALSE(bed.editor->IsFolded(4));
    CHECK_FALSE(bed.editor->IsLineHidden(5));
}

TEST_CASE("code folding: the gutter's chevron folds and unfolds; the placeholder unfolds")
{
    Bed bed("angelscript", kScript);
    const f32 lh = bed.editor->LineHeight();
    const f32 chevron = bed.editor->TextLeft() - 15.0f; // the fold column, before the text's gap
    Click(bed, core::Float2{chevron, bed.editor->CaretRect(At(1, 0)).y + lh * 0.5f});
    CHECK(bed.editor->IsFolded(1));
    Click(bed, core::Float2{chevron, bed.editor->CaretRect(At(1, 0)).y + lh * 0.5f});
    CHECK_FALSE(bed.editor->IsFolded(1));
    Click(bed, core::Float2{chevron, bed.editor->CaretRect(At(0, 0)).y + lh * 0.5f}); // no range there
    CHECK(bed.editor->GetFoldRanges().Size() == 2u);
    REQUIRE(bed.editor->Fold(1));
    const Rect end = bed.editor->CaretRect(At(1, 1));
    Click(bed, core::Float2{end.x + 12.0f, end.y + lh * 0.5f}); // on the dots after the brace
    CHECK_FALSE(bed.editor->IsFolded(1));
}

TEST_CASE("code folding: Ctrl+K Ctrl+0 folds everything, Ctrl+K Ctrl+J unfolds everything")
{
    Bed bed("angelscript", kScript);
    bed.editor->SetCaret(At(4, 0));
    bed.Key(KeyCode::K, KeyModCtrl);
    bed.Key(KeyCode::Num0, KeyModCtrl);
    CHECK(bed.editor->IsFolded(1));
    CHECK(bed.editor->IsFolded(3));
    CHECK(bed.Caret() == At(1, 1)); // out of them all
    CHECK(bed.editor->RowCount() == 4u);
    bed.Key(KeyCode::K, KeyModCtrl);
    bed.Key(KeyCode::J, KeyModCtrl);
    CHECK_FALSE(bed.editor->IsFolded(1));
    CHECK_FALSE(bed.editor->IsFolded(3));
    CHECK(bed.editor->RowCount() == 9u);
}

TEST_CASE("code folding: the host's ranges in place of the language's, carried through edits")
{
    Bed bed("angelscript", kScript);
    const CodeFoldRange mine{0, 2};
    bed.editor->SetFoldRanges(core::Span<const CodeFoldRange>(&mine, 1));
    REQUIRE(bed.editor->GetFoldRanges().Size() == 1u);
    CHECK(HasRange(*bed.editor, 0, 2));
    bed.editor->SetCaret(At(0, 0));
    bed.Type(u8"\n");
    CHECK(HasRange(*bed.editor, 1, 3));
    bed.editor->UseLanguageFolds();
    CHECK(HasRange(*bed.editor, 2, 7));
}

TEST_CASE("code soft wrap: a long line's rows are rows of the map; Down goes by them; nothing scrolls across")
{
    core::String words;
    for (int i = 0; i < 30; ++i)
        words.Append(SV(u8"abcd "));
    words.Append(SV(u8"\nend"));
    Bed bed("angelscript");
    bed.editor->SetText(words.AsView());
    bed.Frame();
    CHECK(bed.editor->RowCount() == 2u);
    bed.Key(KeyCode::Z, KeyModAlt);
    REQUIRE(bed.editor->GetSoftWrap());
    bed.Frame();
    const u32 rows = bed.editor->RowCount() - 1; // the long line's
    CHECK(rows >= 3u);
    const f32 lh = bed.editor->LineHeight();
    const Rect top = bed.editor->CaretRect(At(0, 0));
    CHECK(bed.editor->CaretRect(At(1, 0)).y - top.y == doctest::Approx(lh * static_cast<f32>(rows)));
    // Down from near the start: the line's second row, as far across.
    bed.editor->SetCaret(At(0, 2));
    bed.Key(KeyCode::Down);
    CHECK(bed.Caret().Line == 0u);
    const Rect second = bed.editor->CaretRect(bed.Caret());
    CHECK(second.y - top.y == doctest::Approx(lh));
    CHECK(second.x == doctest::Approx(bed.editor->CaretRect(At(0, 2)).x).epsilon(0.03));
    // The pointer on the second row finds the line's place there.
    const CodePosition hit = bed.editor->PositionAt(core::Float2{bed.editor->TextLeft() + 1.0f, top.y + lh * 1.5f});
    CHECK(hit.Line == 0u);
    CHECK(hit.Column > 0u);
    CHECK(bed.editor->CaretRect(hit).y - top.y == doctest::Approx(lh));
    bed.Key(KeyCode::End);
    bed.Frame();
    CHECK(bed.editor->GetScrollOffset().x == doctest::Approx(0.0f)); // never across
    // Narrower: more rows.
    bed.editor->EditLayoutStyle([](LayoutStyle& s) { s.Width = LayoutLength::Px(200.0f); });
    bed.Frame();
    CHECK(bed.editor->RowCount() - 1 > rows);
}

TEST_CASE("code soft wrap: a word longer than a row breaks; a fold hides every row of what it holds")
{
    core::String text(SV(u8"{\n"));
    for (int i = 0; i < 100; ++i)
        text.Append(SV(u8"x"));
    text.Append(SV(u8"\n}"));
    Bed bed("angelscript");
    bed.editor->SetText(text.AsView());
    bed.editor->SetSoftWrap(true);
    bed.Frame();
    CHECK(bed.editor->RowCount() == 4u); // the hundred in two rows
    REQUIRE(bed.editor->Fold(0));
    CHECK(bed.editor->RowCount() == 2u);
    bed.editor->SetSoftWrap(false);
    bed.Frame();
    CHECK(bed.editor->RowCount() == 2u);
    bed.editor->UnfoldAll();
    CHECK(bed.editor->RowCount() == 3u);
}

TEST_CASE("code whitespace: drawn by the choice: all, a line's end, all but a single space between words, the selections'")
{
    Bed bed("angelscript", u8"  a b  c\t\nx y  ");
    const auto shows = [&](u32 line, u32 column) { return bed.editor->ShowsWhitespaceAt(At(line, column)); };
    CHECK_FALSE(shows(0, 0)); // none by default
    bed.editor->SetShowWhitespace(CodeWhitespace::All);
    CHECK(shows(0, 0));
    CHECK(shows(0, 3));
    CHECK(shows(0, 8)); // the tab
    CHECK_FALSE(shows(0, 2)); // a letter
    bed.editor->SetShowWhitespace(CodeWhitespace::Trailing);
    CHECK(shows(1, 3));
    CHECK(shows(1, 4));
    CHECK_FALSE(shows(1, 1));
    CHECK(shows(0, 8));
    CHECK_FALSE(shows(0, 5));
    bed.editor->SetShowWhitespace(CodeWhitespace::Boundary);
    CHECK(shows(0, 0)); // the indent
    CHECK(shows(0, 1));
    CHECK_FALSE(shows(0, 3)); // one between words
    CHECK(shows(0, 5)); // a run
    CHECK(shows(0, 6));
    CHECK(shows(0, 8));
    bed.editor->SetShowWhitespace(CodeWhitespace::Selection);
    const CodeSelection some{At(0, 0), At(0, 4)};
    bed.editor->SetSelections(core::Span<const CodeSelection>(&some, 1));
    CHECK(shows(0, 1));
    CHECK(shows(0, 3));
    CHECK_FALSE(shows(0, 5));
}

TEST_CASE("code view: draws wrapped, folded, with its whitespace, a selection across rows and the chevrons")
{
    core::String text(SV(u8"void f()\n{\n\tint a = 1;   \n"));
    for (int i = 0; i < 40; ++i)
        text.Append(SV(u8"word "));
    text.Append(SV(u8"\n}\n"));
    Bed bed("angelscript");
    bed.editor->SetText(text.AsView());
    bed.editor->SetSoftWrap(true);
    bed.editor->SetShowWhitespace(CodeWhitespace::All);
    bed.Frame();
    const CodeSelection across{At(2, 2), At(3, 120)};
    bed.editor->SetSelections(core::Span<const CodeSelection>(&across, 1));
    bed.D().InjectMouseMove(bed.editor->ConvertToRootSpace(core::Float2{2.0f, 20.0f})); // the gutter: chevrons
    bed.Frame();
    vg::VGContext canvas;
    {
        DrawContext ctx{canvas};
        bed.root->Draw(ctx);
    }
    REQUIRE(bed.editor->Fold(1));
    bed.editor->SetCaret(At(0, 4));
    bed.Frame();
    {
        DrawContext ctx{canvas};
        bed.root->Draw(ctx);
    }
    CHECK(bed.editor->RowCount() == 4u); // the function's line, the brace's, the close's, the end
}
