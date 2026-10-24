// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - :property_grid partition
//
// The property grid (T1 of Specs/gui-lab-evolution-3.md): a source's properties as rows, a label
// beside an editor, on the core's item view, so only the rows in view exist and each kind of row
// has a pool (a category's header, a group's, one per editor). What the grid keeps is outside the
// rows (zed's way): the properties read once into a tree when the source says they changed, which
// paths are folded (categories start open, groups closed), the search, and one label split for
// every row, dragged at any row's boundary. A search keeps what matches by its shown name or its
// path, with what holds it, opened while it searches; the folding is left as it was. The wheel
// scrolls the grid and never changes a value (ezEngine's rule). An edit is the source's gesture;
// while it goes, its row is not rebound from the values it previews.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui.toolkit:property_grid;

import foundation.core;
import foundation.gui;
import :property_source;
import :property_editor;
import :curve_editors;    // the default editors

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    class PropertyGrid;

    /// One row of a grid: a category's header, or a property (a group, or a value with its editor).
    struct PropertyRow
    {
        core::String Path; ///< a category's: `#` and its name
        PropertyInfo Info; ///< a category's: its name as Name
        bool Category = false;
        bool HasChildren = false;
        bool Open = false;
        i32 Depth = 0;
        u32 Type = 0; ///< its pool: an editor's type, or a header's
        ItemId Id = kNoItem;
        bool Element = false; ///< an element of a list: its index, and what its list allows
        usize Index = 0;
        u8 ListOps = 0;
        usize Count = 0; ///< an element's: how many its list shows
        usize Node = ~usize{0}; ///< the property it shows, in the grid's tree
    };

    namespace detail
    {
        // The grid's rows as the item view's flat model.
        class PropertyRowModel : public IModel
        {
        public:
            explicit PropertyRowModel(core::IAllocator& allocator) : m_rows(allocator), m_rowOfId(allocator) {}

            void SetRows(core::Array<PropertyRow> rows)
            {
                m_rows = core::Move(rows);
                m_rowOfId.Clear();
                for (usize i = 0; i < m_rows.Size(); ++i)
                    m_rowOfId.InsertOrAssign(m_rows[i].Id, static_cast<i32>(i));
                NotifyReset();
            }
            [[nodiscard]] const core::Array<PropertyRow>& Rows() const noexcept { return m_rows; }
            void ValuesChanged()
            {
                if (m_rows.Size() != 0)
                    NotifyRowsChanged(ModelIndex{}, 0, static_cast<i32>(m_rows.Size()));
            }

            [[nodiscard]] usize RowCount(const ModelIndex& parent = {}) const override { return parent.IsValid() ? 0 : m_rows.Size(); }
            [[nodiscard]] usize ColumnCount() const override { return 1; }
            [[nodiscard]] Variant Data(const ModelIndex& index, ModelRole = ModelRole::Display) const override
            {
                return IsValidIndex(index) ? Variant(m_rows[static_cast<usize>(index.Row)].Info.ShownName()) : Variant{};
            }
            [[nodiscard]] ItemId IdOf(const ModelIndex& index) const override
            {
                return IsValidIndex(index) ? m_rows[static_cast<usize>(index.Row)].Id : kNoItem;
            }
            [[nodiscard]] ModelIndex IndexOfId(ItemId id) const override
            {
                const i32* row = m_rowOfId.Find(id);
                return row != nullptr ? MakeModelIndex(*row) : ModelIndex{};
            }

        private:
            core::Array<PropertyRow> m_rows;
            core::HashMap<ItemId, i32> m_rowOfId;
        };
    }

    /// The thin strip at a row's label boundary: dragged, it moves every row's split.
    class PropertySplitHandle : public UIWidget
    {
        RTTI_OBJECT(PropertySplitHandle, UIWidget)
    public:
        explicit PropertySplitHandle(PropertyGrid& grid) : m_grid(grid)
        {
            SetTag(core::StringView(u8"propertysplit"));
            SetCursor(Cursor::EwResize);
        }

    protected:
        void OnMouseDown(const MouseEvent& event) override;
        void OnMouseMove(const MouseEvent& event) override;
        void OnMouseUp(const MouseEvent& event) override
        {
            (void)event;
            m_dragging = false;
        }
        void OnPointerCancel(const MouseEvent&) override { m_dragging = false; }

    private:
        PropertyGrid& m_grid;
        bool m_dragging = false;
    };

    /// A list element's grip: dragged, it moves the element to another place in its list.
    class PropertyGrip : public UIWidget
    {
        RTTI_OBJECT(PropertyGrip, UIWidget)
    public:
        explicit PropertyGrip(PropertyGrid& grid) : m_grid(grid)
        {
            SetTag(core::StringView(u8"propertygrip"));
            SetCursor(Cursor::Grab);
        }
        void SetPath(core::StringView path) { m_path = core::String(path); }

    protected:
        void OnMouseDown(const MouseEvent& event) override;
        void OnMouseMove(const MouseEvent& event) override;
        void OnMouseUp(const MouseEvent& event) override;
        void OnPointerCancel(const MouseEvent& event) override;
        void OnDraw(DrawContext& ctx, const Rect& localBounds) override
        {
            // Two columns of three dots.
            const PartStyle& dots = GetPartStyle(u8"dots");
            Color color = dots.HasBackground ? dots.Box.BackgroundColor : Color{0.55f, 0.58f, 0.62f, 1.0f};
            color.a *= dots.Opacity;
            const f32 cx = localBounds.x + localBounds.width * 0.5f, cy = localBounds.y + localBounds.height * 0.5f;
            for (i32 col = 0; col < 2; ++col)
                for (i32 row = -1; row <= 1; ++row)
                    ctx.VG().FillRect(Rectangle{cx - 3.0f + static_cast<f32>(col) * 4.0f, cy - 1.0f + static_cast<f32>(row) * 4.0f, 2.0f, 2.0f}, color);
        }
        void CollectStyleParts(core::Array<core::StringView>& out) const override { out.PushBack(core::StringView(u8"dots")); }

    private:
        PropertyGrid& m_grid;
        core::String m_path;
        bool m_dragging = false;
    };

    /// A category's header: its chevron and its name across the row.
    class PropertyCategoryContent : public UIWidget
    {
        RTTI_OBJECT(PropertyCategoryContent, UIWidget)
    public:
        explicit PropertyCategoryContent(PropertyGrid& grid);
        void Show(const PropertyRow& row)
        {
            m_path = row.Path;
            m_arrow->SetExpanded(row.Open);
            m_label->SetText(row.Info.ShownName());
        }
        [[nodiscard]] core::StringView GetPath() const noexcept { return m_path.AsView(); }
        [[nodiscard]] Label* GetLabel() const noexcept { return m_label.Get(); }

    protected:
        void OnMouseClick(const MouseEvent& event) override;
        void OnLayout() override
        {
            const Rect box = GetContentBounds();
            const bool rtl = IsRightToLeft();
            m_arrow->Arrange(MirroredIn(Rect{box.x, box.y, kArrow, box.height}, box, rtl));
            m_label->Arrange(MirroredIn(Rect{box.x + kArrow + 2.0f, box.y, core::Max(0.0f, box.width - kArrow - 2.0f), box.height}, box, rtl));
        }
        void OnTextStyleChange() override { ShareTextStyle(*m_label); }

    private:
        static constexpr f32 kArrow = 16.0f;
        PropertyGrid& m_grid;
        core::RefPtr<TreeArrow> m_arrow;
        core::RefPtr<Label> m_label;
        core::String m_path;
    };

    /// A property's row: indented by its depth, a group's chevron, its name (its description the
    /// tooltip), the split, and its editor (none for a group).
    class PropertyRowContent : public UIWidget
    {
        RTTI_OBJECT(PropertyRowContent, UIWidget)
    public:
        PropertyRowContent(PropertyGrid& grid, core::RefPtr<PropertyEditor> editor);
        void Show(const PropertyRow& row);
        [[nodiscard]] core::StringView GetPath() const noexcept { return m_path.AsView(); }
        [[nodiscard]] PropertyEditor* GetEditor() const noexcept { return m_editor.Get(); }
        [[nodiscard]] Label* GetLabel() const noexcept { return m_label.Get(); }
        [[nodiscard]] PropertySplitHandle* GetSplitHandle() const noexcept { return m_split.Get(); }
        [[nodiscard]] PropertyGrip* GetGrip() const noexcept { return m_grip.Get(); }
        /// Marked: an object's value here, or under here, differs from its default.
        void SetChanged(bool changed)
        {
            if (changed == m_changed)
                return;
            m_changed = changed;
            if (changed)
                AddClass(core::StringView(u8"changed"));
            else
                RemoveClass(core::StringView(u8"changed"));
            Invalidate();
        }
        [[nodiscard]] bool IsChanged() const noexcept { return m_changed; }
        void CollectStyleParts(core::Array<core::StringView>& out) const override { out.PushBack(core::StringView(u8"marker")); }
        [[nodiscard]] core::StringView GetTooltipText() const override { return m_description.AsView(); }

    protected:
        void OnLayout() override;
        // The changed marker: a bar at the row's inline start, `::marker`'s colour.
        void OnDraw(DrawContext& ctx, const Rect& localBounds) override
        {
            UIWidget::OnDraw(ctx, localBounds);
            if (!m_changed)
                return;
            const PartStyle& marker = GetPartStyle(u8"marker");
            Color color = marker.HasBackground ? marker.Box.BackgroundColor : Color{0.31f, 0.61f, 1.0f, 1.0f};
            color.a *= marker.Opacity;
            const Rect bar = MirroredIn(Rect{localBounds.x, localBounds.y + 2.0f, 3.0f, core::Max(0.0f, localBounds.height - 4.0f)}, localBounds, IsRightToLeft());
            ctx.VG().FillRect(bar.ToRectangle(), color);
        }
        void OnTextStyleChange() override
        {
            ShareTextStyle(*m_label);
            if (m_editor)
                ShareTextStyle(*m_editor);
        }

    private:
        static constexpr f32 kArrow = 16.0f;
        static constexpr f32 kGrip = 12.0f;
        PropertyGrid& m_grid;
        core::RefPtr<TreeArrow> m_arrow;
        core::RefPtr<Label> m_label;
        core::RefPtr<PropertySplitHandle> m_split;
        core::RefPtr<PropertyGrip> m_grip;
        core::RefPtr<PropertyEditor> m_editor;
        core::String m_path;
        core::String m_description;
        i32 m_depth = 0;
        bool m_movable = false; // an element its list lets move: its grip shows
        bool m_changed = false;
    };

    class PropertyGrid : public ItemView, public IPropertySourceClient, public IPropertyEditHost
    {
        RTTI_OBJECT(PropertyGrid, ItemView)
    public:
        static constexpr u32 kCategoryRow = 0x80000000u;
        static constexpr u32 kGroupRow = 0x80000001u;

        PropertyGrid();
        ~PropertyGrid() override
        {
            SetModel(nullptr);
            if (m_source != nullptr && m_source->GetClient() == this)
                m_source->SetClient(nullptr);
        }

        /// The source it shows (not owned; it outlives the grid or is set to null first).
        void SetSource(IPropertySource* source)
        {
            if (m_source == source)
                return;
            if (m_source != nullptr)
            {
                EndOpenEdit();
                if (m_source->GetClient() == this)
                    m_source->SetClient(nullptr);
            }
            m_source = source;
            if (m_source != nullptr)
                m_source->SetClient(this);
            ReadProperties();
        }
        [[nodiscard]] IPropertySource* GetSource() const noexcept { return m_source; }

        /// The editors it chooses from: an application registers its own here, then Refresh.
        [[nodiscard]] PropertyEditorRegistry& GetEditors() noexcept { return m_editors; }
        /// Reads the properties again (an editor registered, a source's change it did not say).
        void Refresh()
        {
            if (m_editorGeneration != m_editors.GetGeneration())
            {
                m_editorGeneration = m_editors.GetGeneration();
                SetRowFactory(MakeFactory()); // the pools start again
            }
            ReadProperties();
        }

        // === Folding ===
        /// Whether `path` (a group's, or a category's `#Name`) is open: categories start open,
        /// groups closed.
        [[nodiscard]] bool IsOpen(core::StringView path) const
        {
            const bool byDefault = path.Size() != 0 && path[0] == u8'#';
            return byDefault != m_toggled.Contains(core::String(path));
        }
        void SetOpen(core::StringView path, bool open)
        {
            if (IsOpen(path) == open)
                return;
            const core::String key(path);
            if (m_toggled.Contains(key))
                (void)m_toggled.Remove(key);
            else
                (void)m_toggled.Insert(key);
            Fold();
        }
        void ToggleOpen(core::StringView path) { SetOpen(path, !IsOpen(path)); }

        // === Search ===
        /// Shows only what matches `filter` by its shown name or its path (letters in either case
        /// alike), with what holds it; empty shows everything.
        void SetFilter(core::StringView filter)
        {
            if (m_filter.AsView() == filter)
                return;
            m_filter = core::String(filter);
            Fold();
        }
        [[nodiscard]] core::StringView GetFilter() const noexcept { return m_filter.AsView(); }

        // === The label split ===
        /// The labels' share of a row's width (`label-ratio`), kept between 0.1 and 0.9.
        void SetLabelRatio(f32 ratio)
        {
            ratio = core::Clamp(ratio, 0.1f, 0.9f);
            if (ratio == m_labelRatio)
                return;
            m_labelRatio = ratio;
            ForEachRow([](ItemRow& row)
            {
                if (Node* content = row.GetContent())
                    content->RequestLayout();
            });
            Invalidate();
        }
        [[nodiscard]] f32 GetLabelRatio() const noexcept { return m_labelRatio; }
        /// A nested property's indent per level (`indent-width`).
        void SetIndentWidth(f32 width)
        {
            m_indentWidth = core::Max(0.0f, width);
            ItemsChanged();
        }
        [[nodiscard]] f32 GetIndentWidth() const noexcept { return m_indentWidth; }

        // === Lists ===
        /// Changes the list `path` through the source (an open edit ends first); an insert opens it.
        bool EditPropertyList(core::StringView path, const ListEdit& edit) override
        {
            if (m_source == nullptr)
                return false;
            EndOpenEdit();
            const core::String list(path);
            if (!m_source->EditList(list.AsView(), edit))
                return false;
            if (edit.Kind == ListEdit::Op::Insert)
                SetOpen(list.AsView(), true);
            return true;
        }
        /// A grip's drag: the element at `path` picked up, moved over the rows, let go (or given up).
        void BeginReorder(core::StringView path);
        void MoveReorder(core::Float2 screen);
        void EndReorder(bool drop);
        /// The place the element would go now (its index after the move), or -1.
        [[nodiscard]] i32 GetReorderTarget() const noexcept { return m_reorderTo; }
        /// The row's menu, while it is open.
        [[nodiscard]] Menu* GetRowMenu() const noexcept { return m_menu && m_menu->IsOpen() ? m_menu.Get() : nullptr; }
        /// Opens the menu of the row `item` at `position` (in the root's space); false when it has none.
        bool OpenRowMenu(i32 item, core::Float2 position);

        // === The rows ===
        [[nodiscard]] usize GetRowCount() const noexcept { return m_rows.Rows().Size(); }
        [[nodiscard]] const PropertyRow* GetRow(i32 item) const
        {
            return item >= 0 && static_cast<usize>(item) < m_rows.Rows().Size() ? &m_rows.Rows()[static_cast<usize>(item)] : nullptr;
        }
        /// The row of `path` shown now, or -1.
        [[nodiscard]] i32 FindRow(core::StringView path) const
        {
            for (usize i = 0; i < m_rows.Rows().Size(); ++i)
                if (m_rows.Rows()[i].Path.AsView() == path)
                    return static_cast<i32>(i);
            return -1;
        }
        /// The editor showing `path` now (its row realised), or null.
        [[nodiscard]] PropertyEditor* FindEditor(core::StringView path) const
        {
            const i32 item = FindRow(path);
            ItemRow* row = item >= 0 ? RowForItem(item) : nullptr;
            PropertyRowContent* content = row != nullptr ? core::Cast<PropertyRowContent>(row->GetContent()) : nullptr;
            return content != nullptr ? content->GetEditor() : nullptr;
        }
        // === Defaults ===
        /// Whether `path`'s row shows: an object differs from its default there, or under there.
        [[nodiscard]] bool IsRowChanged(core::StringView path) const
        {
            const PropertyRow* row = GetRow(FindRow(path));
            return row != nullptr && row->Node < m_nodes.Size() && IsChanged(row->Node);
        }
        /// Puts each object's default back at `path` and under it, through the source.
        bool RevertProperty(core::StringView path)
        {
            if (m_source == nullptr)
                return false;
            EndOpenEdit();
            const core::String at(path);
            return m_source->Revert(at.AsView());
        }

        // === Copying ===
        /// Copies `path` (and what is under it) to the clipboard through the source; false when
        /// the source cannot.
        bool CopyProperty(core::StringView path)
        {
            EventDispatcher* dispatcher = GetEventDispatcher();
            IClipboard* clipboard = dispatcher != nullptr ? dispatcher->GetClipboard() : nullptr;
            if (m_source == nullptr || clipboard == nullptr)
                return false;
            const core::String text = m_source->CopyValue(path);
            if (text.Size() == 0)
                return false;
            clipboard->SetText(text.AsView());
            return true;
        }
        /// Pastes the clipboard's text into `path` through the source; refused, the reason goes to
        /// SetOnMessage's callback.
        bool PasteProperty(core::StringView path)
        {
            EventDispatcher* dispatcher = GetEventDispatcher();
            IClipboard* clipboard = dispatcher != nullptr ? dispatcher->GetClipboard() : nullptr;
            if (m_source == nullptr || clipboard == nullptr || !clipboard->HasText())
                return false;
            EndOpenEdit();
            const core::String at(path);
            const core::String text = clipboard->GetText();
            core::String reason;
            if (m_source->PasteValue(at.AsView(), text.AsView(), reason))
                return true;
            if (m_onMessage)
                m_onMessage(reason.Size() != 0 ? reason.AsView() : core::StringView(u8"Cannot paste that here"));
            return false;
        }
        /// Told what the grid has to say: why a paste was refused (for a status bar).
        void SetOnMessage(core::Function<void(core::StringView)> onMessage) { m_onMessage = core::Move(onMessage); }

        /// The path an edit is open on (empty: none).
        [[nodiscard]] core::StringView GetEditPath() const noexcept { return m_editPath.AsView(); }

        // === IPropertyEditHost's reads ===
        void GetChildProperties(core::StringView path, core::Array<PropertyInfo>& out) const override
        {
            if (m_source != nullptr)
                m_source->GetProperties(path, out);
        }
        [[nodiscard]] PropertyValue ReadPropertyValue(core::StringView path, PropertyKind kind) const override
        {
            return m_source != nullptr ? foundation::gui::ReadPropertyValue(*m_source, path, kind) : PropertyValue{};
        }

        // === IPropertySourceClient ===
        void OnPropertiesChanged() override { ReadProperties(); }
        void OnValuesChanged() override { m_rows.ValuesChanged(); }

        // === IPropertyEditHost ===
        void BeginPropertyEdit(core::StringView path) override
        {
            if (m_source == nullptr)
                return;
            if (m_editPath.Size() != 0 && m_editPath.AsView() != path)
                EndOpenEdit();
            if (m_editPath.AsView() == path)
                return;
            m_editPath = core::String(path);
            m_source->BeginEdit(path);
        }
        void PreviewPropertyEdit(core::StringView path, const PropertyWrite& write) override
        {
            if (m_source != nullptr && m_editPath.AsView() == path)
                m_source->PreviewEdit(path, write);
        }
        void CommitPropertyEdit(core::StringView path, const PropertyWrite& write) override
        {
            if (m_source == nullptr || m_editPath.AsView() != path)
                return;
            m_editPath.Clear();
            m_source->CommitEdit(path, write);
            m_rows.ValuesChanged(); // its own row too, now the gesture is over
        }
        void CancelPropertyEdit(core::StringView path) override
        {
            if (m_source == nullptr || m_editPath.AsView() != path)
                return;
            m_editPath.Clear();
            m_source->CancelEdit(path);
            m_rows.ValuesChanged();
        }

    protected:
        [[nodiscard]] core::RefPtr<Node> CreateContent(u32) override { return {}; }
        void BindContent(Node&, i32, const ModelIndex&) override {}
        [[nodiscard]] core::StringView RowTag() const override { return core::StringView(u8"propertyrow"); }
        void OnContextMenu(const MouseEvent& event) override
        {
            ItemView::OnContextMenu(event); // the row selected
            const i32 item = ItemAt(event.Position);
            Node* top = GetRootNode();
            if (item >= 0 && top != nullptr && OpenRowMenu(item, top->ConvertToNodeSpace(event.Position)))
                event.Handled = true;
        }
        void OnDrawAbove(DrawContext& ctx) override;
        // Right opens a category or a group, Left closes it (mirrored right to left).
        bool OnExtraKey(KeyCode key, u32 modifiers) override
        {
            if (modifiers == KeyModCtrl && (key == KeyCode::C || key == KeyCode::V))
            {
                const PropertyRow* current = GetRow(GetCurrentItem());
                if (current == nullptr || current->Category)
                    return false;
                const core::String path = current->Path;
                return key == KeyCode::C ? CopyProperty(path.AsView()) : PasteProperty(path.AsView());
            }
            if (modifiers != 0 || (key != KeyCode::Left && key != KeyCode::Right))
                return false;
            const PropertyRow* row = GetRow(GetCurrentItem());
            if (row == nullptr || !(row->Category || row->HasChildren))
                return false;
            const bool open = (key == KeyCode::Right) != IsRightToLeft();
            SetOpen(row->Path.AsView(), open);
            return true;
        }

    private:
        friend class PropertyRowContent;
        friend class PropertyCategoryContent;

        // The properties as read from the source: a tree, each node's children by index.
        struct PropertyNode
        {
            core::String Path;
            PropertyInfo Info;
            core::Array<usize> Children;
        };

        RowFactory MakeFactory();
        void ReadProperties();
        void ReadChildren(core::StringView parent, core::Array<usize>& into, usize depth);
        void Fold();
        bool Matches(const PropertyNode& node) const;
        bool SubtreeMatches(usize node) const;
        bool IsChanged(usize node) const;
        void AddRows(core::Array<PropertyRow>& rows, usize node, i32 depth, bool filtered, const PropertyNode* parent = nullptr) const;
        void BindRow(Node& content, const ModelIndex& index);
        // An edit is open on `path` or on a part of it (a Float3's field).
        [[nodiscard]] bool IsUnderEdit(core::StringView path) const
        {
            const core::StringView edit = m_editPath.AsView();
            if (edit.Size() == 0 || edit.Size() < path.Size() || edit.SubStr(0, path.Size()) != path)
                return false;
            return edit.Size() == path.Size() || edit[path.Size()] == u8'.';
        }
        void EndOpenEdit()
        {
            if (m_editPath.Size() == 0 || m_source == nullptr)
                return;
            const core::String path = core::Move(m_editPath);
            m_editPath.Clear();
            m_source->CancelEdit(path.AsView());
        }

        IPropertySource* m_source = nullptr; // non-owning
        detail::PropertyRowModel m_rows;
        PropertyEditorRegistry m_editors;
        u32 m_editorGeneration = 0;
        core::Array<PropertyNode> m_nodes;
        core::Array<usize> m_top;
        core::HashSet<core::String> m_toggled; // paths folded unlike their default
        core::String m_filter;
        core::String m_editPath;
        core::RefPtr<Menu> m_menu;
        core::Function<void(core::StringView)> m_onMessage;
        // A grip's drag: the list, the element's index, where it would go, and the line's row.
        core::String m_reorderList;
        i32 m_reorderFrom = -1;
        i32 m_reorderTo = -1;
        i32 m_reorderLine = -1;
        bool m_reorderAfter = false;
        f32 m_labelRatio = 0.4f;
        f32 m_indentWidth = 12.0f;
    };
}

