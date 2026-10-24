// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Code - :code_completion partition
//
// The language service (C6 of Specs/gui-lab-evolution-3.md): what the editor asks its host for, so
// the widget stays language-neutral (Godot's and Zero's): completions at a place, and what to say
// about the word under the pointer. The host answers from its compiler (a script module's API, the
// markup registry); the library ships none, as it ships no language.
//
// The completion list: a core popup that never takes the focus (the editor keeps the keys, its
// "completing" key context sending Up, Down, Return, Tab and Escape to the list), filtered fuzzily
// as the word grows (zed's and VS Code's: the letters in order, a match at the start or at a word's
// start, and a run of them, scoring higher), each row its kind, its label with the matched letters
// marked, and its detail.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui.code:code_completion;

import foundation.core;
import foundation.fonts;
import foundation.gui;
import :code_document;

using namespace foundation::core;
namespace core = foundation::core;
namespace fonts = foundation::fonts;

export namespace foundation::gui
{
    /// What a completion is, for its mark and its colour (the list's part of the kind's name).
    enum class CodeCompletionKind : u8
    {
        Text,
        Keyword,
        Variable,
        Function,
        Method,
        Property,
        Field,
        Type,
        Enum,
        EnumMember,
        Constant,
        Module,
        Snippet,
        Count,
    };
    [[nodiscard]] inline core::StringView CodeCompletionKindName(CodeCompletionKind kind) noexcept
    {
        static constexpr const char8_t* kNames[] = {u8"text", u8"keyword", u8"variable", u8"function", u8"method",
                                                    u8"property", u8"field", u8"type", u8"enum", u8"enum-member",
                                                    u8"constant", u8"module", u8"snippet"};
        const usize i = static_cast<usize>(kind);
        return core::StringView(i < static_cast<usize>(CodeCompletionKind::Count) ? kNames[i] : kNames[0]);
    }
    /// The letter a row marks its kind with (in the kind's colour).
    [[nodiscard]] inline core::StringView CodeCompletionKindMark(CodeCompletionKind kind) noexcept
    {
        static constexpr const char8_t* kMarks[] = {u8"t", u8"k", u8"v", u8"f", u8"m", u8"p", u8"d",
                                                    u8"T", u8"E", u8"e", u8"c", u8"M", u8"s"};
        const usize i = static_cast<usize>(kind);
        return core::StringView(i < static_cast<usize>(CodeCompletionKind::Count) ? kMarks[i] : kMarks[0]);
    }

    struct CodeCompletionItem
    {
        core::String Label;  ///< what the list shows and the typed word is matched against
        CodeCompletionKind Kind = CodeCompletionKind::Text;
        core::String Detail; ///< shown dim at the row's end (a type, a signature)
        core::String Insert; ///< what accepting puts in place of the typed word; empty: the label
    };

    /// What the editor asks completions for.
    struct CodeCompletionRequest
    {
        CodePosition At;      ///< the primary caret
        CodePosition WordStart; ///< where the word being typed begins (At when none is)
        bool Invoked = false; ///< asked for (Ctrl+Space) rather than opened by typing
        char8_t Trigger = 0;  ///< the trigger character just typed (a `.`), else 0
    };

    /// The host's: completions and hover for its language. Asked on the GUI's thread, at once.
    class ICodeLanguageService
    {
    public:
        virtual ~ICodeLanguageService() = default;
        /// The characters that open the list when typed (`.` and `:`), with an empty word.
        [[nodiscard]] virtual core::StringView CompletionTriggers() const = 0;
        /// Every completion that may apply at `request.At`; the editor filters them by the word as
        /// it is typed, asking again only when the list opens or a trigger is typed.
        virtual void Complete(const CodeDocument& document, const CodeCompletionRequest& request,
                              core::Array<CodeCompletionItem>& out) = 0;
        /// What to say of what is at `at` (a declaration, a value while debugging); false: nothing.
        virtual bool Hover(const CodeDocument& document, CodePosition at, core::String& out) = 0;
    };

