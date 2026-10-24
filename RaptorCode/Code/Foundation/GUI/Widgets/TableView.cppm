// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :table_view partition
//
// TableView: a virtualised table over a model (eepp's UITableView in role, its column model the
// fullest of the surveyed ones). ItemView realises its rows; a row's content is one cell
// (`tablecell`) per column. Its header (`tableheader`) shows the column names and stays at the top
// while the rows scroll under it, and across with them. Columns are pixels, a percentage of the
// view's width, or auto (an equal share of what is left, no narrower than a minimum); columns
// wider than the view scroll it across. Dragging a header cell's right edge resizes its column (to
// pixels from then on). A click on a header cell reports its column, or with nothing listening
// sorts by it where the model can; the sorted column's cell shows which way. In markup,
// `columns="Name|Score"` and `<TableItem cells="Ada|42"/>` children make a model of its own
// (behind a sorting proxy, numbers kept as numbers so they sort by value).

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui:table_view;

import foundation.core; // RefPtr, MakeRef, Array, Function, Move, Max
import foundation.vg;   // PathBuilder (the sort indicator)
import :rect;
import :event;
import :node;
import :label;
import :text; // TextHAlign
import :ui_widget;
import :model_index;
import :model;
import :item_view;
import :table_model;
import :sorting_proxy_model;
import :variant;
import :list_box; // SplitItems
import :draw_context;
import :layout_style;     // LayoutLength, Overflow
import :event_dispatcher; // SuppressClick (a resize is no click)

using namespace foundation::core;
namespace core = foundation::core;
namespace vg = foundation::vg;

export namespace foundation::gui
{
    class TableView;

    // A column's header cell: a click reports its column; a drag from its right edge resizes the
    // column; the sorted column's cell shows which way (a triangle, up ascending).
    class TableHeaderCell : public Label
    {
        RTTI_OBJECT(TableHeaderCell, Label)
    public:
        explicit TableHeaderCell(TableView& table) : m_table(table)
        {
            SetTag(core::StringView(u8"tableheadercell"));
            StyleWriteScope defaults(*this); // its own values, which a sheet returns to
            SetTextAlignment(TextHAlign::Start, TextVAlign::Middle);
            SetPadding(Thickness{8.0f, 0.0f, 8.0f, 0.0f});
        }
        void SetColumn(usize column) noexcept { m_column = column; }
        [[nodiscard]] usize GetColumn() const noexcept { return m_column; }
        [[nodiscard]] bool IsResizing() const noexcept { return m_resizing; }

        // A press on its edge, its inline end, resizes its column (E7): a drag from what holds it is
        // not offered.
        [[nodiscard]] bool OwnsPressDrag(core::Float2 local) const override { return OnGripAt(local.x); }

    protected:
        void OnMouseDown(const MouseEvent& event) override;
        void OnMouseMove(const MouseEvent& event) override;
        void OnMouseUp(const MouseEvent&) override { m_resizing = false; }
        void OnPointerCancel(const MouseEvent&) override { m_resizing = false; }
        void OnMouseClick(const MouseEvent& event) override;
        void OnDraw(DrawContext& ctx, const Rect& localBounds) override;

    private:
        static constexpr f32 kGrip = 5.0f; // how near its inline-end edge a press resizes
        [[nodiscard]] bool OnGripAt(f32 x) const { return IsRightToLeft() ? x <= kGrip : x >= GetSize().x - kGrip; }
        [[nodiscard]] bool OnGrip(core::Float2 world) const { return OnGripAt(ConvertToNodeSpace(world).x); }

        TableView& m_table; // the view whose header holds it
        usize m_column = 0;
        bool m_resizing = false;
        f32 m_pressX = 0.0f;
        f32 m_startWidth = 0.0f;
    };

    // A table row's content: one cell per column, placed by the table's widths.
    class TableRowContent : public UIWidget
    {
        RTTI_OBJECT(TableRowContent, UIWidget)
    public:
        explicit TableRowContent(const TableView& table) : m_table(table) { SetTag(core::StringView(u8"tablerowcontent")); }

