// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :sorting_proxy_model partition
//
// SortingProxyModel: wraps a source Model and presents the same columns with the rows reordered
// by a sort column. Modeled on eepp's Models::SortingProxyModel (role only). It is both an
// IModel (what a view binds to) and an IModelClient of the source (so it re-sorts + re-notifies
// when the source changes). Sorting uses Variant::Compare on the Sort role, so numeric columns
// order by value. A stable sort keeps equal rows in source order.
//
// Because a TableView is a client of this proxy, its column-header click asks the model to Sort,
// which re-sorts and refreshes the view with no view-side changes.

module;
#include "Core/Prelude.h"

export module foundation.gui:sorting_proxy_model;

import foundation.core; // Array, i32, usize
import :variant;
import :model_index;
import :model;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    class SortingProxyModel : public IModel, public IModelClient
    {
    public:
        SortingProxyModel() = default;
        explicit SortingProxyModel(IModel* source) { SetSource(source); }
        ~SortingProxyModel() override
        {
            if (m_source != nullptr)
                m_source->RemoveClient(this);
        }

        void SetSource(IModel* source)
        {
            if (m_source != nullptr)
                m_source->RemoveClient(this);
            m_source = source;
            if (m_source != nullptr)
                m_source->AddClient(this);
            Rebuild();
            NotifyReset();
        }
        [[nodiscard]] IModel* GetSource() const noexcept { return m_source; }

        // Sort by a column in a given order (None restores source order): the sort capability a
        // view's header asks for.
        bool Sort(usize column, SortOrder order) override
        {
            m_sortColumn = static_cast<i32>(column);
            m_order = order;
            Rebuild();
            NotifyReset();
            return true;
        }

        // Header-click behavior: a new column sorts ascending; the same column toggles
        // ascending <-> descending.
        void ToggleSort(usize column)
        {
            if (m_sortColumn == static_cast<i32>(column))
                m_order = (m_order == SortOrder::Ascending) ? SortOrder::Descending
                                                            : SortOrder::Ascending;
            else
            {
                m_sortColumn = static_cast<i32>(column);
                m_order = SortOrder::Ascending;
            }
            Rebuild();
            NotifyReset();
        }

        [[nodiscard]] i32 GetSortColumn() const noexcept { return m_sortColumn; }
        [[nodiscard]] SortOrder GetSortOrder() const noexcept { return m_order; }

        // The source row a proxy row maps to (-1 if out of range).
        [[nodiscard]] i32 SourceRow(i32 proxyRow) const
        {
            return (proxyRow >= 0 && static_cast<usize>(proxyRow) < m_rowMap.Size())
                       ? m_rowMap[static_cast<usize>(proxyRow)]
                       : -1;
        }

        // The source changed, in any way: re-sort and reset our own views (a range in the source
        // lands anywhere in the sorted order).
        void OnModelReset() override
        {
            Rebuild();
            NotifyReset();
        }

        [[nodiscard]] usize RowCount(const ModelIndex& parent = {}) const override
        {
            return parent.IsValid() ? 0 : m_rowMap.Size();
        }
        [[nodiscard]] usize ColumnCount() const override
        {
            return m_source != nullptr ? m_source->ColumnCount() : 0;
        }
        [[nodiscard]] core::String ColumnName(usize column) const override
        {
            return m_source != nullptr ? m_source->ColumnName(column) : core::String{};
        }
        [[nodiscard]] Variant Data(const ModelIndex& index,
                                   ModelRole role = ModelRole::Display) const override
        {
            const i32 sourceRow = SourceRow(index.Row);
            if (m_source == nullptr || sourceRow < 0)
                return Variant{};
            return m_source->Data(MakeModelIndex(sourceRow, index.Column), role);
        }

        // A row keeps its source row's id, so a view's selection survives a sort.
        [[nodiscard]] ItemId IdOf(const ModelIndex& index) const override
        {
            const i32 sourceRow = SourceRow(index.Row);
            return m_source != nullptr && sourceRow >= 0 ? m_source->IdOf(m_source->Index(sourceRow, index.Column)) : kNoItem;
        }
        [[nodiscard]] bool IsEditable(const ModelIndex& index) const override
        {
            const i32 sourceRow = SourceRow(index.Row);
            return m_source != nullptr && sourceRow >= 0 && m_source->IsEditable(MakeModelIndex(sourceRow, index.Column));
        }
        bool SetData(const ModelIndex& index, const Variant& value) override
        {
            const i32 sourceRow = SourceRow(index.Row);
            return m_source != nullptr && sourceRow >= 0 && m_source->SetData(MakeModelIndex(sourceRow, index.Column), value);
        }

    private:
        void Rebuild()
        {
            const usize n = m_source != nullptr ? m_source->RowCount() : 0;
            m_rowMap.Clear();
            for (usize i = 0; i < n; ++i)
                m_rowMap.PushBack(static_cast<i32>(i));
            if (m_source != nullptr && m_sortColumn >= 0 && m_order != SortOrder::None)
                StableSort();
        }

        // Stable insertion sort of m_rowMap by the sort column's Variant order.
        void StableSort()
        {
            const bool ascending = (m_order == SortOrder::Ascending);
            for (usize a = 1; a < m_rowMap.Size(); ++a)
            {
                const i32 key = m_rowMap[a];
                usize b = a;
                while (b > 0 && ShouldPrecede(key, m_rowMap[b - 1], ascending))
                {
                    m_rowMap[b] = m_rowMap[b - 1];
                    --b;
                }
                m_rowMap[b] = key;
            }
        }

        // True if source row `lhs` should sort before `rhs` (strictly; equal keeps order = stable).
        [[nodiscard]] bool ShouldPrecede(i32 lhs, i32 rhs, bool ascending) const
        {
            const Variant a = m_source->Data(MakeModelIndex(lhs, m_sortColumn), ModelRole::Sort);
            const Variant b = m_source->Data(MakeModelIndex(rhs, m_sortColumn), ModelRole::Sort);
            const i32 cmp = a.Compare(b);
            if (cmp == 0)
                return false;
            return ascending ? (cmp < 0) : (cmp > 0);
        }

        IModel* m_source = nullptr; // non-owning
        Array<i32> m_rowMap;        // proxy row -> source row
        i32 m_sortColumn = -1;
        SortOrder m_order = SortOrder::None;
    };
}
