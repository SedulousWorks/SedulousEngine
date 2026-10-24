// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUISandbox - the Code page (C8 of Specs/gui-lab-evolution-3.md): GUI.Code's editor as a host
// uses it. A script in the sandbox's own AngelScript, checked by the engine's compiler a moment
// after each edit without running it (IScriptManager::Check), its errors the editor's diagnostics;
// a click in the gutter sets a breakpoint; completion and hover from the surface the script
// backend bound (DescribeBoundApi) and the language's words; and a shader beside it. The
// languages are the sandbox's (Data/Assets/ui/sandbox/code), read through the XML serialization.

module;
#include "Core/Prelude.h"

export module gui.sandbox.code;

import foundation.core;
import foundation.xml;
import foundation.xml.serialization;
import foundation.script;
import foundation.gui;
import foundation.gui.code;

using namespace foundation::core;
namespace core = foundation::core;
namespace xml = foundation::xml;
namespace script = foundation::script;
namespace gui = foundation::gui;

export namespace sandbox
{
    /// Outlives the page's editors (the host keeps it before the GUI), so it never reaches into
    /// them as it goes: its change listener goes with the script's document.
    class CodePage final : public gui::ICodeLanguageService
    {
    public:
        /// How long the script rests after an edit before it is checked, in seconds.
        static constexpr f32 kCheckDelay = 0.3f;

        CodePage(IAllocator& allocator, script::IScriptManager* scripts) : m_allocator(allocator), m_scripts(scripts)
        {
            if (m_scripts != nullptr)
                m_api = m_scripts->DescribeBoundApi();
        }

        /// Reads a language definition (the XML of one of Data/Assets/ui/sandbox/code's files).
        [[nodiscard]] bool ReadLanguage(StringView text, gui::CodeLanguage& out)
        {
            xml::XmlDocument doc(m_allocator);
            if (doc.Parse(text) != xml::XmlResult::Ok)
                return false;
            xml::XmlSerializer reader(doc);
            gui::Serialize(reader, out);
            return reader.IsOk() && !out.Contexts.IsEmpty();
        }

        /// The script's editor, with its language's definition and text, and the label that says
        /// how its last check went. Checked at once, so the page opens with its diagnostics.
        void AttachScript(gui::CodeEditor& editor, StringView languageXml, StringView source, gui::Label* status)
        {
            m_script = &editor;
            m_status = status;
            if (ReadLanguage(languageXml, m_scriptLanguage))
                editor.SetLanguage(&m_scriptLanguage);
            editor.SetText(source);
            editor.SetLanguageService(this);
            CodePage* self = this;
            editor.SetOnGutterClick([self](u32 line) { self->ToggleBreakpoint(line); });
            (void)editor.GetDocument().AddChangeListener([self](const gui::CodeChange&) { self->m_checkIn = kCheckDelay; });
            Check();
        }

        /// The shader's editor: highlighting, folding and its regions; no service.
        void AttachShader(gui::CodeEditor& editor, StringView languageXml, StringView source)
        {
            if (ReadLanguage(languageXml, m_shaderLanguage))
                editor.SetLanguage(&m_shaderLanguage);
            editor.SetText(source);
        }

        /// Counts down to the check an edit asked for.
        void Update(f32 deltaTime)
        {
            if (m_checkIn <= 0.0f)
                return;
            m_checkIn -= deltaTime;
            if (m_checkIn <= 0.0f)
                Check();
        }

