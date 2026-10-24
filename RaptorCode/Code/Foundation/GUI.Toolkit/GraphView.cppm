// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - :graph_view partition
//
// The graph view (T6 of Specs/gui-lab-evolution-3.md): a graph source's nodes on a canvas that pans
// and zooms over a grid. A node is a widget (its header, title and a row per pin, which the sheet
// styles), made only while it is in view and reused as the view moves
// (Godot, traktor); a node never seen is made once to learn its size. The canvas runs left to right
// in every language, as a dopesheet's time does: where the nodes are placed is the graph's, so inputs
// stay on a node's left and outputs on its right, and only its text follows the language. Mouse first:
//   - a click selects a node (Shift or Ctrl adds or takes it away), a drag from nothing selects by
//     a box (Shift or Ctrl adding to what is selected);
//   - a drag moves the selected nodes (one gesture through the source, on the grid where it snaps;
//     Escape cancels it);
//   - a drag from a pin links it (ezEngine): the source is asked of each pin, which it answers
//     allowed or refused (and why) and which links it would replace, so the pins that fit are lit,
//     the rest dimmed, a link about to be replaced faded and a refusal's reason shown; a drag from an
//     input that has a link takes that link's end, to rewire it or, dropped on nothing, let it go;
//   - a drag from just outside a node's edge links it to another node (a state machine's
//     transition), where the source takes node links: a straight arrow between their borders, the
//     two ways kept apart, a node to itself when the drag leaves it and comes back;
//   - a click on a link selects it (Shift or Ctrl adds or takes it away);
//   - a link dropped on nothing opens the picker of the kinds of node with a pin that fits, the
//     node chosen made there, linked to it, in one change;
//   - the menu over nothing adds a node (the picker: by category, with a search), pastes, and frames
//     every node or the selection; a node's copies, duplicates, deletes and begins a node link (then
//     the link follows the pointer until a click ends it); a link's deletes it;
//   - Delete deletes the selected nodes and links, Escape cancels a drag or clears the selection,
//     Ctrl+C copies the selected nodes and Ctrl+V pastes them at the pointer, as the property grid's;
//   - a frame (a titled, tinted box behind the nodes; with a body, a comment) moves by its title, the
//     nodes and frames inside it moving with it, and resizes from its edges, each one change; a
//     double click on its title or its body edits it in place.
//   - a double click on a node is the application's (a subgraph opened);
//   - the wheel zooms about the pointer within limits, a middle drag pans.
// Frames' boxes are drawn by the view under the links, their titles and bodies widgets over them.
// Links are drawn by the view under the nodes, culled to it, each pin's place kept from when its
// node was last laid out. The application may highlight nodes and links (a state machine's active
// state). Read only, it selects and does not edit.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui.toolkit:graph_view;

import foundation.core;
import foundation.vg;
import foundation.gui;
import :graph_source;
import :graph_node_picker;

using namespace foundation::core;
namespace core = foundation::core;
namespace vg = foundation::vg;

export namespace foundation::gui
{
    /// What a pin or a node is to a link being dragged: nothing, a place it may end (lit), one it
    /// may not (dimmed), or the one under the pointer that it would end at.
    enum class GraphLinkState : u8
    {
        None,
        Fits,
        Refused,
        Target,
    };

    /// Shows `state` as a class (`fits`, `refused` or `target`) for the sheet.
    inline void ShowLinkState(UIWidget& widget, GraphLinkState state)
    {
        widget.RemoveClass(core::StringView(u8"fits"));
        widget.RemoveClass(core::StringView(u8"refused"));
        widget.RemoveClass(core::StringView(u8"target"));
        if (state == GraphLinkState::Fits)
            widget.AddClass(core::StringView(u8"fits"));
        else if (state == GraphLinkState::Refused)
            widget.AddClass(core::StringView(u8"refused"));
        else if (state == GraphLinkState::Target)
            widget.AddClass(core::StringView(u8"target"));
    }

    /// A pin's row in a node: its name, the pin drawn on the node's edge by the node.
    class GraphPinRow : public UIWidget
    {
        RTTI_OBJECT(GraphPinRow, UIWidget)
    public:
        GraphPinRow()
        {
            SetTag(core::StringView(u8"graphpin"));
            {
                StyleWriteScope defaults(*this);
                EditLayoutStyle([](LayoutStyle& s)
                {
                    s.Direction = FlexDirection::Row;
                    s.AlignItems = Align::Center;
                    s.MinHeight = LayoutLength::Px(20.0f);
                });
                SetPadding(Thickness{12.0f, 0.0f, 12.0f, 0.0f});
            }
            m_name = core::MakeRef<Label>(MemoryAllocator());
            m_name->SetHitTestVisible(false);
            m_name->SetLayoutDirection(LayoutDirection::Auto); // its text reads as written; the row stays left to right
            AddChild(m_name.Get());
        }

        void Show(const GraphPinInfo& pin)
        {
            m_pin = pin.Id;
            m_direction = pin.Direction;
            m_color = pin.TypeColor;
            m_name->SetText(pin.Name.AsView());
            if (pin.Direction == GraphPinDirection::Output)
            {
                RemoveClass(core::StringView(u8"input"));
                AddClass(core::StringView(u8"output"));
            }
            else
            {
                RemoveClass(core::StringView(u8"output"));
                AddClass(core::StringView(u8"input"));
            }
        }
        [[nodiscard]] GraphId GetPinId() const noexcept { return m_pin; }
        [[nodiscard]] GraphPinDirection GetDirection() const noexcept { return m_direction; }
        [[nodiscard]] Color GetTypeColor() const noexcept { return m_color; }
        [[nodiscard]] Label& GetNameLabel() noexcept { return *m_name; }
        /// What it is to a link being dragged.
        void SetLinkState(GraphLinkState state)
        {
            if (state == m_linkState)
                return;
            m_linkState = state;
            ShowLinkState(*this, state);
            // The node draws its pins: up from the row through its column and the body.
            Node* node = this;
            for (i32 up = 0; up < 3 && node != nullptr; ++up)
                node = node->GetParent();
            if (node != nullptr)
                node->Invalidate();
        }
        [[nodiscard]] GraphLinkState GetLinkState() const noexcept { return m_linkState; }

    private:
        core::RefPtr<Label> m_name;
        GraphLinkState m_linkState = GraphLinkState::None;
        GraphId m_pin = 0;
        GraphPinDirection m_direction = GraphPinDirection::Input;
        Color m_color{};
    };

    /// A node's header: its title and subtitle over the source's header colour.
    class GraphNodeHeader : public UIWidget
    {
        RTTI_OBJECT(GraphNodeHeader, UIWidget)
    public:
        GraphNodeHeader()
        {
            SetTag(core::StringView(u8"graphnodeheader"));
            StyleWriteScope defaults(*this);
            EditLayoutStyle([](LayoutStyle& s)
            {
                s.Direction = FlexDirection::Column;
                s.MinHeight = LayoutLength::Px(22.0f);
                s.JustifyContent = Justify::Center;
            });
            SetPadding(Thickness{8.0f, 3.0f, 8.0f, 3.0f});
        }
        void SetHeaderColor(Color color)
        {
            if (color.r == m_color.r && color.g == m_color.g && color.b == m_color.b && color.a == m_color.a)
                return;
            m_color = color;
            Invalidate();
        }
        [[nodiscard]] Color GetHeaderColor() const noexcept { return m_color; }

    protected:
        void OnDraw(DrawContext& ctx, const Rect& localBounds) override
        {
            // Rounded as the node's top corners are, inside its border.
            vg::CornerRadii radii{};
            if (const Node* node = GetParent())
            {
                const NodeBox& box = node->GetBox();
                radii.topLeft = core::Max(0.0f, box.Radii.topLeft - core::Max(box.BorderWidths.top, box.BorderWidths.left));
                radii.topRight = core::Max(0.0f, box.Radii.topRight - core::Max(box.BorderWidths.top, box.BorderWidths.right));
            }
            ctx.VG().FillRoundedRect(Rectangle{0.0f, 0.0f, GetSize().x, GetSize().y}, radii, m_color);
            UIWidget::OnDraw(ctx, localBounds);
        }

    private:
        Color m_color{0.27f, 0.47f, 0.73f, 1.0f};
    };

    /// A node of a graph view: its header and a row per pin, inputs on its left and outputs on its
    /// right in every language (the canvas's flow), each pin drawn on the node's edge. A view fills it
    /// from the source.
    class GraphNodeWidget : public UIWidget
    {
        RTTI_OBJECT(GraphNodeWidget, UIWidget)
    public:
        static constexpr f32 kPinRadius = 4.5f;

        GraphNodeWidget()
        {
            SetTag(core::StringView(u8"graphnode"));
            {
                StyleWriteScope defaults(*this);
                EditLayoutStyle([](LayoutStyle& s)
                {
                    s.Direction = FlexDirection::Column;
                    s.MinWidth = LayoutLength::Px(140.0f);
                });
            }
            m_header = core::MakeRef<GraphNodeHeader>(MemoryAllocator());
            AddChild(m_header.Get());
            m_title = core::MakeRef<Label>(MemoryAllocator());
            m_title->AddClass(core::StringView(u8"title"));
            m_title->SetHitTestVisible(false);
            m_header->AddChild(m_title.Get());
            m_subtitle = core::MakeRef<Label>(MemoryAllocator());
            m_subtitle->AddClass(core::StringView(u8"subtitle"));
            m_subtitle->SetHitTestVisible(false);
            m_subtitle->SetDisplayed(false);
            m_header->AddChild(m_subtitle.Get());

            m_body = MakePart(*this, u8"graphnodebody");
            {
                StyleWriteScope defaults(*m_body);
                m_body->EditLayoutStyle([](LayoutStyle& s)
                {
                    s.Direction = FlexDirection::Row;
                    s.JustifyContent = Justify::SpaceBetween;
                    s.ColumnGap = 8.0f;
                });
                m_body->SetPadding(Thickness{0.0f, 4.0f, 0.0f, 4.0f});
            }
            m_body->SetLayoutDirection(LayoutDirection::LeftToRight);
            m_inputs = MakePart(*m_body, u8"graphpins");
            m_inputs->AddClass(core::StringView(u8"inputs"));
            m_outputs = MakePart(*m_body, u8"graphpins");
            m_outputs->AddClass(core::StringView(u8"outputs"));
            {
                StyleWriteScope defaults(*m_inputs);
                m_inputs->EditLayoutStyle([](LayoutStyle& s) { s.Direction = FlexDirection::Column; });
            }
            {
                StyleWriteScope defaults(*m_outputs);
                m_outputs->EditLayoutStyle([](LayoutStyle& s)
                {
                    s.Direction = FlexDirection::Column;
                    s.AlignItems = Align::End;
                });
            }
        }

        /// Shows `node` (what changed since it last showed one).
        void Show(const GraphNodeInfo& node)
        {
            m_node = node.Id;
            m_title->SetText(node.Title.AsView());
            m_subtitle->SetText(node.Subtitle.AsView());
            m_subtitle->SetDisplayed(!node.Subtitle.IsEmpty());
            m_header->SetHeaderColor(node.HeaderColor);
            usize inputs = 0, outputs = 0;
            for (const GraphPinInfo& pin : node.Pins)
            {
                const bool out = pin.Direction == GraphPinDirection::Output;
                RowAt(out ? m_outputRows : m_inputRows, out ? *m_outputs : *m_inputs, out ? outputs++ : inputs++).Show(pin);
            }
            Trim(m_inputRows, *m_inputs, inputs);
            Trim(m_outputRows, *m_outputs, outputs);
        }
        [[nodiscard]] GraphId GetNodeId() const noexcept { return m_node; }

        /// Shown selected (the sheet's `graphnode.selected`).
        void SetSelected(bool selected)
        {
            if (selected == m_selected)
                return;
            m_selected = selected;
            if (selected)
                AddClass(core::StringView(u8"selected"));
            else
                RemoveClass(core::StringView(u8"selected"));
        }
        [[nodiscard]] bool IsSelected() const noexcept { return m_selected; }
        /// Highlighted by the application (the sheet's `graphnode.highlighted`): a state machine's active state.
        void SetHighlighted(bool highlighted)
        {
            if (highlighted == m_highlighted)
                return;
            m_highlighted = highlighted;
            if (highlighted)
                AddClass(core::StringView(u8"highlighted"));
            else
                RemoveClass(core::StringView(u8"highlighted"));
        }
        [[nodiscard]] bool IsHighlighted() const noexcept { return m_highlighted; }
        /// What the node is to a node link being dragged.
        void SetLinkState(GraphLinkState state)
        {
            if (state == m_linkState)
                return;
            m_linkState = state;
            ShowLinkState(*this, state);
        }
        [[nodiscard]] GraphLinkState GetLinkState() const noexcept { return m_linkState; }

