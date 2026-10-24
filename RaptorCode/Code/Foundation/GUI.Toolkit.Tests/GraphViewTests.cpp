// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - the graph view (T6 of Specs/gui-lab-evolution-3.md): a source's nodes as widgets made
// while in view and reused as it moves (a node never seen made once to learn its size); a click or a
// box selecting, Shift or Ctrl adding or taking away; a drag moving the selected nodes as one gesture
// through the source, on the grid where it snaps, Escape cancelling it; read only moving nothing; a
// double click the application's; the wheel zooming about the pointer within limits and a middle
// drag panning; framing every node. Links: dragged from a pin, the source asked of each pin (lit,
// dimmed, the one under the pointer its target, a refusal and what would be replaced known); an
// input's link end rewired or let go; a node link from just outside a node's edge, the two ways
// apart, to itself after leaving it; a click selecting a link; highlights. Menus and keys: the
// picker of node kinds (by category, with a search), opened from the menu over nothing or by a link
// dropped on nothing (only the kinds it reaches, the node linked); Delete, Escape, Ctrl+C and Ctrl+V;
// a node's menu duplicating and beginning a node link that follows the pointer; a link's deleting.
// Frames: behind the nodes, moved by their title with what lies inside, resized from their edges,
// renamed in place, made around the selection from the menu, deleted.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.fonts;
import foundation.gui;
import foundation.gui.toolkit;

using namespace foundation::gui;
namespace core = foundation::core;
using core::f32;
using core::usize;

namespace
{
    GraphPinInfo Pin(const char8_t* name, GraphPinDirection direction, const char8_t* type = u8"")
    {
        GraphPinInfo pin;
        pin.Name = core::String(name);
        pin.Direction = direction;
        pin.Type = core::String(type);
        return pin;
    }
    GraphNodeType Kind(const char8_t* type, const char8_t* name, const char8_t* category)
    {
        return GraphNodeType{core::String(type), core::String(name), core::String(category)};
    }

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
    class MemoryClipboard : public IClipboard
    {
    public:
        [[nodiscard]] bool HasText() const override { return m_text.Size() != 0; }
        [[nodiscard]] core::String GetText() const override { return m_text; }
        void SetText(core::StringView text) override { m_text = core::String(text); }

    private:
        core::String m_text;
    };

    MenuItem* Item(Menu& menu, const char8_t* text)
    {
        for (usize i = 0; i < menu.ChildCount(); ++i)
            if (MenuItem* item = core::Cast<MenuItem>(menu.GetChildAt(i)); item != nullptr && item->GetText() == core::StringView(text))
                return item;
        return nullptr;
    }
    void Activate(Menu& menu, const char8_t* text)
    {
        MenuItem* item = Item(menu, text);
        REQUIRE(item != nullptr);
        (void)item->HandleActivate();
    }
    GraphNodeInfo Node(const char8_t* title, core::Float2 at)
    {
        GraphNodeInfo node;
        node.Type = core::String(u8"mix"); // a kind the graph makes, so it copies and pastes
        node.Title = core::String(title);
        node.Position = at;
        node.Pins.PushBack(Pin(u8"in", GraphPinDirection::Input));
        node.Pins.PushBack(Pin(u8"out", GraphPinDirection::Output));
        return node;
    }

    // A 600 by 400 view at the root's top-left, the graph's origin at its top-left at the zoom of 1:
    // A at (0, 0) and B at (300, 0) in view, C at (1200, 800) out of it.
    struct Bed
    {
        core::RefPtr<SceneRoot> root = core::MakeRef<SceneRoot>(core::DefaultAllocator(), core::MakeRef<GUIContext>(core::DefaultAllocator()));
        core::RefPtr<GraphView> view = core::MakeRef<GraphView>(core::DefaultAllocator());
        GraphSet graph;
        BlobFormat format;
        MemoryClipboard clipboard;
        core::Array<GraphChange> changes{core::DefaultAllocator()};
        GraphId a = 0, b = 0, c = 0;

        Bed()
        {
            a = graph.AddNode(Node(u8"A", core::Float2{0.0f, 0.0f}));
            b = graph.AddNode(Node(u8"B", core::Float2{300.0f, 0.0f}));
            c = graph.AddNode(Node(u8"C", core::Float2{1200.0f, 800.0f}));
            // Its kinds of node: a Number (Values; out "value": float), a Mix and a Tint (Maths; in "a"
            // and "b": float, out "result"; in "color": color, out "color").
            GraphNodeInfo number;
            number.Title = core::String(u8"Number");
            number.Pins.PushBack(Pin(u8"value", GraphPinDirection::Output, u8"float"));
            GraphNodeInfo mix;
            mix.Title = core::String(u8"Mix");
            mix.Pins.PushBack(Pin(u8"a", GraphPinDirection::Input, u8"float"));
            mix.Pins.PushBack(Pin(u8"b", GraphPinDirection::Input, u8"float"));
            mix.Pins.PushBack(Pin(u8"result", GraphPinDirection::Output, u8"float"));
            GraphNodeInfo tint;
            tint.Title = core::String(u8"Tint");
            tint.Pins.PushBack(Pin(u8"color", GraphPinDirection::Input, u8"color"));
            tint.Pins.PushBack(Pin(u8"color", GraphPinDirection::Output, u8"color"));
            graph.AddNodeType(Kind(u8"number", u8"Number", u8"Values"), number);
            graph.AddNodeType(Kind(u8"mix", u8"Mix", u8"Maths"), mix);
            graph.AddNodeType(Kind(u8"tint", u8"Tint", u8"Maths"), tint);
            graph.SetTextFormat(&format);
            graph.SetOnChange([this](const GraphChange& change) { changes.PushBack(change); });
            D().SetClipboard(&clipboard);
            root->SetSize(core::Float2{800.0f, 600.0f});
            root->EditLayoutStyle([](LayoutStyle& s) { s.AlignItems = Align::Start; });
            view->EditLayoutStyle([](LayoutStyle& s)
            {
                s.Width = LayoutLength::Px(600.0f);
                s.Height = LayoutLength::Px(400.0f);
            });
            root->AddChild(view.Get());
            view->SetSource(&graph);
            (void)root->UpdateLayout();
        }
        ~Bed()
        {
            D().CloseAllPopups();
            D().SetClipboard(nullptr);
            view->SetSource(nullptr);
        }
        void RightClick(core::Float2 at)
        {
            D().InjectMouseMove(at);
            D().InjectMouseDown(at, MouseButton::Right);
            D().InjectMouseUp(at, MouseButton::Right);
        }
        [[nodiscard]] usize NodeCount() const { return graph.State().Nodes.Size(); }
        EventDispatcher& D() { return *root->GetEventDispatcher(); }
        [[nodiscard]] core::Float2 Middle(GraphId node) const
        {
            const Rect r = view->NodeRect(node);
            return core::Float2{r.x + r.width * 0.5f, r.y + r.height * 0.5f};
        }
        [[nodiscard]] core::Float2 Where(GraphId node) const { return graph.GetNode(node)->Position; }
        void Press(core::Float2 at, core::u32 modifiers = 0)
        {
            D().InjectMouseMove(at, modifiers);
            D().InjectMouseDown(at, MouseButton::Left, modifiers);
        }
        void Drag(core::Float2 from, core::Float2 to, core::u32 modifiers = 0)
        {
            Press(from, modifiers);
            D().InjectMouseMove(core::Float2{(from.x + to.x) * 0.5f, (from.y + to.y) * 0.5f}, modifiers);
            D().InjectMouseMove(to, modifiers);
            D().InjectMouseUp(to, MouseButton::Left, modifiers);
        }
        void Click(core::Float2 at, core::u32 modifiers = 0)
        {
            Press(at, modifiers);
            D().InjectMouseUp(at, MouseButton::Left, modifiers);
        }
        void Pause() // a later press is not the second of a double
        {
            D().InjectMouseMove(core::Float2{790.0f, 590.0f});
            D().InjectMouseDown(core::Float2{790.0f, 590.0f}, MouseButton::Left);
            D().InjectMouseUp(core::Float2{790.0f, 590.0f}, MouseButton::Left);
        }
        [[nodiscard]] usize Selected() const { return view->GetSelectedNodes().Size(); }
        [[nodiscard]] GraphId PinOf(GraphId node, const char8_t* name) const
        {
            const GraphId in = graph.FindPin(node, core::StringView(name), GraphPinDirection::Input);
            return in != 0 ? in : graph.FindPin(node, core::StringView(name), GraphPinDirection::Output);
        }
        [[nodiscard]] core::Float2 PinAt(GraphId pin) const
        {
            core::Float2 at{};
            REQUIRE(view->PinPoint(pin, at));
            return at;
        }
        [[nodiscard]] GraphPinRow* Row(GraphId node, GraphId pin) const
        {
            GraphNodeWidget* widget = view->GetNodeWidget(node);
            if (widget == nullptr)
                return nullptr;
            for (usize i = 0; i < widget->PinRowCount(); ++i)
                if (widget->PinRowAt(i).GetPinId() == pin)
                    return &widget->PinRowAt(i);
            return nullptr;
        }
        [[nodiscard]] usize LinkCount() const { return graph.State().Links.Size(); }
        GraphId Add(const char8_t* title, core::Float2 at)
        {
            const GraphId node = graph.AddNode(Node(title, at));
            (void)root->UpdateLayout();
            return node;
        }
    };
    bool Has(GraphPinRow* row, const char8_t* cls) { return row != nullptr && row->HasClass(core::StringView(cls)); }
}

