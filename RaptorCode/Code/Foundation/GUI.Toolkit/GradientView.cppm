// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - :gradient_view partition
//
// The gradient view (T5 of Specs/gui-lab-evolution-3.md) edits one of Core's gradients as a value:
// its colour stops (sRGB) and alpha stops apart, and the space they blend in, drawn with Core's
// EvaluateGradient so what is edited is what plays (ruling 2: no gradient model of the toolkit's).
//   - A strip: alpha stops above a bar of the gradient over a checkerboard, colour stops below it.
//   - A click on the strip adds a stop there (an alpha stop on its upper half, a colour stop on its
//     lower), of the gradient's colour or alpha at that place, and a drag moves it; a press on a stop
//     selects it and a drag moves it, the stops sorted again as it passes; a drag off the strip takes
//     it away (back on, it returns), though never a kind's last stop. Escape gives a drag up.
//   - A double click on a colour stop, or a click on its swatch, opens T4's picker as a popup (its
//     drags preview, closing it is the change, Escape gives it up); an alpha stop has a number field;
//     the selected stop's place has one too; the interpolation is a drop-down.
// The value is the GUI's ColorGradient, as a property grid's gradient row carries it. It reports each step of a gesture (changing), its end (changed) and a gesture given up
// (cancelled, the value back as it was); whoever holds the gradient writes it.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui.toolkit:gradient_view;

import foundation.core;
import foundation.vg;
import foundation.gui;
import :property_editors; // PropertyColorPopup: the picker on a panel

using namespace foundation::core;
namespace core = foundation::core;
namespace vg = foundation::vg;

export namespace foundation::gui
{
    /// A stop of a gradient: which kind, and its place among that kind's stops.
    struct GradientStopRef
    {
        bool Alpha = false;
        i32 Index = -1; ///< -1: none
        [[nodiscard]] bool IsValid() const noexcept { return Index >= 0; }
        [[nodiscard]] bool operator==(const GradientStopRef&) const noexcept = default;
    };

    class GradientView;

    /// A gradient view's strip: the bar and the stops either side of it, and their gestures.
    class GradientStrip : public UIWidget
    {
        RTTI_OBJECT(GradientStrip, UIWidget)
    public:
        static constexpr f32 kLane = 12.0f;       // each stop lane's height
        static constexpr f32 kHitRadius = 6.0f;
        static constexpr f32 kPullOff = 24.0f;    // past the strip by this much, a dragged stop goes

        explicit GradientStrip(GradientView& view) : m_view(view)
        {
            SetTag(core::StringView(u8"gradientstrip"));
            EditLayoutStyle([](LayoutStyle& s) { s.Height = LayoutLength::Px(48.0f); });
        }

        /// Where a time is across it, and back (its own space).
        [[nodiscard]] f32 XAt(f32 time) const
        {
            const Rect box = GetContentBounds();
            return box.x + core::Clamp(time, 0.0f, 1.0f) * box.width;
        }
        [[nodiscard]] f32 TimeAt(f32 x) const
        {
            const Rect box = GetContentBounds();
            return box.width > 0.0f ? core::Clamp((x - box.x) / box.width, 0.0f, 1.0f) : 0.0f;
        }
        /// The bar between the lanes.
        [[nodiscard]] Rect BarBounds() const
        {
            const Rect box = GetContentBounds();
            return Rect{box.x, box.y + kLane, box.width, core::Max(0.0f, box.height - 2.0f * kLane)};
        }
        /// The stop under `local`, if any.
        [[nodiscard]] GradientStopRef StopAt(core::Float2 local) const;

    protected:
        void OnMouseDown(const MouseEvent& event) override;
        void OnMouseMove(const MouseEvent& event) override;
        void OnMouseUp(const MouseEvent& event) override;
        void OnPointerCancel(const MouseEvent& event) override;
        void OnDraw(DrawContext& ctx, const Rect& localBounds) override;

    private:
        friend class GradientView;
        GradientView& m_view;
        bool m_dragging = false;
    };