        /// Where pin `pin` is drawn, in the node's own space (on its left edge for an input, its right
        /// for an output, across from its row's middle); false when it has no such pin.
        [[nodiscard]] bool PinPoint(GraphId pin, core::Float2& out) const
        {
            const auto find = [&](const core::Array<core::RefPtr<GraphPinRow>>& rows, bool output)
            {
                for (const core::RefPtr<GraphPinRow>& row : rows)
                {
                    if (row->GetPinId() != pin)
                        continue;
                    const core::Float2 at = OffsetIn(*row);
                    out = core::Float2{output ? GetSize().x : 0.0f, at.y + row->GetSize().y * 0.5f};
                    return true;
                }
                return false;
            };
            return find(m_inputRows, false) || find(m_outputRows, true);
        }
        /// The pin rows, inputs then outputs.
        [[nodiscard]] usize PinRowCount() const noexcept { return m_inputRows.Size() + m_outputRows.Size(); }
        [[nodiscard]] GraphPinRow& PinRowAt(usize index) const noexcept
        {
            return index < m_inputRows.Size() ? *m_inputRows[index] : *m_outputRows[index - m_inputRows.Size()];
        }
        [[nodiscard]] Label& GetTitleLabel() noexcept { return *m_title; }
        [[nodiscard]] Label& GetSubtitleLabel() noexcept { return *m_subtitle; }
        [[nodiscard]] GraphNodeHeader& GetHeader() noexcept { return *m_header; }
        /// Under the pin rows: where an application puts widgets of its own.
        [[nodiscard]] UIWidget& GetBody() noexcept { return *m_body; }

        /// What it draws: its box and its pins over its edges.
        [[nodiscard]] Rect GetInkBounds() const override
        {
            const Rect ink = UIWidget::GetInkBounds();
            const f32 reach = kPinRadius + 3.0f;
            return Rect{ink.x - reach, ink.y, ink.width + 2.0f * reach, ink.height};
        }

    protected:
        void OnDrawAbove(DrawContext& ctx) override
        {
            for (usize i = 0; i < PinRowCount(); ++i)
            {
                const GraphPinRow& row = PinRowAt(i);
                core::Float2 at{};
                if (!PinPoint(row.GetPinId(), at))
                    continue;
                // While a link is dragged: the pins it may end at ringed light, the one under the
                // pointer larger, the rest dimmed.
                const GraphLinkState state = row.GetLinkState();
                const f32 radius = state == GraphLinkState::Target ? kPinRadius + 2.0f : kPinRadius;
                Color ringColor{0.0f, 0.0f, 0.0f, 0.55f};
                Color color = row.GetTypeColor();
                if (state == GraphLinkState::Fits || state == GraphLinkState::Target)
                    ringColor = Color{1.0f, 1.0f, 1.0f, 0.9f};
                else if (state == GraphLinkState::Refused)
                {
                    color.a *= 0.3f;
                    ringColor.a *= 0.3f;
                }
                vg::PathBuilder ring;
                vg::ShapeBuilder::BuildCircle(at, radius + 1.0f, ring);
                ctx.VG().FillPath(ring.ToPath(), ringColor);
                vg::PathBuilder dot;
                vg::ShapeBuilder::BuildCircle(at, radius, dot);
                ctx.VG().FillPath(dot.ToPath(), color);
            }
        }

    private:
        static core::RefPtr<UIWidget> MakePart(UIWidget& parent, const char8_t* tag)
        {
            core::RefPtr<UIWidget> part = core::MakeRef<UIWidget>(parent.MemoryAllocator());
            part->SetTag(core::StringView(tag));
            parent.AddChild(part.Get());
            return part;
        }
        GraphPinRow& RowAt(core::Array<core::RefPtr<GraphPinRow>>& rows, UIWidget& column, usize index)
        {
            while (rows.Size() <= index)
            {
                rows.PushBack(core::MakeRef<GraphPinRow>(MemoryAllocator()));
                column.AddChild(rows.Back().Get());
            }
            return *rows[index];
        }
        static void Trim(core::Array<core::RefPtr<GraphPinRow>>& rows, UIWidget& column, usize count)
        {
            while (rows.Size() > count)
            {
                column.RemoveChild(rows.Back().Get());
                rows.RemoveAt(rows.Size() - 1);
            }
        }
        // `inner`'s top-left in this node's space (nothing between them is transformed).
        [[nodiscard]] core::Float2 OffsetIn(const Node& inner) const
        {
            core::Float2 at{};
            for (const Node* n = &inner; n != nullptr && n != this; n = n->GetParent())
                at = core::Float2{at.x + n->GetPosition().x, at.y + n->GetPosition().y};
            return at;
        }

        core::RefPtr<GraphNodeHeader> m_header;
        core::RefPtr<Label> m_title;
        core::RefPtr<Label> m_subtitle;
        core::RefPtr<UIWidget> m_body;
        core::RefPtr<UIWidget> m_inputs;
        core::RefPtr<UIWidget> m_outputs;
        core::Array<core::RefPtr<GraphPinRow>> m_inputRows;
        core::Array<core::RefPtr<GraphPinRow>> m_outputRows;
        GraphId m_node = 0;
        bool m_selected = false;
        bool m_highlighted = false;
        GraphLinkState m_linkState = GraphLinkState::None;
    };

    /// A frame of a graph view: its title and its body (a comment's), each edited in place by a
    /// double click. The view draws its tinted box under the links; it holds the words over them.
    class GraphFrameWidget : public UIWidget
    {
        RTTI_OBJECT(GraphFrameWidget, UIWidget)
    public:
        static constexpr f32 kHeaderMin = 24.0f;

        GraphFrameWidget()
        {
            SetTag(core::StringView(u8"graphframe"));
            {
                StyleWriteScope defaults(*this);
                EditLayoutStyle([](LayoutStyle& s)
                {
                    s.Direction = FlexDirection::Column;
                    s.RowGap = 8.0f;
                });
                SetPadding(Thickness{8.0f, 4.0f, 8.0f, 8.0f});
            }
            SetClipChildren(true);
            m_title = core::MakeRef<EditableLabel>(MemoryAllocator());
            m_title->AddClass(core::StringView(u8"title"));
            {
                StyleWriteScope defaults(*m_title);
                m_title->EditLayoutStyle([](LayoutStyle& s) { s.Shrink = 0.0f; });
            }
            AddChild(m_title.Get());
            // The comment in the room the frame has left, as tall as its text and scrolled there when
            // longer (the wheel taken while it moves, then the view's again; while it is typed in, to
            // keep the caret in view).
            m_bodyBox = core::MakeRef<UIWidget>(MemoryAllocator());
            m_bodyBox->SetTag(core::StringView(u8"graphframebody"));
            {
                StyleWriteScope defaults(*m_bodyBox);
                m_bodyBox->EditLayoutStyle([](LayoutStyle& s)
                {
                    s.Direction = FlexDirection::Column;
                    s.Grow = 1.0f;
                    s.MinHeight = LayoutLength::Px(0.0f);
                    s.OverflowY = Overflow::Auto;
                });
            }
            AddChild(m_bodyBox.Get());
            m_body = core::MakeRef<EditableLabel>(MemoryAllocator());
            m_body->AddClass(core::StringView(u8"body"));
            m_body->SetMultiline(true);
            m_body->SetDisplayed(false);
            m_bodyBox->AddChild(m_body.Get());
            GraphFrameWidget* self = this;
            m_title->SetOnTextCommitted([self](core::StringView text)
            {
                if (self->m_onCommitted)
                    self->m_onCommitted(self->m_frame, text, false);
            });
            m_body->SetOnTextCommitted([self](core::StringView text)
            {
                if (self->m_onCommitted)
                    self->m_onCommitted(self->m_frame, text, true);
            });
        }

        void Show(const GraphFrameInfo& frame)
        {
            m_frame = frame.Id;
            if (!m_title->IsEditing())
                m_title->SetText(frame.Title.AsView());
            if (!m_body->IsEditing())
            {
                m_body->SetText(frame.Body.AsView());
                m_body->SetDisplayed(!frame.Body.IsEmpty());
            }
        }
        [[nodiscard]] GraphId GetFrameId() const noexcept { return m_frame; }
        [[nodiscard]] EditableLabel& GetTitleLabel() noexcept { return *m_title; }
        [[nodiscard]] EditableLabel& GetBodyLabel() noexcept { return *m_body; }
        /// What scrolls a comment longer than the frame.
        [[nodiscard]] UIWidget& GetBodyBox() noexcept { return *m_bodyBox; }
        /// Edits its body in place, shown while it does (a frame made a comment).
        void EditBody()
        {
            m_body->SetDisplayed(true);
            m_body->BeginEdit();
        }
        /// How tall its title band is, in its own space: what a press moves it by.
        [[nodiscard]] f32 HeaderHeight() const
        {
            return core::Max(kHeaderMin, m_title->GetPosition().y + m_title->GetSize().y + 4.0f);
        }
        /// Shown selected (the sheet's `graphframe.selected`).
        void SetSelected(bool selected)
        {
            if (selected == m_selected)
                return;
            m_selected = selected;
            if (selected)
                AddClass(core::StringView(u8"selected"));
            else
                RemoveClass(core::StringView(u8"selected"));
        }
        [[nodiscard]] bool IsSelected() const noexcept { return m_selected; }
        /// A title or a body (`body`) committed: the view's, to edit the frame through the source.
        void SetOnCommitted(core::Function<void(GraphId, core::StringView, bool)> callback) { m_onCommitted = core::Move(callback); }

    private:
        core::RefPtr<EditableLabel> m_title;
        core::RefPtr<UIWidget> m_bodyBox;
        core::RefPtr<EditableLabel> m_body;
        GraphId m_frame = 0;
        bool m_selected = false;
        core::Function<void(GraphId, core::StringView, bool)> m_onCommitted;
    };

    class GraphView : public UIWidget, public IGraphSourceClient
    {
        RTTI_OBJECT(GraphView, UIWidget)
    public:
        static constexpr f32 kDragThreshold = 3.0f;
        /// How near a pin a press or a drop takes it (at least; the pin's own size when larger).
        static constexpr f32 kPinReach = 9.0f;
        /// How far outside a node's edge a press begins a node link.
        static constexpr f32 kEdgeReach = 7.0f;
        /// How near a link a click selects it.
        static constexpr f32 kLinkReach = 5.0f;
        /// How far apart a node link and its reverse are drawn.
        static constexpr f32 kParallelGap = 6.0f;
        /// How far inside a frame's edge a press resizes it.
        static constexpr f32 kFrameEdge = 6.0f;
        /// The least a frame is resized to, in the graph's units.
        static constexpr f32 kFrameMinWidth = 80.0f;
        static constexpr f32 kFrameMinHeight = 48.0f;
        /// How far past its edges nodes are made before they come into view.
        static constexpr f32 kViewMargin = 64.0f;
        /// The size a node is taken to have before it was measured.
        [[nodiscard]] static core::Float2 EstimatedNodeSize() noexcept { return core::Float2{160.0f, 80.0f}; }

        GraphView()
        {
            SetTag(core::StringView(u8"graphview"));
            SetTabFocusable(true);
            SetClipChildren(true);
            SetPlacesChildren(true); // the nodes at their points on the canvas, which stays left to right
        }
        ~GraphView() override
        {
            if (m_source)
                m_source->RemoveGraphClient(this);
        }

        // === What it shows ===
        /// The graph it shows and edits (not owned: the source outlives the view or is set to null first).
        void SetSource(IGraphSource* source)
        {
            if (m_source)
                m_source->RemoveGraphClient(this);
            m_source = source;
            if (m_source)
                m_source->AddGraphClient(this);
            m_selection.Clear();
            m_selectedLinks.Clear();
            m_selectedFrames.Clear();
            m_sizes.Clear();
            m_pins.Clear();
            RequestLayout();
        }
        [[nodiscard]] IGraphSource* GetSource() const noexcept { return m_source; }
        /// Read only: it selects, and moves and edits nothing.
        void SetReadOnly(bool readOnly) noexcept { m_readOnly = readOnly; }
        [[nodiscard]] bool IsReadOnly() const noexcept { return m_readOnly; }

        // === The canvas ===
        /// The graph's point at its content box's top-left.
        void SetPan(core::Float2 pan)
        {
            m_fitting = false;
            m_pan = pan;
            RequestLayout();
        }
        [[nodiscard]] core::Float2 GetPan() const noexcept { return m_pan; }
        /// The zoom (within its limits), the graph's point at `about` (its own space) kept in place.
        void SetZoom(f32 zoom, core::Float2 about)
        {
            m_fitting = false;
            const core::Float2 fixed = ViewToGraph(about);
            m_zoom = core::Clamp(zoom, m_zoomMin, m_zoomMax);
            const Rect box = GetContentBounds();
            m_pan = core::Float2{fixed.x - (about.x - box.x) / m_zoom, fixed.y - (about.y - box.y) / m_zoom};
            RequestLayout();
        }
        void SetZoom(f32 zoom) { SetZoom(zoom, core::Float2{GetContentBounds().x, GetContentBounds().y}); }
        [[nodiscard]] f32 GetZoom() const noexcept { return m_zoom; }
        void SetZoomLimits(f32 least, f32 most)
        {
            m_zoomMin = core::Max(0.01f, least);
            m_zoomMax = core::Max(m_zoomMin, most);
            SetZoom(m_zoom);
        }
        [[nodiscard]] f32 ZoomMin() const noexcept { return m_zoomMin; }
        [[nodiscard]] f32 ZoomMax() const noexcept { return m_zoomMax; }
        /// The grid's cell in the graph's units, what a move snaps to when it snaps.
        void SetGridSize(f32 size)
        {
            m_gridSize = core::Max(1.0f, size);
            Invalidate();
        }
        [[nodiscard]] f32 GetGridSize() const noexcept { return m_gridSize; }
        void SetSnapToGrid(bool snap) noexcept { m_snap = snap; }
        [[nodiscard]] bool GetSnapToGrid() const noexcept { return m_snap; }

