// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :tree_view partition
//
// TreeView: a virtualised tree over a model (eepp's UITreeView in role). It flattens the open
// nodes into the items ItemView realises, so a huge tree costs only the rows in view. A row shows
// its indent, a disclosure chevron (the expander's) that opens and closes it, and its text.
// Expansion is a set of node ids, as the selection is, so both survive the flattening; closing a
// node that holds the selection selects the node. Right opens a node (or goes to its first
// child), Left closes it (or goes to its parent). In markup its children are nested
// `<TreeItem text="..." expanded="true">`s, which become a model of its own.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:tree_view;

import foundation.core; // RefPtr, MakeRef, Array, HashSet, HashMap, Function, Move, Max
import :rect;
import :event;
import :draw_context;
import :disclosure; // the chevron an expander draws too
import :node;
import :label;
import :text; // TextHAlign
import :ui_widget;
import :layout_style;
import :model_index;
import :model;
import :item_view;
import :tree_model;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    // A node's chevron: right when closed, down when open; a click opens or closes the node.
    class TreeArrow : public UIWidget
    {
        RTTI_OBJECT(TreeArrow, UIWidget)
    public:
        TreeArrow() { SetTag(core::StringView(u8"treearrow")); }
        void SetExpanded(bool expanded)
        {
            if (m_expanded != expanded)
            {
                m_expanded = expanded;
                Invalidate();
            }
        }
        void SetOnClicked(core::Function<void()> callback) { m_onClicked = core::Move(callback); }

    protected:
        // On the press (as a row selects on it), and taken: the row under it does not select.
        void OnMouseDown(const MouseEvent& event) override
        {
            if (event.Button != MouseButton::Left)
                return;
            event.Handled = true;
            if (m_onClicked)
                m_onClicked();
        }
        void OnDraw(DrawContext& ctx, const Rect&) override { DrawDisclosure(ctx, GetLocalBounds(), m_expanded, m_color, IsRightToLeft()); }

    private:
        bool m_expanded = false;
        Color m_color{0.80f, 0.84f, 0.90f, 1.0f};
        core::Function<void()> m_onClicked;
    };

    // A tree row's content: its indent, its chevron and its text (`treecell`).
    class TreeRowContent : public UIWidget
    {
        RTTI_OBJECT(TreeRowContent, UIWidget)
    public:
        TreeRowContent()
        {
            SetTag(core::StringView(u8"treerowcontent"));
            m_arrow = core::MakeRef<TreeArrow>(MemoryAllocator());
            AddChild(m_arrow.Get());
            m_label = core::MakeRef<Label>(MemoryAllocator());
            m_label->SetTag(core::StringView(u8"treecell"));
            StyleWriteScope defaults(*m_label); // its own values, which a sheet returns to
            m_label->SetTextAlignment(TextHAlign::Start, TextVAlign::Middle);
            m_label->SetHitTestVisible(false);
            AddChild(m_label.Get());
        }
        [[nodiscard]] Label* GetLabel() const noexcept { return m_label.Get(); }
        [[nodiscard]] TreeArrow* GetArrow() const noexcept { return m_arrow.Get(); }
        void Configure(f32 indent, f32 arrowSize, bool hasChildren, bool expanded)
        {
            m_indent = indent;
            m_arrowSize = arrowSize;
            m_arrow->SetVisible(hasChildren);
            m_arrow->SetExpanded(expanded);
            RequestLayout();
        }
        [[nodiscard]] core::Float2 MeasureContent(core::Float2 available) override
        {
            const f32 textX = m_indent + m_arrowSize + 2.0f;
            const core::Float2 text = m_label->Measure(LayoutConstraints{core::Float2{0.0f, 0.0f}, core::Float2{core::Max(0.0f, available.x - textX), kUnbounded},
                                                                         core::Float2{-1.0f, -1.0f}});
            return core::Float2{textX + text.x, core::Max(text.y, m_arrowSize)};
        }

    protected:
        void OnLayout() override
        {
            // Indented from the inline start, the arrow before the text.
            const Rect box = GetContentBounds();
            const bool rtl = IsRightToLeft();
            m_arrow->Arrange(MirroredIn(Rect{box.x + m_indent, box.y, m_arrowSize, box.height}, box, rtl));
            const f32 textX = m_indent + m_arrowSize + 2.0f;
            m_label->Arrange(MirroredIn(Rect{box.x + textX, box.y, core::Max(0.0f, box.width - textX - 2.0f), box.height}, box, rtl));
        }
        void OnTextStyleChange() override { ShareTextStyle(*m_label); }

    private:
        core::RefPtr<TreeArrow> m_arrow;
        core::RefPtr<Label> m_label;
        f32 m_indent = 0.0f;
        f32 m_arrowSize = 16.0f;
    };

    /// A node of a tree written in markup: its text, whether it starts open, and its children.
    class TreeItem : public UIWidget
    {
        RTTI_OBJECT(TreeItem, UIWidget)
    public:
        TreeItem()
        {
            SetTag(core::StringView(u8"treeitem"));
            SetDisplayed(false); // data, not drawn
        }
        bool SetMarkupAttribute(core::StringView name, core::StringView value) override
        {
            if (name != core::StringView(u8"text"))
                return UIWidget::SetMarkupAttribute(name, value);
            m_text = core::String(value);
            return true;
        }
        [[nodiscard]] core::String GetText() const { return m_text; }
        void SetText(const core::String& text) { m_text = text; }
        void SetExpanded(bool expanded) noexcept { m_expanded = expanded; }
        [[nodiscard]] bool IsExpanded() const noexcept { return m_expanded; }

    private:
        core::String m_text;
        bool m_expanded = false;
    };

    class TreeView : public ItemView
    {
        RTTI_OBJECT(TreeView, ItemView)
    public:
        TreeView() : m_expanded(MemoryAllocator()), m_itemOfId(MemoryAllocator())
        {
            SetTag(core::StringView(u8"treeview"));
            StyleWriteScope defaults(*this); // its own values, which a sheet returns to
            SetTextColor(Color{0.88f, 0.90f, 0.94f, 1.0f});
        }
        // Its own model goes before the view's base would let go of it: let go first.
        ~TreeView() override { SetModel(nullptr); }

        void SetIndentWidth(f32 width)
        {
            m_indentWidth = core::Max(0.0f, width);
            ItemsChanged();
        }

        // Expansion by item (a visible row).
        void ExpandItem(i32 item) { SetExpanded(item, true); }
        void CollapseItem(i32 item) { SetExpanded(item, false); }
        void ToggleItem(i32 item) { SetExpanded(item, !IsItemExpanded(item)); }
        [[nodiscard]] bool IsItemExpanded(i32 item) const
        {
            return item >= 0 && item < static_cast<i32>(m_flat.Size()) && m_expanded.Contains(m_flat[static_cast<usize>(item)].Id);
        }
        [[nodiscard]] i32 ItemDepth(i32 item) const
        {
            return item >= 0 && item < static_cast<i32>(m_flat.Size()) ? m_flat[static_cast<usize>(item)].Depth : 0;
        }
        /// Expansion by node id (open or not, shown or not).
        [[nodiscard]] bool IsIdExpanded(ItemId id) const { return m_expanded.Contains(id); }
        void SetIdExpanded(ItemId id, bool expanded)
        {
            if (expanded)
                (void)m_expanded.Insert(id);
            else
                (void)m_expanded.Remove(id);
            Reflatten();
            ItemsChanged();
        }

        /// Markup's children are its items (nested TreeItems), made into a model of its own.
        [[nodiscard]] Node* GetChildHost() override
        {
            if (!m_markupHost)
            {
                TreeView* self = this;
                m_markupHost = core::MakeRef<MarkupChildHost>(MemoryAllocator(), [self](Node& host) { self->AdoptItems(host); });
            }
            return m_markupHost.Get();
        }

    protected:
        [[nodiscard]] usize ItemCount() const override { return m_flat.Size(); }
        [[nodiscard]] ModelIndex ItemToModelIndex(i32 item) const override
        {
            return item >= 0 && item < static_cast<i32>(m_flat.Size()) ? m_flat[static_cast<usize>(item)].Index : ModelIndex{};
        }
        [[nodiscard]] ItemId ItemIdAt(i32 item) const override
        {
            return item >= 0 && item < static_cast<i32>(m_flat.Size()) ? m_flat[static_cast<usize>(item)].Id : kNoItem;
        }
        [[nodiscard]] i32 ItemOfId(ItemId id) const override
        {
            const i32* item = m_itemOfId.Find(id);
            return item != nullptr ? *item : -1;
        }
        [[nodiscard]] bool IsFlat() const override { return false; }
        // A drag resting on a closed node opens it (E7).
        bool OnDragHoverOpen(core::Float2 local) override
        {
            const i32 item = ItemAt(ConvertToWorldSpace(local));
            if (item < 0 || !m_flat[static_cast<usize>(item)].HasChildren || IsItemExpanded(item))
                return false;
            ExpandItem(item);
            return true;
        }
        void OnModelChanged() override { Reflatten(); }
        [[nodiscard]] core::StringView RowTag() const override { return core::StringView(u8"treerow"); }

        [[nodiscard]] core::RefPtr<Node> CreateContent(u32) override
        {
            auto content = core::MakeRef<TreeRowContent>(MemoryAllocator());
            TreeView* self = this;
            TreeRowContent* raw = content.Get();
            content->GetArrow()->SetOnClicked([self, raw]()
            {
                if (const ItemRow* row = core::Cast<ItemRow>(raw->GetParent()))
                    self->ToggleItem(row->GetItemIndex());
            });
            return content;
        }
        void BindContent(Node& content, i32 item, const ModelIndex& index) override
        {
            const FlatEntry& entry = m_flat[static_cast<usize>(item)];
            TreeRowContent& row = static_cast<TreeRowContent&>(content);
            row.GetLabel()->SetText(GetModel()->Data(index).ToString().AsView());
            row.Configure(static_cast<f32>(entry.Depth) * m_indentWidth, m_arrowSize, entry.HasChildren, m_expanded.Contains(entry.Id));
        }

        // The arrow toward the inline end (Right, Left in right to left) opens a node, or on an open
        // one goes to its first child; toward the start closes an open one, or goes to its parent.
        bool OnExtraKey(KeyCode key, u32 modifiers) override
        {
            const i32 item = GetCurrentItem();
            if (modifiers != 0 || item < 0 || item >= static_cast<i32>(m_flat.Size()))
                return false;
            const FlatEntry& entry = m_flat[static_cast<usize>(item)];
            const i32 along = InlineStep(key);
            if (along > 0 && entry.HasChildren)
            {
                if (!IsItemExpanded(item))
                    ExpandItem(item);
                else
                {
                    SelectByUser(item + 1, 0);
                    ScrollToItem(item + 1);
                }
                return true;
            }
            if (along < 0)
            {
                if (entry.HasChildren && IsItemExpanded(item))
                {
                    CollapseItem(item);
                    return true;
                }
                const i32 parent = ParentItem(item);
                if (parent >= 0)
                {
                    SelectByUser(parent, 0);
                    ScrollToItem(parent);
                    return true;
                }
            }
            return false;
        }

    private:
        void AdoptItems(Node& host)
        {
            if (!m_ownModel)
                m_ownModel = core::MakeUnique<TreeModel>(MemoryAllocator());
            while (host.ChildCount() != 0)
            {
                core::RefPtr<Node> child(host.GetChildAt(0));
                host.RemoveChild(child.Get());
                if (const TreeItem* item = core::Cast<TreeItem>(child.Get()))
                    AddItem(*item, TreeModel::kRoot);
            }
            if (GetModel() != m_ownModel.Get())
                SetModel(m_ownModel.Get());
            Reflatten();
            ItemsChanged();
        }
        void AddItem(const TreeItem& item, i32 parent)
        {
            const i32 id = m_ownModel->AddNode(parent, item.GetText().AsView());
            if (item.IsExpanded())
                (void)m_expanded.Insert(static_cast<ItemId>(id));
            for (usize i = 0; i < item.ChildCount(); ++i)
                if (const TreeItem* child = core::Cast<TreeItem>(item.GetChildAt(i)))
                    AddItem(*child, id);
        }

        struct FlatEntry
        {
            ModelIndex Index;
            ItemId Id;
            i32 Depth;
            bool HasChildren;
        };

        void SetExpanded(i32 item, bool expanded)
        {
            if (item < 0 || item >= static_cast<i32>(m_flat.Size()))
                return;
            const ItemId id = m_flat[static_cast<usize>(item)].Id;
            if (expanded == m_expanded.Contains(id))
                return;
            if (expanded)
                (void)m_expanded.Insert(id);
            else
            {
                // Closing a node that holds the keyboard's row moves it, selected, to the node.
                const i32 current = GetCurrentItem();
                const bool holdsCurrent = current > item && IsUnder(current, item);
                (void)m_expanded.Remove(id);
                if (holdsCurrent)
                    SetSelectedItem(item);
            }
            Reflatten();
            ItemsChanged();
        }
        // Whether flat item `item` lies under flat item `ancestor`.
        [[nodiscard]] bool IsUnder(i32 item, i32 ancestor) const
        {
            const i32 depth = m_flat[static_cast<usize>(ancestor)].Depth;
            for (i32 i = ancestor + 1; i < static_cast<i32>(m_flat.Size()); ++i)
            {
                if (m_flat[static_cast<usize>(i)].Depth <= depth)
                    return false;
                if (i == item)
                    return true;
            }
            return false;
        }
        [[nodiscard]] i32 ParentItem(i32 item) const
        {
            const i32 depth = m_flat[static_cast<usize>(item)].Depth;
            for (i32 i = item - 1; i >= 0; --i)
                if (m_flat[static_cast<usize>(i)].Depth < depth)
                    return i;
            return -1;
        }

        void Reflatten()
        {
            m_flat.Clear();
            m_itemOfId.Clear();
            if (GetModel() != nullptr)
                FlattenLevel(ModelIndex{}, 0);
        }
        void FlattenLevel(const ModelIndex& parent, i32 depth)
        {
            IModel* model = GetModel();
            const usize rows = model->RowCount(parent);
            for (usize r = 0; r < rows; ++r)
            {
                const ModelIndex index = model->Index(static_cast<i32>(r), 0, parent);
                const ItemId id = model->IdOf(index);
                const bool hasChildren = model->HasChildren(index);
                m_itemOfId.InsertOrAssign(id, static_cast<i32>(m_flat.Size()));
                m_flat.PushBack(FlatEntry{index, id, depth, hasChildren});
                if (hasChildren && m_expanded.Contains(id))
                    FlattenLevel(index, depth + 1);
            }
        }

        Array<FlatEntry> m_flat;          // the open nodes, in display order
        core::HashSet<ItemId> m_expanded; // the open nodes' ids
        HashMap<ItemId, i32> m_itemOfId;  // an id's flat item
        f32 m_indentWidth = 16.0f;
        f32 m_arrowSize = 16.0f;
        core::UniquePtr<TreeModel> m_ownModel; // markup's items
        core::RefPtr<Node> m_markupHost;       // where markup's items land, then taken in
    };

    RTTI_DEFINE_OBJECT(TreeArrow, "rtti::gui")
    RTTI_DEFINE_OBJECT(TreeRowContent, "rtti::gui")
}