    /// How well `pattern` matches `label` fuzzily: below 0 none, else higher better. Its letters
    /// must come in order, case aside, the first at the label's start or a word's (after `_`, `-`
    /// or `.`, or a capital after a small letter); each scores, more at the start, at a word's
    /// start (the first letter most), right after the letter before it, and in the pattern's case. `positions`, when given, gets
    /// the byte of each matched letter.
    [[nodiscard]] inline i32 CodeFuzzyMatch(core::StringView pattern, core::StringView label, core::Array<u32>* positions = nullptr)
    {
        if (positions != nullptr)
            positions->Clear();
        const usize m = pattern.Size(), n = label.Size();
        if (m == 0)
            return 0;
        if (m > n)
            return -1;
        const auto lower = [](char8_t c) { return c >= u8'A' && c <= u8'Z' ? static_cast<char8_t>(c + 32) : c; };
        const auto isUpper = [](char8_t c) { return c >= u8'A' && c <= u8'Z'; };
        const auto isLower = [](char8_t c) { return c >= u8'a' && c <= u8'z'; };
        const auto wordStart = [&](usize j)
        {
            if (j == 0)
                return true;
            const char8_t before = label[j - 1];
            return before == u8'_' || before == u8'-' || before == u8'.' || before == u8' ' || (isLower(before) && isUpper(label[j]));
        };
        constexpr usize kPattern = 32, kLabel = 128;
        if (m > kPattern || n > kLabel)
        {
            // Too long to weigh: a prefix, case aside, or nothing.
            for (usize i = 0; i < m; ++i)
                if (lower(pattern[i]) != lower(label[i]))
                    return -1;
            if (positions != nullptr)
                for (usize i = 0; i < m; ++i)
                    positions->PushBack(static_cast<u32>(i));
            return static_cast<i32>(m);
        }
        constexpr i16 kNone = -32000;
        i16 score[kPattern][kLabel];
        u8 from[kPattern][kLabel];
        const auto letter = [&](usize i, usize j) -> i16
        {
            // A later letter at a word's start counts less, so a run ("pos" in position) beats an
            // acronym's letters scattered over words ("pOrderSet").
            return static_cast<i16>(1 + (j == 0 ? 8 : wordStart(j) ? (i == 0 ? 6 : 3) : 0) + (pattern[i] == label[j] ? 1 : 0));
        };
        for (usize j = 0; j < n; ++j)
        {
            score[0][j] = lower(pattern[0]) == lower(label[j]) && wordStart(j) ? letter(0, j) : kNone;
            from[0][j] = 0;
        }
        for (usize i = 1; i < m; ++i)
        {
            i16 best = kNone; // the best of row i - 1 before j - 1
            u8 bestAt = 0;
            for (usize j = 0; j < n; ++j)
            {
                score[i][j] = kNone;
                from[i][j] = 0;
                if (j >= 2 && score[i - 1][j - 2] > best)
                {
                    best = score[i - 1][j - 2];
                    bestAt = static_cast<u8>(j - 2);
                }
                if (j == 0 || lower(pattern[i]) != lower(label[j]))
                    continue;
                const i16 run = score[i - 1][j - 1] > kNone ? static_cast<i16>(score[i - 1][j - 1] + 5) : kNone;
                if (run == kNone && best == kNone)
                    continue;
                if (run >= best)
                {
                    score[i][j] = static_cast<i16>(run + letter(i, j));
                    from[i][j] = static_cast<u8>(j - 1);
                }
                else
                {
                    score[i][j] = static_cast<i16>(best + letter(i, j));
                    from[i][j] = bestAt;
                }
            }
        }
        i16 total = kNone;
        usize end = 0;
        for (usize j = 0; j < n; ++j)
            if (score[m - 1][j] > total)
            {
                total = score[m - 1][j];
                end = j;
            }
        if (total == kNone)
            return -1;
        if (positions != nullptr)
        {
            positions->Resize(m);
            usize j = end;
            for (usize i = m; i-- > 0;)
            {
                (*positions)[i] = static_cast<u32>(j);
                j = from[i][j];
            }
        }
        return total;
    }

    /// The editor's completion list (`codecompletion`): the service's completions filtered by the
    /// word typed, best first, one selected. It never takes the focus, and a press in it leaves the
    /// focus in the editor; a click picks a row.
    class CodeCompletionList : public UIWidget
    {
        RTTI_OBJECT(CodeCompletionList, UIWidget)
    public:
        static constexpr usize kRowsShown = 10;
        static constexpr f32 kMinWidth = 200.0f;
        static constexpr f32 kMaxWidth = 560.0f;

