using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.GUI;

// What a graph view reads: nodes, their pins, links and frames, each by a stable id the source gives,
// so nothing shifts when one goes (foundation.ui's canvas addressed its graph by index, a removal
// shifting the rest). Edits are requests the source applies, as the property and curve sources' are:
// a move is a gesture (begun, previewed, committed once or cancelled); connecting, relinking,
// disconnecting, deleting, creating a node and a frame's edits are one change each; copying writes
// the source's text and pasting reads it back. The undo is the application's.
//
// A link is asked for before it is made (ezEngine): the source says whether it may be and why not,
// and which links it would replace, so a view can light the pins that fit while one is dragged.
// Links join two pins (dataflow) or two nodes (a state machine's transitions).
//
// GraphSet is a source of its own graph in memory: what tests and a page without a graph of its own
// edit, each change told to whoever keeps the undo as the graph before and after.

/// A node's, a pin's, a link's or a frame's id, the source's to give; 0 is none.
typealias GraphId = uint64;

enum GraphPinDirection : uint8
{
	Input,
	Output,
}

/// A pin of a node. A class: it owns its text; Set copies another into it.
class GraphPinInfo
{
	public GraphId Id = 0;
	public String Name = new .() ~ delete _;
	public GraphPinDirection Direction = .Input;
	/// What it carries ("float", "color"); empty: anything.
	public String Type = new .() ~ delete _;
	public Color TypeColor = .(0.7f, 0.7f, 0.75f, 1.0f);
	/// It takes several links (an output, as a rule); else one.
	public bool Many = false;

	public this() { }

	public this(StringView name, GraphPinDirection direction, StringView type = "", bool many = false)
	{
		Name.Set(name);
		Direction = direction;
		Type.Set(type);
		Many = many;
	}

	public void Set(GraphPinInfo other)
	{
		Id = other.Id;
		Name.Set(other.Name);
		Direction = other.Direction;
		Type.Set(other.Type);
		TypeColor = other.TypeColor;
		Many = other.Many;
	}
}

/// A node. A class: it owns its text and its pins; Set copies another into it.
class GraphNodeInfo
{
	public GraphId Id = 0;
	/// The kind of node it is, one of the source's node types.
	public String Type = new .() ~ delete _;
	public String Title = new .() ~ delete _;
	public String Subtitle = new .() ~ delete _;
	/// Its top-left in the graph's space.
	public Float2 Position = .(0.0f, 0.0f);
	public Color HeaderColor = .(0.27f, 0.47f, 0.73f, 1.0f);
	public bool Movable = true;
	public bool Deletable = true;
	/// Inputs and outputs, each in its order.
	public List<GraphPinInfo> Pins = new .() ~ DeleteContainerAndItems!(_);

	/// Adds a pin (a copy of `pin` kept).
	public void AddPin(GraphPinInfo pin)
	{
		let copy = new GraphPinInfo();
		copy.Set(pin);
		Pins.Add(copy);
	}

	public void Set(GraphNodeInfo other)
	{
		if (other === this)
			return;
		Id = other.Id;
		Type.Set(other.Type);
		Title.Set(other.Title);
		Subtitle.Set(other.Subtitle);
		Position = other.Position;
		HeaderColor = other.HeaderColor;
		Movable = other.Movable;
		Deletable = other.Deletable;
		ClearAndDeleteItems!(Pins);
		for (let pin in other.Pins)
			AddPin(pin);
	}
}

enum GraphLinkKind : uint8
{
	/// An output pin to an input pin (dataflow).
	Pins,
	/// A node to a node (a state machine's transition).
	Nodes,
}

struct GraphLinkInfo
{
	public GraphId Id = 0;
	public GraphLinkKind Kind = .Pins;
	public GraphId FromNode = 0;
	/// None for a node link.
	public GraphId FromPin = 0;
	public GraphId ToNode = 0;
	public GraphId ToPin = 0;

	public this() { }
}

