// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :number_field partition
//
// NumberField: a number typed, stepped or scrubbed (E6 of Specs/gui-lab-evolution.md), on E4's
// field core with a RangeValue, after Godot's SpinBox and LunarSong's drag fields.
//
// - Its text is its value, written with the step's decimals (none for an `integer` field), between
//   its `prefix` and `suffix`.
// - Typed, the text is read as an expression when it commits (Return, or focus leaving): numbers,
//   + - * /, parentheses; then snapped to the step and kept in the range (unless allowed past it).
//   Text that is no number goes back to the value it had.
// - Not yet being edited, a press and a drag across scrubs it (past a few pixels; Shift fine, Ctrl
//   coarse), reporting `input` as it goes and `change` on release; a press let go without a drag
//   starts editing, all of it selected.
// - Its arrows (repeat buttons, the button core's) step it, as do Up and Down (Page Up and Down a
//   page) and the wheel while it is focused.
// - A value set from code reports nothing but to bindings, as a range's does.
// - Mixed (several objects' values differing, a property grid's): no number shows, its placeholder
//   does, and whatever the user does next sets one, even the value it holds.
// - Escape during a scrub puts the value back as it was before the press and reports the cancel.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:number_field;

import foundation.core; // String, Format, Optional, Float2, Max, Min, Abs, Function
import foundation.vg;   // PathBuilder
import :reactive;       // Observable
import :rect;
import :event;
import :draw_context;
import :node_box;
import :layout_style;
import :ui_widget;
import :button_base;
import :range_value;
import :text_field;
import :event_dispatcher; // CapturePointer (a scrub)

using namespace foundation::core;
namespace core = foundation::core;
namespace vg = foundation::vg;

export namespace foundation::gui
{
    namespace detail
    {
        // At namespace scope, not local to EvaluateExpression: clang does not emit the members
        // of a class local to an exported inline function for its importers.
        struct ExpressionParser
        {
            core::StringView s;
            usize i = 0;
            bool ok = true;
            void Skip()
            {
                while (i < s.Size() && (s[i] == u8' ' || s[i] == u8'\t'))
                    ++i;
            }
            f64 Primary()
            {
                Skip();
                if (i < s.Size() && (s[i] == u8'-' || s[i] == u8'+'))
                {
                    const bool negative = s[i++] == u8'-';
                    const f64 v = Primary();
                    return negative ? -v : v;
                }
                if (i < s.Size() && s[i] == u8'(')
                {
                    ++i;
                    const f64 v = Sum();
                    Skip();
                    if (i < s.Size() && s[i] == u8')')
                        ++i;
                    else
                        ok = false;
                    return v;
                }
                const usize start = i;
                while (i < s.Size() && ((s[i] >= u8'0' && s[i] <= u8'9') || s[i] == u8'.'))
                    ++i;
                const Optional<f64> v = i > start ? core::ParseFloat(s.SubStr(start, i - start)) : Optional<f64>{};
                if (!v.HasValue())
                {
                    ok = false;
                    return 0.0;
                }
                return v.Value();
            }
            f64 Product()
            {
                f64 v = Primary();
                for (;;)
                {
                    Skip();
                    if (i >= s.Size() || (s[i] != u8'*' && s[i] != u8'/'))
                        return v;
                    const bool divide = s[i++] == u8'/';
                    const f64 r = Primary();
                    if (divide && r == 0.0)
                        ok = false;
                    v = divide ? (r != 0.0 ? v / r : 0.0) : v * r;
                }
            }
            f64 Sum()
            {
                f64 v = Product();
                for (;;)
                {
                    Skip();
                    if (i >= s.Size() || (s[i] != u8'+' && s[i] != u8'-'))
                        return v;
                    const bool minus = s[i++] == u8'-';
                    const f64 r = Product();
                    v = minus ? v - r : v + r;
                }
            }
        };
    }

    /// `text` read as arithmetic: numbers (with a decimal point), + - * /, unary minus and
    /// parentheses; none when it is not one (or divides by zero).
    [[nodiscard]] inline Optional<f64> EvaluateExpression(core::StringView text)
    {
        detail::ExpressionParser p{text};
        const f64 v = p.Sum();
        p.Skip();
        if (!p.ok || p.i != text.Size() || text.Size() == 0)
            return {};
        return v;
    }

