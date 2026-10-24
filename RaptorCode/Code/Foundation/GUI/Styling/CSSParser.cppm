// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :css_parser partition
//
// CSSParser: turns `.css` text into a StyleSheet. Ported from eepp's css/StyleSheetParser
// (common subset). Handles `/* comments */`, comma-separated selector lists, `name: value;`
// declaration blocks (custom properties and `!important` among them), `@media` blocks and
// `@keyframes` and `@font-face`; best-effort (malformed bits are skipped). Other at-rules
// (`@import`) are skipped, and nesting is not read. A quoted string is whole, as CSS tokenizes
// one: no `;`, brace or comment opener inside it ends or starts anything, and no `;` inside
// parentheses ends a declaration either (an inline SVG's markup, `url(data:...;base64,...)`).
// Given a diagnostics list (E1), what it skips goes there with its line, for a cook: an at-rule it
// does not read, a declaration with no colon, text with no rule block, a rule not closed, a
// selector that can match nothing. Property names are checked apart (CheckStyleSheetNames: they
// depend on the element types registered).

module;
#include "Core/Prelude.h"

export module foundation.gui:css_parser;

import foundation.core; // String, StringView, Move
import :style_rule;
import :style_sheet;
import :style_selector; // StyleSelector::SplitList
import :media_query;
import :diagnostic; // GuiDiagnostic

using namespace foundation::core;
namespace core = foundation::core;

namespace foundation::gui
{
    // Past the quoted string starting at `i` (its closing quote, a backslash escaping one), or
    // `i` when no string starts there.
    [[nodiscard]] inline usize SkipQuoted(core::StringView s, usize i) noexcept
    {
        if (i >= s.Size() || (s[i] != u8'"' && s[i] != u8'\''))
            return i;
        const char8_t quote = s[i++];
        while (i < s.Size() && s[i] != quote)
            i += s[i] == u8'\\' && i + 1 < s.Size() ? 2 : 1;
        return i < s.Size() ? i + 1 : i;
    }

    // The first of `stops` from `i` outside quoted strings and parentheses; the end when none.
    [[nodiscard]] inline usize ScanTo(core::StringView s, usize i, core::StringView stops) noexcept
    {
        usize depth = 0;
        while (i < s.Size())
        {
            if (const usize past = SkipQuoted(s, i); past != i)
            {
                i = past;
                continue;
            }
            const char8_t c = s[i];
            if (depth == 0)
                for (const char8_t stop : stops)
                    if (c == stop)
                        return i;
            if (c == u8'(')
                ++depth;
            else if (c == u8')' && depth > 0)
                --depth;
            ++i;
        }
        return i;
    }

    // Blank out /* ... */ comments, keeping their line breaks, so a rule's place in the result is
    // its place in the source (its line, for the inspector).
    [[nodiscard]] inline core::String StripComments(core::StringView s)
    {
        core::String out;
        const usize n = s.Size();
        usize runStart = 0, i = 0;
        while (i < n)
        {
            if (const usize past = SkipQuoted(s, i); past != i)
                i = past; // a string's "/*" is its text
            else if (i + 1 < n && s[i] == u8'/' && s[i + 1] == u8'*')
            {
                out.Append(s.SubStr(runStart, i - runStart));
                const usize start = i;
                i += 2;
                while (i + 1 < n && !(s[i] == u8'*' && s[i + 1] == u8'/'))
                    ++i;
                i = (i + 1 < n) ? i + 2 : n; // skip closing */ (or to end)
                for (usize k = start; k < i; ++k)
                    out.Append(core::StringView(s[k] == u8'\n' ? u8"\n" : u8" "));
                runStart = i;
            }
            else
            {
                ++i;
            }
        }
        out.Append(s.SubStr(runStart, n - runStart));
        return out;
    }
}

export namespace foundation::gui
{
    class CSSParser
    {
    public:
        /// Parses CSS source into a StyleSheet named `name` (a path, "theme": where its rules came
        /// from, which each rule keeps with its line and selector, for the inspector).
        /// Given `diagnostics`, what it skips is said there (E1).
        [[nodiscard]] static StyleSheet Parse(core::StringView css, core::StringView name = {},
                                              Array<GuiDiagnostic>* diagnostics = nullptr)
        {
            const core::String cleaned = StripComments(css);
            StyleSheet sheet;
            sheet.SetName(name);
            Source source{cleaned.AsView(), {}, diagnostics};
            source.LineStarts.PushBack(0);
            for (usize i = 0; i < cleaned.Size(); ++i)
                if (cleaned[i] == u8'\n')
                    source.LineStarts.PushBack(i + 1);
            ParseBlock(sheet, source, cleaned.AsView(), MediaQuery{});
            return sheet;
        }