        [[nodiscard]] core::Float2 GraphToView(core::Float2 graph) const
        {
            const Rect box = GetContentBounds();
            return core::Float2{box.x + (graph.x - m_pan.x) * m_zoom, box.y + (graph.y - m_pan.y) * m_zoom};
        }
        [[nodiscard]] core::Float2 ViewToGraph(core::Float2 local) const
        {
            const Rect box = GetContentBounds();
            return core::Float2{m_pan.x + (local.x - box.x) / m_zoom, m_pan.y + (local.y - box.y) / m_zoom};
        }

        /// Fits every node in view (at most at the zoom of 1), and goes on fitting them as it is laid
        /// out (its size settling, its nodes measured) until the canvas is moved: a press or the wheel
        /// in it, or code setting its pan or zoom.
        void FrameAll()
        {
            m_fitting = true;
            Frame(false);
            RequestLayout();
        }
        /// Fits the selected nodes in view; every node with none selected.
        void FrameSelection()
        {
            m_fitting = false;
            Frame(!m_selection.IsEmpty());
        }
        /// Whether it still fits every node (FrameAll, the canvas not moved since).
        [[nodiscard]] bool IsFitting() const noexcept { return m_fitting; }

        // === Edits of the selection (one change each, through the source) ===
        /// Deletes the selected nodes (and their links), then the selected links left; false when
        /// nothing went.
        bool DeleteSelected();
        /// Copies the selected nodes (and the links among them) to the clipboard as the source's text.
        bool CopySelected();
        /// Pastes the clipboard's nodes, their top-left at `at` (the graph's), selecting them.
        bool PasteAt(core::Float2 at);
        /// Copies and pastes the selected nodes beside them, selecting the copies (the clipboard kept).
        bool DuplicateSelected();
        /// Makes a node of `type` at `at` (the graph's), linked from pin `linkFrom` when it is not 0,
        /// selecting it; its id, 0 when it was not made.
        GraphId AddNode(core::StringView type, core::Float2 at, GraphId linkFrom = 0);

        // === Frames ===
        /// Where a frame is, in its own space (as it is being resized, while it is); empty when there
        /// is no such frame.
        [[nodiscard]] Rect FrameRect(GraphId frame) const
        {
            GraphFrameInfo info;
            if (!FindFrame(frame, info))
                return Rect{};
            const Rect graph = m_drag == Drag::Resize && frame == m_resizeFrame ? m_resizeTo : Rect{info.Position.x, info.Position.y, info.Size.x, info.Size.y};
            const core::Float2 at = GraphToView(core::Float2{graph.x, graph.y});
            return Rect{at.x, at.y, graph.width * m_zoom, graph.height * m_zoom};
        }
        [[nodiscard]] GraphFrameWidget* GetFrameWidget(GraphId frame) const
        {
            const core::RefPtr<GraphFrameWidget>* widget = m_frameWidgets.Find(frame);
            return widget != nullptr ? widget->Get() : nullptr;
        }
        [[nodiscard]] const core::Array<GraphId>& GetSelectedFrames() const noexcept { return m_selectedFrames; }
        void SetSelectedFrames(core::Span<const GraphId> frames)
        {
            core::Array<GraphId> next;
            for (const GraphId frame : frames)
                if (!Holds(next, frame))
                    next.PushBack(frame);
            ReselectFrames(core::Move(next));
        }
        [[nodiscard]] bool IsFrameSelected(GraphId frame) const noexcept { return Holds(m_selectedFrames, frame); }
        /// Makes a frame (with `comment`, a comment: a frame with a body) around the selected nodes, or
        /// at `at` (the graph's) with none selected, selecting it; its id, 0 when none was made.
        GraphId AddFrame(core::Float2 at, bool comment = false);

        // === Menus ===
        /// Opens the node picker at `local` (its own space), the node chosen made there; with
        /// `fitting`, a pin, only the kinds a link from it reaches, the node linked to it. False when
        /// there is no kind to offer.
        bool OpenNodePicker(core::Float2 local, GraphId fitting = 0);
        [[nodiscard]] bool IsNodePickerOpen() const
        {
            const EventDispatcher* dispatcher = m_picker ? m_picker->GetEventDispatcher() : nullptr;
            return dispatcher != nullptr && dispatcher->IsPopupOpen(*m_picker);
        }
        [[nodiscard]] GraphNodePicker* GetNodePicker() const noexcept { return m_picker.Get(); }
        /// The context menu while it is open; null when it is not.
        [[nodiscard]] Menu* GetMenu() const noexcept { return m_menu && m_menu->IsOpen() ? m_menu.Get() : nullptr; }
        /// Begins a node link from `node` that follows the pointer until a click ends it (a node's
        /// menu); false when the source takes none from it.
        bool BeginNodeLink(GraphId node);

        // === Nodes ===
        /// A node's size as last measured (an estimate before it was).
        [[nodiscard]] core::Float2 NodeSize(GraphId node) const
        {
            const core::Float2* size = m_sizes.Find(node);
            return size != nullptr ? *size : EstimatedNodeSize();
        }
        /// Where a node is, in its own space; empty when there is no such node.
        [[nodiscard]] Rect NodeRect(GraphId node) const
        {
            const GraphNodeInfo* info = m_source ? m_source->GetNode(node) : nullptr;
            if (info == nullptr)
                return Rect{};
            const core::Float2 at = GraphToView(info->Position);
            const core::Float2 size = NodeSize(node);
            return Rect{at.x, at.y, size.x * m_zoom, size.y * m_zoom};
        }
        /// The topmost node at `local` (its own space); 0 when none.
        [[nodiscard]] GraphId HitNode(core::Float2 local) const
        {
            if (!m_source)
                return 0;
            core::Array<GraphId> order;
            PaintOrder(order);
            for (usize i = order.Size(); i-- > 0;)
                if (NodeRect(order[i]).Contains(local))
                    return order[i];
            return 0;
        }
        /// Where pin `pin` is drawn, in its own space, as its node was last laid out; false when the
        /// view has not laid it out.
        [[nodiscard]] bool PinPoint(GraphId pin, core::Float2& out) const
        {
            const PinPlace* place = m_pins.Find(pin);
            const GraphNodeInfo* node = place != nullptr && m_source ? m_source->GetNode(place->Node) : nullptr;
            if (node == nullptr)
                return false;
            const core::Float2 at = GraphToView(node->Position);
            out = core::Float2{at.x + place->Offset.x * m_zoom, at.y + place->Offset.y * m_zoom};
            return true;
        }
        /// The pin of a node in view at `local` (its own space); 0 when none.
        [[nodiscard]] GraphId HitPin(core::Float2 local) const { return NearestPin(local, PinReach()); }
        /// The line link `link` is drawn along, in its own space (a curve's points, or an edge with its
        /// arrow at the end); false when an end has no place yet.
        [[nodiscard]] bool LinkPoints(const GraphLinkInfo& link, core::Array<core::Float2>& out) const;
        /// The topmost link at `local` (its own space); 0 when none.
        [[nodiscard]] GraphId HitLink(core::Float2 local) const;

        /// A node's widget while it is made (in view); null when it is not.
        [[nodiscard]] GraphNodeWidget* GetNodeWidget(GraphId node) const
        {
            const core::RefPtr<GraphNodeWidget>* widget = m_live.Find(node);
            return widget != nullptr ? widget->Get() : nullptr;
        }
        /// How many node widgets are made now (those in view), and how many wait to be reused.
        [[nodiscard]] usize MadeNodeCount() const noexcept { return m_live.Size(); }
        [[nodiscard]] usize PooledNodeCount() const noexcept { return m_pool.Size(); }

        // === The selection ===
        [[nodiscard]] const core::Array<GraphId>& GetSelectedNodes() const noexcept { return m_selection; }
        void SetSelectedNodes(core::Span<const GraphId> nodes)
        {
            core::Array<GraphId> next;
            for (const GraphId node : nodes)
                if (m_source && m_source->GetNode(node) != nullptr && !Holds(next, node))
                    next.PushBack(node);
            Reselect(core::Move(next));
        }
        [[nodiscard]] bool IsNodeSelected(GraphId node) const noexcept { return Holds(m_selection, node); }
        [[nodiscard]] const core::Array<GraphId>& GetSelectedLinks() const noexcept { return m_selectedLinks; }
        void SetSelectedLinks(core::Span<const GraphId> links)
        {
            core::Array<GraphId> next;
            for (const GraphId link : links)
                if (!Holds(next, link))
                    next.PushBack(link);
            ReselectLinks(core::Move(next));
        }
        [[nodiscard]] bool IsLinkSelected(GraphId link) const noexcept { return Holds(m_selectedLinks, link); }

        // === Highlights (the application's: a state machine's active state) ===
        void SetHighlightedNodes(core::Span<const GraphId> nodes)
        {
            m_highlightedNodes.Clear();
            for (const GraphId node : nodes)
                m_highlightedNodes.PushBack(node);
            RequestLayout();
        }
        void SetHighlightedLinks(core::Span<const GraphId> links)
        {
            m_highlightedLinks.Clear();
            for (const GraphId link : links)
                m_highlightedLinks.PushBack(link);
            Invalidate();
        }
        [[nodiscard]] bool IsNodeHighlighted(GraphId node) const noexcept { return Holds(m_highlightedNodes, node); }
        [[nodiscard]] bool IsLinkHighlighted(GraphId link) const noexcept { return Holds(m_highlightedLinks, link); }

        /// Whether a link is being dragged, and what the source said of where it would end (Allowed
        /// false with no reason: it is over nothing).
        [[nodiscard]] bool IsLinking() const noexcept { return m_drag == Drag::Link; }
        [[nodiscard]] const GraphLinkCheck& GetLinkCheck() const noexcept { return m_targetCheck; }
        /// Told each time the selection changes.
        void SetOnSelectionChanged(core::Function<void()> callback) { m_onSelectionChanged = core::Move(callback); }
        /// A double click on a node: the application's (a subgraph opened).
        void SetOnNodeDoubleClick(core::Function<void(GraphId)> callback) { m_onNodeDoubleClick = core::Move(callback); }

        void OnGraphChanged() override
        {
            if (!m_source)
                return;
            core::Array<GraphId> kept; // an undo may take nodes away
            for (const GraphId node : m_selection)
                if (m_source->GetNode(node) != nullptr)
                    kept.PushBack(node);
            if (kept.Size() != m_selection.Size())
                Reselect(core::Move(kept));
            core::Array<GraphLinkInfo> links;
            m_source->GetLinks(links);
            core::Array<GraphId> keptLinks;
            for (const GraphId link : m_selectedLinks)
                for (const GraphLinkInfo& at : links)
                    if (at.Id == link)
                        keptLinks.PushBack(link);
            if (keptLinks.Size() != m_selectedLinks.Size())
                ReselectLinks(core::Move(keptLinks));
            core::Array<GraphFrameInfo> frames;
            m_source->GetFrames(frames);
            core::Array<GraphId> keptFrames;
            for (const GraphId frame : m_selectedFrames)
                for (const GraphFrameInfo& at : frames)
                    if (at.Id == frame)
                        keptFrames.PushBack(frame);
            if (keptFrames.Size() != m_selectedFrames.Size())
                ReselectFrames(core::Move(keptFrames));
            RequestLayout();
            Invalidate();
        }

    protected:
        void OnLayout() override;
        void OnMouseDown(const MouseEvent& event) override;
        void OnMouseMove(const MouseEvent& event) override;
        void OnMouseUp(const MouseEvent& event) override;
        void OnPointerCancel(const MouseEvent& event) override;
        void OnPointerCaptureLost() override
        {
            if (m_drag == Drag::Link)
                EndLink(false);
            else
                EndDrag(false);
        }
        void OnMouseWheel(const WheelEvent& event) override;
        void OnMouseLeave(const MouseEvent&) override { m_pointerInside = false; }
        void OnContextMenu(const MouseEvent& event) override;
        void OnKeyDown(const KeyEvent& event) override;
        [[nodiscard]] Cursor GetCursorNow() const override;
        void OnDraw(DrawContext& ctx, const Rect& localBounds) override;
        void OnDrawAbove(DrawContext& ctx) override;
        void OnTextStyleChange() override
        {
            m_text.SetFont(GetFont());
            m_text.SetFontSelection(GetFontService(), GetTextStyle().FontFamily.AsView(), GetTextStyle().Selection);
            m_text.SetColor(GetTextColor());
            m_text.SetAlignment(TextHAlign::Start, TextVAlign::Top);
        }

    private:
        enum class Drag : u8
        {
            None,
            Pending, // pressed on a node, not moved past the threshold
            Nodes,
            Box,
            Pan,
            Link,
            Resize,
        };
        // A frame's edges a press is on (several at a corner).
        static constexpr u8 kEdgeLeft = 1, kEdgeTop = 2, kEdgeRight = 4, kEdgeBottom = 8;
        // Where a pin is in its node, as the node was last laid out.
        struct PinPlace
        {
            GraphId Node = 0;
            core::Float2 Offset{}; // in the node's space, unzoomed
            GraphPinDirection Direction = GraphPinDirection::Input;
            Color TypeColor{};
        };

