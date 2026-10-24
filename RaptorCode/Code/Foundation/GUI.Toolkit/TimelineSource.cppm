// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - :timeline_source partition
//
// What a dopesheet reads (T5 of Specs/gui-lab-evolution-3.md): channels named by paths ("Lamp.color.r"),
// the dopesheet folding them into rows by their segments (component, property, channel), and each
// channel's key times. A key is (channel, index); an edit through the source returns the keys' new
// addresses, so a selection survives the source sorting its keys again. Edits are gestures as the
// other sources' are (a move begun, previewed from where the keys were, committed once or
// cancelled) or one change each (a deletion, an insertion); the undo is the source's.

module;
#include "Core/Prelude.h"

export module foundation.gui.toolkit:timeline_source;

import foundation.core;
import foundation.gui;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    /// A key of a timeline: its channel and its place among that channel's keys (sorted by time).
    struct TimelineKeyRef
    {
        usize Channel = 0;
        usize Index = 0;
        [[nodiscard]] bool operator==(const TimelineKeyRef&) const noexcept = default;
    };

    /// What a timeline source tells its views.
    class ITimelineSourceClient
    {
    public:
        virtual ~ITimelineSourceClient() = default;
        /// The channels or their keys changed: read them again.
        virtual void OnTimelineChanged() = 0;
    };

    class ITimelineSource
    {
    public:
        virtual ~ITimelineSource() = default;

        [[nodiscard]] virtual usize ChannelCount() const = 0;
        /// Its path, its segments split by '.': the rows it folds into.
        [[nodiscard]] virtual core::String GetChannelPath(usize channel) const = 0;
        /// Its key times, sorted.
        virtual void GetKeyTimes(usize channel, core::Array<f32>& out) const = 0;

        /// A move begins: where the keys are now is what a preview moves from and a cancel puts back.
        virtual void BeginKeysMove() = 0;
        /// `keys` (as they were at the beginning) moved by `delta` seconds, live; `moved` their places now.
        virtual void PreviewKeysMove(core::Span<const TimelineKeyRef> keys, f32 delta, core::Array<TimelineKeyRef>& moved) = 0;
        /// The move ends as last previewed: one change.
        virtual void CommitKeysMove() = 0;
        /// The move is given up: the keys as they were.
        virtual void CancelKeysMove() = 0;
        /// Deletes `keys`, one change; false when none went.
        virtual bool DeleteKeys(core::Span<const TimelineKeyRef> keys) = 0;
        /// Adds a key to `channel` at `time` (its value the source's: the channel's there, as a
        /// rule), one change; false when it cannot (full, locked). `made` is where it went.
        virtual bool InsertKey(usize channel, f32 time, TimelineKeyRef& made) = 0;

        void AddTimelineClient(ITimelineSourceClient* client) { m_timelineClients.PushBack(client); }
        void RemoveTimelineClient(ITimelineSourceClient* client)
        {
            for (usize i = 0; i < m_timelineClients.Size(); ++i)
                if (m_timelineClients[i] == client)
                {
                    m_timelineClients.RemoveAt(i);
                    return;
                }
        }

    protected:
        void NotifyTimelineChanged()
        {
            for (usize i = 0; i < m_timelineClients.Size(); ++i)
                m_timelineClients[i]->OnTimelineChanged();
        }

    private:
        core::Array<ITimelineSourceClient*> m_timelineClients; // non-owning: each view leaves as it goes
    };
}