    private:
        // The whole source (every block a part of it) and where its lines start.
        struct Source
        {
            core::StringView Whole;
            Array<usize> LineStarts;
            Array<GuiDiagnostic>* Diagnostics = nullptr; // E1: where what is skipped is said
            // Says what was skipped at `part` (its line), when diagnostics were asked for.
            void Skipped(core::StringView part, core::String message) const
            {
                if (Diagnostics != nullptr)
                    Diagnostics->PushBack(GuiDiagnostic{GuiDiagnostic::Severity::Warning, LineOf(part), core::Move(message)});
            }
            // The 1-based line of `part`'s first character other than white space.
            [[nodiscard]] u32 LineOf(core::StringView part) const
            {
                usize at = static_cast<usize>(part.Data() - Whole.Data());
                for (usize k = 0; k < part.Size() && IsWhiteSpace(part[k]); ++k)
                    ++at;
                usize lo = 0, hi = LineStarts.Size();
                while (hi - lo > 1)
                {
                    const usize mid = (lo + hi) / 2;
                    (LineStarts[mid] <= at ? lo : hi) = mid;
                }
                return static_cast<u32>(lo + 1);
            }
        };

        // Parse a run of rules (and nested @media blocks), attaching `media` to each rule.
        static void ParseBlock(StyleSheet& sheet, const Source& source, core::StringView src, const MediaQuery& media)
        {
            const usize n = src.Size();
            usize i = 0;
            while (i < n)
            {
                while (i < n && IsWhiteSpace(src[i]))
                    ++i;
                if (i >= n)
                    break;

                if (src[i] == u8'@')
                {
                    // At-rule: read the prelude up to '{' (block) or ';' (statement).
                    const usize atStart = i;
                    i = ScanTo(src, i, core::StringView(u8"{;"));
                    const core::StringView prelude = Trim(src.SubStr(atStart, i - atStart));
                    if (i < n && src[i] == u8';')
                    {
                        ++i;
                        // @import url(path) or "path" (E13): the style manager loads it through
                        // its resource provider. Other at-statements are skipped.
                        bool read = false;
                        if (prelude.Size() > 7 && prelude.SubStr(0, 7) == core::StringView(u8"@import"))
                            if (const core::StringView path = ImportPath(prelude.SubStr(7, prelude.Size() - 7)); path.Size() != 0)
                            {
                                sheet.AddImport(path);
                                read = true;
                            }
                        if (!read)
                            source.Skipped(prelude, core::Format(u8"an at-rule it does not read: {}", prelude));
                        continue;
                    }
                    if (i >= n)
                        break;

                    // Brace-matched block for this at-rule.
                    ++i; // consume '{'
                    const usize blockStart = i;
                    i32 depth = 1;
                    while (i < n && depth > 0)
                    {
                        if (const usize past = SkipQuoted(src, i); past != i)
                        {
                            i = past;
                            continue;
                        }
                        if (src[i] == u8'{')
                            ++depth;
                        else if (src[i] == u8'}')
                        {
                            --depth;
                            if (depth == 0)
                                break;
                        }
                        ++i;
                    }
                    const core::StringView inner = src.SubStr(blockStart, i - blockStart);
                    if (i < n)
                        ++i; // consume '}'

                    if (IsMedia(prelude))
                    {
                        const core::StringView condition =
                            Trim(prelude.SubStr(6, prelude.Size() - 6));
                        ParseBlock(sheet, source, inner,
                                   MediaQuery{condition}); // v1: inner media replaces outer
                    }
                    else if (IsKeyframes(prelude))
                    {
                        ParseKeyframes(source, sheet, Trim(prelude.SubStr(10, prelude.Size() - 10)),
                                       inner); // after "@keyframes"
                    }
                    else if (prelude == core::StringView(u8"@font-face"))
                    {
                        ParseFontFace(source, sheet, inner);
                    }
                    else if (prelude.Size() > 13 && prelude.SubStr(0, 13) == core::StringView(u8"@spritesheet "))
                    {
                        ParseSpritesheet(source, sheet, Trim(prelude.SubStr(13, prelude.Size() - 13)), inner);
                    }
                    else // unknown at-rule blocks are consumed and skipped
                        source.Skipped(prelude, core::Format(u8"an at-rule it does not read: {}", prelude));
                    continue;
                }

                // Normal rule: selector list up to '{'.
                const usize selStart = i;
                i = ScanTo(src, i, core::StringView(u8"{}"));
                if (i >= n || src[i] != u8'{')
                {
                    const core::StringView stray = Trim(src.SubStr(selStart, i - selStart));
                    source.Skipped(src.SubStr(selStart, i - selStart), core::Format(u8"text with no rule block: {}", stray));
                    break;
                }
                const core::StringView selectorList = src.SubStr(selStart, i - selStart);
                ++i; // consume '{'

                const usize blockStart = i;
                i = ScanTo(src, i, core::StringView(u8"}"));
                const core::StringView block = src.SubStr(blockStart, i - blockStart);
                if (i < n)
                    ++i; // consume '}'
                else
                    source.Skipped(selectorList, core::Format(u8"the rule for {} is not closed", Trim(selectorList)));

                EmitRules(source, sheet, source.LineOf(selectorList), selectorList, block, media);
            }
        }