        /// Compiles the script as it stands, nothing of it run, and shows what the compiler said.
        void Check()
        {
            m_checkIn = 0.0f;
            if (m_script == nullptr)
                return;
            Array<gui::CodeDiagnostic> diagnostics;
            String said;
            if (m_scripts == nullptr)
                said = String(u8"No script backend in this build: nothing checks the script");
            else
            {
                Collector errors;
                const String source = m_script->GetDocument().GetText();
                const bool ok = m_scripts->Check(source.AsView(), kChunk, errors);
                for (const Collector::Entry& e : errors.Entries)
                    diagnostics.PushBack(gui::CodeDiagnostic{RangeOf(e.Line, e.Column), gui::CodeSeverity::Error, e.Message});
                if (ok && errors.Entries.IsEmpty())
                    said = String(u8"Compiles: no errors");
                else if (errors.Entries.Size() == 1)
                    said = Format(u8"1 error: line {}: {}", errors.Entries[0].Line, errors.Entries[0].Message);
                else
                    said = Format(u8"{} errors, the first on line {}: {}", errors.Entries.Size(),
                                  errors.Entries.IsEmpty() ? 0 : errors.Entries[0].Line,
                                  errors.Entries.IsEmpty() ? StringView(u8"") : errors.Entries[0].Message.AsView());
            }
            m_script->SetDiagnostics(diagnostics.AsSpan());
            if (m_status != nullptr)
                m_status->SetText(said.AsView());
            ++m_checks;
        }

        /// How many times the script has been checked, for a test.
        [[nodiscard]] u32 CheckCount() const noexcept { return m_checks; }

        /// Sets a breakpoint on `line`, or takes away the one there.
        void ToggleBreakpoint(u32 line)
        {
            if (m_script == nullptr)
                return;
            for (usize i = 0; i < m_breakpoints.Size(); ++i)
                if (m_script->MarkerLine(m_breakpoints[i]) == line)
                {
                    m_script->RemoveMarker(m_breakpoints[i]);
                    m_breakpoints.RemoveAt(i);
                    return;
                }
            m_breakpoints.PushBack(m_script->AddMarker(line, u8"breakpoint"));
        }

        // === ICodeLanguageService ===
        [[nodiscard]] StringView CompletionTriggers() const override { return u8".:"; }

        void Complete(const gui::CodeDocument& document, const gui::CodeCompletionRequest& request,
                      Array<gui::CodeCompletionItem>& out) override
        {
            const StringView line = document.LineText(request.WordStart.Line);
            const u32 start = request.WordStart.Column;
            // After `x.` or `x::`, the members of what x is; else the words a script may begin with.
            bool statics = false;
            const StringView qualifier = QualifierBefore(line, start, statics);
            if (!qualifier.IsEmpty())
            {
                if (const script::ScriptApiType* type = Resolve(document, qualifier))
                    AddMembers(*type, statics, out);
                return;
            }
            if (start > 0 && line[start - 1] == u8'.')
                return; // a member of something we cannot name
            AddLanguageWords(out);
            for (const script::ScriptApiType& type : m_api)
                out.PushBack(gui::CodeCompletionItem{type.scriptName, type.isNamespace ? gui::CodeCompletionKind::Module : gui::CodeCompletionKind::Type,
                                                     String(type.isNamespace ? u8"namespace" : u8"type"), String{}});
            AddDocumentWords(document, request, out);
        }

        bool Hover(const gui::CodeDocument& document, gui::CodePosition at, String& out) override
        {
            if (at.Line >= document.LineCount())
                return false;
            const StringView line = document.LineText(at.Line);
            u32 begin = at.Column, end = at.Column;
            while (begin > 0 && IsWordByte(line[begin - 1]))
                --begin;
            while (end < line.Size() && IsWordByte(line[end]))
                ++end;
            if (begin == end)
                return false;
            const StringView word = line.SubStr(begin, end - begin);
            bool statics = false;
            const StringView qualifier = QualifierBefore(line, begin, statics);
            if (!qualifier.IsEmpty())
            {
                const script::ScriptApiType* type = Resolve(document, qualifier);
                if (type == nullptr)
                    return false;
                usize shown = 0;
                for (const script::ScriptApiMember& member : type->members)
                    if (member.name.AsView() == word && shown < 3)
                    {
                        if (shown++ > 0)
                            out += u8"\n";
                        out += Format(u8"{}.{}", type->scriptName, member.signature.IsEmpty() ? member.name : member.signature);
                    }
                return shown > 0;
            }
            if (const script::ScriptApiType* type = FindType(word))
            {
                out = Format(u8"{} {} ({} members)", type->isNamespace ? StringView(u8"namespace") : StringView(u8"type"),
                             type->scriptName, type->members.Size());
                return true;
            }
            return false;
        }