namespace foundation::gui
{
    // === Contents ===

    inline void PropertySplitHandle::OnMouseDown(const MouseEvent& event)
    {
        if (event.Button != MouseButton::Left)
            return;
        event.Handled = true;
        m_dragging = true;
    }
    inline void PropertySplitHandle::OnMouseMove(const MouseEvent& event)
    {
        if (!m_dragging)
            return;
        // The pointer's place across the grid's rows, from their inline start.
        const Rect rows = m_grid.GetContentBounds();
        const core::Float2 at = m_grid.ConvertToNodeSpace(event.Position); // events come in screen space
        f32 x = at.x - rows.x;
        if (m_grid.IsRightToLeft())
            x = rows.width - x;
        if (rows.width > 0.0f)
            m_grid.SetLabelRatio(x / rows.width);
    }

    inline PropertyCategoryContent::PropertyCategoryContent(PropertyGrid& grid) : m_grid(grid)
    {
        SetTag(core::StringView(u8"propertycategory"));
        m_arrow = core::MakeRef<TreeArrow>(MemoryAllocator());
        PropertyCategoryContent* self = this;
        m_arrow->SetOnClicked([self]() { self->m_grid.ToggleOpen(self->m_path.AsView()); });
        AddChild(m_arrow.Get());
        m_label = core::MakeRef<Label>(MemoryAllocator());
        m_label->SetTextAlignment(TextHAlign::Start, TextVAlign::Middle);
        m_label->SetHitTestVisible(false);
        AddChild(m_label.Get());
    }
    inline void PropertyCategoryContent::OnMouseClick(const MouseEvent& event)
    {
        if (event.Button != MouseButton::Left)
            return;
        event.Handled = true;
        m_grid.ToggleOpen(m_path.AsView());
    }

