// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :range_widget partition
//
// RangeWidget: what a slider, a scroll bar, a progress bar and a number field share (E6 of
// Specs/gui-lab-evolution.md): a RangeValue and the reflected properties over it (value, min, max,
// step, exponential, allow-greater, allow-lesser). The page is protected: the controls a page means
// something to (a scroll bar's visible part, a slider's and a number field's page keys) expose it;
// a progress bar does not. A value set from code reports nothing (a binding follows it); the user's
// changes report `input` as they go and `change` when committed (a drag's release, a key, a typed
// value's commit), as E4's text fields do.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:range_widget;

import foundation.core; // Function, Move
import :reactive;       // Observable
import :event;
import :ui_widget;
import :range_value;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    class RangeWidget : public UIWidget
    {
        RTTI_OBJECT(RangeWidget, UIWidget)
    public:
        /// The value (a read a binding records).
        [[nodiscard]] f64 GetValue() const
        {
            m_valueChanged.Track();
            return m_range.Value;
        }
        /// Sets the value from code: constrained, reported to bindings, no events.
        void SetValue(f64 value)
        {
            if (Apply(value))
                m_committed = m_range.Value;
        }

        [[nodiscard]] f64 GetMin() const noexcept { return m_range.Min; }
        void SetMin(f64 min) { Edit([&](RangeValue& r) { r.Min = min; }); }
        [[nodiscard]] f64 GetMax() const noexcept { return m_range.Max; }
        void SetMax(f64 max) { Edit([&](RangeValue& r) { r.Max = max; }); }
        [[nodiscard]] f64 GetStep() const noexcept { return m_range.Step; }
        void SetStep(f64 step) { Edit([&](RangeValue& r) { r.Step = step < 0.0 ? 0.0 : step; }); }
        [[nodiscard]] bool IsExponential() const noexcept { return m_range.Exponential; }
        void SetExponential(bool exponential) { Edit([&](RangeValue& r) { r.Exponential = exponential; }); }
        [[nodiscard]] bool AllowsGreater() const noexcept { return m_range.AllowGreater; }
        void SetAllowGreater(bool allow) { Edit([&](RangeValue& r) { r.AllowGreater = allow; }); }
        [[nodiscard]] bool AllowsLesser() const noexcept { return m_range.AllowLesser; }
        void SetAllowLesser(bool allow) { Edit([&](RangeValue& r) { r.AllowLesser = allow; }); }
        [[nodiscard]] const RangeValue& GetRange() const noexcept { return m_range; }
        /// The value's place along the range, 0 to 1.
        [[nodiscard]] f64 GetRatio() const { return m_range.Ratio(); }

        /// Each change the user makes, as it goes (the `input` event).
        void SetOnValueChanging(core::Function<void(f64)> callback) { m_onChanging = core::Move(callback); }
        /// A change the user committed (the `change` event).
        void SetOnValueChanged(core::Function<void(f64)> callback) { m_onChanged = core::Move(callback); }

    protected:
        RangeWidget() = default;

        [[nodiscard]] f64 GetPageSize() const noexcept { return m_range.Page; }
        /// The page is a visible part (a scroll bar's): the value stops short of the maximum by it.
        void SetPageShown(bool shown) { Edit([&](RangeValue& r) { r.PageShown = shown; }); }
        void SetPageSize(f64 page) { Edit([&](RangeValue& r) { r.Page = page < 0.0 ? 0.0 : page; }); }

        /// The user moved it to `value`: reported as `input`, and committed (`change`) now or later.
        void ChangeByUser(f64 value, bool commit)
        {
            if (Apply(value))
            {
                if (m_onChanging)
                    m_onChanging(m_range.Value);
                SendEvent(Event(EventType::Input, this));
            }
            if (commit)
                Commit();
        }
        /// A gesture ended (a drag released): its change, if any, is committed.
        void Commit()
        {
            if (m_range.Value == m_committed)
                return;
            m_committed = m_range.Value;
            if (m_onChanged)
                m_onChanged(m_range.Value);
            SendEvent(Event(EventType::Changed, this));
        }
        /// The range or the value changed: redraw (a control with parts of its own does more).
        virtual void OnRangeChange() { Invalidate(); }

    private:
        bool Apply(f64 value)
        {
            value = m_range.Constrain(value);
            if (value == m_range.Value)
                return false;
            m_range.Value = value;
            OnRangeChange();
            m_valueChanged.Notify();
            return true;
        }
        template <typename F>
        void Edit(F&& change)
        {
            RangeValue next = m_range;
            change(next);
            next.Value = next.Constrain(next.Value);
            if (next == m_range)
                return;
            const bool moved = next.Value != m_range.Value;
            m_range = next;
            OnRangeChange();
            if (moved)
            {
                m_committed = m_range.Value;
                m_valueChanged.Notify();
            }
        }

        RangeValue m_range;
        f64 m_committed = 0.0; // the value last committed (a change reports once)
        Observable m_valueChanged;
        core::Function<void(f64)> m_onChanging;
        core::Function<void(f64)> m_onChanged;
    };
}
