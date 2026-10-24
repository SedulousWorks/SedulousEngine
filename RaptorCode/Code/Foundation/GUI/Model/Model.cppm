// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :model partition
//
// IModel: the abstract data source a model-backed view renders (eepp's Models::Model in role). A
// model exposes rows of cells under a parent (RowCount x ColumnCount; a flat model has the top
// level alone), returns a Variant per (index, role), and tells its clients (the views) what
// changed (E6 of Specs/gui-lab-evolution.md): rows inserted, removed, moved or changed under a
// parent, or, when it cannot say, a reset. A client that does not follow ranges takes each as a
// reset. Each row has an id that stays its own while rows come and go, so a view keeps its
// selection and expansion as id sets (Zero's and LunarSong's way). Editing (IsEditable, SetData)
// and sorting (Sort) are capabilities a model may have.

module;
#include "Core/Prelude.h"

export module foundation.gui:model;

import foundation.core; // Array, String, usize
import :variant;
import :model_index;
import :event; // DragPayload, DropEffect (a drop on a view)

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    /// A row's identity, its own while rows are inserted, removed and moved around it.
    using ItemId = u64;
    inline constexpr ItemId kNoItem = ~ItemId{0};

    enum class SortOrder
    {
        None,
        Ascending,
        Descending
    };

    class IModel;

    /// Where in a row a drop lands (E7): before it, onto it (a tree's child), or after it.
    enum class DropPlace : u8
    {
        Before,
        On,
        After,
    };

    /// A drop on a view, as its model hears it: what is dropped, where (a row and a place; an
    /// invalid row is the end of the top level), with which effect, and, from a view, the ids of
    /// the rows dragged and their model.
    struct ModelDrop
    {
        const DragPayload* Payload = nullptr;
        ModelIndex Index;
        DropPlace Place = DropPlace::After;
        DropEffect Effect = DropEffect::Move;
        core::Array<ItemId> Ids;
        const IModel* Source = nullptr;
    };

    // What a model tells a view. Each range defaults to a reset, so a client follows only the
    // ranges it can.
    class IModelClient
    {
    public:
        virtual ~IModelClient() = default;
        /// Anything may have changed: read it all again.
        virtual void OnModelReset() = 0;
        /// `count` rows were inserted under `parent`, the first now at `first`.
        virtual void OnRowsInserted(const ModelIndex& parent, i32 first, i32 count)
        {
            (void)parent, (void)first, (void)count;
            OnModelReset();
        }
        /// `count` rows were removed under `parent`, the first having been at `first`.
        virtual void OnRowsRemoved(const ModelIndex& parent, i32 first, i32 count)
        {
            (void)parent, (void)first, (void)count;
            OnModelReset();
        }
        /// `count` rows under `parent` that were at `first` now start at `to` (in the order after
        /// the move).
        virtual void OnRowsMoved(const ModelIndex& parent, i32 first, i32 count, i32 to)
        {
            (void)parent, (void)first, (void)count, (void)to;
            OnModelReset();
        }
        /// The data of `count` rows under `parent` from `first` changed (not their number or order).
        virtual void OnRowsChanged(const ModelIndex& parent, i32 first, i32 count)
        {
            (void)parent, (void)first, (void)count;
            OnModelReset();
        }
    };

    class IModel
    {
    public:
        virtual ~IModel() = default;

        // Number of rows under `parent` (an invalid parent = the top level). Flat models
        // ignore the parent (they only have a top level).
        [[nodiscard]] virtual usize RowCount(const ModelIndex& parent = {}) const = 0;
        [[nodiscard]] virtual usize ColumnCount() const = 0;
        [[nodiscard]] virtual core::String ColumnName(usize /*column*/) const
        {
            return core::String{};
        }
        [[nodiscard]] virtual Variant Data(const ModelIndex& index,
                                           ModelRole role = ModelRole::Display) const = 0;

        // === Identity ===
        /// The id of the row `index` is in. By default a tree's node id (InternalId), else the
        /// row number, which a model whose rows move should replace with ids of its own.
        [[nodiscard]] virtual ItemId IdOf(const ModelIndex& index) const
        {
            if (!index.IsValid())
                return kNoItem;
            return index.InternalId >= 0 ? static_cast<ItemId>(index.InternalId) : static_cast<ItemId>(index.Row);
        }
        /// The top-level row whose id is `id` (invalid: none). A tree's view finds its nodes itself.
        [[nodiscard]] virtual ModelIndex IndexOfId(ItemId id) const
        {
            for (usize r = 0; r < RowCount(); ++r)
            {
                const ModelIndex index = Index(static_cast<i32>(r));
                if (IdOf(index) == id)
                    return index;
            }
            return ModelIndex{};
        }

        // === Capabilities ===
        [[nodiscard]] virtual bool IsEditable(const ModelIndex&) const { return false; }
        /// Writes an edited value; false when it is refused (the editor then stays open).
        virtual bool SetData(const ModelIndex&, const Variant&) { return false; }
        /// Sorts by `column` (None: the source's order); false when the model cannot sort.
        virtual bool Sort(usize column, SortOrder order)
        {
            (void)column, (void)order;
            return false;
        }

        /// What a drop would do (E7): an effect, or none, with a reason when it says why; none
        /// with no reason means the place is not one it takes (the view tries another).
        [[nodiscard]] virtual DropEffect CanDrop(const ModelDrop& drop, core::String& reason) const
        {
            (void)drop, (void)reason;
            return DropEffect::None;
        }
        /// Does the drop; false when it could not.
        virtual bool Drop(const ModelDrop& drop)
        {
            (void)drop;
            return false;
        }
        /// Removes rows by id (what a view moved to another model leaves behind); false when it
        /// cannot.
        virtual bool RemoveIds(const core::Array<ItemId>& ids)
        {
            (void)ids;
            return false;
        }

        // === Tree structure (flat defaults; a tree model overrides these) ===
        // The index of the cell at (row, column) under `parent`.
        [[nodiscard]] virtual ModelIndex Index(i32 row, i32 column = 0,
                                               const ModelIndex& /*parent*/ = {}) const
        {
            return MakeModelIndex(row, column);
        }
        // The parent of `child` (invalid = a top-level node; flat models have no parents).
        [[nodiscard]] virtual ModelIndex ParentIndex(const ModelIndex& /*child*/) const
        {
            return ModelIndex{};
        }
        // Whether `parent` has any child rows.
        [[nodiscard]] virtual bool HasChildren(const ModelIndex& parent = {}) const
        {
            return RowCount(parent) > 0;
        }

        [[nodiscard]] bool IsValidIndex(const ModelIndex& index) const
        {
            return index.Row >= 0 && static_cast<usize>(index.Row) < RowCount() &&
                   index.Column >= 0 && static_cast<usize>(index.Column) < ColumnCount();
        }

        // Client (view) registration. Clients are non-owning and must outlive the model or
        // unregister first.
        void AddClient(IModelClient* client)
        {
            if (client != nullptr)
                m_clients.PushBack(client);
        }
        void RemoveClient(IModelClient* client)
        {
            for (usize i = 0; i < m_clients.Size(); ++i)
                if (m_clients[i] == client)
                {
                    m_clients.RemoveAt(i);
                    return;
                }
        }

        // === Telling the clients (after the change is made) ===
        void NotifyReset()
        {
            for (usize i = 0; i < m_clients.Size(); ++i)
                m_clients[i]->OnModelReset();
        }
        void NotifyRowsInserted(const ModelIndex& parent, i32 first, i32 count)
        {
            for (usize i = 0; i < m_clients.Size(); ++i)
                m_clients[i]->OnRowsInserted(parent, first, count);
        }
        void NotifyRowsRemoved(const ModelIndex& parent, i32 first, i32 count)
        {
            for (usize i = 0; i < m_clients.Size(); ++i)
                m_clients[i]->OnRowsRemoved(parent, first, count);
        }
        void NotifyRowsMoved(const ModelIndex& parent, i32 first, i32 count, i32 to)
        {
            for (usize i = 0; i < m_clients.Size(); ++i)
                m_clients[i]->OnRowsMoved(parent, first, count, to);
        }
        void NotifyRowsChanged(const ModelIndex& parent, i32 first, i32 count)
        {
            for (usize i = 0; i < m_clients.Size(); ++i)
                m_clients[i]->OnRowsChanged(parent, first, count);
        }

    protected:
        Array<IModelClient*> m_clients; // non-owning
    };

    /// Ids for a flat model's rows: one per row, handed out in turn, moving with its row. Finding
    /// an id's row is a lookup (E17b: an accessibility node asks it for every item it describes),
    /// its index made again on the first ask after the rows change.
    class RowIds
    {
    public:
        [[nodiscard]] usize Size() const noexcept { return m_ids.Size(); }
        [[nodiscard]] ItemId At(usize row) const { return row < m_ids.Size() ? m_ids[row] : kNoItem; }
        [[nodiscard]] i32 RowOf(ItemId id) const
        {
            if (m_stale)
            {
                m_rows.Clear();
                for (usize i = 0; i < m_ids.Size(); ++i)
                    m_rows.InsertOrAssign(m_ids[i], static_cast<i32>(i));
                m_stale = false;
            }
            const i32* row = m_rows.Find(id);
            return row != nullptr ? *row : -1;
        }
        void Reset(usize count)
        {
            m_ids.Clear();
            for (usize i = 0; i < count; ++i)
                m_ids.PushBack(m_next++);
            m_stale = true;
        }
        void Insert(usize row)
        {
            m_ids.Insert(row, m_next++);
            m_stale = true;
        }
        /// Puts an existing id back at `row` (a row moved by a drop keeps its id).
        void InsertId(usize row, ItemId id)
        {
            m_ids.Insert(row, id);
            m_stale = true;
        }
        void Remove(usize row)
        {
            m_ids.RemoveAt(row);
            m_stale = true;
        }
        void Move(usize from, usize to)
        {
            const ItemId id = m_ids[from];
            m_ids.RemoveAt(from);
            m_ids.Insert(to, id);
            m_stale = true;
        }

    private:
        Array<ItemId> m_ids;
        ItemId m_next = 0;
        mutable HashMap<ItemId, i32> m_rows; // id to row, as of the last ask
        mutable bool m_stale = true;
    };
}