/// A titled, coloured rectangle behind nodes (with a body: a comment). A class: it owns its text;
/// Set copies another into it.
class GraphFrameInfo
{
	public GraphId Id = 0;
	public String Title = new .() ~ delete _;
	public String Body = new .() ~ delete _;
	public Float2 Position = .(0.0f, 0.0f);
	public Float2 Size = .(200.0f, 120.0f);
	public Color Tint = .(0.35f, 0.4f, 0.5f, 0.35f);

	public void Set(GraphFrameInfo other)
	{
		if (other === this)
			return;
		Id = other.Id;
		Title.Set(other.Title);
		Body.Set(other.Body);
		Position = other.Position;
		Size = other.Size;
		Tint = other.Tint;
	}
}

/// What a source says of a link asked for.
class GraphLinkCheck
{
	public bool Allowed = false;
	/// Why not, when it is not.
	public String Reason = new .() ~ delete _;
	/// The links it would take the place of.
	public List<GraphId> Replaces = new .() ~ delete _;

	public void Clear()
	{
		Allowed = false;
		Reason.Clear();
		Replaces.Clear();
	}
}

/// A kind of node the source can make, for a view's menu. A class: it owns its text; Set copies
/// another into it.
class GraphNodeType
{
	public String Type = new .() ~ delete _;
	public String Name = new .() ~ delete _;
	public String Category = new .() ~ delete _;

	public this() { }

	public this(StringView type, StringView name, StringView category = "")
	{
		Type.Set(type);
		Name.Set(name);
		Category.Set(category);
	}

	public void Set(GraphNodeType other)
	{
		Type.Set(other.Type);
		Name.Set(other.Name);
		Category.Set(other.Category);
	}
}

interface IGraphSourceClient
{
	/// Nodes, pins, links or frames changed: read them again.
	void OnGraphChanged();
}

abstract class IGraphSource
{
	// Not owned: each view leaves as it goes.
	private List<IGraphSourceClient> mClients = new .() ~ delete _;

	// === What there is ===

	/// Its nodes' ids, into `outNodes` (emptied first).
	public abstract void GetNodes(List<GraphId> outNodes);
	/// The node `node` (the source's own: read it, never change it); null when there is none.
	public abstract GraphNodeInfo GetNode(GraphId node);
	/// Its links, into `outLinks` (emptied first).
	public abstract void GetLinks(List<GraphLinkInfo> outLinks);
	/// Copies of its frames, into `outFrames` (emptied first, its items deleted); the caller deletes
	/// them.
	public abstract void GetFrames(List<GraphFrameInfo> outFrames);

	// === Moving (a gesture) ===

	/// A move begins: where the nodes and frames are now is what a preview moves from.
	public abstract void BeginMove();
	/// `nodes` and `frames` by `delta` from where they were at the beginning, live.
	public abstract void PreviewMove(Span<GraphId> nodes, Span<GraphId> frames, Float2 delta);
	public abstract void CommitMove();
	public abstract void CancelMove();

	// === Links ===

	/// Whether `link` (its id unset) may be made, and what it would replace, into `outCheck`. With no
	/// `To` end (ToNode 0): whether a link may begin at its `From` end, a pin of either direction or,
	/// for a node link, a node (what a view asks before it lets one be dragged from there).
	public abstract void CheckLink(GraphLinkInfo link, GraphLinkCheck outCheck);
	/// Makes `link` as CheckLink said (taking the place of what it replaces), one change; its id, 0
	/// when it may not be.
	public abstract GraphId Connect(GraphLinkInfo link);
	/// Moves link `link`'s ends to `to`'s, one change; false when it may not be.
	public abstract bool Relink(GraphId link, GraphLinkInfo to);
	/// Removes `links`, one change; false when none went.
	public abstract bool Disconnect(Span<GraphId> links);

	// === Nodes ===

	/// Deletes `nodes` (the deletable among them) and their links, one change; false when none went.
	public abstract bool DeleteNodes(Span<GraphId> nodes);
	/// The kinds of node it makes, copies into `outTypes` (emptied first, its items deleted); with
	/// `fittingPin`, a pin, only those with a pin a link from it may reach.
	public abstract void GetNodeTypes(GraphId fittingPin, List<GraphNodeType> outTypes);
	/// Makes a node of `type` at `at`; with `linkFrom`, a pin, links it to the new node's first pin
	/// that fits, in the same change. Its id, 0 when it cannot.
	public abstract GraphId CreateNode(StringView type, Float2 at, GraphId linkFrom);

