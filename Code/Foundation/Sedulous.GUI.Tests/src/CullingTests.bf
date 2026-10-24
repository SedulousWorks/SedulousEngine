using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

// Culling: a node whose subtree's ink misses the clip is not drawn, and culling never changes what
// shows. The differential test draws the same tree with culling off and on and requires the same
// geometry where it can show: every triangle that lands inside its command's scissor (in a layer
// that itself shows), the same in both.

/// A long scrolled page of what reaches past its box: outer shadows, rounded clips holding more
/// than they show, rotated boxes, blurred groups, and a box half off the window. The root (and
/// with it the page) and the styles go with it.
class CullPage
{
	public SceneRoot Root ~ _.ReleaseRef();
	/// Borrowed: the tree holds it.
	public UIWidget Scroller;
	public StyleManager Styles = new .() ~ delete _;

	public this()
	{
		CullingTests.UseSheet(Styles,
			"page { width: 400px; height: 300px; overflow: auto; flex-direction: column; gap: 6px; }" +
			"row { height: 30px; flex-direction: row; gap: 8px; }" +
			"card { width: 60px; height: 24px; background-color: #336699; border-radius: 8px;" +
			"       box-shadow: 0 6px 18px rgba(0, 0, 0, 0.5); }" +
			"clip { width: 50px; height: 24px; overflow: hidden; border-radius: 10px; background-color: #444444; }" +
			"clip > inner { width: 120px; height: 60px; background-color: #aa3344; }" +
			"spin { width: 30px; height: 10px; background-color: #66aa33; transform: rotate(60deg); }" +
			"fx { width: 40px; height: 20px; filter: blur(3px); }" +
			"fx > dot { width: 20px; height: 20px; background-color: #ffffff; }" +
			"edge { position: absolute; left: 380px; top: 40px; width: 60px; height: 30px; background-color: #cc9900;" +
			"       box-shadow: 0 0 12px 4px #000000; }");
		Root = SceneFixtures.NewScene(400.0f, 300.0f);
		Scroller = CullingTests.Add(Root, "page");
		for (int i = 0; i < 80; i++)
		{
			let row = CullingTests.Add(Scroller, "row");
			CullingTests.Add(row, "card");
			let clip = CullingTests.Add(row, "clip");
			CullingTests.Add(clip, "inner");
			CullingTests.Add(row, "spin");
			let fx = CullingTests.Add(row, "fx");
			CullingTests.Add(fx, "dot");
		}
		CullingTests.Add(Root, "edge");
	}

	/// Styles, lays out and draws the page, culling or not, into `outGeometry`; how many nodes the
	/// frame culled.
	public uint32 Draw(bool culling, List<uint64> outGeometry)
	{
		Styles.ApplyTree(Root);
		Root.UpdateLayout();
		let canvas = scope VGContext();
		let dc = scope DrawContext(canvas);
		dc.Culling = culling;
		Root.DrawFrame(dc);
		CullingTests.VisibleGeometry(canvas.GetBatch(), outGeometry);
		return Root.LastFrameStats.NodesCulled;
	}
}