        [[nodiscard]] f32 PinReach() const noexcept { return core::Max(kPinReach, (GraphNodeWidget::kPinRadius + 3.0f) * m_zoom); }
        // The pin of a made node nearest `local` within `reach`; 0 when none.
        [[nodiscard]] GraphId NearestPin(core::Float2 local, f32 reach) const
        {
            GraphId best = 0;
            f32 bestDistance = reach * reach;
            for (const auto& entry : m_pins)
            {
                if (m_live.Find(entry.value.Node) == nullptr)
                    continue;
                core::Float2 at{};
                if (!PinPoint(entry.key, at))
                    continue;
                const f32 dx = at.x - local.x, dy = at.y - local.y;
                if (dx * dx + dy * dy <= bestDistance)
                {
                    bestDistance = dx * dx + dy * dy;
                    best = entry.key;
                }
            }
            return best;
        }
        // The node whose edge `local` is just outside of (none when it is inside a node).
        [[nodiscard]] GraphId HitNodeEdge(core::Float2 local) const
        {
            if (!m_source)
                return 0;
            core::Array<GraphId> order;
            PaintOrder(order);
            for (usize i = order.Size(); i-- > 0;)
            {
                const Rect r = NodeRect(order[i]);
                if (r.Contains(local))
                    return 0;
                if (Rect{r.x - kEdgeReach, r.y - kEdgeReach, r.width + 2.0f * kEdgeReach, r.height + 2.0f * kEdgeReach}.Contains(local))
                    return order[i];
            }
            return 0;
        }
        // The link a drag would make ending at `target` (a pin, or a node for a node link).
        [[nodiscard]] GraphLinkInfo Candidate(GraphId target) const
        {
            GraphLinkInfo link;
            link.Kind = m_linkKind;
            if (m_linkKind == GraphLinkKind::Nodes)
            {
                link.FromNode = m_anchorNode;
                link.ToNode = target;
                return link;
            }
            const PinPlace* place = m_pins.Find(target);
            const GraphId targetNode = place != nullptr ? place->Node : 0;
            if (m_anchorOutput)
            {
                link.FromNode = m_anchorNode;
                link.FromPin = m_anchorPin;
                link.ToNode = targetNode;
                link.ToPin = target;
            }
            else
            {
                link.FromNode = targetNode;
                link.FromPin = target;
                link.ToNode = m_anchorNode;
                link.ToPin = m_anchorPin;
            }
            return link;
        }
        [[nodiscard]] bool FindFrame(GraphId frame, GraphFrameInfo& out) const
        {
            if (!m_source || frame == 0)
                return false;
            core::Array<GraphFrameInfo> frames;
            m_source->GetFrames(frames);
            for (const GraphFrameInfo& at : frames)
                if (at.Id == frame)
                {
                    out = at;
                    return true;
                }
            return false;
        }
        // The topmost frame at `local`: on which of its edges, and whether on its title band.
        [[nodiscard]] GraphId HitFrame(core::Float2 local, u8& edges, bool& header) const
        {
            edges = 0;
            header = false;
            if (!m_source)
                return 0;
            core::Array<GraphFrameInfo> frames;
            m_source->GetFrames(frames);
            for (usize i = frames.Size(); i-- > 0;)
            {
                const Rect r = FrameRect(frames[i].Id);
                if (!r.Contains(local))
                    continue;
                if (local.x < r.x + kFrameEdge)
                    edges |= kEdgeLeft;
                if (local.x > r.Right() - kFrameEdge)
                    edges |= kEdgeRight;
                if (local.y < r.y + kFrameEdge)
                    edges |= kEdgeTop;
                if (local.y > r.Bottom() - kFrameEdge)
                    edges |= kEdgeBottom;
                const GraphFrameWidget* widget = GetFrameWidget(frames[i].Id);
                const f32 band = (widget != nullptr ? widget->HeaderHeight() : GraphFrameWidget::kHeaderMin) * m_zoom;
                header = local.y < r.y + band;
                return frames[i].Id;
            }
            return 0;
        }
        void ReselectFrames(core::Array<GraphId> next)
        {
            bool same = next.Size() == m_selectedFrames.Size();
            for (usize i = 0; same && i < next.Size(); ++i)
                same = Holds(m_selectedFrames, next[i]);
            m_selectedFrames = core::Move(next);
            if (same)
                return;
            RequestLayout();
            Invalidate();
            if (m_onSelectionChanged)
                m_onSelectionChanged();
        }
        void EditFrameText(GraphId frame, core::StringView text, bool body)
        {
            GraphFrameInfo info;
            if (m_readOnly || !FindFrame(frame, info))
                return;
            if (body)
                info.Body = core::String(text);
            else
                info.Title = core::String(text);
            (void)m_source->EditFrame(info);
        }
        void ResizeTo(core::Float2 local);
        void ReselectLinks(core::Array<GraphId> next)
        {
            bool same = next.Size() == m_selectedLinks.Size();
            for (usize i = 0; same && i < next.Size(); ++i)
                same = Holds(m_selectedLinks, next[i]);
            m_selectedLinks = core::Move(next);
            if (same)
                return;
            Invalidate();
            if (m_onSelectionChanged)
                m_onSelectionChanged();
        }
        bool BeginLink(core::Float2 local);
        bool BeginNodeLinkFrom(GraphId node);
        void OpenMenu(core::Float2 local, core::Float2 screen);
        void PopupAt(Node& popup, core::Float2 local, PopupOptions options);
        void LinkTo(core::Float2 local);
        void EndLink(bool commit);
        void ShowLinkStates();
        // A curve from an output's point to an input's, leaving and arriving along the reading direction.
        void CurvePoints(core::Float2 from, core::Float2 to, core::Array<core::Float2>& out) const;
        // A straight edge between two nodes' borders (`gap` to its right), or a loop on one node.
        void EdgePoints(const Rect& from, const Rect& to, f32 gap, core::Array<core::Float2>& out) const;
        void StrokeLine(DrawContext& ctx, core::Span<const core::Float2> points, Color color, f32 width, bool arrow) const;

        [[nodiscard]] static bool Holds(const core::Array<GraphId>& ids, GraphId id) noexcept
        {
            for (const GraphId at : ids)
                if (at == id)
                    return true;
            return false;
        }
        void Reselect(core::Array<GraphId> next)
        {
            bool same = next.Size() == m_selection.Size();
            for (usize i = 0; same && i < next.Size(); ++i)
                same = Holds(m_selection, next[i]);
            m_selection = core::Move(next);
            if (same)
                return;
            RequestLayout(); // selected nodes stand on top
            Invalidate();
            if (m_onSelectionChanged)
                m_onSelectionChanged();
        }
        void Toggle(GraphId node)
        {
            core::Array<GraphId> next;
            for (const GraphId at : m_selection)
                if (at != node)
                    next.PushBack(at);
            if (next.Size() == m_selection.Size())
                next.PushBack(node);
            Reselect(core::Move(next));
        }
        void SelectOnly(GraphId node)
        {
            core::Array<GraphId> next;
            if (node != 0)
                next.PushBack(node);
            Reselect(core::Move(next));
        }
        // The source's nodes in the order they are drawn: the selected last, over the rest.
        void PaintOrder(core::Array<GraphId>& out) const
        {
            out.Clear();
            core::Array<GraphId> ids;
            m_source->GetNodes(ids);
            for (const GraphId id : ids)
                if (!Holds(m_selection, id))
                    out.PushBack(id);
            for (const GraphId id : ids)
                if (Holds(m_selection, id))
                    out.PushBack(id);
        }
        void CapturePointer()
        {
            if (EventDispatcher* dispatcher = GetEventDispatcher())
                dispatcher->CapturePointer(*this);
        }
        void ReleasePointer()
        {
            if (EventDispatcher* dispatcher = GetEventDispatcher())
                dispatcher->ReleasePointer(*this);
        }
        void BeginMove();
        void MoveTo(core::Float2 local);
        void EndDrag(bool commit);
        void Frame(bool selectionOnly);
        [[nodiscard]] core::RefPtr<GraphNodeWidget> TakeWidget();

        IGraphSource* m_source = nullptr;
        bool m_readOnly = false;
        core::Float2 m_pan{};
        f32 m_zoom = 1.0f;
        f32 m_zoomMin = 0.2f;
        f32 m_zoomMax = 2.0f;
        f32 m_gridSize = 16.0f;
        bool m_snap = true;
        bool m_fitting = false; // FrameAll's: fitting every node until the canvas is moved
        core::Array<GraphId> m_selection;
        core::Function<void()> m_onSelectionChanged;
        core::Function<void(GraphId)> m_onNodeDoubleClick;

        core::HashMap<GraphId, core::RefPtr<GraphNodeWidget>> m_live; // the nodes made, by id
        core::Array<core::RefPtr<GraphNodeWidget>> m_pool;            // made, waiting to be reused
        core::HashMap<GraphId, core::Float2> m_sizes;                  // each node's size as last measured
        core::HashMap<GraphId, PinPlace> m_pins;                       // each pin's place, by pin id
        core::Array<GraphId> m_selectedLinks;
        core::Array<GraphId> m_highlightedNodes;
        core::Array<GraphId> m_highlightedLinks;
        core::HashMap<GraphId, core::RefPtr<GraphFrameWidget>> m_frameWidgets;
        core::Array<GraphId> m_selectedFrames;
        core::Array<GraphId> m_frameBoxBase;   // the frames a box adds to
        core::Array<GraphId> m_moveNodes;      // what a move moves: the selected nodes, and those inside the selected frames
        core::Array<GraphId> m_moveFrames;
        GraphId m_pressedFrame = 0;            // the frame pressed by its title
        GraphId m_resizeFrame = 0;
        u8 m_resizeEdges = 0;
        Rect m_resizeFrom{};                   // the graph's
        Rect m_resizeTo{};

        Drag m_drag = Drag::None;
        core::Float2 m_pressAt{};   // where the gesture began, its own space
        core::Float2 m_boxTo{};
        GraphId m_pressed = 0;      // the node pressed
        core::Float2 m_pressedFrom{}; // its place in the graph when the move began
        bool m_additive = false;    // Shift or Ctrl held at the press
        core::Array<GraphId> m_boxBase; // what a box adds to
        core::Float2 m_panFrom{};

        // A link dragged: from a pin (or, a node link, a node), or an existing link's input end.
        GraphLinkKind m_linkKind = GraphLinkKind::Pins;
        GraphId m_anchorNode = 0;
        GraphId m_anchorPin = 0;
        bool m_anchorOutput = true;    // the anchor is the link's From end
        GraphId m_relinking = 0;       // the link whose end is carried
        GraphId m_relinkFrom = 0;      // the input it came off
        bool m_linkMoved = false;      // past the threshold
        bool m_leftAnchor = false;     // a node link's pointer left its node (so it may come back to it)
        core::Float2 m_linkTo{};
        GraphId m_target = 0;
        GraphLinkCheck m_targetCheck;
        core::HashMap<GraphId, bool> m_fits; // each pin's (or node's) answer, asked once per drag
        bool m_sticky = false;         // begun from a menu: it follows the pointer until a click
        mutable Text m_text;           // a refusal's reason

        core::Float2 m_pointer{};      // where the pointer was last over it, its own space
        bool m_pointerInside = false;
        core::RefPtr<Menu> m_menu;
        core::RefPtr<GraphNodePicker> m_picker;
        core::Float2 m_pickAt{};       // where the node picked goes, the graph's
        GraphId m_pickFrom = 0;        // the pin it is linked from
    };

    // === Making the nodes in view ===

    inline core::RefPtr<GraphNodeWidget> GraphView::TakeWidget()
    {
        if (!m_pool.IsEmpty())
        {
            core::RefPtr<GraphNodeWidget> widget = m_pool.Back();
            m_pool.RemoveAt(m_pool.Size() - 1);
            return widget;
        }
        return core::MakeRef<GraphNodeWidget>(MemoryAllocator());
    }