        [[nodiscard]] usize CellCount() const noexcept { return m_cells.Size(); }
        [[nodiscard]] Label* CellAt(usize i) const { return i < m_cells.Size() ? m_cells[i].Get() : nullptr; }
        /// As many cells as `count`.
        void EnsureCells(usize count)
        {
            while (m_cells.Size() < count)
            {
                auto cell = core::MakeRef<Label>(MemoryAllocator());
                cell->SetTag(core::StringView(u8"tablecell")); // a row's, not a sheet's generic label
                StyleWriteScope defaults(*cell);
                cell->SetTextAlignment(TextHAlign::Start, TextVAlign::Middle);
                cell->SetPadding(Thickness{8.0f, 0.0f, 8.0f, 0.0f});
                cell->SetHitTestVisible(false); // a press on it is the row's
                ShareTextStyle(*cell);
                AddChild(cell.Get());
                m_cells.PushBack(core::Move(cell));
            }
            for (usize i = 0; i < m_cells.Size(); ++i)
                m_cells[i]->SetDisplayed(i < count);
        }
        [[nodiscard]] core::Float2 MeasureContent(core::Float2 available) override;

    protected:
        void OnLayout() override;
        void OnTextStyleChange() override
        {
            for (const core::RefPtr<Label>& cell : m_cells)
                ShareTextStyle(*cell);
        }

    private:
        const TableView& m_table; // the view whose row holds it
        Array<core::RefPtr<Label>> m_cells;
    };

    /// A row of a table written in markup: its cells as text, '|' between them.
    class TableItem : public UIWidget
    {
        RTTI_OBJECT(TableItem, UIWidget)
    public:
        TableItem()
        {
            SetTag(core::StringView(u8"tableitem"));
            SetDisplayed(false); // data, not drawn
        }
        bool SetMarkupAttribute(core::StringView name, core::StringView value) override
        {
            if (name != core::StringView(u8"cells"))
                return UIWidget::SetMarkupAttribute(name, value);
            m_cells = core::String(value);
            return true;
        }
        [[nodiscard]] core::String GetCells() const { return m_cells; }
        /// Its cells, '|' between them; set after the table took it in (a script's `add` then
        /// `cells`), the table's row follows.
        void SetCells(const core::String& cells)
        {
            m_cells = cells;
            if (m_onCellsChanged)
                m_onCellsChanged();
        }
        /// The table that took it in hears when its cells change.
        void SetOnCellsChanged(core::Function<void()> callback) { m_onCellsChanged = core::Move(callback); }

    private:
        core::String m_cells;
        core::Function<void()> m_onCellsChanged;
    };

    class TableView : public ItemView
    {
        RTTI_OBJECT(TableView, ItemView)
    public:
        TableView()
        {
            SetTag(core::StringView(u8"tableview"));
            m_header = core::MakeRef<UIWidget>(MemoryAllocator());
            m_header->SetTag(core::StringView(u8"tableheader"));
            m_header->SetBox(FilledBox(m_headerColor)); // its own face, which a sheet's replaces
            AddChild(m_header.Get());
            StyleWriteScope defaults(*this); // its own values, which a sheet returns to
            SetTextColor(Color{0.86f, 0.89f, 0.94f, 1.0f});
            EditLayoutStyle([](LayoutStyle& s) { s.OverflowX = Overflow::Auto; }); // columns past its width
        }

        // Its own model goes before the view's base would let go of it: let go first.
        ~TableView() override { SetModel(nullptr); }

