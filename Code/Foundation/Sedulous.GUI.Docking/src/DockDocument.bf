using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// DockLayoutDocument: a dock layout as the engine's serializer reads and writes it (D2 of
// Specs/gui-lab-evolution-3.md).
//
// The layout itself stays a value (a drop's preview runs an operation on a copy); the document
// holds one and is what an application saves and restores. Docking reads and writes no files:
// where a layout is kept, when it is saved and where named presets live are the application's;
// hosting knows nothing of it. The payload is versioned: one written under another version is
// refused until a migration reads it. A restore reads into a document of its own and is adopted
// with DockLayout.Adopt, which checks it first, so a bad file leaves the current layout as it is.

class DockLayoutDocument : ISerializable
{
	public static readonly uint64 TypeId = TypeIdOf("Sedulous.GUI.DockLayoutDocument");
	public const uint32 DataVersion = 1;

	public DockLayout Layout = new .() ~ delete _;

	public void Serialize(ISerializer ar)
	{
		BeginVersionedPayload(ar, TypeId, DataVersion);
		let reading = ar.Mode == .Read;
		let l = Layout;
		SerializeValue(ar, "nextNode", ref l.mNextNode);
		SerializeValue(ar, "nextSurface", ref l.mNextSurface);

		var surfaceCount = (uint32)l.mSurfaces.Count;
		ar.Key("surfaces");
		ar.BeginArray(ref surfaceCount);
		if (reading)
			ClearAndDeleteItems!(l.mSurfaces);
		for (uint32 i < surfaceCount)
		{
			let surface = reading ? new DockSurface() : l.mSurfaces[(int)i];
			let kind = scope String((surface.Kind == .Main) ? "main" : "floating");
			ar.BeginObject();
			SerializeValue(ar, "id", ref surface.Id);
			Sedulous.Core.Serialization.Serialize(ar, "kind", kind);
			SerializeValue(ar, "root", ref surface.Root);
			SerializeValue(ar, "x", ref surface.Bounds.X);
			SerializeValue(ar, "y", ref surface.Bounds.Y);
			SerializeValue(ar, "width", ref surface.Bounds.Width);
			SerializeValue(ar, "height", ref surface.Bounds.Height);
			Sedulous.Core.Serialization.Serialize(ar, "screen", surface.Screen);
			SerializeValue(ar, "scale", ref surface.Scale);
			SerializeValue(ar, "maximized", ref surface.Maximized);
			ar.EndObject();
			if (reading)
			{
				surface.Kind = (kind == "main") ? .Main : .Floating;
				l.mSurfaces.Add(surface);
			}
		}
		ar.EndArray();

		var nodeCount = (uint32)l.mNodes.Count;
		ar.Key("nodes");
		ar.BeginArray(ref nodeCount);
		if (reading)
			ClearAndDeleteItems!(l.mNodes);
		for (uint32 i < nodeCount)
		{
			let node = reading ? new DockNode() : l.mNodes[(int)i];
			let kind = scope String(node.IsStack ? "stack" : "split");
			let axis = scope String((node.Axis == .Vertical) ? "vertical" : "horizontal");
			ar.BeginObject();
			SerializeValue(ar, "id", ref node.Id);
			SerializeValue(ar, "parent", ref node.Parent);
			Sedulous.Core.Serialization.Serialize(ar, "kind", kind);
			Sedulous.Core.Serialization.Serialize(ar, "axis", axis);
			ar.Key("children");
			SerializeList(ar, node.Children);
			ar.Key("weights");
			SerializeList(ar, node.Weights);
			ar.Key("panels");
			SerializeList(ar, node.Panels);
			SerializeValue(ar, "active", ref node.Active);
			SerializeValue(ar, "flags", ref node.Flags);
			ar.EndObject();
			if (reading)
			{
				node.Kind = (kind == "split") ? .Split : .Stack;
				node.Axis = (axis == "vertical") ? .Vertical : .Horizontal;
				l.mNodes.Add(node);
			}
		}
		ar.EndArray();

		var hiddenCount = (uint32)l.mHidden.Count;
		ar.Key("hidden");
		ar.BeginArray(ref hiddenCount);
		if (reading)
			ClearAndDeleteItems!(l.mHidden);
		for (uint32 i < hiddenCount)
		{
			let hidden = reading ? new DockHidden() : l.mHidden[(int)i];
			ar.BeginObject();
			Sedulous.Core.Serialization.Serialize(ar, "panel", hidden.Panel);
			SerializeValue(ar, "surface", ref hidden.Last.Surface);
			SerializeValue(ar, "stack", ref hidden.Last.Stack);
			SerializeValue(ar, "index", ref hidden.Last.Index);
			ar.Key("neighbours");
			SerializeList(ar, hidden.Last.Neighbours);
			ar.EndObject();
			if (reading)
				l.mHidden.Add(hidden);
		}
		ar.EndArray();
		EndVersionedPayload(ar);
	}
}
