// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - :dopesheet partition
//
// The dopesheet (T5 of Specs/gui-lab-evolution-3.md): a timeline source's channels as rows folded by
// their paths' segments (component, property, channel), a parent row showing the keys of every
// channel under it, on a shared TimeAxis (a curve view stands under it on the same axis). Mouse
// first:
//   - a click on a key selects it (a parent's selects every key under it at that time; Shift or Ctrl
//     adds or takes away), a drag from nothing selects by a box;
//   - a drag moves the selected keys in time (the pressed key on a frame with a frame rate, all kept
//     in the clip), previewed through the source and committed once, Escape giving it up; the
//     source's answer says where the keys went, so the selection follows them;
//   - Delete removes them; a double click on a channel's row inserts a key there (its value the
//     source's);
//   - a click on a row's name folds or opens it; the wheel over the names scrolls the rows, over
//     the keys zooms about the pointer; a middle drag pans.
// Its names are at the inline start (the right, right to left); time runs left to right in either
// direction, as the ruler's does, so a ruler and a curve view beside it start at its keys.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui.toolkit:dopesheet;

import foundation.core;
import foundation.vg;
import foundation.gui;
import :time_axis;
import :timeline_source;

using namespace foundation::core;
namespace core = foundation::core;
namespace vg = foundation::vg;

export namespace foundation::gui
{
    /// A row of a dopesheet: a segment of the channels' paths.
    struct DopesheetRow
    {
        core::String Path;      ///< the path to it ("Lamp.color")
        core::String Name;      ///< its last segment ("color")
        u32 Depth = 0;          ///< its segments less one
        i32 Channel = -1;       ///< the channel it is; -1: only a parent
        bool HasChildren = false;
        bool Folded = false;
    };

    class Dopesheet : public UIWidget, public ITimeAxisClient, public ITimelineSourceClient
    {
        RTTI_OBJECT(Dopesheet, UIWidget)
    public:
        static constexpr f32 kRowHeight = 20.0f;
        static constexpr f32 kIndent = 12.0f;
        static constexpr f32 kHitRadius = 5.0f;
        static constexpr f32 kDragThreshold = 3.0f;

