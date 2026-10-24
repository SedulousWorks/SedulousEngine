// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - :curve_view partition
//
// The curve view (T5 of Specs/gui-lab-evolution-3.md): a source's curves on one canvas, time across
// on a shared TimeAxis and value up on a range of its own, drawn with Core's EvaluateCurve so what is
// edited is what plays. Mouse first, as ezEngine's:
//   - a click selects a key (Shift or Ctrl adds or takes it away), a drag from nothing selects by a box;
//   - a drag moves the selected keys (Shift locks it to the axis it moved along most), their times on
//     frames with a frame rate, their values in a curve's range, the keys sorted again as they pass
//     and their tangents set by their modes, so auto and smooth keys follow;
//   - a selected key's handles (where a cubic segment meets it) set its tangents; dragging an auto
//     or a flat key's handle makes it smooth;
//   - a double click on a curve adds a key there, on the curve;
//   - a key's menu sets the interpolation and the tangent mode of the selected keys, or deletes them
//     (Delete does too); the menu over nothing frames every curve or the selection;
//   - the wheel zooms about the pointer (Ctrl only time, Shift only value), a middle drag pans.
// Each gesture is one edit through the source (one undo entry, the application's).

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui.toolkit:curve_view;

import foundation.core;
import foundation.vg;
import foundation.gui;
import :time_axis;
import :curve_source;

using namespace foundation::core;
namespace core = foundation::core;
namespace vg = foundation::vg;

export namespace foundation::gui
{
    /// What is under a point of a curve view.
    struct CurveHit
    {
        enum class Kind : u8
        {
            None,
            Key,
            TangentIn,
            TangentOut,
            Curve,
        };
        Kind What = Kind::None;
        CurveKeyRef Key; ///< a key's, a handle's key; a curve's index in Key.Curve
    };

    class CurveView : public UIWidget, public ITimeAxisClient, public ICurveSourceClient
    {
        RTTI_OBJECT(CurveView, UIWidget)
    public:
        static constexpr f32 kHitRadius = 6.0f;
        static constexpr f32 kHandleLength = 40.0f;
        static constexpr f32 kDragThreshold = 3.0f;

        CurveView()
        {
            SetTag(core::StringView(u8"curveview"));
            SetTabFocusable(true);
        }
        ~CurveView() override
        {
            if (m_axis)
                m_axis->Leave(this);
            if (m_source)
                m_source->RemoveClient(this);
        }

        // === What it shows ===
        void SetTimeAxis(core::RefPtr<TimeAxis> axis)
        {
            if (m_axis)
                m_axis->Leave(this);
            m_axis = core::Move(axis);
            if (m_axis)
                m_axis->Join(this);
            Invalidate();
        }
        [[nodiscard]] TimeAxis* GetTimeAxis() const noexcept { return m_axis.Get(); }
        /// The curves it edits (not owned: the source outlives the view or is set to null first).
        void SetSource(ICurveSource* source)
        {
            if (m_source)
                m_source->RemoveClient(this);
            m_source = source;
            if (m_source)
                m_source->AddClient(this);
            m_selection.Clear();
            Invalidate();
        }
        [[nodiscard]] ICurveSource* GetSource() const noexcept { return m_source; }

        /// The values from its bottom to its top.
        void SetValueRange(f32 low, f32 high)
        {
            if (high - low < 1e-6f)
                high = low + 1e-6f;
            m_valueLow = low;
            m_valueHigh = high;
            Invalidate();
        }
        [[nodiscard]] f32 ValueLow() const noexcept { return m_valueLow; }
        [[nodiscard]] f32 ValueHigh() const noexcept { return m_valueHigh; }

        /// Fits the time axis and the values to every curve's keys (and its range, where it has one).
        void FrameAll() { Frame(false); }
        /// Fits them to the selected keys; to every curve with none selected.
        void FrameSelection() { Frame(!m_selection.IsEmpty()); }

        // === The selection ===
        [[nodiscard]] const core::Array<CurveKeyRef>& GetSelection() const noexcept { return m_selection; }
        void SetSelection(core::Span<const CurveKeyRef> keys)
        {
            m_selection.Clear();
            for (const CurveKeyRef& key : keys)
                Select(key, true);
            Invalidate();
        }
        [[nodiscard]] bool IsSelected(const CurveKeyRef& key) const noexcept
        {
            for (const CurveKeyRef& at : m_selection)
                if (at == key)
                    return true;
            return false;
        }