    class GradientView : public UIWidget
    {
        RTTI_OBJECT(GradientView, UIWidget)
    public:
        GradientView()
        {
            SetTag(core::StringView(u8"gradientview"));
            SetTabFocusable(true);
            EditLayoutStyle([](LayoutStyle& s)
            {
                s.Direction = FlexDirection::Column;
                s.RowGap = 6.0f;
            });
            GradientView* self = this;
            m_strip = core::MakeRef<GradientStrip>(MemoryAllocator(), *this);
            AddChild(m_strip.Get());

            m_controls = core::MakeRef<UIWidget>(MemoryAllocator());
            m_controls->EditLayoutStyle([](LayoutStyle& s)
            {
                s.Direction = FlexDirection::Row;
                s.ColumnGap = 6.0f;
                s.AlignItems = Align::Center;
            });
            AddChild(m_controls.Get());
            m_interpolation = core::MakeRef<ComboBox>(MemoryAllocator());
            const char8_t* const spaces[] = {u8"sRGB", u8"Linear light", u8"OKLab", u8"Constant"}; // GradientInterpolation's order
            for (const char8_t* name : spaces)
                m_interpolation->AddItem(core::StringView(name));
            m_interpolation->EditLayoutStyle([](LayoutStyle& s) { s.Width = LayoutLength::Px(110.0f); });
            m_interpolation->SetOnSelectionChanged([self](i32 index) { self->PickedInterpolation(index); });
            m_controls->AddChild(m_interpolation.Get());

            m_timeLabel = MakeLabel(u8"At");
            m_time = MakeField(0.0, 1.0, 0.01);
            m_time->SetOnValueChanging([self](f64 value) { self->TypedTime(value, false); });
            m_time->SetOnValueChanged([self](f64 value) { self->TypedTime(value, true); });
            m_time->SetOnValueCancelled([self]() { self->CancelGesture(); });

            m_alphaLabel = MakeLabel(u8"Alpha");
            m_alpha = MakeField(0.0, 1.0, 0.01);
            m_alpha->SetOnValueChanging([self](f64 value) { self->TypedAlpha(value, false); });
            m_alpha->SetOnValueChanged([self](f64 value) { self->TypedAlpha(value, true); });
            m_alpha->SetOnValueCancelled([self]() { self->CancelGesture(); });

            m_swatch = core::MakeRef<ColorSwatch>(MemoryAllocator());
            m_swatch->EditLayoutStyle([](LayoutStyle& s)
            {
                s.Width = LayoutLength::Px(40.0f);
                s.Height = LayoutLength::Px(20.0f);
                s.Shrink = 0.0f;
            });
            m_swatch->SetShowsAlpha(false);
            m_swatch->SetOnClick([self]() { self->OpenPicker(); });
            m_controls->AddChild(m_swatch.Get());

            m_popup = core::MakeRef<PropertyColorPopup>(MemoryAllocator());
            m_popup->GetPicker().SetShowsAlpha(false); // a gradient's alpha is its alpha stops'
            m_popup->GetPicker().SetOnColorChanging([self](Color color) { self->PickedColor(color); });
            m_popup->GetPicker().SetOnColorChanged([self](Color color) { self->PickedColor(color); });
            ShowSelection();
        }
        ~GradientView() override = default;

        // === The value ===
        /// Sets the gradient from code: shown, nothing reported.
        void SetValue(const ColorGradient& value)
        {
            m_value = value;
            if (m_selected.IsValid() && m_selected.Index >= static_cast<i32>(Count(m_selected.Alpha)))
                m_selected = GradientStopRef{};
            ShowSelection();
            Invalidate();
        }
        [[nodiscard]] const ColorGradient& GetValue() const noexcept { return m_value; }
        /// The most stops of each kind (a particle gradient's eight); 0: no limit.
        void SetMaxStops(u32 most) noexcept { m_maxStops = most; }

        void SetOnGradientChanging(core::Function<void(const ColorGradient&)> callback) { m_onChanging = core::Move(callback); }
        void SetOnGradientChanged(core::Function<void(const ColorGradient&)> callback) { m_onChanged = core::Move(callback); }
        /// A gesture given up: the value is as it was before it.
        void SetOnGradientCancelled(core::Function<void()> callback) { m_onCancelled = core::Move(callback); }

        // === The selection ===
        [[nodiscard]] GradientStopRef GetSelected() const noexcept { return m_selected; }
        void Select(GradientStopRef stop)
        {
            if (stop.IsValid() && stop.Index >= static_cast<i32>(Count(stop.Alpha)))
                stop = GradientStopRef{};
            m_selected = stop;
            ShowSelection();
            Invalidate();
        }