	// === Frames ===

	/// Makes a frame, one change; its id.
	public abstract GraphId CreateFrame(GraphFrameInfo frame);
	/// Sets a frame's title, body, place, size and tint, one change; false when nothing changed.
	public abstract bool EditFrame(GraphFrameInfo frame);
	public abstract bool DeleteFrames(Span<GraphId> frames);

	// === The clipboard ===

	/// `nodes` and the links among them as the source's text, appended; nothing when it cannot copy.
	public abstract void CopyNodes(Span<GraphId> nodes, String outText);
	/// Reads `text` (CopyNodes') back as new nodes, their top-left at `at`, one change; `made` the new
	/// nodes' ids (emptied first). False when it is not the source's.
	public abstract bool PasteNodes(StringView text, Float2 at, List<GraphId> made);

	public void AddGraphClient(IGraphSourceClient client)
	{
		mClients.Add(client);
	}

	public void RemoveGraphClient(IGraphSourceClient client)
	{
		for (int i = 0; i < mClients.Count; ++i)
		{
			if (mClients[i] === client)
			{
				mClients.RemoveAt(i);
				return;
			}
		}
	}

	protected void NotifyGraphChanged()
	{
		for (int i = 0; i < mClients.Count; ++i)
			mClients[i].OnGraphChanged();
	}
}

/// A graph's whole state: what a GraphSet change holds before and after. A class: it owns its nodes
/// and frames; Set copies another into it.
class GraphState
{
	public List<GraphNodeInfo> Nodes = new .() ~ DeleteContainerAndItems!(_);
	public List<GraphLinkInfo> Links = new .() ~ delete _;
	public List<GraphFrameInfo> Frames = new .() ~ DeleteContainerAndItems!(_);
	public GraphId NextId = 1;

	public void Set(GraphState other)
	{
		if (other === this)
			return;
		ClearAndDeleteItems!(Nodes);
		for (let node in other.Nodes)
		{
			let copy = new GraphNodeInfo();
			copy.Set(node);
			Nodes.Add(copy);
		}
		Links.Clear();
		Links.AddRange(other.Links);
		ClearAndDeleteItems!(Frames);
		for (let frame in other.Frames)
		{
			let copy = new GraphFrameInfo();
			copy.Set(frame);
			Frames.Add(copy);
		}
		NextId = other.NextId;
	}
}

/// One change: what (in words), and the graph before and after it.
class GraphChange
{
	public String Words = new .() ~ delete _;
	public GraphState Before = new .() ~ delete _;
	public GraphState After = new .() ~ delete _;

	public void Set(GraphChange other)
	{
		Words.Set(other.Words);
		Before.Set(other.Before);
		After.Set(other.After);
	}
}

/// A graph of its own, in memory. Its node types are templates the page adds; a pin's type decides
/// what links to it (the same type, or either empty); an input takes one link unless it says many, a
/// new one replacing the old. Its nodes link to each other only where the page says.
class GraphSet : IGraphSource
{
	private class Template
	{
		public GraphNodeType Type = new .() ~ delete _;
		public GraphNodeInfo Node = new .() ~ delete _;
	}

	private class ReadNode
	{
		public String Type = new .() ~ delete _;
		public String Title = new .() ~ delete _;
		public Float2 At = .(0.0f, 0.0f);
	}

	private GraphState mState = new .() ~ delete _;
	// The graph when a move began.
	private GraphState mBefore = new .() ~ delete _;
	private bool mMoving = false;
	private bool mNodeLinks = false;
	private List<Template> mTypes = new .() ~ DeleteContainerAndItems!(_);
	// Not owned.
	private IPropertyTextFormat mFormat = null;
	private delegate void(GraphChange change) mOnChange ~ delete _;