/// Culling: what is out of view is not drawn, and what shows is the same either way.
class CullingTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	/// A new widget tagged `tag`, the last child of `parent` (borrowed: the tree holds it).
	public static UIWidget Add(Node parent, StringView tag)
	{
		let w = new UIWidget();
		w.Tag = tag;
		parent.AddChild(w);
		w.ReleaseRef();
		return w;
	}

	/// `styles` styling by `css`.
	public static void UseSheet(StyleManager styles, StringView css)
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse(css, sheet);
		styles.StyleSheet = sheet;
	}

	/// What can show of a batch, into `outHashes`: a hash per triangle that lands inside its
	/// command's scissor (or in an unscissored command), in order, with what it is drawn with. A
	/// layer's commands show only when its composite does; layers count by their order among those
	/// that show (a culled node's layer shifts the others' indices), and textures by their first
	/// use among what shows (each draw has a canvas of its own, so a texture's address is no
	/// identity across draws).
	public static void VisibleGeometry(VGBatch batch, List<uint64> outHashes)
	{
		bool TriangleShows(VGCommand cmd, int first)
		{
			if (!cmd.Scissored && (cmd.ClipMode != .Scissor))
				return true;
			var mn = Float2(1e30f, 1e30f);
			var mx = Float2(-1e30f, -1e30f);
			for (int k = 0; k < 3; k++)
			{
				let at = first + k;
				let p = (cmd.DrawMode == .Box) ? batch.BoxVertices[at].Position : batch.Vertices[(int)batch.Indices[at]].Position;
				mn = .(Math.Min(mn.X, p.X), Math.Min(mn.Y, p.Y));
				mx = .(Math.Max(mx.X, p.X), Math.Max(mx.Y, p.Y));
			}
			let c = cmd.ClipRect;
			return (mx.X > c.X) && (mn.X < c.X + c.Width) && (mx.Y > c.Y) && (mn.Y < c.Y + c.Height);
		}
		bool Colours(VGCommand cmd) =>
			(cmd.FillPhase != .StencilWrite) && (cmd.FillPhase != .ClipApply) && (cmd.FillPhase != .ClipClear);
		// Which layers show: one whose composite has a triangle that shows, inside a layer that shows.
		let layerShows = scope List<bool>();
		for (int l = 0; l < batch.Layers.Count; l++)
			layerShows.Add(false);
		for (int c = batch.Commands.Count - 1; c >= 0; c--) // a child layer composites after its own commands
		{
			let cmd = batch.Commands[c];
			if (cmd.CompositeLayer < 0)
				continue;
			let parentShows = (cmd.Layer < 0) || layerShows[cmd.Layer];
			for (int i = 0; parentShows && (i + 3 <= cmd.IndexCount); i += 3)
			{
				if (TriangleShows(cmd, cmd.StartIndex + i))
					layerShows[cmd.CompositeLayer] = true;
			}
		}
		let ordinal = scope List<int32>();
		int32 next = 0;
		for (int l = 0; l < batch.Layers.Count; l++)
			ordinal.Add(layerShows[l] ? next++ : -1);

		let textures = scope List<void*>(); // by first use
		for (let cmd in batch.Commands)
		{
			if (!Colours(cmd) || ((cmd.Layer >= 0) && !layerShows[cmd.Layer]))
				continue;
			void* address = (cmd.TextureIndex >= 0) ? Internal.UnsafeCastToPtr(batch.Textures[cmd.TextureIndex]) : null;
			int32 texture = -1;
			for (int t = 0; (t < textures.Count) && (address != null); t++)
			{
				if (textures[t] == address)
					texture = (int32)t;
			}
			if ((texture < 0) && (address != null))
			{
				texture = (int32)textures.Count;
				textures.Add(address);
			}
			int32[6] state = .((int32)cmd.DrawMode, (int32)cmd.BlendMode, (int32)cmd.FillPhase,
				(cmd.Layer >= 0) ? ordinal[cmd.Layer] : -1, (cmd.CompositeLayer >= 0) ? ordinal[cmd.CompositeLayer] : -1,
				cmd.Backdrop ? 1 : 0);
			var stateHash = HashBytes(&state, sizeof(int32[6]));
			stateHash = HashBytes(&texture, sizeof(int32), stateHash);
			for (int i = 0; i + 3 <= cmd.IndexCount; i += 3)
			{
				let first = cmd.StartIndex + i;
				if (!TriangleShows(cmd, first))
					continue;
				var h = stateHash;
				for (int k = 0; k < 3; k++)
				{
					let at = first + k;
					if (cmd.DrawMode == .Box)
					{
						var v = batch.BoxVertices[at];
						h = HashBytes(&v, sizeof(VGBoxVertex), h);
					}
					else
					{
						var v = batch.Vertices[(int)batch.Indices[at]];
						h = HashBytes(&v, sizeof(VGVertex), h);
					}
				}
				outHashes.Add(h);
			}
		}
	}

	[Test]
	public static void TheSameGeometryShowsWithCullingOnAsOffAtTheTopScrolledAndAtTheEnd()
	{
		let page = scope CullPage();
		float[3] scrolls = .(0.0f, 731.0f, 100000.0f);
		for (let scroll in scrolls)
		{
			page.Root.UpdateLayout();
			page.Scroller.ScrollOffset = .(0.0f, scroll);
			let reference = scope List<uint64>();
			let culled = scope List<uint64>();
			let culledOff = page.Draw(false, reference);
			let culledOn = page.Draw(true, culled);
			Test.Assert(culledOff == 0, scope $"scroll {scroll}");
			Test.Assert(culledOn < 20, scope $"scroll {scroll}"); // the 80 rows out of view are skipped by the scroller's index, not visited
			Test.Assert(reference.Count == culled.Count, scope $"scroll {scroll}");
			bool same = true;
			for (int i = 0; i < reference.Count; i++)
				same = same && (reference[i] == culled[i]);
			Test.Assert(same, scope $"scroll {scroll}");
			Test.Assert(reference.Count > 0, scope $"scroll {scroll}");
		}
	}

	[Test]
	public static void ANodesInkReachesItsOuterShadowAndItsFilterAndItsSubtreesPastItsBox()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let shadowed = Add(root, "box");
		let styles = scope StyleManager();
		UseSheet(styles,
			"box { position: absolute; left: 10px; top: 10px; width: 100px; height: 50px; box-shadow: 4px 6px 10px 2px #000000, inset 0 0 40px #ffffff; }" +
			"box > far { position: absolute; left: 150px; top: 0px; width: 10px; height: 10px; }" +
			"blurred { width: 20px; height: 20px; filter: blur(2px); }");
		styles.ApplyTree(root);
		root.UpdateLayout();
		// The outer shadow: 2 of spread and 15 of blur (three sigma of a CSS blur of 10) past the
		// offset; the inset one adds nothing.
		let ink = shadowed.InkBounds;
		Test.Assert(Near(ink.X, 4.0f - 17.0f));
		Test.Assert(Near(ink.Y, 6.0f - 17.0f));
		Test.Assert(Near(ink.Right, 100.0f + 4.0f + 17.0f));
		Test.Assert(Near(ink.Bottom, 50.0f + 6.0f + 17.0f));

		// A child placed past the box widens the subtree's ink, and moving it changes the ink kept.
		let far = Add(shadowed, "far");
		styles.ApplyTree(root);
		root.UpdateLayout();
		Test.Assert(Near(shadowed.SubtreeInk.Right, 160.0f));
		far.Position = .(300.0f, 0.0f);
		Test.Assert(Near(shadowed.SubtreeInk.Right, 310.0f));

		// A filter's blur widens it all by three sigma.
		let blurred = Add(root, "blurred");
		styles.ApplyTree(root);
		root.UpdateLayout();
		Test.Assert(Near(blurred.SubtreeInk.X, -6.0f));
		Test.Assert(Near(blurred.SubtreeInk.Width, 32.0f));
	}

	/// A host's frame: style, tick, lay out, ask, draw; what it asked.
	private static bool HostFrame(SceneRoot root, StyleManager styles)
	{
		styles.ApplyTree(root);
		root.Context.Update(SceneFixtures.Frame);
		root.UpdateLayout();
		let needed = root.NeedsFrame();
		let canvas = scope VGContext();
		let dc = scope DrawContext(canvas);
		root.DrawFrame(dc);
		return needed;
	}

	[Test]
	public static void AFadingBoxOutOfViewAsksForNoFramesScrolledIntoViewItDoesATurningOneAlwaysDoes()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let page = Add(root, "page");
		Add(page, "spacer");
		let fading = Add(page, "fading");
		let styles = scope StyleManager();
		UseSheet(styles,
			"page { width: 400px; height: 300px; overflow: auto; flex-direction: column; }" +
			"spacer { height: 2000px; }" +
			"fading { width: 40px; height: 40px; background-color: #ffffff; animation: fade 1s infinite alternate; }" +
			"turning { width: 40px; height: 40px; background-color: #ffffff; animation: turn 1s infinite; }" +
			"@keyframes fade { from { opacity: 0.2; } to { opacity: 1; } }" +
			"@keyframes turn { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }");

		Test.Assert(HostFrame(root, styles)); // the first frame
		Test.Assert(fading.DrawnFrame == 0); // culled: below the page's view
		Test.Assert(!HostFrame(root, styles));
		Test.Assert(root.LastFrameStats.AnimatedNode.IsEmpty);

		page.ScrollOffset = .(0.0f, 1900.0f); // into view: a redraw, which draws it
		Test.Assert(HostFrame(root, styles));
		Test.Assert(fading.DrawnFrame != 0);
		Test.Assert(HostFrame(root, styles)); // now its animation asks
		Test.Assert(root.LastFrameStats.Reasons.Animation);

		page.ScrollOffset = .(0.0f, 0.0f);
		Test.Assert(HostFrame(root, styles));
		Test.Assert(!HostFrame(root, styles)); // out of view again: quiet

		// A turning box could swing into view: out of view, it still asks.
		let turning = Add(page, "turning");
		Test.Assert(HostFrame(root, styles));
		Test.Assert(HostFrame(root, styles));
		Test.Assert(turning.DrawnFrame == 0);
		Test.Assert(HostFrame(root, styles));
		Test.Assert(root.LastFrameStats.Reasons.Animation);
	}

	[Test]
	public static void ABoxInViewFadingInFromNothingKeepsAskingForFrames()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let fading = Add(root, "fading");
		let styles = scope StyleManager();
		UseSheet(styles,
			"fading { width: 40px; height: 40px; background-color: #ffffff; animation: rise 1s infinite alternate; }" +
			"@keyframes rise { from { opacity: 0; } to { opacity: 1; } }");
		Test.Assert(HostFrame(root, styles)); // the first frame, at opacity 0
		Test.Assert(fading.DrawnFrame != 0); // in view, though nothing of it shows
		Test.Assert(HostFrame(root, styles)); // its fade asks: it is no quiet animation out of sight
		Test.Assert(root.LastFrameStats.Reasons.Animation);
	}

	/// What the index must give: every child whose transformed subtree ink meets `area`, in order,
	/// into `outNodes`.
	private static void ReachingByWalk(Node parent, Rect area, List<Node> outNodes)
	{
		for (int i = 0; i < parent.ChildCount; i++)
		{
			let c = parent.GetChildAt(i);
			let r = c.Transform.TransformRect(c.SubtreeInk);
			if ((r.X <= area.Right) && (area.X <= r.Right) && (r.Y <= area.Bottom) && (area.Y <= r.Bottom))
				outNodes.Add(c);
		}
	}

	private static bool SameNodes(List<Node> a, List<Node> b)
	{
		if (a.Count != b.Count)
			return false;
		for (int i = 0; i < a.Count; i++)
		{
			if (a[i] != b[i])
				return false;
		}
		return true;
	}

	/// Whether `scroller`'s index of its children agrees with a walk, over points, rows and views
	/// down the page.
	private static bool IndexAgrees(Node scroller)
	{
		float[3] heights = .(0.0f, 40.0f, 300.0f); // a point, a row, a view
		bool all = true;
		let indexed = scope List<Node>();
		let walked = scope List<Node>();
		for (float y = -100.0f; y < 3200.0f; y += 97.0f)
		{
			for (let h in heights)
			{
				let area = Rect(10.0f, y, 200.0f, h);
				indexed.Clear();
				walked.Clear();
				scroller.ChildrenReaching(area, indexed);
				ReachingByWalk(scroller, area, walked);
				all = all && SameNodes(indexed, walked);
			}
		}
		return all;
	}

	[Test]
	public static void ANodesIndexOfItsChildrenAgreesWithAWalkMovedScatteredAndPainted()
	{
		let page = scope CullPage();
		let geometry = scope List<uint64>();
		page.Draw(true, geometry);
		let scroller = page.Scroller;
		Test.Assert(IndexAgrees(scroller));
		let builds = scroller.ChildIndexBuilds;
		Test.Assert(builds >= 1);

		// A card fades in a row: something under the scroller changed, but no reach moved.
		scroller.GetChildAt(5).GetChildAt(0).Alpha = 0.5f;
		geometry.Clear();
		page.Draw(true, geometry);
		Test.Assert(IndexAgrees(scroller));
		Test.Assert(scroller.ChildIndexBuilds == builds);

		// Rows moved and scattered out of order: built again, and still agreeing.
		scroller.GetChildAt(3).Position = .(20.0f, 2500.0f);
		scroller.GetChildAt(70).Position = .(0.0f, 10.0f);
		geometry.Clear();
		page.Draw(true, geometry);
		Test.Assert(scroller.ChildIndexBuilds > builds);
		Test.Assert(IndexAgrees(scroller));
		// A child taken away and one added: the index is of the children it has.
		scroller.RemoveChild(scroller.GetChildAt(10));
		Add(scroller, "row");
		geometry.Clear();
		page.Draw(true, geometry);
		Test.Assert(IndexAgrees(scroller));
	}

	[Test]
	public static void APointFindsThroughTheIndexWhatItFindsByTryingEachChild()
	{
		let page = scope CullPage();
		let geometry = scope List<uint64>();
		page.Draw(true, geometry);
		page.Scroller.ScrollOffset = .(0.0f, 731.0f);
		geometry.Clear();
		page.Draw(true, geometry);
		let scroller = page.Scroller;
		bool same = true;
		int found = 0;
		for (float y = 2.0f; y < 300.0f; y += 7.0f)
		{
			for (float x = 2.0f; x < 370.0f; x += 13.0f) // short of the box placed over the page's edge
			{
				let p = Float2(x, y);
				Node expected = null;
				for (int i = scroller.ChildCount - 1; (i >= 0) && (expected == null); i--)
					expected = scroller.GetChildAt(i).OverFind(p);
				if ((expected == null) && scroller.PointInside(p))
					expected = scroller;
				var hit = page.Root.OverFind(p);
				if (hit == page.Root)
					hit = null; // the root's own box: what the walk above does not try
				same = same && (hit == expected);
				found += (hit != null) ? 1 : 0;
			}
		}
		Test.Assert(same);
		Test.Assert(found > 100);
	}
}