    private:
        static constexpr StringView kChunk = u8"code.as";

        struct Collector final : script::IScriptErrorHandler
        {
            struct Entry
            {
                i32 Line;
                i32 Column;
                String Message;
            };
            Array<Entry> Entries;
            void OnError(const script::ScriptError& error) override
            {
                if (error.module != kChunk) // the backend's own sections are not the page's
                    return;
                Entries.PushBack(Entry{error.line, error.column, String(error.message)});
            }
        };

        [[nodiscard]] static bool IsWordByte(char8_t c) noexcept
        {
            return (c >= u8'a' && c <= u8'z') || (c >= u8'A' && c <= u8'Z') || (c >= u8'0' && c <= u8'9') || c == u8'_' || c >= 0x80;
        }

        /// What the compiler's (1-based) line and column point at: the word there, or one
        /// character; the line's text when no column is given.
        [[nodiscard]] gui::CodeRange RangeOf(i32 line, i32 column) const
        {
            const gui::CodeDocument& doc = m_script->GetDocument();
            const u32 l = line > 0 ? Min(static_cast<u32>(line - 1), doc.LineCount() - 1) : 0;
            const StringView text = doc.LineText(l);
            if (column <= 0)
            {
                u32 first = 0;
                while (first < text.Size() && (text[first] == u8' ' || text[first] == u8'\t'))
                    ++first;
                return gui::CodeRange{gui::CodePosition{l, first}, gui::CodePosition{l, static_cast<u32>(text.Size())}};
            }
            const u32 c = Min(static_cast<u32>(column - 1), static_cast<u32>(text.Size()));
            u32 end = c;
            while (end < text.Size() && IsWordByte(text[end]))
                ++end;
            if (end == c && end < text.Size())
                ++end;
            return gui::CodeRange{gui::CodePosition{l, c}, gui::CodePosition{l, end}};
        }

        /// The name before `x.` or `x::` ending at `start` (`statics` for `::`); empty when none.
        [[nodiscard]] static StringView QualifierBefore(StringView line, u32 start, bool& statics)
        {
            u32 end = start;
            statics = false;
            if (end >= 2 && line[end - 1] == u8':' && line[end - 2] == u8':')
            {
                statics = true;
                end -= 2;
            }
            else if (end >= 1 && line[end - 1] == u8'.')
                end -= 1;
            else
                return {};
            u32 begin = end;
            while (begin > 0 && IsWordByte(line[begin - 1]))
                --begin;
            return line.SubStr(begin, end - begin);
        }

        [[nodiscard]] const script::ScriptApiType* FindType(StringView name) const
        {
            for (const script::ScriptApiType& type : m_api)
                if (type.scriptName.AsView() == name)
                    return &type;
            return nullptr;
        }

        /// A type or namespace by its name, or the type a variable of that name is declared with
        /// in the script (`Node@ card`, `Float3 at`), the last declaration found.
        [[nodiscard]] const script::ScriptApiType* Resolve(const gui::CodeDocument& document, StringView name) const
        {
            if (const script::ScriptApiType* type = FindType(name))
                return type;
            const script::ScriptApiType* found = nullptr;
            for (u32 l = 0; l < document.LineCount(); ++l)
            {
                const StringView text = document.LineText(l);
                for (usize at = 0; at + name.Size() <= text.Size(); ++at)
                {
                    if (text.SubStr(at, name.Size()) != name || (at > 0 && IsWordByte(text[at - 1])) ||
                        (at + name.Size() < text.Size() && IsWordByte(text[at + name.Size()])))
                        continue;
                    // Back over spaces, a handle or reference mark, and spaces, to the type's name.
                    usize p = at;
                    while (p > 0 && text[p - 1] == u8' ')
                        --p;
                    while (p > 0 && (text[p - 1] == u8'@' || text[p - 1] == u8'&'))
                        --p;
                    while (p > 0 && text[p - 1] == u8' ')
                        --p;
                    usize q = p;
                    while (q > 0 && IsWordByte(text[q - 1]))
                        --q;
                    if (q == p || p == at)
                        continue;
                    if (const script::ScriptApiType* type = FindType(text.SubStr(q, p - q)))
                        found = type;
                }
            }
            return found;
        }