        CodeCompletionList() : m_items(MemoryAllocator()), m_shown(MemoryAllocator()), m_rows(MemoryAllocator())
        {
            SetTag(core::StringView(u8"codecompletion"));
            SetKeepsFocus(true);
            SetClipChildren(true);
            StyleWriteScope defaults(*this);
            EditLayoutStyle([](LayoutStyle& s) { s.OverflowY = Overflow::Auto; });
        }

        /// The service's completions, filtered by the word typed.
        void SetItems(core::Array<CodeCompletionItem> items, core::StringView prefix)
        {
            m_items = core::Move(items);
            (void)Filter(prefix);
        }
        [[nodiscard]] usize ItemCount() const noexcept { return m_items.Size(); }
        /// Shows those `prefix` matches, best first (in the service's order while it is empty), the
        /// first selected; how many.
        usize Filter(core::StringView prefix)
        {
            m_prefix = core::String(prefix);
            m_shown.Clear();
            for (usize i = 0; i < m_items.Size(); ++i)
            {
                const i32 score = CodeFuzzyMatch(prefix, m_items[i].Label.AsView());
                if (score >= 0)
                    m_shown.PushBack(Shown{static_cast<u32>(i), score});
            }
            if (prefix.Size() != 0)
                m_shown.Sort([this](const Shown& a, const Shown& b)
                {
                    if (a.Score != b.Score)
                        return a.Score > b.Score;
                    return m_items[a.Item].Label.Size() < m_items[b.Item].Label.Size(); // the shorter, at a tie
                });
            m_rows.Clear();
            m_selected = 0;
            SetScrollOffset(core::Float2{0.0f, 0.0f});
            RequestLayout();
            Invalidate();
            return m_shown.Size();
        }
        [[nodiscard]] core::StringView GetPrefix() const noexcept { return m_prefix.AsView(); }
        [[nodiscard]] usize ShownCount() const noexcept { return m_shown.Size(); }
        [[nodiscard]] const CodeCompletionItem& ShownItem(usize index) const { return m_items[m_shown[index].Item]; }
        [[nodiscard]] usize GetSelected() const noexcept { return m_selected; }
        /// The selected completion; null when none shows.
        [[nodiscard]] const CodeCompletionItem* SelectedItem() const
        {
            return m_selected < m_shown.Size() ? &ShownItem(m_selected) : nullptr;
        }
        void SetSelected(usize index)
        {
            if (m_shown.IsEmpty())
                return;
            index = core::Min(index, m_shown.Size() - 1);
            if (index == m_selected)
                return;
            m_selected = index;
            ScrollToSelected();
            Invalidate();
            if (m_onSelected)
                m_onSelected(m_selected);
        }
        /// Up and Down (`wrap`: past an end to the other), the pages (stopping at the ends).
        void MoveSelection(i32 delta, bool wrap)
        {
            if (m_shown.IsEmpty())
                return;
            const i64 count = static_cast<i64>(m_shown.Size());
            i64 to = static_cast<i64>(m_selected) + delta;
            if (wrap && (delta == 1 || delta == -1))
                to = (to % count + count) % count;
            SetSelected(static_cast<usize>(core::Clamp<i64>(to, 0, count - 1)));
        }
        /// The page a Page Up or Down moves.
        [[nodiscard]] static i32 PageRows() noexcept { return static_cast<i32>(kRowsShown) - 1; }

        /// How far across a row its label begins: the editor lines it up with the word.
        [[nodiscard]] f32 LabelInset() const { return GetChrome().Left + kPad + m_measure.LayoutFor(Rect{}).Width + kPad; }
        [[nodiscard]] f32 RowHeight() const
        {
            const f32 line = m_measure.GetLineHeight();
            return (line > 0.0f ? line : 16.0f) + 4.0f;
        }

        void SetOnPicked(core::Function<void(usize)> callback) { m_onPicked = core::Move(callback); }
        void SetOnSelected(core::Function<void(usize)> callback) { m_onSelected = core::Move(callback); }

        void CollectStyleParts(core::Array<core::StringView>& out) const override
        {
            out.PushBack(core::StringView(u8"selected"));
            out.PushBack(core::StringView(u8"match"));
            out.PushBack(core::StringView(u8"detail"));
            for (usize i = 0; i < static_cast<usize>(CodeCompletionKind::Count); ++i)
                out.PushBack(CodeCompletionKindName(static_cast<CodeCompletionKind>(i)));
        }