    inline PropertyRowContent::PropertyRowContent(PropertyGrid& grid, core::RefPtr<PropertyEditor> editor)
        : m_grid(grid), m_editor(core::Move(editor))
    {
        SetTag(core::StringView(u8"propertyrowcontent"));
        m_arrow = core::MakeRef<TreeArrow>(MemoryAllocator());
        PropertyRowContent* self = this;
        m_arrow->SetOnClicked([self]() { self->m_grid.ToggleOpen(self->m_path.AsView()); });
        AddChild(m_arrow.Get());
        m_label = core::MakeRef<Label>(MemoryAllocator());
        m_label->SetTag(core::StringView(u8"propertyname"));
        m_label->SetTextAlignment(TextHAlign::Start, TextVAlign::Middle);
        m_label->SetHitTestVisible(false);
        AddChild(m_label.Get());
        if (m_editor)
            AddChild(m_editor.Get());
        m_grip = core::MakeRef<PropertyGrip>(MemoryAllocator(), grid);
        AddChild(m_grip.Get());
        m_split = core::MakeRef<PropertySplitHandle>(MemoryAllocator(), grid);
        AddChild(m_split.Get()); // last: over the editor's edge
    }
    inline void PropertyRowContent::Show(const PropertyRow& row)
    {
        m_path = row.Path;
        m_depth = row.Depth;
        m_description = row.Info.Description;
        m_arrow->SetVisible(row.HasChildren);
        m_arrow->SetExpanded(row.Open);
        m_label->SetText(row.Info.ShownName());
        m_movable = row.Element && (row.ListOps & PropertyListMove) != 0 && row.Count > 1;
        m_grip->SetDisplayed(m_movable);
        m_grip->SetPath(row.Path.AsView());
        RequestLayout();
    }
    inline void PropertyRowContent::OnLayout()
    {
        const Rect box = GetContentBounds();
        const bool rtl = IsRightToLeft();
        const f32 split = core::Floor(box.width * m_grid.GetLabelRatio());
        const f32 indent = static_cast<f32>(m_depth) * m_grid.GetIndentWidth();
        m_arrow->Arrange(MirroredIn(Rect{box.x + indent, box.y, kArrow, box.height}, box, rtl));
        if (m_movable) // in the indent before the element
            m_grip->Arrange(MirroredIn(Rect{box.x + core::Max(0.0f, indent - kGrip), box.y, kGrip, box.height}, box, rtl));
        const f32 textX = indent + kArrow + 2.0f;
        m_label->Arrange(MirroredIn(Rect{box.x + textX, box.y, core::Max(0.0f, split - textX - 4.0f), box.height}, box, rtl));
        if (m_editor)
            m_editor->Arrange(MirroredIn(Rect{box.x + split + 2.0f, box.y + 1.0f, core::Max(0.0f, box.width - split - 2.0f), core::Max(0.0f, box.height - 2.0f)}, box, rtl));
        m_split->Arrange(MirroredIn(Rect{box.x + split - 3.0f, box.y, 6.0f, box.height}, box, rtl));
    }