TEST_CASE("GraphView: nodes are widgets made while in view, reused as it pans, and zoomed with it")
{
    Bed bed;
    CHECK(bed.view->MadeNodeCount() == 2);
    REQUIRE(bed.view->GetNodeWidget(bed.a) != nullptr);
    REQUIRE(bed.view->GetNodeWidget(bed.b) != nullptr);
    CHECK(bed.view->GetNodeWidget(bed.c) == nullptr);
    CHECK(bed.view->GetNodeWidget(bed.a)->GetTitleLabel().GetText() == core::StringView(u8"A"));
    CHECK(bed.view->GetNodeWidget(bed.a)->PinRowCount() == 2);
    // C was made once to learn its size, then went back to the pool.
    CHECK(bed.view->PooledNodeCount() == 1);
    CHECK(bed.view->NodeSize(bed.c).x == doctest::Approx(bed.view->NodeSize(bed.a).x));
    CHECK(bed.view->NodeSize(bed.c).y == doctest::Approx(bed.view->NodeSize(bed.a).y));

    // Panned to C: its widget is one reused, and A's and B's go back to the pool.
    bed.view->SetPan(core::Float2{1100.0f, 700.0f});
    (void)bed.root->UpdateLayout();
    CHECK(bed.view->MadeNodeCount() == 1);
    REQUIRE(bed.view->GetNodeWidget(bed.c) != nullptr);
    CHECK(bed.view->GetNodeWidget(bed.c)->GetTitleLabel().GetText() == core::StringView(u8"C"));
    CHECK(bed.view->GetNodeWidget(bed.a) == nullptr);
    CHECK(bed.view->MadeNodeCount() + bed.view->PooledNodeCount() == 3);
    const Rect atC = bed.view->NodeRect(bed.c);
    CHECK(atC.x == doctest::Approx(100.0f));
    CHECK(atC.y == doctest::Approx(100.0f));

    // Zoomed out, a widget is drawn at the zoom, its rect following.
    bed.view->SetPan(core::Float2{0.0f, 0.0f});
    bed.view->SetZoom(0.5f);
    (void)bed.root->UpdateLayout();
    REQUIRE(bed.view->GetNodeWidget(bed.b) != nullptr);
    CHECK(bed.view->GetNodeWidget(bed.b)->GetScale().x == doctest::Approx(0.5f));
    CHECK(bed.view->NodeRect(bed.b).x == doctest::Approx(150.0f));
    CHECK(bed.view->NodeRect(bed.b).width == doctest::Approx(bed.view->NodeSize(bed.b).x * 0.5f));
    // A pin is drawn on its node's edge: an input at the start, an output at the end.
    GraphNodeWidget& node = *bed.view->GetNodeWidget(bed.b);
    core::Float2 in{}, out{};
    REQUIRE(node.PinPoint(node.PinRowAt(0).GetPinId(), in));
    REQUIRE(node.PinPoint(node.PinRowAt(1).GetPinId(), out));
    CHECK(in.x == doctest::Approx(0.0f));
    CHECK(out.x == doctest::Approx(node.GetSize().x));
    CHECK(in.y > node.GetHeader().GetSize().y);
}

TEST_CASE("GraphView: right to left, the canvas still runs left to right, inputs on a node's left and outputs on its right")
{
    Bed bed;
    bed.root->SetLayoutDirection(foundation::gui::Node::LayoutDirection::RightToLeft);
    (void)bed.root->UpdateLayout();
    REQUIRE(bed.view->IsRightToLeft());
    CHECK(bed.view->GetPlacesChildren()); // its nodes at their canvas points, which right to left leaves
    GraphNodeWidget& node = *bed.view->GetNodeWidget(bed.a);
    GraphPinRow& in = node.PinRowAt(0);
    GraphPinRow& out = node.PinRowAt(1);
    REQUIRE(in.GetDirection() == GraphPinDirection::Input);
    CHECK_FALSE(in.IsRightToLeft());
    // The input's row at the node's left, the output's at its right, their pins on those edges.
    const Rect nodeAt = node.GetScreenBounds();
    CHECK(in.GetScreenBounds().x == doctest::Approx(nodeAt.x).epsilon(0.01));
    CHECK(out.GetScreenBounds().Right() == doctest::Approx(nodeAt.Right()).epsilon(0.01));
    core::Float2 inAt{}, outAt{};
    REQUIRE(node.PinPoint(in.GetPinId(), inAt));
    REQUIRE(node.PinPoint(out.GetPinId(), outAt));
    CHECK(inAt.x == doctest::Approx(0.0f));
    CHECK(outAt.x == doctest::Approx(node.GetSize().x));
    // A's output to B's input is the short way across, not round the nodes.
    const GraphId aOut = bed.PinOf(bed.a, u8"out"), bIn = bed.PinOf(bed.b, u8"in");
    const f32 shift = bed.view->GetScreenBounds().x; // the root puts the view at its right
    const auto screen = [shift](core::Float2 at) { return core::Float2{at.x + shift, at.y}; };
    bed.Drag(screen(bed.PinAt(aOut)), screen(bed.PinAt(bIn)));
    REQUIRE(bed.LinkCount() == 1);
    core::Array<core::Float2> points;
    REQUIRE(bed.view->LinkPoints(bed.graph.State().Links[0], points));
    const f32 left = bed.view->NodeRect(bed.a).Right(), right = bed.view->NodeRect(bed.b).x;
    for (const core::Float2& p : points)
    {
        CHECK(p.x >= left - 0.5f);
        CHECK(p.x <= right + 0.5f);
    }
}