        // === Edits (each one change) ===
        /// Adds a stop at `time` of the gradient's colour or alpha there; false when the kind is full.
        bool AddStop(bool alpha, f32 time)
        {
            if (m_maxStops != 0 && Count(alpha) >= m_maxStops)
                return false;
            const GradientStopRef stop = Insert(alpha, time);
            Select(stop);
            Changed(true);
            return true;
        }
        /// Takes the selected stop away; false when there is none, or it is its kind's last.
        bool RemoveSelected()
        {
            if (!m_selected.IsValid() || Count(m_selected.Alpha) <= 1)
                return false;
            Erase(m_selected);
            m_selected = GradientStopRef{};
            ShowSelection();
            Changed(true);
            return true;
        }

        // === Parts ===
        [[nodiscard]] GradientStrip* GetStrip() const noexcept { return m_strip.Get(); }
        [[nodiscard]] ComboBox* GetInterpolationBox() const noexcept { return m_interpolation.Get(); }
        [[nodiscard]] NumberField* GetTimeField() const noexcept { return m_time.Get(); }
        [[nodiscard]] NumberField* GetAlphaField() const noexcept { return m_alpha.Get(); }
        [[nodiscard]] ColorSwatch* GetSwatch() const noexcept { return m_swatch.Get(); }
        /// The picker, while it is open.
        [[nodiscard]] ColorPicker* GetPicker() const
        {
            const EventDispatcher* dispatcher = m_popup->GetEventDispatcher();
            return dispatcher != nullptr && dispatcher->IsPopupOpen(*m_popup) ? &m_popup->GetPicker() : nullptr;
        }
        /// Opens the picker on the selected colour stop.
        void OpenPicker()
        {
            EventDispatcher* dispatcher = GetEventDispatcher();
            if (dispatcher == nullptr || !m_selected.IsValid() || m_selected.Alpha || GetPicker() != nullptr)
                return;
            ShareTextStyle(*m_popup, false);
            Color color = m_value.Colors[static_cast<usize>(m_selected.Index)].color;
            color.a = 1.0f;
            m_popup->GetPicker().SetColor(color);
            m_picking = false;
            PopupOptions options;
            options.Anchor = m_swatch.Get();
            options.Placement = PopupPlacement{PopupSide::Below, PopupAlign::Start, 2.0f, true};
            options.TakesFocus = true;
            options.FitContent = true;
            GradientView* self = this;
            options.OnClosed = [self](PopupCloseReason reason) { self->PickerClosed(reason == PopupCloseReason::Escape); };
            dispatcher->OpenPopup(*this, *m_popup, core::Move(options));
        }

    protected:
        void OnKeyDown(const KeyEvent& event) override
        {
            const KeyCode key = static_cast<KeyCode>(event.KeyCode);
            if (key == KeyCode::Escape && m_strip->m_dragging)
            {
                event.Handled = true;
                m_strip->m_dragging = false;
                CancelGesture();
                return;
            }
            if (event.Modifiers == 0 && (key == KeyCode::Delete || key == KeyCode::Backspace) && !m_strip->m_dragging && event.Target == this)
                event.Handled = RemoveSelected();
        }
        void OnTextStyleChange() override
        {
            ShareTextStyle(*m_interpolation);
            ShareTextStyle(*m_time);
            ShareTextStyle(*m_alpha);
            ShareTextStyle(*m_timeLabel);
            ShareTextStyle(*m_alphaLabel);
        }

    private:
        friend class GradientStrip;

        core::RefPtr<Label> MakeLabel(const char8_t* text)
        {
            auto label = core::MakeRef<Label>(MemoryAllocator());
            label->SetText(core::StringView(text));
            label->SetHitTestVisible(false);
            m_controls->AddChild(label.Get());
            return label;
        }
        core::RefPtr<NumberField> MakeField(f64 low, f64 high, f64 step)
        {
            auto field = core::MakeRef<NumberField>(MemoryAllocator());
            field->SetMin(low);
            field->SetMax(high);
            field->SetStep(step);
            field->EditLayoutStyle([](LayoutStyle& s) { s.Width = LayoutLength::Px(72.0f); });
            m_controls->AddChild(field.Get());
            return field;
        }