	/// A kind of node it makes: a template whose pins (ids unset) each new node copies (copies of
	/// both kept).
	public void AddNodeType(GraphNodeType type, GraphNodeInfo node)
	{
		let made = new Template();
		made.Type.Set(type);
		made.Node.Set(node);
		mTypes.Add(made);
	}

	/// Adds a node from code (a copy, its pins given ids here), no change told; its id.
	public GraphId AddNode(GraphNodeInfo node)
	{
		let copy = new GraphNodeInfo();
		copy.Set(node);
		copy.Id = Next();
		for (let pin in copy.Pins)
			pin.Id = Next();
		mState.Nodes.Add(copy);
		NotifyGraphChanged();
		return copy.Id;
	}

	/// Adds a link from code, unchecked, no change told; its id.
	public GraphId AddLink(GraphLinkInfo link)
	{
		var made = link;
		made.Id = Next();
		mState.Links.Add(made);
		NotifyGraphChanged();
		return made.Id;
	}

	/// A pin of a node by its name; 0 when none.
	public GraphId FindPin(GraphId node, StringView name, GraphPinDirection direction)
	{
		if (let found = GetNode(node))
		{
			for (let pin in found.Pins)
			{
				if ((pin.Name == name) && (pin.Direction == direction))
					return pin.Id;
			}
		}
		return 0;
	}

	/// Its graph (its own: read it, never change it).
	public GraphState State => mState;

	/// Whether its nodes link to each other (a state machine's transitions), not only its pins.
	public bool NodeLinks
	{
		get => mNodeLinks;
		set => mNodeLinks = value;
	}

	/// The application's serializer for copies (not owned; null: no copying).
	public IPropertyTextFormat TextFormat
	{
		get => mFormat;
		set => mFormat = value;
	}

	/// Each change, for whoever keeps the undo. OWNERSHIP of `callback` transfers.
	public void SetOnChange(delegate void(GraphChange change) callback)
	{
		delete mOnChange;
		mOnChange = callback;
	}

	/// Puts a change's graph back (`undo`: before it; else after), no change told.
	public void Apply(GraphChange change, bool undo)
	{
		mState.Set(undo ? change.Before : change.After);
		NotifyGraphChanged();
	}

	// === IGraphSource ===

	public override void GetNodes(List<GraphId> outNodes)
	{
		outNodes.Clear();
		for (let node in mState.Nodes)
			outNodes.Add(node.Id);
	}

	public override GraphNodeInfo GetNode(GraphId node)
	{
		for (let at in mState.Nodes)
		{
			if (at.Id == node)
				return at;
		}
		return null;
	}

	public override void GetLinks(List<GraphLinkInfo> outLinks)
	{
		outLinks.Clear();
		outLinks.AddRange(mState.Links);
	}

	public override void GetFrames(List<GraphFrameInfo> outFrames)
	{
		ClearAndDeleteItems!(outFrames);
		for (let frame in mState.Frames)
		{
			let copy = new GraphFrameInfo();
			copy.Set(frame);
			outFrames.Add(copy);
		}
	}

	public override void BeginMove()
	{
		mMoving = true;
		mBefore.Set(mState);
	}

	public override void PreviewMove(Span<GraphId> nodes, Span<GraphId> frames, Float2 delta)
	{
		if (!mMoving)
			return;
		for (int i = 0; (i < mState.Nodes.Count) && (i < mBefore.Nodes.Count); ++i)
		{
			if (Holds(nodes, mState.Nodes[i].Id) && mState.Nodes[i].Movable)
				mState.Nodes[i].Position = .(mBefore.Nodes[i].Position.X + delta.X, mBefore.Nodes[i].Position.Y + delta.Y);
		}
		for (int i = 0; (i < mState.Frames.Count) && (i < mBefore.Frames.Count); ++i)
		{
			if (Holds(frames, mState.Frames[i].Id))
				mState.Frames[i].Position = .(mBefore.Frames[i].Position.X + delta.X, mBefore.Frames[i].Position.Y + delta.Y);
		}
		NotifyGraphChanged();
	}

	public override void CommitMove()
	{
		if (!mMoving)
			return;
		mMoving = false;
		Told("Moved", mBefore);
	}