    protected:
        core::Float2 MeasureContent(core::Float2) override
        {
            // As wide as its widest rows (of the first few), within bounds; as tall as ten rows.
            f32 widest = 0.0f;
            const usize measured = core::Min<usize>(m_shown.Size(), 50);
            for (usize i = 0; i < measured; ++i)
                widest = core::Max(widest, RowFor(i).Width);
            const f32 rows = static_cast<f32>(core::Min(m_shown.Size(), kRowsShown));
            return core::Float2{core::Clamp(widest, kMinWidth, kMaxWidth), rows * RowHeight()};
        }
        void OnLayout() override
        {
            // Not the base's: it has no children; what it scrolls over is its rows.
            const Rect content = GetContentBounds();
            SetScrollExtent(core::Float2{content.width, static_cast<f32>(m_shown.Size()) * RowHeight()});
        }
        void OnTextStyleChange() override
        {
            m_styleText = [this](Text& text)
            {
                text.SetFont(GetFont());
                text.SetFontSelection(GetFontService(), GetTextStyle().FontFamily.AsView(), GetTextStyle().Selection);
                text.SetColor(GetTextColor());
                text.SetWhiteSpace(TextWhiteSpace::Pre);
                text.SetDirection(ParagraphDirection{fonts::TextDirection::LeftToRight, false});
            };
            m_styleText(m_measure);
            m_measure.SetString(core::StringView(u8"M"));
            m_rows.Clear();
            RequestLayout();
            Invalidate();
        }
        void OnPartStyleChange(core::StringView part) override
        {
            UIWidget::OnPartStyleChange(part);
            m_rows.Clear();
            Invalidate();
        }
        void OnDraw(DrawContext& ctx, const Rect& localBounds) override
        {
            UIWidget::OnDraw(ctx, localBounds);
            if (m_shown.IsEmpty())
                return;
            const Rect content = GetContentBounds();
            const f32 rh = RowHeight();
            const f32 top = ScrollShift().y;
            const usize first = static_cast<usize>(core::Max(0.0f, top / rh));
            const usize last = core::Min(m_shown.Size() - 1, static_cast<usize>(core::Max(0.0f, (top + content.height) / rh)));
            const PartStyle& selected = GetPartStyle(u8"selected");
            Color selectedColor = selected.HasBackground ? selected.Box.BackgroundColor : Color{0.17f, 0.24f, 0.36f, 1.0f};
            selectedColor.a *= selected.Opacity;
            ctx.PushClip(content);
            for (usize i = first; i <= last; ++i)
            {
                const f32 y = content.y + static_cast<f32>(i) * rh - top;
                if (i == m_selected)
                    ctx.VG().FillRect(Rectangle{content.x, y, content.width, rh}, selectedColor);
                const Row& row = RowFor(i);
                const auto draw = [&](const Text& text, f32 x)
                {
                    const TextLayout& layout = text.LayoutFor(Rect{});
                    text.DrawLayout(ctx, layout, core::Float2{x, y + (rh - layout.Height) * 0.5f});
                };
                draw(row.Mark, content.x + kPad);
                draw(row.Label, content.x + kPad + row.MarkWidth + kPad);
                // The detail at the end, where it clears the label.
                const f32 labelEnd = content.x + kPad + row.MarkWidth + kPad + row.LabelWidth;
                const f32 detailX = content.x + content.width - kPad - row.DetailWidth;
                if (row.DetailWidth > 0.0f && detailX >= labelEnd + kPad * 2.0f)
                    draw(row.Detail, detailX);
            }
            ctx.PopClip();
        }
        void OnMouseDown(const MouseEvent& event) override
        {
            if (event.Button != MouseButton::Left || m_shown.IsEmpty())
                return;
            event.Handled = true;
            const core::Float2 local = ConvertToNodeSpace(event.Position);
            const f32 row = (local.y - GetContentBounds().y + ScrollShift().y) / RowHeight();
            if (row < 0.0f || static_cast<usize>(row) >= m_shown.Size())
                return;
            SetSelected(static_cast<usize>(row));
            if (m_onPicked)
                m_onPicked(m_selected);
        }

    private:
        static constexpr f32 kPad = 6.0f;
        struct Shown
        {
            u32 Item = 0;
            i32 Score = 0;
        };
        struct Row
        {
            Text Mark;
            Text Label;
            Text Detail;
            f32 MarkWidth = 0.0f;
            f32 LabelWidth = 0.0f;
            f32 DetailWidth = 0.0f;
            f32 Width = 0.0f; // the whole row's, padded
        };