        // === Edits of the selection (one each, through the source) ===
        void SetInterpolation(CurveKeyInterpolation interpolation)
        {
            EditSelected([interpolation](CurveKey& key) { key.interpolation = interpolation; });
        }
        void SetTangentMode(CurveTangentMode mode)
        {
            EditSelected([mode](CurveKey& key) { key.tangentMode = mode; });
        }
        /// Deletes the selected keys; false when none were.
        bool DeleteSelected()
        {
            if (!m_source || m_selection.IsEmpty())
                return false;
            m_source->BeginKeysEdit();
            for (usize c = 0; c < m_source->CurveCount(); ++c)
            {
                if (!HasSelectedOn(c))
                    continue;
                core::Array<CurveKey> keys;
                const core::Span<const CurveKey> from = m_source->GetKeys(c);
                for (usize i = 0; i < from.Size(); ++i)
                    if (!IsSelected(CurveKeyRef{c, i}))
                        keys.PushBack(from[i]);
                ApplyTangentModes(keys.AsSpan());
                m_source->PreviewKeys(c, keys.AsSpan());
            }
            m_source->CommitKeysEdit();
            m_selection.Clear();
            Invalidate();
            return true;
        }
        /// Adds a key to `curve` at `time`, on the curve (its interpolation the segment's it splits);
        /// false when the curve is full or locked.
        bool InsertKey(usize curve, f32 time)
        {
            if (!m_source || curve >= m_source->CurveCount())
                return false;
            const CurveInfo info = m_source->GetCurveInfo(curve);
            const core::Span<const CurveKey> from = m_source->GetKeys(curve);
            if (info.Locked || (info.MaxKeys != 0 && from.Size() >= info.MaxKeys))
                return false;
            if (m_axis)
                time = core::Clamp(m_axis->Snap(time), 0.0f, m_axis->Duration());
            CurveKey key;
            key.time = time;
            key.value = EvaluateCurve(from, time);
            key.interpolation = CurveKeyInterpolation::Cubic;
            key.tangentMode = CurveTangentMode::Auto;
            usize at = 0;
            while (at < from.Size() && from[at].time <= time)
                ++at;
            if (at > 0)
                key.interpolation = from[at - 1].interpolation;
            core::Array<CurveKey> keys;
            for (usize i = 0; i < from.Size(); ++i)
            {
                if (i == at)
                    keys.PushBack(key);
                keys.PushBack(from[i]);
            }
            if (at == from.Size())
                keys.PushBack(key);
            ApplyTangentModes(keys.AsSpan());
            m_source->BeginKeysEdit();
            m_source->PreviewKeys(curve, keys.AsSpan());
            m_source->CommitKeysEdit();
            m_selection.Clear();
            m_selection.PushBack(CurveKeyRef{curve, at});
            Invalidate();
            return true;
        }

        // === Where things are (in its own space) ===
        [[nodiscard]] core::Float2 KeyPoint(f32 time, f32 value) const
        {
            const Rect box = GetContentBounds();
            const f32 x = box.x + (m_axis ? m_axis->TimeToOffset(time) : 0.0f);
            const f32 y = box.Bottom() - (value - m_valueLow) / (m_valueHigh - m_valueLow) * box.height;
            return core::Float2{x, y};
        }
        [[nodiscard]] f32 TimeAtX(f32 x) const { return m_axis ? m_axis->OffsetToTime(x - GetContentBounds().x) : 0.0f; }
        [[nodiscard]] f32 ValueAtY(f32 y) const
        {
            const Rect box = GetContentBounds();
            return box.height > 0.0f ? m_valueLow + (box.Bottom() - y) / box.height * (m_valueHigh - m_valueLow) : m_valueLow;
        }
        /// Where a key's handle is drawn (`out`: the one leaving it).
        [[nodiscard]] core::Float2 HandlePoint(const CurveKey& key, bool out) const
        {
            const Rect box = GetContentBounds();
            const f32 pixelsPerSecond = m_axis ? m_axis->PixelsPerSecond() : 1.0f;
            const f32 pixelsPerValue = box.height / (m_valueHigh - m_valueLow);
            const f32 slope = out ? key.tangentOut : key.tangentIn;
            core::Float2 direction{pixelsPerSecond, -slope * pixelsPerValue};
            const f32 length = core::Sqrt(direction.x * direction.x + direction.y * direction.y);
            if (length <= 0.0f)
                return KeyPoint(key.time, key.value);
            const f32 sign = out ? 1.0f : -1.0f;
            const core::Float2 at = KeyPoint(key.time, key.value);
            return core::Float2{at.x + sign * direction.x / length * kHandleLength, at.y + sign * direction.y / length * kHandleLength};
        }
        /// What is at `local` (its own space): a selected key's handle first, then a key, then a curve.
        [[nodiscard]] CurveHit HitTest(core::Float2 local) const
        {
            CurveHit hit;
            if (!m_source)
                return hit;
            for (const CurveKeyRef& ref : m_selection)
            {
                const core::Span<const CurveKey> keys = m_source->GetKeys(ref.Curve);
                if (ref.Index >= keys.Size() || m_source->GetCurveInfo(ref.Curve).Locked)
                    continue;
                if (HasHandle(keys, ref.Index, true) && Near(HandlePoint(keys[ref.Index], true), local))
                    return CurveHit{CurveHit::Kind::TangentOut, ref};
                if (HasHandle(keys, ref.Index, false) && Near(HandlePoint(keys[ref.Index], false), local))
                    return CurveHit{CurveHit::Kind::TangentIn, ref};
            }
            for (usize c = m_source->CurveCount(); c-- > 0;)
            {
                if (m_source->GetCurveInfo(c).Locked)
                    continue;
                const core::Span<const CurveKey> keys = m_source->GetKeys(c);
                for (usize i = keys.Size(); i-- > 0;)
                    if (Near(KeyPoint(keys[i].time, keys[i].value), local))
                        return CurveHit{CurveHit::Kind::Key, CurveKeyRef{c, i}};
            }
            const f32 time = TimeAtX(local.x);
            for (usize c = m_source->CurveCount(); c-- > 0;)
            {
                if (m_source->GetCurveInfo(c).Locked)
                    continue;
                const f32 y = KeyPoint(time, EvaluateCurve(m_source->GetKeys(c), time)).y;
                if (core::Abs(y - local.y) <= kHitRadius)
                    return CurveHit{CurveHit::Kind::Curve, CurveKeyRef{c, 0}};
            }
            return hit;
        }
        /// Whether a key shows a handle on that side: a cubic segment meets it there.
        [[nodiscard]] static bool HasHandle(core::Span<const CurveKey> keys, usize index, bool out) noexcept
        {
            if (out)
                return index + 1 < keys.Size() && keys[index].interpolation == CurveKeyInterpolation::Cubic;
            return index > 0 && index < keys.Size() && keys[index - 1].interpolation == CurveKeyInterpolation::Cubic;
        }
        [[nodiscard]] Menu* GetKeyMenu() const noexcept { return m_menu && m_menu->IsOpen() ? m_menu.Get() : nullptr; }