        [[nodiscard]] usize Count(bool alpha) const noexcept { return alpha ? m_value.Alphas.Size() : m_value.Colors.Size(); }
        [[nodiscard]] f32 TimeOf(const GradientStopRef& stop) const
        {
            return stop.Alpha ? m_value.Alphas[static_cast<usize>(stop.Index)].time : m_value.Colors[static_cast<usize>(stop.Index)].time;
        }
        // Puts a stop at `time` of what the gradient has there; where it went.
        GradientStopRef Insert(bool alpha, f32 time)
        {
            const Color here = m_value.Evaluate(time);
            if (alpha)
            {
                usize at = 0;
                while (at < m_value.Alphas.Size() && m_value.Alphas[at].time <= time)
                    ++at;
                m_value.Alphas.Insert(at, GradientAlphaStop{time, here.a});
                return GradientStopRef{true, static_cast<i32>(at)};
            }
            usize at = 0;
            while (at < m_value.Colors.Size() && m_value.Colors[at].time <= time)
                ++at;
            m_value.Colors.Insert(at, GradientColorStop{time, Color{here.r, here.g, here.b, 1.0f}});
            return GradientStopRef{false, static_cast<i32>(at)};
        }
        void Erase(const GradientStopRef& stop)
        {
            if (stop.Alpha)
                m_value.Alphas.RemoveAt(static_cast<usize>(stop.Index));
            else
                m_value.Colors.RemoveAt(static_cast<usize>(stop.Index));
        }
        // Moves a stop to `time`, sorted again; where it went.
        GradientStopRef MoveStop(GradientStopRef stop, f32 time)
        {
            time = core::Clamp(time, 0.0f, 1.0f);
            if (stop.Alpha)
            {
                GradientAlphaStop moved = m_value.Alphas[static_cast<usize>(stop.Index)];
                moved.time = time;
                m_value.Alphas.RemoveAt(static_cast<usize>(stop.Index));
                usize at = 0;
                while (at < m_value.Alphas.Size() && m_value.Alphas[at].time <= time)
                    ++at;
                m_value.Alphas.Insert(at, moved);
                return GradientStopRef{true, static_cast<i32>(at)};
            }
            GradientColorStop moved = m_value.Colors[static_cast<usize>(stop.Index)];
            moved.time = time;
            m_value.Colors.RemoveAt(static_cast<usize>(stop.Index));
            usize at = 0;
            while (at < m_value.Colors.Size() && m_value.Colors[at].time <= time)
                ++at;
            m_value.Colors.Insert(at, moved);
            return GradientStopRef{false, static_cast<i32>(at)};
        }

        // A gesture's start: what a cancel puts back.
        void BeginGesture()
        {
            if (m_gesture)
                return;
            m_gesture = true;
            m_before = m_value;
            m_beforeSelected = m_selected;
        }
        void Changed(bool done)
        {
            Invalidate();
            if (done)
            {
                m_gesture = false;
                if (m_onChanged)
                    m_onChanged(m_value);
            }
            else if (m_onChanging)
                m_onChanging(m_value);
        }
        void CancelGesture()
        {
            if (!m_gesture)
                return;
            m_gesture = false;
            m_value = m_before;
            m_selected = m_beforeSelected;
            m_pulledOff = false;
            ShowSelection();
            Invalidate();
            if (m_onCancelled)
                m_onCancelled();
        }

        // The strip's drag: the stop to `time`, or off the strip (gone while it stays off).
        void DragStop(f32 time, bool off)
        {
            if (!m_dragStop.IsValid())
                return;
            m_value = m_dragBase;
            m_pulledOff = off && Count(m_dragStop.Alpha) > 1;
            if (m_pulledOff)
            {
                Erase(m_dragStop);
                m_selected = GradientStopRef{};
            }
            else
                m_selected = MoveStop(m_dragStop, time);
            ShowSelection();
            Changed(false);
        }
        void EndStopDrag()
        {
            m_dragStop = GradientStopRef{};
            m_pulledOff = false;
            if (m_gesture)
            {
                if (m_value == m_before)
                    m_gesture = false; // a click on a stop: nothing changed
                else
                    Changed(true);
            }
        }