    /// A number field's arrow: a repeat button acting on the press, its triangle the
    /// `spinbutton::arrow` part's background colour.
    class SpinButton : public ButtonBase
    {
        RTTI_OBJECT(SpinButton, ButtonBase)
    public:
        explicit SpinButton(bool up) : m_up(up)
        {
            SetTag(core::StringView(u8"spinbutton"));
            AddClass(core::StringView(up ? u8"up" : u8"down"));
            SetTabFocusable(false); // the field keeps the focus
            SetRepeat(true);
            SetRepeatDelay(0.4f);
            SetRepeatInterval(0.06f);
        }
        [[nodiscard]] bool IsUp() const noexcept { return m_up; }

        void CollectStyleParts(core::Array<core::StringView>& out) const override { out.PushBack(core::StringView(u8"arrow")); }

    protected:
        void OnDraw(DrawContext& ctx, const Rect& localBounds) override
        {
            (void)localBounds;
            const Rect b = GetContentBounds();
            const PartStyle& arrow = GetPartStyle(u8"arrow");
            Color color = arrow.HasBackground ? arrow.Box.BackgroundColor : Color{0.70f, 0.74f, 0.80f, 1.0f};
            color.a *= arrow.Opacity;
            const f32 w = core::Min(8.0f, b.width * 0.6f), h = w * 0.55f;
            const f32 x = b.x + (b.width - w) * 0.5f, y = b.y + (b.height - h) * 0.5f;
            vg::PathBuilder pb;
            if (m_up)
            {
                pb.MoveTo(x, y + h);
                pb.LineTo(x + w, y + h);
                pb.LineTo(x + w * 0.5f, y);
            }
            else
            {
                pb.MoveTo(x, y);
                pb.LineTo(x + w, y);
                pb.LineTo(x + w * 0.5f, y + h);
            }
            pb.Close();
            ctx.VG().FillPath(pb.ToPath(), color);
        }

    private:
        bool m_up;
    };

    class NumberField : public TextField
    {
        RTTI_OBJECT(NumberField, TextField)
    public:
        NumberField()
        {
            SetTag(core::StringView(u8"numberfield"));
            NumberField* self = this;
            m_up = core::MakeRef<SpinButton>(MemoryAllocator(), true);
            m_down = core::MakeRef<SpinButton>(MemoryAllocator(), false);
            m_up->SetOnClick([self]() { self->StepBy(1.0); });
            m_down->SetOnClick([self]() { self->StepBy(-1.0); });
            AddChild(m_up.Get());
            AddChild(m_down.Get());
            m_range.Max = 100.0;
            m_range.Step = 1.0;
            ShowValue();
        }

        // === Value ===
        /// The value (a read a binding records).
        [[nodiscard]] f64 GetValue() const
        {
            m_valueChanged.Track();
            return m_range.Value;
        }
        /// Sets the value from code: constrained, shown, reported to bindings, no events.
        void SetValue(f64 value)
        {
            m_mixed = false;
            m_commitAlways = false;
            if (Apply(value))
                m_committedValue = m_range.Value;
            ShowValue();
        }
        [[nodiscard]] f64 GetMin() const noexcept { return m_range.Min; }
        void SetMin(f64 min) { EditRange([&](RangeValue& r) { r.Min = min; }); }
        [[nodiscard]] f64 GetMax() const noexcept { return m_range.Max; }
        void SetMax(f64 max) { EditRange([&](RangeValue& r) { r.Max = max; }); }
        [[nodiscard]] f64 GetStep() const noexcept { return m_range.Step; }
        void SetStep(f64 step) { EditRange([&](RangeValue& r) { r.Step = step < 0.0 ? 0.0 : step; }); }
        /// Page Up and Down's step (0: a tenth of the range).
        [[nodiscard]] f64 GetPage() const noexcept { return m_range.Page; }
        void SetPage(f64 page) { EditRange([&](RangeValue& r) { r.Page = page < 0.0 ? 0.0 : page; }); }
        [[nodiscard]] bool AllowsGreater() const noexcept { return m_range.AllowGreater; }
        void SetAllowGreater(bool allow) { EditRange([&](RangeValue& r) { r.AllowGreater = allow; }); }
        [[nodiscard]] bool AllowsLesser() const noexcept { return m_range.AllowLesser; }
        void SetAllowLesser(bool allow) { EditRange([&](RangeValue& r) { r.AllowLesser = allow; }); }
        /// Whole numbers only: snapped to them and written without decimals.
        [[nodiscard]] bool IsInteger() const noexcept { return m_integer; }
        void SetInteger(bool integer)
        {
            m_integer = integer;
            SetValue(m_range.Value);
        }
        [[nodiscard]] const RangeValue& GetRange() const noexcept { return m_range; }