        // An @spritesheet's block (E13): `src: url(atlas.png);` and a `name: x y width height;` per
        // sprite, in the image's pixels (px or none). One without a source is dropped.
        static void ParseSpritesheet(const Source& source, StyleSheet& sheet, core::StringView name, core::StringView block)
        {
            Spritesheet out;
            out.Name = core::String(name);
            for (const StyleProperty& p : ParseDeclList(source, block))
            {
                const core::StringView value = Trim(p.Value.AsView());
                if (p.Name.AsView() == core::StringView(u8"src"))
                {
                    core::StringView path = value;
                    if (path.Size() > 5 && path.SubStr(0, 4) == core::StringView(u8"url(") && path[path.Size() - 1] == u8')')
                        path = Trim(path.SubStr(4, path.Size() - 5));
                    if (path.Size() >= 2 && (path[0] == u8'"' || path[0] == u8'\'') && path[path.Size() - 1] == path[0])
                        path = path.SubStr(1, path.Size() - 2);
                    out.Source = core::String(path);
                    continue;
                }
                f32 v[4]{};
                usize n = 0;
                usize start = 0;
                for (usize i = 0; i <= value.Size() && n < 4; ++i)
                    if (i == value.Size() || value[i] == u8' ')
                    {
                        core::StringView token = value.SubStr(start, i - start);
                        if (token.Size() > 2 && token.SubStr(token.Size() - 2, 2) == core::StringView(u8"px"))
                            token = token.SubStr(0, token.Size() - 2);
                        if (const Optional<f32> number = ParseLength(token); token.Size() != 0 && number.HasValue())
                            v[n++] = number.Value();
                        start = i + 1;
                    }
                if (n == 4)
                    out.Sprites.PushBack(Sprite{core::String(p.Name.AsView()), v[0], v[1], v[2], v[3]});
            }
            if (out.Source.Size() != 0)
                sheet.AddSpritesheet(core::Move(out));
        }

        // An @import's path: its url() or its quoted string (a media list after it is ignored).
        [[nodiscard]] static core::StringView ImportPath(core::StringView rest)
        {
            core::StringView s = Trim(rest);
            if (s.Size() > 5 && s.SubStr(0, 4) == core::StringView(u8"url("))
            {
                usize close = 4;
                while (close < s.Size() && s[close] != u8')')
                    ++close;
                s = Trim(s.SubStr(4, close - 4));
            }
            else if (s.Size() != 0 && (s[0] == u8'"' || s[0] == u8'\''))
            {
                usize close = 1;
                while (close < s.Size() && s[close] != s[0])
                    ++close;
                return s.SubStr(1, close - 1);
            }
            if (s.Size() >= 2 && (s[0] == u8'"' || s[0] == u8'\'') && s[s.Size() - 1] == s[0])
                s = s.SubStr(1, s.Size() - 2);
            return s;
        }