TEST_CASE("GraphView: a click or a box selects; Shift or Ctrl adds or takes away")
{
    Bed bed;
    int told = 0;
    bed.view->SetOnSelectionChanged([&told]() { ++told; });
    bed.Click(bed.Middle(bed.a));
    REQUIRE(bed.Selected() == 1);
    CHECK(bed.view->IsNodeSelected(bed.a));
    CHECK(bed.view->GetNodeWidget(bed.a)->HasClass(core::StringView(u8"selected")));
    CHECK(told == 1);
    bed.Pause();
    bed.Click(core::Float2{500.0f, 350.0f});
    CHECK(bed.Selected() == 0); // a click on nothing selects nothing
    bed.Pause();
    bed.Click(bed.Middle(bed.a));
    bed.Pause();
    bed.Click(bed.Middle(bed.b), KeyModShift);
    CHECK(bed.Selected() == 2);
    bed.Pause();
    bed.Click(bed.Middle(bed.a), KeyModShift);
    bed.Click(bed.Middle(bed.a), KeyModCtrl); // a second press soon after: still a toggle
    CHECK(bed.Selected() == 2);
    bed.Pause();
    bed.Click(bed.Middle(bed.b), KeyModCtrl);
    REQUIRE(bed.Selected() == 1);
    CHECK(bed.view->IsNodeSelected(bed.a));
    CHECK_FALSE(bed.view->GetNodeWidget(bed.b)->HasClass(core::StringView(u8"selected")));

    // A box from nothing over both; with Shift it adds to what is selected.
    bed.Pause();
    bed.Drag(core::Float2{590.0f, 390.0f}, core::Float2{10.0f, 10.0f});
    CHECK(bed.Selected() == 2);
    bed.Pause();
    bed.Click(bed.Middle(bed.b));
    REQUIRE(bed.Selected() == 1);
    const Rect atA = bed.view->NodeRect(bed.a);
    bed.Drag(core::Float2{atA.Right() + 20.0f, 390.0f}, core::Float2{atA.x + 10.0f, atA.y + 10.0f}, KeyModShift);
    CHECK(bed.Selected() == 2);

    // A node the source takes away (an undo) leaves the selection.
    REQUIRE(bed.graph.DeleteNodes(core::Span<const GraphId>(&bed.a, 1)));
    REQUIRE(bed.Selected() == 1);
    CHECK(bed.view->IsNodeSelected(bed.b));
}

TEST_CASE("GraphView: a drag moves the selected nodes as one gesture, on the grid, and Escape cancels it")
{
    Bed bed;
    bed.Click(bed.Middle(bed.a));
    bed.Pause();
    bed.Click(bed.Middle(bed.b), KeyModShift);
    bed.Pause();
    // 37 by 21 on a grid of 16: the pressed node lands at (32, 16), the other keeps its place to it.
    const core::Float2 from = bed.Middle(bed.a);
    bed.Drag(from, core::Float2{from.x + 37.0f, from.y + 21.0f});
    CHECK(bed.Where(bed.a).x == doctest::Approx(32.0f));
    CHECK(bed.Where(bed.a).y == doctest::Approx(16.0f));
    CHECK(bed.Where(bed.b).x == doctest::Approx(332.0f));
    CHECK(bed.Where(bed.b).y == doctest::Approx(16.0f));
    REQUIRE(bed.changes.Size() == 1); // one change for the whole drag
    CHECK(bed.Selected() == 2);
    bed.graph.Apply(bed.changes[0], true);
    CHECK(bed.Where(bed.a).x == doctest::Approx(0.0f));

    // Not snapping, it moves as the pointer did (over the zoom).
    bed.Pause();
    bed.view->SetSnapToGrid(false);
    bed.view->SetZoom(0.5f);
    (void)bed.root->UpdateLayout();
    bed.Click(bed.Middle(bed.a));
    bed.Pause();
    const core::Float2 at = bed.Middle(bed.a);
    bed.Drag(at, core::Float2{at.x + 10.0f, at.y + 5.0f});
    CHECK(bed.Where(bed.a).x == doctest::Approx(20.0f));
    CHECK(bed.Where(bed.a).y == doctest::Approx(10.0f));
    CHECK(bed.Where(bed.b).x == doctest::Approx(300.0f)); // not selected
    REQUIRE(bed.changes.Size() == 2);

    // Escape mid-drag puts it back, and nothing is told.
    bed.Pause();
    const core::Float2 again = bed.Middle(bed.a);
    bed.Press(again);
    bed.D().InjectMouseMove(core::Float2{again.x + 40.0f, again.y + 40.0f});
    CHECK(bed.Where(bed.a).x == doctest::Approx(100.0f));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    CHECK(bed.Where(bed.a).x == doctest::Approx(20.0f));
    bed.D().InjectMouseUp(core::Float2{again.x + 40.0f, again.y + 40.0f}, MouseButton::Left);
    CHECK(bed.Where(bed.a).x == doctest::Approx(20.0f));
    CHECK(bed.changes.Size() == 2);

    // Read only, a drag selects and moves nothing.
    bed.Pause();
    bed.view->SetReadOnly(true);
    const core::Float2 still = bed.Middle(bed.a);
    bed.Drag(still, core::Float2{still.x + 50.0f, still.y});
    CHECK(bed.Where(bed.a).x == doctest::Approx(20.0f));
    CHECK(bed.changes.Size() == 2);
    CHECK(bed.view->IsNodeSelected(bed.a));
}

TEST_CASE("GraphView: the wheel zooms about the pointer within its limits; a middle drag pans")
{
    Bed bed;
    const core::Float2 at{250.0f, 150.0f};
    const core::Float2 under = bed.view->ViewToGraph(at);
    bed.D().InjectMouseMove(at);
    bed.D().InjectMouseWheel(at, core::Float2{0.0f, 1.0f});
    CHECK(bed.view->GetZoom() == doctest::Approx(1.15f));
    CHECK(bed.view->ViewToGraph(at).x == doctest::Approx(under.x));
    CHECK(bed.view->ViewToGraph(at).y == doctest::Approx(under.y));
    for (int i = 0; i < 20; ++i)
        bed.D().InjectMouseWheel(at, core::Float2{0.0f, 1.0f});
    CHECK(bed.view->GetZoom() == doctest::Approx(bed.view->ZoomMax()));
    for (int i = 0; i < 40; ++i)
        bed.D().InjectMouseWheel(at, core::Float2{0.0f, -1.0f});
    CHECK(bed.view->GetZoom() == doctest::Approx(bed.view->ZoomMin()));

    bed.view->SetZoom(0.5f);
    const core::Float2 pan = bed.view->GetPan();
    bed.D().InjectMouseDown(at, MouseButton::Middle);
    bed.D().InjectMouseMove(core::Float2{at.x + 50.0f, at.y + 30.0f});
    bed.D().InjectMouseUp(core::Float2{at.x + 50.0f, at.y + 30.0f}, MouseButton::Middle);
    CHECK(bed.view->GetPan().x == doctest::Approx(pan.x - 100.0f));
    CHECK(bed.view->GetPan().y == doctest::Approx(pan.y - 60.0f));
    CHECK(bed.changes.IsEmpty());
}

