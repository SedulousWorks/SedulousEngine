// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Docking - :document partition: DockLayoutDocument, a dock layout as the engine's serializer
// reads and writes it (D2 of Specs/gui-lab-evolution-3.md).
//
// The layout itself stays a value (a drop's preview runs an operation on a copy); the document
// holds one and is what an application saves and restores. Docking reads and writes no files:
// where a layout is kept, when it is saved and where named presets live are the application's;
// hosting knows nothing of it. The payload is versioned: one written under another version is
// refused until a migration reads it. A restore reads into a document of its own and is adopted
// with DockLayout::Adopt, which checks it first, so a bad file leaves the current layout as it is.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui.docking:document;

import foundation.core;
import :layout;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    class DockLayoutDocument : public ISerializable
    {
        RTTI_OBJECT(DockLayoutDocument, ISerializable)
    public:
        DockLayout Layout;

        void Serialize(ISerializer& ar) override
        {
            BeginVersionedPayload(ar, StaticType());
            const bool reading = ar.Mode() == SerializeMode::Read;
            DockLayout& l = Layout;
            core::Serialize(ar, "nextNode", l.m_nextNode);
            core::Serialize(ar, "nextSurface", l.m_nextSurface);

            u32 surfaceCount = static_cast<u32>(l.m_surfaces.Size());
            ar.Key("surfaces");
            ar.BeginArray(surfaceCount);
            if (reading)
                l.m_surfaces.Clear();
            for (u32 i = 0; i < surfaceCount; ++i)
            {
                DockSurface surface = reading ? DockSurface{} : l.m_surfaces[i];
                String kind(surface.Kind == DockSurfaceKind::Main ? u8"main" : u8"floating");
                ar.BeginObject();
                core::Serialize(ar, "id", surface.Id);
                core::Serialize(ar, "kind", kind);
                core::Serialize(ar, "root", surface.Root);
                core::Serialize(ar, "x", surface.Bounds.x);
                core::Serialize(ar, "y", surface.Bounds.y);
                core::Serialize(ar, "width", surface.Bounds.width);
                core::Serialize(ar, "height", surface.Bounds.height);
                core::Serialize(ar, "screen", surface.Screen);
                core::Serialize(ar, "scale", surface.Scale);
                core::Serialize(ar, "maximized", surface.Maximized);
                ar.EndObject();
                if (reading)
                {
                    surface.Kind = kind.AsView() == core::StringView(u8"main") ? DockSurfaceKind::Main : DockSurfaceKind::Floating;
                    l.m_surfaces.PushBack(core::Move(surface));
                }
            }
            ar.EndArray();

            u32 nodeCount = static_cast<u32>(l.m_nodes.Size());
            ar.Key("nodes");
            ar.BeginArray(nodeCount);
            if (reading)
                l.m_nodes.Clear();
            for (u32 i = 0; i < nodeCount; ++i)
            {
                DockNode node = reading ? DockNode{} : l.m_nodes[i];
                String kind(node.IsStack() ? u8"stack" : u8"split");
                String axis(node.Axis == DockAxis::Vertical ? u8"vertical" : u8"horizontal");
                ar.BeginObject();
                core::Serialize(ar, "id", node.Id);
                core::Serialize(ar, "parent", node.Parent);
                core::Serialize(ar, "kind", kind);
                core::Serialize(ar, "axis", axis);
                core::Serialize(ar, "children", node.Children);
                core::Serialize(ar, "weights", node.Weights);
                core::Serialize(ar, "panels", node.Panels);
                core::Serialize(ar, "active", node.Active);
                core::Serialize(ar, "flags", node.Flags);
                ar.EndObject();
                if (reading)
                {
                    node.Kind = kind.AsView() == core::StringView(u8"split") ? DockNodeKind::Split : DockNodeKind::Stack;
                    node.Axis = axis.AsView() == core::StringView(u8"vertical") ? DockAxis::Vertical : DockAxis::Horizontal;
                    l.m_nodes.PushBack(core::Move(node));
                }
            }
            ar.EndArray();

            u32 hiddenCount = static_cast<u32>(l.m_hidden.Size());
            ar.Key("hidden");
            ar.BeginArray(hiddenCount);
            if (reading)
                l.m_hidden.Clear();
            for (u32 i = 0; i < hiddenCount; ++i)
            {
                DockHidden hidden = reading ? DockHidden{} : l.m_hidden[i];
                ar.BeginObject();
                core::Serialize(ar, "panel", hidden.Panel);
                core::Serialize(ar, "surface", hidden.Last.Surface);
                core::Serialize(ar, "stack", hidden.Last.Stack);
                core::Serialize(ar, "index", hidden.Last.Index);
                core::Serialize(ar, "neighbours", hidden.Last.Neighbours);
                ar.EndObject();
                if (reading)
                    l.m_hidden.PushBack(core::Move(hidden));
            }
            ar.EndArray();
            EndVersionedPayload(ar);
        }
    };

    RTTI_DEFINE_OBJECT_VERSIONED(DockLayoutDocument, "rtti::gui::docking", 1)
}