        Dopesheet()
        {
            SetTag(core::StringView(u8"dopesheet"));
            SetTabFocusable(true);
        }
        ~Dopesheet() override
        {
            if (m_axis)
                m_axis->Leave(this);
            if (m_source)
                m_source->RemoveTimelineClient(this);
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
        /// The channels it shows (not owned: the source outlives the view or is set to null first).
        void SetSource(ITimelineSource* source)
        {
            if (m_source)
                m_source->RemoveTimelineClient(this);
            m_source = source;
            if (m_source)
                m_source->AddTimelineClient(this);
            m_selection.Clear();
            m_dirty = true;
            Invalidate();
        }
        [[nodiscard]] ITimelineSource* GetSource() const noexcept { return m_source; }
        /// The names' column (pixels): a ruler above it starts this far in to line up.
        [[nodiscard]] f32 GetLabelWidth() const noexcept { return m_labelWidth; }
        void SetLabelWidth(f32 width)
        {
            m_labelWidth = core::Max(width, 0.0f);
            Invalidate();
        }

        // === Rows ===
        /// The rows shown, folded ones' children left out.
        [[nodiscard]] const core::Array<DopesheetRow>& GetRows() const
        {
            Rebuild();
            return m_visible;
        }
        [[nodiscard]] i32 FindRow(core::StringView path) const
        {
            Rebuild();
            for (usize i = 0; i < m_visible.Size(); ++i)
                if (m_visible[i].Path.AsView() == path)
                    return static_cast<i32>(i);
            return -1;
        }
        void SetFolded(core::StringView path, bool folded)
        {
            for (usize i = 0; i < m_folded.Size(); ++i)
                if (m_folded[i].AsView() == path)
                {
                    if (!folded)
                        m_folded.RemoveAt(i);
                    m_dirty = true;
                    Invalidate();
                    return;
                }
            if (folded)
                m_folded.PushBack(core::String(path));
            m_dirty = true;
            Invalidate();
        }
        [[nodiscard]] bool IsFolded(core::StringView path) const
        {
            for (const core::String& at : m_folded)
                if (at.AsView() == path)
                    return true;
            return false;
        }
        /// The keys a row shows at each of its times: its channel's and every channel's under it.
        void GetRowKeys(usize row, core::Array<f32>& times, core::Array<core::Array<TimelineKeyRef>>& keys) const;
        /// Where a row's key at `time` is drawn (its own space).
        [[nodiscard]] core::Float2 KeyPoint(usize row, f32 time) const
        {
            const Rect box = GetContentBounds();
            return core::Float2{KeysLeft() + (m_axis ? m_axis->TimeToOffset(time) : 0.0f),
                                box.y + (static_cast<f32>(row) + 0.5f) * kRowHeight - m_rowScroll};
        }
        /// The names' column and the keys' area (its own space).
        [[nodiscard]] Rect NamesBounds() const
        {
            const Rect box = GetContentBounds();
            const f32 width = core::Min(m_labelWidth, box.width);
            return Rect{IsRightToLeft() ? box.Right() - width : box.x, box.y, width, box.height};
        }
        [[nodiscard]] f32 KeysLeft() const
        {
            const Rect box = GetContentBounds();
            return IsRightToLeft() ? box.x : box.x + m_labelWidth;
        }
        [[nodiscard]] i32 RowAtY(f32 y) const
        {
            const Rect box = GetContentBounds();
            const f32 at = y - box.y + m_rowScroll;
            if (at < 0.0f)
                return -1;
            const i32 row = static_cast<i32>(at / kRowHeight);
            return row < static_cast<i32>(GetRows().Size()) ? row : -1;
        }
        [[nodiscard]] f32 TimeAtX(f32 x) const { return m_axis ? m_axis->OffsetToTime(x - KeysLeft()) : 0.0f; }
        [[nodiscard]] f32 GetRowScroll() const noexcept { return m_rowScroll; }

        // === The selection ===
        [[nodiscard]] const core::Array<TimelineKeyRef>& GetSelection() const noexcept { return m_selection; }
        void SetSelection(core::Span<const TimelineKeyRef> keys)
        {
            m_selection.Clear();
            for (const TimelineKeyRef& key : keys)
                Select(key, true);
            Invalidate();
        }
        [[nodiscard]] bool IsSelected(const TimelineKeyRef& key) const noexcept
        {
            for (const TimelineKeyRef& at : m_selection)
                if (at == key)
                    return true;
            return false;
        }
        /// Deletes the selected keys, one change; false when none were.
        bool DeleteSelected()
        {
            if (!m_source || m_selection.IsEmpty())
                return false;
            const bool done = m_source->DeleteKeys(m_selection.AsSpan());
            m_selection.Clear();
            Invalidate();
            return done;
        }

        void OnTimeAxisChanged() override { Invalidate(); }
        void OnTimelineChanged() override
        {
            m_dirty = true;
            if (m_source && m_drag != Drag::Keys)
                for (usize i = m_selection.Size(); i-- > 0;) // an undo may take keys away
                {
                    core::Array<f32> times;
                    if (m_selection[i].Channel < m_source->ChannelCount())
                        m_source->GetKeyTimes(m_selection[i].Channel, times);
                    if (m_selection[i].Index >= times.Size())
                        m_selection.RemoveAt(i);
                }
            Invalidate();
        }

    protected:
        void OnMouseDown(const MouseEvent& event) override;
        void OnMouseMove(const MouseEvent& event) override;
        void OnMouseUp(const MouseEvent& event) override;
        void OnPointerCancel(const MouseEvent& event) override;
        void OnMouseWheel(const WheelEvent& event) override;
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
            Pending,
            Keys,
            Box,
            Pan,
        };
        struct RowNode
        {
            core::String Path;
            core::String Name;
            u32 Depth = 0;
            i32 Channel = -1;
            core::Array<usize> Children; // indexes into m_nodes
        };

