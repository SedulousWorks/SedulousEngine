// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Docking - a dock layout saved and restored (D2 of Specs/gui-lab-evolution-3.md): through the
// engine's text serializer and back whole; another version refused; a broken layout refused and
// the current one left as it was; panels not registered kept as placeholders, registered ones not
// named put at their default place; a floating window off every screen brought back onto one.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.xml;
import foundation.xml.serialization;
import foundation.gui.docking;

using namespace foundation::gui;
namespace core = foundation::core;
namespace xml = foundation::xml;
using core::f32;

namespace
{
    core::StringView SV(const char8_t* s) { return core::StringView(s); }

    core::String Save(DockLayoutDocument& document)
    {
        xml::XmlSerializer writer(core::DefaultAllocator());
        document.Serialize(writer);
        REQUIRE(writer.IsOk());
        core::String text;
        writer.GetOutput(text);
        return text;
    }
    // The text read into `out`; whether it read.
    bool Load(core::StringView text, DockLayoutDocument& out)
    {
        xml::XmlDocument doc(core::DefaultAllocator());
        if (doc.Parse(text) != xml::XmlResult::Ok)
            return false;
        xml::XmlSerializer reader(doc);
        out.Serialize(reader);
        return reader.IsOk();
    }
    // `text` with each `from` made `to`; `count` says how many there were.
    core::String Replaced(core::StringView text, core::StringView from, core::StringView to, core::usize* count = nullptr)
    {
        core::String out;
        core::usize found = 0;
        for (core::usize i = 0; i < text.Size();)
            if (i + from.Size() <= text.Size() && text.SubStr(i, from.Size()) == from)
            {
                out.Append(to);
                i += from.Size();
                ++found;
            }
            else
                out.PushBack(text[i++]);
        if (count != nullptr)
            *count = found;
        return out;
    }
    DockLayout Sample()
    {
        DockLayout layout;
        const DockNodeId central = layout.CentralStack();
        REQUIRE(layout.InsertTab(SV(u8"scene"), central).Ok());
        REQUIRE(layout.InsertBeside(SV(u8"hierarchy"), central, DockSide::Start, 0.2f).Ok());
        REQUIRE(layout.InsertAtEdge(SV(u8"console"), layout.MainSurface(), DockSide::Bottom, 0.3f).Ok());
        REQUIRE(layout.InsertTab(SV(u8"log"), layout.StackOf(SV(u8"console"))).Ok());
        REQUIRE(layout.Float(SV(u8"profiler"), core::Rectangle{1500.0f, 200.0f, 500.0f, 400.0f}).Ok());
        REQUIRE(layout.InsertBeside(SV(u8"inspector"), central, DockSide::End).Ok());
        REQUIRE(layout.Close(SV(u8"inspector")).Ok());
        return layout;
    }
}

TEST_CASE("dock document: a layout through text and back, whole")
{
    DockLayoutDocument saved;
    saved.Layout = Sample();
    const core::String text = Save(saved);
    DockLayoutDocument loaded;
    REQUIRE(Load(text.AsView(), loaded));
    const DockLayout& l = loaded.Layout;
    core::String why;
    CHECK(l.CheckInvariants(&why));
    CHECK(l.Surfaces().Size() == 2u);
    CHECK(l.StackOf(SV(u8"log")) == l.StackOf(SV(u8"console")));
    CHECK(l.FindNode(l.StackOf(SV(u8"console")))->Active == 1u);
    CHECK(l.FindHidden(SV(u8"inspector")) != nullptr);
    CHECK(l.FindSurface(l.SurfaceOf(l.StackOf(SV(u8"profiler"))))->Bounds.x == doctest::Approx(1500.0f));
    CHECK(Save(loaded) == text); // nothing lost or changed on the way
    // Operations go on from where it was: new ids do not collide.
    DockLayout again = l;
    CHECK(again.InsertTab(SV(u8"assets"), again.StackOf(SV(u8"hierarchy"))).Ok());
    CHECK(again.CheckInvariants(&why));
}