        [[nodiscard]] static bool IsMedia(core::StringView prelude) noexcept
        {
            return prelude.Size() >= 6 && prelude.SubStr(0, 6) == core::StringView(u8"@media");
        }
        [[nodiscard]] static bool IsKeyframes(core::StringView prelude) noexcept
        {
            return prelude.Size() >= 10 &&
                   prelude.SubStr(0, 10) == core::StringView(u8"@keyframes");
        }

        // An @font-face's declarations: font-family and src (its first url, a path), font-weight
        // (a number, normal or bold) and font-style; one without a family or a source is dropped.
        static void ParseFontFace(const Source& source, StyleSheet& sheet, core::StringView block)
        {
            FontFaceRule face;
            for (const StyleProperty& p : ParseDeclList(source, block))
            {
                const core::StringView value = Trim(p.Value.AsView());
                if (p.Name.AsView() == core::StringView(u8"font-family"))
                {
                    core::StringView family = value;
                    if (family.Size() >= 2 && (family[0] == u8'"' || family[0] == u8'\'') && family[family.Size() - 1] == family[0])
                        family = Trim(family.SubStr(1, family.Size() - 2));
                    face.Family = core::String(family);
                }
                else if (p.Name.AsView() == core::StringView(u8"src"))
                {
                    // The first source of a list (`url(a.ttf) format("truetype"), url(b.woff)`).
                    usize end = 0;
                    while (end < value.Size() && value[end] != u8')' && value[end] != u8',')
                        ++end;
                    core::StringView first = Trim(value.SubStr(0, end < value.Size() && value[end] == u8')' ? end + 1 : end));
                    if (first.Size() >= 5 && first.SubStr(0, 4) == core::StringView(u8"url(") && first[first.Size() - 1] == u8')')
                        first = Trim(first.SubStr(4, first.Size() - 5));
                    if (first.Size() >= 2 && (first[0] == u8'"' || first[0] == u8'\'') && first[first.Size() - 1] == first[0])
                        first = first.SubStr(1, first.Size() - 2);
                    face.Source = core::String(first);
                }
                else if (p.Name.AsView() == core::StringView(u8"font-weight"))
                {
                    if (value == core::StringView(u8"bold"))
                        face.Weight = 700;
                    else if (const Optional<f64> w = ParseFloat(value); w.HasValue() && w.Value() >= 1.0 && w.Value() <= 1000.0)
                        face.Weight = static_cast<u16>(w.Value());
                }
                else if (p.Name.AsView() == core::StringView(u8"font-style"))
                {
                    face.Italic = value == core::StringView(u8"italic") || value.StartsWith(core::StringView(u8"oblique"));
                }
            }
            if (face.Family.Size() != 0 && face.Source.Size() != 0)
                sheet.AddFontFace(core::Move(face));
        }

        // Parse the inner of @keyframes: a run of `<offset-list> { decls }` stops (offset is a
        // percentage, or from/to). Comma-separated offsets share a block.
        static void ParseKeyframes(const Source& source, StyleSheet& sheet, core::StringView name, core::StringView inner)
        {
            Keyframes keyframes;
            keyframes.Name = core::String(name);

            const usize n = inner.Size();
            usize i = 0;
            while (i < n)
            {
                while (i < n && IsWhiteSpace(inner[i]))
                    ++i;
                if (i >= n)
                    break;

                const usize selStart = i;
                i = ScanTo(inner, i, core::StringView(u8"{"));
                if (i >= n)
                    break;
                const core::StringView offsetList = inner.SubStr(selStart, i - selStart);
                ++i; // consume '{'
                const usize blockStart = i;
                i = ScanTo(inner, i, core::StringView(u8"}"));
                const core::StringView block = inner.SubStr(blockStart, i - blockStart);
                if (i < n)
                    ++i; // consume '}'

                // A stop per (comma-separated) offset, sharing the declarations.
                usize s = 0;
                const usize on = offsetList.Size();
                for (usize k = 0; k <= on; ++k)
                {
                    if (k == on || offsetList[k] == u8',')
                    {
                        const core::StringView spec = Trim(offsetList.SubStr(s, k - s));
                        f32 offset = 0.0f;
                        if (ParseKeyframeOffset(spec, offset))
                        {
                            KeyframeStop stop;
                            stop.Offset = offset;
                            stop.Properties = ParseDeclList(source, block);
                            keyframes.Stops.PushBack(core::Move(stop));
                        }
                        s = k + 1;
                    }
                }
            }
            sheet.AddKeyframes(core::Move(keyframes));
        }