        // The rows again from the channels' paths: a tree by segments, in the order they first
        // appear, then the shown rows in order (a folded row's children left out).
        void Rebuild() const
        {
            if (!m_dirty)
                return;
            m_dirty = false;
            m_nodes.Clear();
            m_roots.Clear();
            m_visible.Clear();
            m_visibleNodes.Clear();
            if (!m_source)
                return;
            for (usize c = 0; c < m_source->ChannelCount(); ++c)
            {
                const core::String path = m_source->GetChannelPath(c);
                i32 parent = -1;
                usize start = 0;
                u32 depth = 0;
                while (start <= path.Size())
                {
                    usize end = start;
                    while (end < path.Size() && path[end] != u8'.')
                        ++end;
                    const core::StringView prefix = path.AsView().SubStr(0, end);
                    const core::StringView name = path.AsView().SubStr(start, end - start);
                    const core::Array<usize>& siblings = parent < 0 ? m_roots : m_nodes[static_cast<usize>(parent)].Children;
                    i32 found = -1;
                    for (const usize n : siblings)
                        if (m_nodes[n].Path.AsView() == prefix)
                            found = static_cast<i32>(n);
                    if (found < 0)
                    {
                        RowNode node;
                        node.Path = core::String(prefix);
                        node.Name = core::String(name);
                        node.Depth = depth;
                        m_nodes.PushBack(core::Move(node));
                        found = static_cast<i32>(m_nodes.Size() - 1);
                        if (parent < 0)
                            m_roots.PushBack(static_cast<usize>(found));
                        else
                            m_nodes[static_cast<usize>(parent)].Children.PushBack(static_cast<usize>(found));
                    }
                    parent = found;
                    ++depth;
                    if (end >= path.Size())
                        break;
                    start = end + 1;
                }
                if (parent >= 0)
                    m_nodes[static_cast<usize>(parent)].Channel = static_cast<i32>(c);
            }
            for (const usize root : m_roots)
                Show(root);
        }
        void Show(usize node) const
        {
            const RowNode& n = m_nodes[node];
            DopesheetRow row;
            row.Path = n.Path;
            row.Name = n.Name;
            row.Depth = n.Depth;
            row.Channel = n.Channel;
            row.HasChildren = !n.Children.IsEmpty();
            row.Folded = row.HasChildren && IsFolded(n.Path.AsView());
            const bool folded = row.Folded;
            m_visible.PushBack(core::Move(row));
            m_visibleNodes.PushBack(node);
            if (!folded)
                for (const usize child : n.Children)
                    Show(child);
        }
        void Gather(usize node, core::Array<i32>& channels) const
        {
            if (m_nodes[node].Channel >= 0)
                channels.PushBack(m_nodes[node].Channel);
            for (const usize child : m_nodes[node].Children)
                Gather(child, channels);
        }

        void Select(const TimelineKeyRef& key, bool on)
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
        [[nodiscard]] bool AllSelected(core::Span<const TimelineKeyRef> keys) const noexcept
        {
            for (const TimelineKeyRef& key : keys)
                if (!IsSelected(key))
                    return false;
            return !keys.IsEmpty();
        }
        // The keys under a point of the key area: a row's marker within reach.
        bool KeysAt(core::Float2 local, core::Array<TimelineKeyRef>& out, f32& time) const;
        void MoveTo(f32 x);
        void EndDrag(bool commit);

        core::RefPtr<TimeAxis> m_axis;
        ITimelineSource* m_source = nullptr;
        f32 m_labelWidth = 160.0f;
        f32 m_rowScroll = 0.0f;
        core::Array<core::String> m_folded;
        core::Array<TimelineKeyRef> m_selection;

