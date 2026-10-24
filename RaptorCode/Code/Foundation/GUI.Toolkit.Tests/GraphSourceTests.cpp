// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - the graph source (T6 of Specs/gui-lab-evolution-3.md): nodes, pins, links and frames
// by stable ids; a link asked for first (allowed or why not, what it replaces); a move a gesture; each
// other edit one change, told before and after, undone by putting the graph back; node types for a
// menu, filtered to a pin that fits, a node made linked to it; copies through the application's
// serializer.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;
import foundation.gui.toolkit;

using namespace foundation::gui;
namespace core = foundation::core;
using core::usize;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    // Core's binary serializer, its bytes held as the text.
    class BlobFormat : public IPropertyTextFormat
    {
    public:
        core::String Write(core::Function<void(core::ISerializer&)> write) override
        {
            core::MemoryStream stream;
            core::BinarySerializer ar(stream, core::SerializeMode::Write);
            write(ar);
            const core::Span<const core::byte> bytes = stream.Bytes();
            return ar.IsOk() ? core::String(core::StringView(reinterpret_cast<const char8_t*>(bytes.Data()), bytes.Size())) : core::String{};
        }
        bool Read(core::StringView text, core::Function<void(core::ISerializer&)> read) override
        {
            core::MemoryStream stream;
            (void)stream.Write(text.Data(), text.Size());
            (void)stream.Seek(0, core::SeekOrigin::Begin);
            core::BinarySerializer ar(stream, core::SerializeMode::Read);
            read(ar);
            return ar.IsOk();
        }
    };

    GraphPinInfo Pin(const char8_t* name, GraphPinDirection direction, const char8_t* type, bool many = false)
    {
        GraphPinInfo pin;
        pin.Name = core::String(name);
        pin.Direction = direction;
        pin.Type = core::String(type);
        pin.Many = many;
        return pin;
    }

    // A small dataflow graph: a Number (out "value": float, many), a Colour (out "rgb": color),
    // and a Mix (in "a": float, in "b": float, out "result": float).
    struct Bed
    {
        GraphSet graph;
        core::Array<GraphChange> changes{core::DefaultAllocator()};
        GraphId number = 0, colour = 0, mix = 0;

        Bed()
        {
            GraphNodeInfo numberNode;
            numberNode.Title = core::String(u8"Number");
            numberNode.Pins.PushBack(Pin(u8"value", GraphPinDirection::Output, u8"float", true));
            GraphNodeInfo colourNode;
            colourNode.Title = core::String(u8"Colour");
            colourNode.Pins.PushBack(Pin(u8"rgb", GraphPinDirection::Output, u8"color", true));
            GraphNodeInfo mixNode;
            mixNode.Title = core::String(u8"Mix");
            mixNode.Pins.PushBack(Pin(u8"a", GraphPinDirection::Input, u8"float"));
            mixNode.Pins.PushBack(Pin(u8"b", GraphPinDirection::Input, u8"float"));
            mixNode.Pins.PushBack(Pin(u8"result", GraphPinDirection::Output, u8"float", true));
            graph.AddNodeType(GraphNodeType{core::String(u8"number"), core::String(u8"Number"), core::String(u8"Values")}, numberNode);
            graph.AddNodeType(GraphNodeType{core::String(u8"colour"), core::String(u8"Colour"), core::String(u8"Values")}, colourNode);
            graph.AddNodeType(GraphNodeType{core::String(u8"mix"), core::String(u8"Mix"), core::String(u8"Maths")}, mixNode);
            numberNode.Type = core::String(u8"number");
            colourNode.Type = core::String(u8"colour");
            mixNode.Type = core::String(u8"mix");
            number = graph.AddNode(numberNode);
            colour = graph.AddNode(colourNode);
            mixNode.Position = core::Float2{200.0f, 0.0f};
            mix = graph.AddNode(mixNode);
            graph.SetOnChange([this](const GraphChange& change) { changes.PushBack(change); });
        }
        GraphLinkInfo Link(GraphId fromNode, const char8_t* out, GraphId toNode, const char8_t* in) const
        {
            GraphLinkInfo link;
            link.Kind = GraphLinkKind::Pins;
            link.FromNode = fromNode;
            link.FromPin = graph.FindPin(fromNode, SV(out), GraphPinDirection::Output);
            link.ToNode = toNode;
            link.ToPin = graph.FindPin(toNode, SV(in), GraphPinDirection::Input);
            return link;
        }
        [[nodiscard]] usize LinkCount() const { return graph.State().Links.Size(); }
    };
}