    inline void GraphView::OnLayout()
    {
        core::HashMap<GraphId, core::RefPtr<GraphNodeWidget>> live;
        core::HashMap<GraphId, core::Float2> sizes;
        core::Array<GraphId> order;
        core::Array<GraphNodeWidget*> unseen; // made only to be measured
        if (m_source)
            PaintOrder(order);
        const Rect box = GetContentBounds();
        const Rect reach{box.x - kViewMargin, box.y - kViewMargin, box.width + 2.0f * kViewMargin, box.height + 2.0f * kViewMargin};
        usize index = 0;
        // The frames first, under the nodes; few, each made while it is in the graph.
        {
            core::Array<GraphFrameInfo> frames;
            if (m_source)
                m_source->GetFrames(frames);
            core::HashMap<GraphId, core::RefPtr<GraphFrameWidget>> made;
            GraphView* self = this;
            for (const GraphFrameInfo& frame : frames)
            {
                core::RefPtr<GraphFrameWidget> widget;
                if (core::RefPtr<GraphFrameWidget>* had = m_frameWidgets.Find(frame.Id))
                {
                    widget = *had;
                    (void)m_frameWidgets.Remove(frame.Id);
                }
                else
                {
                    widget = core::MakeRef<GraphFrameWidget>(MemoryAllocator());
                    widget->SetOnCommitted([self](GraphId id, core::StringView text, bool body) { self->EditFrameText(id, text, body); });
                    AddChild(widget.Get());
                }
                widget->Show(frame);
                widget->SetSelected(Holds(m_selectedFrames, frame.Id));
                const Rect at = FrameRect(frame.Id);
                widget->Arrange(Rect{at.x, at.y, at.width / m_zoom, at.height / m_zoom});
                if (widget->GetScale().x != m_zoom || widget->GetScale().y != m_zoom)
                    widget->SetScale(core::Float2{m_zoom, m_zoom});
                if (index < ChildCount() && GetChildAt(index) != widget.Get())
                    SetChildIndex(widget.Get(), index);
                ++index;
                made.InsertOrAssign(frame.Id, core::Move(widget));
            }
            for (auto& entry : m_frameWidgets)
                RemoveChild(entry.value.Get());
            m_frameWidgets = core::Move(made);
        }
        for (const GraphId id : order)
        {
            const GraphNodeInfo* info = m_source->GetNode(id);
            const core::Float2* known = m_sizes.Find(id);
            const core::Float2 at = GraphToView(info->Position);
            const core::Float2 guess = known != nullptr ? *known : EstimatedNodeSize();
            const bool inView = reach.Intersects(Rect{at.x, at.y, guess.x * m_zoom, guess.y * m_zoom});
            if (!inView && known != nullptr)
            {
                sizes.InsertOrAssign(id, *known);
                continue;
            }
            core::RefPtr<GraphNodeWidget> widget;
            if (core::RefPtr<GraphNodeWidget>* had = m_live.Find(id))
            {
                widget = *had;
                (void)m_live.Remove(id);
            }
            else
            {
                widget = TakeWidget();
                if (widget->GetParent() != this)
                    AddChild(widget.Get());
            }
            widget->Show(*info);
            widget->SetSelected(Holds(m_selection, id));
            widget->SetHighlighted(Holds(m_highlightedNodes, id));
            const core::Float2 size = widget->Measure(LayoutConstraints{});
            sizes.InsertOrAssign(id, size);
            widget->Arrange(Rect{at.x, at.y, size.x, size.y});
            for (usize i = 0; i < widget->PinRowCount(); ++i) // the pins' places, kept for the links
            {
                const GraphPinRow& row = widget->PinRowAt(i);
                core::Float2 offset{};
                if (widget->PinPoint(row.GetPinId(), offset))
                    m_pins.InsertOrAssign(row.GetPinId(), PinPlace{id, offset, row.GetDirection(), row.GetTypeColor()});
            }
            if (widget->GetScale().x != m_zoom || widget->GetScale().y != m_zoom)
                widget->SetScale(core::Float2{m_zoom, m_zoom});
            if (index < ChildCount() && GetChildAt(index) != widget.Get())
                SetChildIndex(widget.Get(), index); // drawn in the paint order
            ++index;
            if (!reach.Intersects(Rect{at.x, at.y, size.x * m_zoom, size.y * m_zoom}))
                unseen.PushBack(widget.Get());
            live.InsertOrAssign(id, core::Move(widget));
        }
        // Those that left the view (or the graph) go back to the pool, as do those made only to be measured.
        for (auto& entry : m_live)
        {
            RemoveChild(entry.value.Get());
            m_pool.PushBack(core::Move(entry.value));
        }
        for (GraphNodeWidget* widget : unseen)
            if (core::RefPtr<GraphNodeWidget>* held = live.Find(widget->GetNodeId()))
            {
                core::RefPtr<GraphNodeWidget> keep = *held;
                (void)live.Remove(widget->GetNodeId());
                RemoveChild(keep.Get());
                m_pool.PushBack(core::Move(keep));
            }
        m_live = core::Move(live);
        m_sizes = core::Move(sizes);
        core::HashMap<GraphId, PinPlace> pins; // those of nodes gone go
        for (const auto& entry : m_pins)
            if (m_sizes.Find(entry.value.Node) != nullptr)
                pins.InsertOrAssign(entry.key, entry.value);
        m_pins = core::Move(pins);
        ShowLinkStates();
        if (m_fitting)
            Frame(false); // every node measured now; laid out again where that moves them
    }

    // === Gestures ===

    inline void GraphView::OnMouseDown(const MouseEvent& event)
    {
        if (!m_source || (m_drag != Drag::None && !(m_drag == Drag::Link && m_sticky)))
            return;
        m_fitting = false; // the canvas is the user's now
        const core::Float2 local = ConvertToNodeSpace(event.Position); // events come in screen space
        if (event.Button == MouseButton::Middle)
        {
            event.Handled = true;
            m_drag = Drag::Pan;
            m_pressAt = local;
            m_panFrom = m_pan;
            CapturePointer();
            return;
        }
        if (m_drag == Drag::Link && m_sticky) // a link begun from a menu: a click ends it
        {
            event.Handled = true;
            LinkTo(local);
            EndLink(event.Button == MouseButton::Left);
            return;
        }
        if (event.Button != MouseButton::Left)
            return;
        event.Handled = true;
        RequestFocus();
        m_pressAt = local;
        m_boxTo = local;
        m_additive = (event.Modifiers & (KeyModShift | KeyModCtrl)) != 0;
        if (!m_readOnly && BeginLink(local))
        {
            CapturePointer();
            return;
        }
        const GraphId hit = HitNode(local);
        if (hit != 0 && event.ClickCount == 2 && !m_additive)
        {
            SelectOnly(hit);
            if (m_onNodeDoubleClick)
                m_onNodeDoubleClick(hit);
            return;
        }
        const GraphId link = hit == 0 ? HitLink(local) : 0;
        u8 edges = 0;
        bool header = false;
        const GraphId frame = hit == 0 && link == 0 ? HitFrame(local, edges, header) : 0;
        if (!m_additive)
            ReselectLinks(core::Array<GraphId>{});
        m_pressed = 0;
        m_pressedFrame = 0;
        if (hit != 0)
        {
            m_pressed = hit;
            if (!m_additive && !IsNodeSelected(hit))
                ReselectFrames(core::Array<GraphId>{});
            if (m_additive)
                Toggle(hit);
            else if (!IsNodeSelected(hit))
                SelectOnly(hit);
            m_drag = IsNodeSelected(hit) ? Drag::Pending : Drag::None;
        }
        else if (frame != 0 && edges != 0 && !m_readOnly)
        {
            if (!m_additive)
            {
                SelectOnly(0);
                const GraphId only[] = {frame};
                SetSelectedFrames(only);
            }
            GraphFrameInfo info;
            (void)FindFrame(frame, info);
            m_resizeFrame = frame;
            m_resizeEdges = edges;
            m_resizeFrom = Rect{info.Position.x, info.Position.y, info.Size.x, info.Size.y};
            m_resizeTo = m_resizeFrom;
            m_drag = Drag::Resize;
        }
        else if (frame != 0 && header)
        {
            m_pressedFrame = frame;
            if (m_additive)
            {
                core::Array<GraphId> next = m_selectedFrames;
                if (Holds(next, frame))
                {
                    for (usize i = 0; i < next.Size(); ++i)
                        if (next[i] == frame)
                        {
                            next.RemoveAt(i);
                            break;
                        }
                }
                else
                    next.PushBack(frame);
                ReselectFrames(core::Move(next));
            }
            else if (!IsFrameSelected(frame))
            {
                SelectOnly(0);
                const GraphId only[] = {frame};
                SetSelectedFrames(only);
            }
            m_drag = IsFrameSelected(frame) ? Drag::Pending : Drag::None;
        }
        else if (link != 0)
        {
            if (!m_additive)
                SelectOnly(0);
            core::Array<GraphId> next = m_selectedLinks;
            if (Holds(next, link))
            {
                for (usize i = 0; i < next.Size(); ++i)
                    if (next[i] == link)
                    {
                        next.RemoveAt(i);
                        break;
                    }
            }
            else
                next.PushBack(link);
            ReselectLinks(core::Move(next));
            m_drag = Drag::None;
        }
        else
        {
            if (!m_additive)
            {
                SelectOnly(0);
                ReselectFrames(core::Array<GraphId>{});
            }
            m_boxBase = m_selection;
            m_frameBoxBase = m_selectedFrames;
            m_drag = Drag::Box;
        }
        if (link != 0 && !m_additive)
            ReselectFrames(core::Array<GraphId>{});
        if (m_drag != Drag::None)
            CapturePointer();
    }
    inline void GraphView::OnMouseMove(const MouseEvent& event)
    {
        const core::Float2 local = ConvertToNodeSpace(event.Position);
        m_pointer = local;
        m_pointerInside = true;
        if (m_drag == Drag::None || !m_source)
            return;
        switch (m_drag)
        {
        case Drag::Pending:
            if (core::Abs(local.x - m_pressAt.x) < kDragThreshold && core::Abs(local.y - m_pressAt.y) < kDragThreshold)
                return;
            if (m_readOnly)
                return;
            m_drag = Drag::Nodes;
            BeginMove();
            MoveTo(local);
            break;
        case Drag::Nodes:
            MoveTo(local);
            break;
        case Drag::Box:
        {
            m_boxTo = local;
            const Rect area{core::Min(m_pressAt.x, local.x), core::Min(m_pressAt.y, local.y), core::Abs(local.x - m_pressAt.x),
                            core::Abs(local.y - m_pressAt.y)};
            core::Array<GraphId> next = m_boxBase;
            core::Array<GraphId> ids;
            m_source->GetNodes(ids);
            for (const GraphId id : ids)
                if (!Holds(next, id) && area.Intersects(NodeRect(id)))
                    next.PushBack(id);
            Reselect(core::Move(next));
            core::Array<GraphId> frames = m_frameBoxBase; // a frame wholly inside
            core::Array<GraphFrameInfo> all;
            m_source->GetFrames(all);
            for (const GraphFrameInfo& frame : all)
                if (!Holds(frames, frame.Id) && area.Contains(FrameRect(frame.Id)))
                    frames.PushBack(frame.Id);
            ReselectFrames(core::Move(frames));
            Invalidate();
            break;
        }
        case Drag::Link:
            LinkTo(local);
            break;
        case Drag::Resize:
            ResizeTo(local);
            break;
        case Drag::Pan:
            SetPan(core::Float2{m_panFrom.x - (local.x - m_pressAt.x) / m_zoom, m_panFrom.y - (local.y - m_pressAt.y) / m_zoom});
            break;
        default:
            break;
        }
    }
    inline void GraphView::OnMouseUp(const MouseEvent& event)
    {
        if (m_drag == Drag::Pan)
        {
            if (event.Button == MouseButton::Middle)
            {
                m_drag = Drag::None;
                ReleasePointer();
            }
            return;
        }
        if (event.Button != MouseButton::Left)
            return;
        if (m_drag == Drag::Link)
        {
            if (m_sticky)
                return; // the press that began it from a menu, or the one that ended it
            LinkTo(ConvertToNodeSpace(event.Position));
            EndLink(true);
            return;
        }
        if (m_drag == Drag::Pending && !m_additive) // a click on one of several selected selects it alone
        {
            SelectOnly(m_pressed);
            core::Array<GraphId> frames;
            if (m_pressedFrame != 0)
                frames.PushBack(m_pressedFrame);
            ReselectFrames(core::Move(frames));
        }
        EndDrag(true);
    }
    inline void GraphView::OnPointerCancel(const MouseEvent&)
    {
        if (m_drag == Drag::Link)
            EndLink(false);
        else
            EndDrag(false);
    }
    inline void GraphView::OnKeyDown(const KeyEvent& event)
    {
        if (event.Target != this)
            return; // a frame's title being edited types its own keys
        const KeyCode key = static_cast<KeyCode>(event.KeyCode);
        if (key == KeyCode::Escape && (m_drag == Drag::Nodes || m_drag == Drag::Resize))
        {
            event.Handled = true;
            EndDrag(false);
        }
        else if (key == KeyCode::Escape && m_drag == Drag::Link)
        {
            event.Handled = true;
            EndLink(false);
        }
        else if (key == KeyCode::Escape && event.Modifiers == 0 && m_drag == Drag::None &&
                 (!m_selection.IsEmpty() || !m_selectedLinks.IsEmpty() || !m_selectedFrames.IsEmpty()))
        {
            event.Handled = true;
            Reselect(core::Array<GraphId>{});
            ReselectLinks(core::Array<GraphId>{});
            ReselectFrames(core::Array<GraphId>{});
        }
        else if (event.Modifiers == 0 && (key == KeyCode::Delete || key == KeyCode::Backspace) && m_drag == Drag::None)
            event.Handled = DeleteSelected();
        else if (event.Modifiers == KeyModCtrl && key == KeyCode::C && m_drag == Drag::None)
            event.Handled = CopySelected();
        else if (event.Modifiers == KeyModCtrl && key == KeyCode::V && m_drag == Drag::None)
        {
            const Rect box = GetContentBounds();
            const core::Float2 at = m_pointerInside ? m_pointer : core::Float2{box.x + box.width * 0.5f, box.y + box.height * 0.5f};
            event.Handled = PasteAt(ViewToGraph(at));
        }
    }
    inline void GraphView::OnMouseWheel(const WheelEvent& event)
    {
        const f32 steps = event.Delta.y != 0.0f ? event.Delta.y : event.Delta.x;
        if (steps == 0.0f)
            return;
        event.Handled = true;
        SetZoom(m_zoom * core::Pow(1.15f, steps), ConvertToNodeSpace(event.Position));
    }

