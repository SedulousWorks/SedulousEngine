// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Code - :code_language partition
//
// A language's definition (C2 of Specs/gui-lab-evolution-3.md, ruling 1): a value its owners supply,
// built in code or read from a file through the engine's serialization (a script module's for its
// language, the sandbox's for its pages); the library ships none. A definition is contexts, each a
// list of rules tried in turn at each place of a line: a literal, an identifier (looked up in the
// language's words: keywords, types, constants), a number, one of some characters or a run of them,
// the rest of the line, and a long bracket's open or close (Luau's `[==[`). A rule gives its text a token, and may
// enter a context (a string, a comment, a tag) or leave some; what no rule takes is its context's
// token, an escape character taking the next with it. A context may end at the line's end (a line
// comment, a preprocessor line).
//
// The tokenizer reads one line at a time from the state the line before ended in (the contexts
// entered, a long bracket's level), as every editor surveyed does; a view keeps each line's tokens
// with the state it began in and the line's hash, and stops tokenizing where a line ends in the state
// it ended in before (eepp's).

module;
#include "Core/Prelude.h"

export module foundation.gui.code:code_language;

import foundation.core;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    /// What a run of code is: each draws in its part's colour (`codeeditor::keyword`).
    enum class CodeToken : u8
    {
        Text,
        Keyword,
        Type,
        Constant,
        Builtin,
        Number,
        String,
        Escape,
        Comment,
        Preprocessor,
        Operator,
        Punctuation,
        Tag,
        Attribute,
        Property,
        Selector,
        Invalid,
        Count,
    };
    namespace detail
    {
        inline constexpr const char8_t* kCodeTokenNames[] = {
            u8"text",         u8"keyword",  u8"type",        u8"constant", u8"builtin",   u8"number",
            u8"string",       u8"escape",   u8"comment",     u8"preprocessor", u8"operator", u8"punctuation",
            u8"tag",          u8"attribute", u8"property",   u8"selector", u8"invalid",
        };
    }
    /// A token's name: its part's (`keyword`), and how a definition file writes it.
    [[nodiscard]] inline core::StringView CodeTokenName(CodeToken token) noexcept
    {
        return token < CodeToken::Count ? core::StringView(detail::kCodeTokenNames[static_cast<usize>(token)]) : core::StringView(u8"text");
    }
    [[nodiscard]] inline CodeToken CodeTokenNamed(core::StringView name) noexcept
    {
        for (usize i = 0; i < static_cast<usize>(CodeToken::Count); ++i)
            if (name == core::StringView(detail::kCodeTokenNames[i]))
                return static_cast<CodeToken>(i);
        return CodeToken::Text;
    }

    /// What a rule matches at a place in a line.
    enum class CodeMatch : u8
    {
        Literal,    ///< its text, as it is
        Identifier, ///< a name (letters, digits, underscores; not first a digit), looked up in the words
        Number,     ///< a number: decimal, 0x hex, with a fraction, an exponent, a suffix
        AnyOf,      ///< one of its text's characters
        Run,        ///< one or more of its text's characters (a CSS colour's `#1a2b3c`)
        LineRest,   ///< the rest of the line
        LongOpen,   ///< its text's character, '='s, the character again (Luau's `[==[`), the '='s kept
        LongClose,  ///< its text's character, as many '='s as the open's, the character again
    };
    namespace detail
    {
        inline constexpr const char8_t* kCodeMatchNames[] = {
            u8"literal", u8"identifier", u8"number", u8"any-of", u8"run", u8"line-rest", u8"long-open", u8"long-close",
        };
    }

    struct CodeRule
    {
        CodeMatch Match = CodeMatch::Literal;
        core::String Text;          ///< the literal; the characters of any-of; a long bracket's character
        CodeToken Token = CodeToken::Text; ///< an identifier's when the words do not name it
        core::String Enter;         ///< the context it enters, by name (empty: none)
        u8 Leave = 0;               ///< how many contexts it leaves (before entering)
        bool LineStart = false;     ///< only first on its line, past the indent (a `#` line)
    };

    struct CodeContext
    {
        core::String Name;
        CodeToken Token = CodeToken::Text; ///< what no rule takes is
        core::String Escape;               ///< an escape: it and the character after it, escape tokens
        bool EndsAtLineEnd = false;        ///< left where its line ends
        core::Array<CodeRule> Rules;
    };

    /// Words a language names, of one token: its keywords, its types, its constants (`List` the
    /// words, space-separated).
    struct CodeWords
    {
        CodeToken Token = CodeToken::Keyword;
        core::String List;
    };

    /// A pair the editor knows: a bracket it matches, or what typing one side puts the other for.
    struct CodePair
    {
        core::String Open;
        core::String Close;
    };

    /// Where a line's tokenizing stands: the contexts entered (the first context below them all) and
    /// an open long bracket's level.
    struct CodeLexState
    {
        static constexpr u8 kDepth = 7;
        u8 Depth = 0;
        u8 Stack[kDepth] = {};
        u8 Level = 0;

        [[nodiscard]] u8 Top() const noexcept { return Depth > 0 ? Stack[Depth - 1] : 0; }
        [[nodiscard]] bool operator==(const CodeLexState& o) const noexcept
        {
            if (Depth != o.Depth || Level != o.Level)
                return false;
            for (u8 i = 0; i < Depth; ++i)
                if (Stack[i] != o.Stack[i])
                    return false;
            return true;
        }
    };

    /// A run of a line's bytes and its token.
    struct CodeSpan
    {
        u32 Start = 0;
        u32 End = 0;
        CodeToken Token = CodeToken::Text;
    };

    class CodeLanguage
    {
    public:
        core::String Id;   ///< what its owners register it by ("angelscript")
        core::String Name; ///< what it is called ("AngelScript")
        core::Array<core::String> Extensions; ///< file name endings it is for ("as")
        bool IdentifierDashes = false;        ///< names may hold '-' and begin with it (CSS's)
        core::Array<CodeWords> Words;
        core::Array<CodeContext> Contexts;    ///< the first is where a file starts
        // How it is edited (C3):
        core::String LineComment;             ///< what a line comment begins with ("//", "--")
        CodePair BlockComment;                ///< a block comment's ends ("/*" "*/", "<!--" "-->")
        core::Array<CodePair> Brackets;       ///< matched, and indent between ("(" ")", "{" "}")
        core::Array<CodePair> AutoClose;      ///< typing the open puts the close ("(" ")", "\"" "\"")
        core::String IndentAfter;             ///< what, ending a line, indents the next (space-separated: "{ ( [", Luau's "then do")
        core::String OutdentFirst;            ///< what, first on its line, outdents it ("}", Luau's "end else until")
        // How it folds (C7):
        bool FoldByIndent = false;            ///< by indentation rather than by its brackets (Luau's blocks, markup)
        core::String RegionStart;             ///< a line beginning with it opens a fold to its RegionEnd ("#pragma region")
        core::String RegionEnd;

        /// Resolves what refers by name (a rule's context, the words), once after it is filled in or
        /// read; tokenizing asks it first.
        void Prepare()
        {
            m_enter.Clear();
            for (const CodeContext& context : Contexts)
                for (const CodeRule& rule : context.Rules)
                {
                    i32 index = -1;
                    if (!rule.Enter.IsEmpty())
                        for (usize i = 0; i < Contexts.Size(); ++i)
                            if (Contexts[i].Name == rule.Enter)
                                index = static_cast<i32>(i);
                    m_enter.PushBack(index);
                }
            m_words.Clear();
            for (const CodeWords& group : Words)
            {
                const core::StringView list = group.List.AsView();
                usize at = 0;
                while (at < list.Size())
                {
                    while (at < list.Size() && (list[at] == u8' ' || list[at] == u8'\n' || list[at] == u8'\t' || list[at] == u8'\r'))
                        ++at;
                    usize end = at;
                    while (end < list.Size() && list[end] != u8' ' && list[end] != u8'\n' && list[end] != u8'\t' && list[end] != u8'\r')
                        ++end;
                    if (end > at)
                        m_words.InsertOrAssign(core::String(list.SubStr(at, end - at)), group.Token);
                    at = end;
                }
            }
            m_prepared = true;
        }

        /// Tokenizes `line` from `state` (the line before's end), leaving it as this line ends; the
        /// runs in order, those of one token joined.
        void Tokenize(core::StringView line, CodeLexState& state, core::Array<CodeSpan>& out) const
        {
            out.Clear();
            if (!m_prepared || Contexts.IsEmpty())
            {
                if (line.Size() != 0)
                    out.PushBack(CodeSpan{0, static_cast<u32>(line.Size()), CodeToken::Text});
                return;
            }
            const auto emit = [&out](usize start, usize end, CodeToken token)
            {
                if (end <= start)
                    return;
                if (!out.IsEmpty() && out.Back().End == start && out.Back().Token == token)
                    out.Back().End = static_cast<u32>(end);
                else
                    out.PushBack(CodeSpan{static_cast<u32>(start), static_cast<u32>(end), token});
            };
            usize pos = 0;
            while (pos < line.Size())
            {
                const u8 top = state.Top() < Contexts.Size() ? state.Top() : 0;
                const CodeContext& context = Contexts[top];
                if (!context.Escape.IsEmpty() && StartsAt(line, pos, context.Escape.AsView()))
                {
                    const usize end = core::Min(line.Size(), NextChar(line, pos + context.Escape.Size()));
                    emit(pos, end, CodeToken::Escape);
                    pos = end;
                    continue;
                }
                bool matched = false;
                const usize ruleBase = RuleBase(top);
                for (usize r = 0; r < context.Rules.Size(); ++r)
                {
                    const CodeRule& rule = context.Rules[r];
                    if (rule.LineStart && !OnlySpaceBefore(line, pos))
                        continue;
                    u8 level = state.Level;
                    const usize length = MatchAt(rule, line, pos, level);
                    if (length == 0)
                        continue;
                    CodeToken token = rule.Token;
                    if (rule.Match == CodeMatch::Identifier)
                        if (const CodeToken* named = m_words.Find(core::String(line.SubStr(pos, length))))
                            token = *named;
                    emit(pos, pos + length, token);
                    pos += length;
                    for (u8 i = 0; i < rule.Leave && state.Depth > 0; ++i)
                        --state.Depth;
                    const i32 enter = m_enter[ruleBase + r];
                    if (enter >= 0 && state.Depth < CodeLexState::kDepth)
                        state.Stack[state.Depth++] = static_cast<u8>(enter);
                    if (rule.Match == CodeMatch::LongOpen)
                        state.Level = level;
                    matched = true;
                    break;
                }
                if (matched)
                    continue;
                const usize end = NextChar(line, pos);
                emit(pos, end, context.Token);
                pos = end;
            }
            // A line comment, a preprocessor line: done where the line is.
            while (state.Depth > 0 && state.Top() < Contexts.Size() && Contexts[state.Top()].EndsAtLineEnd)
                --state.Depth;
        }

    private:
        [[nodiscard]] usize RuleBase(u8 context) const noexcept
        {
            usize base = 0;
            for (u8 i = 0; i < context; ++i)
                base += Contexts[i].Rules.Size();
            return base;
        }
        [[nodiscard]] static bool StartsAt(core::StringView line, usize pos, core::StringView text) noexcept
        {
            return text.Size() != 0 && pos + text.Size() <= line.Size() && line.SubStr(pos, text.Size()) == text;
        }
        [[nodiscard]] static usize NextChar(core::StringView line, usize pos) noexcept
        {
            ++pos;
            while (pos < line.Size() && (static_cast<u8>(line[pos]) & 0xC0u) == 0x80u)
                ++pos;
            return pos;
        }
        [[nodiscard]] static bool OnlySpaceBefore(core::StringView line, usize pos) noexcept
        {
            for (usize i = 0; i < pos; ++i)
                if (line[i] != u8' ' && line[i] != u8'\t')
                    return false;
            return true;
        }
        [[nodiscard]] static bool Holds(core::StringView set, char8_t c) noexcept
        {
            for (char8_t in : set)
                if (in == c)
                    return true;
            return false;
        }
        [[nodiscard]] static bool IsDigit(char8_t c) noexcept { return c >= u8'0' && c <= u8'9'; }
        [[nodiscard]] static bool IsNameStart(char8_t c) noexcept
        {
            return (c >= u8'a' && c <= u8'z') || (c >= u8'A' && c <= u8'Z') || c == u8'_' || static_cast<u8>(c) >= 0x80u;
        }
        [[nodiscard]] bool IsNamePart(char8_t c) const noexcept { return IsNameStart(c) || IsDigit(c) || (IdentifierDashes && c == u8'-'); }
        [[nodiscard]] usize MatchAt(const CodeRule& rule, core::StringView line, usize pos, u8& level) const noexcept
        {
            switch (rule.Match)
            {
            case CodeMatch::Literal: return StartsAt(line, pos, rule.Text.AsView()) ? rule.Text.Size() : 0;
            case CodeMatch::Identifier:
            {
                // With dashes (CSS), a name may begin with them: `-webkit-x`, `--token`.
                usize start = pos;
                while (IdentifierDashes && start < line.Size() && line[start] == u8'-')
                    ++start;
                if (start >= line.Size() || !IsNameStart(line[start]) || (pos > 0 && IsNamePart(line[pos - 1])))
                    return 0;
                usize end = pos + 1;
                while (end < line.Size() && IsNamePart(line[end]))
                    ++end;
                return end - pos;
            }
            case CodeMatch::Number:
            {
                if (pos > 0 && IsNamePart(line[pos - 1]))
                    return 0; // a digit inside a name
                usize end = pos;
                if (StartsAt(line, pos, core::StringView(u8"0x")) || StartsAt(line, pos, core::StringView(u8"0X")))
                {
                    end += 2;
                    while (end < line.Size() && (IsDigit(line[end]) || (line[end] >= u8'a' && line[end] <= u8'f') ||
                                                 (line[end] >= u8'A' && line[end] <= u8'F') || line[end] == u8'_'))
                        ++end;
                    return end > pos + 2 ? end - pos : 0;
                }
                const bool startsWithDot = line[pos] == u8'.';
                if (!IsDigit(line[pos]) && !(startsWithDot && pos + 1 < line.Size() && IsDigit(line[pos + 1])))
                    return 0;
                while (end < line.Size() && (IsDigit(line[end]) || line[end] == u8'_'))
                    ++end;
                if (end < line.Size() && line[end] == u8'.' && !(end + 1 < line.Size() && line[end + 1] == u8'.'))
                {
                    ++end;
                    while (end < line.Size() && IsDigit(line[end]))
                        ++end;
                }
                if (end < line.Size() && (line[end] == u8'e' || line[end] == u8'E'))
                {
                    usize at = end + 1;
                    if (at < line.Size() && (line[at] == u8'+' || line[at] == u8'-'))
                        ++at;
                    if (at < line.Size() && IsDigit(line[at]))
                    {
                        end = at;
                        while (end < line.Size() && IsDigit(line[end]))
                            ++end;
                    }
                }
                while (end < line.Size() && ((line[end] >= u8'a' && line[end] <= u8'z') || (line[end] >= u8'A' && line[end] <= u8'Z')))
                    ++end; // a suffix: 1.0f, 10u, 2ull
                return end - pos;
            }
            case CodeMatch::AnyOf: return Holds(rule.Text.AsView(), line[pos]) ? 1 : 0;
            case CodeMatch::Run:
            {
                usize end = pos;
                while (end < line.Size() && Holds(rule.Text.AsView(), line[end]))
                    ++end;
                return end - pos;
            }
            case CodeMatch::LineRest: return line.Size() - pos;
            case CodeMatch::LongOpen:
            {
                if (rule.Text.IsEmpty() || line[pos] != rule.Text.AsView()[0])
                    return 0;
                usize end = pos + 1;
                u8 equals = 0;
                while (end < line.Size() && line[end] == u8'=')
                {
                    ++end;
                    ++equals;
                }
                if (end >= line.Size() || line[end] != rule.Text.AsView()[0])
                    return 0;
                level = equals;
                return end + 1 - pos;
            }
            case CodeMatch::LongClose:
            {
                if (rule.Text.IsEmpty() || line[pos] != rule.Text.AsView()[0])
                    return 0;
                usize end = pos + 1;
                for (u8 i = 0; i < level; ++i, ++end)
                    if (end >= line.Size() || line[end] != u8'=')
                        return 0;
                if (end >= line.Size() || line[end] != rule.Text.AsView()[0])
                    return 0;
                return end + 1 - pos;
            }
            }
            return 0;
        }

        core::Array<i32> m_enter; // each rule's context to enter, in context order
        core::HashMap<core::String, CodeToken> m_words;
        bool m_prepared = false;
    };

    // === Serialization: a definition as its owners keep it (the engine's XML, any serializer) ===
    namespace detail
    {
        template <typename T>
        void Optional(ISerializer& ar, const char* key, T& value)
        {
            if (ar.Mode() == SerializeMode::Read && !ar.HasKey(key))
                return;
            core::Serialize(ar, key, value);
        }
        inline void TokenField(ISerializer& ar, const char* key, CodeToken& token)
        {
            core::String name(CodeTokenName(token));
            if (ar.Mode() == SerializeMode::Read && !ar.HasKey(key))
                return;
            core::Serialize(ar, key, name);
            token = CodeTokenNamed(name.AsView());
        }
    }
    inline void Serialize(ISerializer& ar, CodeRule& rule)
    {
        ar.BeginObject();
        core::String match(detail::kCodeMatchNames[static_cast<usize>(rule.Match)]);
        detail::Optional(ar, "match", match);
        for (usize i = 0; i < sizeof(detail::kCodeMatchNames) / sizeof(detail::kCodeMatchNames[0]); ++i)
            if (match.AsView() == core::StringView(detail::kCodeMatchNames[i]))
                rule.Match = static_cast<CodeMatch>(i);
        detail::Optional(ar, "text", rule.Text);
        detail::TokenField(ar, "token", rule.Token);
        detail::Optional(ar, "enter", rule.Enter);
        detail::Optional(ar, "leave", rule.Leave);
        detail::Optional(ar, "lineStart", rule.LineStart);
        ar.EndObject();
    }
    inline void Serialize(ISerializer& ar, CodeContext& context)
    {
        ar.BeginObject();
        detail::Optional(ar, "name", context.Name);
        detail::TokenField(ar, "token", context.Token);
        detail::Optional(ar, "escape", context.Escape);
        detail::Optional(ar, "endsAtLineEnd", context.EndsAtLineEnd);
        detail::Optional(ar, "rules", context.Rules);
        ar.EndObject();
    }
    inline void Serialize(ISerializer& ar, CodeWords& words)
    {
        ar.BeginObject();
        detail::TokenField(ar, "token", words.Token);
        detail::Optional(ar, "list", words.List);
        ar.EndObject();
    }
    inline void Serialize(ISerializer& ar, CodePair& pair)
    {
        ar.BeginObject();
        detail::Optional(ar, "open", pair.Open);
        detail::Optional(ar, "close", pair.Close);
        ar.EndObject();
    }
    inline void Serialize(ISerializer& ar, CodeLanguage& language)
    {
        ar.BeginObject();
        detail::Optional(ar, "id", language.Id);
        detail::Optional(ar, "name", language.Name);
        detail::Optional(ar, "extensions", language.Extensions);
        detail::Optional(ar, "identifierDashes", language.IdentifierDashes);
        detail::Optional(ar, "words", language.Words);
        detail::Optional(ar, "contexts", language.Contexts);
        detail::Optional(ar, "lineComment", language.LineComment);
        if (ar.Mode() != SerializeMode::Read || ar.HasKey("blockComment"))
            core::Serialize(ar, "blockComment", language.BlockComment);
        detail::Optional(ar, "brackets", language.Brackets);
        detail::Optional(ar, "autoClose", language.AutoClose);
        detail::Optional(ar, "indentAfter", language.IndentAfter);
        detail::Optional(ar, "outdentFirst", language.OutdentFirst);
        detail::Optional(ar, "foldByIndent", language.FoldByIndent);
        detail::Optional(ar, "regionStart", language.RegionStart);
        detail::Optional(ar, "regionEnd", language.RegionEnd);
        ar.EndObject();
        if (ar.Mode() == SerializeMode::Read)
            language.Prepare();
    }
}
