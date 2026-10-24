// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :label partition
//
// Label: a UIWidget that displays text. It composes the Text primitive (drawn in the
// padding-inset content bounds) onto the widget base; modeled on eepp's UITextView (role, not a
// line-for-line port). Its text is shaped and laid out by :text_layout (E4): it wraps as its
// white-space says, takes line-height and letter-spacing, ends an overflowing line as its
// text-overflow says and clamps its lines; a rich label's text is markup, its links events.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:label;

import foundation.core;  // StringView, Color, Float2
import foundation.fonts; // CachedFont
import :reactive; // Observable (what bindings follow)
import :rect;
import :draw_context;
import :text;
import :ui_widget;
import :layout_style; // kUnbounded
import :event;        // LinkEvent

using namespace foundation::core;
namespace core = foundation::core;
namespace fonts = foundation::fonts;

export namespace foundation::gui
{
    /// CSS's text-overflow keyword for `overflow` ("clip", "ellipsis", "ellipsis-start", "ellipsis-middle").
    [[nodiscard]] inline core::StringView TextOverflowName(TextOverflow overflow) noexcept
    {
        switch (overflow)
        {
        case TextOverflow::Ellipsis: return core::StringView(u8"ellipsis");
        case TextOverflow::EllipsisStart: return core::StringView(u8"ellipsis-start");
        case TextOverflow::EllipsisMiddle: return core::StringView(u8"ellipsis-middle");
        default: return core::StringView(u8"clip");
        }
    }
    /// The overflow a keyword names (clip for one it does not know).
    [[nodiscard]] inline TextOverflow TextOverflowNamed(core::StringView name) noexcept
    {
        if (name == core::StringView(u8"ellipsis"))
            return TextOverflow::Ellipsis;
        if (name == core::StringView(u8"ellipsis-start"))
            return TextOverflow::EllipsisStart;
        if (name == core::StringView(u8"ellipsis-middle"))
            return TextOverflow::EllipsisMiddle;
        return TextOverflow::Clip;
    }

    class Label : public UIWidget
    {
        RTTI_OBJECT(Label, UIWidget)
    public:
        Label()
        {
            SetTag(core::StringView(u8"label"));
            StyleWriteScope defaults(*this); // its own values, which a sheet returns to
            SetTextAlignment(TextHAlign::Start, TextVAlign::Middle);
        }

        /// Its text: plain, or a rich text's markup when it is rich (SetRich).
        /// The bytes of its text an access key is (E12): underlined while access keys show; start ==
        /// end for none. Its button sets it, having taken the `&` out.
        void SetMnemonicRange(usize start, usize end)
        {
            m_mnemonicStart = start;
            m_mnemonicEnd = end;
            if (end <= start)
                m_text.SetUnderline(0, 0);
            Invalidate();
        }
        void SetText(core::StringView text)
        {
            if (text == m_text.GetString())
                return;
            if (m_rich)
                m_text.SetMarkup(text);
            else
                m_text.SetString(text);
            RequestLayout(); // its size follows its text
            Invalidate();
            m_textChanged.Notify();
        }
        /// The text (a read a binding records).
        [[nodiscard]] core::StringView GetText() const
        {
            m_textChanged.Track();
            return m_text.GetString();
        }

        /// A rich label's text is markup: runs in their own colours, sizes, faces and effects,
        /// underlines, inline icons and links (:text_runs), a click on a link reported as a `link`
        /// event with its id. Markup's `rich="true"`, or the RichText element.
        void SetRich(bool rich)
        {
            if (rich == m_rich)
                return;
            m_rich = rich;
            const core::String text(m_text.GetString());
            if (rich)
                m_text.SetMarkup(text.AsView());
            else
                m_text.SetString(text.AsView());
            RequestLayout();
            Invalidate();
        }
        [[nodiscard]] bool IsRich() const noexcept { return m_rich; }

        // Markup: <Label text="Hello" rich="true">.
        bool SetMarkupAttribute(core::StringView name, core::StringView value) override
        {
            if (name == core::StringView(u8"text"))
            {
                SetText(value);
                return true;
            }
            if (name == core::StringView(u8"rich"))
            {
                SetRich(value == core::StringView(u8"true"));
                return true;
            }
            return UIWidget::SetMarkupAttribute(name, value);
        }

        /// CSS's text-overflow: what shows where a line passes the label's width (clip, or an
        /// ellipsis at its end, start or middle). Not inherited.
        void SetTextOverflow(TextOverflow overflow)
        {
            m_text.SetOverflow(overflow);
            Invalidate();
        }
        [[nodiscard]] TextOverflow GetTextOverflow() const noexcept { return m_text.GetOverflow(); }
        void SetTextOverflowName(const core::String& name) { SetTextOverflow(TextOverflowNamed(Trim(name.AsView()))); }
        [[nodiscard]] core::String GetTextOverflowName() const { return core::String(TextOverflowName(GetTextOverflow())); }
        /// CSS's line-clamp: the most lines it shows, the last ending in an ellipsis when its
        /// text-overflow has one (0: all). Not inherited.
        void SetLineClamp(i32 lines)
        {
            m_text.SetMaxLines(static_cast<u32>(core::Max(0, lines)));
            RequestLayout();
            Invalidate();
        }
        [[nodiscard]] i32 GetLineClamp() const noexcept { return static_cast<i32>(m_text.GetMaxLines()); }