    inline void PropertyGrip::OnMouseDown(const MouseEvent& event)
    {
        if (event.Button != MouseButton::Left)
            return;
        event.Handled = true;
        m_dragging = true;
        SetCursor(Cursor::Grabbing);
        m_grid.BeginReorder(m_path.AsView());
    }
    inline void PropertyGrip::OnMouseMove(const MouseEvent& event)
    {
        if (m_dragging)
            m_grid.MoveReorder(event.Position);
    }
    inline void PropertyGrip::OnMouseUp(const MouseEvent& event)
    {
        (void)event;
        if (!m_dragging)
            return;
        m_dragging = false;
        SetCursor(Cursor::Grab);
        m_grid.EndReorder(true);
    }
    inline void PropertyGrip::OnPointerCancel(const MouseEvent&)
    {
        if (!m_dragging)
            return;
        m_dragging = false;
        SetCursor(Cursor::Grab);
        m_grid.EndReorder(false);
    }

    // === The grid ===

    inline PropertyGrid::PropertyGrid()
        : m_rows(MemoryAllocator()), m_editors(MemoryAllocator()), m_nodes(MemoryAllocator()), m_top(MemoryAllocator()),
          m_toggled(MemoryAllocator())
    {
        SetTag(core::StringView(u8"propertygrid"));
        SetRowHeight(24.0f);
        RegisterDefaultPropertyEditors(m_editors);
        m_editorGeneration = m_editors.GetGeneration();
        SetRowFactory(MakeFactory());
        SetModel(&m_rows);
    }