        void SetHeaderHeight(f32 height)
        {
            m_headerHeight = core::Max(0.0f, height);
            RequestLayout();
        }
        /// A column's width: pixels, a percentage of the view's width, or auto.
        void SetColumnWidth(usize column, LayoutLength width)
        {
            while (m_columnWidths.Size() <= column)
                m_columnWidths.PushBack(LayoutLength{});
            m_columnWidths[column] = width;
            RequestLayout();
        }
        /// Every column's width as text, one per column (`120px 30% auto`; a bare number is
        /// pixels): markup's `column-widths`.
        void SetColumnWidthsText(const core::String& text)
        {
            m_columnWidths.Clear();
            core::StringView rest = core::Trim(text.AsView());
            while (rest.Size() != 0)
            {
                usize end = 0;
                while (end < rest.Size() && rest[end] != u8' ')
                    ++end;
                const core::StringView word = rest.SubStr(0, end);
                rest = core::Trim(rest.SubStr(end, rest.Size() - end));
                LayoutLength width;
                if (word.Size() > 1 && word[word.Size() - 1] == u8'%')
                    width = LayoutLength::Percent(static_cast<f32>(core::ParseFloat(word.SubStr(0, word.Size() - 1)).ValueOr(0.0)));
                else if (word != core::StringView(u8"auto"))
                {
                    const core::StringView digits = word.Size() > 2 && word.SubStr(word.Size() - 2, 2) == core::StringView(u8"px") ? word.SubStr(0, word.Size() - 2) : word;
                    width = LayoutLength::Px(static_cast<f32>(core::ParseFloat(digits).ValueOr(0.0)));
                }
                m_columnWidths.PushBack(width);
            }
            RequestLayout();
        }
        [[nodiscard]] core::String GetColumnWidthsText() const
        {
            core::String text;
            for (usize c = 0; c < m_columnWidths.Size(); ++c)
            {
                if (c > 0)
                    text.Append(core::StringView(u8" "));
                const LayoutLength& w = m_columnWidths[c];
                const core::String written = w.Kind == LayoutLengthKind::Px        ? core::Format(u8"{}px", w.Value)
                                             : w.Kind == LayoutLengthKind::Percent ? core::Format(u8"{}%", w.Value)
                                             : w.Kind == LayoutLengthKind::Calc    ? core::Format(u8"calc({}px + {}%)", w.Value, w.PercentPart)
                                                                                   : core::String(core::StringView(u8"auto"));
                text.Append(written.AsView());
            }
            return text;
        }
        /// The narrowest a column gets (an auto one squeezed, one dragged).
        void SetMinColumnWidth(f32 width)
        {
            m_minColumnWidth = core::Max(1.0f, width);
            RequestLayout();
        }
        [[nodiscard]] f32 GetMinColumnWidth() const noexcept { return m_minColumnWidth; }
        /// Its columns' total width in the last layout (past the view's: it scrolls across).
        [[nodiscard]] f32 GetColumnsWidth() const
        {
            f32 total = 0.0f;
            for (f32 w : m_widths)
                total += w;
            return total;
        }
        /// The sort indicator: which column shows which way (a header click that sorts sets it).
        void SetSortIndicator(i32 column, SortOrder order)
        {
            m_sortColumn = column;
            m_sortOrder = order;
            for (const core::RefPtr<TableHeaderCell>& cell : m_headerCells)
                cell->Invalidate();
        }
        [[nodiscard]] i32 GetSortColumn() const noexcept { return m_sortColumn; }
        [[nodiscard]] SortOrder GetSortOrder() const noexcept { return m_sortOrder; }
        /// A column's width in the last layout.
        [[nodiscard]] f32 GetColumnWidth(usize column) const { return column < m_widths.Size() ? m_widths[column] : 0.0f; }
        [[nodiscard]] usize GetColumnCount() const { return GetModel() != nullptr ? GetModel()->ColumnCount() : 0; }

        // === Markup: a model of its own ===
        /// Its columns' names, '|' between them (markup's `columns`).
        void SetColumnsText(const core::String& text)
        {
            EnsureOwnModel();
            Array<core::String> columns;
            for (core::StringView name : SplitItems(text.AsView()))
                columns.PushBack(core::String(name));
            m_ownModel->SetColumns(core::Move(columns));
        }
        [[nodiscard]] core::String GetColumnsText() const
        {
            Array<core::String> columns;
            for (usize c = 0; c < GetColumnCount(); ++c)
                columns.PushBack(GetModel()->ColumnName(c));
            return JoinItems(columns);
        }
        /// Its own model's cells may be edited in place (F2).
        void SetEditable(bool editable)
        {
            EnsureOwnModel();
            m_ownModel->SetEditable(editable);
            m_editable = editable;
        }
        [[nodiscard]] bool IsEditable() const noexcept { return m_editable; }
        /// Markup's children are its rows (TableItems).
        [[nodiscard]] Node* GetChildHost() override
        {
            if (!m_markupHost)
            {
                TableView* self = this;
                m_markupHost = core::MakeRef<MarkupChildHost>(MemoryAllocator(), [self](Node& host)
                {
                    self->EnsureOwnModel();
                    while (host.ChildCount() != 0)
                    {
                        core::RefPtr<Node> child(host.GetChildAt(0));
                        host.RemoveChild(child.Get());
                        TableItem* item = core::Cast<TableItem>(child.Get());
                        if (item == nullptr)
                            continue;
                        // Its row, and the item kept: a script that added it sets its cells after,
                        // through the handle it holds, and the row follows.
                        const usize row = self->m_ownModel->RowCount(ModelIndex{});
                        self->m_ownModel->AddRow(ParseCells(item->GetCells()));
                        item->SetOnCellsChanged([self, item, row]()
                        {
                            const Array<Variant> cells = ParseCells(item->GetCells());
                            for (usize c = 0; c < cells.Size(); ++c)
                                self->m_ownModel->SetCell(row, c, cells[c]);
                        });
                        self->m_rowItems.PushBack(core::RefPtr<TableItem>(item));
                    }
                });
            }
            return m_markupHost.Get();
        }