TEST_CASE("GraphView: a double click on a node is the application's; framing fits the nodes in view")
{
    Bed bed;
    GraphId opened = 0;
    bed.view->SetOnNodeDoubleClick([&opened](GraphId node) { opened = node; });
    bed.Click(bed.Middle(bed.b));
    bed.Click(bed.Middle(bed.b));
    CHECK(opened == bed.b);
    CHECK(bed.changes.IsEmpty());

    bed.view->FrameAll();
    (void)bed.root->UpdateLayout();
    const Rect box = bed.view->GetContentBounds();
    const GraphId all[] = {bed.a, bed.b, bed.c};
    for (const GraphId node : all)
        CHECK(box.Contains(bed.view->NodeRect(node)));
    CHECK(bed.view->MadeNodeCount() == 3);

    // Asked before it has a size, it frames them once it is laid out.
    core::RefPtr<GraphView> later = core::MakeRef<GraphView>(core::DefaultAllocator());
    later->EditLayoutStyle([](LayoutStyle& s)
    {
        s.Width = LayoutLength::Px(300.0f);
        s.Height = LayoutLength::Px(200.0f);
    });
    later->SetSource(&bed.graph);
    later->FrameAll();
    bed.root->AddChild(later.Get());
    (void)bed.root->UpdateLayout();
    const Rect small = later->GetContentBounds();
    REQUIRE(small.width > 0.0f);
    for (const GraphId node : all)
        CHECK(small.Contains(later->NodeRect(node)));
    // It goes on fitting them as its nodes change size, until the canvas is moved.
    CHECK(later->IsFitting());
    later->EditLayoutStyle([](LayoutStyle& s) { s.Width = LayoutLength::Px(420.0f); });
    (void)bed.root->UpdateLayout();
    for (const GraphId node : all)
        CHECK(later->GetContentBounds().Contains(later->NodeRect(node)));
    later->SetPan(later->GetPan());
    CHECK_FALSE(later->IsFitting());
    later->SetSource(nullptr);

    // The selection alone, at no more than the zoom of 1.
    bed.view->SetSelectedNodes(core::Span<const GraphId>(&bed.c, 1));
    bed.view->FrameSelection();
    CHECK(bed.view->GetZoom() == doctest::Approx(1.0f));
    CHECK(box.Contains(bed.view->NodeRect(bed.c)));
    CHECK_FALSE(box.Intersects(bed.view->NodeRect(bed.a)));
}

TEST_CASE("GraphView: a drag from an output to an input that fits links them, the pins lit and dimmed as the source answers")
{
    Bed bed;
    const GraphId aIn = bed.PinOf(bed.a, u8"in"), aOut = bed.PinOf(bed.a, u8"out");
    const GraphId bIn = bed.PinOf(bed.b, u8"in"), bOut = bed.PinOf(bed.b, u8"out");
    const core::Float2 from = bed.PinAt(aOut);
    bed.Press(from);
    bed.D().InjectMouseMove(core::Float2{from.x + 40.0f, from.y + 150.0f});
    REQUIRE(bed.view->IsLinking());
    CHECK(Has(bed.Row(bed.b, bIn), u8"fits"));
    CHECK(Has(bed.Row(bed.a, aIn), u8"refused")); // a node does not feed itself
    CHECK(Has(bed.Row(bed.b, bOut), u8"refused")); // an output to an output
    bed.D().InjectMouseMove(bed.PinAt(bIn));
    CHECK(Has(bed.Row(bed.b, bIn), u8"target"));
    CHECK(bed.view->GetLinkCheck().Allowed);
    bed.D().InjectMouseUp(bed.PinAt(bIn), MouseButton::Left);
    CHECK_FALSE(bed.view->IsLinking());
    REQUIRE(bed.LinkCount() == 1);
    CHECK(bed.graph.State().Links[0].FromPin == aOut);
    CHECK(bed.graph.State().Links[0].ToPin == bIn);
    REQUIRE(bed.changes.Size() == 1);
    CHECK(bed.changes[0].Words == core::String(u8"Linked"));
    CHECK_FALSE(Has(bed.Row(bed.b, bIn), u8"target"));
    CHECK_FALSE(Has(bed.Row(bed.a, aIn), u8"refused"));

    // Onto a pin it may not reach: refused, and why; nothing made.
    bed.Pause();
    bed.Press(bed.PinAt(aOut));
    bed.D().InjectMouseMove(core::Float2{from.x + 40.0f, from.y + 150.0f});
    bed.D().InjectMouseMove(bed.PinAt(aIn));
    CHECK_FALSE(bed.view->GetLinkCheck().Allowed);
    CHECK(bed.view->GetLinkCheck().Reason == core::String(u8"A node does not feed itself"));
    bed.D().InjectMouseUp(bed.PinAt(aIn), MouseButton::Left);
    CHECK(bed.LinkCount() == 1);

    // Another output onto B's input: the link it would replace is known, and goes when it is made.
    bed.Pause();
    const GraphId d = bed.Add(u8"D", core::Float2{0.0f, 200.0f});
    const GraphId dOut = bed.PinOf(d, u8"out");
    bed.Press(bed.PinAt(dOut));
    bed.D().InjectMouseMove(core::Float2{400.0f, 300.0f});
    bed.D().InjectMouseMove(bed.PinAt(bIn));
    REQUIRE(bed.view->GetLinkCheck().Replaces.Size() == 1);
    CHECK(bed.view->GetLinkCheck().Replaces[0] == bed.graph.State().Links[0].Id);
    bed.D().InjectMouseUp(bed.PinAt(bIn), MouseButton::Left);
    REQUIRE(bed.LinkCount() == 1);
    CHECK(bed.graph.State().Links[0].FromPin == dOut);

    // Dropped on nothing, a new link is not made; Escape mid-drag ends it too.
    bed.Pause();
    bed.Drag(bed.PinAt(bOut), core::Float2{560.0f, 380.0f});
    CHECK(bed.LinkCount() == 1);
    bed.Press(bed.PinAt(aOut));
    bed.D().InjectMouseMove(bed.PinAt(bIn));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    CHECK_FALSE(bed.view->IsLinking());
    bed.D().InjectMouseUp(bed.PinAt(bIn), MouseButton::Left);
    CHECK(bed.LinkCount() == 1);
    CHECK(bed.changes.Size() == 2);
}

TEST_CASE("GraphView: an input's link end is dragged off to rewire it or let it go; from an input with none, a link begins backwards")
{
    Bed bed;
    const GraphId aOut = bed.PinOf(bed.a, u8"out"), bIn = bed.PinOf(bed.b, u8"in");
    GraphLinkInfo made;
    made.FromNode = bed.a;
    made.FromPin = aOut;
    made.ToNode = bed.b;
    made.ToPin = bIn;
    const GraphId link = bed.graph.AddLink(made);
    const GraphId d = bed.Add(u8"D", core::Float2{300.0f, 200.0f});
    const GraphId dIn = bed.PinOf(d, u8"in");

    bed.Drag(bed.PinAt(bIn), bed.PinAt(dIn));
    REQUIRE(bed.LinkCount() == 1);
    CHECK(bed.graph.State().Links[0].Id == link); // the same link, its end moved
    CHECK(bed.graph.State().Links[0].ToNode == d);
    CHECK(bed.graph.State().Links[0].ToPin == dIn);
    REQUIRE(bed.changes.Size() == 1);
    CHECK(bed.changes[0].Words == core::String(u8"Relinked"));

    // Off and back where it came from: nothing changes.
    bed.Pause();
    bed.Press(bed.PinAt(dIn));
    bed.D().InjectMouseMove(core::Float2{560.0f, 380.0f});
    bed.D().InjectMouseMove(bed.PinAt(dIn));
    CHECK(bed.view->GetLinkCheck().Allowed);
    bed.D().InjectMouseUp(bed.PinAt(dIn), MouseButton::Left);
    CHECK(bed.changes.Size() == 1);
    CHECK(bed.graph.State().Links[0].ToPin == dIn);

    // Dropped on nothing, it goes.
    bed.Pause();
    bed.Drag(bed.PinAt(dIn), core::Float2{560.0f, 380.0f});
    CHECK(bed.LinkCount() == 0);
    REQUIRE(bed.changes.Size() == 2);
    CHECK(bed.changes[1].Words == core::String(u8"Unlinked"));

    // From the input, now with none, to an output: a link from that output.
    bed.Pause();
    bed.Drag(bed.PinAt(dIn), bed.PinAt(aOut));
    REQUIRE(bed.LinkCount() == 1);
    CHECK(bed.graph.State().Links[0].FromPin == aOut);
    CHECK(bed.graph.State().Links[0].ToPin == dIn);

    // Read only, a drag from a pin makes nothing.
    bed.Pause();
    bed.view->SetReadOnly(true);
    bed.Drag(bed.PinAt(bed.PinOf(bed.b, u8"out")), bed.PinAt(dIn));
    CHECK(bed.LinkCount() == 1);
}

