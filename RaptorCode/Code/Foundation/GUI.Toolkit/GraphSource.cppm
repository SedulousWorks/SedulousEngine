// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - :graph_source partition
//
// What a graph view reads (T6 of Specs/gui-lab-evolution-3.md): nodes, their pins, links and frames,
// each by a stable id the source gives, so nothing shifts when one goes (foundation.ui's canvas
// addressed its graph by index, a removal shifting the rest). Edits are requests the source applies,
// as the property and curve sources' are: a move is a gesture (begun, previewed, committed once or
// cancelled); connecting, relinking, disconnecting, deleting, creating a node and a frame's edits are
// one change each; copying writes the source's text and pasting reads it back. The undo is the
// application's.
//
// A link is asked for before it is made (ezEngine): the source says whether it may be and why not,
// and which links it would replace, so a view can light the pins that fit while one is dragged.
// Links join two pins (dataflow) or two nodes (a state machine's transitions).
//
// GraphSet is a source of its own graph in memory: what tests and a page without a graph of its own
// edit, each change told to whoever keeps the undo as the graph before and after.

module;
#include "Core/Prelude.h"

export module foundation.gui.toolkit:graph_source;

import foundation.core;
import foundation.gui;
import :reflected_source; // IPropertyTextFormat: the application's serializer, for copies

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    /// A node's, a pin's, a link's or a frame's id, the source's to give; 0 is none.
    using GraphId = u64;

    enum class GraphPinDirection : u8
    {
        Input,
        Output,
    };

    struct GraphPinInfo
    {
        GraphId Id = 0;
        core::String Name;
        GraphPinDirection Direction = GraphPinDirection::Input;
        core::String Type;         ///< what it carries ("float", "color"); empty: anything
        Color TypeColor{0.7f, 0.7f, 0.75f, 1.0f};
        bool Many = false;         ///< it takes several links (an output, as a rule); else one
    };

    struct GraphNodeInfo
    {
        GraphId Id = 0;
        core::String Type;         ///< the kind of node it is, one of the source's node types
        core::String Title;
        core::String Subtitle;
        core::Float2 Position{};   ///< its top-left in the graph's space
        Color HeaderColor{0.27f, 0.47f, 0.73f, 1.0f};
        bool Movable = true;
        bool Deletable = true;
        core::Array<GraphPinInfo> Pins; ///< inputs and outputs, each in its order
    };

    enum class GraphLinkKind : u8
    {
        Pins,  ///< an output pin to an input pin (dataflow)
        Nodes, ///< a node to a node (a state machine's transition)
    };

    struct GraphLinkInfo
    {
        GraphId Id = 0;
        GraphLinkKind Kind = GraphLinkKind::Pins;
        GraphId FromNode = 0;
        GraphId FromPin = 0; ///< none for a node link
        GraphId ToNode = 0;
        GraphId ToPin = 0;
    };

    /// A titled, coloured rectangle behind nodes (with a body: a comment).
    struct GraphFrameInfo
    {
        GraphId Id = 0;
        core::String Title;
        core::String Body;
        core::Float2 Position{};
        core::Float2 Size{200.0f, 120.0f};
        Color Tint{0.35f, 0.4f, 0.5f, 0.35f};
    };

    /// What a source says of a link asked for.
    struct GraphLinkCheck
    {
        bool Allowed = false;
        core::String Reason;             ///< why not, when it is not
        core::Array<GraphId> Replaces;   ///< the links it would take the place of
    };

    /// A kind of node the source can make, for a view's menu.
    struct GraphNodeType
    {
        core::String Type;
        core::String Name;
        core::String Category;
    };

    class IGraphSourceClient
    {
    public:
        virtual ~IGraphSourceClient() = default;
        /// Nodes, pins, links or frames changed: read them again.
        virtual void OnGraphChanged() = 0;
    };

    class IGraphSource
    {
    public:
        virtual ~IGraphSource() = default;

        // === What there is ===
        virtual void GetNodes(core::Array<GraphId>& out) const = 0;
        /// The node `node`; null when there is none.
        [[nodiscard]] virtual const GraphNodeInfo* GetNode(GraphId node) const = 0;
        virtual void GetLinks(core::Array<GraphLinkInfo>& out) const = 0;
        virtual void GetFrames(core::Array<GraphFrameInfo>& out) const = 0;

        // === Moving (a gesture) ===
        /// A move begins: where the nodes and frames are now is what a preview moves from.
        virtual void BeginMove() = 0;
        /// `nodes` and `frames` by `delta` from where they were at the beginning, live.
        virtual void PreviewMove(core::Span<const GraphId> nodes, core::Span<const GraphId> frames, core::Float2 delta) = 0;
        virtual void CommitMove() = 0;
        virtual void CancelMove() = 0;

        // === Links ===
        /// Whether `link` (its id unset) may be made, and what it would replace. With no `To` end
        /// (ToNode 0): whether a link may begin at its `From` end, a pin of either direction or, for a
        /// node link, a node (what a view asks before it lets one be dragged from there).
        [[nodiscard]] virtual GraphLinkCheck CheckLink(const GraphLinkInfo& link) const = 0;
        /// Makes `link` as CheckLink said (taking the place of what it replaces), one change; its
        /// id, 0 when it may not be.
        virtual GraphId Connect(const GraphLinkInfo& link) = 0;
        /// Moves link `link`'s ends to `to`'s, one change; false when it may not be.
        virtual bool Relink(GraphId link, const GraphLinkInfo& to) = 0;
        /// Removes `links`, one change; false when none went.
        virtual bool Disconnect(core::Span<const GraphId> links) = 0;

        // === Nodes ===
        /// Deletes `nodes` (the deletable among them) and their links, one change; false when none went.
        virtual bool DeleteNodes(core::Span<const GraphId> nodes) = 0;
        /// The kinds of node it makes; with `fitting`, a pin, only those with a pin a link from it may reach.
        virtual void GetNodeTypes(GraphId fittingPin, core::Array<GraphNodeType>& out) const = 0;
        /// Makes a node of `type` at `at`; with `linkFrom`, a pin, links it to the new node's first pin
        /// that fits, in the same change. Its id, 0 when it cannot.
        virtual GraphId CreateNode(core::StringView type, core::Float2 at, GraphId linkFrom) = 0;

        // === Frames ===
        /// Makes a frame, one change; its id.
        virtual GraphId CreateFrame(const GraphFrameInfo& frame) = 0;
        /// Sets a frame's title, body, place, size and tint, one change; false when nothing changed.
        virtual bool EditFrame(const GraphFrameInfo& frame) = 0;
        virtual bool DeleteFrames(core::Span<const GraphId> frames) = 0;

        // === The clipboard ===
        /// `nodes` and the links among them as the source's text; empty when it cannot copy.
        [[nodiscard]] virtual core::String CopyNodes(core::Span<const GraphId> nodes) const = 0;
        /// Reads `text` (CopyNodes') back as new nodes, their top-left at `at`, one change; `made` the
        /// new nodes' ids. False when it is not the source's.
        virtual bool PasteNodes(core::StringView text, core::Float2 at, core::Array<GraphId>& made) = 0;

        void AddGraphClient(IGraphSourceClient* client) { m_clients.PushBack(client); }
        void RemoveGraphClient(IGraphSourceClient* client)
        {
            for (usize i = 0; i < m_clients.Size(); ++i)
                if (m_clients[i] == client)
                {
                    m_clients.RemoveAt(i);
                    return;
                }
        }

    protected:
        void NotifyGraphChanged()
        {
            for (usize i = 0; i < m_clients.Size(); ++i)
                m_clients[i]->OnGraphChanged();
        }

    private:
        core::Array<IGraphSourceClient*> m_clients; // non-owning: each view leaves as it goes
    };

    /// A graph's whole state: what a GraphSet change holds before and after.
    struct GraphState
    {
        core::Array<GraphNodeInfo> Nodes;
        core::Array<GraphLinkInfo> Links;
        core::Array<GraphFrameInfo> Frames;
        GraphId NextId = 1;
    };
    struct GraphChange
    {
        core::String Words;
        GraphState Before;
        GraphState After;
    };

    /// A graph of its own, in memory. Its node types are templates the page adds; a pin's type
    /// decides what links to it (the same type, or either empty); an input takes one link unless it
    /// says many, a new one replacing the old. Its nodes link to each other only where the page says.
    class GraphSet : public IGraphSource
    {
    public:
        /// A kind of node it makes: a template whose pins (ids unset) each new node copies.
        void AddNodeType(const GraphNodeType& type, const GraphNodeInfo& node)
        {
            m_types.PushBack(Template{type, node});
        }
        /// Adds a node from code (its pins given ids here), no change told; its id.
        GraphId AddNode(GraphNodeInfo node)
        {
            node.Id = Next();
            for (GraphPinInfo& pin : node.Pins)
                pin.Id = Next();
            m_state.Nodes.PushBack(core::Move(node));
            NotifyGraphChanged();
            return m_state.Nodes.Back().Id;
        }
        /// Adds a link from code, unchecked, no change told; its id.
        GraphId AddLink(GraphLinkInfo link)
        {
            link.Id = Next();
            m_state.Links.PushBack(link);
            NotifyGraphChanged();
            return link.Id;
        }
        /// A pin of a node by its name; 0 when none.
        [[nodiscard]] GraphId FindPin(GraphId node, core::StringView name, GraphPinDirection direction) const
        {
            if (const GraphNodeInfo* found = GetNode(node))
                for (const GraphPinInfo& pin : found->Pins)
                    if (pin.Name.AsView() == name && pin.Direction == direction)
                        return pin.Id;
            return 0;
        }
        [[nodiscard]] const GraphState& State() const noexcept { return m_state; }
        /// Whether its nodes link to each other (a state machine's transitions), not only its pins.
        void SetNodeLinks(bool allowed) noexcept { m_nodeLinks = allowed; }
        [[nodiscard]] bool GetNodeLinks() const noexcept { return m_nodeLinks; }

        /// The application's serializer for copies (not owned; null: no copying).
        void SetTextFormat(IPropertyTextFormat* format) noexcept { m_format = format; }
        /// Each change, for whoever keeps the undo.
        void SetOnChange(core::Function<void(const GraphChange&)> callback) { m_onChange = core::Move(callback); }
        /// Puts a change's graph back (`undo`: before it; else after), no change told.
        void Apply(const GraphChange& change, bool undo)
        {
            m_state = undo ? change.Before : change.After;
            NotifyGraphChanged();
        }

        // === IGraphSource ===
        void GetNodes(core::Array<GraphId>& out) const override
        {
            out.Clear();
            for (const GraphNodeInfo& node : m_state.Nodes)
                out.PushBack(node.Id);
        }
        [[nodiscard]] const GraphNodeInfo* GetNode(GraphId node) const override
        {
            for (const GraphNodeInfo& at : m_state.Nodes)
                if (at.Id == node)
                    return &at;
            return nullptr;
        }
        void GetLinks(core::Array<GraphLinkInfo>& out) const override
        {
            out.Clear();
            for (const GraphLinkInfo& link : m_state.Links)
                out.PushBack(link);
        }
        void GetFrames(core::Array<GraphFrameInfo>& out) const override
        {
            out.Clear();
            for (const GraphFrameInfo& frame : m_state.Frames)
                out.PushBack(frame);
        }

        void BeginMove() override
        {
            m_moving = true;
            m_before = m_state;
        }
        void PreviewMove(core::Span<const GraphId> nodes, core::Span<const GraphId> frames, core::Float2 delta) override
        {
            if (!m_moving)
                return;
            for (usize i = 0; i < m_state.Nodes.Size() && i < m_before.Nodes.Size(); ++i)
                if (Holds(nodes, m_state.Nodes[i].Id) && m_state.Nodes[i].Movable)
                    m_state.Nodes[i].Position = core::Float2{m_before.Nodes[i].Position.x + delta.x, m_before.Nodes[i].Position.y + delta.y};
            for (usize i = 0; i < m_state.Frames.Size() && i < m_before.Frames.Size(); ++i)
                if (Holds(frames, m_state.Frames[i].Id))
                    m_state.Frames[i].Position = core::Float2{m_before.Frames[i].Position.x + delta.x, m_before.Frames[i].Position.y + delta.y};
            NotifyGraphChanged();
        }
        void CommitMove() override
        {
            if (!m_moving)
                return;
            m_moving = false;
            Told(core::String(u8"Moved"), m_before);
        }
        void CancelMove() override
        {
            if (!m_moving)
                return;
            m_moving = false;
            m_state = m_before;
            NotifyGraphChanged();
        }

        [[nodiscard]] GraphLinkCheck CheckLink(const GraphLinkInfo& link) const override
        {
            GraphLinkCheck check;
            const GraphNodeInfo* from = GetNode(link.FromNode);
            const GraphNodeInfo* to = GetNode(link.ToNode);
            if (from == nullptr || (to == nullptr && link.ToNode != 0))
            {
                check.Reason = core::String(u8"No such node");
                return check;
            }
            if (link.Kind == GraphLinkKind::Nodes)
            {
                // A state machine's transitions: any two nodes, a node to itself, several.
                check.Allowed = m_nodeLinks;
                if (!m_nodeLinks)
                    check.Reason = core::String(u8"This graph links pins, not nodes");
                return check;
            }
            if (to == nullptr) // where a link begins: any pin
            {
                check.Allowed = PinOf(*from, link.FromPin) != nullptr;
                if (!check.Allowed)
                    check.Reason = core::String(u8"No such pin");
                return check;
            }
            const GraphPinInfo* out = PinOf(*from, link.FromPin);
            const GraphPinInfo* in = PinOf(*to, link.ToPin);
            if (out == nullptr || in == nullptr)
            {
                check.Reason = core::String(u8"No such pin");
                return check;
            }
            if (out->Direction != GraphPinDirection::Output || in->Direction != GraphPinDirection::Input)
            {
                check.Reason = core::String(u8"A link goes from an output to an input");
                return check;
            }
            if (from->Id == to->Id)
            {
                check.Reason = core::String(u8"A node does not feed itself");
                return check;
            }
            if (out->Type.Size() != 0 && in->Type.Size() != 0 && out->Type != in->Type)
            {
                check.Reason = core::Format(u8"A {} does not go into a {}", out->Type, in->Type);
                return check;
            }
            for (const GraphLinkInfo& at : m_state.Links)
            {
                if (at.Kind != GraphLinkKind::Pins)
                    continue;
                if (at.FromPin == link.FromPin && at.ToPin == link.ToPin)
                {
                    check.Reason = core::String(u8"They are linked already");
                    return check;
                }
                if (at.ToPin == link.ToPin && !in->Many)
                    check.Replaces.PushBack(at.Id);
                if (at.FromPin == link.FromPin && !out->Many)
                    check.Replaces.PushBack(at.Id);
            }
            check.Allowed = true;
            return check;
        }
        GraphId Connect(const GraphLinkInfo& link) override
        {
            const GraphLinkCheck check = CheckLink(link);
            if (!check.Allowed)
                return 0;
            const GraphState before = m_state;
            for (const GraphId gone : check.Replaces)
                RemoveLink(gone);
            GraphLinkInfo made = link;
            made.Id = Next();
            m_state.Links.PushBack(made);
            Told(core::String(u8"Linked"), before);
            return made.Id;
        }
        bool Relink(GraphId link, const GraphLinkInfo& to) override
        {
            const GraphLinkInfo* found = FindLink(link);
            if (found == nullptr)
                return false;
            const GraphState before = m_state;
            const GraphLinkInfo old = *found;
            RemoveLink(link); // asked without it, so it does not refuse or replace itself
            const GraphLinkCheck check = CheckLink(to);
            if (!check.Allowed)
            {
                m_state = before;
                return false;
            }
            for (const GraphId gone : check.Replaces)
                RemoveLink(gone);
            GraphLinkInfo moved = to;
            moved.Id = old.Id;
            moved.Kind = old.Kind;
            m_state.Links.PushBack(moved);
            Told(core::String(u8"Relinked"), before);
            return true;
        }
        bool Disconnect(core::Span<const GraphId> links) override
        {
            const GraphState before = m_state;
            bool any = false;
            for (const GraphId link : links)
                any = RemoveLink(link) || any;
            if (any)
                Told(core::String(u8"Unlinked"), before);
            return any;
        }

        bool DeleteNodes(core::Span<const GraphId> nodes) override
        {
            const GraphState before = m_state;
            bool any = false;
            for (usize i = m_state.Nodes.Size(); i-- > 0;)
            {
                const GraphNodeInfo& node = m_state.Nodes[i];
                if (!Holds(nodes, node.Id) || !node.Deletable)
                    continue;
                const GraphId id = node.Id;
                for (usize l = m_state.Links.Size(); l-- > 0;)
                    if (m_state.Links[l].FromNode == id || m_state.Links[l].ToNode == id)
                        m_state.Links.RemoveAt(l);
                m_state.Nodes.RemoveAt(i);
                any = true;
            }
            if (any)
                Told(core::String(u8"Deleted"), before);
            return any;
        }
        void GetNodeTypes(GraphId fittingPin, core::Array<GraphNodeType>& out) const override
        {
            out.Clear();
            const GraphPinInfo* from = fittingPin != 0 ? FindPinAnywhere(fittingPin) : nullptr;
            for (const Template& type : m_types)
                if (fittingPin == 0 || (from != nullptr && FirstFitting(type.Node, *from) >= 0))
                    out.PushBack(type.Type);
        }
        GraphId CreateNode(core::StringView type, core::Float2 at, GraphId linkFrom) override
        {
            const Template* chosen = nullptr;
            for (const Template& t : m_types)
                if (t.Type.Type.AsView() == type)
                    chosen = &t;
            if (chosen == nullptr)
                return 0;
            const GraphState before = m_state;
            GraphNodeInfo node = chosen->Node;
            node.Type = core::String(type);
            node.Position = at;
            node.Id = Next();
            for (GraphPinInfo& pin : node.Pins)
                pin.Id = Next();
            m_state.Nodes.PushBack(node);
            if (linkFrom != 0)
                if (const GraphPinInfo* from = FindPinAnywhere(linkFrom))
                {
                    const i32 fit = FirstFitting(node, *from);
                    if (fit >= 0)
                    {
                        GraphLinkInfo link;
                        link.Kind = GraphLinkKind::Pins;
                        const bool fromOut = from->Direction == GraphPinDirection::Output;
                        const GraphId fromNode = NodeOfPin(linkFrom);
                        link.FromNode = fromOut ? fromNode : node.Id;
                        link.FromPin = fromOut ? linkFrom : node.Pins[static_cast<usize>(fit)].Id;
                        link.ToNode = fromOut ? node.Id : fromNode;
                        link.ToPin = fromOut ? node.Pins[static_cast<usize>(fit)].Id : linkFrom;
                        const GraphLinkCheck check = CheckLink(link);
                        if (check.Allowed)
                        {
                            for (const GraphId gone : check.Replaces)
                                RemoveLink(gone);
                            link.Id = Next();
                            m_state.Links.PushBack(link);
                        }
                    }
                }
            Told(core::Format(u8"Added {}", chosen->Type.Name), before);
            return node.Id;
        }

        GraphId CreateFrame(const GraphFrameInfo& frame) override
        {
            const GraphState before = m_state;
            GraphFrameInfo made = frame;
            made.Id = Next();
            m_state.Frames.PushBack(made);
            Told(core::String(u8"Framed"), before);
            return made.Id;
        }
        bool EditFrame(const GraphFrameInfo& frame) override
        {
            for (GraphFrameInfo& at : m_state.Frames)
                if (at.Id == frame.Id)
                {
                    if (at.Title == frame.Title && at.Body == frame.Body && at.Position.x == frame.Position.x && at.Position.y == frame.Position.y &&
                        at.Size.x == frame.Size.x && at.Size.y == frame.Size.y && at.Tint == frame.Tint)
                        return false;
                    const GraphState before = m_state;
                    at = frame;
                    Told(core::String(u8"Edited a frame"), before);
                    return true;
                }
            return false;
        }
        bool DeleteFrames(core::Span<const GraphId> frames) override
        {
            const GraphState before = m_state;
            bool any = false;
            for (usize i = m_state.Frames.Size(); i-- > 0;)
                if (Holds(frames, m_state.Frames[i].Id))
                {
                    m_state.Frames.RemoveAt(i);
                    any = true;
                }
            if (any)
                Told(core::String(u8"Deleted a frame"), before);
            return any;
        }

        // The nodes (type, title, place from their top-left) and the links among them, by their
        // places in the copy, written with the application's serializer.
        [[nodiscard]] core::String CopyNodes(core::Span<const GraphId> nodes) const override
        {
            if (m_format == nullptr || nodes.IsEmpty())
                return core::String{};
            core::Array<const GraphNodeInfo*> chosen;
            for (const GraphNodeInfo& node : m_state.Nodes)
                if (Holds(nodes, node.Id))
                    chosen.PushBack(&node);
            if (chosen.IsEmpty())
                return core::String{};
            core::Float2 origin = chosen[0]->Position;
            for (const GraphNodeInfo* node : chosen)
                origin = core::Float2{core::Min(origin.x, node->Position.x), core::Min(origin.y, node->Position.y)};
            const GraphSet* self = this;
            return m_format->Write([self, &chosen, origin](core::ISerializer& ar)
            {
                core::String shape(u8"graph nodes");
                core::Serialize(ar, "shape", shape);
                i64 count = static_cast<i64>(chosen.Size());
                core::Serialize(ar, "count", count);
                for (usize i = 0; i < chosen.Size(); ++i)
                {
                    ar.Key(Key(u8'n', i).items);
                    ar.BeginObject();
                    core::String type = chosen[i]->Type;
                    core::Serialize(ar, "type", type);
                    core::String title = chosen[i]->Title;
                    core::Serialize(ar, "title", title);
                    core::Float2 at{chosen[i]->Position.x - origin.x, chosen[i]->Position.y - origin.y};
                    core::Serialize(ar, "at", at);
                    ar.EndObject();
                }
                // Links among them: by node place and pin place, so the copies link alike.
                i64 links = 0;
                core::Array<i64> rows;
                for (const GraphLinkInfo& link : self->m_state.Links)
                {
                    const i64 from = Place(chosen, link.FromNode), to = Place(chosen, link.ToNode);
                    if (from < 0 || to < 0)
                        continue;
                    rows.PushBack(static_cast<i64>(link.Kind));
                    rows.PushBack(from);
                    rows.PushBack(PinPlace(*chosen[static_cast<usize>(from)], link.FromPin));
                    rows.PushBack(to);
                    rows.PushBack(PinPlace(*chosen[static_cast<usize>(to)], link.ToPin));
                    ++links;
                }
                core::Serialize(ar, "links", links);
                for (usize i = 0; i < rows.Size(); ++i)
                    core::Serialize(ar, Key(u8'l', i).items, rows[i]);
            });
        }
        bool PasteNodes(core::StringView text, core::Float2 at, core::Array<GraphId>& made) override
        {
            made.Clear();
            if (m_format == nullptr)
                return false;
            struct Read
            {
                core::String Type;
                core::String Title;
                core::Float2 At{};
            };
            core::Array<Read> nodes;
            core::Array<i64> rows;
            bool ours = false;
            const bool read = m_format->Read(text, [&](core::ISerializer& ar)
            {
                core::String shape;
                core::Serialize(ar, "shape", shape);
                ours = shape.AsView() == core::StringView(u8"graph nodes");
                if (!ours)
                    return;
                i64 count = 0;
                core::Serialize(ar, "count", count);
                for (i64 i = 0; i < core::Clamp<i64>(count, 0, 4096); ++i)
                {
                    Read node;
                    ar.Key(Key(u8'n', static_cast<usize>(i)).items);
                    ar.BeginObject();
                    core::Serialize(ar, "type", node.Type);
                    core::Serialize(ar, "title", node.Title);
                    core::Serialize(ar, "at", node.At);
                    ar.EndObject();
                    nodes.PushBack(core::Move(node));
                }
                i64 links = 0;
                core::Serialize(ar, "links", links);
                for (i64 i = 0; i < core::Clamp<i64>(links, 0, 4096) * 5; ++i)
                {
                    i64 value = 0;
                    core::Serialize(ar, Key(u8'l', static_cast<usize>(i)).items, value);
                    rows.PushBack(value);
                }
            });
            if (!read || !ours || nodes.IsEmpty())
                return false;
            const GraphState before = m_state;
            for (const Read& node : nodes)
            {
                const Template* chosen = nullptr;
                for (const Template& t : m_types)
                    if (t.Type.Type == node.Type)
                        chosen = &t;
                if (chosen == nullptr)
                {
                    made.PushBack(0);
                    continue;
                }
                GraphNodeInfo copy = chosen->Node;
                copy.Type = node.Type;
                copy.Title = node.Title;
                copy.Position = core::Float2{at.x + node.At.x, at.y + node.At.y};
                copy.Id = Next();
                for (GraphPinInfo& pin : copy.Pins)
                    pin.Id = Next();
                m_state.Nodes.PushBack(copy);
                made.PushBack(copy.Id);
            }
            for (usize r = 0; r + 4 < rows.Size(); r += 5)
            {
                const usize from = static_cast<usize>(rows[r + 1]), to = static_cast<usize>(rows[r + 3]);
                if (from >= made.Size() || to >= made.Size() || made[from] == 0 || made[to] == 0)
                    continue;
                GraphLinkInfo link;
                link.Kind = static_cast<GraphLinkKind>(rows[r]);
                link.FromNode = made[from];
                link.ToNode = made[to];
                link.FromPin = PinAt(*GetNode(made[from]), rows[r + 2]);
                link.ToPin = PinAt(*GetNode(made[to]), rows[r + 4]);
                if (CheckLink(link).Allowed)
                {
                    link.Id = Next();
                    m_state.Links.PushBack(link);
                }
            }
            for (usize i = made.Size(); i-- > 0;)
                if (made[i] == 0)
                    made.RemoveAt(i);
            if (made.IsEmpty()) // none of a kind it makes: no change
            {
                m_state = before;
                return false;
            }
            Told(core::String(u8"Pasted"), before);
            return true;
        }

    private:
        struct Template
        {
            GraphNodeType Type;
            GraphNodeInfo Node;
        };
        GraphId Next() { return m_state.NextId++; }
        void Told(core::String words, const GraphState& before)
        {
            NotifyGraphChanged();
            if (m_onChange)
                m_onChange(GraphChange{core::Move(words), before, m_state});
        }
        [[nodiscard]] static bool Holds(core::Span<const GraphId> ids, GraphId id) noexcept
        {
            for (const GraphId at : ids)
                if (at == id)
                    return true;
            return false;
        }
        [[nodiscard]] static const GraphPinInfo* PinOf(const GraphNodeInfo& node, GraphId pin) noexcept
        {
            for (const GraphPinInfo& at : node.Pins)
                if (at.Id == pin)
                    return &at;
            return nullptr;
        }
        [[nodiscard]] const GraphPinInfo* FindPinAnywhere(GraphId pin) const noexcept
        {
            for (const GraphNodeInfo& node : m_state.Nodes)
                if (const GraphPinInfo* found = PinOf(node, pin))
                    return found;
            return nullptr;
        }
        [[nodiscard]] GraphId NodeOfPin(GraphId pin) const noexcept
        {
            for (const GraphNodeInfo& node : m_state.Nodes)
                if (PinOf(node, pin) != nullptr)
                    return node.Id;
            return 0;
        }
        [[nodiscard]] const GraphLinkInfo* FindLink(GraphId link) const noexcept
        {
            for (const GraphLinkInfo& at : m_state.Links)
                if (at.Id == link)
                    return &at;
            return nullptr;
        }
        bool RemoveLink(GraphId link)
        {
            for (usize i = 0; i < m_state.Links.Size(); ++i)
                if (m_state.Links[i].Id == link)
                {
                    m_state.Links.RemoveAt(i);
                    return true;
                }
            return false;
        }
        // The first pin of `node` a link from `from` may reach (the other direction, a type that fits); -1: none.
        [[nodiscard]] static i32 FirstFitting(const GraphNodeInfo& node, const GraphPinInfo& from) noexcept
        {
            for (usize i = 0; i < node.Pins.Size(); ++i)
            {
                const GraphPinInfo& pin = node.Pins[i];
                if (pin.Direction == from.Direction)
                    continue;
                if (pin.Type.Size() == 0 || from.Type.Size() == 0 || pin.Type == from.Type)
                    return static_cast<i32>(i);
            }
            return -1;
        }
        [[nodiscard]] static i64 Place(const core::Array<const GraphNodeInfo*>& nodes, GraphId id) noexcept
        {
            for (usize i = 0; i < nodes.Size(); ++i)
                if (nodes[i]->Id == id)
                    return static_cast<i64>(i);
            return -1;
        }
        [[nodiscard]] static i64 PinPlace(const GraphNodeInfo& node, GraphId pin) noexcept
        {
            for (usize i = 0; i < node.Pins.Size(); ++i)
                if (node.Pins[i].Id == pin)
                    return static_cast<i64>(i);
            return -1;
        }
        [[nodiscard]] static GraphId PinAt(const GraphNodeInfo& node, i64 place) noexcept
        {
            return place >= 0 && static_cast<usize>(place) < node.Pins.Size() ? node.Pins[static_cast<usize>(place)].Id : 0;
        }
        // "n3", "l12": keys the serializer reads as C strings.
        [[nodiscard]] static core::FixedArray<char, 24> Key(char8_t prefix, usize index)
        {
            core::FixedArray<char, 24> key;
            key.Add(static_cast<char>(prefix));
            const core::String digits = core::Format(u8"{}", index);
            for (usize i = 0; i < digits.Size() && key.Size() + 1 < key.CapacityValue(); ++i)
                key.Add(static_cast<char>(digits[i]));
            key.Add('\0'); // read as a C string (items)
            return key;
        }

        GraphState m_state;
        GraphState m_before; // the graph when a move began
        bool m_moving = false;
        bool m_nodeLinks = false;
        core::Array<Template> m_types;
        IPropertyTextFormat* m_format = nullptr;
        core::Function<void(const GraphChange&)> m_onChange;
    };
}
