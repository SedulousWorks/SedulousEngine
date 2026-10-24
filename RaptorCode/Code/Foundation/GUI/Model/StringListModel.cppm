// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :string_list_model partition
//
// StringListModel: the simplest concrete Model - a single column of strings, one per row, each
// with an id of its own (eepp's ItemListModel in role). Its edits tell its views the rows they
// touch: an insert, a removal, a move or a change; SetItems and Clear reset them. Editable, a
// view may edit its rows in place.

module;
#include "Core/Prelude.h"

export module foundation.gui:string_list_model;

import foundation.core; // Array, String, StringView, Move
import :variant;
import :model_index;
import :model;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    class StringListModel : public IModel
    {
    public:
        StringListModel() = default;
        explicit StringListModel(Array<core::String> items) : m_items(core::Move(items)) { m_ids.Reset(m_items.Size()); }

        void SetItems(Array<core::String> items)
        {
            m_items = core::Move(items);
            m_ids.Reset(m_items.Size());
            NotifyReset();
        }
        void AddItem(core::StringView item) { InsertItem(m_items.Size(), item); }
        void InsertItem(usize row, core::StringView item)
        {
            row = core::Min(row, m_items.Size());
            m_items.Insert(row, core::String(item));
            m_ids.Insert(row);
            NotifyRowsInserted(ModelIndex{}, static_cast<i32>(row), 1);
        }
        void RemoveItem(usize row)
        {
            if (row >= m_items.Size())
                return;
            m_items.RemoveAt(row);
            m_ids.Remove(row);
            NotifyRowsRemoved(ModelIndex{}, static_cast<i32>(row), 1);
        }
        void SetItem(usize row, core::StringView item)
        {
            if (row >= m_items.Size())
                return;
            m_items[row] = core::String(item);
            NotifyRowsChanged(ModelIndex{}, static_cast<i32>(row), 1);
        }
        void MoveItem(usize from, usize to)
        {
            if (from >= m_items.Size() || to >= m_items.Size() || from == to)
                return;
            core::String item = core::Move(m_items[from]);
            m_items.RemoveAt(from);
            m_items.Insert(to, core::Move(item));
            m_ids.Move(from, to);
            NotifyRowsMoved(ModelIndex{}, static_cast<i32>(from), 1, static_cast<i32>(to));
        }
        void Clear()
        {
            m_items.Clear();
            m_ids.Reset(0);
            NotifyReset();
        }

        /// Its rows may be edited in place.
        void SetEditable(bool editable) noexcept { m_editable = editable; }

        [[nodiscard]] core::StringView ItemAt(usize row) const
        {
            return row < m_items.Size() ? m_items[row].AsView() : core::StringView{};
        }

        [[nodiscard]] usize RowCount(const ModelIndex& parent = {}) const override
        {
            return parent.IsValid() ? 0 : m_items.Size();
        }
        [[nodiscard]] usize ColumnCount() const override { return 1; }
        [[nodiscard]] Variant Data(const ModelIndex& index,
                                   ModelRole role = ModelRole::Display) const override
        {
            if (!IsValidIndex(index))
                return Variant{};
            if (role == ModelRole::Display || role == ModelRole::Sort)
                return Variant(m_items[static_cast<usize>(index.Row)].AsView());
            return Variant{};
        }
        [[nodiscard]] ItemId IdOf(const ModelIndex& index) const override
        {
            return index.IsValid() ? m_ids.At(static_cast<usize>(index.Row)) : kNoItem;
        }
        [[nodiscard]] ModelIndex IndexOfId(ItemId id) const override
        {
            const i32 row = m_ids.RowOf(id);
            return row >= 0 ? MakeModelIndex(row) : ModelIndex{};
        }
        [[nodiscard]] bool IsEditable(const ModelIndex& index) const override { return m_editable && IsValidIndex(index); }
        bool SetData(const ModelIndex& index, const Variant& value) override
        {
            if (!IsEditable(index))
                return false;
            SetItem(static_cast<usize>(index.Row), value.ToString().AsView());
            return true;
        }

        // === Drops (E7) ===
        // Its own rows move or copy between rows (not onto one); another model's rows, or `text`,
        // come in as text, copied or moved (the source removes what moved).
        [[nodiscard]] DropEffect CanDrop(const ModelDrop& drop, core::String& reason) const override
        {
            if (drop.Place == DropPlace::On)
                return DropEffect::None; // a list has nothing to drop onto: the view tries between
            const bool rows = drop.Source != nullptr && !drop.Ids.IsEmpty();
            const bool text = drop.Payload != nullptr && drop.Payload->Type.AsView() == core::StringView(u8"text");
            if (!rows && !text)
                return DropEffect::None;
            if (drop.Effect == DropEffect::Link)
            {
                reason = core::String(u8"A list cannot link its rows");
                return DropEffect::None;
            }
            return text ? DropEffect::Copy : drop.Effect;
        }
        bool Drop(const ModelDrop& drop) override
        {
            core::String ignored;
            if (CanDrop(drop, ignored) == DropEffect::None)
                return false;
            usize at = !drop.Index.IsValid() ? m_items.Size()
                       : drop.Place == DropPlace::Before ? static_cast<usize>(drop.Index.Row)
                                                        : static_cast<usize>(drop.Index.Row) + 1;
            if (drop.Ids.IsEmpty())
            {
                const core::String* value = drop.Payload->Value.TryGet<core::String>();
                const core::String text = value != nullptr ? *value : drop.Payload->Label;
                m_items.Insert(core::Min(at, m_items.Size()), text);
                m_ids.Insert(core::Min(at, m_ids.Size()));
                NotifyReset();
                return true;
            }
            // The rows, in their order, taken out (moving within) or read (copying, or from another model).
            Array<core::String> texts;
            Array<ItemId> ids;
            const bool within = drop.Source == this && drop.Effect == DropEffect::Move;
            Array<usize> rows;
            for (ItemId id : drop.Ids)
            {
                const ModelIndex index = drop.Source->IndexOfId(id);
                if (index.IsValid())
                    rows.PushBack(static_cast<usize>(index.Row));
            }
            for (usize i = 1; i < rows.Size(); ++i) // in row order
                for (usize j = i; j > 0 && rows[j - 1] > rows[j]; --j)
                {
                    const usize t = rows[j];
                    rows[j] = rows[j - 1];
                    rows[j - 1] = t;
                }
            for (usize row : rows)
            {
                texts.PushBack(drop.Source->Data(drop.Source->Index(static_cast<i32>(row))).ToString());
                ids.PushBack(drop.Source->IdOf(drop.Source->Index(static_cast<i32>(row))));
            }
            if (within)
                for (usize i = rows.Size(); i-- > 0;)
                {
                    m_items.RemoveAt(rows[i]);
                    m_ids.Remove(rows[i]);
                    if (rows[i] < at)
                        --at;
                }
            at = core::Min(at, m_items.Size());
            for (usize i = 0; i < texts.Size(); ++i)
            {
                m_items.Insert(at + i, texts[i]);
                if (within)
                    m_ids.InsertId(at + i, ids[i]); // a moved row keeps its id (and its selection)
                else
                    m_ids.Insert(at + i);
            }
            NotifyReset();
            return true;
        }
        bool RemoveIds(const Array<ItemId>& ids) override
        {
            bool removed = false;
            for (ItemId id : ids)
            {
                const i32 row = m_ids.RowOf(id);
                if (row < 0)
                    continue;
                m_items.RemoveAt(static_cast<usize>(row));
                m_ids.Remove(static_cast<usize>(row));
                removed = true;
            }
            if (removed)
                NotifyReset();
            return removed;
        }

    private:
        Array<core::String> m_items;
        RowIds m_ids;
        bool m_editable = false;
    };
}