        void ShowSelection()
        {
            m_showing = true;
            m_interpolation->SetSelectedIndex(static_cast<i32>(m_value.Interpolation));
            const bool any = m_selected.IsValid();
            const bool alpha = any && m_selected.Alpha;
            m_timeLabel->SetDisplayed(any);
            m_time->SetDisplayed(any);
            m_alphaLabel->SetDisplayed(alpha);
            m_alpha->SetDisplayed(alpha);
            m_swatch->SetDisplayed(any && !alpha);
            if (any)
            {
                m_time->SetValue(TimeOf(m_selected));
                if (alpha)
                    m_alpha->SetValue(m_value.Alphas[static_cast<usize>(m_selected.Index)].alpha);
                else
                    m_swatch->SetColor(m_value.Colors[static_cast<usize>(m_selected.Index)].color);
            }
            m_showing = false;
        }
        void PickedInterpolation(i32 index)
        {
            if (m_showing || index < 0 || index > static_cast<i32>(GradientInterpolation::Constant))
                return;
            m_value.Interpolation = static_cast<GradientInterpolation>(index);
            Changed(true);
        }
        void TypedTime(f64 value, bool done)
        {
            if (m_showing || !m_selected.IsValid())
                return;
            BeginGesture();
            m_selected = MoveStop(m_selected, static_cast<f32>(value));
            Changed(done);
        }
        void TypedAlpha(f64 value, bool done)
        {
            if (m_showing || !m_selected.IsValid() || !m_selected.Alpha)
                return;
            BeginGesture();
            m_value.Alphas[static_cast<usize>(m_selected.Index)].alpha = core::Clamp(static_cast<f32>(value), 0.0f, 1.0f);
            Changed(done);
        }
        void PickedColor(Color color)
        {
            if (!m_selected.IsValid() || m_selected.Alpha)
                return;
            if (!m_picking)
            {
                m_picking = true;
                BeginGesture();
            }
            color.a = 1.0f;
            m_value.Colors[static_cast<usize>(m_selected.Index)].color = color;
            m_swatch->SetColor(color);
            Changed(false);
        }
        void PickerClosed(bool escaped)
        {
            if (!m_picking)
                return;
            m_picking = false;
            if (escaped)
                CancelGesture();
            else
                Changed(true);
        }

        core::RefPtr<GradientStrip> m_strip;
        core::RefPtr<UIWidget> m_controls;
        core::RefPtr<ComboBox> m_interpolation;
        core::RefPtr<Label> m_timeLabel;
        core::RefPtr<NumberField> m_time;
        core::RefPtr<Label> m_alphaLabel;
        core::RefPtr<NumberField> m_alpha;
        core::RefPtr<ColorSwatch> m_swatch;
        core::RefPtr<PropertyColorPopup> m_popup;

        ColorGradient m_value;
        GradientStopRef m_selected;
        u32 m_maxStops = 0;
        bool m_showing = false;  // the controls are being set from the value
        bool m_gesture = false;  // a gesture under way
        bool m_picking = false;  // the open picker has changed the colour
        ColorGradient m_before;  // the value when the gesture began
        GradientStopRef m_beforeSelected;
        GradientStopRef m_dragStop; // the stop the strip drags, in m_dragBase
        ColorGradient m_dragBase;   // the value the drag works from
        bool m_pulledOff = false;
        core::Function<void(const ColorGradient&)> m_onChanging;
        core::Function<void(const ColorGradient&)> m_onChanged;
        core::Function<void()> m_onCancelled;
    };

    // === The strip ===

    inline GradientStopRef GradientStrip::StopAt(core::Float2 local) const
    {
        const Rect box = GetContentBounds();
        const ColorGradient& value = m_view.m_value;
        const bool alphaLane = local.y < box.y + kLane + 2.0f;
        const bool colorLane = local.y > box.Bottom() - kLane - 2.0f;
        GradientStopRef best;
        f32 bestDistance = kHitRadius + 1.0f;
        if (alphaLane)
            for (usize i = 0; i < value.Alphas.Size(); ++i)
            {
                const f32 d = core::Abs(XAt(value.Alphas[i].time) - local.x);
                if (d <= kHitRadius && d < bestDistance)
                {
                    best = GradientStopRef{true, static_cast<i32>(i)};
                    bestDistance = d;
                }
            }
        if (colorLane)
            for (usize i = 0; i < value.Colors.Size(); ++i)
            {
                const f32 d = core::Abs(XAt(value.Colors[i].time) - local.x);
                if (d <= kHitRadius && d < bestDistance)
                {
                    best = GradientStopRef{false, static_cast<i32>(i)};
                    bestDistance = d;
                }
            }
        return best;
    }