        void OnTimeAxisChanged() override { Invalidate(); }
        void OnCurvesChanged() override
        {
            if (!m_source)
                return;
            for (usize i = m_selection.Size(); i-- > 0;) // an undo may take keys away
                if (m_selection[i].Curve >= m_source->CurveCount() || m_selection[i].Index >= m_source->GetKeys(m_selection[i].Curve).Size())
                    m_selection.RemoveAt(i);
            Invalidate();
        }

    protected:
        void OnMouseDown(const MouseEvent& event) override;
        void OnMouseMove(const MouseEvent& event) override;
        void OnMouseUp(const MouseEvent& event) override;
        void OnPointerCancel(const MouseEvent& event) override;
        void OnMouseWheel(const WheelEvent& event) override;
        void OnContextMenu(const MouseEvent& event) override;
        void OnKeyDown(const KeyEvent& event) override;
        void OnTextStyleChange() override
        {
            m_text.SetFont(GetFont());
            m_text.SetFontSelection(GetFontService(), GetTextStyle().FontFamily.AsView(), GetTextStyle().Selection);
            m_text.SetColor(GetTextColor());
            m_text.SetAlignment(TextHAlign::Start, TextVAlign::Top);
        }
        [[nodiscard]] Cursor GetCursorNow() const override { return m_drag == Drag::Pan ? Cursor::Grabbing : UIWidget::GetCursorNow(); }
        void OnDraw(DrawContext& ctx, const Rect& localBounds) override;

    private:
        enum class Drag : u8
        {
            None,
            Pending, // pressed on a key, not moved past the threshold
            Keys,
            Handle,
            Box,
            Pan,
        };

        [[nodiscard]] static bool Near(core::Float2 a, core::Float2 b) noexcept
        {
            return core::Abs(a.x - b.x) <= kHitRadius && core::Abs(a.y - b.y) <= kHitRadius;
        }
        [[nodiscard]] bool HasSelectedOn(usize curve) const noexcept
        {
            for (const CurveKeyRef& ref : m_selection)
                if (ref.Curve == curve)
                    return true;
            return false;
        }
        void Select(const CurveKeyRef& key, bool on)
        {
            for (usize i = 0; i < m_selection.Size(); ++i)
                if (m_selection[i] == key)
                {
                    if (!on)
                        m_selection.RemoveAt(i);
                    return;
                }
            if (on)
                m_selection.PushBack(key);
        }
        template <typename F>
        void EditSelected(F&& change)
        {
            if (!m_source || m_selection.IsEmpty())
                return;
            m_source->BeginKeysEdit();
            for (usize c = 0; c < m_source->CurveCount(); ++c)
            {
                if (!HasSelectedOn(c))
                    continue;
                core::Array<CurveKey> keys;
                for (const CurveKey& key : m_source->GetKeys(c))
                    keys.PushBack(key);
                for (const CurveKeyRef& ref : m_selection)
                    if (ref.Curve == c && ref.Index < keys.Size())
                        change(keys[ref.Index]);
                ApplyTangentModes(keys.AsSpan());
                m_source->PreviewKeys(c, keys.AsSpan());
            }
            m_source->CommitKeysEdit();
        }
        void Frame(bool selectionOnly);
        void BeginMove();
        void MoveTo(core::Float2 local, bool lockAxis);
        void DragHandle(core::Float2 local);
        void EndDrag(bool commit);
        void OpenMenu(core::Float2 local, core::Float2 screen);