        [[nodiscard]] static core::String ColorTag(Color c)
        {
            char8_t tag[] = u8"[color=#rrggbbaa]";
            const f32 channels[4] = {c.r, c.g, c.b, c.a};
            constexpr char8_t kHex[] = u8"0123456789abcdef";
            for (usize k = 0; k < 4; ++k)
            {
                const u32 v = static_cast<u32>(core::Clamp(channels[k], 0.0f, 1.0f) * 255.0f + 0.5f);
                tag[8 + k * 2] = kHex[v >> 4];
                tag[9 + k * 2] = kHex[v & 15u];
            }
            return core::String(core::StringView(tag, sizeof(tag) - 1));
        }
        [[nodiscard]] Color PartText(core::StringView part, Color fallback) const
        {
            const PartStyle& style = GetPartStyle(part);
            return style.HasColor ? style.TextColor : fallback;
        }
        // Its shown row `index`, made as it is first drawn or measured.
        const Row& RowFor(usize index) const
        {
            while (m_rows.Size() < m_shown.Size())
                m_rows.PushBack(core::UniquePtr<Row>{});
            core::UniquePtr<Row>& slot = m_rows[index];
            if (slot)
                return *slot;
            slot = core::MakeUnique<Row>(const_cast<CodeCompletionList*>(this)->MemoryAllocator());
            Row& row = *slot;
            const CodeCompletionItem& item = ShownItem(index);
            if (m_styleText)
            {
                m_styleText(row.Mark);
                m_styleText(row.Label);
                m_styleText(row.Detail);
            }
            row.Mark.SetColor(PartText(CodeCompletionKindName(item.Kind), GetTextColor()));
            row.Mark.SetString(CodeCompletionKindMark(item.Kind));
            // The label, its matched letters in the match part's colour ("[[" a "[").
            core::Array<u32> matched(const_cast<CodeCompletionList*>(this)->MemoryAllocator());
            (void)CodeFuzzyMatch(m_prefix.AsView(), item.Label.AsView(), &matched);
            const core::String open = ColorTag(PartText(core::StringView(u8"match"), GetTextColor()));
            core::String markup;
            const core::StringView label = item.Label.AsView();
            usize next = 0;
            for (usize i = 0; i < label.Size(); ++i)
            {
                const bool hit = next < matched.Size() && matched[next] == i;
                if (hit)
                {
                    markup.Append(open.AsView());
                    ++next;
                }
                markup.Append(label[i] == u8'[' ? core::StringView(u8"[[") : label.SubStr(i, 1));
                if (hit)
                    markup.Append(core::StringView(u8"[/color]"));
            }
            row.Label.SetMarkup(markup.AsView());
            row.Detail.SetColor(PartText(core::StringView(u8"detail"), GetTextColor()));
            row.Detail.SetString(item.Detail.AsView());
            row.MarkWidth = core::Max(row.Mark.LayoutFor(Rect{}).Width, m_measure.LayoutFor(Rect{}).Width);
            row.LabelWidth = row.Label.LayoutFor(Rect{}).Width;
            row.DetailWidth = item.Detail.IsEmpty() ? 0.0f : row.Detail.LayoutFor(Rect{}).Width;
            row.Width = kPad + row.MarkWidth + kPad + row.LabelWidth + (row.DetailWidth > 0.0f ? kPad * 3.0f + row.DetailWidth : 0.0f) + kPad;
            return row;
        }
        void ScrollToSelected()
        {
            const f32 rh = RowHeight();
            const f32 top = static_cast<f32>(m_selected) * rh;
            const f32 view = GetContentBounds().height;
            const core::Float2 offset = GetScrollOffset();
            if (top < offset.y)
                SetScrollOffset(core::Float2{offset.x, top});
            else if (top + rh > offset.y + view)
                SetScrollOffset(core::Float2{offset.x, top + rh - view});
        }

        core::Array<CodeCompletionItem> m_items;
        core::Array<Shown> m_shown;
        mutable core::Array<core::UniquePtr<Row>> m_rows; // by shown index
        core::String m_prefix;
        usize m_selected = 0;
        Text m_measure; // one wide letter: the kind's column
        core::Function<void(Text&)> m_styleText;
        core::Function<void(usize)> m_onPicked;
        core::Function<void(usize)> m_onSelected;
    };
}