TEST_CASE("GraphSet: nodes, pins and links by ids that stay when another goes")
{
    Bed bed;
    core::Array<GraphId> nodes(core::DefaultAllocator());
    bed.graph.GetNodes(nodes);
    REQUIRE(nodes.Size() == 3);
    const GraphNodeInfo* mix = bed.graph.GetNode(bed.mix);
    REQUIRE(mix != nullptr);
    CHECK(mix->Title == core::String(u8"Mix"));
    REQUIRE(mix->Pins.Size() == 3);
    CHECK(mix->Pins[0].Id != 0);
    CHECK(mix->Pins[0].Id != mix->Pins[1].Id);

    const GraphId link = bed.graph.Connect(bed.Link(bed.number, u8"value", bed.mix, u8"a"));
    REQUIRE(link != 0);
    REQUIRE(bed.graph.DeleteNodes(core::Span<const GraphId>(&bed.colour, 1)));
    CHECK(bed.graph.GetNode(bed.mix) != nullptr); // the others keep their ids
    core::Array<GraphLinkInfo> links(core::DefaultAllocator());
    bed.graph.GetLinks(links);
    REQUIRE(links.Size() == 1);
    CHECK(links[0].Id == link);
}

TEST_CASE("GraphSet: a link is asked for first: allowed, refused with why, or what it would replace")
{
    Bed bed;
    GraphLinkCheck check = bed.graph.CheckLink(bed.Link(bed.number, u8"value", bed.mix, u8"a"));
    CHECK(check.Allowed);
    CHECK(check.Replaces.IsEmpty());

    check = bed.graph.CheckLink(bed.Link(bed.colour, u8"rgb", bed.mix, u8"a"));
    CHECK_FALSE(check.Allowed);
    CHECK(check.Reason == core::String(u8"A color does not go into a float"));

    GraphLinkInfo backwards = bed.Link(bed.number, u8"value", bed.mix, u8"a");
    backwards.ToPin = bed.graph.FindPin(bed.mix, SV(u8"result"), GraphPinDirection::Output);
    CHECK_FALSE(bed.graph.CheckLink(backwards).Allowed);

    const GraphId first = bed.graph.Connect(bed.Link(bed.number, u8"value", bed.mix, u8"a"));
    CHECK_FALSE(bed.graph.CheckLink(bed.Link(bed.number, u8"value", bed.mix, u8"a")).Allowed); // linked already
    // An input takes one: a second into it replaces the first.
    const GraphId other = bed.graph.AddNode(*bed.graph.GetNode(bed.number));
    check = bed.graph.CheckLink(bed.Link(other, u8"value", bed.mix, u8"a"));
    CHECK(check.Allowed);
    REQUIRE(check.Replaces.Size() == 1);
    CHECK(check.Replaces[0] == first);
    REQUIRE(bed.graph.Connect(bed.Link(other, u8"value", bed.mix, u8"a")) != 0);
    CHECK(bed.LinkCount() == 1);
    // An output takes many.
    CHECK(bed.graph.CheckLink(bed.Link(bed.number, u8"value", bed.mix, u8"b")).Replaces.IsEmpty());

    // Where a link may begin: any pin, either way.
    GraphLinkInfo begin;
    begin.FromNode = bed.mix;
    begin.FromPin = bed.graph.FindPin(bed.mix, SV(u8"a"), GraphPinDirection::Input);
    CHECK(bed.graph.CheckLink(begin).Allowed);

    // Node links (a state machine's) only where the graph takes them; then any two, a node to
    // itself, several.
    GraphLinkInfo transition;
    transition.Kind = GraphLinkKind::Nodes;
    transition.FromNode = bed.number;
    transition.ToNode = bed.number;
    CHECK_FALSE(bed.graph.CheckLink(transition).Allowed);
    transition.ToNode = 0;
    CHECK_FALSE(bed.graph.CheckLink(transition).Allowed);
    bed.graph.SetNodeLinks(true);
    CHECK(bed.graph.CheckLink(transition).Allowed);
    transition.ToNode = bed.number;
    CHECK(bed.graph.CheckLink(transition).Allowed);
}