    inline void GraphView::BeginMove()
    {
        const GraphNodeInfo* pressed = m_source->GetNode(m_pressed);
        m_pressedFrom = pressed != nullptr ? pressed->Position : core::Float2{};
        GraphFrameInfo pressedFrame;
        if (pressed == nullptr && FindFrame(m_pressedFrame, pressedFrame))
            m_pressedFrom = pressedFrame.Position;
        // What moves: the selected nodes and frames, and what lies wholly inside the selected frames.
        m_moveNodes = m_selection;
        m_moveFrames = m_selectedFrames;
        core::Array<GraphFrameInfo> frames;
        m_source->GetFrames(frames);
        core::Array<GraphId> nodes;
        m_source->GetNodes(nodes);
        for (const GraphFrameInfo& frame : frames)
        {
            if (!Holds(m_selectedFrames, frame.Id))
                continue;
            const Rect inside{frame.Position.x, frame.Position.y, frame.Size.x, frame.Size.y};
            for (const GraphId node : nodes)
            {
                const GraphNodeInfo* info = m_source->GetNode(node);
                const core::Float2 size = NodeSize(node);
                if (!Holds(m_moveNodes, node) && inside.Contains(Rect{info->Position.x, info->Position.y, size.x, size.y}))
                    m_moveNodes.PushBack(node);
            }
            for (const GraphFrameInfo& other : frames)
                if (!Holds(m_moveFrames, other.Id) && inside.Contains(Rect{other.Position.x, other.Position.y, other.Size.x, other.Size.y}))
                    m_moveFrames.PushBack(other.Id);
        }
        m_source->BeginMove();
    }
    inline void GraphView::MoveTo(core::Float2 local)
    {
        core::Float2 delta{(local.x - m_pressAt.x) / m_zoom, (local.y - m_pressAt.y) / m_zoom};
        if (m_snap) // the pressed node lands on the grid; the rest keep their places to it
        {
            const f32 x = core::Round((m_pressedFrom.x + delta.x) / m_gridSize) * m_gridSize;
            const f32 y = core::Round((m_pressedFrom.y + delta.y) / m_gridSize) * m_gridSize;
            delta = core::Float2{x - m_pressedFrom.x, y - m_pressedFrom.y};
        }
        m_source->PreviewMove(m_moveNodes.AsSpan(), m_moveFrames.AsSpan(), delta);
    }
    inline void GraphView::EndDrag(bool commit)
    {
        const Drag drag = m_drag;
        m_drag = Drag::None;
        if (drag == Drag::None)
            return;
        ReleasePointer();
        if (drag == Drag::Box)
            Invalidate();
        if (drag == Drag::Resize)
        {
            RequestLayout();
            GraphFrameInfo info;
            const bool changed = m_resizeTo.x != m_resizeFrom.x || m_resizeTo.y != m_resizeFrom.y || m_resizeTo.width != m_resizeFrom.width ||
                                 m_resizeTo.height != m_resizeFrom.height;
            if (commit && changed && FindFrame(m_resizeFrame, info))
            {
                info.Position = core::Float2{m_resizeTo.x, m_resizeTo.y};
                info.Size = core::Float2{m_resizeTo.width, m_resizeTo.height};
                (void)m_source->EditFrame(info);
            }
            return;
        }
        if (drag != Drag::Nodes || !m_source)
            return;
        if (commit)
            m_source->CommitMove();
        else
            m_source->CancelMove();
    }

    inline void GraphView::Frame(bool selectionOnly)
    {
        if (!m_source)
            return;
        core::Array<GraphId> ids;
        if (selectionOnly)
            ids = m_selection;
        else
            m_source->GetNodes(ids);
        bool any = false;
        f32 left = 0.0f, top = 0.0f, right = 0.0f, bottom = 0.0f;
        for (const GraphId id : ids)
        {
            const GraphNodeInfo* info = m_source->GetNode(id);
            if (info == nullptr)
                continue;
            const core::Float2 size = NodeSize(id);
            const f32 l = info->Position.x, t = info->Position.y, r = l + size.x, b = t + size.y;
            left = any ? core::Min(left, l) : l;
            top = any ? core::Min(top, t) : t;
            right = any ? core::Max(right, r) : r;
            bottom = any ? core::Max(bottom, b) : b;
            any = true;
        }
        if (!any)
            return;
        const Rect box = GetContentBounds();
        if (box.width <= 0.0f || box.height <= 0.0f)
            return; // not laid out yet: fitting does it once it is
        const f32 margin = 32.0f;
        const f32 width = right - left + 2.0f * margin, height = bottom - top + 2.0f * margin;
        const f32 zoom = core::Clamp(core::Min(1.0f, core::Min(box.width / width, box.height / height)), m_zoomMin, m_zoomMax);
        const core::Float2 middle{(left + right) * 0.5f, (top + bottom) * 0.5f};
        const core::Float2 pan{middle.x - box.width * 0.5f / zoom, middle.y - box.height * 0.5f / zoom};
        if (core::Abs(zoom - m_zoom) < 1e-5f && core::Abs(pan.x - m_pan.x) < 0.01f && core::Abs(pan.y - m_pan.y) < 0.01f)
            return; // where it is already: nothing to lay out again
        m_zoom = zoom;
        m_pan = pan;
        RequestLayout();
    }

    // === Edits of the selection ===

    inline bool GraphView::DeleteSelected()
    {
        if (!m_source || m_readOnly)
            return false;
        bool any = false;
        if (!m_selection.IsEmpty())
        {
            const core::Array<GraphId> nodes = m_selection;
            any = m_source->DeleteNodes(nodes.AsSpan());
        }
        if (!m_selectedLinks.IsEmpty()) // those the nodes did not take with them
        {
            core::Array<GraphLinkInfo> links;
            m_source->GetLinks(links);
            core::Array<GraphId> left;
            for (const GraphId link : m_selectedLinks)
                for (const GraphLinkInfo& at : links)
                    if (at.Id == link)
                        left.PushBack(link);
            if (!left.IsEmpty())
                any = m_source->Disconnect(left.AsSpan()) || any;
        }
        if (!m_selectedFrames.IsEmpty())
        {
            const core::Array<GraphId> frames = m_selectedFrames;
            any = m_source->DeleteFrames(frames.AsSpan()) || any;
        }
        return any;
    }
    inline bool GraphView::CopySelected()
    {
        EventDispatcher* dispatcher = GetEventDispatcher();
        IClipboard* clipboard = dispatcher != nullptr ? dispatcher->GetClipboard() : nullptr;
        if (!m_source || clipboard == nullptr || m_selection.IsEmpty())
            return false;
        const core::String text = m_source->CopyNodes(m_selection.AsSpan());
        if (text.IsEmpty())
            return false;
        clipboard->SetText(text.AsView());
        return true;
    }
    inline bool GraphView::PasteAt(core::Float2 at)
    {
        EventDispatcher* dispatcher = GetEventDispatcher();
        IClipboard* clipboard = dispatcher != nullptr ? dispatcher->GetClipboard() : nullptr;
        if (!m_source || m_readOnly || clipboard == nullptr || !clipboard->HasText())
            return false;
        const core::String text = clipboard->GetText();
        core::Array<GraphId> made;
        if (!m_source->PasteNodes(text.AsView(), at, made))
            return false;
        Reselect(core::Move(made));
        ReselectLinks(core::Array<GraphId>{});
        return true;
    }
    inline bool GraphView::DuplicateSelected()
    {
        if (!m_source || m_readOnly || m_selection.IsEmpty())
            return false;
        const core::String text = m_source->CopyNodes(m_selection.AsSpan());
        if (text.IsEmpty())
            return false;
        bool any = false;
        core::Float2 corner{};
        for (const GraphId node : m_selection)
            if (const GraphNodeInfo* info = m_source->GetNode(node))
            {
                corner = any ? core::Float2{core::Min(corner.x, info->Position.x), core::Min(corner.y, info->Position.y)} : info->Position;
                any = true;
            }
        core::Array<GraphId> made;
        const f32 step = 2.0f * m_gridSize;
        if (!m_source->PasteNodes(text.AsView(), core::Float2{corner.x + step, corner.y + step}, made))
            return false;
        Reselect(core::Move(made));
        return true;
    }
    inline GraphId GraphView::AddNode(core::StringView type, core::Float2 at, GraphId linkFrom)
    {
        if (!m_source || m_readOnly)
            return 0;
        if (m_snap)
            at = core::Float2{core::Round(at.x / m_gridSize) * m_gridSize, core::Round(at.y / m_gridSize) * m_gridSize};
        const GraphId made = m_source->CreateNode(type, at, linkFrom);
        if (made != 0)
        {
            SelectOnly(made);
            ReselectLinks(core::Array<GraphId>{});
        }
        return made;
    }

    inline GraphId GraphView::AddFrame(core::Float2 at, bool comment)
    {
        if (!m_source || m_readOnly)
            return 0;
        GraphFrameInfo frame;
        frame.Title = core::String(comment ? u8"Comment" : u8"Frame");
        if (comment)
            frame.Body = core::String(u8"Write here");
        frame.Position = at;
        bool any = false;
        f32 left = 0.0f, top = 0.0f, right = 0.0f, bottom = 0.0f;
        for (const GraphId node : m_selection) // around the selected nodes, room for its title above them
            if (const GraphNodeInfo* info = m_source->GetNode(node))
            {
                const core::Float2 size = NodeSize(node);
                left = any ? core::Min(left, info->Position.x) : info->Position.x;
                top = any ? core::Min(top, info->Position.y) : info->Position.y;
                right = any ? core::Max(right, info->Position.x + size.x) : info->Position.x + size.x;
                bottom = any ? core::Max(bottom, info->Position.y + size.y) : info->Position.y + size.y;
                any = true;
            }
        if (any)
        {
            const f32 margin = m_gridSize, above = comment ? 3.0f * m_gridSize : 2.0f * m_gridSize;
            frame.Position = core::Float2{left - margin, top - above};
            frame.Size = core::Float2{right - left + 2.0f * margin, bottom - top + above + margin};
        }
        else if (m_snap)
            frame.Position = core::Float2{core::Round(at.x / m_gridSize) * m_gridSize, core::Round(at.y / m_gridSize) * m_gridSize};
        const GraphId made = m_source->CreateFrame(frame);
        if (made != 0)
        {
            const GraphId only[] = {made};
            SetSelectedFrames(only);
        }
        return made;
    }
    inline void GraphView::ResizeTo(core::Float2 local)
    {
        const f32 dx = (local.x - m_pressAt.x) / m_zoom, dy = (local.y - m_pressAt.y) / m_zoom;
        const auto snap = [this](f32 v) { return m_snap ? core::Round(v / m_gridSize) * m_gridSize : v; };
        const Rect from = m_resizeFrom;
        f32 left = from.x, top = from.y, right = from.Right(), bottom = from.Bottom();
        if ((m_resizeEdges & kEdgeLeft) != 0)
            left = core::Min(snap(from.x + dx), right - kFrameMinWidth);
        if ((m_resizeEdges & kEdgeRight) != 0)
            right = core::Max(snap(from.Right() + dx), left + kFrameMinWidth);
        if ((m_resizeEdges & kEdgeTop) != 0)
            top = core::Min(snap(from.y + dy), bottom - kFrameMinHeight);
        if ((m_resizeEdges & kEdgeBottom) != 0)
            bottom = core::Max(snap(from.Bottom() + dy), top + kFrameMinHeight);
        m_resizeTo = Rect{left, top, right - left, bottom - top};
        RequestLayout();
        Invalidate();
    }
    inline Cursor GraphView::GetCursorNow() const
    {
        if (m_drag == Drag::Pan)
            return Cursor::Grabbing;
        u8 edges = m_drag == Drag::Resize ? m_resizeEdges : 0;
        if (m_drag == Drag::None && m_pointerInside && !m_readOnly && HitNode(m_pointer) == 0 && HitLink(m_pointer) == 0)
        {
            bool header = false;
            (void)HitFrame(m_pointer, edges, header);
        }
        const bool horizontal = (edges & (kEdgeLeft | kEdgeRight)) != 0, vertical = (edges & (kEdgeTop | kEdgeBottom)) != 0;
        if (horizontal && vertical)
        {
            const bool falling = (edges & kEdgeLeft) != 0 ? (edges & kEdgeTop) != 0 : (edges & kEdgeBottom) != 0;
            return falling ? Cursor::NwseResize : Cursor::NeswResize;
        }
        if (horizontal)
            return Cursor::EwResize;
        if (vertical)
            return Cursor::NsResize;
        return UIWidget::GetCursorNow();
    }

    // === Menus ===