        core::RefPtr<TimeAxis> m_axis;
        ICurveSource* m_source = nullptr;
        f32 m_valueLow = 0.0f;
        f32 m_valueHigh = 1.0f;
        core::Array<CurveKeyRef> m_selection;

        Drag m_drag = Drag::None;
        core::Float2 m_pressAt{};       // where the gesture began, its own space
        CurveKeyRef m_pressed;          // the key pressed (a move's or a handle's)
        bool m_handleOut = false;
        bool m_additive = false;        // Shift or Ctrl held at the press
        core::Array<core::Array<CurveKey>> m_original; // each curve's keys at the gesture's start
        core::Array<CurveKeyRef> m_originalSelection;
        f32 m_panTime = 0.0f;
        f32 m_panLow = 0.0f;
        f32 m_panHigh = 1.0f;
        core::Float2 m_boxTo{};
        core::RefPtr<Menu> m_menu;
        mutable Text m_text; // each value label in turn
    };

    // === Gestures ===

    inline void CurveView::OnMouseDown(const MouseEvent& event)
    {
        if (!m_source || !m_axis)
            return;
        const core::Float2 local = ConvertToNodeSpace(event.Position); // events come in screen space
        if (event.Button == MouseButton::Middle)
        {
            event.Handled = true;
            m_drag = Drag::Pan;
            m_pressAt = local;
            m_panTime = m_axis->Scroll();
            m_panLow = m_valueLow;
            m_panHigh = m_valueHigh;
            return;
        }
        if (event.Button != MouseButton::Left)
            return;
        event.Handled = true;
        RequestFocus();
        m_pressAt = local;
        m_boxTo = local;
        m_additive = (event.Modifiers & (KeyModShift | KeyModCtrl)) != 0;
        const CurveHit hit = HitTest(local);
        // A double click on the curve adds a key; on a key it is a click (a Shift+click soon after
        // selecting a key takes it away again).
        if (event.ClickCount == 2 && hit.What == CurveHit::Kind::Curve)
        {
            (void)InsertKey(hit.Key.Curve, TimeAtX(local.x));
            m_drag = Drag::None;
            return;
        }
        switch (hit.What)
        {
        case CurveHit::Kind::TangentIn:
        case CurveHit::Kind::TangentOut:
            m_pressed = hit.Key;
            m_handleOut = hit.What == CurveHit::Kind::TangentOut;
            m_drag = Drag::Handle;
            BeginMove();
            break;
        case CurveHit::Kind::Key:
            m_pressed = hit.Key;
            if (m_additive)
                Select(hit.Key, !IsSelected(hit.Key));
            else if (!IsSelected(hit.Key))
            {
                m_selection.Clear();
                m_selection.PushBack(hit.Key);
            }
            m_drag = IsSelected(hit.Key) ? Drag::Pending : Drag::None;
            break;
        default:
            if (!m_additive)
                m_selection.Clear();
            m_drag = Drag::Box;
            break;
        }
        Invalidate();
    }
    inline void CurveView::OnMouseMove(const MouseEvent& event)
    {
        if (m_drag == Drag::None || !m_source || !m_axis)
            return;
        const core::Float2 local = ConvertToNodeSpace(event.Position);
        switch (m_drag)
        {
        case Drag::Pending:
            if (core::Abs(local.x - m_pressAt.x) < kDragThreshold && core::Abs(local.y - m_pressAt.y) < kDragThreshold)
                return;
            m_drag = Drag::Keys;
            BeginMove();
            MoveTo(local, (event.Modifiers & KeyModShift) != 0);
            break;
        case Drag::Keys:
            MoveTo(local, (event.Modifiers & KeyModShift) != 0);
            break;
        case Drag::Handle:
            DragHandle(local);
            break;
        case Drag::Box:
            m_boxTo = local;
            Invalidate();
            break;
        case Drag::Pan:
        {
            const Rect box = GetContentBounds();
            const f32 perPixel = box.height > 0.0f ? (m_panHigh - m_panLow) / box.height : 0.0f;
            const f32 shift = (local.y - m_pressAt.y) * perPixel;
            m_valueLow = m_panLow + shift;
            m_valueHigh = m_panHigh + shift;
            m_axis->SetScroll(m_panTime - (local.x - m_pressAt.x) / m_axis->PixelsPerSecond());
            Invalidate();
            break;
        }
        default:
            break;
        }
    }
    inline void CurveView::OnMouseUp(const MouseEvent& event)
    {
        if (m_drag == Drag::Pan)
        {
            if (event.Button == MouseButton::Middle)
                m_drag = Drag::None;
            return;
        }
        if (event.Button != MouseButton::Left)
            return;
        if (m_drag == Drag::Box && m_source)
        {
            const core::Float2 to = ConvertToNodeSpace(event.Position);
            const f32 left = core::Min(m_pressAt.x, to.x), right = core::Max(m_pressAt.x, to.x);
            const f32 top = core::Min(m_pressAt.y, to.y), bottom = core::Max(m_pressAt.y, to.y);
            for (usize c = 0; c < m_source->CurveCount(); ++c)
            {
                if (m_source->GetCurveInfo(c).Locked)
                    continue;
                const core::Span<const CurveKey> keys = m_source->GetKeys(c);
                for (usize i = 0; i < keys.Size(); ++i)
                {
                    const core::Float2 at = KeyPoint(keys[i].time, keys[i].value);
                    if (at.x >= left && at.x <= right && at.y >= top && at.y <= bottom)
                        Select(CurveKeyRef{c, i}, true);
                }
            }
            m_drag = Drag::None;
            Invalidate();
            return;
        }
        if (m_drag == Drag::Pending && !m_additive)
        {
            // A click on a key of several selected selects it alone.
            m_selection.Clear();
            m_selection.PushBack(m_pressed);
            Invalidate();
        }
        EndDrag(true);
    }
    inline void CurveView::OnPointerCancel(const MouseEvent&) { EndDrag(false); }
    inline void CurveView::OnKeyDown(const KeyEvent& event)
    {
        const KeyCode key = static_cast<KeyCode>(event.KeyCode);
        if (key == KeyCode::Escape && (m_drag == Drag::Keys || m_drag == Drag::Handle))
        {
            event.Handled = true;
            EndDrag(false);
            return;
        }
        if (event.Modifiers == 0 && (key == KeyCode::Delete || key == KeyCode::Backspace) && m_drag == Drag::None)
            event.Handled = DeleteSelected();
    }
    inline void CurveView::OnMouseWheel(const WheelEvent& event)
    {
        if (!m_axis)
            return;
        const f32 steps = event.Delta.y != 0.0f ? event.Delta.y : event.Delta.x; // Shift may turn the wheel sideways
        if (steps == 0.0f)
            return;
        event.Handled = true;
        const core::Float2 local = ConvertToNodeSpace(event.Position);
        const f32 factor = core::Pow(1.2f, steps);
        const bool timeOnly = (event.Modifiers & KeyModCtrl) != 0;
        const bool valueOnly = (event.Modifiers & KeyModShift) != 0;
        if (!valueOnly)
            m_axis->ZoomAbout(TimeAtX(local.x), factor);
        if (!timeOnly)
        {
            const f32 value = ValueAtY(local.y);
            SetValueRange(value - (value - m_valueLow) / factor, value + (m_valueHigh - value) / factor);
        }
        Invalidate();
    }
    inline void CurveView::OnContextMenu(const MouseEvent& event)
    {
        if (!m_source)
            return;
        event.Handled = true;
        OpenMenu(ConvertToNodeSpace(event.Position), event.Position);
    }