TEST_CASE("GraphSet: each change told before and after, one each; a move a gesture; an undo puts the graph back")
{
    Bed bed;
    const GraphId link = bed.graph.Connect(bed.Link(bed.number, u8"value", bed.mix, u8"a"));
    REQUIRE(bed.changes.Size() == 1);
    CHECK(bed.changes[0].Before.Links.IsEmpty());
    CHECK(bed.changes[0].After.Links.Size() == 1);

    const GraphId moved[] = {bed.number, bed.mix};
    bed.graph.BeginMove();
    bed.graph.PreviewMove(moved, {}, core::Float2{10.0f, 5.0f});
    bed.graph.PreviewMove(moved, {}, core::Float2{30.0f, 15.0f});
    CHECK(bed.graph.GetNode(bed.mix)->Position.x == doctest::Approx(230.0f));
    CHECK(bed.changes.Size() == 1); // previews are no change
    bed.graph.CommitMove();
    CHECK(bed.changes.Size() == 2);
    bed.graph.BeginMove();
    bed.graph.PreviewMove(moved, {}, core::Float2{100.0f, 0.0f});
    bed.graph.CancelMove();
    CHECK(bed.graph.GetNode(bed.mix)->Position.x == doctest::Approx(230.0f));
    CHECK(bed.changes.Size() == 2);

    // Relinked: the same link, its end moved.
    GraphLinkInfo to = bed.Link(bed.number, u8"value", bed.mix, u8"b");
    REQUIRE(bed.graph.Relink(link, to));
    core::Array<GraphLinkInfo> links(core::DefaultAllocator());
    bed.graph.GetLinks(links);
    REQUIRE(links.Size() == 1);
    CHECK(links[0].Id == link);
    CHECK(links[0].ToPin == to.ToPin);
    CHECK_FALSE(bed.graph.Relink(link, bed.Link(bed.colour, u8"rgb", bed.mix, u8"b"))); // refused: as it was
    bed.graph.GetLinks(links);
    CHECK(links[0].ToPin == to.ToPin);

    REQUIRE(bed.graph.Disconnect(core::Span<const GraphId>(&link, 1)));
    CHECK(bed.LinkCount() == 0);
    bed.graph.Apply(bed.changes.Back(), true);
    CHECK(bed.LinkCount() == 1);
    bed.graph.Apply(bed.changes[1], true); // back before the move
    CHECK(bed.graph.GetNode(bed.mix)->Position.x == doctest::Approx(200.0f));
}

TEST_CASE("GraphSet: node types for a menu, filtered to a pin that fits; a node made linked to it in one change")
{
    Bed bed;
    core::Array<GraphNodeType> types(core::DefaultAllocator());
    bed.graph.GetNodeTypes(0, types);
    CHECK(types.Size() == 3);
    // From a colour's output: only what takes a colour or anything (none takes a colour here).
    bed.graph.GetNodeTypes(bed.graph.FindPin(bed.colour, SV(u8"rgb"), GraphPinDirection::Output), types);
    CHECK(types.IsEmpty());
    // From a number's output: the Mix takes it.
    const GraphId value = bed.graph.FindPin(bed.number, SV(u8"value"), GraphPinDirection::Output);
    bed.graph.GetNodeTypes(value, types);
    REQUIRE(types.Size() == 1);
    CHECK(types[0].Type == core::String(u8"mix"));

    const GraphId made = bed.graph.CreateNode(SV(u8"mix"), core::Float2{50.0f, 80.0f}, value);
    REQUIRE(made != 0);
    CHECK(bed.graph.GetNode(made)->Position.y == doctest::Approx(80.0f));
    core::Array<GraphLinkInfo> links(core::DefaultAllocator());
    bed.graph.GetLinks(links);
    REQUIRE(links.Size() == 1);
    CHECK(links[0].FromPin == value);
    CHECK(links[0].ToPin == bed.graph.FindPin(made, SV(u8"a"), GraphPinDirection::Input));
    CHECK(bed.changes.Size() == 1);
    CHECK(bed.changes[0].Words == core::String(u8"Added Mix"));
}