TEST_CASE("GraphView: a click selects a link, Shift or Ctrl adding or taking it away; the application highlights nodes and links")
{
    Bed bed;
    const GraphId aOut = bed.PinOf(bed.a, u8"out"), bIn = bed.PinOf(bed.b, u8"in");
    GraphLinkInfo made;
    made.FromNode = bed.a;
    made.FromPin = aOut;
    made.ToNode = bed.b;
    made.ToPin = bIn;
    const GraphId link = bed.graph.AddLink(made);
    core::Array<core::Float2> points(core::DefaultAllocator());
    REQUIRE(bed.view->LinkPoints(made, points));
    CHECK(points.Size() > 2); // a curve
    const core::Float2 from = bed.PinAt(aOut), to = bed.PinAt(bIn);
    const core::Float2 middle{(from.x + to.x) * 0.5f, (from.y + to.y) * 0.5f}; // the curve's middle
    CHECK(bed.view->HitLink(middle) == link);
    bed.Click(bed.Middle(bed.a));
    bed.Pause();
    bed.Click(middle);
    REQUIRE(bed.view->GetSelectedLinks().Size() == 1);
    CHECK(bed.view->IsLinkSelected(link));
    CHECK(bed.Selected() == 0); // a click on a link alone selects it alone
    bed.Pause();
    bed.Click(middle, KeyModCtrl);
    CHECK(bed.view->GetSelectedLinks().IsEmpty());
    bed.Pause();
    bed.Click(middle);
    bed.Pause();
    bed.Click(core::Float2{500.0f, 350.0f});
    CHECK(bed.view->GetSelectedLinks().IsEmpty());
    CHECK(bed.changes.IsEmpty());

    // An undo taking the link away takes it from the selection.
    bed.Pause();
    bed.Click(middle);
    const GraphId gone[] = {link};
    REQUIRE(bed.graph.Disconnect(gone));
    CHECK(bed.view->GetSelectedLinks().IsEmpty());

    bed.view->SetHighlightedNodes(core::Span<const GraphId>(&bed.a, 1));
    (void)bed.root->UpdateLayout();
    CHECK(bed.view->GetNodeWidget(bed.a)->HasClass(core::StringView(u8"highlighted")));
    CHECK_FALSE(bed.view->GetNodeWidget(bed.b)->HasClass(core::StringView(u8"highlighted")));
    bed.view->SetHighlightedLinks(core::Span<const GraphId>(&link, 1));
    CHECK(bed.view->IsLinkHighlighted(link));
}

TEST_CASE("GraphView: node links from just outside a node's edge, where the source takes them; the two ways apart; to itself after leaving it")
{
    Bed bed;
    const Rect atA = bed.view->NodeRect(bed.a);
    const Rect atB = bed.view->NodeRect(bed.b);
    const core::Float2 edgeA{atA.Right() + 3.0f, atA.y + 4.0f};
    const core::Float2 edgeB{atB.x - 3.0f, atB.y + 4.0f};
    // A graph of pins: the edge begins nothing.
    bed.Drag(edgeA, bed.Middle(bed.b));
    CHECK(bed.LinkCount() == 0);

    bed.graph.SetNodeLinks(true);
    bed.Pause();
    bed.Drag(edgeA, bed.Middle(bed.b));
    REQUIRE(bed.LinkCount() == 1);
    const GraphLinkInfo there = bed.graph.State().Links[0];
    CHECK(there.Kind == GraphLinkKind::Nodes);
    CHECK(there.FromNode == bed.a);
    CHECK(there.ToNode == bed.b);
    bed.Pause();
    bed.Drag(edgeB, bed.Middle(bed.a));
    REQUIRE(bed.LinkCount() == 2);
    const GraphLinkInfo back = bed.graph.State().Links[1];
    CHECK(back.FromNode == bed.b);
    // The two ways drawn apart, each with its own line to click.
    core::Array<core::Float2> one(core::DefaultAllocator()), other(core::DefaultAllocator());
    REQUIRE(bed.view->LinkPoints(there, one));
    REQUIRE(bed.view->LinkPoints(back, other));
    const core::Float2 m1{(one[0].x + one.Back().x) * 0.5f, (one[0].y + one.Back().y) * 0.5f};
    const core::Float2 m2{(other[0].x + other.Back().x) * 0.5f, (other[0].y + other.Back().y) * 0.5f};
    CHECK(core::Abs(m1.y - m2.y) >= 2.0f * GraphView::kParallelGap - 0.01f);
    CHECK(bed.view->HitLink(m1) == there.Id);
    CHECK(bed.view->HitLink(m2) == back.Id);

    // Straight back onto its own node: nothing; out and back: a link to itself.
    bed.Pause();
    bed.Drag(edgeA, bed.Middle(bed.a));
    CHECK(bed.LinkCount() == 2);
    bed.Pause();
    bed.Press(edgeA);
    bed.D().InjectMouseMove(core::Float2{560.0f, 380.0f});
    bed.D().InjectMouseMove(bed.Middle(bed.a));
    bed.D().InjectMouseUp(bed.Middle(bed.a), MouseButton::Left);
    REQUIRE(bed.LinkCount() == 3);
    CHECK(bed.graph.State().Links[2].FromNode == bed.a);
    CHECK(bed.graph.State().Links[2].ToNode == bed.a);
    REQUIRE(bed.view->LinkPoints(bed.graph.State().Links[2], one));
    CHECK(one.Size() > 2); // a loop
}

TEST_CASE("GraphView: the menu over nothing adds a node through the picker, by category with a search")
{
    Bed bed;
    const core::Float2 at{450.0f, 300.0f};
    bed.RightClick(at);
    Menu* menu = bed.view->GetMenu();
    REQUIRE(menu != nullptr);
    REQUIRE(Item(*menu, u8"Paste") != nullptr);
    CHECK_FALSE(Item(*menu, u8"Paste")->IsEnabled()); // nothing on the clipboard
    REQUIRE(Item(*menu, u8"Frame all") != nullptr);
    Activate(*menu, u8"Add node\u2026");
    REQUIRE(bed.view->IsNodePickerOpen());
    GraphNodePicker& picker = *bed.view->GetNodePicker();
    REQUIRE(picker.ShownCount() == 3); // Values: Number; Maths: Mix, Tint
    CHECK(picker.ShownAt(0).Name == core::String(u8"Number"));
    CHECK(picker.ShownAt(1).Name == core::String(u8"Mix"));
    picker.SetQuery(core::StringView(u8"MI"));
    REQUIRE(picker.ShownCount() == 1);
    CHECK(picker.ShownAt(0).Name == core::String(u8"Mix"));
    REQUIRE(picker.ChooseCurrent());
    CHECK_FALSE(bed.view->IsNodePickerOpen());
    REQUIRE(bed.changes.Size() == 1);
    CHECK(bed.changes[0].Words == core::String(u8"Added Mix"));
    REQUIRE(bed.Selected() == 1);
    const GraphNodeInfo* made = bed.graph.GetNode(bed.view->GetSelectedNodes()[0]);
    REQUIRE(made != nullptr);
    CHECK(made->Position.x == doctest::Approx(448.0f)); // where the menu was, on the grid
    CHECK(made->Position.y == doctest::Approx(304.0f));

    // By the keys: Down to the second kind, Enter.
    REQUIRE(bed.view->OpenNodePicker(core::Float2{100.0f, 300.0f}));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Down));
    CHECK(picker.GetCurrent() == 1);
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Return));
    CHECK_FALSE(bed.view->IsNodePickerOpen());
    REQUIRE(bed.changes.Size() == 2);
    CHECK(bed.changes[1].Words == core::String(u8"Added Mix"));
}

