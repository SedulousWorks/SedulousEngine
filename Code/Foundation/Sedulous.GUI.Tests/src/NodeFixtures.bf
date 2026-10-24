using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// The top of a tree laid out in no GUI, as a SceneRoot is in one: a fixed size (its code's
/// width and height), and the display scale its edges round to.
class ScaledRoot : Node
{
	private float mDisplayScale = 1.0f;

	/// Device pixels per logical unit: every edge of the tree rounds to that grid.
	public void SetDisplayScale(float scale)
	{
		let was = mDisplayScale;
		mDisplayScale = Math.Max(scale, 0.01f);
		Scale = .(mDisplayScale, mDisplayScale);
		if (mDisplayScale != was)
		{
			RequestLayoutTree(); // every edge rounds to the new grid
			Invalidate();
		}
	}

	protected override float TopPixelScale => mDisplayScale;
}

/// A root that holds what a GUI's root holds for its tree: an element table, an action manager
/// and a mutation queue; and the host's last drawn frame, as a test sets it.
class GuiRoot : Node
{
	public Sedulous.GUI.ElementTable Table = new .() ~ _.ReleaseRef();
	public Sedulous.GUI.ActionManager Actions = new .() ~ delete _;
	public Sedulous.GUI.MutationQueue Queue = new .() ~ delete _;
	public uint32 LastFrame = 0;

	public override Sedulous.GUI.ElementTable ElementTable => Table;
	public override Sedulous.GUI.ActionManager ActionManager => Actions;
	public override Sedulous.GUI.MutationQueue MutationQueue => Queue;
	public override uint32 LastDrawnFrame => LastFrame;
}

/// A layout bed: a root of a given size (400 x 300 unless told), which the tree under it hangs
/// from. The root (and with it the tree) goes with the bed.
class Bed
{
	public ScaledRoot Root = new .() ~ _.ReleaseRef();

	public this(float width = 400.0f, float height = 300.0f)
	{
		Root.Size = .(width, height);
	}

	/// The layout pass; how many containers laid out.
	public uint32 Layout() => Root.UpdateLayout();
}

/// What the node and layout tests share.
static class NodeFixtures
{
	/// doctest's Approx: within a relative epsilon (scaled by 1 plus the larger magnitude).
	public static bool Near(float a, float b, float epsilon = 1.2e-5f) =>
		Math.Abs(a - b) < epsilon * (1.0f + Math.Max(Math.Abs(a), Math.Abs(b)));

	/// A new node styled by `style`, the last child of `parent`, which holds it: the node comes
	/// back borrowed.
	public static Node Box(Node parent, delegate void(LayoutStyle style) style)
	{
		let node = new Node();
		node.EditLayoutStyle(style);
		parent.AddChild(node);
		node.ReleaseRef(); // the tree's reference keeps it
		return node;
	}

	/// A new unstyled node, the last child of `parent` (borrowed).
	public static Node Box(Node parent)
	{
		let node = new Node();
		parent.AddChild(node);
		node.ReleaseRef();
		return node;
	}

	/// A new node `w` by `h` pixels, the last child of `parent` (borrowed).
	public static Node Fixed(Node parent, float w, float h) => Box(parent, scope (s) =>
		{
			s.Width = LayoutLength.Px(w);
			s.Height = LayoutLength.Px(h);
		});

	public static void CheckRect(Node node, float x, float y, float w, float h)
	{
		Test.Assert(Near(node.Position.X, x), scope $"x {node.Position.X}, expected {x}");
		Test.Assert(Near(node.Position.Y, y), scope $"y {node.Position.Y}, expected {y}");
		Test.Assert(Near(node.Size.X, w), scope $"width {node.Size.X}, expected {w}");
		Test.Assert(Near(node.Size.Y, h), scope $"height {node.Size.Y}, expected {h}");
	}
}
