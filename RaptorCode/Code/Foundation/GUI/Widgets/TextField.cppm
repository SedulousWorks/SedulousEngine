// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :text_field partition
//
// TextField: a single-line, editable text control (E4 of Specs/gui-lab-evolution.md), over the
// editing model and keys TextEditBase gives it. Modeled on eepp's UITextInput (role only). Its text
// sits on one line, centred down its height, and scrolls across to keep the caret in view; Return
// submits it (the `submit` event, its value committing as `change`). It may mask its text as a
// password: a bullet for each character, copying and cutting taking nothing out, no IME composition.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:text_field;

import foundation.core; // Float2, Max, Min
import :rect;
import :text;
import :commands; // CommandEvent
import :text_editing_keys; // kTextSubmitCommand
import :text_edit_base;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    class TextField : public TextEditBase
    {
        RTTI_OBJECT(TextField, TextEditBase)
    public:
        TextField()
        {
            SetTag(core::StringView(u8"textfield"));
            ShownText().SetWhiteSpace(TextWhiteSpace::Pre); // its spaces as typed, on one line
            ShownText().SetAlignment(TextHAlign::Start, TextVAlign::Middle);
            HintText().SetAlignment(TextHAlign::Start, TextVAlign::Middle);
            {
                StyleWriteScope defaults(*this);
                SetTextAlignment(TextHAlign::Start, TextVAlign::Middle);
            }
            (void)OnCommand(core::StringView(kTextSubmitCommand), [this](CommandEvent&) { Submit(); });
        }

        /// A password field draws a bullet for each character and lets nothing out by copy or cut.
        void SetPassword(bool password)
        {
            if (password == m_password)
                return;
            m_password = password;
            GetModel().SetCopyAllowed(!password);
            Synced();
        }
        [[nodiscard]] bool IsPassword() const noexcept { return m_password; }

        /// How far its text is scrolled across from its inline start (to keep the caret in view):
        /// from the left in a left-to-right line, from the right in a right-to-left one.
        [[nodiscard]] f32 GetScrollX() const noexcept { return m_scrollX; }

        /// One line of its font, a field's usual width, when nothing sizes it (E2).
        [[nodiscard]] core::Float2 MeasureContent(core::Float2) override
        {
            return core::Float2{160.0f, (ShownText().GetFont() != nullptr) ? ShownText().GetLineHeight() : 20.0f};
        }
        /// Its line's baseline, where it draws its value (and its placeholder, in the same font).
        [[nodiscard]] f32 BaselineAt(core::Float2 size) const override
        {
            const Thickness c = GetChrome();
            return ShownText().FirstBaseline(Rect{c.Left, c.Top, core::Max(0.0f, size.x - c.TotalHorizontal()),
                                                  core::Max(0.0f, size.y - c.TotalVertical())});
        }

    protected:
        [[nodiscard]] bool IsMasked() const override { return m_password; }
        [[nodiscard]] const TextLayout& EditLayout() const override { return ShownText().LayoutFor(Rect{}); } // one line, unbounded
        // The layout's origin (E17a): a line shorter than the field where its alignment puts it,
        // resolved against the line's own direction (start is the right in a right-to-left one); a
        // longer one scrolled from its inline start. Its line is centred down it.
        [[nodiscard]] core::Float2 TextOrigin(const Rect& content) const override
        {
            const core::Float2 origin = ShownText().Origin(Rect{content.x, content.y, 0.0f, content.height});
            const TextLayout& layout = EditLayout();
            const f32 view = View(content);
            if (layout.Width <= view)
                return core::Float2{origin.x + Slack(layout, view - layout.Width), origin.y};
            return core::Float2{origin.x - ScrollFromLeft(layout, view), origin.y};
        }
        // Scrolls by the least that shows the caret, and no further than the text needs.
        void KeepCaretInView() override
        {
            const TextLayout& layout = EditLayout();
            const f32 view = View(EditBounds());
            const f32 caret = layout.CaretX(DisplayCaret());
            const f32 before = m_scrollX;
            f32 left = ScrollFromLeft(layout, view);
            if (caret - left > view)
                left = caret - view;
            if (caret < left)
                left = caret;
            const f32 range = core::Max(0.0f, layout.Width - view);
            left = core::Clamp(left, 0.0f, range);
            m_scrollX = RunsRightToLeft(layout) ? range - left : left;
            if (m_scrollX != before)
                Invalidate();
        }

    private:
        [[nodiscard]] static f32 View(const Rect& content) { return core::Max(0.0f, content.width - kCaretWidth); }
        // The line's paragraph runs right to left (the field's own way while it is empty).
        [[nodiscard]] bool RunsRightToLeft(const TextLayout& layout) const
        {
            return layout.Lines.IsEmpty() ? IsRightToLeft() : layout.Lines[0].RightToLeft;
        }
        // The scroll as the layout moves left, from the inline-start scroll it keeps.
        [[nodiscard]] f32 ScrollFromLeft(const TextLayout& layout, f32 view) const
        {
            const f32 range = core::Max(0.0f, layout.Width - view);
            const f32 fromStart = core::Clamp(m_scrollX, 0.0f, range);
            return RunsRightToLeft(layout) ? range - fromStart : fromStart;
        }
        // How far a short line sits from the left, of the `slack` it leaves.
        [[nodiscard]] f32 Slack(const TextLayout& layout, f32 slack) const
        {
            TextHAlign align = ShownText().GetHAlign();
            if (align == TextHAlign::Start)
                align = RunsRightToLeft(layout) ? TextHAlign::Right : TextHAlign::Left;
            else if (align == TextHAlign::End)
                align = RunsRightToLeft(layout) ? TextHAlign::Left : TextHAlign::Right;
            return align == TextHAlign::Center ? slack * 0.5f : align == TextHAlign::Right ? slack : 0.0f;
        }

    private:
        f32 m_scrollX = 0.0f;
        bool m_password = false;
    };
}