TEST_CASE("GraphView: a link dropped on nothing opens the picker of the kinds it reaches; the node chosen comes linked, one change")
{
    Bed bed;
    const GraphId aOut = bed.PinOf(bed.a, u8"out");
    bed.Drag(bed.PinAt(aOut), core::Float2{450.0f, 300.0f});
    REQUIRE(bed.view->IsNodePickerOpen());
    GraphNodePicker& picker = *bed.view->GetNodePicker();
    REQUIRE(picker.ShownCount() == 2); // those with an input: Mix and Tint
    CHECK(picker.ShownAt(0).Name == core::String(u8"Mix"));
    CHECK(picker.ShownAt(1).Name == core::String(u8"Tint"));
    REQUIRE(picker.Choose(0));
    REQUIRE(bed.changes.Size() == 1);
    CHECK(bed.changes[0].Words == core::String(u8"Added Mix"));
    REQUIRE(bed.LinkCount() == 1);
    const GraphLinkInfo link = bed.graph.State().Links[0];
    CHECK(link.FromPin == aOut);
    CHECK(link.ToNode == bed.view->GetSelectedNodes()[0]);
    CHECK(link.ToPin == bed.graph.FindPin(link.ToNode, core::StringView(u8"a"), GraphPinDirection::Input));
}

TEST_CASE("GraphView: Delete, Escape, Ctrl+C and Ctrl+V as the property grid's; Duplicate from a node's menu")
{
    Bed bed;
    bed.Click(bed.Middle(bed.a));
    bed.Pause();
    bed.Click(bed.Middle(bed.b), KeyModShift);
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::C), KeyModCtrl);
    CHECK(bed.clipboard.HasText());
    bed.D().InjectMouseMove(core::Float2{450.0f, 300.0f});
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::V), KeyModCtrl);
    REQUIRE(bed.changes.Size() == 1);
    CHECK(bed.changes[0].Words == core::String(u8"Pasted"));
    CHECK(bed.NodeCount() == 5);
    REQUIRE(bed.Selected() == 2); // the copies
    CHECK_FALSE(bed.view->IsNodeSelected(bed.a));
    const GraphNodeInfo* first = bed.graph.GetNode(bed.view->GetSelectedNodes()[0]);
    REQUIRE(first != nullptr);
    CHECK(first->Position.y == doctest::Approx(300.0f)); // their top-left at the pointer

    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Delete));
    CHECK(bed.NodeCount() == 3);
    REQUIRE(bed.changes.Size() == 2);
    CHECK(bed.changes[1].Words == core::String(u8"Deleted"));
    CHECK(bed.Selected() == 0);

    bed.Pause();
    bed.Click(bed.Middle(bed.a));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    CHECK(bed.Selected() == 0);

    // A selected link goes with Delete.
    GraphLinkInfo made;
    made.FromNode = bed.a;
    made.FromPin = bed.PinOf(bed.a, u8"out");
    made.ToNode = bed.b;
    made.ToPin = bed.PinOf(bed.b, u8"in");
    (void)bed.graph.AddLink(made);
    const core::Float2 from = bed.PinAt(made.FromPin), to = bed.PinAt(made.ToPin);
    bed.Pause();
    bed.Click(core::Float2{(from.x + to.x) * 0.5f, (from.y + to.y) * 0.5f});
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Delete));
    CHECK(bed.LinkCount() == 0);
    CHECK(bed.changes.Back().Words == core::String(u8"Unlinked"));

    // Duplicate beside it, from its menu (the clipboard kept).
    bed.clipboard.SetText(core::StringView(u8"kept"));
    bed.RightClick(bed.Middle(bed.a));
    REQUIRE(bed.view->GetMenu() != nullptr);
    Activate(*bed.view->GetMenu(), u8"Duplicate");
    CHECK(bed.NodeCount() == 4);
    REQUIRE(bed.Selected() == 1);
    const GraphNodeInfo* copy = bed.graph.GetNode(bed.view->GetSelectedNodes()[0]);
    REQUIRE(copy != nullptr);
    CHECK(copy->Title == core::String(u8"A"));
    CHECK(copy->Position.x == doctest::Approx(32.0f));
    CHECK(copy->Position.y == doctest::Approx(32.0f));
    CHECK(bed.clipboard.GetText() == core::String(u8"kept"));

    // Read only: no Duplicate or Delete, and Delete deletes nothing.
    bed.view->SetReadOnly(true);
    bed.Pause();
    bed.RightClick(bed.Middle(bed.a));
    REQUIRE(bed.view->GetMenu() != nullptr);
    CHECK(Item(*bed.view->GetMenu(), u8"Copy") != nullptr);
    CHECK(Item(*bed.view->GetMenu(), u8"Duplicate") == nullptr);
    CHECK(Item(*bed.view->GetMenu(), u8"Delete") == nullptr);
    bed.D().CloseAllPopups();
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Delete));
    CHECK(bed.NodeCount() == 4);
}

TEST_CASE("GraphView: a node's menu begins a node link that follows the pointer until a click; a link's menu deletes it")
{
    Bed bed;
    bed.RightClick(bed.Middle(bed.a));
    REQUIRE(bed.view->GetMenu() != nullptr);
    CHECK(Item(*bed.view->GetMenu(), u8"Add transition") == nullptr); // a graph of pins
    bed.D().CloseAllPopups();

    bed.graph.SetNodeLinks(true);
    bed.Pause();
    bed.RightClick(bed.Middle(bed.a));
    REQUIRE(bed.view->GetMenu() != nullptr);
    Activate(*bed.view->GetMenu(), u8"Add transition");
    REQUIRE(bed.view->IsLinking());
    bed.D().InjectMouseMove(bed.Middle(bed.b));
    CHECK(bed.view->GetLinkCheck().Allowed);
    bed.Click(bed.Middle(bed.b));
    CHECK_FALSE(bed.view->IsLinking());
    REQUIRE(bed.LinkCount() == 1);
    const GraphLinkInfo link = bed.graph.State().Links[0];
    CHECK(link.Kind == GraphLinkKind::Nodes);
    CHECK(link.FromNode == bed.a);
    CHECK(link.ToNode == bed.b);

    // Escape ends one unmade.
    bed.Pause();
    bed.RightClick(bed.Middle(bed.b));
    Activate(*bed.view->GetMenu(), u8"Add transition");
    REQUIRE(bed.view->IsLinking());
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    CHECK_FALSE(bed.view->IsLinking());
    CHECK(bed.LinkCount() == 1);

    // The link's menu deletes it.
    core::Array<core::Float2> points(core::DefaultAllocator());
    REQUIRE(bed.view->LinkPoints(link, points));
    bed.Pause();
    bed.RightClick(core::Float2{(points[0].x + points.Back().x) * 0.5f, (points[0].y + points.Back().y) * 0.5f});
    REQUIRE(bed.view->GetMenu() != nullptr);
    Activate(*bed.view->GetMenu(), u8"Delete");
    CHECK(bed.LinkCount() == 0);
}