        // The natural size of the text (for layout).
        [[nodiscard]] core::Float2 MeasureText() const { return m_text.Measure(); }
        /// Its text's size (E2, E4): shaped, on one line, or wrapped to the width available where
        /// its white-space wraps (its longest word when no width is given), clamped to its lines.
        [[nodiscard]] core::Float2 MeasureContent(core::Float2 available) override
        {
            SyncServices();
            if (m_text.GetFont() == nullptr || m_text.IsEmpty())
                return core::Float2{0.0f, (m_text.GetFont() != nullptr) ? m_text.GetLineHeight() : 0.0f};
            return m_text.MeasureWrapped(available.x);
        }
        /// Its text's first baseline, where it draws it in the content box.
        [[nodiscard]] f32 BaselineAt(core::Float2 size) const override
        {
            const Thickness c = GetChrome();
            return m_text.FirstBaseline(Rect{c.Left, c.Top, core::Max(0.0f, size.x - c.TotalHorizontal()),
                                             core::Max(0.0f, size.y - c.TotalVertical())});
        }
        // The size wrapped text occupies at `maxWidth` (widest line x total height).
        [[nodiscard]] core::Float2 MeasureWrapped(f32 maxWidth) const { return m_text.MeasureWrapped(maxWidth); }
        /// What it lays out and draws.
        [[nodiscard]] const Text& GetTextLayout() const noexcept { return m_text; }

    protected:
        // Its text draws in its text style (its own, a sheet's, or what it inherits).
        void OnTextStyleChange() override
        {
            const TextStyle& style = GetTextStyle();
            m_text.SetFont(GetFont());
            m_text.SetFontSelection(GetFontService(), GetTextStyle().FontFamily.AsView(), GetTextStyle().Selection);
            m_text.SetColor(GetTextColor());
            m_text.SetAlignment(GetTextAlignH(), GetTextAlignV());
            m_text.SetDirection(TextDirectionFor());
            m_text.SetWhiteSpace(style.WhiteSpace);
            m_text.SetLineHeight(style.LineHeightPixels());
            m_text.SetLetterSpacing(style.LetterSpacing);
            m_text.SetBreakWords(style.BreakWords);
        }

        /// Its box and, unless it clips it, its text where it is laid out (a line past the box).
        [[nodiscard]] Rect GetInkBounds() const override
        {
            const Rect ink = UIWidget::GetInkBounds();
            if (ClipsChildren() || !m_text.HasFont() || m_text.IsEmpty())
                return ink;
            const Rect bounds = GetContentBounds();
            const TextLayout& layout = m_text.LayoutFor(bounds);
            const core::Float2 origin = m_text.Origin(bounds);
            return Rect::Union(ink, Rect{origin.x, origin.y, core::Max(layout.Width, bounds.width), layout.Height});
        }

        void OnDraw(DrawContext& ctx, const Rect& localBounds) override
        {
            (void)localBounds;
            SyncServices();
            // An access key underlined while access keys show (E12).
            if (m_mnemonicEnd > m_mnemonicStart)
            {
                const bool shown = AreMnemonicsShown();
                m_text.SetUnderline(shown ? m_mnemonicStart : 0, shown ? m_mnemonicEnd : 0);
            }
            // Overflow other than visible clips its own text too, as CSS's does an element's content.
            const bool clip = ClipsChildren();
            if (clip)
                ctx.PushClip(GetLocalBounds());
            m_text.Draw(ctx, GetContentBounds()); // aligned within the padding-inset bounds
            if (clip)
                ctx.PopClip();
        }

        // Over a rich text's link the pointer shows the hand (E11), as a browser's does.
        [[nodiscard]] Cursor GetCursorNow() const override { return m_overLink ? Cursor::Pointer : UIWidget::GetCursorNow(); }
        void OnMouseMove(const MouseEvent& event) override
        {
            m_overLink = m_rich && m_text.LinkAt(GetContentBounds(), ConvertToNodeSpace(event.Position)).Size() != 0;
        }
        void OnMouseLeave(const MouseEvent&) override { m_overLink = false; }

        // A click on a rich text's link reports it.
        void OnMouseClick(const MouseEvent& event) override
        {
            if (!m_rich)
                return;
            const core::StringView link = m_text.LinkAt(GetContentBounds(), ConvertToNodeSpace(event.Position));
            if (link.Size() == 0)
                return;
            event.Handled = true;
            const core::String id(link); // the event outlives no relayout
            SendEvent(LinkEvent(this, id.AsView()));
        }

        // The GUI's fonts and resources, which a rich text's own faces and icons need.
        void SyncServices()
        {
            if (!m_rich)
                return;
            m_text.SetFontService(GetFontService());
            m_text.SetResourceProvider(GetResourceProvider());
        }

        Text m_text;
        bool m_rich = false;
        bool m_overLink = false; // the pointer is over one of its links
        usize m_mnemonicStart = 0; // the access key's bytes, underlined while access keys show
        usize m_mnemonicEnd = 0;
        Observable m_textChanged; // what bindings reading the text follow
    };

    /// A label whose text is markup (Label with rich on), for markup's <RichText text="...">.
    class RichText : public Label
    {
        RTTI_OBJECT(RichText, Label)
    public:
        RichText()
        {
            SetTag(core::StringView(u8"richtext"));
            SetRich(true);
        }
    };
}
