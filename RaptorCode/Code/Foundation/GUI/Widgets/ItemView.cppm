// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :item_view partition
//
// ItemView: the engine behind ListView, TreeView and TableView (E6 of Specs/gui-lab-evolution.md).
// It is a scroll container like any other node (its wheel, bars, touch, fling, smooth scrolling,
// right stick and `::scrollbar` parts are Node's), which realises only the rows in view:
//
//   - Rows come from a factory (a native one, or the view's own default): each row type has a
//     pool of rows, and a row scrolled out of view goes back to its pool for the next one.
//     A row is an ItemRow holding the factory's content; it shows `:selected`.
//   - Heights are fixed (`row-height`) or measured: a measured row's height is estimated until it
//     is first realised, then measured, and kept in a sum tree (RowHeights), so finding the row at
//     an offset or the offset of a row is a logarithmic walk (GPUI's list in role).
//   - Scrolling is anchored to an item and an offset into it: a row above measuring taller, or
//     rows inserted above, leave what is in view where it is.
//   - The model reports row ranges (E6); the view follows inserts, removals, moves and changes of
//     a flat model and resets for the rest. Selection is a set of row ids, so it survives inserts,
//     moves and sorting.
//   - A grid is a layout mode of the same view: cells of a size, as many across as fit (stretched
//     to fill the row), lines of them down; the arrows move across and down.
//   - Rows from markup: a `<template>` child is made into each row, its `{{item}}`,
//     `{{item.Column}}` and `{{index}}` attributes filled for the item it shows; templates of a
//     `type` are picked by the text in the view's `row-type-column`. `items="a|b|c"` gives a
//     markup list a model of its own.
//   - Drag and drop (E7): with a `drag-type`, rows drag the selection (their ids, the view a weak
//     handle in the payload's value); as a target the view finds where a drop lands in a row
//     (before, on or after it, by quarter bands, by halves when the model takes nothing onto a
//     row), asks its model (ModelDrop: CanDrop, Drop), and draws an insertion line or an outline
//     (`::drop-indicator`); a row moved to another model is removed from this one.
//   - A double-click, Return or the pad's South reports `activate`; typing letters and digits
//     jumps to the next row that starts with them (read from the keys, not text input, which the
//     shell turns on for fields alone); F2 (or BeginEdit) edits a row in place, a hook able to
//     refuse the edit or the value.
//
// A subclass says what an item is (ItemCount, ItemToModelIndex: a tree flattens its open nodes),
// makes its default rows (CreateContent, BindContent), and adds decorations (a table's header).

module;
#include "Core/Prelude.h"
#include <algorithm> // sort (the items with accessibility nodes)
#include "Core/Reflection/Reflect.h"

export module foundation.gui:item_view;