    inline RowFactory PropertyGrid::MakeFactory()
    {
        PropertyGrid* self = this;
        RowFactory factory;
        factory.TypeOf = [self](const ModelIndex& index) -> u32
        {
            const PropertyRow* row = self->GetRow(index.Row);
            return row != nullptr ? row->Type : PropertyEditorRegistry::kNoEditor;
        };
        factory.Create = [self](u32 type) -> core::RefPtr<Node>
        {
            if (type == kCategoryRow)
                return core::MakeRef<PropertyCategoryContent>(self->MemoryAllocator(), *self);
            core::RefPtr<PropertyEditor> editor;
            if (type != kGroupRow)
                editor = self->m_editors.Create(type, self->MemoryAllocator());
            return core::MakeRef<PropertyRowContent>(self->MemoryAllocator(), *self, core::Move(editor));
        };
        factory.Bind = [self](Node& content, const ModelIndex& index) { self->BindRow(content, index); };
        return factory;
    }

    inline void PropertyGrid::BindRow(Node& content, const ModelIndex& index)
    {
        const PropertyRow* row = GetRow(index.Row);
        if (row == nullptr)
            return;
        if (PropertyCategoryContent* category = core::Cast<PropertyCategoryContent>(&content))
        {
            category->Show(*row);
            return;
        }
        PropertyRowContent* property = core::Cast<PropertyRowContent>(&content);
        if (property == nullptr)
            return;
        // The row an edit is open on keeps what its editor shows: the source's values are its
        // previews, and the editor is mid-gesture.
        const bool editing = IsUnderEdit(row->Path.AsView()) && property->GetPath() == row->Path.AsView();
        property->Show(*row);
        property->SetChanged(row->Node < m_nodes.Size() && IsChanged(row->Node));
        if (PropertyEditor* editor = property->GetEditor(); editor != nullptr && !editing && m_source != nullptr)
            editor->Bind(*this, row->Path.AsView(), row->Info, ReadPropertyValue(row->Path.AsView(), row->Info.Kind));
    }