        /// Text before and after the number ("$", " px").
        void SetPrefix(const core::String& prefix)
        {
            m_prefix = prefix;
            ShowValue();
        }
        [[nodiscard]] core::String GetPrefix() const { return m_prefix; }
        void SetSuffix(const core::String& suffix)
        {
            m_suffix = suffix;
            ShowValue();
        }
        [[nodiscard]] core::String GetSuffix() const { return m_suffix; }

        // Markup's prefix and suffix as written: a suffix's leading space is part of it.
        bool SetMarkupAttribute(core::StringView name, core::StringView value) override
        {
            if (name == core::StringView(u8"prefix"))
                SetPrefix(core::String(value));
            else if (name == core::StringView(u8"suffix"))
                SetSuffix(core::String(value));
            else
                return TextField::SetMarkupAttribute(name, value);
            return true;
        }

        /// Each change the user makes, as it goes (a scrub's steps).
        void SetOnValueChanging(core::Function<void(f64)> callback) { m_onChanging = core::Move(callback); }
        /// A change the user committed (a typed value, a step, a scrub's release).
        void SetOnValueChanged(core::Function<void(f64)> callback) { m_onChanged = core::Move(callback); }

        /// Neither value shown: the values it stands for differ. Set after SetValue, which clears it.
        void SetMixed(bool mixed)
        {
            if (m_mixed == mixed)
                return;
            m_mixed = mixed;
            m_commitAlways = false;
            m_committedValue = m_range.Value;
            ShowValue();
        }
        [[nodiscard]] bool IsMixed() const noexcept { return m_mixed; }
        /// Whether the wheel steps it while it is focused (on); off, the wheel goes on to what scrolls.
        void SetStepsOnWheel(bool steps) noexcept { m_stepsOnWheel = steps; }
        [[nodiscard]] bool StepsOnWheel() const noexcept { return m_stepsOnWheel; }
        /// A scrub given up with Escape: the value is back as it was before it.
        void SetOnValueCancelled(core::Function<void()> callback) { m_onCancelled = core::Move(callback); }

        /// Being edited as text (typed into, or a press let go on it); otherwise a press scrubs.
        [[nodiscard]] bool IsEditing() const noexcept { return m_editing; }
        [[nodiscard]] SpinButton* GetUpButton() const noexcept { return m_up.Get(); }
        [[nodiscard]] SpinButton* GetDownButton() const noexcept { return m_down.Get(); }

        /// The value as it is written: the step's decimals, between the prefix and the suffix.
        [[nodiscard]] core::String FormatValue(f64 value) const
        {
            const i32 decimals = m_integer ? 0 : m_range.Decimals();
            f64 scale = 1.0;
            for (i32 d = 0; d < decimals; ++d)
                scale *= 10.0;
            const f64 rounded = static_cast<f64>(static_cast<i64>(value * scale + (value < 0.0 ? -0.5 : 0.5))) / scale;
            core::String text(m_prefix);
            if (decimals == 0)
                text += core::Format(u8"{}", static_cast<i64>(rounded)).AsView();
            else
                text += core::Format(u8"{}", rounded).AsView();
            text += m_suffix.AsView();
            return text;
        }

    protected:
        // The text read as an expression; a number committed, else the old value back.
        void OnCommitting() override
        {
            core::StringView text = Trim(GetModel().GetText());
            if (m_prefix.Size() != 0 && text.Size() >= m_prefix.Size() && text.SubStr(0, m_prefix.Size()) == m_prefix.AsView())
                text = Trim(text.SubStr(m_prefix.Size(), text.Size() - m_prefix.Size()));
            if (m_suffix.Size() != 0 && text.Size() >= m_suffix.Size() &&
                text.SubStr(text.Size() - m_suffix.Size(), m_suffix.Size()) == m_suffix.AsView())
                text = Trim(text.SubStr(0, text.Size() - m_suffix.Size()));
            if (const Optional<f64> v = EvaluateExpression(text); v.HasValue())
                ChangeByUser(v.Value(), false);
            else if (m_mixed)
                return; // nothing typed into a mixed field: still mixed
            ShowValue();
            CommitValue();
        }