    inline void CurveView::BeginMove()
    {
        m_original.Clear();
        for (usize c = 0; c < m_source->CurveCount(); ++c)
        {
            core::Array<CurveKey> keys;
            for (const CurveKey& key : m_source->GetKeys(c))
                keys.PushBack(key);
            m_original.PushBack(core::Move(keys));
        }
        m_originalSelection.Clear();
        for (const CurveKeyRef& ref : m_selection)
            m_originalSelection.PushBack(ref);
        m_source->BeginKeysEdit();
    }
    inline void CurveView::MoveTo(core::Float2 local, bool lockAxis)
    {
        if (m_pressed.Curve >= m_original.Size() || m_pressed.Index >= m_original[m_pressed.Curve].Size())
            return;
        const CurveKey& anchor = m_original[m_pressed.Curve][m_pressed.Index];
        f32 dt = TimeAtX(local.x) - TimeAtX(m_pressAt.x);
        f32 dv = ValueAtY(local.y) - ValueAtY(m_pressAt.y);
        if (lockAxis)
        {
            if (core::Abs(local.x - m_pressAt.x) >= core::Abs(local.y - m_pressAt.y))
                dv = 0.0f;
            else
                dt = 0.0f;
        }
        dt = m_axis->Snap(anchor.time + dt) - anchor.time; // the pressed key lands on a frame; the rest keep their spacing
        core::Array<CurveKeyRef> selection;
        for (usize c = 0; c < m_original.Size(); ++c)
        {
            bool any = false;
            for (const CurveKeyRef& ref : m_originalSelection)
                any = any || ref.Curve == c;
            if (!any)
                continue;
            const CurveInfo info = m_source->GetCurveInfo(c);
            core::Array<CurveKey> keys;
            core::Array<bool> moved;
            for (usize i = 0; i < m_original[c].Size(); ++i)
            {
                CurveKey key = m_original[c][i];
                bool selected = false;
                for (const CurveKeyRef& ref : m_originalSelection)
                    selected = selected || (ref.Curve == c && ref.Index == i);
                if (selected)
                {
                    key.time = core::Clamp(key.time + dt, 0.0f, m_axis->Duration());
                    key.value += dv;
                    if (info.HasRange)
                        key.value = core::Clamp(key.value, info.Min, info.Max);
                }
                keys.PushBack(key);
                moved.PushBack(selected);
            }
            // Sorted by time again, stably: a moved key passes the others, ties keep their order.
            for (usize i = 1; i < keys.Size(); ++i)
                for (usize j = i; j > 0 && keys[j].time < keys[j - 1].time; --j)
                {
                    core::Swap(keys[j], keys[j - 1]);
                    const bool m = moved[j];
                    moved[j] = moved[j - 1];
                    moved[j - 1] = m;
                }
            ApplyTangentModes(keys.AsSpan());
            m_source->PreviewKeys(c, keys.AsSpan());
            for (usize n = 0; n < keys.Size(); ++n)
            {
                if (!moved[n])
                    continue;
                selection.PushBack(CurveKeyRef{c, n});
            }
        }
        // The selection follows its keys to their places; each step starts again from the originals.
        m_selection = core::Move(selection);
        Invalidate();
    }
    inline void CurveView::DragHandle(core::Float2 local)
    {
        if (m_pressed.Curve >= m_original.Size() || m_pressed.Index >= m_original[m_pressed.Curve].Size())
            return;
        core::Array<CurveKey> keys;
        for (const CurveKey& key : m_original[m_pressed.Curve])
            keys.PushBack(key);
        CurveKey& key = keys[m_pressed.Index];
        f32 dt = TimeAtX(local.x) - key.time;
        const f32 dv = ValueAtY(local.y) - key.value;
        // A handle stays on its side of its key: past it, nearly upright.
        const f32 least = 1e-4f;
        if (m_handleOut)
            dt = core::Max(dt, least);
        else
            dt = core::Min(dt, -least);
        const f32 slope = dv / dt;
        if (key.tangentMode == CurveTangentMode::Auto || key.tangentMode == CurveTangentMode::Flat)
            key.tangentMode = CurveTangentMode::Smooth;
        if (key.tangentMode == CurveTangentMode::Smooth)
            key.tangentIn = key.tangentOut = slope;
        else if (m_handleOut)
            key.tangentOut = slope;
        else
            key.tangentIn = slope;
        ApplyTangentModes(keys.AsSpan());
        m_source->PreviewKeys(m_pressed.Curve, keys.AsSpan());
        Invalidate();
    }
    inline void CurveView::EndDrag(bool commit)
    {
        const Drag drag = m_drag;
        m_drag = Drag::None;
        if (drag != Drag::Keys && drag != Drag::Handle)
            return;
        if (!m_source)
            return;
        if (commit)
            m_source->CommitKeysEdit();
        else
        {
            m_source->CancelKeysEdit();
            m_selection = core::Move(m_originalSelection);
        }
        m_original.Clear();
        Invalidate();
    }

