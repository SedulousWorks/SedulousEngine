// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Code - the language service (C6 of Specs/gui-lab-evolution-3.md), with a service of the
// test's own over the sandbox's AngelScript: the fuzzy match and its order; a name typed opens the
// list, more letters filter it, Up and Down go round it, Return and Tab put the pick in place of the
// word at each caret as one undo step, Escape or the caret leaving the word closes it; a trigger
// opens it on no word; not by typing in a comment, though Ctrl+Space opens it there; a click picks
// a row, the focus kept in the editor; the list sits below the word, its label lined up with it;
// the service's word under the pointer joins the tooltip.
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

    // A script's few names; what it was last asked.
    class Service : public ICodeLanguageService
    {
    public:
        CodeCompletionRequest Last;
        int Asked = 0;
        core::StringView CompletionTriggers() const override { return SV(u8"."); }
        void Complete(const CodeDocument&, const CodeCompletionRequest& request, core::Array<CodeCompletionItem>& out) override
        {
            Last = request;
            ++Asked;
            const auto add = [&out](const char8_t* label, CodeCompletionKind kind, const char8_t* detail)
            {
                CodeCompletionItem item;
                item.Label = core::String(SV(label));
                item.Kind = kind;
                item.Detail = core::String(SV(detail));
                out.PushBack(core::Move(item));
            };
            add(u8"position", CodeCompletionKind::Property, u8"Float3");
            add(u8"print", CodeCompletionKind::Function, u8"void print(const string &in)");
            add(u8"pow", CodeCompletionKind::Function, u8"float pow(float, float)");
            add(u8"Player", CodeCompletionKind::Type, u8"class");
        }
        int Hovered = 0;
        bool Hover(const CodeDocument& document, CodePosition at, core::String& out) override
        {
            ++Hovered;
            const core::StringView line = document.LineText(at.Line);
            if (at.Column > 8 || line.Size() < 8 || line.SubStr(0, 8) != SV(u8"position"))
                return false;
            out = core::String(SV(u8"Float3 position"));
            return true;
        }
    };

    struct CompletionBed : Bed
    {
        Service service;
        explicit CompletionBed(const char8_t* text = u8"") : Bed("angelscript", text) { editor->SetLanguageService(&service); }
        [[nodiscard]] CodeCompletionList& List() const { return editor->GetCompletionList(); }
        [[nodiscard]] core::StringView Shown(usize i) const { return List().ShownItem(i).Label.AsView(); }
        [[nodiscard]] core::StringView Selected() const
        {
            const CodeCompletionItem* item = List().SelectedItem();
            return item != nullptr ? item->Label.AsView() : core::StringView{};
        }
    };
}

TEST_CASE("code completion: the fuzzy match takes the letters in order, from a word's start, scoring the start, runs and case")
{
    core::Array<u32> at(core::DefaultAllocator());
    CHECK(CodeFuzzyMatch(SV(u8"gpos"), SV(u8"GetPosition"), &at) >= 0);
    REQUIRE(at.Size() == 4u);
    CHECK(at[0] == 0u);
    CHECK(at[1] == 3u); // the P of Position, a word's start
    CHECK(at[3] == 5u);
    CHECK(CodeFuzzyMatch(SV(u8"xyz"), SV(u8"GetPosition")) < 0);
    CHECK(CodeFuzzyMatch(SV(u8"et"), SV(u8"GetPosition")) < 0); // its first letter inside a word
    CHECK(CodeFuzzyMatch(SV(u8"pos"), SV(u8"get_position")) >= 0); // after an underscore
    CHECK(CodeFuzzyMatch(SV(u8"pos"), SV(u8"position")) > CodeFuzzyMatch(SV(u8"pos"), SV(u8"getPosition")));
    CHECK(CodeFuzzyMatch(SV(u8"pos"), SV(u8"position")) > CodeFuzzyMatch(SV(u8"pos"), SV(u8"pOrderSet")));
    CHECK(CodeFuzzyMatch(SV(u8"Pos"), SV(u8"Position")) > CodeFuzzyMatch(SV(u8"Pos"), SV(u8"position")));
    CHECK(CodeFuzzyMatch(SV(u8""), SV(u8"anything")) == 0);
}