    inline void GradientStrip::OnMouseDown(const MouseEvent& event)
    {
        if (event.Button != MouseButton::Left)
            return;
        event.Handled = true;
        m_view.RequestFocus();
        const core::Float2 local = ConvertToNodeSpace(event.Position); // events come in screen space
        GradientStopRef stop = StopAt(local);
        if (event.ClickCount == 2 && stop.IsValid())
        {
            m_view.Select(stop);
            if (!stop.Alpha)
                m_view.OpenPicker();
            return;
        }
        m_view.BeginGesture();
        if (!stop.IsValid())
        {
            // A click on nothing adds a stop there, and the drag goes on with it.
            const Rect box = GetContentBounds();
            const bool alpha = local.y < box.y + box.height * 0.5f;
            if (m_view.m_maxStops != 0 && m_view.Count(alpha) >= m_view.m_maxStops)
            {
                m_view.m_gesture = false;
                return;
            }
            stop = m_view.Insert(alpha, TimeAt(local.x));
        }
        m_view.m_selected = stop;
        m_view.m_dragStop = stop;
        m_view.m_dragBase = m_view.m_value;
        m_view.ShowSelection();
        m_view.Invalidate();
        m_dragging = true;
    }
    inline void GradientStrip::OnMouseMove(const MouseEvent& event)
    {
        if (!m_dragging)
            return;
        const core::Float2 local = ConvertToNodeSpace(event.Position);
        const Rect box = GetContentBounds();
        const bool off = local.y < box.y - kPullOff || local.y > box.Bottom() + kPullOff;
        m_view.DragStop(TimeAt(local.x), off);
    }
    inline void GradientStrip::OnMouseUp(const MouseEvent& event)
    {
        if (!m_dragging || event.Button != MouseButton::Left)
            return;
        m_dragging = false;
        m_view.EndStopDrag();
    }
    inline void GradientStrip::OnPointerCancel(const MouseEvent&)
    {
        if (!m_dragging)
            return;
        m_dragging = false;
        m_view.CancelGesture();
    }

    inline void GradientStrip::OnDraw(DrawContext& ctx, const Rect& localBounds)
    {
        UIWidget::OnDraw(ctx, localBounds);
        const ColorGradient& value = m_view.m_value;
        const Rect bar = BarBounds();
        if (bar.width <= 0.0f || bar.height <= 0.0f)
            return;
        // The bar: the gradient over a checkerboard, a column a pixel or two wide at a time.
        detail::DrawChecker(ctx, bar);
        for (f32 x = 0.0f; x < bar.width; x += 2.0f)
        {
            const Color color = value.Evaluate((x + 1.0f) / bar.width);
            ctx.VG().FillRect(Rectangle{bar.x + x, bar.y, core::Min(2.0f, bar.width - x), bar.height}, color);
        }
        const PartStyle& selectedPart = GetPartStyle(u8"selected");
        Color selected = selectedPart.HasBackground ? selectedPart.Box.BackgroundColor : Color{1.0f, 1.0f, 1.0f, 1.0f};
        const Color edge = GetTextColor();
        const GradientStopRef chosen = m_view.m_selected;
        // A stop: a triangle pointing at the bar, filled with its colour or its alpha as grey.
        const auto marker = [&](f32 time, bool above, Color fill, bool on)
        {
            const f32 x = XAt(time);
            const f32 tip = above ? bar.y : bar.Bottom();
            const f32 base = above ? bar.y - kLane : bar.Bottom() + kLane;
            vg::PathBuilder shape;
            shape.MoveTo(x, tip);
            shape.LineTo(x + 5.0f, base);
            shape.LineTo(x - 5.0f, base);
            shape.Close();
            ctx.VG().FillPath(shape.ToPath(), fill);
            ctx.VG().StrokePath(shape.ToPath(), on ? selected : edge, vg::StrokeStyle(on ? 2.0f : 1.0f));
        };
        for (usize i = 0; i < value.Alphas.Size(); ++i)
        {
            const f32 a = value.Alphas[i].alpha;
            marker(value.Alphas[i].time, true, Color{a, a, a, 1.0f}, chosen.Alpha && chosen.Index == static_cast<i32>(i));
        }
        for (usize i = 0; i < value.Colors.Size(); ++i)
        {
            Color c = value.Colors[i].color;
            c.a = 1.0f;
            marker(value.Colors[i].time, false, c, !chosen.Alpha && chosen.Index == static_cast<i32>(i));
        }
    }
}