TEST_CASE("GraphSet: frames made, edited and deleted, each one change; moved with nodes in one gesture")
{
    Bed bed;
    GraphFrameInfo frame;
    frame.Title = core::String(u8"Inputs");
    const GraphId id = bed.graph.CreateFrame(frame);
    REQUIRE(id != 0);
    core::Array<GraphFrameInfo> frames(core::DefaultAllocator());
    bed.graph.GetFrames(frames);
    REQUIRE(frames.Size() == 1);
    frame = frames[0];
    frame.Body = core::String(u8"What feeds the mix");
    CHECK(bed.graph.EditFrame(frame));
    CHECK_FALSE(bed.graph.EditFrame(frame)); // nothing changed

    bed.graph.BeginMove();
    bed.graph.PreviewMove(core::Span<const GraphId>(&bed.number, 1), core::Span<const GraphId>(&id, 1), core::Float2{40.0f, 0.0f});
    bed.graph.CommitMove();
    bed.graph.GetFrames(frames);
    CHECK(frames[0].Position.x == doctest::Approx(40.0f));
    CHECK(bed.graph.GetNode(bed.number)->Position.x == doctest::Approx(40.0f));
    REQUIRE(bed.graph.DeleteFrames(core::Span<const GraphId>(&id, 1)));
    CHECK(bed.changes.Size() == 4);
}

TEST_CASE("GraphSet: nodes copied with the links among them, pasted as new nodes at a place, one change")
{
    Bed bed;
    BlobFormat format;
    bed.graph.SetTextFormat(&format);
    REQUIRE(bed.graph.Connect(bed.Link(bed.number, u8"value", bed.mix, u8"a")) != 0);
    REQUIRE(bed.graph.Connect(bed.Link(bed.colour, u8"rgb", bed.number, u8"value")) == 0); // refused, not in the copy
    const GraphId chosen[] = {bed.number, bed.mix};
    const core::String text = bed.graph.CopyNodes(chosen);
    REQUIRE(text.Size() != 0);

    core::Array<GraphId> made(core::DefaultAllocator());
    REQUIRE(bed.graph.PasteNodes(text.AsView(), core::Float2{0.0f, 300.0f}, made));
    REQUIRE(made.Size() == 2);
    CHECK(bed.graph.GetNode(made[0])->Title == core::String(u8"Number"));
    CHECK(bed.graph.GetNode(made[1])->Position.x == doctest::Approx(200.0f)); // its place from the copy's top-left
    CHECK(bed.graph.GetNode(made[1])->Position.y == doctest::Approx(300.0f));
    CHECK(bed.LinkCount() == 2); // the copy's own link, between the copies
    CHECK(bed.changes.Back().Words == core::String(u8"Pasted"));
    CHECK_FALSE(bed.graph.PasteNodes(SV(u8"not ours"), core::Float2{}, made));

    // Nodes of no kind it makes: nothing pasted, and no change told.
    const usize told = bed.changes.Size();
    GraphNodeInfo stray;
    stray.Title = core::String(u8"Stray");
    stray.Type = core::String(u8"unknown");
    const GraphId strayId = bed.graph.AddNode(stray);
    const core::String strays = bed.graph.CopyNodes(core::Span<const GraphId>(&strayId, 1));
    REQUIRE_FALSE(strays.IsEmpty());
    CHECK_FALSE(bed.graph.PasteNodes(strays.AsView(), core::Float2{}, made));
    CHECK(made.IsEmpty());
    CHECK(bed.changes.Size() == told);
}