    inline void CurveView::Frame(bool selectionOnly)
    {
        if (!m_source || !m_axis)
            return;
        bool any = false;
        f32 t0 = 0.0f, t1 = 0.0f, v0 = 0.0f, v1 = 0.0f;
        bool rangedAny = false;
        f32 ranged = 0.0f, rangedHigh = 0.0f;
        const auto take = [&](f32 t, f32 v)
        {
            if (!any)
            {
                t0 = t1 = t;
                v0 = v1 = v;
                any = true;
                return;
            }
            t0 = core::Min(t0, t);
            t1 = core::Max(t1, t);
            v0 = core::Min(v0, v);
            v1 = core::Max(v1, v);
        };
        for (usize c = 0; c < m_source->CurveCount(); ++c)
        {
            const core::Span<const CurveKey> keys = m_source->GetKeys(c);
            if (selectionOnly)
            {
                for (const CurveKeyRef& ref : m_selection)
                    if (ref.Curve == c && ref.Index < keys.Size())
                        take(keys[ref.Index].time, keys[ref.Index].value);
                continue;
            }
            const CurveInfo info = m_source->GetCurveInfo(c);
            for (const CurveKey& key : keys)
                take(key.time, key.value);
            if (keys.Size() > 1) // the curve between its keys, an overshoot seen
                for (i32 s = 0; s <= 64; ++s)
                {
                    const f32 t = keys[0].time + (keys[keys.Size() - 1].time - keys[0].time) * static_cast<f32>(s) / 64.0f;
                    take(t, EvaluateCurve(keys, t));
                }
            if (info.HasRange)
            {
                ranged = !rangedAny ? info.Min : core::Min(ranged, info.Min);
                rangedHigh = !rangedAny ? info.Max : core::Max(rangedHigh, info.Max);
                rangedAny = true;
            }
        }
        if (!any)
            return;
        if (rangedAny) // a framing shows at least the ranges
        {
            v0 = core::Min(v0, ranged);
            v1 = core::Max(v1, rangedHigh);
        }
        if (t1 - t0 < 1e-4f)
        {
            t0 -= 0.5f;
            t1 += 0.5f;
        }
        if (v1 - v0 < 1e-4f)
        {
            v0 -= 1.0f;
            v1 += 1.0f;
        }
        const f32 timeMargin = (t1 - t0) * 0.05f;
        const f32 valueMargin = (v1 - v0) * 0.1f;
        m_axis->Frame(t0 - timeMargin, t1 + timeMargin, GetContentBounds().width);
        SetValueRange(v0 - valueMargin, v1 + valueMargin);
    }