	public override void CancelMove()
	{
		if (!mMoving)
			return;
		mMoving = false;
		mState.Set(mBefore);
		NotifyGraphChanged();
	}

	public override void CheckLink(GraphLinkInfo link, GraphLinkCheck check)
	{
		check.Clear();
		let from = GetNode(link.FromNode);
		let to = GetNode(link.ToNode);
		if ((from == null) || ((to == null) && (link.ToNode != 0)))
		{
			check.Reason.Set("No such node");
			return;
		}
		if (link.Kind == .Nodes)
		{
			// A state machine's transitions: any two nodes, a node to itself, several.
			check.Allowed = mNodeLinks;
			if (!mNodeLinks)
				check.Reason.Set("This graph links pins, not nodes");
			return;
		}
		if (to == null) // where a link begins: any pin
		{
			check.Allowed = PinOf(from, link.FromPin) != null;
			if (!check.Allowed)
				check.Reason.Set("No such pin");
			return;
		}
		let @out = PinOf(from, link.FromPin);
		let @in = PinOf(to, link.ToPin);
		if ((@out == null) || (@in == null))
		{
			check.Reason.Set("No such pin");
			return;
		}
		if ((@out.Direction != .Output) || (@in.Direction != .Input))
		{
			check.Reason.Set("A link goes from an output to an input");
			return;
		}
		if (from.Id == to.Id)
		{
			check.Reason.Set("A node does not feed itself");
			return;
		}
		if ((@out.Type.Length != 0) && (@in.Type.Length != 0) && (@out.Type != @in.Type))
		{
			check.Reason.AppendF("A {} does not go into a {}", @out.Type, @in.Type);
			return;
		}
		for (let at in mState.Links)
		{
			if (at.Kind != .Pins)
				continue;
			if ((at.FromPin == link.FromPin) && (at.ToPin == link.ToPin))
			{
				check.Reason.Set("They are linked already");
				return;
			}
			if ((at.ToPin == link.ToPin) && !@in.Many)
				check.Replaces.Add(at.Id);
			if ((at.FromPin == link.FromPin) && !@out.Many)
				check.Replaces.Add(at.Id);
		}
		check.Allowed = true;
	}

	public override GraphId Connect(GraphLinkInfo link)
	{
		let check = scope GraphLinkCheck();
		CheckLink(link, check);
		if (!check.Allowed)
			return 0;
		let before = scope GraphState();
		before.Set(mState);
		for (let gone in check.Replaces)
			RemoveLink(gone);
		var made = link;
		made.Id = Next();
		mState.Links.Add(made);
		Told("Linked", before);
		return made.Id;
	}

	public override bool Relink(GraphId link, GraphLinkInfo to)
	{
		let found = FindLink(link);
		if (found < 0)
			return false;
		let before = scope GraphState();
		before.Set(mState);
		let old = mState.Links[found];
		RemoveLink(link); // asked without it, so it does not refuse or replace itself
		let check = scope GraphLinkCheck();
		CheckLink(to, check);
		if (!check.Allowed)
		{
			mState.Set(before);
			return false;
		}
		for (let gone in check.Replaces)
			RemoveLink(gone);
		var moved = to;
		moved.Id = old.Id;
		moved.Kind = old.Kind;
		mState.Links.Add(moved);
		Told("Relinked", before);
		return true;
	}

	public override bool Disconnect(Span<GraphId> links)
	{
		let before = scope GraphState();
		before.Set(mState);
		bool any = false;
		for (let link in links)
			any = RemoveLink(link) || any;
		if (any)
			Told("Unlinked", before);
		return any;
	}

	public override bool DeleteNodes(Span<GraphId> nodes)
	{
		let before = scope GraphState();
		before.Set(mState);
		bool any = false;
		for (int i = mState.Nodes.Count - 1; i >= 0; i--)
		{
			let node = mState.Nodes[i];
			if (!Holds(nodes, node.Id) || !node.Deletable)
				continue;
			let id = node.Id;
			for (int l = mState.Links.Count - 1; l >= 0; l--)
			{
				if ((mState.Links[l].FromNode == id) || (mState.Links[l].ToNode == id))
					mState.Links.RemoveAt(l);
			}
			delete node;
			mState.Nodes.RemoveAt(i);
			any = true;
		}
		if (any)
			Told("Deleted", before);
		return any;
	}