TEST_CASE("code completion: a name typed opens the list; more letters filter it; Up and Down go round; Return puts the pick in, one undo step")
{
    CompletionBed bed;
    bed.Type(u8"p");
    REQUIRE(bed.editor->IsCompleting());
    CHECK(bed.service.Asked == 1);
    CHECK(bed.service.Last.WordStart == At(0, 0));
    CHECK_FALSE(bed.service.Last.Invoked);
    CHECK(bed.List().ShownCount() == 4u); // Player's P too, case aside
    bed.Type(u8"o");
    CHECK(bed.service.Asked == 1); // filtered, not asked again
    REQUIRE(bed.List().ShownCount() == 2u);
    CHECK(bed.Shown(0) == SV(u8"pow")); // as good a match, and shorter
    CHECK(bed.Shown(1) == SV(u8"position"));
    CHECK(bed.Selected() == SV(u8"pow"));
    bed.Key(KeyCode::Down);
    CHECK(bed.Selected() == SV(u8"position"));
    CHECK(bed.Caret() == At(0, 2)); // the caret stays
    bed.Key(KeyCode::Down);
    CHECK(bed.Selected() == SV(u8"pow")); // round
    bed.Key(KeyCode::Up);
    CHECK(bed.Selected() == SV(u8"position"));
    bed.Key(KeyCode::Return);
    CHECK_TEXT(*bed.editor, u8"position");
    CHECK(bed.Caret() == At(0, 8));
    CHECK_FALSE(bed.editor->IsCompleting());
    bed.Key(KeyCode::Return); // the editor's own again
    CHECK_TEXT(*bed.editor, u8"position\n");
    bed.Key(KeyCode::Z, KeyModCtrl);
    bed.Key(KeyCode::Z, KeyModCtrl);
    CHECK_TEXT(*bed.editor, u8"po"); // the pick, one step
}

TEST_CASE("code completion: Escape, the caret leaving the word, or no match closes it; a number never opens it")
{
    CompletionBed bed(u8"x = ");
    bed.editor->SetCaret(At(0, 4));
    bed.Type(u8"pr");
    REQUIRE(bed.editor->IsCompleting());
    bed.Key(KeyCode::Escape);
    CHECK_FALSE(bed.editor->IsCompleting());
    CHECK_TEXT(*bed.editor, u8"x = pr");
    bed.editor->SetCaret(At(0, 6));
    CHECK(bed.editor->TriggerCompletion(true));
    bed.Key(KeyCode::Left);
    CHECK(bed.editor->IsCompleting()); // still in the word: "p"
    bed.Key(KeyCode::Left);
    CHECK_FALSE(bed.editor->IsCompleting()); // before it
    bed.editor->SetCaret(At(0, 6));
    bed.Type(u8"i");
    REQUIRE(bed.editor->IsCompleting());
    bed.Type(u8"q");
    CHECK_FALSE(bed.editor->IsCompleting()); // "priq" matches nothing
    bed.editor->SetText(SV(u8""));
    bed.Type(u8"1");
    CHECK_FALSE(bed.editor->IsCompleting());
}

TEST_CASE("code completion: a trigger opens it on no word, in the service's order; typing in a comment does not, Ctrl+Space does")
{
    CompletionBed bed;
    bed.Type(u8"a.");
    REQUIRE(bed.editor->IsCompleting());
    CHECK(bed.service.Last.Trigger == u8'.');
    CHECK(bed.service.Last.WordStart == At(0, 2));
    REQUIRE(bed.List().ShownCount() == 4u);
    CHECK(bed.Shown(0) == SV(u8"position"));
    CHECK(bed.Shown(3) == SV(u8"Player"));
    bed.Key(KeyCode::Escape);
    bed.editor->SetText(SV(u8"// "));
    bed.editor->SetCaret(At(0, 3));
    bed.Type(u8"po");
    CHECK_FALSE(bed.editor->IsCompleting());
    bed.Key(KeyCode::Space, KeyModCtrl);
    CHECK(bed.editor->IsCompleting());
    CHECK(bed.service.Last.Invoked);
}