    inline void PropertyGrid::ReadProperties()
    {
        m_nodes.Clear();
        m_top.Clear();
        if (m_source != nullptr)
            ReadChildren(core::StringView{}, m_top, 0);
        Fold();
    }

    inline void PropertyGrid::ReadChildren(core::StringView parent, core::Array<usize>& into, usize depth)
    {
        core::Array<PropertyInfo> infos(MemoryAllocator());
        m_source->GetProperties(parent, infos);
        for (PropertyInfo& info : infos)
        {
            const usize at = m_nodes.Size();
            PropertyNode node{JoinPropertyPath(parent, info.Name.AsView()), core::Move(info), core::Array<usize>(MemoryAllocator())};
            m_nodes.PushBack(core::Move(node));
            into.PushBack(at);
            const PropertyKind kind = m_nodes[at].Info.Kind;
            if ((kind == PropertyKind::Group || kind == PropertyKind::List) && depth < 32) // a cycle in a source stops here
            {
                core::Array<usize> children(MemoryAllocator());
                const core::String path = m_nodes[at].Path;
                ReadChildren(path.AsView(), children, depth + 1);
                m_nodes[at].Children = core::Move(children);
            }
        }
    }

    inline bool PropertyGrid::Matches(const PropertyNode& node) const
    {
        const core::StringView filter = m_filter.AsView();
        const auto contains = [filter](core::StringView text)
        {
            for (usize i = 0; i + filter.Size() <= text.Size(); ++i)
            {
                if (i > 0 && (text[i] & 0xC0u) == 0x80u)
                    continue; // inside a character
                if (StartsWithIgnoringCase(text.SubStr(i, text.Size() - i), filter))
                    return true;
            }
            return false;
        };
        return contains(node.Info.ShownName()) || contains(node.Path.AsView());
    }
    // An object differs from its default here (a value, a list's count), or under here.
    inline bool PropertyGrid::IsChanged(usize node) const
    {
        if (m_source == nullptr)
            return false;
        const PropertyNode& at = m_nodes[node];
        if (at.Info.Kind != PropertyKind::Group)
            for (usize i = 0; i < m_source->ObjectCount(); ++i)
            {
                const Variant byDefault = m_source->GetDefault(at.Path.AsView(), i);
                if (byDefault.IsEmpty())
                    continue;
                if (m_source->GetValue(at.Path.AsView(), i).Compare(byDefault) != 0) // an int and a float by value
                    return true;
            }
        for (const usize child : at.Children)
            if (IsChanged(child))
                return true;
        return false;
    }