	public override void GetNodeTypes(GraphId fittingPin, List<GraphNodeType> outTypes)
	{
		ClearAndDeleteItems!(outTypes);
		let from = (fittingPin != 0) ? FindPinAnywhere(fittingPin) : null;
		for (let type in mTypes)
		{
			if ((fittingPin == 0) || ((from != null) && (FirstFitting(type.Node, from) >= 0)))
			{
				let copy = new GraphNodeType();
				copy.Set(type.Type);
				outTypes.Add(copy);
			}
		}
	}

	public override GraphId CreateNode(StringView type, Float2 at, GraphId linkFrom)
	{
		Template chosen = null;
		for (let t in mTypes)
		{
			if (t.Type.Type == type)
				chosen = t;
		}
		if (chosen == null)
			return 0;
		let before = scope GraphState();
		before.Set(mState);
		let node = new GraphNodeInfo();
		node.Set(chosen.Node);
		node.Type.Set(type);
		node.Position = at;
		node.Id = Next();
		for (let pin in node.Pins)
			pin.Id = Next();
		mState.Nodes.Add(node);
		if (linkFrom != 0)
		{
			if (let from = FindPinAnywhere(linkFrom))
			{
				let fit = FirstFitting(node, from);
				if (fit >= 0)
				{
					var link = GraphLinkInfo();
					link.Kind = .Pins;
					let fromOut = from.Direction == .Output;
					let fromNode = NodeOfPin(linkFrom);
					link.FromNode = fromOut ? fromNode : node.Id;
					link.FromPin = fromOut ? linkFrom : node.Pins[fit].Id;
					link.ToNode = fromOut ? node.Id : fromNode;
					link.ToPin = fromOut ? node.Pins[fit].Id : linkFrom;
					let check = scope GraphLinkCheck();
					CheckLink(link, check);
					if (check.Allowed)
					{
						for (let gone in check.Replaces)
							RemoveLink(gone);
						link.Id = Next();
						mState.Links.Add(link);
					}
				}
			}
		}
		Told(scope String()..AppendF("Added {}", chosen.Type.Name), before);
		return node.Id;
	}

	public override GraphId CreateFrame(GraphFrameInfo frame)
	{
		let before = scope GraphState();
		before.Set(mState);
		let made = new GraphFrameInfo();
		made.Set(frame);
		made.Id = Next();
		mState.Frames.Add(made);
		Told("Framed", before);
		return made.Id;
	}

	public override bool EditFrame(GraphFrameInfo frame)
	{
		for (let at in mState.Frames)
		{
			if (at.Id == frame.Id)
			{
				if ((at.Title == frame.Title) && (at.Body == frame.Body) && (at.Position.X == frame.Position.X) && (at.Position.Y == frame.Position.Y) &&
					(at.Size.X == frame.Size.X) && (at.Size.Y == frame.Size.Y) && (at.Tint == frame.Tint))
					return false;
				let before = scope GraphState();
				before.Set(mState);
				at.Set(frame);
				Told("Edited a frame", before);
				return true;
			}
		}
		return false;
	}

	public override bool DeleteFrames(Span<GraphId> frames)
	{
		let before = scope GraphState();
		before.Set(mState);
		bool any = false;
		for (int i = mState.Frames.Count - 1; i >= 0; i--)
		{
			if (Holds(frames, mState.Frames[i].Id))
			{
				delete mState.Frames[i];
				mState.Frames.RemoveAt(i);
				any = true;
			}
		}
		if (any)
			Told("Deleted a frame", before);
		return any;
	}