    inline void GraphView::PopupAt(Node& popup, core::Float2 local, PopupOptions options)
    {
        EventDispatcher* dispatcher = GetEventDispatcher();
        Node* top = GetRootNode();
        if (dispatcher == nullptr || top == nullptr)
            return;
        const core::Float2 at = top->ConvertToNodeSpace(ConvertToWorldSpace(local));
        options.AnchorRect = Rect{at.x, at.y, 0.0f, 0.0f};
        options.HasAnchorRect = true;
        options.Placement = PopupPlacement{PopupSide::Below, PopupAlign::Start, 0.0f, true};
        dispatcher->OpenPopup(*this, popup, core::Move(options));
    }
    inline bool GraphView::OpenNodePicker(core::Float2 local, GraphId fitting)
    {
        if (!m_source || m_readOnly)
            return false;
        core::Array<GraphNodeType> types;
        m_source->GetNodeTypes(fitting, types);
        if (types.IsEmpty())
            return false;
        if (!m_picker)
            m_picker = core::MakeRef<GraphNodePicker>(MemoryAllocator());
        ShareTextStyle(*m_picker, false);
        m_picker->SetTypes(types.AsSpan());
        m_pickAt = ViewToGraph(local);
        m_pickFrom = fitting;
        GraphView* self = this;
        m_picker->SetOnChosen([self](const GraphNodeType& type)
        {
            const core::String chosen = type.Type;
            if (EventDispatcher* dispatcher = self->GetEventDispatcher())
                (void)dispatcher->ClosePopup(*self->m_picker);
            (void)self->AddNode(chosen.AsView(), self->m_pickAt, self->m_pickFrom);
        });
        PopupOptions options;
        options.TakesFocus = true;
        options.FitContent = true;
        PopupAt(*m_picker, local, core::Move(options));
        return true;
    }
    inline void GraphView::OnContextMenu(const MouseEvent& event)
    {
        if (!m_source || m_drag != Drag::None)
            return;
        event.Handled = true;
        OpenMenu(ConvertToNodeSpace(event.Position), event.Position);
    }
    inline void GraphView::OpenMenu(core::Float2 local, core::Float2 screen)
    {
        Node* top = GetRootNode();
        if (top == nullptr)
            return;
        m_menu = core::MakeRef<Menu>(MemoryAllocator());
        ShareTextStyle(*m_menu, false);
        m_menu->SetAutoWidth(true);
        GraphView* self = this;
        const GraphId node = HitNode(local);
        const GraphId link = node == 0 ? HitLink(local) : 0;
        u8 edges = 0;
        bool header = false;
        const GraphId frame = node == 0 && link == 0 ? HitFrame(local, edges, header) : 0;
        if (frame != 0 && header)
        {
            if (m_readOnly)
                return;
            if (!IsFrameSelected(frame))
            {
                SelectOnly(0);
                ReselectLinks(core::Array<GraphId>{});
                const GraphId only[] = {frame};
                SetSelectedFrames(only);
            }
            m_menu->AddItem(core::StringView(u8"Rename"), [self, frame]()
            {
                if (GraphFrameWidget* widget = self->GetFrameWidget(frame))
                    widget->GetTitleLabel().BeginEdit();
            });
            m_menu->AddItem(core::StringView(u8"Edit comment"), [self, frame]()
            {
                if (GraphFrameWidget* widget = self->GetFrameWidget(frame))
                    widget->EditBody();
            });
            m_menu->AddSeparator();
            m_menu->AddItem(core::StringView(u8"Delete"), [self]() { (void)self->DeleteSelected(); });
        }
        else if (node != 0)
        {
            if (!IsNodeSelected(node))
            {
                SelectOnly(node);
                ReselectLinks(core::Array<GraphId>{});
            }
            m_menu->AddItem(core::StringView(u8"Copy"), [self]() { (void)self->CopySelected(); });
            if (!m_readOnly)
            {
                m_menu->AddItem(core::StringView(u8"Duplicate"), [self]() { (void)self->DuplicateSelected(); });
                bool deletable = false;
                for (const GraphId at : m_selection)
                    if (const GraphNodeInfo* info = m_source->GetNode(at))
                        deletable = deletable || info->Deletable;
                m_menu->AddItem(core::StringView(u8"Delete"), [self]() { (void)self->DeleteSelected(); })->SetEnabled(deletable);
                GraphLinkInfo begin;
                begin.Kind = GraphLinkKind::Nodes;
                begin.FromNode = node;
                if (m_source->CheckLink(begin).Allowed)
                    m_menu->AddItem(core::StringView(u8"Add transition"), [self, node]() { (void)self->BeginNodeLink(node); });
            }
            m_menu->AddSeparator();
            m_menu->AddItem(core::StringView(u8"Frame selection"), [self]() { self->FrameSelection(); });
        }
        else if (link != 0)
        {
            if (m_readOnly)
                return;
            if (!IsLinkSelected(link))
            {
                SelectOnly(0);
                const GraphId only[] = {link};
                SetSelectedLinks(only);
            }
            m_menu->AddItem(core::StringView(u8"Delete"), [self]() { (void)self->DeleteSelected(); });
        }
        else
        {
            if (!m_readOnly)
            {
                core::Array<GraphNodeType> types;
                m_source->GetNodeTypes(0, types);
                m_menu->AddItem(core::StringView(u8"Add node\u2026"), [self, local]() { (void)self->OpenNodePicker(local); })->SetEnabled(!types.IsEmpty());
                EventDispatcher* dispatcher = GetEventDispatcher();
                IClipboard* clipboard = dispatcher != nullptr ? dispatcher->GetClipboard() : nullptr;
                const core::Float2 at = ViewToGraph(local);
                m_menu->AddItem(core::StringView(u8"Paste"), [self, at]() { (void)self->PasteAt(at); })->SetEnabled(clipboard != nullptr && clipboard->HasText());
                m_menu->AddItem(core::StringView(u8"Add frame"), [self, at]() { (void)self->AddFrame(at); });
                m_menu->AddItem(core::StringView(u8"Add comment"), [self, at]() { (void)self->AddFrame(at, true); });
                m_menu->AddSeparator();
            }
            m_menu->AddItem(core::StringView(u8"Frame all"), [self]() { self->FrameAll(); });
            m_menu->AddItem(core::StringView(u8"Frame selection"), [self]() { self->FrameSelection(); })->SetEnabled(!m_selection.IsEmpty());
        }
        m_menu->Open(*this, top->ConvertToNodeSpace(screen));
    }

    // === Links ===

    inline bool GraphView::BeginLink(core::Float2 local)
    {
        m_relinking = 0;
        m_relinkFrom = 0;
        m_target = 0;
        m_targetCheck = GraphLinkCheck{};
        m_linkMoved = false;
        m_leftAnchor = false;
        m_linkTo = local;
        m_fits.Clear();
        GraphLinkInfo begin;
        if (const GraphId pin = HitPin(local); pin != 0)
        {
            const PinPlace& place = *m_pins.Find(pin);
            m_linkKind = GraphLinkKind::Pins;
            // An input with a link: its end is taken (the last made), to rewire it or let it go.
            if (place.Direction == GraphPinDirection::Input)
            {
                core::Array<GraphLinkInfo> links;
                m_source->GetLinks(links);
                for (const GraphLinkInfo& link : links)
                    if (link.Kind == GraphLinkKind::Pins && link.ToPin == pin)
                    {
                        m_relinking = link.Id;
                        m_anchorNode = link.FromNode;
                        m_anchorPin = link.FromPin;
                    }
            }
            if (m_relinking != 0)
            {
                m_relinkFrom = pin;
                m_anchorOutput = true;
            }
            else
            {
                m_anchorNode = place.Node;
                m_anchorPin = pin;
                m_anchorOutput = place.Direction == GraphPinDirection::Output;
                begin.FromNode = place.Node;
                begin.FromPin = pin;
                if (!m_source->CheckLink(begin).Allowed)
                    return false;
            }
            // Each pin asked once: where this link may end.
            for (const auto& entry : m_pins)
            {
                if (entry.key == m_anchorPin)
                    continue;
                const bool fits = entry.key == m_relinkFrom || m_source->CheckLink(Candidate(entry.key)).Allowed;
                m_fits.InsertOrAssign(entry.key, fits);
            }
        }
        else if (const GraphId node = HitNodeEdge(local); node != 0)
        {
            m_pressAt = local;
            return BeginNodeLinkFrom(node);
        }
        else
            return false;
        m_drag = Drag::Link;
        m_pressAt = local;
        ShowLinkStates();
        Invalidate();
        return true;
    }
    inline bool GraphView::BeginNodeLinkFrom(GraphId node)
    {
        GraphLinkInfo begin;
        begin.Kind = GraphLinkKind::Nodes;
        begin.FromNode = node;
        if (!m_source->CheckLink(begin).Allowed)
            return false;
        m_linkKind = GraphLinkKind::Nodes;
        m_anchorNode = node;
        m_anchorPin = 0;
        m_anchorOutput = true;
        core::Array<GraphId> ids;
        m_source->GetNodes(ids);
        for (const GraphId id : ids)
            m_fits.InsertOrAssign(id, m_source->CheckLink(Candidate(id)).Allowed);
        m_drag = Drag::Link;
        ShowLinkStates();
        Invalidate();
        return true;
    }
    inline bool GraphView::BeginNodeLink(GraphId node)
    {
        if (!m_source || m_readOnly || m_drag != Drag::None || m_source->GetNode(node) == nullptr)
            return false;
        m_relinking = 0;
        m_relinkFrom = 0;
        m_target = 0;
        m_targetCheck = GraphLinkCheck{};
        m_leftAnchor = false;
        m_fits.Clear();
        const Rect at = NodeRect(node);
        m_linkTo = m_pointerInside ? m_pointer : core::Float2{at.Right(), at.y};
        m_pressAt = m_linkTo;
        if (!BeginNodeLinkFrom(node))
            return false;
        m_sticky = true;
        m_linkMoved = true;
        RequestFocus();
        CapturePointer();
        return true;
    }
    inline void GraphView::LinkTo(core::Float2 local)
    {
        m_linkTo = local;
        if (!m_linkMoved && core::Abs(local.x - m_pressAt.x) < kDragThreshold && core::Abs(local.y - m_pressAt.y) < kDragThreshold)
            return;
        m_linkMoved = true;
        GraphId target = 0;
        if (m_linkKind == GraphLinkKind::Pins)
        {
            target = NearestPin(local, core::Max(PinReach(), 14.0f));
            if (target == m_anchorPin)
                target = 0;
        }
        else
        {
            target = HitNode(local);
            if (target != m_anchorNode && HitNodeEdge(local) != m_anchorNode)
                m_leftAnchor = true;
            if (target == m_anchorNode && !m_leftAnchor) // to itself only once it has left and come back
                target = 0;
        }
        if (target != m_target)
        {
            m_target = target;
            m_targetCheck = GraphLinkCheck{};
            if (target != 0 && target == m_relinkFrom)
                m_targetCheck.Allowed = true; // back where it came from: nothing changes
            else if (target != 0)
                m_targetCheck = m_source->CheckLink(Candidate(target));
            ShowLinkStates();
        }
        Invalidate();
    }
    inline void GraphView::EndLink(bool commit)
    {
        if (m_drag != Drag::Link)
            return;
        m_drag = Drag::None;
        m_sticky = false;
        const GraphId target = m_target;
        const GraphLinkCheck check = m_targetCheck;
        m_target = 0;
        m_targetCheck = GraphLinkCheck{};
        m_fits.Clear();
        ShowLinkStates();
        ReleasePointer();
        Invalidate();
        if (!commit || !m_linkMoved || !m_source)
            return;
        if (target == 0)
        {
            if (m_relinking != 0) // an end dropped on nothing lets the link go
            {
                const GraphId gone[] = {m_relinking};
                (void)m_source->Disconnect(gone);
            }
            else if (m_linkKind == GraphLinkKind::Pins) // a new one: the kinds of node it may reach
                (void)OpenNodePicker(m_linkTo, m_anchorPin);
            return;
        }
        if (!check.Allowed || target == m_relinkFrom)
            return;
        if (m_relinking != 0)
            (void)m_source->Relink(m_relinking, Candidate(target));
        else
            (void)m_source->Connect(Candidate(target));
    }
    inline void GraphView::ShowLinkStates()
    {
        const bool linking = m_drag == Drag::Link;
        const auto stateOf = [this, linking](GraphId id, bool kind) -> GraphLinkState
        {
            if (!linking || !kind)
                return GraphLinkState::None;
            const bool* fits = m_fits.Find(id);
            if (fits == nullptr)
                return GraphLinkState::None;
            if (id == m_target && m_targetCheck.Allowed)
                return GraphLinkState::Target;
            return *fits ? GraphLinkState::Fits : GraphLinkState::Refused;
        };
        for (const auto& entry : m_live)
        {
            GraphNodeWidget& widget = *entry.value;
            widget.SetLinkState(stateOf(entry.key, m_linkKind == GraphLinkKind::Nodes));
            for (usize i = 0; i < widget.PinRowCount(); ++i)
            {
                GraphPinRow& row = widget.PinRowAt(i);
                row.SetLinkState(stateOf(row.GetPinId(), m_linkKind == GraphLinkKind::Pins));
            }
        }
    }

    inline void GraphView::CurvePoints(core::Float2 from, core::Float2 to, core::Array<core::Float2>& out) const
    {
        const f32 reach = core::Max(30.0f * m_zoom, core::Abs(to.x - from.x) * 0.5f);
        const core::Float2 c0{from.x + reach, from.y}; // out of an output's right, into an input's left
        const core::Float2 c1{to.x - reach, to.y};
        constexpr i32 kSteps = 32;
        for (i32 i = 0; i <= kSteps; ++i)
        {
            const f32 t = static_cast<f32>(i) / static_cast<f32>(kSteps);
            const f32 u = 1.0f - t;
            const f32 a = u * u * u, b = 3.0f * u * u * t, c = 3.0f * u * t * t, d = t * t * t;
            out.PushBack(core::Float2{a * from.x + b * c0.x + c * c1.x + d * to.x, a * from.y + b * c0.y + c * c1.y + d * to.y});
        }
    }
    inline void GraphView::EdgePoints(const Rect& from, const Rect& to, f32 gap, core::Array<core::Float2>& out) const
    {
        const core::Float2 a{from.x + from.width * 0.5f, from.y + from.height * 0.5f};
        const core::Float2 b{to.x + to.width * 0.5f, to.y + to.height * 0.5f};
        f32 dx = b.x - a.x, dy = b.y - a.y;
        const f32 length = core::Sqrt(dx * dx + dy * dy);
        if (length < 1e-3f) // a node to itself: a loop over its top right corner
        {
            const f32 side = from.Right() - 24.0f * m_zoom;
            const f32 lift = 36.0f * m_zoom, spread = 14.0f * m_zoom;
            const core::Float2 start{side - spread, from.y}, end{side + spread, from.y};
            const core::Float2 c0{start.x - spread, from.y - lift}, c1{end.x + spread, from.y - lift};
            constexpr i32 kSteps = 24;
            for (i32 i = 0; i <= kSteps; ++i)
            {
                const f32 t = static_cast<f32>(i) / static_cast<f32>(kSteps);
                const f32 u = 1.0f - t;
                const f32 p = u * u * u, q = 3.0f * u * u * t, r = 3.0f * u * t * t, w = t * t * t;
                out.PushBack(core::Float2{p * start.x + q * c0.x + r * c1.x + w * end.x, p * start.y + q * c0.y + r * c1.y + w * end.y});
            }
            return;
        }
        dx /= length;
        dy /= length;
        const core::Float2 side{-dy * gap, dx * gap}; // to the edge's right, so its reverse lies apart
        // Where the line from the middle leaves each box.
        const auto exitAt = [](const Rect& box, f32 x, f32 y)
        {
            const f32 hx = box.width * 0.5f, hy = box.height * 0.5f;
            const f32 tx = core::Abs(x) > 1e-6f ? hx / core::Abs(x) : 1e30f;
            const f32 ty = core::Abs(y) > 1e-6f ? hy / core::Abs(y) : 1e30f;
            return core::Min(tx, ty);
        };
        const f32 leave = exitAt(from, dx, dy), arrive = exitAt(to, dx, dy);
        out.PushBack(core::Float2{a.x + dx * leave + side.x, a.y + dy * leave + side.y});
        out.PushBack(core::Float2{b.x - dx * arrive + side.x, b.y - dy * arrive + side.y});
    }