    inline void CurveView::OpenMenu(core::Float2 local, core::Float2 screen)
    {
        Node* top = GetRootNode();
        if (top == nullptr)
            return;
        const CurveHit hit = HitTest(local);
        if (hit.What == CurveHit::Kind::Key && !IsSelected(hit.Key))
        {
            m_selection.Clear();
            m_selection.PushBack(hit.Key);
            Invalidate();
        }
        m_menu = core::MakeRef<Menu>(MemoryAllocator());
        ShareTextStyle(*m_menu, false);
        m_menu->SetAutoWidth(true);
        CurveView* self = this;
        if (hit.What == CurveHit::Kind::Key)
        {
            // Checked where every selected key agrees.
            bool sameInterp = true, sameMode = true;
            CurveKeyInterpolation interp = CurveKeyInterpolation::Cubic;
            CurveTangentMode mode = CurveTangentMode::Auto;
            for (usize n = 0; n < m_selection.Size(); ++n)
            {
                const CurveKey& key = m_source->GetKeys(m_selection[n].Curve)[m_selection[n].Index];
                if (n == 0)
                {
                    interp = key.interpolation;
                    mode = key.tangentMode;
                }
                sameInterp = sameInterp && key.interpolation == interp;
                sameMode = sameMode && key.tangentMode == mode;
            }
            const struct
            {
                const char8_t* Name;
                CurveKeyInterpolation Value;
            } interps[] = {{u8"Constant", CurveKeyInterpolation::Constant}, {u8"Linear", CurveKeyInterpolation::Linear}, {u8"Cubic", CurveKeyInterpolation::Cubic}};
            for (const auto& item : interps)
            {
                const CurveKeyInterpolation value = item.Value;
                m_menu->AddCheckItem(core::StringView(item.Name), sameInterp && interp == value, [self, value](bool) { self->SetInterpolation(value); });
            }
            m_menu->AddSeparator();
            const struct
            {
                const char8_t* Name;
                CurveTangentMode Value;
            } modes[] = {{u8"Auto", CurveTangentMode::Auto}, {u8"Smooth", CurveTangentMode::Smooth}, {u8"Flat", CurveTangentMode::Flat}, {u8"Broken", CurveTangentMode::Broken}};
            for (const auto& item : modes)
            {
                const CurveTangentMode value = item.Value;
                m_menu->AddCheckItem(core::StringView(item.Name), sameMode && mode == value, [self, value](bool) { self->SetTangentMode(value); });
            }
            m_menu->AddSeparator();
            m_menu->AddItem(core::StringView(u8"Delete"), [self]() { (void)self->DeleteSelected(); });
        }
        else
        {
            m_menu->AddItem(core::StringView(u8"Frame all"), [self]() { self->FrameAll(); });
            MenuItem* selected = m_menu->AddItem(core::StringView(u8"Frame selection"), [self]() { self->FrameSelection(); });
            selected->SetEnabled(!m_selection.IsEmpty());
        }
        m_menu->Open(*this, top->ConvertToNodeSpace(screen));
    }

    // === Drawing ===

