// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :tree_model partition
//
// TreeModel: a concrete hierarchical Model - nodes with a text label and children. Modeled on
// eepp's tree models (role only). Nodes are stored in a flat array; a ModelIndex's InternalId
// is the node's array index, which the tree methods (Index / ParentIndex / RowCount(parent) /
// HasChildren) use to navigate. A removed node keeps its slot (it is detached, not erased), so
// node ids stay stable and a view keeps selection and expansion by id. Each edit tells the
// views the rows it touched under their parent.

module;
#include "Core/Prelude.h"

export module foundation.gui:tree_model;

import foundation.core; // Array, String, StringView, i32, i64
import :variant;
import :model_index;
import :model;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    class TreeModel : public IModel
    {
    public:
        static constexpr i32 kRoot = -1; // parent id for a top-level node

        TreeModel() = default;

        // Add a node under `parentId` (kRoot for a top level node); returns the new node's id.
        i32 AddNode(i32 parentId, core::StringView text)
        {
            const i32 id = static_cast<i32>(m_nodes.Size());
            m_nodes.PushBack(Node{core::String(text), parentId, {}, false});
            Array<i32>& siblings = parentId == kRoot ? m_roots : m_nodes[static_cast<usize>(parentId)].Children;
            siblings.PushBack(id);
            NotifyRowsInserted(IndexOfNode(parentId), static_cast<i32>(siblings.Size()) - 1, 1);
            return id;
        }
        /// Removes a node and what is under it (their ids are not reused).
        void RemoveNode(i32 nodeId)
        {
            if (!IsLive(nodeId))
                return;
            const i32 parentId = m_nodes[static_cast<usize>(nodeId)].Parent;
            const ModelIndex parent = IndexOfNode(parentId);
            const i32 row = RowOf(nodeId);
            Array<i32>& siblings = parentId == kRoot ? m_roots : m_nodes[static_cast<usize>(parentId)].Children;
            siblings.RemoveAt(static_cast<usize>(row));
            Detach(nodeId);
            NotifyRowsRemoved(parent, row, 1);
        }
        void SetText(i32 nodeId, core::StringView text)
        {
            if (!IsLive(nodeId))
                return;
            m_nodes[static_cast<usize>(nodeId)].Text = core::String(text);
            NotifyRowsChanged(IndexOfNode(m_nodes[static_cast<usize>(nodeId)].Parent), RowOf(nodeId), 1);
        }
        /// Moves a node (with what is under it) under `parentId` at `row` (past the end: last).
        /// False when that would put it inside itself.
        bool MoveNode(i32 nodeId, i32 parentId, usize row)
        {
            if (!IsLive(nodeId) || (parentId != kRoot && !IsLive(parentId)) || IsWithin(parentId, nodeId))
                return false;
            Detach(nodeId, false);
            Array<i32>& siblings = parentId == kRoot ? m_roots : m_nodes[static_cast<usize>(parentId)].Children;
            siblings.Insert(core::Min(row, siblings.Size()), nodeId);
            m_nodes[static_cast<usize>(nodeId)].Parent = parentId;
            NotifyReset();
            return true;
        }

        // === Drops (E7) ===
        // Its own nodes move: onto a node (its last child) or beside one; never inside themselves.
        // `text` comes in as a new node.
        [[nodiscard]] DropEffect CanDrop(const ModelDrop& drop, core::String& reason) const override
        {
            const i32 parent = DropParent(drop);
            if (drop.Source == this && !drop.Ids.IsEmpty())
            {
                for (ItemId id : drop.Ids)
                    if (IsWithin(parent, static_cast<i32>(id)))
                    {
                        reason = core::String(u8"A node cannot go inside itself");
                        return DropEffect::None;
                    }
                return DropEffect::Move; // a tree moves its nodes (copying a subtree is not taken)
            }
            if (drop.Payload != nullptr && drop.Payload->Type.AsView() == core::StringView(u8"text"))
                return DropEffect::Copy;
            return DropEffect::None;
        }
        bool Drop(const ModelDrop& drop) override
        {
            core::String ignored;
            if (CanDrop(drop, ignored) == DropEffect::None)
                return false;
            const i32 parent = DropParent(drop);
            usize row = DropRow(drop, parent);
            if (drop.Source != this || drop.Ids.IsEmpty())
            {
                const core::String* value = drop.Payload->Value.TryGet<core::String>();
                const i32 id = AddNode(parent, value != nullptr ? value->AsView() : drop.Payload->Label.AsView());
                (void)MoveNode(id, parent, row);
                return true;
            }
            for (ItemId id : drop.Ids)
            {
                const i32 node = static_cast<i32>(id);
                // A node moving down within its own parent: the row past it shifts back by one.
                const Array<i32>& siblings = parent == kRoot ? m_roots : m_nodes[static_cast<usize>(parent)].Children;
                for (usize i = 0; i < siblings.Size() && i < row; ++i)
                    if (siblings[i] == node)
                    {
                        --row;
                        break;
                    }
                if (MoveNode(node, parent, row))
                    ++row;
            }
            return true;
        }

        void Clear()
        {
            m_nodes.Clear();
            m_roots.Clear();
            NotifyReset();
        }
        /// The index of a node (invalid for kRoot or a removed node).
        [[nodiscard]] ModelIndex IndexOfNode(i32 nodeId) const
        {
            return IsLive(nodeId) ? MakeModelIndex(RowOf(nodeId), 0, nodeId) : ModelIndex{};
        }

        [[nodiscard]] core::StringView TextOf(i32 nodeId) const
        {
            return (nodeId >= 0 && static_cast<usize>(nodeId) < m_nodes.Size())
                       ? m_nodes[static_cast<usize>(nodeId)].Text.AsView()
                       : core::StringView{};
        }

        [[nodiscard]] usize ColumnCount() const override { return 1; }

        [[nodiscard]] usize RowCount(const ModelIndex& parent = {}) const override
        {
            if (!parent.IsValid())
                return m_roots.Size();
            const i32 id = static_cast<i32>(parent.InternalId);
            return (id >= 0 && static_cast<usize>(id) < m_nodes.Size())
                       ? m_nodes[static_cast<usize>(id)].Children.Size()
                       : 0;
        }

        [[nodiscard]] ModelIndex Index(i32 row, i32 column = 0,
                                       const ModelIndex& parent = {}) const override
        {
            const i32 childId = ChildIdAt(parent, row);
            if (childId < 0)
                return ModelIndex{};
            return MakeModelIndex(row, column, childId);
        }

        [[nodiscard]] ModelIndex ParentIndex(const ModelIndex& child) const override
        {
            const i32 id = static_cast<i32>(child.InternalId);
            if (id < 0 || static_cast<usize>(id) >= m_nodes.Size())
                return ModelIndex{};
            const i32 parentId = m_nodes[static_cast<usize>(id)].Parent;
            if (parentId == kRoot)
                return ModelIndex{}; // top-level: no parent
            return MakeModelIndex(RowOf(parentId), 0, parentId);
        }

        [[nodiscard]] bool HasChildren(const ModelIndex& parent = {}) const override
        {
            return RowCount(parent) > 0;
        }

        [[nodiscard]] Variant Data(const ModelIndex& index,
                                   ModelRole role = ModelRole::Display) const override
        {
            const i32 id = static_cast<i32>(index.InternalId);
            if (id < 0 || static_cast<usize>(id) >= m_nodes.Size())
                return Variant{};
            if (role == ModelRole::Display || role == ModelRole::Sort)
                return Variant(m_nodes[static_cast<usize>(id)].Text.AsView());
            return Variant{};
        }

    private:
        struct Node
        {
            core::String Text;
            i32 Parent = kRoot;
            Array<i32> Children;
            bool Removed = false; // detached: its slot kept so ids stay stable
        };

        [[nodiscard]] i32 ChildIdAt(const ModelIndex& parent, i32 row) const
        {
            if (!parent.IsValid())
                return (row >= 0 && static_cast<usize>(row) < m_roots.Size())
                           ? m_roots[static_cast<usize>(row)]
                           : -1;
            const i32 id = static_cast<i32>(parent.InternalId);
            if (id < 0 || static_cast<usize>(id) >= m_nodes.Size())
                return -1;
            const Array<i32>& children = m_nodes[static_cast<usize>(id)].Children;
            return (row >= 0 && static_cast<usize>(row) < children.Size())
                       ? children[static_cast<usize>(row)]
                       : -1;
        }

        // The row index of `nodeId` within its parent's child list (or root list).
        [[nodiscard]] i32 RowOf(i32 nodeId) const
        {
            if (nodeId < 0 || static_cast<usize>(nodeId) >= m_nodes.Size())
                return -1;
            const i32 parentId = m_nodes[static_cast<usize>(nodeId)].Parent;
            const Array<i32>& siblings =
                (parentId == kRoot) ? m_roots : m_nodes[static_cast<usize>(parentId)].Children;
            for (usize i = 0; i < siblings.Size(); ++i)
                if (siblings[i] == nodeId)
                    return static_cast<i32>(i);
            return -1;
        }

        [[nodiscard]] bool IsLive(i32 nodeId) const
        {
            return nodeId >= 0 && static_cast<usize>(nodeId) < m_nodes.Size() && !m_nodes[static_cast<usize>(nodeId)].Removed;
        }
        void Detach(i32 nodeId)
        {
            Node& node = m_nodes[static_cast<usize>(nodeId)];
            node.Removed = true;
            for (i32 child : node.Children)
                Detach(child);
            node.Children.Clear();
        }
        // Takes a live node out of its parent's children (to be put back elsewhere).
        void Detach(i32 nodeId, bool)
        {
            const i32 parentId = m_nodes[static_cast<usize>(nodeId)].Parent;
            Array<i32>& siblings = parentId == kRoot ? m_roots : m_nodes[static_cast<usize>(parentId)].Children;
            for (usize i = 0; i < siblings.Size(); ++i)
                if (siblings[i] == nodeId)
                {
                    siblings.RemoveAt(i);
                    break;
                }
        }
        // Whether `nodeId` is `ancestorId` or lies under it.
        [[nodiscard]] bool IsWithin(i32 nodeId, i32 ancestorId) const
        {
            for (i32 n = nodeId; n != kRoot && IsLive(n); n = m_nodes[static_cast<usize>(n)].Parent)
                if (n == ancestorId)
                    return true;
            return false;
        }
        // The node a drop goes under: onto a node, that node; beside one, its parent.
        [[nodiscard]] i32 DropParent(const ModelDrop& drop) const
        {
            if (!drop.Index.IsValid())
                return kRoot;
            const i32 at = static_cast<i32>(drop.Index.InternalId);
            if (drop.Place == DropPlace::On)
                return at;
            return IsLive(at) ? m_nodes[static_cast<usize>(at)].Parent : kRoot;
        }
        // The row under that parent a drop goes to.
        [[nodiscard]] usize DropRow(const ModelDrop& drop, i32 parent) const
        {
            const Array<i32>& siblings = parent == kRoot ? m_roots : m_nodes[static_cast<usize>(parent)].Children;
            if (!drop.Index.IsValid() || drop.Place == DropPlace::On)
                return siblings.Size();
            const i32 row = RowOf(static_cast<i32>(drop.Index.InternalId));
            return static_cast<usize>(drop.Place == DropPlace::Before ? row : row + 1);
        }

        Array<Node> m_nodes;
        Array<i32> m_roots;
    };
}
