using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A widget that records that it drew, by its name, in SceneFixtures.DrawLog.
class Probe : UIWidget
{
	private String mName = new .() ~ delete _;

	public this(StringView name)
	{
		mName.Set(name);
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		SceneFixtures.DrawLog.Add(new String(mName));
	}
}

/// What the scene, dispatcher and popup tests share.
static class SceneFixtures
{
	/// What the probes drew, in order (DrawRoot clears it).
	public static List<String> DrawLog = new .() ~ DeleteContainerAndItems!(_);

	/// A root of a GUI of its own, `width` by `height` (unsized for 0 by 0), held by the caller:
	/// it releases it, and the GUI goes with it.
	public static SceneRoot NewScene(float width = 0.0f, float height = 0.0f)
	{
		let context = new GUIContext();
		let root = new SceneRoot(context);
		context.ReleaseRef(); // the root's keeps it
		if ((width > 0.0f) || (height > 0.0f))
			root.Size = .(width, height);
		return root;
	}

	/// A new node at `x`, `y`, `w` by `h`, held by the caller (it releases it); the last child of
	/// `parent` when one is given.
	public static Node NewNode(float x, float y, float w, float h, Node parent = null)
	{
		let node = new Node();
		node.Size = .(w, h);
		node.Position = .(x, y);
		if (parent != null)
			parent.AddChild(node);
		return node;
	}

	/// A new widget at `x`, `y`, `w` by `h` with the id `id`, the last child of `parent`, held by
	/// the caller (it releases it).
	public static UIWidget NewWidget(Node parent, float x, float y, float w, float h, StringView id = default)
	{
		let widget = new UIWidget();
		widget.Position = .(x, y);
		widget.Size = .(w, h);
		if (id.Length != 0)
			widget.Id = id;
		if (parent != null)
			parent.AddChild(widget);
		return widget;
	}

	/// A new probe `name` at `at`, `size`, the last child of `parent` (when given), held by the
	/// caller.
	public static Probe NewProbe(Node parent, StringView name, Float2 at, Float2 size)
	{
		let probe = new Probe(name);
		probe.Position = at;
		probe.Size = size;
		if (parent != null)
			parent.AddChild(probe);
		return probe;
	}

	/// Options for a popup placed against the point `point`, of `kind`; the caller hands them on.
	public static PopupOptions At(Float2 point, PopupKind kind = .Auto)
	{
		let o = new PopupOptions();
		o.Kind = kind;
		o.AnchorRect = .(point.X, point.Y, 0.0f, 0.0f);
		o.HasAnchorRect = true;
		return o;
	}

	/// A press and its release at `at`.
	public static void Click(EventDispatcher d, Float2 at)
	{
		d.InjectMouseDown(at, .Left);
		d.InjectMouseUp(at, .Left);
	}

	/// Draws `root` as Draw does (no frame counted), the draw log cleared first.
	public static void DrawRoot(SceneRoot root)
	{
		ClearAndDeleteItems!(DrawLog);
		let canvas = scope VGContext();
		let ctx = scope DrawContext(canvas);
		root.Draw(ctx);
	}

	/// One frame of the GUI's clock (16 ms, by ticks).
	public static TimeSpan Frame => TimeSpan((int64)(0.016 * (double)TimeSpan.TicksPerSecond));

	public static TimeSpan Seconds(double s) => TimeSpan((int64)(s * (double)TimeSpan.TicksPerSecond));
}