        void OnKeyDown(const KeyEvent& event) override
        {
            if (event.Target == this && event.Modifiers == 0 && IsTreeEnabled())
            {
                const KeyCode key = static_cast<KeyCode>(event.KeyCode);
                if (key == KeyCode::Escape && m_pressing)
                {
                    CancelScrub();
                    event.Handled = true;
                    return;
                }
                f64 by = 0.0;
                if (key == KeyCode::Up)
                    by = m_range.KeyStep();
                else if (key == KeyCode::Down)
                    by = -m_range.KeyStep();
                else if (key == KeyCode::PageUp)
                    by = m_range.PageStep();
                else if (key == KeyCode::PageDown)
                    by = -m_range.PageStep();
                if (by != 0.0)
                {
                    StepValue(by);
                    event.Handled = true;
                    return;
                }
                if (key == KeyCode::Space || (key >= KeyCode::A && key <= KeyCode::Num9))
                    m_editing = true; // typing into it
            }
            TextField::OnKeyDown(event);
        }
        void OnTextInput(const TextInputEvent& event) override
        {
            m_editing = true;
            TextField::OnTextInput(event);
        }
        void OnMouseWheel(const WheelEvent& event) override
        {
            if (!m_stepsOnWheel || !IsFocused() || event.Delta.y == 0.0f)
                return;
            StepValue(m_range.KeyStep() * static_cast<f64>(event.Delta.y));
            event.Handled = true;
        }

        void OnMouseDown(const MouseEvent& event) override
        {
            if (m_editing || event.Button != MouseButton::Left)
            {
                TextField::OnMouseDown(event);
                return;
            }
            // Not editing: a press may become a scrub, or a click that starts editing.
            RequestFocus();
            event.Handled = true;
            m_pressing = true;
            m_scrubbing = false;
            m_pressX = event.Position.x;
            m_scrubFrom = m_range.Value;
            m_scrubFromMixed = m_mixed;
        }
        void OnMouseMove(const MouseEvent& event) override
        {
            if (!m_pressing)
            {
                TextField::OnMouseMove(event);
                return;
            }
            // Toward the inline end raises it, as a slider's does.
            const f32 dx = (event.Position.x - m_pressX) * (IsRightToLeft() ? -1.0f : 1.0f);
            if (!m_scrubbing && core::Abs(dx) < kScrubThreshold)
                return;
            m_scrubbing = true;
            // A step per few pixels; Shift a tenth as fast, Ctrl ten times.
            f64 rate = (m_range.Step > 0.0 ? m_range.Step : (m_range.Max - m_range.Min) / 200.0) / kPixelsPerStep;
            if ((event.Modifiers & KeyModShift) != 0)
                rate *= 0.1;
            if ((event.Modifiers & KeyModCtrl) != 0)
                rate *= 10.0;
            ChangeByUser(m_scrubFrom + static_cast<f64>(dx) * rate, true);
            ShowValue();
        }
        void OnMouseUp(const MouseEvent& event) override
        {
            if (!m_pressing)
            {
                TextField::OnMouseUp(event);
                return;
            }
            m_pressing = false;
            if (m_scrubbing)
            {
                m_scrubbing = false;
                CommitValue();
                return;
            }
            // A click: editing, all of it selected.
            m_editing = true;
            GetModel().SelectAll();
            Synced();
        }
        void OnPointerCancel(const MouseEvent& event) override
        {
            if (m_scrubbing)
                CommitValue();
            m_pressing = false;
            m_scrubbing = false;
            TextField::OnPointerCancel(event);
        }
        void OnFocusLost() override
        {
            TextField::OnFocusLost(); // commits
            m_editing = false;
        }

        // Its text kept clear of its arrows, at its inline end.
        [[nodiscard]] Rect EditBounds() const override
        {
            const Rect content = GetContentBounds();
            const Thickness b = GetBorderThickness();
            if (IsRightToLeft())
            {
                const f32 left = core::Max(content.x, b.Left + kSpinWidth + kSpinGap);
                return Rect{left, content.y, core::Max(0.0f, content.Right() - left), content.height};
            }
            const f32 right = core::Min(content.Right(), GetSize().x - b.Right - kSpinWidth - kSpinGap);
            return Rect{content.x, content.y, core::Max(0.0f, right - content.x), content.height};
        }