namespace
{
    // The bed panned so the graph's (-100, -100) is at the view's top-left, not snapping, with a frame
    // round A and B: from (-20, -40), 480 by 200.
    GraphId Framed(Bed& bed)
    {
        bed.view->SetSnapToGrid(false);
        bed.view->SetPan(core::Float2{-100.0f, -100.0f});
        GraphFrameInfo frame;
        frame.Title = core::String(u8"Group");
        frame.Position = core::Float2{-20.0f, -40.0f};
        frame.Size = core::Float2{480.0f, 200.0f};
        const GraphId id = bed.graph.CreateFrame(frame);
        (void)bed.root->UpdateLayout();
        bed.changes.Clear();
        return id;
    }
    GraphFrameInfo FrameOf(const Bed& bed, GraphId frame)
    {
        for (const GraphFrameInfo& at : bed.graph.State().Frames)
            if (at.Id == frame)
                return at;
        return GraphFrameInfo{};
    }
    // A mock font: 6px a byte, 12px a line.
    class SixFont : public foundation::fonts::IFont
    {
    public:
        core::StringView FamilyName() const override { return core::StringView(u8"six"); }
        core::Span<const core::u8> SourceData() const override { return {}; }
        foundation::fonts::FontMetrics Metrics() const override
        {
            foundation::fonts::FontMetrics m;
            m.ascent = 10.0f;
            m.descent = -2.0f;
            m.lineHeight = 12.0f;
            m.pixelHeight = 10.0f;
            m.scale = 1.0f;
            return m;
        }
        core::f32 PixelHeight() const override { return 10.0f; }
        foundation::fonts::GlyphInfo GetGlyphInfo(core::i32 cp) const override
        {
            foundation::fonts::GlyphInfo g;
            g.codepoint = cp;
            g.advanceWidth = 6.0f;
            return g;
        }
        core::f32 GetKerning(core::i32, core::i32) const override { return 0.0f; }
        bool HasGlyph(core::i32) const override { return true; }
        core::f32 MeasureString(core::StringView text) const override { return static_cast<core::f32>(text.Size()) * 6.0f; }
        core::f32 MeasureString(core::StringView text, core::Array<foundation::fonts::GlyphPosition>&) const override { return MeasureString(text); }
    };
    usize ChildIndex(foundation::gui::Node& parent, foundation::gui::Node* child)
    {
        for (usize i = 0; i < parent.ChildCount(); ++i)
            if (parent.GetChildAt(i) == child)
                return i;
        return parent.ChildCount();
    }
}

TEST_CASE("GraphView: a frame stands behind the nodes; dragged by its title it moves with what lies inside, one change")
{
    Bed bed;
    const GraphId frame = Framed(bed);
    REQUIRE(bed.view->GetFrameWidget(frame) != nullptr);
    CHECK(bed.view->GetFrameWidget(frame)->GetTitleLabel().GetText() == core::StringView(u8"Group"));
    CHECK(ChildIndex(*bed.view, bed.view->GetFrameWidget(frame)) < ChildIndex(*bed.view, bed.view->GetNodeWidget(bed.a)));
    const Rect r = bed.view->FrameRect(frame);
    CHECK(r.x == doctest::Approx(80.0f));
    CHECK(r.y == doctest::Approx(60.0f));
    const core::Float2 title{r.x + 30.0f, r.y + 10.0f};

    bed.Click(title);
    CHECK(bed.view->IsFrameSelected(frame));
    CHECK(bed.view->GetFrameWidget(frame)->HasClass(core::StringView(u8"selected")));
    CHECK(bed.Selected() == 0);
    bed.Pause();
    bed.Drag(title, core::Float2{title.x + 37.0f, title.y + 21.0f});
    CHECK(FrameOf(bed, frame).Position.x == doctest::Approx(17.0f));
    CHECK(FrameOf(bed, frame).Position.y == doctest::Approx(-19.0f));
    CHECK(bed.Where(bed.a).x == doctest::Approx(37.0f)); // inside it
    CHECK(bed.Where(bed.b).x == doctest::Approx(337.0f));
    CHECK(bed.Where(bed.c).x == doctest::Approx(1200.0f)); // outside
    REQUIRE(bed.changes.Size() == 1);
    CHECK(bed.changes[0].Words == core::String(u8"Moved"));

    // Escape mid-drag puts it all back.
    bed.Pause();
    const core::Float2 again{bed.view->FrameRect(frame).x + 30.0f, bed.view->FrameRect(frame).y + 10.0f};
    bed.Press(again);
    bed.D().InjectMouseMove(core::Float2{again.x + 50.0f, again.y});
    CHECK(bed.Where(bed.a).x == doctest::Approx(87.0f));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    bed.D().InjectMouseUp(core::Float2{again.x + 50.0f, again.y}, MouseButton::Left);
    CHECK(bed.Where(bed.a).x == doctest::Approx(37.0f));
    CHECK(FrameOf(bed, frame).Position.x == doctest::Approx(17.0f));
    CHECK(bed.changes.Size() == 1);

    // A box over the whole of it selects it, and the nodes it touches.
    bed.Pause();
    bed.Drag(core::Float2{599.0f, 395.0f}, core::Float2{60.0f, 50.0f}); // it reaches 597 now
    CHECK(bed.view->IsFrameSelected(frame));
    CHECK(bed.Selected() == 2);
}

TEST_CASE("GraphView: a frame's edges resize it, previewed and one change on release; Escape cancels")
{
    Bed bed;
    const GraphId frame = Framed(bed);
    Rect r = bed.view->FrameRect(frame);
    const core::Float2 right{r.Right() - 2.0f, r.y + r.height * 0.5f};
    bed.Press(right);
    bed.D().InjectMouseMove(core::Float2{right.x + 30.0f, right.y});
    CHECK(bed.view->FrameRect(frame).width == doctest::Approx(510.0f)); // previewed
    CHECK(bed.changes.IsEmpty());
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Escape));
    bed.D().InjectMouseUp(core::Float2{right.x + 30.0f, right.y}, MouseButton::Left);
    CHECK(bed.view->FrameRect(frame).width == doctest::Approx(480.0f));
    CHECK(bed.changes.IsEmpty());

    bed.Pause();
    bed.Drag(right, core::Float2{right.x + 60.0f, right.y});
    CHECK(FrameOf(bed, frame).Size.x == doctest::Approx(540.0f));
    REQUIRE(bed.changes.Size() == 1);
    CHECK(bed.changes[0].Words == core::String(u8"Edited a frame"));

    // From its bottom start corner: wider to the start, taller.
    bed.Pause();
    r = bed.view->FrameRect(frame);
    const core::Float2 corner{r.x + 2.0f, r.Bottom() - 2.0f};
    bed.Drag(corner, core::Float2{corner.x - 30.0f, corner.y + 40.0f});
    CHECK(FrameOf(bed, frame).Position.x == doctest::Approx(-50.0f));
    CHECK(FrameOf(bed, frame).Position.y == doctest::Approx(-40.0f));
    CHECK(FrameOf(bed, frame).Size.x == doctest::Approx(570.0f));
    CHECK(FrameOf(bed, frame).Size.y == doctest::Approx(240.0f));

    // No smaller than its least.
    bed.Pause();
    r = bed.view->FrameRect(frame);
    const core::Float2 left{r.x + 2.0f, r.y + r.height * 0.5f};
    bed.Drag(left, core::Float2{left.x + 1000.0f, left.y});
    CHECK(FrameOf(bed, frame).Size.x == doctest::Approx(GraphView::kFrameMinWidth));
}

