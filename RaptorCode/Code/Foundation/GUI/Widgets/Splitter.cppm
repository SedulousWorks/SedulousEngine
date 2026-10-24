// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :splitter partition
//
// Splitter: panes side by side (or one above another) with a handle between each two that resizes
// them (D0 of Specs/gui-lab-evolution-3.md). The one splitter (round three's ruling 6): docking's
// splits and every other split are this widget.
//
// Its children are its panes, laid out along its axis by their weights. Each pane gets at least
// its minimum along the axis: its sheet's min-width (or min-height), else none. Not its content's:
// the user alone moves a handle, so a pane whose content grows (a tab shown with longer text) wraps
// or clips it where it stands rather than pushing its neighbours. When even the minimums do not
// fit, it gives them and clips what passes its end.
//
// A SplitterHandle sits between each two panes, kept in step as panes come and go (a pane added in
// markup or by a script gets its handle). A handle is a widget of its own: focusable, read as a
// separator whose value is where it stands, dragged by the pointer, moved by the arrow keys along
// the axis (Shift for longer steps; Home and End to its limits), and a double click gives the panes
// back the shares they were given. A resize moves the two panes either side of the handle alone; a
// pane that goes gives its share to its neighbours, the other panes keeping theirs.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:splitter;

import foundation.core; // Array, Float2, Function, Max, Min, Clamp, RefPtr, String
import :rect;
import :event;
import :draw_context;
import :layout_style;
import :ui_widget;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    class Splitter;

    /// Which way a Splitter's panes go.
    enum class SplitterAxis : u8
    {
        Horizontal, ///< side by side, from the inline start
        Vertical,   ///< one above another
    };

    /// The handle between two of a Splitter's panes.
    class SplitterHandle : public UIWidget
    {
        RTTI_OBJECT(SplitterHandle, UIWidget)
    public:
        /// How far an arrow key moves it, and with Shift.
        static constexpr f32 kStep = 8.0f;
        static constexpr f32 kLongStep = 48.0f;

        SplitterHandle()
        {
            SetTag(core::StringView(u8"splitter-handle"));
            SetTabFocusable(true);
            StyleWriteScope defaults(*this); // its own values, which a sheet returns to
            EditLayoutStyle([](LayoutStyle& s) { s.Shrink = 0.0f; });
        }

        /// Where it stands, as a screen reader reads a separator: the share of the panes' room
        /// before it, 0 to 100.
        [[nodiscard]] f64 GetValue() const;
        void SetValue(f64 value);
        [[nodiscard]] f64 GetMin() const noexcept { return 0.0; }
        [[nodiscard]] f64 GetMax() const noexcept { return 100.0; }
        /// How thick it is along its splitter's axis, when its sheet does not size it.
        void SetThickness(f32 thickness)
        {
            m_thickness = Max(0.0f, thickness);
            RequestLayout();
        }
        [[nodiscard]] f32 GetThickness() const noexcept { return m_thickness; }

        [[nodiscard]] Splitter* GetSplitter() const;
        /// Its place among its splitter's handles.
        [[nodiscard]] usize GetIndex() const;

        [[nodiscard]] core::Float2 MeasureContent(core::Float2) override;

    protected:
        [[nodiscard]] bool OwnsPressDrag(core::Float2) const override { return true; }
        void OnMouseDown(const MouseEvent& event) override;
        void OnMouseMove(const MouseEvent& event) override;
        void OnMouseUp(const MouseEvent&) override { m_dragging = false; }
        void OnPointerCancel(const MouseEvent&) override { m_dragging = false; }
        void OnKeyDown(const KeyEvent& event) override;

    private:
        [[nodiscard]] bool Horizontal() const;
        f32 m_thickness = 6.0f;
        f32 m_grab = 0.0f; // where along it the press took it, in its own space
        bool m_dragging = false;
    };

    class Splitter : public UIWidget
    {
        RTTI_OBJECT(Splitter, UIWidget)
    public:
        Splitter()
        {
            SetTag(core::StringView(u8"splitter"));
            StyleWriteScope defaults(*this);
            EditLayoutStyle([](LayoutStyle& s)
            {
                s.OverflowX = Overflow::Hidden; // what passes its end when the minimums do not fit
                s.OverflowY = Overflow::Hidden;
            });
        }

        [[nodiscard]] SplitterAxis GetAxis() const noexcept { return m_axis; }
        void SetAxis(SplitterAxis axis)
        {
            if (axis == m_axis)
                return;
            m_axis = axis;
            for (const RefPtr<SplitterHandle>& handle : m_handles)
            {
                MarkAxis(*handle);
                handle->RequestLayout(); // its thickness lies along the other axis now
            }
            RequestLayout();
        }
        /// Markup's and a sheet's `axis`: horizontal or vertical.
        [[nodiscard]] core::String GetAxisName() const
        {
            return core::String(m_axis == SplitterAxis::Vertical ? u8"vertical" : u8"horizontal");
        }
        void SetAxisName(const core::String& name)
        {
            SetAxis(name.AsView() == core::StringView(u8"vertical") ? SplitterAxis::Vertical : SplitterAxis::Horizontal);
        }

        [[nodiscard]] usize GetPaneCount() const noexcept { return m_panes.Size(); }
        [[nodiscard]] Node* GetPane(usize index) const noexcept { return index < m_panes.Size() ? m_panes[index].Pane : nullptr; }
        [[nodiscard]] SplitterHandle* GetHandle(usize index) const noexcept { return index < m_handles.Size() ? m_handles[index].Get() : nullptr; }

        /// The panes' shares, in order (any scale: 1 2 1 gives the middle pane half). They are what
        /// a double click on a handle gives back; panes past them take an even share.
        void SetWeights(Span<const f32> weights)
        {
            m_given.Clear();
            for (const f32 weight : weights)
                m_given.PushBack(weight);
            ResetWeights();
        }
        /// Markup's and a sheet's `weights`: the shares, separated by spaces.
        [[nodiscard]] core::String GetWeightsText() const;
        void SetWeightsText(const core::String& text);
        /// Each pane's share now, adding up to 1.
        [[nodiscard]] Array<f32> GetWeights() const;
        /// The given shares back (an even share where none was given).
        void ResetWeights()
        {
            for (usize i = 0; i < m_panes.Size(); ++i)
                m_panes[i].Weight = i < m_given.Size() && m_given[i] > 0.0f ? m_given[i] : 1.0f;
            RequestLayout();
            Changed();
        }

        /// Moves handle `index` so it starts `position` along the axis in this splitter's content
        /// box (physical: from the left, or the top), as far as the two panes' minimums let it.
        void MoveHandleTo(usize index, f32 position);
        /// The panes' sizes along the axis as last laid out, in order.
        [[nodiscard]] const Array<f32>& GetPaneSizes() const noexcept { return m_sizes; }

        /// After a handle moved or the shares were reset (what a dock layout writes back).
        void SetOnResized(Function<void()> callback) { m_onResized = core::Move(callback); }

        [[nodiscard]] core::Float2 MeasureContent(core::Float2 available) override;

    protected:
        void OnChildrenChanged() override { SyncPanes(); }
        void OnLayout() override;

    private:
        friend class SplitterHandle;
        struct PaneState
        {
            Node* Pane = nullptr; // one of its children
            f32 Weight = 1.0f;
        };

        [[nodiscard]] bool Horizontal() const noexcept { return m_axis == SplitterAxis::Horizontal; }
        [[nodiscard]] f32 Along(core::Float2 v) const noexcept { return Horizontal() ? v.x : v.y; }
        void MarkAxis(SplitterHandle& handle) const
        {
            handle.RemoveClass(core::StringView(Horizontal() ? u8"vertical" : u8"horizontal"));
            handle.AddClass(core::StringView(Horizontal() ? u8"horizontal" : u8"vertical"));
            handle.SetCursor(Horizontal() ? Cursor::EwResize : Cursor::NsResize);
        }
        // A pane's least size along the axis: its sheet's minimum, else none.
        [[nodiscard]] f32 MinimumOf(const Node& pane) const;
        // The panes found among the children again, a handle between each two, the children in
        // that order; a pane gone gives its share to its neighbours.
        void SyncPanes();
        void Changed()
        {
            if (m_onResized)
                m_onResized();
        }

        SplitterAxis m_axis = SplitterAxis::Horizontal;
        Array<PaneState> m_panes;
        Array<RefPtr<SplitterHandle>> m_handles;
        Array<f32> m_given;
        Array<f32> m_sizes;      // each pane's size along the axis, as last laid out
        Array<f32> m_minimums;   // and its minimum
        Array<f32> m_thickness;  // each handle's
        bool m_syncing = false;
        Function<void()> m_onResized;
    };

    // === SplitterHandle ===

    inline Splitter* SplitterHandle::GetSplitter() const { return core::Cast<Splitter>(GetParent()); }
    inline bool SplitterHandle::Horizontal() const
    {
        const Splitter* splitter = GetSplitter();
        return splitter == nullptr || splitter->GetAxis() == SplitterAxis::Horizontal;
    }
    inline usize SplitterHandle::GetIndex() const
    {
        if (const Splitter* splitter = GetSplitter())
            for (usize i = 0; i < splitter->m_handles.Size(); ++i)
                if (splitter->m_handles[i].Get() == this)
                    return i;
        return 0;
    }
    inline core::Float2 SplitterHandle::MeasureContent(core::Float2)
    {
        return Horizontal() ? core::Float2{m_thickness, 0.0f} : core::Float2{0.0f, m_thickness};
    }
    inline f64 SplitterHandle::GetValue() const
    {
        const Splitter* splitter = GetSplitter();
        if (splitter == nullptr)
            return 0.0;
        f32 before = 0.0f, all = 0.0f;
        for (usize i = 0; i < splitter->m_sizes.Size(); ++i)
        {
            all += splitter->m_sizes[i];
            if (i <= GetIndex())
                before += splitter->m_sizes[i];
        }
        return all > 0.0f ? 100.0 * static_cast<f64>(before) / static_cast<f64>(all) : 0.0;
    }
    inline void SplitterHandle::SetValue(f64 value)
    {
        Splitter* splitter = GetSplitter();
        if (splitter == nullptr)
            return;
        f32 all = 0.0f;
        for (const f32 size : splitter->m_sizes)
            all += size;
        f32 position = static_cast<f32>(Clamp(value, 0.0, 100.0) / 100.0) * all;
        for (usize i = 0; i < GetIndex() && i < splitter->m_thickness.Size(); ++i)
            position += splitter->m_thickness[i];
        if (splitter->IsRightToLeft() && Horizontal())
            position = splitter->GetContentBounds().width - position - GetSize().x; // its value runs from the inline start
        splitter->MoveHandleTo(GetIndex(), position);
    }
    inline void SplitterHandle::OnMouseDown(const MouseEvent& event)
    {
        if (event.Button != MouseButton::Left)
            return;
        event.Handled = true;
        if (event.ClickCount >= 2)
        {
            if (Splitter* splitter = GetSplitter())
                splitter->ResetWeights();
            return;
        }
        m_dragging = true;
        const core::Float2 local = ConvertToNodeSpace(event.Position); // events come in screen space
        m_grab = Horizontal() ? local.x : local.y;
    }
    inline void SplitterHandle::OnMouseMove(const MouseEvent& event)
    {
        Splitter* splitter = GetSplitter();
        if (!m_dragging || splitter == nullptr)
            return;
        // The pointer in the splitter's content box, less where along the handle it was taken.
        const Rect box = splitter->GetContentBounds();
        const core::Float2 local = splitter->ConvertToNodeSpace(event.Position);
        const f32 at = Horizontal() ? local.x - box.x : local.y - box.y;
        splitter->MoveHandleTo(GetIndex(), at - m_grab);
    }
    inline void SplitterHandle::OnKeyDown(const KeyEvent& event)
    {
        Splitter* splitter = GetSplitter();
        if (splitter == nullptr)
            return;
        const f32 step = (event.Modifiers & KeyModShift) != 0 ? kLongStep : kStep;
        const Rect box = splitter->GetContentBounds();
        const f32 here = Horizontal() ? GetPosition().x - box.x : GetPosition().y - box.y;
        f32 to = here;
        const KeyCode key = static_cast<KeyCode>(event.KeyCode);
        if ((Horizontal() && key == KeyCode::Left) || (!Horizontal() && key == KeyCode::Up))
            to = here - step;
        else if ((Horizontal() && key == KeyCode::Right) || (!Horizontal() && key == KeyCode::Down))
            to = here + step;
        else if (key == KeyCode::Home)
            to = splitter->IsRightToLeft() && Horizontal() ? 1.0e9f : -1.0e9f; // the inline start
        else if (key == KeyCode::End)
            to = splitter->IsRightToLeft() && Horizontal() ? -1.0e9f : 1.0e9f;
        else
            return;
        event.Handled = true;
        splitter->MoveHandleTo(GetIndex(), to);
    }

    // === Splitter ===

    inline core::String Splitter::GetWeightsText() const
    {
        core::String out;
        for (usize i = 0; i < m_given.Size(); ++i)
        {
            if (i != 0)
                out.Append(core::StringView(u8" "));
            out.Append(core::Format(u8"{}", m_given[i]).AsView());
        }
        return out;
    }
    inline void Splitter::SetWeightsText(const core::String& text)
    {
        Array<f32> weights;
        const core::StringView all = text.AsView();
        usize start = 0;
        for (usize i = 0; i <= all.Size(); ++i)
            if (i == all.Size() || all[i] == u8' ' || all[i] == u8',')
            {
                if (i > start)
                    weights.PushBack(static_cast<f32>(ParseFloat(all.SubStr(start, i - start)).ValueOr(1.0)));
                start = i + 1;
            }
        SetWeights(Span<const f32>(weights.Data(), weights.Size()));
    }
    inline Array<f32> Splitter::GetWeights() const
    {
        Array<f32> out;
        f32 sum = 0.0f;
        for (const PaneState& pane : m_panes)
            sum += pane.Weight;
        for (const PaneState& pane : m_panes)
            out.PushBack(sum > 0.0f ? pane.Weight / sum : 0.0f);
        return out;
    }

    inline f32 Splitter::MinimumOf(const Node& pane) const
    {
        const LayoutStyle& s = pane.GetLayoutStyle();
        const Rect box = GetContentBounds();
        const Optional<f32> given = (Horizontal() ? s.MinWidth : s.MinHeight).Resolve(Horizontal() ? box.width : box.height);
        return given.HasValue() ? Max(0.0f, given.Value()) : 0.0f;
    }

    inline void Splitter::SyncPanes()
    {
        if (m_syncing)
            return;
        m_syncing = true;
        // The panes, in the children's order.
        Array<Node*> found;
        for (usize i = 0; i < ChildCount(); ++i)
            if (Node* child = GetChildAt(i); core::Cast<SplitterHandle>(child) == nullptr)
                found.PushBack(child);
        // Shares: a pane that stays keeps its own; one that went gives its share to its
        // neighbours that stay, in proportion to theirs; a new one takes its given share, or the
        // average of the others'.
        Array<PaneState> before = core::Move(m_panes);
        const auto stays = [&found](const Node* pane)
        {
            for (const Node* f : found)
                if (f == pane)
                    return true;
            return false;
        };
        for (usize i = 0; i < before.Size(); ++i)
        {
            if (stays(before[i].Pane))
                continue;
            PaneState* previous = nullptr;
            PaneState* next = nullptr;
            for (usize j = i; j > 0; --j)
                if (stays(before[j - 1].Pane))
                {
                    previous = &before[j - 1];
                    break;
                }
            for (usize j = i + 1; j < before.Size(); ++j)
                if (stays(before[j].Pane))
                {
                    next = &before[j];
                    break;
                }
            const f32 gone = before[i].Weight;
            const f32 both = (previous != nullptr ? previous->Weight : 0.0f) + (next != nullptr ? next->Weight : 0.0f);
            if (previous != nullptr)
                previous->Weight += both > 0.0f ? gone * previous->Weight / both : gone;
            if (next != nullptr)
                next->Weight += both > 0.0f ? gone * next->Weight / both : (previous != nullptr ? 0.0f : gone);
        }
        f32 kept = 0.0f;
        usize keptCount = 0;
        for (const PaneState& state : before)
            if (stays(state.Pane))
            {
                kept += state.Weight;
                ++keptCount;
            }
        for (usize i = 0; i < found.Size(); ++i)
        {
            PaneState state{found[i], 0.0f};
            bool known = false;
            for (const PaneState& old : before)
                if (old.Pane == found[i])
                {
                    state.Weight = old.Weight;
                    known = true;
                }
            if (!known)
                state.Weight = i < m_given.Size() && m_given[i] > 0.0f ? m_given[i] : (keptCount > 0 ? kept / static_cast<f32>(keptCount) : 1.0f);
            m_panes.PushBack(state);
        }
        // A handle between each two panes.
        const usize wanted = m_panes.Size() > 0 ? m_panes.Size() - 1 : 0;
        while (m_handles.Size() > wanted)
        {
            m_handles.Back()->RemoveFromParent();
            m_handles.PopBack();
        }
        while (m_handles.Size() < wanted)
        {
            RefPtr<SplitterHandle> handle = MakeRef<SplitterHandle>(MemoryAllocator());
            MarkAxis(*handle);
            m_handles.PushBack(handle);
        }
        // The children in order: a pane, a handle, a pane, ... (focus and a screen reader go so).
        usize at = 0;
        for (usize i = 0; i < m_panes.Size(); ++i)
        {
            Node* nodes[2] = {m_panes[i].Pane, i < m_handles.Size() ? m_handles[i].Get() : nullptr};
            for (Node* node : nodes)
            {
                if (node == nullptr)
                    continue;
                if (GetChildAt(at) != node)
                {
                    RefPtr<Node> keep(node); // held while it moves
                    if (node->GetParent() == this)
                        node->RemoveFromParent();
                    (void)AddChildAt(node, at);
                }
                ++at;
            }
        }
        m_syncing = false;
        RequestLayout();
    }

    inline core::Float2 Splitter::MeasureContent(core::Float2 available)
    {
        (void)available;
        core::Float2 out{0.0f, 0.0f};
        for (usize i = 0; i < ChildCount(); ++i)
        {
            Node* child = GetChildAt(i);
            const core::Float2 size = child->Measure(LayoutConstraints{});
            if (Horizontal())
            {
                out.x += size.x;
                out.y = Max(out.y, size.y);
            }
            else
            {
                out.y += size.y;
                out.x = Max(out.x, size.x);
            }
        }
        return out;
    }

    inline void Splitter::OnLayout()
    {
        const Rect box = GetContentBounds();
        const f32 main = Horizontal() ? box.width : box.height;
        const usize count = m_panes.Size();
        m_thickness.Clear();
        f32 handles = 0.0f;
        for (const RefPtr<SplitterHandle>& handle : m_handles)
        {
            const f32 t = Along(handle->Measure(LayoutConstraints{}));
            m_thickness.PushBack(t);
            handles += t;
        }
        const f32 room = Max(0.0f, main - handles);
        m_minimums.Clear();
        f32 minimums = 0.0f;
        for (const PaneState& pane : m_panes)
        {
            const f32 least = MinimumOf(*pane.Pane);
            m_minimums.PushBack(least);
            minimums += least;
        }
        // Each pane's share of the room, then those below their minimums held at them and the rest
        // shared again among the others, until none is below; when the minimums alone pass the
        // room, each has its minimum and what passes the end is clipped.
        m_sizes.Resize(count);
        if (minimums >= room)
        {
            for (usize i = 0; i < count; ++i)
                m_sizes[i] = m_minimums[i];
        }
        else
        {
            Array<bool> held;
            held.Resize(count);
            for (usize i = 0; i < count; ++i)
                held[i] = false;
            for (usize round = 0; round <= count; ++round)
            {
                f32 free = room, weights = 0.0f;
                for (usize i = 0; i < count; ++i)
                {
                    if (held[i])
                        free -= m_minimums[i];
                    else
                        weights += m_panes[i].Weight;
                }
                bool more = false;
                for (usize i = 0; i < count; ++i)
                {
                    if (held[i])
                    {
                        m_sizes[i] = m_minimums[i];
                        continue;
                    }
                    m_sizes[i] = weights > 0.0f ? free * m_panes[i].Weight / weights : free / static_cast<f32>(count);
                    if (m_sizes[i] < m_minimums[i])
                    {
                        held[i] = true;
                        more = true;
                    }
                }
                if (!more)
                    break;
            }
        }
        // In order from the inline start (a horizontal splitter right to left runs from the right).
        const bool mirrored = Horizontal() && IsRightToLeft();
        f32 along = 0.0f;
        const auto place = [&](Node& node, f32 size)
        {
            Rect at;
            if (Horizontal())
            {
                const f32 x = mirrored ? box.x + box.width - along - size : box.x + along;
                at = Rect{x, box.y, size, box.height};
            }
            else
                at = Rect{box.x, box.y + along, box.width, size};
            node.Arrange(at);
            along += size;
        };
        for (usize i = 0; i < count; ++i)
        {
            place(*m_panes[i].Pane, m_sizes[i]);
            if (i < m_handles.Size())
                place(*m_handles[i], m_thickness[i]);
        }
        for (const RefPtr<SplitterHandle>& handle : m_handles)
            handle->MarkAccessDirty(); // its value moved
    }

    inline void Splitter::MoveHandleTo(usize index, f32 position)
    {
        if (index + 1 >= m_panes.Size() || index + 1 >= m_sizes.Size() || m_minimums.Size() != m_sizes.Size())
            return;
        // Where it starts now, from the inline start; the position taken there too.
        f32 start = 0.0f;
        for (usize i = 0; i <= index; ++i)
            start += m_sizes[i] + (i < index ? m_thickness[i] : 0.0f);
        if (Horizontal() && IsRightToLeft())
            position = GetContentBounds().width - position - m_thickness[index];
        const f32 a = m_sizes[index], b = m_sizes[index + 1];
        const f32 lowest = m_minimums[index], highest = a + b - m_minimums[index + 1];
        if (highest < lowest)
            return; // the two have no room to give each other
        const f32 to = Clamp(a + position - start, lowest, highest);
        if (to == a)
            return;
        // The two panes alone change, their shares keeping their sum.
        const f32 both = m_panes[index].Weight + m_panes[index + 1].Weight;
        m_panes[index].Weight = both * to / (a + b);
        m_panes[index + 1].Weight = both - m_panes[index].Weight;
        m_sizes[index] = to;
        m_sizes[index + 1] = a + b - to;
        RequestLayout();
        Changed();
    }

}