    inline bool PropertyGrid::SubtreeMatches(usize node) const
    {
        if (!m_nodes[node].Info.Visible)
            return false;
        if (Matches(m_nodes[node]))
            return true;
        for (const usize child : m_nodes[node].Children)
            if (SubtreeMatches(child))
                return true;
        return false;
    }

    // `filtered`: only what matches, and what holds it, shows (an ancestor matched clears it).
    inline void PropertyGrid::AddRows(core::Array<PropertyRow>& rows, usize index, i32 depth, bool filtered, const PropertyNode* parent) const
    {
        const PropertyNode& node = m_nodes[index];
        if (!node.Info.Visible)
            return;
        const bool matches = !filtered || Matches(node);
        if (!matches && !SubtreeMatches(index))
            return;
        PropertyRow row;
        row.Path = node.Path;
        row.Info = node.Info;
        row.Depth = depth;
        // A group has no editor unless a hint asks for one (a Float3), which may be none; an
        // editor covering the children shows them on this row, so none go under it.
        row.Type = node.Info.Kind == PropertyKind::Group && node.Info.Hint.Size() == 0 ? kGroupRow : m_editors.Choose(node.Info);
        if (row.Type == PropertyEditorRegistry::kNoEditor && node.Info.Kind == PropertyKind::Group && !node.Children.IsEmpty())
            row.Type = kGroupRow; // a hint no editor takes: its own rows, if it has any
        const bool covered = m_editors.CoversChildren(row.Type);
        const bool holds = node.Info.Kind == PropertyKind::Group || node.Info.Kind == PropertyKind::List;
        row.HasChildren = holds && !node.Children.IsEmpty() && !covered;
        if (parent != nullptr && parent->Info.Kind == PropertyKind::List)
        {
            row.Element = true;
            row.ListOps = parent->Info.ReadOnly ? u8{0} : parent->Info.ListOps;
            row.Count = parent->Children.Size();
            for (usize i = 0; i < parent->Children.Size(); ++i)
                if (parent->Children[i] == index)
                    row.Index = i;
        }
        row.Open = row.HasChildren && (IsOpen(node.Path.AsView()) || !matches);
        row.Id = core::HashBytes(node.Path.Data(), node.Path.Size());
        row.Node = index;
        rows.PushBack(core::Move(row));
        if (rows.Back().Open)
            for (const usize child : node.Children)
                AddRows(rows, child, depth + 1, !matches, &node);
    }

    inline void PropertyGrid::Fold()
    {
        core::Array<PropertyRow> rows(MemoryAllocator());
        const bool filtered = m_filter.Size() != 0;
        // The categories in the order they first come; what has none comes first, without a header.
        core::Array<core::String> categories(MemoryAllocator());
        for (const usize top : m_top)
        {
            const core::String& category = m_nodes[top].Info.Category;
            if (category.Size() == 0)
                AddRows(rows, top, 0, filtered);
            else
            {
                bool seen = false;
                for (const core::String& known : categories)
                    seen = seen || known == category;
                if (!seen)
                    categories.PushBack(category);
            }
        }
        for (const core::String& category : categories)
        {
            PropertyRow header;
            header.Path = core::String(u8"#");
            header.Path.Append(category.AsView());
            header.Info.Name = category;
            header.Category = true;
            header.Type = kCategoryRow;
            header.Id = core::HashBytes(header.Path.Data(), header.Path.Size());
            bool any = !filtered;
            if (filtered)
                for (const usize top : m_top)
                    if (m_nodes[top].Info.Category == category && SubtreeMatches(top))
                        any = true;
            if (!any)
                continue;
            header.Open = IsOpen(header.Path.AsView()) || filtered;
            const bool open = header.Open;
            rows.PushBack(core::Move(header));
            if (open)
                for (const usize top : m_top)
                    if (m_nodes[top].Info.Category == category)
                        AddRows(rows, top, 0, filtered);
        }
        m_rows.SetRows(core::Move(rows));
    }

    // === Lists ===