        // Header clicks (a column); with none set, a click sorts where the model can.
        void SetOnColumnHeaderClicked(core::Function<void(usize)> callback) { m_onHeaderClicked = core::Move(callback); }
        [[nodiscard]] Node* GetHeader() const noexcept { return m_header.Get(); }

    protected:
        // Its header cells write in its font (their colour is their own: tableheadercell { color }).
        void OnTextStyleChange() override
        {
            for (const core::RefPtr<TableHeaderCell>& h : m_headerCells)
                ShareTextStyle(*h, false);
            ItemView::OnTextStyleChange();
        }
        [[nodiscard]] core::StringView RowTag() const override { return core::StringView(u8"tablerow"); }
        [[nodiscard]] f32 ContentTopInset() const override { return m_headerHeight; }
        void OnModelChanged() override { SyncHeader(); }
        // The columns' widths for this layout, from the content box's width: a row is as wide as
        // the view, or as the columns when they are wider.
        [[nodiscard]] f32 RowWidth(f32 width) const override
        {
            ComputeColumnWidths(width);
            return core::Max(width, GetColumnsWidth());
        }

        [[nodiscard]] core::RefPtr<Node> CreateContent(u32) override { return core::MakeRef<TableRowContent>(MemoryAllocator(), *this); }
        void BindContent(Node& content, i32 item, const ModelIndex&) override
        {
            TableRowContent& row = static_cast<TableRowContent&>(content);
            const usize columns = GetColumnCount();
            row.EnsureCells(columns);
            for (usize c = 0; c < columns; ++c)
                row.CellAt(c)->SetText(GetModel()->Data(GetModel()->Index(item, static_cast<i32>(c))).ToString().AsView());
        }
        [[nodiscard]] Rect EditRect(const ItemRow& row, i32 column) const override
        {
            const Rect box = row.GetContentBounds();
            f32 x = box.x;
            for (i32 c = 0; c < column && static_cast<usize>(c) < m_widths.Size(); ++c)
                x += m_widths[static_cast<usize>(c)];
            return MirroredIn(Rect{x, box.y, GetColumnWidth(static_cast<usize>(core::Max(0, column))), box.height}, box, IsRightToLeft());
        }

        // The header lies at the top of the view, over the rows scrolled under it.
        void OnLayoutDecorations() override
        {
            // Over the rows, from where they start (their columns from the inline start).
            const Rect box = GetContentBounds();
            m_header->SetVisible(m_headerHeight > 0.0f);
            const f32 width = core::Max(box.width, GetColumnsWidth());
            m_header->Arrange(Rect{RowLeft(box, width), box.y + GetScrollOffset().y, width, m_headerHeight});
            const Rect across{0.0f, 0.0f, width, m_headerHeight};
            const bool rtl = IsRightToLeft();
            f32 x = 0.0f;
            for (usize c = 0; c < m_headerCells.Size(); ++c)
            {
                const f32 w = GetColumnWidth(c);
                m_headerCells[c]->Arrange(MirroredIn(Rect{x, 0.0f, w, m_headerHeight}, across, rtl));
                x += w;
            }
            if (GetChildIndex(m_header.Get()) + 1 != ChildCount())
                m_header->ToFront(); // drawn, and pressed, over the rows
        }

    private:
        friend class TableRowContent;
        friend class TableHeaderCell;