        // Its arrows stacked at its inline end, inside its border.
        void OnLayout() override
        {
            const Thickness b = GetBorderThickness();
            const core::Float2 size = GetSize();
            const f32 h = core::Max(0.0f, size.y - b.TotalVertical());
            const f32 x = IsRightToLeft() ? b.Left : size.x - b.Right - kSpinWidth;
            m_up->Arrange(Rect{x, b.Top, kSpinWidth, h * 0.5f});
            m_down->Arrange(Rect{x, b.Top + h * 0.5f, kSpinWidth, h - h * 0.5f});
        }

    private:
        static constexpr f32 kSpinWidth = 16.0f;
        static constexpr f32 kSpinGap = 2.0f; // between its text and its arrows
        static constexpr f32 kScrubThreshold = 4.0f; // pixels a press moves before it scrubs
        static constexpr f32 kPixelsPerStep = 4.0f;

        bool Apply(f64 value)
        {
            if (m_integer)
                value = static_cast<f64>(static_cast<i64>(value + (value < 0.0 ? -0.5 : 0.5)));
            value = m_range.Constrain(value);
            if (value == m_range.Value && !m_mixed)
                return false;
            m_mixed = false; // the user set one value, whatever it is
            m_range.Value = value;
            m_valueChanged.Notify();
            return true;
        }
        template <typename F>
        void EditRange(F&& change)
        {
            change(m_range);
            const f64 before = m_range.Value;
            m_range.Value = m_range.Constrain(m_range.Value);
            if (m_range.Value != before)
            {
                m_committedValue = m_range.Value;
                m_valueChanged.Notify();
            }
            ShowValue();
        }
        // The user moved it: `input`, and `change` now or at the gesture's end.
        void ChangeByUser(f64 value, bool reportInput)
        {
            const bool wasMixed = m_mixed;
            if (!Apply(value))
                return;
            if (wasMixed)
                m_commitAlways = true; // committed even at the value it held
            if (reportInput)
            {
                if (m_onChanging)
                    m_onChanging(m_range.Value);
                SendEvent(Event(EventType::Input, this));
            }
        }
        void CommitValue()
        {
            if (m_range.Value == m_committedValue && !m_commitAlways)
                return;
            m_commitAlways = false;
            m_committedValue = m_range.Value;
            if (m_onChanged)
                m_onChanged(m_range.Value);
            SendEvent(Event(EventType::Changed, this));
        }
        // A step from an arrow, a key or the wheel: committed at once, any typing dropped.
        void StepBy(f64 steps) { StepValue(m_range.KeyStep() * steps); }
        void StepValue(f64 by)
        {
            if (!IsTreeEnabled())
                return;
            ChangeByUser(m_range.Value + by, true);
            m_editing = false;
            ShowValue();
            CommitValue();
        }
        // The text shows the value (and is the committed text, so the field reports no edit);
        // mixed, it is empty and the placeholder shows.
        void ShowValue() { SetText(m_mixed ? core::StringView{} : FormatValue(m_range.Value).AsView()); }
        // Escape mid-scrub: the value and the mixed state back, the press over, the cancel told.
        void CancelScrub()
        {
            const bool scrubbed = m_scrubbing;
            m_pressing = false;
            m_scrubbing = false;
            if (EventDispatcher* dispatcher = GetEventDispatcher())
                dispatcher->ReleasePointer(*this);
            if (!scrubbed)
                return;
            Apply(m_scrubFrom);
            m_mixed = m_scrubFromMixed;
            m_commitAlways = false;
            m_committedValue = m_range.Value;
            ShowValue();
            if (m_onCancelled)
                m_onCancelled();
        }

        RangeValue m_range;
        f64 m_committedValue = 0.0;
        bool m_integer = false;
        bool m_editing = false;
        bool m_pressing = false;  // a press not yet a click or a scrub
        bool m_scrubbing = false;
        bool m_mixed = false;
        bool m_scrubFromMixed = false;
        bool m_commitAlways = false; // a mixed field's first change commits whatever its value
        bool m_stepsOnWheel = true;
        f32 m_pressX = 0.0f;
        f64 m_scrubFrom = 0.0;
        core::String m_prefix;
        core::String m_suffix;
        Observable m_valueChanged;
        core::RefPtr<SpinButton> m_up;
        core::RefPtr<SpinButton> m_down;
        core::Function<void(f64)> m_onChanging;
        core::Function<void(f64)> m_onChanged;
        core::Function<void()> m_onCancelled;
    };
}