    inline void CurveView::OnDraw(DrawContext& ctx, const Rect& localBounds)
    {
        UIWidget::OnDraw(ctx, localBounds);
        if (!m_axis)
            return;
        const Rect box = GetContentBounds();
        ctx.PushClip(box);
        const auto partColor = [this](const char8_t* name, Color fallback)
        {
            const PartStyle& part = GetPartStyle(name);
            Color color = part.HasBackground ? part.Box.BackgroundColor : fallback;
            color.a *= part.Opacity;
            return color;
        };
        // The grid: a line at each labelled time, and at each value step, labelled.
        const Color grid = partColor(u8"grid", Color{1.0f, 1.0f, 1.0f, 0.08f});
        const f32 timeStep = m_axis->TickStep(TimeRuler::kMinLabelSpacing);
        for (i64 i = static_cast<i64>(core::Ceil(m_axis->Scroll() / timeStep));; ++i)
        {
            const f32 offset = m_axis->TimeToOffset(static_cast<f32>(i) * timeStep);
            if (offset > box.width)
                break;
            ctx.VG().FillRect(Rectangle{core::Floor(box.x + offset), box.y, 1.0f, box.height}, grid);
        }
        const f32 range = m_valueHigh - m_valueLow;
        f32 valueStep = 1.0f;
        if (box.height > 0.0f)
        {
            const f32 least = range * 30.0f / box.height; // labels 30 px apart at least
            const f32 magnitude = core::Pow(10.0f, core::Floor(core::Log(least) / core::Log(10.0f)));
            valueStep = 10.0f * magnitude;
            const f32 multiples[] = {1.0f, 2.0f, 5.0f};
            for (const f32 m : multiples)
                if (m * magnitude >= least * 0.9999f)
                {
                    valueStep = m * magnitude;
                    break;
                }
        }
        for (i64 i = static_cast<i64>(core::Ceil(m_valueLow / valueStep)); static_cast<f32>(i) * valueStep <= m_valueHigh; ++i)
        {
            const f32 value = static_cast<f32>(i) * valueStep;
            const f32 y = KeyPoint(0.0f, value).y;
            ctx.VG().FillRect(Rectangle{box.x, core::Floor(y), box.width, 1.0f}, grid);
            if (m_text.HasFont())
            {
                m_text.SetString(FormatStepped(value, valueStep).AsView());
                m_text.Draw(ctx, core::Float2{box.x + 3.0f, y + 1.0f});
            }
        }
        if (m_source)
        {
            const Color selected = partColor(u8"selected", Color{1.0f, 1.0f, 1.0f, 1.0f});
            for (usize c = 0; c < m_source->CurveCount(); ++c)
            {
                const CurveInfo info = m_source->GetCurveInfo(c);
                const core::Span<const CurveKey> keys = m_source->GetKeys(c);
                Color stroke = info.StrokeColor;
                if (info.Locked)
                    stroke.a *= 0.45f;
                if (!keys.IsEmpty())
                {
                    vg::PathBuilder line;
                    for (f32 x = 0.0f; x <= box.width + 2.0f; x += 2.0f)
                    {
                        const f32 t = m_axis->OffsetToTime(x);
                        const core::Float2 at = KeyPoint(t, EvaluateCurve(keys, t));
                        if (x == 0.0f)
                            line.MoveTo(at.x, at.y);
                        else
                            line.LineTo(at.x, at.y);
                    }
                    ctx.VG().StrokePath(line.ToPath(), stroke, vg::StrokeStyle(1.5f));
                }
                for (usize i = 0; i < keys.Size(); ++i)
                {
                    const bool on = IsSelected(CurveKeyRef{c, i});
                    const core::Float2 at = KeyPoint(keys[i].time, keys[i].value);
                    const bool sides[] = {false, true};
                    if (on)
                        for (const bool out : sides)
                        {
                            if (!HasHandle(keys, i, out))
                                continue;
                            const core::Float2 handle = HandlePoint(keys[i], out);
                            vg::PathBuilder arm;
                            arm.MoveTo(at.x, at.y);
                            arm.LineTo(handle.x, handle.y);
                            ctx.VG().StrokePath(arm.ToPath(), selected, vg::StrokeStyle(1.0f));
                            vg::PathBuilder knob;
                            vg::ShapeBuilder::BuildCircle(handle, 3.0f, knob);
                            ctx.VG().FillPath(knob.ToPath(), selected);
                        }
                    vg::PathBuilder diamond;
                    const f32 r = on ? 5.0f : 4.0f;
                    diamond.MoveTo(at.x, at.y - r);
                    diamond.LineTo(at.x + r, at.y);
                    diamond.LineTo(at.x, at.y + r);
                    diamond.LineTo(at.x - r, at.y);
                    diamond.Close();
                    ctx.VG().FillPath(diamond.ToPath(), on ? selected : stroke);
                }
            }
        }
        const Color playhead = partColor(u8"playhead", Color{0.31f, 0.61f, 1.0f, 1.0f});
        ctx.VG().FillRect(Rectangle{core::Floor(box.x + m_axis->TimeToOffset(m_axis->Playhead())), box.y, 1.0f, box.height}, playhead);
        if (m_drag == Drag::Box)
        {
            Color fill = partColor(u8"selection-box", Color{0.31f, 0.61f, 1.0f, 0.2f});
            const Rect area{core::Min(m_pressAt.x, m_boxTo.x), core::Min(m_pressAt.y, m_boxTo.y), core::Abs(m_boxTo.x - m_pressAt.x),
                            core::Abs(m_boxTo.y - m_pressAt.y)};
            ctx.VG().FillRect(area.ToRectangle(), fill);
        }
        ctx.PopClip();
    }
}