        mutable bool m_dirty = true;
        mutable core::Array<RowNode> m_nodes;
        mutable core::Array<usize> m_roots;
        mutable core::Array<DopesheetRow> m_visible;
        mutable core::Array<usize> m_visibleNodes; // each shown row's node

        Drag m_drag = Drag::None;
        core::Float2 m_pressAt{};
        core::Float2 m_boxTo{};
        bool m_additive = false;
        f32 m_anchorTime = 0.0f;                    // the pressed key's time at the press
        core::Array<TimelineKeyRef> m_pressed;      // the keys under the press
        core::Array<TimelineKeyRef> m_moving;       // the selection as it was when the move began
        f32 m_movingLow = 0.0f, m_movingHigh = 0.0f; // their earliest and latest times then
        f32 m_panScroll = 0.0f;
        mutable Text m_text; // each name in turn
    };

    inline void Dopesheet::GetRowKeys(usize row, core::Array<f32>& times, core::Array<core::Array<TimelineKeyRef>>& keys) const
    {
        times.Clear();
        keys.Clear();
        Rebuild();
        if (!m_source || row >= m_visibleNodes.Size())
            return;
        core::Array<i32> channels;
        Gather(m_visibleNodes[row], channels);
        core::Array<f32> channelTimes;
        for (const i32 channel : channels)
        {
            m_source->GetKeyTimes(static_cast<usize>(channel), channelTimes);
            for (usize i = 0; i < channelTimes.Size(); ++i)
            {
                const f32 t = channelTimes[i];
                usize at = 0;
                while (at < times.Size() && times[at] < t - 1e-5f)
                    ++at;
                if (at < times.Size() && core::Abs(times[at] - t) <= 1e-5f)
                {
                    keys[at].PushBack(TimelineKeyRef{static_cast<usize>(channel), i});
                    continue;
                }
                times.Insert(at, t);
                core::Array<TimelineKeyRef> here;
                here.PushBack(TimelineKeyRef{static_cast<usize>(channel), i});
                keys.Insert(at, core::Move(here));
            }
        }
    }

    inline bool Dopesheet::KeysAt(core::Float2 local, core::Array<TimelineKeyRef>& out, f32& time) const
    {
        out.Clear();
        const i32 row = RowAtY(local.y);
        if (row < 0)
            return false;
        core::Array<f32> times;
        core::Array<core::Array<TimelineKeyRef>> keys;
        GetRowKeys(static_cast<usize>(row), times, keys);
        f32 best = kHitRadius + 1.0f;
        i32 found = -1;
        for (usize i = 0; i < times.Size(); ++i)
        {
            const f32 d = core::Abs(KeyPoint(static_cast<usize>(row), times[i]).x - local.x);
            if (d <= kHitRadius && d < best)
            {
                best = d;
                found = static_cast<i32>(i);
            }
        }
        if (found < 0)
            return false;
        out = core::Move(keys[static_cast<usize>(found)]);
        time = times[static_cast<usize>(found)];
        return true;
    }

    // === Gestures ===