        // The header's cells follow the columns (cells kept while the columns stay, so a press on
        // one that sorts does not free the cell under the pointer).
        void SyncHeader()
        {
            const usize columns = GetColumnCount();
            while (m_headerCells.Size() > columns)
            {
                m_headerCells[m_headerCells.Size() - 1]->RemoveFromParent();
                m_headerCells.RemoveAt(m_headerCells.Size() - 1);
            }
            while (m_headerCells.Size() < columns)
            {
                auto cell = core::MakeRef<TableHeaderCell>(MemoryAllocator(), *this);
                cell->SetColumn(m_headerCells.Size());
                ShareTextStyle(*cell, false);
                {
                    StyleWriteScope defaults(*cell);
                    cell->SetTextColor(m_headerTextColor);
                }
                m_header->AddChild(cell.Get());
                m_headerCells.PushBack(core::Move(cell));
            }
            for (usize c = 0; c < columns; ++c)
                m_headerCells[c]->SetText(GetModel()->ColumnName(c).AsView());
        }
        void HeaderClicked(usize column)
        {
            if (m_onHeaderClicked)
            {
                m_onHeaderClicked(column);
                return;
            }
            // Nothing listening: sort by it where the model can (a new column ascending, the
            // same one turning over).
            const SortOrder order = m_sortColumn == static_cast<i32>(column) && m_sortOrder == SortOrder::Ascending ? SortOrder::Descending : SortOrder::Ascending;
            if (GetModel() != nullptr && GetModel()->Sort(column, order))
                SetSortIndicator(static_cast<i32>(column), order);
        }

        // Pixels and percentages as they say, auto columns an equal share of what is left; none
        // narrower than the minimum (so the columns may come out wider than the view).
        void ComputeColumnWidths(f32 bodyWidth) const
        {
            const usize columns = GetColumnCount();
            const Array<f32> before = m_widths;
            m_widths.Clear();
            f32 given = 0.0f;
            usize autoCount = 0;
            for (usize c = 0; c < columns; ++c)
            {
                const LayoutLength w = c < m_columnWidths.Size() ? m_columnWidths[c] : LayoutLength{};
                const Optional<f32> px = w.Resolve(bodyWidth);
                if (px.HasValue())
                    given += core::Max(m_minColumnWidth, px.Value());
                else
                    ++autoCount;
            }
            const f32 share = autoCount > 0 ? (bodyWidth - given) / static_cast<f32>(autoCount) : 0.0f;
            for (usize c = 0; c < columns; ++c)
            {
                const LayoutLength w = c < m_columnWidths.Size() ? m_columnWidths[c] : LayoutLength{};
                // Read as the given widths are above: ValueOr on this temporary goes unemitted in an
                // optimized clang build, which then fails to link.
                const core::Optional<f32> px = w.Resolve(bodyWidth);
                m_widths.PushBack(core::Max(m_minColumnWidth, px.HasValue() ? px.Value() : share));
            }
            // Widths changed with the row's own width the same (one column narrower, an auto one
            // wider): the rows' cells are placed again, as the header's are.
            bool changed = before.Size() != m_widths.Size();
            for (usize c = 0; c < m_widths.Size() && !changed; ++c)
                changed = before[c] != m_widths[c];
            if (changed)
                for (const core::RefPtr<ItemRow>& row : LiveRows())
                    if (Node* content = row->GetContent())
                        content->RequestLayout();
        }
        void EnsureOwnModel()
        {
            if (m_ownModel)
                return;
            m_ownModel = core::MakeUnique<TableModel>(MemoryAllocator());
            m_ownProxy = core::MakeUnique<SortingProxyModel>(MemoryAllocator(), m_ownModel.Get());
            SetModel(m_ownProxy.Get());
        }
        // A row's cells from text: a number stays a number (it sorts by value).
        [[nodiscard]] static Array<Variant> ParseCells(const core::String& text)
        {
            Array<Variant> cells;
            for (core::StringView cell : SplitItems(text.AsView()))
            {
                bool integer = cell.Size() != 0;
                for (usize i = 0; i < cell.Size(); ++i)
                    integer = integer && ((cell[i] >= u8'0' && cell[i] <= u8'9') || (i == 0 && cell[i] == u8'-' && cell.Size() > 1));
                const Optional<f64> number = core::ParseFloat(cell);
                if (integer)
                    cells.PushBack(Variant(static_cast<i64>(number.ValueOr(0.0))));
                else if (number.HasValue() && cell.Size() != 0)
                    cells.PushBack(Variant(number.Value()));
                else
                    cells.PushBack(Variant(cell));
            }
            return cells;
        }
        // A drag of a header cell's edge: the column takes that many pixels.
        void ResizeColumn(usize column, f32 width) { SetColumnWidth(column, LayoutLength::Px(core::Max(m_minColumnWidth, width))); }