        static void AddMembers(const script::ScriptApiType& type, bool statics, Array<gui::CodeCompletionItem>& out)
        {
            for (const script::ScriptApiMember& member : type.members)
            {
                if (member.kind == script::ScriptApiMemberKind::Operator || (!type.isNamespace && member.isStatic != statics))
                    continue;
                bool seen = false; // an overload shows once, with its first signature
                for (const gui::CodeCompletionItem& item : out)
                    seen = seen || item.Label == member.name;
                if (seen)
                    continue;
                gui::CodeCompletionKind kind = gui::CodeCompletionKind::Method;
                if (member.kind == script::ScriptApiMemberKind::Property)
                    kind = gui::CodeCompletionKind::Property;
                else if (member.kind == script::ScriptApiMemberKind::Constant)
                    kind = gui::CodeCompletionKind::Constant;
                else if (type.isNamespace || member.isStatic)
                    kind = gui::CodeCompletionKind::Function;
                out.PushBack(gui::CodeCompletionItem{member.name, kind, member.signature, String{}});
            }
        }

        void AddLanguageWords(Array<gui::CodeCompletionItem>& out) const
        {
            for (const gui::CodeWords& words : m_scriptLanguage.Words)
            {
                gui::CodeCompletionKind kind = gui::CodeCompletionKind::Keyword;
                if (words.Token == gui::CodeToken::Type)
                    kind = gui::CodeCompletionKind::Type;
                else if (words.Token == gui::CodeToken::Constant)
                    kind = gui::CodeCompletionKind::Constant;
                const StringView list = words.List.AsView();
                usize begin = 0;
                for (usize i = 0; i <= list.Size(); ++i)
                    if (i == list.Size() || list[i] == u8' ')
                    {
                        if (i > begin)
                            out.PushBack(gui::CodeCompletionItem{String(list.SubStr(begin, i - begin)), kind, String{}, String{}});
                        begin = i + 1;
                    }
            }
        }

        /// The script's own names (its functions, variables), as an editor offers the words of
        /// the file: each once, not the word being typed, not what the list holds already.
        static void AddDocumentWords(const gui::CodeDocument& document, const gui::CodeCompletionRequest& request,
                                     Array<gui::CodeCompletionItem>& out)
        {
            for (u32 l = 0; l < document.LineCount(); ++l)
            {
                const StringView text = document.LineText(l);
                usize at = 0;
                while (at < text.Size())
                {
                    if (!IsWordByte(text[at]))
                    {
                        ++at;
                        continue;
                    }
                    usize end = at;
                    while (end < text.Size() && IsWordByte(text[end]))
                        ++end;
                    const bool typing = l == request.WordStart.Line && at == request.WordStart.Column;
                    if (end - at >= 3 && !typing && !(text[at] >= u8'0' && text[at] <= u8'9'))
                    {
                        const StringView word = text.SubStr(at, end - at);
                        bool seen = false;
                        for (const gui::CodeCompletionItem& item : out)
                            seen = seen || item.Label.AsView() == word;
                        if (!seen)
                            out.PushBack(gui::CodeCompletionItem{String(word), gui::CodeCompletionKind::Text, String{}, String{}});
                    }
                    at = end;
                }
            }
        }

        IAllocator& m_allocator;
        script::IScriptManager* m_scripts = nullptr;
        Array<script::ScriptApiType> m_api;
        gui::CodeLanguage m_scriptLanguage;
        gui::CodeLanguage m_shaderLanguage;
        gui::CodeEditor* m_script = nullptr;
        gui::Label* m_status = nullptr;
        f32 m_checkIn = 0.0f;
        u32 m_checks = 0;
        Array<u32> m_breakpoints;
    };
}