	// The nodes (type, title, place from their top-left) and the links among them, by their places
	// in the copy, written with the application's serializer.
	public override void CopyNodes(Span<GraphId> nodes, String outText)
	{
		if ((mFormat == null) || nodes.IsEmpty)
			return;
		let chosen = scope List<GraphNodeInfo>();
		for (let node in mState.Nodes)
		{
			if (Holds(nodes, node.Id))
				chosen.Add(node);
		}
		if (chosen.IsEmpty)
			return;
		var origin = chosen[0].Position;
		for (let node in chosen)
			origin = .(Min(origin.X, node.Position.X), Min(origin.Y, node.Position.Y));
		mFormat.Write(scope (ar) =>
			{
				let shape = scope String("graph nodes");
				Serialize(ar, "shape", shape);
				var count = (int64)chosen.Count;
				SerializeValue(ar, "count", ref count);
				let key = scope String();
				for (int i = 0; i < chosen.Count; ++i)
				{
					ar.Key(Key('n', i, key));
					ar.BeginObject();
					let type = scope String(chosen[i].Type);
					Serialize(ar, "type", type);
					let title = scope String(chosen[i].Title);
					Serialize(ar, "title", title);
					var at = Float2(chosen[i].Position.X - origin.X, chosen[i].Position.Y - origin.Y);
					ar.Key("at");
					Serialize(ar, ref at);
					ar.EndObject();
				}
				// Links among them: by node place and pin place, so the copies link alike.
				int64 links = 0;
				let rows = scope List<int64>();
				for (let link in mState.Links)
				{
					let from = Place(chosen, link.FromNode);
					let to = Place(chosen, link.ToNode);
					if ((from < 0) || (to < 0))
						continue;
					rows.Add((int64)link.Kind);
					rows.Add(from);
					rows.Add(PinPlace(chosen[(int)from], link.FromPin));
					rows.Add(to);
					rows.Add(PinPlace(chosen[(int)to], link.ToPin));
					++links;
				}
				SerializeValue(ar, "links", ref links);
				for (int i = 0; i < rows.Count; ++i)
					SerializeValue(ar, Key('l', i, key), ref rows[i]);
			}, outText);
	}

	public override bool PasteNodes(StringView text, Float2 at, List<GraphId> made)
	{
		made.Clear();
		if (mFormat == null)
			return false;
		let nodes = scope List<ReadNode>();
		defer { ClearAndDeleteItems!(nodes); }
		let rows = scope List<int64>();
		bool ours = false;
		let read = mFormat.Read(text, scope [&] (ar) =>
			{
				let shape = scope String();
				Serialize(ar, "shape", shape);
				ours = shape == "graph nodes";
				if (!ours)
					return;
				int64 count = 0;
				SerializeValue(ar, "count", ref count);
				let key = scope String();
				for (int64 i = 0; i < Math.Clamp(count, (int64)0, (int64)4096); ++i)
				{
					let node = new ReadNode();
					ar.Key(Key('n', (int)i, key));
					ar.BeginObject();
					Serialize(ar, "type", node.Type);
					Serialize(ar, "title", node.Title);
					ar.Key("at");
					Serialize(ar, ref node.At);
					ar.EndObject();
					nodes.Add(node);
				}
				int64 links = 0;
				SerializeValue(ar, "links", ref links);
				for (int64 i = 0; i < Math.Clamp(links, (int64)0, (int64)4096) * 5; ++i)
				{
					int64 value = 0;
					SerializeValue(ar, Key('l', (int)i, key), ref value);
					rows.Add(value);
				}
			});
		if (!read || !ours || nodes.IsEmpty)
			return false;
		let before = scope GraphState();
		before.Set(mState);
		for (let node in nodes)
		{
			Template chosen = null;
			for (let t in mTypes)
			{
				if (t.Type.Type == node.Type)
					chosen = t;
			}
			if (chosen == null)
			{
				made.Add(0);
				continue;
			}
			let copy = new GraphNodeInfo();
			copy.Set(chosen.Node);
			copy.Type.Set(node.Type);
			copy.Title.Set(node.Title);
			copy.Position = .(at.X + node.At.X, at.Y + node.At.Y);
			copy.Id = Next();
			for (let pin in copy.Pins)
				pin.Id = Next();
			mState.Nodes.Add(copy);
			made.Add(copy.Id);
		}
		let check = scope GraphLinkCheck();
		for (int r = 0; r + 4 < rows.Count; r += 5)
		{
			let from = (int)rows[r + 1];
			let to = (int)rows[r + 3];
			if ((from < 0) || (to < 0) || (from >= made.Count) || (to >= made.Count) || (made[from] == 0) || (made[to] == 0))
				continue;
			var link = GraphLinkInfo();
			link.Kind = (GraphLinkKind)rows[r];
			link.FromNode = made[from];
			link.ToNode = made[to];
			link.FromPin = PinAt(GetNode(made[from]), rows[r + 2]);
			link.ToPin = PinAt(GetNode(made[to]), rows[r + 4]);
			CheckLink(link, check);
			if (check.Allowed)
			{
				link.Id = Next();
				mState.Links.Add(link);
			}
		}
		for (int i = made.Count - 1; i >= 0; i--)
		{
			if (made[i] == 0)
				made.RemoveAt(i);
		}
		if (made.IsEmpty) // none of a kind it makes: no change
		{
			mState.Set(before);
			return false;
		}
		Told("Pasted", before);
		return true;
	}