        core::RefPtr<UIWidget> m_header;
        Array<core::RefPtr<TableHeaderCell>> m_headerCells;
        Array<LayoutLength> m_columnWidths; // auto when unset
        mutable Array<f32> m_widths;   // resolved for the current layout (RowWidth works them out)
        core::Function<void(usize)> m_onHeaderClicked;
        i32 m_sortColumn = -1;
        SortOrder m_sortOrder = SortOrder::None;
        f32 m_headerHeight = 26.0f;
        f32 m_minColumnWidth = 40.0f;
        core::UniquePtr<TableModel> m_ownModel;         // markup's rows
        Array<core::RefPtr<TableItem>> m_rowItems;      // the items they came from, each its row's
        core::UniquePtr<SortingProxyModel> m_ownProxy; // over it, so its header sorts
        core::RefPtr<Node> m_markupHost;               // where markup's rows land, then taken in
        bool m_editable = false;
        Color m_headerColor{0.20f, 0.22f, 0.27f, 1.0f};
        Color m_headerTextColor{0.86f, 0.89f, 0.94f, 1.0f};
    };

    inline void TableHeaderCell::OnMouseDown(const MouseEvent& event)
    {
        if (event.Button != MouseButton::Left || !OnGrip(event.Position))
            return;
        // On its edge: a resize, not a click (no sort follows).
        event.Handled = true;
        m_resizing = true;
        m_pressX = event.Position.x;
        m_startWidth = m_table.GetColumnWidth(m_column);
        if (EventDispatcher* d = GetEventDispatcher())
            d->SuppressClick();
    }

    inline void TableHeaderCell::OnMouseMove(const MouseEvent& event)
    {
        if (m_resizing)
        {
            // Pulled toward the inline end, it widens.
            const f32 dx = event.Position.x - m_pressX;
            m_table.ResizeColumn(m_column, m_startWidth + (IsRightToLeft() ? -dx : dx));
            return;
        }
        SetCursor(OnGrip(event.Position) ? Cursor::EwResize : Cursor::Auto); // the edge says it resizes
    }

    inline void TableHeaderCell::OnMouseClick(const MouseEvent& event)
    {
        event.Handled = true;
        m_table.HeaderClicked(m_column);
    }

    inline void TableHeaderCell::OnDraw(DrawContext& ctx, const Rect& localBounds)
    {
        Label::OnDraw(ctx, localBounds);
        if (m_table.GetSortColumn() != static_cast<i32>(m_column) || m_table.GetSortOrder() == SortOrder::None)
            return;
        // A small triangle at its inline end, up for ascending, down for descending.
        const Rect box = GetContentBounds();
        const f32 s = 4.0f;
        const f32 cx = MirroredX(box.x + box.width - s, box, IsRightToLeft());
        const f32 cy = box.y + box.height * 0.5f;
        const f32 dir = m_table.GetSortOrder() == SortOrder::Ascending ? -1.0f : 1.0f;
        vg::PathBuilder pb;
        pb.MoveTo(cx - s, cy - dir * s * 0.5f);
        pb.LineTo(cx + s, cy - dir * s * 0.5f);
        pb.LineTo(cx, cy + dir * s * 0.5f);
        pb.Close();
        ctx.VG().FillPath(pb.ToPath(), GetTextColor());
    }

    inline core::Float2 TableRowContent::MeasureContent(core::Float2 available)
    {
        // As tall as its tallest cell at its column's width.
        f32 height = 0.0f;
        for (usize c = 0; c < m_cells.Size(); ++c)
            if (m_cells[c]->IsDisplayed())
            {
                const f32 w = m_table.GetColumnWidth(c);
                height = core::Max(height, m_cells[c]->Measure(LayoutConstraints{core::Float2{w, 0.0f}, core::Float2{w, kUnbounded}, core::Float2{w, -1.0f}, true, false}).y);
            }
        return core::Float2{available.x, height};
    }

    inline void TableRowContent::OnLayout()
    {
        // Its columns from the inline start.
        const Rect box = GetContentBounds();
        const bool rtl = IsRightToLeft();
        f32 x = box.x;
        for (usize c = 0; c < m_cells.Size(); ++c)
        {
            if (!m_cells[c]->IsDisplayed())
                continue;
            const f32 w = m_table.GetColumnWidth(c);
            m_cells[c]->Arrange(MirroredIn(Rect{x, box.y, w, box.height}, box, rtl));
            x += w;
        }
    }

    RTTI_DEFINE_OBJECT(TableHeaderCell, "rtti::gui")
    RTTI_DEFINE_OBJECT(TableRowContent, "rtti::gui")
}