    inline void PropertyGrid::BeginReorder(core::StringView path)
    {
        const i32 item = FindRow(path);
        const PropertyRow* row = GetRow(item);
        if (row == nullptr || !row->Element || (row->ListOps & PropertyListMove) == 0)
            return;
        EndOpenEdit();
        m_reorderList = core::String(ParentPropertyPath(path));
        m_reorderFrom = static_cast<i32>(row->Index);
        m_reorderTo = -1;
        m_reorderLine = -1;
    }
    // Over an element of the same list: before it or after it, by its halves.
    inline void PropertyGrid::MoveReorder(core::Float2 screen)
    {
        if (m_reorderFrom < 0)
            return;
        m_reorderTo = -1;
        m_reorderLine = -1;
        const i32 item = ItemAt(screen);
        const PropertyRow* row = GetRow(item);
        if (row != nullptr && row->Element && ParentPropertyPath(row->Path.AsView()) == m_reorderList.AsView())
        {
            const Rect bounds = ItemBounds(item);
            const f32 y = ConvertToNodeSpace(screen).y + GetScrollOffset().y;
            m_reorderAfter = y > bounds.y + bounds.height * 0.5f;
            const i32 slot = static_cast<i32>(row->Index) + (m_reorderAfter ? 1 : 0); // a gap between elements
            m_reorderTo = slot > m_reorderFrom ? slot - 1 : slot;
            m_reorderLine = item;
        }
        Invalidate();
    }
    inline void PropertyGrid::EndReorder(bool drop)
    {
        const core::String list = core::Move(m_reorderList);
        m_reorderList.Clear();
        const i32 from = m_reorderFrom, to = m_reorderTo;
        m_reorderFrom = m_reorderTo = m_reorderLine = -1;
        Invalidate();
        if (drop && from >= 0 && to >= 0 && to != from)
        {
            ListEdit edit;
            edit.Kind = ListEdit::Op::Move;
            edit.Index = static_cast<usize>(from);
            edit.To = static_cast<usize>(to);
            (void)EditPropertyList(list.AsView(), edit);
        }
    }

    // The line where a dragged element would go.
    inline void PropertyGrid::OnDrawAbove(DrawContext& ctx)
    {
        ItemView::OnDrawAbove(ctx);
        if (m_reorderLine < 0 || m_reorderTo < 0)
            return;
        const PartStyle& part = GetPartStyle(u8"drop-indicator");
        const Color color = part.HasBackground ? part.Box.BackgroundColor : Color{0.31f, 0.61f, 1.0f, 1.0f};
        const Rect box = GetContentBounds();
        Rect row = ItemBounds(m_reorderLine);
        row.x -= GetScrollOffset().x;
        row.y -= GetScrollOffset().y;
        const f32 y = m_reorderAfter ? row.y + row.height - 1.0f : row.y - 1.0f;
        ctx.PushClip(box);
        ctx.VG().FillRect(Rectangle{row.x, y, row.width, 2.0f}, color);
        ctx.PopClip();
    }

    // A row's menu: an element's insert before it, remove it, move it up or down; any row's revert.
    inline bool PropertyGrid::OpenRowMenu(i32 item, core::Float2 position)
    {
        const PropertyRow* found = GetRow(item);
        if (found == nullptr || found->Category)
            return false;
        const PropertyRow row = *found; // the rows change under the menu's actions
        m_menu = core::MakeRef<Menu>(MemoryAllocator());
        ShareTextStyle(*m_menu, false);
        m_menu->SetAutoWidth(true);
        bool any = false;
        if (row.Element)
        {
            PropertyGrid* self = this;
            const core::String list(ParentPropertyPath(row.Path.AsView()));
            const auto edit = [self, list](ListEdit::Op op, usize index, usize to)
            {
                ListEdit change;
                change.Kind = op;
                change.Index = index;
                change.To = to;
                (void)self->EditPropertyList(list.AsView(), change);
            };
            const usize index = row.Index;
            MenuItem* insert = m_menu->AddItem(core::StringView(u8"Insert above"), [edit, index]() { edit(ListEdit::Op::Insert, index, 0); });
            insert->SetEnabled((row.ListOps & PropertyListAdd) != 0);
            MenuItem* remove = m_menu->AddItem(core::StringView(u8"Remove"), [edit, index]() { edit(ListEdit::Op::Remove, index, 0); });
            remove->SetEnabled((row.ListOps & PropertyListRemove) != 0);
            m_menu->AddSeparator();
            MenuItem* up = m_menu->AddItem(core::StringView(u8"Move up"), [edit, index]() { edit(ListEdit::Op::Move, index, index - 1); });
            up->SetEnabled((row.ListOps & PropertyListMove) != 0 && index > 0);
            MenuItem* down = m_menu->AddItem(core::StringView(u8"Move down"), [edit, index]() { edit(ListEdit::Op::Move, index, index + 1); });
            down->SetEnabled((row.ListOps & PropertyListMove) != 0 && index + 1 < row.Count);
            any = true;
        }
        if (m_source != nullptr)
        {
            if (any)
                m_menu->AddSeparator();
            PropertyGrid* self = this;
            const core::String path = row.Path;
            EventDispatcher* dispatcher = GetEventDispatcher();
            IClipboard* clipboard = dispatcher != nullptr ? dispatcher->GetClipboard() : nullptr;
            MenuItem* copy = m_menu->AddItem(core::StringView(u8"Copy"), [self, path]() { (void)self->CopyProperty(path.AsView()); });
            copy->SetEnabled(clipboard != nullptr && m_source->CopyValue(path.AsView()).Size() != 0);
            MenuItem* paste = m_menu->AddItem(core::StringView(u8"Paste"), [self, path]() { (void)self->PasteProperty(path.AsView()); });
            paste->SetEnabled(clipboard != nullptr && clipboard->HasText() && !row.Info.ReadOnly);
            m_menu->AddSeparator();
            MenuItem* revert = m_menu->AddItem(m_source->GetRevertText(path.AsView()).AsView(), [self, path]() { (void)self->RevertProperty(path.AsView()); });
            revert->SetEnabled(row.Node < m_nodes.Size() && IsChanged(row.Node));
            any = true;
        }
        if (!any)
            return false;
        m_menu->Open(*this, position);
        return true;
    }
}