	private GraphId Next() => mState.NextId++;

	private void Told(StringView words, GraphState before)
	{
		NotifyGraphChanged();
		if (mOnChange != null)
		{
			let change = scope GraphChange();
			change.Words.Set(words);
			change.Before.Set(before);
			change.After.Set(mState);
			mOnChange(change);
		}
	}

	private static bool Holds(Span<GraphId> ids, GraphId id)
	{
		for (let at in ids)
		{
			if (at == id)
				return true;
		}
		return false;
	}

	private static GraphPinInfo PinOf(GraphNodeInfo node, GraphId pin)
	{
		for (let at in node.Pins)
		{
			if (at.Id == pin)
				return at;
		}
		return null;
	}

	private GraphPinInfo FindPinAnywhere(GraphId pin)
	{
		for (let node in mState.Nodes)
		{
			if (let found = PinOf(node, pin))
				return found;
		}
		return null;
	}

	private GraphId NodeOfPin(GraphId pin)
	{
		for (let node in mState.Nodes)
		{
			if (PinOf(node, pin) != null)
				return node.Id;
		}
		return 0;
	}

	// The link's place among the links; -1: none.
	private int FindLink(GraphId link)
	{
		for (int i = 0; i < mState.Links.Count; ++i)
		{
			if (mState.Links[i].Id == link)
				return i;
		}
		return -1;
	}

	private bool RemoveLink(GraphId link)
	{
		for (int i = 0; i < mState.Links.Count; ++i)
		{
			if (mState.Links[i].Id == link)
			{
				mState.Links.RemoveAt(i);
				return true;
			}
		}
		return false;
	}

	// The first pin of `node` a link from `from` may reach (the other direction, a type that fits);
	// -1: none.
	private static int32 FirstFitting(GraphNodeInfo node, GraphPinInfo from)
	{
		for (int i = 0; i < node.Pins.Count; ++i)
		{
			let pin = node.Pins[i];
			if (pin.Direction == from.Direction)
				continue;
			if ((pin.Type.Length == 0) || (from.Type.Length == 0) || (pin.Type == from.Type))
				return (int32)i;
		}
		return -1;
	}

	private static int64 Place(List<GraphNodeInfo> nodes, GraphId id)
	{
		for (int i = 0; i < nodes.Count; ++i)
		{
			if (nodes[i].Id == id)
				return (int64)i;
		}
		return -1;
	}

	private static int64 PinPlace(GraphNodeInfo node, GraphId pin)
	{
		for (int i = 0; i < node.Pins.Count; ++i)
		{
			if (node.Pins[i].Id == pin)
				return (int64)i;
		}
		return -1;
	}

	private static GraphId PinAt(GraphNodeInfo node, int64 place) => ((place >= 0) && (place < (int64)node.Pins.Count)) ? node.Pins[(int)place].Id : 0;

	// "n3", "l12": `prefix` and the index, into `key` (emptied first).
	private static StringView Key(char8 prefix, int index, String key)
	{
		key.Clear();
		key.Append(prefix);
		index.ToString(key);
		return key;
	}
}