TEST_CASE("code completion: Tab accepts too, at every caret on the same word")
{
    CompletionBed bed(u8"a\nb");
    bed.editor->SetCaret(At(0, 1));
    bed.editor->AddCaret(At(1, 1));
    bed.Type(u8" pri");
    REQUIRE(bed.editor->IsCompleting());
    CHECK(bed.Selected() == SV(u8"print"));
    bed.Key(KeyCode::Tab);
    CHECK_TEXT(*bed.editor, u8"a print\nb print");
    CHECK_FALSE(bed.editor->IsCompleting());
}

TEST_CASE("code completion: the list sits below the word, its label lined up; a click picks a row and the editor keeps the focus")
{
    CompletionBed bed(u8"  ");
    bed.editor->SetCaret(At(0, 2));
    bed.Type(u8"p");
    REQUIRE(bed.editor->IsCompleting());
    bed.Frame();
    CodeCompletionList& list = bed.List();
    REQUIRE(bed.D().IsPopupOpen(list));
    const Rect word = bed.editor->CaretRect(At(0, 2));
    const core::Float2 wordAt = bed.editor->ConvertToRootSpace(core::Float2{word.x, word.y + word.height});
    const core::Float2 listAt = list.ConvertToRootSpace(core::Float2{0.0f, 0.0f});
    CHECK(listAt.x + list.LabelInset() == doctest::Approx(wordAt.x));
    CHECK(listAt.y >= wordAt.y);
    // The second row: print.
    const f32 y = listAt.y + list.GetContentBounds().y + list.RowHeight() * 1.5f;
    bed.D().InjectMouseDown(core::Float2{listAt.x + 20.0f, y}, MouseButton::Left);
    bed.D().InjectMouseUp(core::Float2{listAt.x + 20.0f, y}, MouseButton::Left);
    CHECK_TEXT(*bed.editor, u8"  print");
    CHECK_FALSE(bed.editor->IsCompleting());
    CHECK(bed.editor->IsFocused());
    // A press in the code closes it, and places the caret as ever.
    bed.Type(u8"\np");
    REQUIRE(bed.editor->IsCompleting());
    bed.D().InjectMouseDown(bed.editor->ConvertToRootSpace(core::Float2{bed.editor->TextLeft() + 1.0f, bed.editor->CaretRect(At(0, 0)).y + 2.0f}), MouseButton::Left);
    CHECK_FALSE(bed.editor->IsCompleting());
    CHECK(bed.Caret() == At(0, 0));
}

TEST_CASE("code completion: what the service says of the word under the pointer joins its tooltip, asked once per word")
{
    CompletionBed bed(u8"position = 1;");
    const auto over = [&](u32 column)
    {
        const Rect caret = bed.editor->CaretRect(At(0, column));
        bed.D().InjectMouseMove(bed.editor->ConvertToRootSpace(core::Float2{caret.x + 3.0f, caret.y + 4.0f}));
    };
    over(2);
    CHECK(bed.editor->GetTooltipText() == SV(u8"Float3 position"));
    over(4);
    CHECK(bed.editor->GetTooltipText() == SV(u8"Float3 position"));
    CHECK(bed.service.Hovered == 1); // the same word
    over(12); // the semicolon: no word
    CHECK(bed.editor->GetTooltipText().Size() == 0u);
    const Rect end = bed.editor->CaretRect(At(0, 13));
    bed.D().InjectMouseMove(bed.editor->ConvertToRootSpace(core::Float2{end.x + 60.0f, end.y + 4.0f}));
    CHECK(bed.editor->GetTooltipText().Size() == 0u); // past the line's end
}
