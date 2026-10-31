using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI.Toolkit;

/// One node: a lightweight data object the canvas draws, not a view.
///
/// Nodes are DATA rather than views because a graph may hold hundreds and none of them needs
/// layout, styling or hit testing of its own. The canvas draws them all directly.
class NodeGraphNode
{
	/// The caller's own identifier. The canvas never interprets it and only hands it back, so a
	/// consumer can map a node to whatever it actually represents.
	public int64 UserHandle = 0;

	public String Title = new .() ~ delete _;
	/// Smaller text under the title. Empty for none.
	public String Subtitle = new .() ~ delete _;

	/// In CANVAS space, before the pan and zoom are applied.
	public Float2 Position = .Zero;
	public Float2 Size = .(160.0f, 80.0f);

	public Color HeaderColor = Color.Rgb(70, 130, 200);

	public bool IsSelected = false;

	/// An extra ring OUTSIDE the selection outline: the live state while a graph is running,
	/// say. Driven entirely by the caller; the canvas never sets it.
	public bool IsHighlighted = false;
	public Color HighlightColor = .(1.0f, 170 / 255.0f, 60 / 255.0f, 220 / 255.0f);

	/// OWNED. Ordered top to bottom down the left side.
	public List<NodeGraphPort> InputPorts = new .() ~ DeleteContainerAndItems!(_);
	/// OWNED. Ordered top to bottom down the right side.
	public List<NodeGraphPort> OutputPorts = new .() ~ DeleteContainerAndItems!(_);

	public bool IsMovable = true;
	public bool IsDeletable = true;

	public this() {}

	public this(StringView title, Float2 position)
	{
		Title.Set(title);
		Position = position;
	}
}