TEST_CASE("GraphView: a frame's title and body edit in place; the menu adds a frame round the selection and a comment; Delete deletes them")
{
    Bed bed;
    const GraphId frame = Framed(bed);
    GraphFrameWidget& widget = *bed.view->GetFrameWidget(frame);
    widget.GetTitleLabel().BeginEdit();
    REQUIRE(widget.GetTitleLabel().GetEditor() != nullptr);
    widget.GetTitleLabel().GetEditor()->SetText(core::StringView(u8"Renamed"));
    REQUIRE(widget.GetTitleLabel().EndEdit(true));
    CHECK(FrameOf(bed, frame).Title == core::String(u8"Renamed"));
    REQUIRE(bed.changes.Size() == 1);
    CHECK(bed.changes[0].Words == core::String(u8"Edited a frame"));

    // While its body is edited, the keys are the field's: Delete deletes no node.
    bed.Click(bed.Middle(bed.a));
    widget.EditBody();
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Delete));
    CHECK(bed.NodeCount() == 3);
    widget.GetBodyLabel().GetEditor()->SetText(core::StringView(u8"A note"));
    REQUIRE(widget.GetBodyLabel().EndEdit(true));
    CHECK(FrameOf(bed, frame).Body == core::String(u8"A note"));
    (void)bed.root->UpdateLayout();
    CHECK(widget.GetBodyLabel().IsDisplayed());

    // Its title's menu renames it.
    bed.Pause();
    bed.RightClick(core::Float2{bed.view->FrameRect(frame).x + 30.0f, bed.view->FrameRect(frame).y + 10.0f});
    REQUIRE(bed.view->GetMenu() != nullptr);
    Activate(*bed.view->GetMenu(), u8"Rename");
    CHECK(widget.GetTitleLabel().IsEditing());
    REQUIRE(widget.GetTitleLabel().EndEdit(false));

    // Round the selected nodes, from the menu over nothing.
    bed.Pause();
    bed.Click(bed.Middle(bed.a));
    bed.Pause();
    bed.Click(bed.Middle(bed.b), KeyModShift);
    bed.RightClick(core::Float2{300.0f, 380.0f});
    REQUIRE(bed.view->GetMenu() != nullptr);
    Activate(*bed.view->GetMenu(), u8"Add frame");
    REQUIRE(bed.graph.State().Frames.Size() == 2);
    const GraphFrameInfo round = bed.graph.State().Frames[1];
    CHECK(bed.changes.Back().Words == core::String(u8"Framed"));
    const Rect inside{round.Position.x, round.Position.y, round.Size.x, round.Size.y};
    CHECK(inside.Contains(Rect{0.0f, 0.0f, bed.view->NodeSize(bed.a).x, bed.view->NodeSize(bed.a).y}));
    CHECK(inside.Contains(Rect{300.0f, 0.0f, bed.view->NodeSize(bed.b).x, bed.view->NodeSize(bed.b).y}));
    CHECK(bed.view->IsFrameSelected(round.Id));

    // A comment where the menu was, nothing selected: a frame with a body.
    bed.Pause();
    bed.Click(core::Float2{300.0f, 380.0f});
    bed.RightClick(core::Float2{300.0f, 380.0f});
    Activate(*bed.view->GetMenu(), u8"Add comment");
    REQUIRE(bed.graph.State().Frames.Size() == 3);
    const GraphFrameInfo comment = bed.graph.State().Frames[2];
    CHECK_FALSE(comment.Body.IsEmpty());
    (void)bed.root->UpdateLayout();
    REQUIRE(bed.view->GetFrameWidget(comment.Id) != nullptr);
    CHECK(bed.view->GetFrameWidget(comment.Id)->GetBodyLabel().IsDisplayed());

    // Delete deletes the selected frame, and nothing else.
    REQUIRE(bed.view->IsFrameSelected(comment.Id));
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Delete));
    CHECK(bed.graph.State().Frames.Size() == 2);
    CHECK(bed.changes.Back().Words == core::String(u8"Deleted a frame"));
    CHECK(bed.NodeCount() == 3);
    CHECK(bed.view->GetSelectedFrames().IsEmpty());
}

TEST_CASE("GraphView: a comment longer than its frame scrolls in its box, to the caret while typed in and under the wheel")
{
    Bed bed;
    const GraphId frame = Framed(bed);
    GraphFrameWidget& widget = *bed.view->GetFrameWidget(frame);
    foundation::fonts::CachedFont font{core::DefaultAllocator(), core::DefaultAllocator().New<SixFont>(), nullptr, nullptr};
    widget.GetBodyLabel().SetFont(&font);
    widget.EditBody();
    TextArea* area = core::Cast<TextArea>(widget.GetBodyLabel().GetEditor());
    REQUIRE(area != nullptr);
    REQUIRE(area->IsFocused());
    // Thirty lines of 12 in a frame 200 tall.
    for (int i = 0; i < 30; ++i)
    {
        bed.D().InjectText(core::StringView(u8"line"));
        bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Return));
    }
    (void)bed.root->UpdateLayout();
    UIWidget& box = widget.GetBodyBox();
    EditableLabel& label = widget.GetBodyLabel();
    const Rect frameAt = widget.GetScreenBounds();
    CHECK(box.GetScreenBounds().Bottom() <= frameAt.Bottom() - 7.5f); // the frame's padding below it
    // As tall as its text, the box scrolled to its end, where the caret is.
    CHECK(label.GetSize().y == doctest::Approx(31.0f * 12.0f));
    REQUIRE(box.IsScrollContainer());
    CHECK(box.GetScrollOffset().y == doctest::Approx(label.GetSize().y - box.GetContentBounds().height));
    CHECK(area->GetScrollY() == doctest::Approx(0.0f));
    CHECK(widget.ClipsChildren());
    // Back to the top (Ctrl+Home), the box follows the caret there.
    bed.D().InjectKeyDown(static_cast<core::u32>(KeyCode::Home), static_cast<core::u32>(KeyModCtrl));
    CHECK(box.GetScrollOffset().y == doctest::Approx(0.0f));

    // Committed, it is as tall as its text, the box scrolling it; it reads from its top.
    REQUIRE(label.EndEdit(true));
    (void)bed.root->UpdateLayout();
    CHECK(label.GetSize().y == doctest::Approx(31.0f * 12.0f));
    CHECK(label.BaselineAt(label.GetSize()) == doctest::Approx(label.GetChrome().Top + 10.0f));
    CHECK(box.GetScrollOffset().y == doctest::Approx(0.0f));
    const f32 zoom = bed.view->GetZoom();
    const Rect boxAt = box.GetScreenBounds();
    const core::Float2 over{boxAt.x + 200.0f, boxAt.y + 40.0f}; // between A and B
    bed.D().InjectMouseMove(over);
    (void)bed.D().InjectMouseWheel(over, core::Float2{0.0f, -1.0f});
    CHECK(box.GetScrollTarget().y > 0.0f);
    CHECK(bed.view->GetZoom() == doctest::Approx(zoom)); // the box took it
    // At its top, the wheel up is the view's zoom again.
    box.SetScrollOffset(core::Float2{0.0f, 0.0f});
    (void)bed.D().InjectMouseWheel(over, core::Float2{0.0f, 1.0f});
    CHECK(bed.view->GetZoom() > zoom);
    label.SetFont(nullptr);
    (void)bed.root->UpdateLayout();
}