TEST_CASE("dock document: a layout of another version is refused")
{
    DockLayoutDocument saved;
    saved.Layout = Sample();
    const core::String text = Save(saved);
    core::usize found = 0;
    const core::String stale = Replaced(text.AsView(), SV(u8"<u32 name=\"version\">1</u32>"), SV(u8"<u32 name=\"version\">2</u32>"), &found);
    REQUIRE(found == 1u); // the document's version, stored once
    DockLayoutDocument loaded;
    CHECK_FALSE(Load(stale.AsView(), loaded));
}

TEST_CASE("dock document: a broken layout is refused, and the current one stays")
{
    DockLayout current = Sample();
    DockLayoutDocument saved;
    saved.Layout = current;
    const core::String was = Save(saved);
    // A panel docked in two stacks in the text.
    core::usize found = 0;
    const core::String broken = Replaced(was.AsView(), SV(u8"<string>hierarchy</string>"), SV(u8"<string>scene</string>"), &found);
    REQUIRE(found >= 1u); // its stack's, and a closed panel's neighbour
    DockLayoutDocument read;
    REQUIRE(Load(broken.AsView(), read)); // it reads, but does not hold together
    const DockOutcome adopted = current.Adopt(read.Layout, {});
    CHECK_FALSE(adopted.Ok());
    CHECK(adopted.Refused == core::String(u8"a panel docked twice"));
    saved.Layout = current;
    CHECK(Save(saved) == was); // unchanged
    // Ids past the next one made (a file edited by hand): a new node would collide.
    const core::String behind = Replaced(was.AsView(), SV(u8"<u32 name=\"nextNode\">8</u32>"), SV(u8"<u32 name=\"nextNode\">3</u32>"), &found);
    REQUIRE(found == 1u);
    REQUIRE(Load(behind.AsView(), read));
    CHECK(current.Adopt(read.Layout, {}).Refused == core::String(u8"a node's id past the next one made"));
}

TEST_CASE("dock document: placeholders kept, registered panels it does not name at their default place, floats brought on screen")
{
    DockLayoutDocument saved;
    saved.Layout = Sample();
    DockLayoutDocument read;
    REQUIRE(Load(Save(saved).AsView(), read));
    DockLayout layout;
    const DockDefault known[] = {
        DockDefault{core::String(u8"scene"), true, DockSide::End, 0.25f},       // named: stays where it is
        DockDefault{core::String(u8"assets"), false, DockSide::Bottom, 0.25f},  // not named: at the bottom
        DockDefault{core::String(u8"documents"), true, DockSide::End, 0.25f},   // not named: a central tab
    };
    const core::Rectangle screens[] = {core::Rectangle{0.0f, 0.0f, 1280.0f, 720.0f}};
    REQUIRE(layout.Adopt(read.Layout, core::Span<const DockDefault>(known, 3), core::Span<const core::Rectangle>(screens, 1)).Ok());
    CHECK(layout.StackOf(SV(u8"hierarchy")) != kNoDock); // not registered: kept, a placeholder
    CHECK(layout.StackOf(SV(u8"documents")) == layout.CentralStack());
    const DockNodeId assets = layout.StackOf(SV(u8"assets"));
    REQUIRE(assets != kNoDock);
    CHECK(layout.FindNode(layout.FindSurface(layout.MainSurface())->Root)->Children.Back() == assets); // along the bottom
    CHECK(layout.FindHidden(SV(u8"inspector")) != nullptr); // closed stays closed
    // The profiler floated at 1500 across, off the one screen: back on it.
    const DockSurface* floating = layout.FindSurface(layout.SurfaceOf(layout.StackOf(SV(u8"profiler"))));
    REQUIRE(floating != nullptr);
    CHECK(floating->Bounds.x + floating->Bounds.width <= 1280.0f);
    CHECK(floating->Bounds.width == doctest::Approx(500.0f));
    core::String why;
    CHECK(layout.CheckInvariants(&why));
}