import foundation.core; // RefPtr, Array, HashSet, Function, Move, Min, Max
import :rect;
import :event;
import :draw_context;
import :node;
import :ui_widget;
import :layout_style; // Overflow, ScrollAlign, LayoutConstraints
import :variant;
import :model_index;
import :model;
import :text_field;
import :text;             // StartsWithIgnoringCase (type-ahead)
import :event_dispatcher; // GetTime (type-ahead)
import :reactive;         // Observable (what bindings follow)
import :element_types;    // ElementSet (a template's elements)
import :markup;           // MarkupLoader, ItemBinding (template rows)
import :string_list_model;
import :list_model;       // a script's model (E16)
import :list_box;         // SplitItems, JoinItems
import foundation.vg;     // StrokeStyle (the drop indicator)

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    enum class SelectionMode
    {
        Single,
        Multi
    };

    /// How an item view lays its items out: rows down (List), or cells across then down (Grid).
    enum class ItemLayout : u8
    {
        List,
        Grid,
    };

    /// Row heights in a sum tree (a Fenwick tree): the offset of a row and the row at an offset
    /// in O(log n), a height changed in O(log n); inserts and removals rebuild it, O(n).
    class RowHeights
    {
    public:
        void Reset(usize count, f32 estimate)
        {
            m_heights.Clear();
            m_measured.Clear();
            for (usize i = 0; i < count; ++i)
            {
                m_heights.PushBack(estimate);
                m_measured.PushBack(0);
            }
            Rebuild();
        }
        void Insert(usize at, usize count, f32 estimate)
        {
            at = core::Min(at, m_heights.Size());
            for (usize i = 0; i < count; ++i)
            {
                m_heights.Insert(at, estimate);
                m_measured.Insert(at, u8{0});
            }
            Rebuild();
        }
        void Remove(usize at, usize count)
        {
            for (usize i = 0; i < count && at < m_heights.Size(); ++i)
            {
                m_heights.RemoveAt(at);
                m_measured.RemoveAt(at);
            }
            Rebuild();
        }
        /// `count` rows from `first` now start at `to` (in the order after the move).
        void Move(usize first, usize count, usize to)
        {
            Array<f32> heights;
            Array<u8> measured;
            for (usize i = 0; i < count && first < m_heights.Size(); ++i)
            {
                heights.PushBack(m_heights[first]);
                measured.PushBack(m_measured[first]);
                m_heights.RemoveAt(first);
                m_measured.RemoveAt(first);
            }
            to = core::Min(to, m_heights.Size());
            for (usize i = 0; i < heights.Size(); ++i)
            {
                m_heights.Insert(to + i, heights[i]);
                m_measured.Insert(to + i, measured[i]);
            }
            Rebuild();
        }

        [[nodiscard]] usize Size() const noexcept { return m_heights.Size(); }
        [[nodiscard]] f32 At(usize i) const { return i < m_heights.Size() ? m_heights[i] : 0.0f; }
        [[nodiscard]] bool IsMeasured(usize i) const { return i < m_measured.Size() && m_measured[i] != 0; }
        /// Sets a row's height (measured: it stays until Unmeasure); true when it changed.
        bool Set(usize i, f32 height, bool measured = true)
        {
            if (i >= m_heights.Size())
                return false;
            m_measured[i] = measured ? 1 : 0;
            const f32 delta = height - m_heights[i];
            if (delta == 0.0f)
                return false;
            m_heights[i] = height;
            for (usize k = i + 1; k <= m_heights.Size(); k += k & (~k + 1))
                m_tree[k] += delta;
            return true;
        }
        void Unmeasure(usize i)
        {
            if (i < m_measured.Size())
                m_measured[i] = 0;
        }
        /// Where row `i` starts: the sum of the heights before it.
        [[nodiscard]] f32 Top(usize i) const
        {
            f32 sum = 0.0f;
            for (usize k = core::Min(i, m_heights.Size()); k > 0; k -= k & (~k + 1))
                sum += m_tree[k];
            return sum;
        }
        [[nodiscard]] f32 Total() const { return Top(m_heights.Size()); }
        /// The row at offset `y` (the last row past the end; 0 when there are none).
        [[nodiscard]] usize Find(f32 y) const
        {
            const usize n = m_heights.Size();
            if (n == 0)
                return 0;
            usize pos = 0;
            for (usize step = m_highBit; step > 0; step >>= 1)
                if (pos + step <= n && m_tree[pos + step] <= y)
                {
                    pos += step;
                    y -= m_tree[pos];
                }
            return core::Min(pos, n - 1);
        }

    private:
        void Rebuild()
        {
            const usize n = m_heights.Size();
            m_tree.Clear();
            for (usize i = 0; i <= n; ++i)
                m_tree.PushBack(0.0f);
            for (usize i = 1; i <= n; ++i)
            {
                m_tree[i] += m_heights[i - 1];
                const usize parent = i + (i & (~i + 1));
                if (parent <= n)
                    m_tree[parent] += m_tree[i];
            }
            m_highBit = 1;
            while (m_highBit * 2 <= n)
                m_highBit *= 2;
        }

        Array<f32> m_heights;
        Array<u8> m_measured;
        Array<f32> m_tree; // 1-based
        usize m_highBit = 1;
    };

    class ItemView;

    /// A native row factory: a row's content made once per pooled row of a type, and filled for
    /// each item it shows.
    struct RowFactory
    {
        /// The row type an item takes (unset: one type); each type has its own pool.
        core::Function<u32(const ModelIndex&)> TypeOf;
        core::Function<core::RefPtr<Node>(u32 type)> Create;
        core::Function<void(Node& content, const ModelIndex& index)> Bind;
    };

    /// One realised row: the view's container round a factory's content. It shows `:selected`
    /// and draws the view's ::selection part under its content while selected.
    class ItemRow : public UIWidget
    {
        RTTI_OBJECT(ItemRow, UIWidget)
    public:
        explicit ItemRow(ItemView& view);

        [[nodiscard]] i32 GetItemIndex() const noexcept { return m_item; }
        [[nodiscard]] ItemId GetItemId() const noexcept { return m_id; }
        [[nodiscard]] u32 GetRowType() const noexcept { return m_type; }
        [[nodiscard]] Node* GetContent() const noexcept { return m_content.Get(); }
        [[nodiscard]] bool IsSelected() const noexcept { return m_selected; }
        [[nodiscard]] u32 GetWidgetStates() const override { return m_selected ? WidgetStateSelected : WidgetStateNone; }

    protected:
        void OnMouseDown(const MouseEvent& event) override;
        void OnMouseClick(const MouseEvent& event) override;
        void OnDraw(DrawContext& ctx, const Rect& localBounds) override;
        void OnLayout() override;
        void OnTextStyleChange() override
        {
            if (UINode* content = core::Cast<UINode>(m_content.Get()))
                ShareTextStyle(*content);
        }

    private:
        friend class ItemView;
        void SetSelectedState(bool selected)
        {
            if (selected == m_selected)
                return;
            m_selected = selected;
            MarkStyleStateDirty(StateSelected);
            Invalidate();
        }

        ItemView& m_view; // its parent, which owns it
        core::RefPtr<Node> m_content;
        i32 m_item = -1;
        ItemId m_id = kNoItem;
        u32 m_type = 0;
        bool m_selected = false;
        bool m_dirty = true; // its content shows stale data
        bool m_taken = false; // claimed in this realisation
    };

    // A row made from a markup template: the template's tree, and the attributes it fills from
    // the item it shows.
    class TemplateRowContent : public UIWidget
    {
        RTTI_OBJECT(TemplateRowContent, UIWidget)
    public:
        TemplateRowContent() { SetTag(core::StringView(u8"templaterow")); }
        [[nodiscard]] Array<ItemBinding>& Bindings() noexcept { return m_bindings; }

    protected:
        // The template's root fills the row (or a grid's cell), inside its margin.
        void OnLayout() override
        {
            const Rect box = GetContentBounds();
            for (usize i = 0; i < ChildCount(); ++i)
            {
                Node& child = *GetChildAt(i);
                const Thickness m = child.GetMargin();
                child.Arrange(Rect{box.x + m.Left, box.y + m.Top, core::Max(0.0f, box.width - m.TotalHorizontal()),
                                   core::Max(0.0f, box.height - m.TotalVertical())});
            }
        }

    private:
        Array<ItemBinding> m_bindings;
    };

    class ItemView : public UIWidget, public IModelClient
    {
        RTTI_OBJECT(ItemView, UIWidget)
    public:
        ItemView() : m_selected(MemoryAllocator())
        {
            SetTabFocusable(true);
            StyleWriteScope defaults(*this);
            EditLayoutStyle([](LayoutStyle& s)
            {
                s.OverflowY = Overflow::Auto;
            });
            SetScrollStep(m_rowHeight);
        }
        ~ItemView() override
        {
            if (m_model != nullptr)
                m_model->RemoveClient(this);
        }

        // === Model ===
        void SetModel(IModel* model)
        {
            if (m_model != nullptr)
                m_model->RemoveClient(this);
            m_model = model;
            if (m_model != nullptr)
                m_model->AddClient(this);
            m_selected.Clear();
            m_current = kNoItem;
            m_anchorSelection = kNoItem;
            ResetScrollAnchor();
            SetScrollOffset(core::Float2{0.0f, 0.0f});
            OnModelReset();
        }
        [[nodiscard]] IModel* GetModel() const noexcept { return m_model; }

        // === Rows ===
        /// Rows from a native factory instead of the view's own (the pools start again).
        void SetRowFactory(RowFactory factory)
        {
            m_factory = core::Move(factory);
            DropRows();
            RequestLayout();
        }
        /// A markup template for rows (`type` names one of several, picked by the
        /// row-type-column's text; empty: the default).
        bool SetMarkupTemplate(core::StringView type, core::StringView markup) override
        {
            m_templates.PushBack(RowTemplate{core::String(type), core::String(markup)});
            UseTemplates();
            return true;
        }
        /// The column whose text picks a row's template (by its `type`).
        void SetRowTypeColumn(const core::String& column)
        {
            m_rowTypeColumn = column;
            if (!m_templates.IsEmpty())
                UseTemplates();
        }
        [[nodiscard]] core::String GetRowTypeColumn() const { return m_rowTypeColumn; }
        /// Shows a script's list model (E16), keeping it alive while it does.
        void SetListModel(RefPtr<ListModel> model)
        {
            m_listModel = core::Move(model);
            SetModel(m_listModel ? &m_listModel->Model() : nullptr);
        }
        /// A model of its own from text, '|' between the items (markup's `items`).
        void SetItemsText(const core::String& text)
        {
            if (!m_ownModel)
                m_ownModel = core::MakeUnique<StringListModel>(MemoryAllocator());
            Array<core::String> items;
            for (core::StringView item : SplitItems(text.AsView()))
                items.PushBack(core::String(item));
            m_ownModel->SetItems(core::Move(items));
            if (m_model != m_ownModel.Get())
                SetModel(m_ownModel.Get());
        }
        [[nodiscard]] core::String GetItemsText() const
        {
            Array<core::String> items;
            if (m_ownModel)
                for (usize i = 0; i < m_ownModel->RowCount(); ++i)
                    items.PushBack(core::String(m_ownModel->ItemAt(i)));
            return JoinItems(items);
        }
        /// "single" or "multi" (markup's `selection-mode`).
        void SetSelectionModeName(const core::String& name)
        {
            m_selectionMode = core::Trim(name.AsView()) == core::StringView(u8"multi") ? SelectionMode::Multi : SelectionMode::Single;
        }
        [[nodiscard]] core::String GetSelectionModeName() const
        {
            return core::String(m_selectionMode == SelectionMode::Multi ? core::StringView(u8"multi") : core::StringView(u8"single"));
        }

        /// Every row this tall (0: each measured, estimated until it is).
        void SetRowHeight(f32 height)
        {
            m_rowHeight = core::Max(0.0f, height);
            SetScrollStep(m_rowHeight > 0.0f ? m_rowHeight : m_estimate);
            m_heights.Reset(ItemCount(), RowEstimate());
            RequestLayout();
        }
        [[nodiscard]] f32 GetRowHeight() const noexcept { return m_rowHeight; }
        /// What an unmeasured row is taken to be until it is realised.
        void SetEstimatedRowHeight(f32 height)
        {
            m_estimate = core::Max(1.0f, height);
            if (m_rowHeight <= 0.0f)
                m_heights.Reset(ItemCount(), m_estimate);
            RequestLayout();
        }
        [[nodiscard]] f32 GetEstimatedRowHeight() const noexcept { return m_estimate; }
        /// The rows realised now (in view, and one past each edge).
        [[nodiscard]] usize VisibleRowCount() const noexcept { return m_live.Size(); }
        /// The realised row showing `item` (null when it is not in view).
        [[nodiscard]] ItemRow* RowForItem(i32 item) const
        {
            for (const core::RefPtr<ItemRow>& row : m_live)
                if (row->m_item == item)
                    return row.Get();
            return nullptr;
        }
        /// The item under a point in world space (-1: none).
        [[nodiscard]] i32 ItemAt(core::Float2 world) const
        {
            for (const core::RefPtr<ItemRow>& row : m_live)
                if (row->GetScreenBounds().Contains(world))
                    return row->m_item;
            return -1;
        }
        /// Where an item starts in the content and how tall it is (estimated until measured).
        [[nodiscard]] Rect ItemBounds(i32 item) const
        {
            const Rect box = GetContentBounds();
            const i32 i = core::Max(0, item);
            if (m_layout == ItemLayout::Grid)
            {
                const i32 across = GridColumns(box.width);
                const f32 w = box.width / static_cast<f32>(across);
                return CellBounds(box, i, across, w, box.y + ContentTopInset() + ItemTop(i), ItemHeight(i));
            }
            const f32 width = RowWidth(box.width);
            return Rect{RowLeft(box, width), box.y + ContentTopInset() + ItemTop(i), width, ItemHeight(i)};
        }
        /// Where a row `width` wide starts: at the box's left, or, scrolling from the right (right to
        /// left, a table wider than its view), at its right less the width, overflowing leftward.
        [[nodiscard]] f32 RowLeft(const Rect& box, f32 width) const { return ScrollsFromRight() ? box.Right() - width : box.x; }
        /// A grid's cell: across its line from the inline start.
        [[nodiscard]] Rect CellBounds(const Rect& box, i32 item, i32 across, f32 width, f32 y, f32 height) const
        {
            return MirroredIn(Rect{box.x + static_cast<f32>(item % across) * width, y, width, height}, box, IsRightToLeft());
        }

        // === Grid ===
        /// Lists rows down, or lays cells out in a grid.
        void SetLayoutMode(ItemLayout layout)
        {
            m_layout = layout;
            ForEachRow([](ItemRow& row) { row.m_dirty = true; });
            RequestLayout();
        }
        [[nodiscard]] ItemLayout GetLayoutMode() const noexcept { return m_layout; }
        /// "list" or "grid" (markup's `layout`).
        void SetLayoutModeName(const core::String& name)
        {
            SetLayoutMode(core::Trim(name.AsView()) == core::StringView(u8"grid") ? ItemLayout::Grid : ItemLayout::List);
        }
        [[nodiscard]] core::String GetLayoutModeName() const
        {
            return core::String(m_layout == ItemLayout::Grid ? core::StringView(u8"grid") : core::StringView(u8"list"));
        }
        /// A grid cell's least width (as many fit across as can, stretched to fill) and height.
        void SetCellWidth(f32 width)
        {
            m_cellSize.x = core::Max(1.0f, width);
            RequestLayout();
        }
        [[nodiscard]] f32 GetCellWidth() const noexcept { return m_cellSize.x; }
        void SetCellHeight(f32 height)
        {
            m_cellSize.y = core::Max(1.0f, height);
            RequestLayout();
        }
        [[nodiscard]] f32 GetCellHeight() const noexcept { return m_cellSize.y; }
        /// How many cells a grid lays across (1 for a list).
        [[nodiscard]] i32 GetColumnsAcross() const { return GridColumns(GetContentBounds().width); }
        /// Scrolls so `item` shows (Nearest: the least move).
        void ScrollToItem(i32 item, ScrollAlign align = ScrollAlign::Nearest)
        {
            if (item < 0 || item >= static_cast<i32>(ItemCount()))
                return;
            const Rect box = GetContentBounds();
            const f32 view = core::Max(0.0f, box.height - ContentTopInset());
            const f32 top = ItemTop(item);
            const f32 bottom = top + ItemHeight(item);
            const f32 now = GetScrollTarget().y;
            f32 to = now;
            switch (align)
            {
            case ScrollAlign::Start: to = top; break;
            case ScrollAlign::End: to = bottom - view; break;
            case ScrollAlign::Center: to = (top + bottom - view) * 0.5f; break;
            case ScrollAlign::Nearest:
            default:
                if (top < now)
                    to = top;
                else if (bottom > now + view)
                    to = core::Min(top, bottom - view);
                break;
            }
            // Its offset is known now, so the extent is brought up to date first (the range).
            SetScrollExtent(core::Float2{GetContentExtent().x, ContentTopInset() + ContentHeight()});
            ScrollTo(core::Float2{GetScrollTarget().x, to});
            if (!m_realizing)
                Realize();
        }

        // === Drag and drop (E7) ===
        // (Rows drag the selection as the view's `drag-type`; empty, they do not drag.)
        /// The ids of the rows of the drag going from here (in their order).
        [[nodiscard]] const core::Array<ItemId>& GetDraggedIds() const noexcept { return m_dragIds; }
        /// Where a drop would land now (the item, -1 for the end; the place), while one is over it.
        [[nodiscard]] i32 GetDropItem() const noexcept { return m_dropOver ? m_dropItem : -1; }
        [[nodiscard]] DropPlace GetDropPlace() const noexcept { return m_dropPlace; }
        [[nodiscard]] bool IsDropOver() const noexcept { return m_dropOver; }

        // === Appearance ===
        void CollectStyleParts(core::Array<core::StringView>& out) const override
        {
            out.PushBack(core::StringView(u8"selection"));
            out.PushBack(core::StringView(u8"drop-indicator"));
        }
        // Its rows draw the selection in ::selection's style.
        void OnPartStyleChange(core::StringView part) override
        {
            if (part == core::StringView(u8"selection"))
                ForEachRow([](ItemRow& row) { row.Invalidate(); });
        }

        // === Selection ===
        void SetSelectionMode(SelectionMode mode) noexcept { m_selectionMode = mode; }
        [[nodiscard]] SelectionMode GetSelectionMode() const noexcept { return m_selectionMode; }
        /// The user changed the selection (code's changes report nothing); the index is the
        /// current item's.
        void SetOnSelectionChanged(core::Function<void(ModelIndex)> callback) { m_onSelection = core::Move(callback); }
        /// A row was activated: a double-click, Return or the pad's South.
        void SetOnActivated(core::Function<void(ModelIndex)> callback) { m_onActivated = core::Move(callback); }

        [[nodiscard]] usize GetSelectionCount() const noexcept { return m_selected.Size(); }
        [[nodiscard]] bool IsIdSelected(ItemId id) const { return m_selected.Contains(id); }
        [[nodiscard]] bool IsItemSelected(i32 item) const { return item >= 0 && IsIdSelected(ItemIdAt(item)); }
        /// The selected ids.
        void GetSelectedIds(core::Array<ItemId>& out) const
        {
            for (ItemId id : m_selected)
                out.PushBack(id);
        }
        /// The current item (where the keyboard is) when it is selected, else -1.
        [[nodiscard]] i32 GetSelectedItem() const
        {
            m_selectionChanged.Track(); // a read a binding records
            const i32 item = ItemOfId(m_current);
            return item >= 0 && IsIdSelected(m_current) ? item : -1;
        }
        /// The item the keyboard is on (-1: none).
        [[nodiscard]] i32 GetCurrentItem() const { return ItemOfId(m_current); }
        [[nodiscard]] ModelIndex GetSelectedIndex() const
        {
            const i32 item = GetSelectedItem();
            return item >= 0 ? ItemToModelIndex(item) : ModelIndex{};
        }

        // === Accessibility (E17b): its items as nodes of the accessibility tree, which the GUI
        // builds (AccessibilityImpl.cpp). Not every item has one: the rows made and a page of items
        // each side, the current item and the selected ones (each node says its place among all),
        // so a list of a hundred thousand sends a few dozen. ===
        [[nodiscard]] usize GetItemCount() const { return ItemCount(); }
        [[nodiscard]] core::String GetItemText(i32 item) const { return TypeAheadText(item); }
        [[nodiscard]] ModelIndex GetItemIndex(i32 item) const { return ItemToModelIndex(item); }
        /// The items that have nodes, in item order.
        void GetAccessItems(core::Array<i32>& out) const
        {
            const i32 count = static_cast<i32>(ItemCount());
            if (count <= 0)
                return;
            i32 first = count, last = -1;
            for (const core::RefPtr<ItemRow>& row : m_live)
                if (row->m_item >= 0)
                {
                    first = core::Min(first, row->m_item);
                    last = core::Max(last, row->m_item);
                }
            if (last < 0)
                first = last = core::Max(0, GetCurrentItem());
            const i32 page = core::Max(1, last - first + 1);
            core::HashSet<i32> wanted;
            for (i32 i = core::Max(0, first - page); i <= core::Min(count - 1, last + page); ++i)
                (void)wanted.Insert(i);
            if (const i32 current = GetCurrentItem(); current >= 0)
                (void)wanted.Insert(current);
            usize selected = 0;
            for (ItemId id : m_selected)
                if (const i32 item = ItemOfId(id); item >= 0 && selected++ < kAccessSelectedCap)
                    (void)wanted.Insert(item);
            for (i32 item : wanted)
                out.PushBack(item);
            std::sort(out.begin(), out.end());
        }
        /// An item's key among this view's nodes: it follows the item as rows recycle, scroll and
        /// move, made the first time the item is asked for. The GUI joins it to the view's own.
        [[nodiscard]] u32 GetAccessKeyOfItem(i32 item)
        {
            const ItemId id = ItemIdAt(item);
            if (const u32* key = m_accessKeys.Find(id))
                return *key;
            const u32 key = m_nextAccessKey++;
            m_accessKeys.InsertOrAssign(id, key);
            m_accessItems.InsertOrAssign(key, id);
            return key;
        }
        /// The item a key names now (-1: gone).
        [[nodiscard]] i32 GetItemOfAccessKey(u32 key) const
        {
            const ItemId* id = m_accessItems.Find(key);
            return id != nullptr ? ItemOfId(*id) : -1;
        }
        /// This view's key among the GUI's item views (0 until the GUI gives it one).
        [[nodiscard]] u32 GetAccessViewKey() const noexcept { return m_accessViewKey; }
        void SetAccessViewKey(u32 key) noexcept { m_accessViewKey = key; }
        /// What each item's node said last (by its id), so a node unchanged is not sent again.
        [[nodiscard]] core::HashMap<u64, u64>& AccessItemsSent() noexcept { return m_accessSent; }
        /// A screen reader moves to an item: as the keyboard would, selected and scrolled to.
        void FocusItemFromAccess(i32 item)
        {
            RequestFocus();
            SelectByUser(item, 0);
            ScrollToItem(item);
        }
        void ActivateItemFromAccess(i32 item) { ActivateItem(item); }
        /// Selects one item from code (scrolled into view; no events). -1 clears.
        void SetSelectedItem(i32 item)
        {
            if (item < 0 || item >= static_cast<i32>(ItemCount()))
            {
                ClearSelection();
                return;
            }
            SelectOnly(item);
            ScrollToItem(item);
        }
        void ClearSelection()
        {
            m_selected.Clear();
            m_anchorSelection = kNoItem;
            RefreshSelectionStates();
        }
        /// Every item (multi-selection), as Ctrl+A does.
        void SelectAll()
        {
            if (m_selectionMode != SelectionMode::Multi)
                return;
            for (i32 i = 0; i < static_cast<i32>(ItemCount()); ++i)
                (void)m_selected.Insert(ItemIdAt(i));
            RefreshSelectionStates();
        }

        // === Editing ===
        /// Edits `item` in place (`column` for a table), if its model cell is editable and the
        /// begin hook allows; false otherwise.
        bool BeginEdit(i32 item, i32 column = 0);
        /// Ends an edit: commits (if the commit hook and the model take it) or cancels. False
        /// when the value was refused and it is still editing.
        bool EndEdit(bool commit);
        [[nodiscard]] bool IsEditing() const noexcept { return m_editing; }
        [[nodiscard]] TextField* GetEditor() const noexcept { return m_editor.Get(); }
        /// May refuse to start an edit.
        void SetOnEditBegin(core::Function<bool(const ModelIndex&)> hook) { m_onEditBegin = core::Move(hook); }
        /// May refuse a value (false: it keeps editing, marked `.invalid`); otherwise the model's
        /// SetData decides.
        void SetOnEditCommit(core::Function<bool(const ModelIndex&, core::StringView)> hook) { m_onEditCommit = core::Move(hook); }
        void SetOnEditCancel(core::Function<void(const ModelIndex&)> hook) { m_onEditCancel = core::Move(hook); }

        // === IModelClient ===
        void OnModelReset() override
        {
            OnModelChanged();
            if (m_editing && ItemOfId(m_editId) < 0)
                (void)EndEdit(false);
            m_heights.Reset(ItemCount(), RowEstimate());
            ForEachRow([](ItemRow& row) { row.m_dirty = true; });
            PruneSelection();
            ClampScrollAnchor();
            RequestLayout();
        }
        void OnRowsInserted(const ModelIndex& parent, i32 first, i32 count) override
        {
            if (parent.IsValid() || !IsFlat())
            {
                OnModelReset();
                return;
            }
            m_heights.Insert(static_cast<usize>(first), static_cast<usize>(count), RowEstimate());
            if (first <= m_scrollAnchor)
                m_scrollAnchor += count; // what is in view stays in view
            RequestLayout();
        }
        void OnRowsRemoved(const ModelIndex& parent, i32 first, i32 count) override
        {
            if (parent.IsValid() || !IsFlat())
            {
                OnModelReset();
                return;
            }
            m_heights.Remove(static_cast<usize>(first), static_cast<usize>(count));
            if (m_editing && ItemOfId(m_editId) < 0)
                (void)EndEdit(false);
            if (m_scrollAnchor >= first + count)
                m_scrollAnchor -= count;
            else if (m_scrollAnchor >= first)
            {
                m_scrollAnchor = first; // its row went: the one now in its place, from its top
                m_scrollAnchorDelta = 0.0f;
            }
            PruneSelection();
            ClampScrollAnchor();
            RequestLayout();
        }
        void OnRowsMoved(const ModelIndex& parent, i32 first, i32 count, i32 to) override
        {
            if (parent.IsValid() || !IsFlat())
            {
                OnModelReset();
                return;
            }
            m_heights.Move(static_cast<usize>(first), static_cast<usize>(count), static_cast<usize>(to));
            RequestLayout();
        }
        void OnRowsChanged(const ModelIndex& parent, i32 first, i32 count) override
        {
            if (parent.IsValid() || !IsFlat())
            {
                OnModelReset();
                return;
            }
            for (i32 i = first; i < first + count; ++i)
            {
                m_heights.Unmeasure(static_cast<usize>(i));
                if (ItemRow* row = RowForItem(i))
                    row->m_dirty = true;
            }
            RequestLayout();
        }

    protected:
        // === What a subclass says ===
        [[nodiscard]] virtual usize ItemCount() const { return m_model != nullptr ? m_model->RowCount() : 0; }
        [[nodiscard]] virtual ModelIndex ItemToModelIndex(i32 item) const
        {
            return m_model != nullptr ? m_model->Index(item) : ModelIndex{};
        }
        [[nodiscard]] virtual ItemId ItemIdAt(i32 item) const
        {
            return m_model != nullptr && item >= 0 ? m_model->IdOf(ItemToModelIndex(item)) : kNoItem;
        }
        [[nodiscard]] virtual i32 ItemOfId(ItemId id) const
        {
            if (m_model == nullptr || id == kNoItem)
                return -1;
            const ModelIndex index = m_model->IndexOfId(id);
            return index.IsValid() ? index.Row : -1;
        }
        /// Its items are the model's top-level rows (a tree's are not: it resets on every range).
        [[nodiscard]] virtual bool IsFlat() const { return true; }
        /// A default row's content, and filling it (when no factory is set).
        [[nodiscard]] virtual core::RefPtr<Node> CreateContent(u32 type) = 0;
        virtual void BindContent(Node& content, i32 item, const ModelIndex& index) = 0;
        /// Room above the rows (a table's header).
        [[nodiscard]] virtual f32 ContentTopInset() const { return 0.0f; }
        /// How wide a row is in a content box `width` wide (a table's columns may be wider).
        [[nodiscard]] virtual f32 RowWidth(f32 width) const { return width; }
        /// The model was set or reset (a tree flattens, a table rebuilds its header).
        virtual void OnModelChanged() {}
        /// After the rows are placed (a table places its header).
        virtual void OnLayoutDecorations() {}
        /// A key before the view's own (a tree's Left and Right); true when used.
        virtual bool OnExtraKey(KeyCode key, u32 modifiers)
        {
            (void)key, (void)modifiers;
            return false;
        }
        /// Where an editor goes over a row (in the row's space).
        [[nodiscard]] virtual Rect EditRect(const ItemRow& row, i32 column) const
        {
            (void)column;
            return row.GetContentBounds();
        }
        /// The text type-ahead matches (the display text of the item's first column).
        [[nodiscard]] virtual core::String TypeAheadText(i32 item) const
        {
            return m_model != nullptr ? m_model->Data(ItemToModelIndex(item)).ToString() : core::String{};
        }
        /// Its rows' tag (`listviewrow`, `treerow`, ...).
        [[nodiscard]] virtual core::StringView RowTag() const { return core::StringView(u8"itemrow"); }

        // === Helpers for a subclass ===
        template <typename F>
        void ForEachRow(F&& f)
        {
            for (const core::RefPtr<ItemRow>& row : m_live)
                f(*row);
            for (Pool& pool : m_pools)
                for (const core::RefPtr<ItemRow>& row : pool.Rows)
                    f(*row);
        }
        [[nodiscard]] const core::Array<core::RefPtr<ItemRow>>& LiveRows() const noexcept { return m_live; }
        /// The items changed in a way only the subclass knows (a tree opened a node): heights
        /// start again, rows are refilled.
        void ItemsChanged()
        {
            m_heights.Reset(ItemCount(), RowEstimate());
            ForEachRow([](ItemRow& row) { row.m_dirty = true; });
            PruneSelection();
            ClampScrollAnchor();
            RequestLayout();
            if (!m_realizing && GetSize().y > 0.0f)
                Realize();
        }
        /// Selects as a click does, with its modifiers (a subclass's own rows call it).
        void SelectByUser(i32 item, u32 modifiers);

        void OnLayout() override
        {
            Realize();
            OnLayoutDecorations();
        }
        void OnScrollChange() override
        {
            if (m_realizing)
                return;
            UpdateScrollAnchor();
            if (GetSize().y <= 0.0f)
                return;
            Realize(); // laid out: the rows now in view, at once (a press lands on them)
            OnLayoutDecorations();
        }
        void OnTextStyleChange() override
        {
            ForEachRow([this](ItemRow& row) { ShareTextStyle(row); });
            if (m_rowHeight <= 0.0f)
                m_heights.Reset(ItemCount(), RowEstimate()); // a new font measures anew
            RequestLayout();
        }
        void OnKeyDown(const KeyEvent& event) override;
        // Typed text is its type-ahead (E12): it asks for text input while it has items.
        [[nodiscard]] bool WantsTextInput() const override { return IsTreeEnabled() && ItemCount() > 0; }
        void OnTextInput(const TextInputEvent& event) override
        {
            if (event.Target == this && TypeAhead(event.Text))
                event.Handled = true;
        }
        bool OnActivate() override
        {
            const i32 item = GetCurrentItem();
            if (item < 0)
                return false;
            ActivateItem(item);
            return true;
        }
        // A context menu asked for over a row selects it first (unless it is selected already),
        // and goes on up (to whoever opens a menu).
        void OnContextMenu(const MouseEvent& event) override
        {
            const i32 item = ItemAt(event.Position);
            if (item >= 0 && !IsItemSelected(item))
                SelectByUser(item, 0);
        }

        // --- Drag and drop (E7) ---
        bool OnDragRequested(DragRequest& request) override
        {
            if (GetDragType().IsEmpty() || m_model == nullptr)
                return false;
            const i32 item = request.FromKeyboard ? GetCurrentItem() : ItemAt(ConvertToWorldSpace(request.Press));
            if (item < 0)
                return false;
            m_deferredItem = -1;
            if (!IsItemSelected(item))
            {
                SelectOnly(item);
                NotifySelectionByUser();
            }
            // The selection in item order (one row: no scan).
            m_dragIds.Clear();
            if (m_selected.Size() == 1)
                m_dragIds.PushBack(ItemIdAt(item));
            else
                for (i32 i = 0; i < static_cast<i32>(ItemCount()); ++i)
                    if (IsItemSelected(i))
                        m_dragIds.PushBack(ItemIdAt(i));
            request.Payload.Type = GetDragType();
            request.Payload.Value = HandleAs(Node::StaticType()); // the view, weakly: a target reads its ids
            request.Payload.Label = m_dragIds.Size() == 1 ? TypeAheadText(item) : core::Format(u8"{} items", m_dragIds.Size());
            request.Payload.Allowed = DropEffectsCopy | DropEffectsMove;
            return true;
        }
        void OnDragQuery(DropQuery& query) override;
        void OnDragLeave(const DragEvent&) override { SetDropIndicator(false, -1, DropPlace::After); }
        void OnDrop(const DragEvent& event) override;
        void OnDragEnd(const DragResult& result) override
        {
            // Moved to another model: the rows leave this one (one moved within it moved already).
            if (result.Effect == DropEffect::Move && m_model != nullptr && !m_dragIds.IsEmpty())
            {
                const ItemView* target = core::Cast<ItemView>(result.Target);
                if (target == nullptr || target->GetModel() != m_model)
                    (void)m_model->RemoveIds(m_dragIds);
            }
            m_dragIds.Clear();
        }
        void OnDrawAbove(DrawContext& ctx) override;

    private:
        friend class ItemRow;

        // Where a drop at `local` lands, as the model hears it (its answer in `effect`/`reason`).
        ModelDrop DropAt(const DropQuery& query, DropEffect& effect, core::String& reason);
        void SetDropIndicator(bool over, i32 item, DropPlace place)
        {
            if (over == m_dropOver && item == m_dropItem && place == m_dropPlace)
                return;
            m_dropOver = over;
            m_dropItem = item;
            m_dropPlace = place;
            Invalidate();
        }
        // A click on a row whose press left a multi-selection alone (to drag it): selected alone now.
        void RowClicked(ItemRow& row, const MouseEvent&)
        {
            if (m_deferredItem >= 0 && m_deferredItem == row.m_item)
            {
                SelectOnly(m_deferredItem);
                NotifySelectionByUser();
            }
            m_deferredItem = -1;
        }

        struct Pool
        {
            u32 Type = 0;
            core::Array<core::RefPtr<ItemRow>> Rows;
        };

        struct RowTemplate
        {
            core::String Type;
            core::String Markup;
        };
        // Rows from the markup templates: each type made by loading its markup with item
        // bindings, and filled by them.
        void UseTemplates()
        {
            ItemView* self = this;
            RowFactory factory;
            factory.TypeOf = [self](const ModelIndex& index) { return self->TemplateFor(index); };
            factory.Create = [self](u32 type) -> core::RefPtr<Node>
            {
                auto content = core::MakeRef<TemplateRowContent>(self->MemoryAllocator());
                const ElementSet* elements = self->GetElementSet();
                if (elements == nullptr || type >= self->m_templates.Size())
                    return content;
                MarkupLoader loader(*elements, self->MemoryAllocator());
                loader.SetItemBindings(&content->Bindings());
                if (core::RefPtr<Node> tree = loader.LoadFromString(self->m_templates[type].Markup.AsView()))
                    content->AddChild(tree.Get());
                return content;
            };
            factory.Bind = [self](Node& content, const ModelIndex& index)
            {
                for (const ItemBinding& binding : static_cast<TemplateRowContent&>(content).Bindings())
                {
                    core::String text;
                    for (const MarkupTemplatePart& part : binding.Parts)
                        text.Append(part.IsName ? self->ItemField(index, part.Text.AsView()).AsView() : part.Text.AsView());
                    MarkupLoader::ApplyAttribute(*binding.Target, binding.Attribute.AsView(), text.AsView());
                }
            };
            m_factory = core::Move(factory);
            DropRows();
            RequestLayout();
        }
        // The template an item takes: the one whose type is its row-type-column's text, else the
        // default (the one with no type, else the first).
        [[nodiscard]] u32 TemplateFor(const ModelIndex& index) const
        {
            u32 fallback = 0;
            for (usize t = 0; t < m_templates.Size(); ++t)
                if (m_templates[t].Type.IsEmpty())
                {
                    fallback = static_cast<u32>(t);
                    break;
                }
            if (m_rowTypeColumn.IsEmpty())
                return fallback;
            const core::String field = core::Format(u8"item.{}", m_rowTypeColumn);
            const core::String kind = ItemField(index, field.AsView());
            for (usize t = 0; t < m_templates.Size(); ++t)
                if (!m_templates[t].Type.IsEmpty() && m_templates[t].Type.AsView() == kind.AsView())
                    return static_cast<u32>(t);
            return fallback;
        }
        // A template name's text for an item: `item` (its first column), `item.Column` (a column
        // by name), `index` (its row).
        [[nodiscard]] core::String ItemField(const ModelIndex& index, core::StringView name) const
        {
            if (m_model == nullptr)
                return core::String{};
            if (name == core::StringView(u8"index"))
                return core::Format(u8"{}", index.Row);
            if (name == core::StringView(u8"item"))
                return m_model->Data(index).ToString();
            const core::StringView prefix(u8"item.");
            if (name.Size() <= prefix.Size() || name.SubStr(0, prefix.Size()) != prefix)
                return core::String{};
            const core::StringView column = name.SubStr(prefix.Size(), name.Size() - prefix.Size());
            for (usize c = 0; c < m_model->ColumnCount(); ++c)
                if (m_model->ColumnName(c).AsView() == column)
                    return m_model->Data(m_model->Index(index.Row, static_cast<i32>(c), m_model->ParentIndex(index))).ToString();
            return core::String{};
        }

        // --- Geometry: a list's rows by the heights, a grid's lines by the cell height ---
        [[nodiscard]] i32 GridColumns(f32 width) const
        {
            return m_layout == ItemLayout::Grid ? core::Max(1, static_cast<i32>(width / m_cellSize.x)) : 1;
        }
        [[nodiscard]] i32 Across() const { return GridColumns(GetContentBounds().width); }
        [[nodiscard]] f32 ItemTop(i32 item) const
        {
            if (m_layout == ItemLayout::Grid)
                return static_cast<f32>(item / Across()) * m_cellSize.y;
            return m_heights.Top(static_cast<usize>(item));
        }
        [[nodiscard]] f32 ItemHeight(i32 item) const
        {
            return m_layout == ItemLayout::Grid ? m_cellSize.y : m_heights.At(static_cast<usize>(item));
        }
        [[nodiscard]] f32 ContentHeight() const
        {
            if (m_layout == ItemLayout::Grid)
            {
                const i32 across = Across();
                return static_cast<f32>((static_cast<i32>(ItemCount()) + across - 1) / across) * m_cellSize.y;
            }
            return m_heights.Total();
        }
        void RealizeGrid();

        [[nodiscard]] static bool StylePending(const Node& node)
        {
            if (node.IsStyleDirty())
                return true;
            for (usize i = 0; i < node.ChildCount(); ++i)
                if (StylePending(*node.GetChildAt(i)))
                    return true;
            return false;
        }
        [[nodiscard]] f32 RowEstimate() const noexcept { return m_rowHeight > 0.0f ? m_rowHeight : m_estimate; }
        [[nodiscard]] u32 RowTypeOf(i32 item) const
        {
            return m_factory.TypeOf ? m_factory.TypeOf(ItemToModelIndex(item)) : 0u;
        }

        // The rows in view (and one past each edge) realised, measured and placed; the scroll
        // anchor kept where it was when rows above it measured differently from their estimate.
        void Realize();
        bool TypeAhead(core::StringView typed);
        // A row for `item`: the live one showing its id, else one from its type's pool, else new.
        ItemRow* TakeRow(i32 item, core::Array<core::RefPtr<ItemRow>>& next);
        void ReleaseRow(ItemRow& row)
        {
            if (m_editing && row.m_id == m_editId)
                (void)EndEdit(true); // scrolled away: what was typed is kept
            row.SetDisplayed(false);
            row.m_id = kNoItem;
            row.m_item = -1;
            PoolOf(row.m_type).Rows.PushBack(core::RefPtr<ItemRow>(&row));
        }
        Pool& PoolOf(u32 type)
        {
            for (Pool& pool : m_pools)
                if (pool.Type == type)
                    return pool;
            m_pools.PushBack(Pool{type, {}});
            return m_pools[m_pools.Size() - 1];
        }
        void DropRows()
        {
            ForEachRow([](ItemRow& row) { row.RemoveFromParent(); });
            m_live.Clear();
            m_pools.Clear();
        }

        // --- The scroll anchor: an item and how far into it the top of the view is ---
        void ResetScrollAnchor()
        {
            m_scrollAnchor = 0;
            m_scrollAnchorDelta = 0.0f;
        }
        void UpdateScrollAnchor()
        {
            if (m_layout == ItemLayout::Grid)
                return; // a grid's cells do not change height
            const f32 y = GetScrollOffset().y;
            m_scrollAnchor = static_cast<i32>(m_heights.Find(y));
            m_scrollAnchorDelta = y - m_heights.Top(static_cast<usize>(m_scrollAnchor));
        }
        void ClampScrollAnchor()
        {
            const i32 count = static_cast<i32>(ItemCount());
            if (m_scrollAnchor >= count)
                ResetScrollAnchor();
        }

        // --- Selection ---
        void SelectOnly(i32 item)
        {
            const ItemId id = ItemIdAt(item);
            m_selected.Clear();
            (void)m_selected.Insert(id);
            m_current = id;
            m_anchorSelection = id;
            RefreshSelectionStates();
        }
        void SelectRange(i32 item)
        {
            const i32 anchor = ItemOfId(m_anchorSelection);
            const i32 from = anchor >= 0 ? anchor : item;
            m_selected.Clear();
            for (i32 i = core::Min(from, item); i <= core::Max(from, item); ++i)
                (void)m_selected.Insert(ItemIdAt(i));
            m_current = ItemIdAt(item);
            RefreshSelectionStates();
        }
        void ToggleSelected(i32 item)
        {
            const ItemId id = ItemIdAt(item);
            if (!m_selected.Remove(id))
                (void)m_selected.Insert(id);
            m_current = id;
            m_anchorSelection = id;
            RefreshSelectionStates();
        }
        void PruneSelection()
        {
            core::Array<ItemId> gone;
            for (ItemId id : m_selected)
                if (ItemOfId(id) < 0)
                    gone.PushBack(id);
            for (ItemId id : gone)
                (void)m_selected.Remove(id);
            if (ItemOfId(m_current) < 0)
                m_current = kNoItem;
            if (ItemOfId(m_anchorSelection) < 0)
                m_anchorSelection = kNoItem;
        }
        void RefreshSelectionStates()
        {
            m_selectionChanged.Notify();
            for (const core::RefPtr<ItemRow>& row : m_live)
                row->SetSelectedState(IsIdSelected(row->m_id));
        }
        void NotifySelectionByUser()
        {
            if (m_onSelection)
                m_onSelection(GetSelectedIndex());
            SendEvent(Event(EventType::Changed, this));
        }
        void ActivateItem(i32 item)
        {
            const ModelIndex index = ItemToModelIndex(item);
            if (m_onActivated)
                m_onActivated(index);
            SendEvent(ItemEvent(EventType::ItemActivate, this, item, index));
        }

        // A press on a row: the left button selects (a second press activates), the right one
        // selects for its context menu.
        void RowPressed(ItemRow& row, const MouseEvent& event)
        {
            if (row.m_item < 0)
                return;
            if (event.Button == MouseButton::Left)
            {
                event.Handled = true;
                RequestFocus();
                if (event.ClickCount == 2)
                {
                    ActivateItem(row.m_item);
                    return;
                }
                // A plain press on a row of a multi-selection leaves it (a drag takes it all); the
                // click, if no drag starts, selects the row alone.
                if (m_selectionMode == SelectionMode::Multi && event.Modifiers == 0 && m_selected.Size() > 1 && IsItemSelected(row.m_item))
                {
                    m_deferredItem = row.m_item;
                    m_current = ItemIdAt(row.m_item);
                    return;
                }
                SelectByUser(row.m_item, event.Modifiers);
            }
        }

        IModel* m_model = nullptr; // non-owning (unless it is m_ownModel, or m_listModel's)
        RefPtr<ListModel> m_listModel; // a script's model it shows (E16)
        core::UniquePtr<StringListModel> m_ownModel; // markup's `items`
        RowFactory m_factory;
        Array<RowTemplate> m_templates;
        core::String m_rowTypeColumn;
        mutable Observable m_selectionChanged; // what bindings reading the selection follow
        core::Array<ItemId> m_dragIds;        // the rows of the drag going from here
        i32 m_deferredItem = -1;              // a pressed row of a multi-selection, selected alone on click
        bool m_dropOver = false;              // a drop would land here now
        i32 m_dropItem = -1;
        DropPlace m_dropPlace = DropPlace::After;
        ModelDrop m_lastDrop;                 // the drop the last query found
        RowHeights m_heights;
        core::Array<core::RefPtr<ItemRow>> m_live; // realised, in item order
        // Accessibility (E17b): each item's key, and back; this view's key; what each node said.
        core::HashMap<ItemId, u32> m_accessKeys;
        core::HashMap<u32, ItemId> m_accessItems;
        u32 m_nextAccessKey = 1;
        u32 m_accessViewKey = 0;
        core::HashMap<u64, u64> m_accessSent;
        static constexpr usize kAccessSelectedCap = 50; // a selection of thousands: its first fifty
        core::Array<Pool> m_pools;                 // released rows, by type
        core::HashSet<ItemId> m_selected;
        ItemId m_current = kNoItem;         // where the keyboard is
        ItemId m_anchorSelection = kNoItem; // where a Shift range starts
        SelectionMode m_selectionMode = SelectionMode::Single;
        core::Function<void(ModelIndex)> m_onSelection;
        core::Function<void(ModelIndex)> m_onActivated;
        f32 m_rowHeight = 24.0f;
        f32 m_estimate = 24.0f;
        ItemLayout m_layout = ItemLayout::List;
        core::Float2 m_cellSize{96.0f, 96.0f};
        i32 m_scrollAnchor = 0;
        f32 m_scrollAnchorDelta = 0.0f;
        bool m_realizing = false;
        // Type-ahead.
        core::String m_typed;
        f32 m_typedAt = -10.0f;
        // Editing.
        core::RefPtr<TextField> m_editor;
        bool m_editing = false;
        ItemId m_editId = kNoItem;
        i32 m_editColumn = 0;
        core::Function<bool(const ModelIndex&)> m_onEditBegin;
        core::Function<bool(const ModelIndex&, core::StringView)> m_onEditCommit;
        core::Function<void(const ModelIndex&)> m_onEditCancel;
    };

    // === ItemRow ===

    inline ItemRow::ItemRow(ItemView& view) : m_view(view)
    {
        SetTag(view.RowTag());
    }

    inline void ItemRow::OnMouseDown(const MouseEvent& event) { m_view.RowPressed(*this, event); }
    inline void ItemRow::OnMouseClick(const MouseEvent& event) { m_view.RowClicked(*this, event); }

    inline void ItemRow::OnDraw(DrawContext& ctx, const Rect& localBounds)
    {
        UIWidget::OnDraw(ctx, localBounds);
        if (m_selected)
            m_view.GetPartStyle(u8"selection").Draw(ctx, GetLocalBounds(), FilledBox(Color{0.18f, 0.37f, 0.62f, 1.0f}));
    }

    // Its content fills it; an editor lies over it where the view says.
    inline void ItemRow::OnLayout()
    {
        const Rect box = GetContentBounds();
        if (m_content)
            m_content->Arrange(box);
        TextField* editor = m_view.m_editor.Get();
        if (editor != nullptr && editor->GetParent() == this && editor->IsDisplayed())
            editor->Arrange(m_view.EditRect(*this, m_view.m_editColumn));
    }

    // === ItemView ===

    inline ItemRow* ItemView::TakeRow(i32 item, core::Array<core::RefPtr<ItemRow>>& next)
    {
        const ItemId id = ItemIdAt(item);
        const u32 type = RowTypeOf(item);
        ItemRow* row = nullptr;
        for (const core::RefPtr<ItemRow>& live : m_live)
            if (!live->m_taken && live->m_id == id && live->m_type == type)
            {
                row = live.Get();
                break;
            }
        if (row == nullptr)
        {
            Pool& pool = PoolOf(type);
            if (pool.Rows.Size() != 0)
            {
                row = pool.Rows[pool.Rows.Size() - 1].Get();
                next.PushBack(pool.Rows[pool.Rows.Size() - 1]);
                pool.Rows.RemoveAt(pool.Rows.Size() - 1);
            }
            else
            {
                auto made = core::MakeRef<ItemRow>(MemoryAllocator(), *this);
                made->m_type = type;
                made->m_content = m_factory.Create ? m_factory.Create(type) : CreateContent(type);
                if (made->m_content)
                    made->AddChild(made->m_content.Get());
                ShareTextStyle(*made);
                AddChild(made.Get());
                row = made.Get();
                next.PushBack(made);
            }
            row->m_dirty = true;
            row->m_id = id;
        }
        else
            next.PushBack(core::RefPtr<ItemRow>(row));
        row->m_taken = true;
        row->m_item = item;
        if (row->m_dirty)
        {
            const ModelIndex index = ItemToModelIndex(item);
            if (row->m_content)
            {
                if (m_factory.Bind)
                    m_factory.Bind(*row->m_content, index);
                else
                    BindContent(*row->m_content, item, index);
            }
            row->m_dirty = false;
        }
        row->SetDisplayed(true);
        row->SetSelectedState(IsIdSelected(id));
        return row;
    }

    inline void ItemView::Realize()
    {
        if (m_realizing)
            return;
        if (m_layout == ItemLayout::Grid)
        {
            RealizeGrid();
            return;
        }
        m_realizing = true;
        const Rect box = GetContentBounds();
        const f32 inset = ContentTopInset();
        const f32 width = RowWidth(box.width);
        const usize count = ItemCount();
        if (m_heights.Size() != count)
            m_heights.Reset(count, RowEstimate());
        const bool measured = m_rowHeight <= 0.0f;
        const LayoutConstraints across{core::Float2{width, 0.0f}, core::Float2{width, kUnbounded}, core::Float2{width, -1.0f}};

        // Realise from the anchor; a row above it measuring differently moves the anchor's
        // offset, which is put back, and the rows are taken again (a few passes settle it).
        for (int pass = 0; pass < 3; ++pass)
        {
            const f32 top = GetScrollOffset().y;
            const f32 bottom = top + core::Max(0.0f, box.height - inset);
            core::Array<core::RefPtr<ItemRow>> next;
            usize first = count > 0 ? m_heights.Find(top) : 0;
            if (first > 0)
                --first; // one above the view
            // The rows leaving the view go back to their pools first, so those coming in take
            // them rather than new ones (judged by the heights as they stand).
            {
                usize last = first;
                while (last < count && m_heights.Top(last) < bottom)
                    ++last;
                // (By the ids in range, not each row's lookup: an id's row is a search in a list.)
                core::Array<ItemId> inRange;
                for (usize i = first; i <= core::Min(last, count - (count > 0 ? 1 : 0)) && count > 0; ++i)
                    inRange.PushBack(ItemIdAt(static_cast<i32>(i)));
                core::Array<core::RefPtr<ItemRow>> kept;
                for (const core::RefPtr<ItemRow>& row : m_live)
                {
                    bool stays = false;
                    for (ItemId id : inRange)
                        stays = stays || id == row->m_id;
                    if (stays)
                        kept.PushBack(row);
                    else
                        ReleaseRow(*row);
                }
                m_live = core::Move(kept);
            }
            for (const core::RefPtr<ItemRow>& row : m_live)
                row->m_taken = false;
            if (count > 0)
            {
                bool pastEnd = false;
                for (usize i = first; i < count && !pastEnd; ++i)
                {
                    pastEnd = m_heights.Top(i) >= bottom; // one below the view
                    ItemRow* row = TakeRow(static_cast<i32>(i), next);
                    // A row not yet styled (just made, or its template's attributes just
                    // written) is measured again once it is. Unstyled it often measures nothing
                    // (no font yet); then it keeps its estimate, since rows of no height all start
                    // at the top and the view would start at the last of them.
                    if (measured && !m_heights.IsMeasured(i))
                    {
                        const bool pending = StylePending(*row);
                        const f32 height = row->Measure(across).y;
                        if (!pending || height > 0.0f)
                            (void)m_heights.Set(i, height, !pending);
                    }
                }
            }
            for (const core::RefPtr<ItemRow>& row : m_live)
                if (!row->m_taken)
                    ReleaseRow(*row);
            m_live = core::Move(next);
            for (const core::RefPtr<ItemRow>& row : m_live)
                row->m_taken = false;

            SetScrollExtent(core::Float2{width, inset + m_heights.Total()});
            if (IsFlinging() || IsSmoothScrolling() || m_scrollAnchor >= static_cast<i32>(count))
                break;
            const f32 want = m_heights.Top(static_cast<usize>(m_scrollAnchor)) + m_scrollAnchorDelta;
            if (core::Abs(want - GetScrollOffset().y) < 0.5f || GetScrollRange().y < want - 0.5f)
                break;
            ApplyScrollOffset(core::Float2{GetScrollOffset().x, want});
        }

        for (const core::RefPtr<ItemRow>& row : m_live)
        {
            const usize i = static_cast<usize>(row->m_item);
            row->Arrange(Rect{RowLeft(box, width), box.y + inset + m_heights.Top(i), width, m_heights.At(i)});
        }
        m_realizing = false;
    }

    // A grid's cells in view (and a line past each edge), at the cell size, stretched across.
    inline void ItemView::RealizeGrid()
    {
        m_realizing = true;
        const Rect box = GetContentBounds();
        const f32 inset = ContentTopInset();
        const i32 count = static_cast<i32>(ItemCount());
        const i32 across = GridColumns(box.width);
        const f32 cellW = box.width / static_cast<f32>(across);
        const f32 top = GetScrollOffset().y;
        const f32 bottom = top + core::Max(0.0f, box.height - inset);
        const i32 firstLine = core::Max(0, static_cast<i32>(top / m_cellSize.y) - 1);
        const i32 lastLine = static_cast<i32>(bottom / m_cellSize.y) + 1;
        const i32 first = core::Min(count, firstLine * across);
        const i32 last = core::Min(count, (lastLine + 1) * across);

        core::Array<ItemId> inRange;
        for (i32 i = first; i < last; ++i)
            inRange.PushBack(ItemIdAt(i));
        core::Array<core::RefPtr<ItemRow>> kept;
        for (const core::RefPtr<ItemRow>& row : m_live)
        {
            bool stays = false;
            for (ItemId id : inRange)
                stays = stays || id == row->m_id;
            if (stays)
                kept.PushBack(row);
            else
                ReleaseRow(*row);
        }
        m_live = core::Move(kept);
        for (const core::RefPtr<ItemRow>& row : m_live)
            row->m_taken = false;
        core::Array<core::RefPtr<ItemRow>> next;
        for (i32 i = first; i < last; ++i)
            (void)TakeRow(i, next);
        m_live = core::Move(next);
        for (const core::RefPtr<ItemRow>& row : m_live)
        {
            row->m_taken = false;
            const i32 i = row->m_item;
            row->Arrange(CellBounds(box, i, across, cellW, box.y + inset + static_cast<f32>(i / across) * m_cellSize.y, m_cellSize.y));
        }
        SetScrollExtent(core::Float2{box.width, inset + ContentHeight()});
        m_realizing = false;
    }

    inline void ItemView::SelectByUser(i32 item, u32 modifiers)
    {
        if (item < 0 || item >= static_cast<i32>(ItemCount()))
            return;
        const bool ctrl = (modifiers & KeyModCtrl) != 0;
        const bool shift = (modifiers & KeyModShift) != 0;
        if (m_selectionMode == SelectionMode::Multi && shift && m_anchorSelection != kNoItem)
            SelectRange(item);
        else if (m_selectionMode == SelectionMode::Multi && ctrl)
            ToggleSelected(item);
        else
            SelectOnly(item);
        NotifySelectionByUser();
    }

    inline void ItemView::OnKeyDown(const KeyEvent& event)
    {
        const KeyCode key = static_cast<KeyCode>(event.KeyCode);
        if (m_editing && event.Target == m_editor.Get())
        {
            if (key == KeyCode::Escape)
            {
                (void)EndEdit(false);
                event.Handled = true;
            }
            return;
        }
        if (event.Target != this)
            return;
        if (OnExtraKey(key, event.Modifiers))
        {
            event.Handled = true;
            return;
        }
        const i32 items = static_cast<i32>(ItemCount());
        if (items == 0)
            return;
        const bool shift = (event.Modifiers & KeyModShift) != 0;
        const bool ctrl = (event.Modifiers & KeyModCtrl) != 0;
        if (key == KeyCode::F2 && event.Modifiers == 0)
        {
            if (GetCurrentItem() >= 0 && BeginEdit(GetCurrentItem()))
                event.Handled = true;
            return;
        }
        if (key == KeyCode::A && ctrl && m_selectionMode == SelectionMode::Multi)
        {
            SelectAll();
            NotifySelectionByUser();
            event.Handled = true;
            return;
        }
        if (key == KeyCode::Space && ctrl && m_selectionMode == SelectionMode::Multi && GetCurrentItem() >= 0)
        {
            ToggleSelected(GetCurrentItem());
            NotifySelectionByUser();
            event.Handled = true;
            return;
        }
        // A key that types is its type-ahead's (E12): the text it types arrives next, through the
        // keyboard layout and an IME, and no binding of the bare key takes it.
        if ((event.Modifiers & ~static_cast<u32>(KeyModShift)) == 0 && KeyTypesText(key) && ItemCount() > 0)
        {
            event.Handled = true;
            return;
        }
        const i32 current = GetCurrentItem();
        // A grid's line is a step of `across` items; a page the lines (rows) that fit.
        const i32 across = Across();
        const f32 rowH = core::Max(1.0f, ItemHeight(core::Max(0, current)));
        const i32 page = core::Max(1, static_cast<i32>((GetContentBounds().height - ContentTopInset()) / rowH) - 1) * across;
        const bool grid = m_layout == ItemLayout::Grid;
        i32 target = current;
        switch (key)
        {
        case KeyCode::Up: target = current < 0 ? 0 : current - across >= 0 ? current - across : current; break;
        case KeyCode::Down: target = current < 0 ? 0 : current + across < items ? current + across : current; break;
        case KeyCode::Left:
        case KeyCode::Right:
            // Along a grid's rows as they run: toward the inline end is the next item.
            if (!grid)
                return;
            target = InlineStep(key) < 0 ? (current <= 0 ? 0 : current - 1) : (current < 0 ? 0 : core::Min(items - 1, current + 1));
            break;
        case KeyCode::Home: target = 0; break;
        case KeyCode::End: target = items - 1; break;
        case KeyCode::PageUp: target = core::Max(0, core::Max(0, current) - page); break;
        case KeyCode::PageDown: target = core::Min(items - 1, core::Max(0, current) + page); break;
        default: return;
        }
        // An arrow at the view's edge is given back (focus moves on).
        const bool arrow = key == KeyCode::Up || key == KeyCode::Down || key == KeyCode::Left || key == KeyCode::Right;
        if (arrow && target == current && IsItemSelected(current))
            return;
        event.Handled = true;
        const EventDispatcher* dispatcher = GetEventDispatcher();
        if (dispatcher != nullptr && dispatcher->IsKeyboardDrag())
        {
            m_current = ItemIdAt(target); // dragging from the keys: the keyboard moves, the selection stays
            Invalidate();
        }
        else if (ctrl && m_selectionMode == SelectionMode::Multi)
            m_current = ItemIdAt(target); // Ctrl moves the keyboard alone (Ctrl+Space picks)
        else if (shift && m_selectionMode == SelectionMode::Multi)
        {
            SelectRange(target);
            NotifySelectionByUser();
        }
        else
        {
            SelectOnly(target);
            NotifySelectionByUser();
        }
        ScrollToItem(target);
    }

    // Typing jumps to the next item whose text starts with what was typed (within a second of
    // the last text; one character again cycles through the items starting with it). The text is
    // typed text (E12): it follows the keyboard layout and an IME. False for no text or no items.
    inline bool ItemView::TypeAhead(core::StringView typed)
    {
        if (typed.Size() == 0 || ItemCount() == 0)
            return false;
        const EventDispatcher* d = GetEventDispatcher();
        const f32 now = d != nullptr ? d->GetTime() : 0.0f;
        if (now - m_typedAt > 1.0f)
            m_typed = core::String{};
        m_typedAt = now;
        m_typed.Append(typed);
        // One character typed again: the next item starting with it.
        core::StringView prefix = m_typed.AsView();
        usize firstEnd = 0;
        (void)core::DecodeUtf8(prefix, firstEnd);
        const core::StringView first = prefix.SubStr(0, firstEnd);
        bool repeated = prefix.Size() > firstEnd;
        for (usize at = firstEnd; at < prefix.Size() && repeated; at += firstEnd)
            repeated = prefix.Size() - at >= firstEnd && prefix.SubStr(at, firstEnd) == first;
        if (repeated)
            prefix = first;
        const i32 items = static_cast<i32>(ItemCount());
        const i32 current = GetCurrentItem();
        const i32 start = (prefix.Size() == firstEnd || current < 0) ? current + 1 : current; // one character: past the current
        for (i32 n = 0; n < items; ++n)
        {
            const i32 item = ((start + n) % items + items) % items;
            if (StartsWithIgnoringCase(TypeAheadText(item).AsView(), prefix))
            {
                SelectOnly(item);
                NotifySelectionByUser();
                ScrollToItem(item);
                break;
            }
        }
        return true;
    }

    inline bool ItemView::BeginEdit(i32 item, i32 column)
    {
        if (m_model == nullptr || item < 0 || item >= static_cast<i32>(ItemCount()))
            return false;
        ModelIndex index = ItemToModelIndex(item);
        index.Column = column;
        if (!m_model->IsEditable(index) || (m_onEditBegin && !m_onEditBegin(index)))
            return false;
        if (m_editing && !EndEdit(true))
            return false;
        ScrollToItem(item);
        Realize();
        ItemRow* row = RowForItem(item);
        if (row == nullptr)
            return false;
        if (!m_editor)
        {
            m_editor = core::MakeRef<TextField>(MemoryAllocator());
            m_editor->AddClass(core::StringView(u8"editor"));
            ItemView* self = this;
            m_editor->SetOnSubmit([self](core::StringView) { (void)self->EndEdit(true); });
            (void)m_editor->AddEventListener(EventType::FocusLost, [self](const Event&)
            {
                // Focus went elsewhere: committed if it may be, else put back.
                if (self->m_editing && !self->EndEdit(true))
                    (void)self->EndEdit(false);
            });
        }
        m_editing = true;
        m_editId = ItemIdAt(item);
        m_editColumn = column;
        row->AddChild(m_editor.Get());
        ShareTextStyle(*m_editor);
        m_editor->RemoveClass(core::StringView(u8"invalid"));
        m_editor->SetText(m_model->Data(index).ToString().AsView());
        m_editor->SetDisplayed(true);
        m_editor->GetModel().SelectAll();
        m_editor->Arrange(EditRect(*row, column));
        m_editor->RequestFocus();
        return true;
    }

    inline bool ItemView::EndEdit(bool commit)
    {
        if (!m_editing)
            return true;
        const i32 item = ItemOfId(m_editId);
        ModelIndex index = item >= 0 ? ItemToModelIndex(item) : ModelIndex{};
        index.Column = m_editColumn;
        if (commit && index.IsValid())
        {
            const core::String text(m_editor->GetText());
            const bool taken = (!m_onEditCommit || m_onEditCommit(index, text.AsView())) && m_model->SetData(index, Variant(text.AsView()));
            if (!taken)
            {
                m_editor->AddClass(core::StringView(u8"invalid"));
                return false;
            }
        }
        else if (!commit && m_onEditCancel && index.IsValid())
            m_onEditCancel(index);
        m_editing = false;
        m_editId = kNoItem;
        const bool hadFocus = m_editor->IsFocused();
        m_editor->SetDisplayed(false);
        if (hadFocus)
            RequestFocus(); // the view keeps the focus the editor had
        return true;
    }

    inline ModelDrop ItemView::DropAt(const DropQuery& query, DropEffect& effect, core::String& reason)
    {
        ModelDrop drop;
        drop.Payload = &query.Payload;
        drop.Effect = query.Preferred;
        // From an item view: its dragged rows and its model.
        if (const ItemView* source = core::Cast<ItemView>(Node::FromHandle(query.Payload.Value)))
        {
            drop.Ids = source->m_dragIds;
            drop.Source = source->m_model;
        }
        // From the keys: the current row (onto it where the model takes that, else after it).
        if (query.FromKeyboard)
        {
            const i32 current = GetCurrentItem();
            drop.Index = current >= 0 ? ItemToModelIndex(current) : ModelIndex{};
            drop.Place = current >= 0 ? DropPlace::On : DropPlace::After;
            effect = m_model->CanDrop(drop, reason);
            if (effect == DropEffect::None && reason.IsEmpty() && current >= 0)
            {
                drop.Place = DropPlace::After;
                effect = m_model->CanDrop(drop, reason);
            }
            return drop;
        }
        const i32 item = ItemAt(ConvertToWorldSpace(query.Local));
        if (item < 0)
        {
            drop.Index = ModelIndex{}; // past the rows: the end
            drop.Place = DropPlace::After;
            effect = m_model->CanDrop(drop, reason);
            return drop;
        }
        drop.Index = ItemToModelIndex(item);
        // Where in the row: quarters at the edges are before and after, the middle onto it (a grid
        // reads across); a place the model does not take falls back to the halves.
        const Rect b = ItemBounds(item);
        const core::Float2 content{query.Local.x + GetScrollOffset().x, query.Local.y + GetScrollOffset().y};
        const bool across = m_layout == ItemLayout::Grid;
        f32 at = across ? (content.x - b.x) / core::Max(1.0f, b.width) : (content.y - b.y) / core::Max(1.0f, b.height);
        if (across && IsRightToLeft())
            at = 1.0f - at; // before is the inline start, the right
        drop.Place = at < 0.25f ? DropPlace::Before : at > 0.75f ? DropPlace::After : DropPlace::On;
        effect = m_model->CanDrop(drop, reason);
        if (effect == DropEffect::None && reason.IsEmpty())
        {
            drop.Place = drop.Place == DropPlace::On ? (at < 0.5f ? DropPlace::Before : DropPlace::After) : DropPlace::On;
            effect = m_model->CanDrop(drop, reason);
        }
        return drop;
    }

    inline void ItemView::OnDragQuery(DropQuery& query)
    {
        if (m_model == nullptr)
            return;
        DropEffect effect = DropEffect::None;
        core::String reason;
        const ModelDrop drop = DropAt(query, effect, reason);
        if (effect == DropEffect::None)
        {
            SetDropIndicator(false, -1, DropPlace::After);
            if (!reason.IsEmpty())
                query.Refuse(reason.AsView());
            return;
        }
        query.Accept(effect);
        query.Effect = effect; // the model's (a list takes text as a copy)
        query.Reason = reason;
        const i32 item = drop.Index.IsValid() ? ItemOfId(m_model->IdOf(drop.Index)) : -1;
        query.Place = static_cast<i32>(drop.Place);
        SetDropIndicator(true, item, drop.Place);
        m_lastDrop = drop; // what a drop now does (the release asks once more, here)
    }

    // The drop as the last query found it (the release asked again where it landed).
    inline void ItemView::OnDrop(const DragEvent& event)
    {
        if (m_model == nullptr || !m_dropOver)
            return;
        ModelDrop drop = m_lastDrop;
        drop.Effect = event.Effect;
        SetDropIndicator(false, -1, DropPlace::After);
        (void)m_model->Drop(drop);
    }

    // The insertion line before or after a row (across a grid's cell edge), or an outline round
    // the row a drop goes onto.
    inline void ItemView::OnDrawAbove(DrawContext& ctx)
    {
        if (!m_dropOver)
            return;
        const PartStyle& part = GetPartStyle(u8"drop-indicator");
        const Color color = part.HasBackground ? part.Box.BackgroundColor : Color{0.31f, 0.61f, 1.0f, 1.0f};
        const Rect box = GetContentBounds();
        Rect row;
        if (m_dropItem < 0)
        {
            const usize count = ItemCount();
            row = count > 0 ? ItemBounds(static_cast<i32>(count) - 1) : Rect{box.x, box.y + ContentTopInset(), box.width, 0.0f};
        }
        else
            row = ItemBounds(m_dropItem);
        row.x -= GetScrollOffset().x;
        row.y -= GetScrollOffset().y;
        ctx.PushClip(box);
        const bool across = m_layout == ItemLayout::Grid;
        if (m_dropPlace == DropPlace::On && m_dropItem >= 0)
        {
            vg::PathBuilder pb;
            pb.MoveTo(row.x + 1.0f, row.y + 1.0f);
            pb.LineTo(row.x + row.width - 1.0f, row.y + 1.0f);
            pb.LineTo(row.x + row.width - 1.0f, row.y + row.height - 1.0f);
            pb.LineTo(row.x + 1.0f, row.y + row.height - 1.0f);
            pb.Close();
            ctx.VG().StrokePath(pb.ToPath(), color, vg::StrokeStyle(2.0f));
        }
        else
        {
            const bool before = m_dropPlace == DropPlace::Before && m_dropItem >= 0;
            const bool left = before != IsRightToLeft(); // before is the inline start
            const Rect line = across ? Rect{left ? row.x - 1.0f : row.x + row.width - 1.0f, row.y, 2.0f, row.height}
                                     : Rect{row.x, (before ? row.y : row.y + row.height) - 1.0f, row.width, 2.0f};
            ctx.VG().FillRect(core::Rectangle{line.x, line.y, line.width, line.height}, color);
        }
        ctx.PopClip();
    }

    RTTI_DEFINE_OBJECT(TemplateRowContent, "rtti::gui")
    RTTI_DEFINE_OBJECT(ItemRow, "rtti::gui")
}