    inline void Dopesheet::OnMouseDown(const MouseEvent& event)
    {
        if (!m_source || !m_axis)
            return;
        const core::Float2 local = ConvertToNodeSpace(event.Position); // events come in screen space
        if (event.Button == MouseButton::Middle)
        {
            event.Handled = true;
            m_drag = Drag::Pan;
            m_pressAt = local;
            m_panScroll = m_axis->Scroll();
            return;
        }
        if (event.Button != MouseButton::Left)
            return;
        event.Handled = true;
        RequestFocus();
        if (NamesBounds().Contains(local))
        {
            // The names: a click folds or opens a row that has children.
            const i32 row = RowAtY(local.y);
            if (row >= 0 && GetRows()[static_cast<usize>(row)].HasChildren)
                SetFolded(GetRows()[static_cast<usize>(row)].Path.AsView(), !GetRows()[static_cast<usize>(row)].Folded);
            return;
        }
        m_pressAt = local;
        m_boxTo = local;
        m_additive = (event.Modifiers & (KeyModShift | KeyModCtrl)) != 0;
        f32 time = 0.0f;
        const bool onKey = KeysAt(local, m_pressed, time);
        if (event.ClickCount == 2 && !onKey)
        {
            const i32 row = RowAtY(local.y);
            if (row >= 0 && GetRows()[static_cast<usize>(row)].Channel >= 0)
            {
                TimelineKeyRef made;
                const f32 at = core::Clamp(m_axis->Snap(TimeAtX(local.x)), 0.0f, m_axis->Duration());
                if (m_source->InsertKey(static_cast<usize>(GetRows()[static_cast<usize>(row)].Channel), at, made))
                {
                    m_selection.Clear();
                    m_selection.PushBack(made);
                }
            }
            m_drag = Drag::None;
            Invalidate();
            return;
        }
        if (onKey)
        {
            m_anchorTime = time;
            const bool all = AllSelected(m_pressed.AsSpan());
            if (m_additive)
                for (const TimelineKeyRef& key : m_pressed)
                    Select(key, !all);
            else if (!all)
            {
                m_selection.Clear();
                for (const TimelineKeyRef& key : m_pressed)
                    m_selection.PushBack(key);
            }
            m_drag = AllSelected(m_pressed.AsSpan()) ? Drag::Pending : Drag::None;
        }
        else
        {
            if (!m_additive)
                m_selection.Clear();
            m_drag = Drag::Box;
        }
        Invalidate();
    }
    inline void Dopesheet::OnMouseMove(const MouseEvent& event)
    {
        if (m_drag == Drag::None || !m_source || !m_axis)
            return;
        const core::Float2 local = ConvertToNodeSpace(event.Position);
        switch (m_drag)
        {
        case Drag::Pending:
        {
            if (core::Abs(local.x - m_pressAt.x) < kDragThreshold && core::Abs(local.y - m_pressAt.y) < kDragThreshold)
                return;
            m_drag = Drag::Keys;
            m_moving.Clear();
            core::Array<f32> times;
            bool first = true;
            for (const TimelineKeyRef& key : m_selection)
            {
                m_moving.PushBack(key);
                m_source->GetKeyTimes(key.Channel, times);
                if (key.Index >= times.Size())
                    continue;
                m_movingLow = first ? times[key.Index] : core::Min(m_movingLow, times[key.Index]);
                m_movingHigh = first ? times[key.Index] : core::Max(m_movingHigh, times[key.Index]);
                first = false;
            }
            m_source->BeginKeysMove();
            MoveTo(local.x);
            break;
        }
        case Drag::Keys:
            MoveTo(local.x);
            break;
        case Drag::Box:
            m_boxTo = local;
            Invalidate();
            break;
        case Drag::Pan:
            m_axis->SetScroll(m_panScroll - (local.x - m_pressAt.x) / m_axis->PixelsPerSecond());
            break;
        default:
            break;
        }
    }
    inline void Dopesheet::MoveTo(f32 x)
    {
        f32 delta = TimeAtX(x) - TimeAtX(m_pressAt.x);
        delta = m_axis->Snap(m_anchorTime + delta) - m_anchorTime; // the pressed key on a frame, the rest kept apart
        delta = core::Clamp(delta, -m_movingLow, m_axis->Duration() - m_movingHigh); // all kept in the clip
        core::Array<TimelineKeyRef> moved;
        m_source->PreviewKeysMove(m_moving.AsSpan(), delta, moved);
        m_selection = core::Move(moved);
        Invalidate();
    }
    inline void Dopesheet::OnMouseUp(const MouseEvent& event)
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
            core::Array<f32> times;
            core::Array<core::Array<TimelineKeyRef>> keys;
            for (usize row = 0; row < GetRows().Size(); ++row)
            {
                GetRowKeys(row, times, keys);
                for (usize i = 0; i < times.Size(); ++i)
                {
                    const core::Float2 at = KeyPoint(row, times[i]);
                    if (at.x >= left && at.x <= right && at.y >= top && at.y <= bottom)
                        for (const TimelineKeyRef& key : keys[i])
                            Select(key, true);
                }
            }
            m_drag = Drag::None;
            Invalidate();
            return;
        }
        if (m_drag == Drag::Pending && !m_additive)
        {
            m_selection.Clear(); // a click on a key of several selected selects it alone
            for (const TimelineKeyRef& key : m_pressed)
                m_selection.PushBack(key);
            Invalidate();
        }
        EndDrag(true);
    }
    inline void Dopesheet::OnPointerCancel(const MouseEvent&) { EndDrag(false); }
    inline void Dopesheet::EndDrag(bool commit)
    {
        const Drag drag = m_drag;
        m_drag = Drag::None;
        if (drag != Drag::Keys || !m_source)
            return;
        if (commit)
            m_source->CommitKeysMove();
        else
        {
            m_source->CancelKeysMove();
            m_selection = core::Move(m_moving);
        }
        m_moving.Clear();
        Invalidate();
    }
    inline void Dopesheet::OnKeyDown(const KeyEvent& event)
    {
        const KeyCode key = static_cast<KeyCode>(event.KeyCode);
        if (key == KeyCode::Escape && m_drag == Drag::Keys)
        {
            event.Handled = true;
            EndDrag(false);
            return;
        }
        if (event.Modifiers == 0 && (key == KeyCode::Delete || key == KeyCode::Backspace) && m_drag == Drag::None)
            event.Handled = DeleteSelected();
    }
    inline void Dopesheet::OnMouseWheel(const WheelEvent& event)
    {
        const f32 steps = event.Delta.y != 0.0f ? event.Delta.y : event.Delta.x;
        if (steps == 0.0f)
            return;
        event.Handled = true;
        const core::Float2 local = ConvertToNodeSpace(event.Position);
        const Rect box = GetContentBounds();
        if (NamesBounds().Contains(local))
        {
            // Over the names: the rows scroll, kept in what they fill.
            const f32 most = core::Max(0.0f, static_cast<f32>(GetRows().Size()) * kRowHeight - box.height);
            m_rowScroll = core::Clamp(m_rowScroll - steps * kRowHeight * 3.0f, 0.0f, most);
            Invalidate();
            return;
        }
        if (m_axis)
            m_axis->ZoomAbout(TimeAtX(local.x), core::Pow(1.2f, steps));
    }

    // === Drawing ===

    inline void Dopesheet::OnDraw(DrawContext& ctx, const Rect& localBounds)
    {
        UIWidget::OnDraw(ctx, localBounds);
        const Rect box = GetContentBounds();
        const auto partColor = [this](const char8_t* name, Color fallback)
        {
            const PartStyle& part = GetPartStyle(name);
            Color color = part.HasBackground ? part.Box.BackgroundColor : fallback;
            color.a *= part.Opacity;
            return color;
        };
        const Color labels = partColor(u8"labels", Color{0.0f, 0.0f, 0.0f, 0.15f});
        const Color separator = partColor(u8"separator", Color{1.0f, 1.0f, 1.0f, 0.06f});
        const Color keyColor = partColor(u8"key", Color{0.8f, 0.8f, 0.85f, 1.0f});
        const Color summary = partColor(u8"summary", Color{0.55f, 0.58f, 0.65f, 1.0f});
        const Color selected = partColor(u8"selected", Color{1.0f, 0.8f, 0.3f, 1.0f});
        ctx.PushClip(box);
        const Rect names = NamesBounds();
        const bool rtl = IsRightToLeft();
        const Rect keysArea{KeysLeft(), box.y, core::Max(0.0f, box.width - names.width), box.height};
        ctx.VG().FillRect(names.ToRectangle(), labels);
        const core::Array<DopesheetRow>& rows = GetRows();
        core::Array<f32> times;
        core::Array<core::Array<TimelineKeyRef>> keys;
        for (usize r = 0; r < rows.Size(); ++r)
        {
            const DopesheetRow& row = rows[r];
            const f32 top = box.y + static_cast<f32>(r) * kRowHeight - m_rowScroll;
            if (top > box.Bottom() || top + kRowHeight < box.y)
                continue;
            ctx.VG().FillRect(Rectangle{box.x, top + kRowHeight - 1.0f, box.width, 1.0f}, separator);
            // From the names' inline start: a chevron, then the name.
            const f32 indent = 4.0f + static_cast<f32>(row.Depth) * kIndent;
            const f32 side = rtl ? -1.0f : 1.0f;
            const f32 start = rtl ? names.Right() - indent : names.x + indent;
            if (row.HasChildren)
            {
                // A chevron: toward the inline end when folded, down when open.
                vg::PathBuilder chevron;
                const f32 cx = start + side * 4.0f, cy = top + kRowHeight * 0.5f;
                if (row.Folded)
                {
                    chevron.MoveTo(cx - side * 2.0f, cy - 4.0f);
                    chevron.LineTo(cx + side * 3.0f, cy);
                    chevron.LineTo(cx - side * 2.0f, cy + 4.0f);
                }
                else
                {
                    chevron.MoveTo(cx - 4.0f, cy - 2.0f);
                    chevron.LineTo(cx, cy + 3.0f);
                    chevron.LineTo(cx + 4.0f, cy - 2.0f);
                }
                chevron.Close();
                ctx.VG().FillPath(chevron.ToPath(), GetTextColor());
            }
            if (m_text.HasFont())
            {
                ctx.PushClip(Rect{names.x + 2.0f, top, core::Max(0.0f, names.width - 4.0f), kRowHeight});
                m_text.SetString(row.Name.AsView());
                const f32 width = m_text.Measure().x;
                m_text.Draw(ctx, core::Float2{rtl ? start - 12.0f - width : start + 12.0f, top + 3.0f});
                ctx.PopClip();
            }
            if (!m_axis)
                continue;
            ctx.PushClip(Rect{keysArea.x, top, keysArea.width, kRowHeight});
            GetRowKeys(r, times, keys);
            for (usize i = 0; i < times.Size(); ++i)
            {
                const core::Float2 at = KeyPoint(r, times[i]);
                const bool on = AllSelected(keys[i].AsSpan());
                const f32 size = row.Channel >= 0 ? 5.0f : 4.0f;
                vg::PathBuilder diamond;
                diamond.MoveTo(at.x, at.y - size);
                diamond.LineTo(at.x + size, at.y);
                diamond.LineTo(at.x, at.y + size);
                diamond.LineTo(at.x - size, at.y);
                diamond.Close();
                ctx.VG().FillPath(diamond.ToPath(), on ? selected : (row.Channel >= 0 ? keyColor : summary));
            }
            ctx.PopClip();
        }
        if (m_axis)
        {
            const Color playhead = partColor(u8"playhead", Color{0.31f, 0.61f, 1.0f, 1.0f});
            const f32 x = KeysLeft() + m_axis->TimeToOffset(m_axis->Playhead());
            if (x >= keysArea.x && x <= keysArea.Right())
                ctx.VG().FillRect(Rectangle{core::Floor(x), box.y, 1.0f, box.height}, playhead);
        }
        if (m_drag == Drag::Box)
        {
            const Color fill = partColor(u8"selection-box", Color{0.31f, 0.61f, 1.0f, 0.2f});
            ctx.VG().FillRect(Rectangle{core::Min(m_pressAt.x, m_boxTo.x), core::Min(m_pressAt.y, m_boxTo.y), core::Abs(m_boxTo.x - m_pressAt.x),
                                        core::Abs(m_boxTo.y - m_pressAt.y)},
                              fill);
        }
        ctx.PopClip();
    }
}