    inline bool GraphView::LinkPoints(const GraphLinkInfo& link, core::Array<core::Float2>& out) const
    {
        out.Clear();
        if (!m_source)
            return false;
        if (link.Kind == GraphLinkKind::Nodes)
        {
            if (m_source->GetNode(link.FromNode) == nullptr || m_source->GetNode(link.ToNode) == nullptr)
                return false;
            // Apart from its reverse; a second the same way further apart again.
            f32 gap = 0.0f;
            usize before = 0;
            bool reverse = false;
            core::Array<GraphLinkInfo> links;
            m_source->GetLinks(links);
            for (const GraphLinkInfo& at : links)
            {
                if (at.Kind != GraphLinkKind::Nodes || link.FromNode == link.ToNode)
                    continue;
                if (at.FromNode == link.ToNode && at.ToNode == link.FromNode)
                    reverse = true;
                if (at.FromNode == link.FromNode && at.ToNode == link.ToNode && at.Id < link.Id)
                    ++before;
            }
            if (reverse || before > 0)
                gap = kParallelGap * (1.0f + 2.0f * static_cast<f32>(before));
            EdgePoints(NodeRect(link.FromNode), NodeRect(link.ToNode), gap, out);
            return true;
        }
        core::Float2 from{}, to{};
        if (!PinPoint(link.FromPin, from) || !PinPoint(link.ToPin, to))
            return false;
        CurvePoints(from, to, out);
        return true;
    }
    inline GraphId GraphView::HitLink(core::Float2 local) const
    {
        if (!m_source)
            return 0;
        core::Array<GraphLinkInfo> links;
        m_source->GetLinks(links);
        core::Array<core::Float2> points;
        for (usize l = links.Size(); l-- > 0;)
        {
            if (!LinkPoints(links[l], points))
                continue;
            for (usize i = 1; i < points.Size(); ++i)
            {
                const core::Float2 a = points[i - 1], b = points[i];
                const f32 vx = b.x - a.x, vy = b.y - a.y;
                const f32 lengthSq = vx * vx + vy * vy;
                f32 t = lengthSq > 0.0f ? ((local.x - a.x) * vx + (local.y - a.y) * vy) / lengthSq : 0.0f;
                t = core::Clamp(t, 0.0f, 1.0f);
                const f32 dx = a.x + vx * t - local.x, dy = a.y + vy * t - local.y;
                if (dx * dx + dy * dy <= kLinkReach * kLinkReach)
                    return links[l].Id;
            }
        }
        return 0;
    }
    inline void GraphView::StrokeLine(DrawContext& ctx, core::Span<const core::Float2> points, Color color, f32 width, bool arrow) const
    {
        if (points.Size() < 2)
            return;
        vg::PathBuilder line;
        line.MoveTo(points[0].x, points[0].y);
        for (usize i = 1; i < points.Size(); ++i)
            line.LineTo(points[i].x, points[i].y);
        ctx.VG().StrokePath(line.ToPath(), color, vg::StrokeStyle(width));
        if (!arrow)
            return;
        // Its head at the end, along the last stretch.
        const core::Float2 tip = points[points.Size() - 1], back = points[points.Size() - 2];
        f32 dx = tip.x - back.x, dy = tip.y - back.y;
        const f32 length = core::Sqrt(dx * dx + dy * dy);
        if (length < 1e-4f)
            return;
        dx /= length;
        dy /= length;
        const f32 size = core::Clamp(9.0f * m_zoom, 6.0f, 14.0f);
        vg::PathBuilder head;
        head.MoveTo(tip.x, tip.y);
        head.LineTo(tip.x - dx * size - dy * size * 0.55f, tip.y - dy * size + dx * size * 0.55f);
        head.LineTo(tip.x - dx * size + dy * size * 0.55f, tip.y - dy * size - dx * size * 0.55f);
        head.Close();
        ctx.VG().FillPath(head.ToPath(), color);
    }

    // === Drawing ===

    inline void GraphView::OnDraw(DrawContext& ctx, const Rect& localBounds)
    {
        UIWidget::OnDraw(ctx, localBounds);
        const Rect box = GetContentBounds();
        ctx.PushClip(box);
        const auto partColor = [this](const char8_t* name, Color fallback)
        {
            const PartStyle& part = GetPartStyle(name);
            Color color = part.HasBackground ? part.Box.BackgroundColor : fallback;
            color.a *= part.Opacity;
            return color;
        };
        // The grid: a line each cell while they stand apart, and a stronger one each eighth.
        const Color minor = partColor(u8"grid", Color{1.0f, 1.0f, 1.0f, 0.04f});
        const Color major = partColor(u8"grid-major", Color{1.0f, 1.0f, 1.0f, 0.09f});
        const f32 cell = m_gridSize * m_zoom;
        const bool fine = cell >= 6.0f;
        const f32 step = fine ? m_gridSize : m_gridSize * 8.0f;
        const core::Float2 first = ViewToGraph(core::Float2{box.x, box.y});
        const core::Float2 last = ViewToGraph(core::Float2{box.Right(), box.Bottom()});
        for (i64 i = static_cast<i64>(core::Floor(first.x / step)); static_cast<f32>(i) * step <= last.x; ++i)
        {
            const bool strong = !fine || i % 8 == 0;
            const f32 x = GraphToView(core::Float2{static_cast<f32>(i) * step, 0.0f}).x;
            ctx.VG().FillRect(Rectangle{core::Floor(x), box.y, 1.0f, box.height}, strong ? major : minor);
        }
        for (i64 i = static_cast<i64>(core::Floor(first.y / step)); static_cast<f32>(i) * step <= last.y; ++i)
        {
            const bool strong = !fine || i % 8 == 0;
            const f32 y = GraphToView(core::Float2{0.0f, static_cast<f32>(i) * step}).y;
            ctx.VG().FillRect(Rectangle{box.x, core::Floor(y), box.width, 1.0f}, strong ? major : minor);
        }
        // The frames' boxes, under the links: tinted, their title bands more so.
        if (m_source)
        {
            core::Array<GraphFrameInfo> frames;
            m_source->GetFrames(frames);
            const vg::CornerRadii round(core::Clamp(4.0f * m_zoom, 1.0f, 6.0f));
            for (const GraphFrameInfo& frame : frames)
            {
                const Rect r = FrameRect(frame.Id);
                if (!box.Intersects(r))
                    continue;
                ctx.VG().FillRoundedRect(r.ToRectangle(), round, frame.Tint);
                const GraphFrameWidget* widget = GetFrameWidget(frame.Id);
                const f32 band = core::Min(r.height, (widget != nullptr ? widget->HeaderHeight() : GraphFrameWidget::kHeaderMin) * m_zoom);
                Color strong = frame.Tint;
                strong.a = core::Min(1.0f, strong.a * 1.8f);
                vg::CornerRadii top = round;
                top.bottomLeft = top.bottomRight = 0.0f;
                ctx.VG().FillRoundedRect(Rectangle{r.x, r.y, r.width, band}, top, strong);
            }
        }
        // The links, under the nodes, each culled to the view; one being rewired is drawn as the drag.
        if (m_source)
        {
            const Color nodeLink = partColor(u8"node-link", Color{0.8f, 0.82f, 0.88f, 1.0f});
            const Color selected = partColor(u8"link-selected", Color{1.0f, 1.0f, 1.0f, 1.0f});
            const Color highlight = partColor(u8"link-highlight", Color{1.0f, 0.65f, 0.2f, 1.0f});
            const f32 width = core::Clamp(2.0f * m_zoom, 1.0f, 3.0f);
            core::Array<GraphLinkInfo> links;
            m_source->GetLinks(links);
            core::Array<core::Float2> points;
            const bool replacing = m_drag == Drag::Link && m_targetCheck.Allowed;
            for (const GraphLinkInfo& link : links)
            {
                if ((m_drag == Drag::Link && m_linkMoved && link.Id == m_relinking) || !LinkPoints(link, points))
                    continue;
                f32 left = points[0].x, right = left, top = points[0].y, bottom = top;
                for (const core::Float2& p : points)
                {
                    left = core::Min(left, p.x);
                    right = core::Max(right, p.x);
                    top = core::Min(top, p.y);
                    bottom = core::Max(bottom, p.y);
                }
                if (!box.Intersects(Rect{left - 8.0f, top - 8.0f, right - left + 16.0f, bottom - top + 16.0f}))
                    continue;
                Color color = nodeLink;
                if (link.Kind == GraphLinkKind::Pins)
                    if (const PinPlace* place = m_pins.Find(link.FromPin))
                        color = place->TypeColor;
                f32 stroke = width;
                if (Holds(m_highlightedLinks, link.Id))
                {
                    color = highlight;
                    stroke = width + 1.5f;
                }
                if (Holds(m_selectedLinks, link.Id))
                {
                    color = selected;
                    stroke = width + 1.0f;
                }
                if (replacing && Holds(m_targetCheck.Replaces, link.Id))
                    color.a *= 0.3f; // about to be replaced
                StrokeLine(ctx, points.AsSpan(), color, stroke, link.Kind == GraphLinkKind::Nodes);
            }
        }
        ctx.PopClip();
    }
    inline void GraphView::OnDrawAbove(DrawContext& ctx)
    {
        if (m_drag == Drag::Link && m_linkMoved && m_source)
        {
            ctx.PushClip(GetContentBounds());
            const PartStyle& part = GetPartStyle(u8"link-drag");
            Color color = part.HasBackground ? part.Box.BackgroundColor : Color{1.0f, 1.0f, 1.0f, 0.85f};
            color.a *= part.Opacity;
            const f32 width = core::Clamp(2.0f * m_zoom, 1.0f, 3.0f);
            core::Array<core::Float2> points;
            if (m_linkKind == GraphLinkKind::Nodes)
            {
                const Rect from = NodeRect(m_anchorNode);
                const Rect to = m_target != 0 && m_targetCheck.Allowed ? NodeRect(m_target) : Rect{m_linkTo.x, m_linkTo.y, 0.0f, 0.0f};
                EdgePoints(from, to, 0.0f, points);
                StrokeLine(ctx, points.AsSpan(), color, width, true);
            }
            else
            {
                core::Float2 anchor{}, carried = m_linkTo;
                if (m_target != 0 && m_targetCheck.Allowed)
                    (void)PinPoint(m_target, carried); // it snaps to the pin it would end at
                if (PinPoint(m_anchorPin, anchor))
                {
                    if (m_anchorOutput)
                        CurvePoints(anchor, carried, points);
                    else
                        CurvePoints(carried, anchor, points);
                    if (const PinPlace* place = m_pins.Find(m_anchorPin))
                        color = Color{place->TypeColor.r, place->TypeColor.g, place->TypeColor.b, color.a};
                    StrokeLine(ctx, points.AsSpan(), color, width, false);
                }
            }
            // Why not, beside the pointer.
            if (m_target != 0 && !m_targetCheck.Allowed && !m_targetCheck.Reason.IsEmpty() && m_text.HasFont())
            {
                m_text.SetString(m_targetCheck.Reason.AsView());
                const core::Float2 size = m_text.Measure();
                const Rect note{m_linkTo.x + 14.0f, m_linkTo.y + 10.0f, size.x + 12.0f, size.y + 6.0f};
                const PartStyle& tip = GetPartStyle(u8"link-refused");
                Color back = tip.HasBackground ? tip.Box.BackgroundColor : Color{0.45f, 0.12f, 0.12f, 0.95f};
                back.a *= tip.Opacity;
                ctx.VG().FillRoundedRect(note.ToRectangle(), 4.0f, back);
                m_text.Draw(ctx, core::Float2{note.x + 6.0f, note.y + 3.0f});
            }
            ctx.PopClip();
            return;
        }
        if (m_drag != Drag::Box)
            return;
        const PartStyle& part = GetPartStyle(u8"selection-box");
        Color fill = part.HasBackground ? part.Box.BackgroundColor : Color{0.31f, 0.61f, 1.0f, 0.2f};
        fill.a *= part.Opacity;
        const Rect area{core::Min(m_pressAt.x, m_boxTo.x), core::Min(m_pressAt.y, m_boxTo.y), core::Abs(m_boxTo.x - m_pressAt.x),
                        core::Abs(m_boxTo.y - m_pressAt.y)};
        ctx.PushClip(GetContentBounds());
        ctx.VG().FillRect(area.ToRectangle(), fill);
        ctx.PopClip();
    }
}