        // "0%".."100%" -> 0..1; "from" -> 0; "to" -> 1. Returns false if unrecognized.
        [[nodiscard]] static bool ParseKeyframeOffset(core::StringView spec, f32& out) noexcept
        {
            if (spec == core::StringView(u8"from"))
            {
                out = 0.0f;
                return true;
            }
            if (spec == core::StringView(u8"to"))
            {
                out = 1.0f;
                return true;
            }
            usize len = spec.Size();
            if (len == 0)
                return false;
            if (spec[len - 1] == u8'%')
                --len; // strip trailing %
            f32 value = 0.0f, scale = 1.0f;
            bool seenDot = false, any = false;
            for (usize k = 0; k < len; ++k)
            {
                const char8_t c = spec[k];
                if (c == u8'.')
                {
                    seenDot = true;
                    continue;
                }
                if (c < u8'0' || c > u8'9')
                    return false;
                any = true;
                if (seenDot)
                {
                    scale *= 0.1f;
                    value += static_cast<f32>(c - u8'0') * scale;
                }
                else
                    value = value * 10.0f + static_cast<f32>(c - u8'0');
            }
            if (!any)
                return false;
            out = value * 0.01f; // percent -> fraction
            return true;
        }

        // One rule per comma-separated selector, each carrying the block's declarations + media.
        static void EmitRules(const Source& source, StyleSheet& sheet, u32 line, core::StringView selectorList,
                              core::StringView block, const MediaQuery& media)
        {
            // Commas inside :is(), :not() or [a="b,c"] do not split.
            for (const core::StringView selector : StyleSelector::SplitList(selectorList))
            {
                StyleRule rule{selector};
                rule.SetSource(Trim(selector), line);
                if (rule.Selector().IsNever())
                    source.Skipped(selectorList, core::Format(u8"the selector {} matches nothing (a pseudo-class or function it does not know, or a typo)",
                                                              Trim(selector)));
                ApplyDeclarations(source, rule, block);
                if (!media.IsEmpty())
                    rule.SetMedia(media);
                sheet.AddRule(core::Move(rule));
            }
        }

        // Split `name: value;` declarations into the rule (later same-name wins via SetProperty).
        static void ApplyDeclarations(const Source& source, StyleRule& rule, core::StringView block)
        {
            for (const StyleProperty& p : ParseDeclList(source, block))
                rule.SetProperty(p.Name.AsView(), p.Value.AsView(), p.Important);
        }

        // Parse `name: value;` declarations into a flat property list (in source order).
        [[nodiscard]] static Array<StyleProperty> ParseDeclList(const Source& source, core::StringView block)
        {
            Array<StyleProperty> out;
            usize start = 0;
            const usize n = block.Size();
            while (start <= n)
            {
                const usize end = ScanTo(block, start, core::StringView(u8";"));
                const core::StringView decl = block.SubStr(start, end - start);
                start = end + 1;
                const usize colon = FindChar(decl, u8':');
                if (colon == kNotFound)
                {
                    if (Trim(decl).Size() != 0)
                        source.Skipped(decl, core::Format(u8"a declaration with no colon: {}", Trim(decl)));
                    continue;
                }
                const core::StringView name = Trim(decl.SubStr(0, colon));
                core::StringView value = Trim(decl.SubStr(colon + 1, decl.Size() - colon - 1));

                // Trailing !important.
                bool important = false;
                const core::StringView flag(u8"!important");
                if (value.Size() >= flag.Size() && value.SubStr(value.Size() - flag.Size(), flag.Size()) == flag)
                {
                    important = true;
                    value = Trim(value.SubStr(0, value.Size() - flag.Size()));
                }

                if (name.Size() != 0)
                    out.PushBack(StyleProperty(name, value, important));
            }
            return out;
        }

        static constexpr usize kNotFound = static_cast<usize>(-1);
        [[nodiscard]] static usize FindChar(core::StringView s, char8_t c) noexcept
        {
            for (usize i = 0; i < s.Size(); ++i)
                if (s[i] == c)
                    return i;
            return kNotFound;
        }
    };
}
