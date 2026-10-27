using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.GUI;
using Sedulous.GUI.Inspector;

namespace Sedulous.GUI.Testing;

// Helpers for tests of GUIs built with the GUI (E8f of Specs/gui-lab-evolution.md).
//
// A Finder names nodes: by CSS selector (the GUI's own engine, eepp's querySelector) or by their
// text (a widget's reflected `Text`, the outermost of a widget and its parts), within another
// finder's match, shown ones only unless asked. A Tester drives one root on a fixed clock: every
// action is followed by a frame (update, style, layout), so a test reads what a user would see.
// Its actions are the user's: click, right click, double click, hover, drag, type, a key chord, a
// held direction, a pad button, files dropped. Each aims at the middle of what it found, and fails
// when something else lies there. A finder that expects one node and finds none or several fails,
// listing what it found and the tree around where it looked; failures go to a handler (a test's
// assertion) and are kept. CompareImages is the image tests' match (E8g): every channel within a
// tolerance on all but a small share of the pixels, with a picture of where they differ.

static
{
	/// The text a node shows, appended to `outText`: its reflected `Text` (a label's, a button's,
	/// a field's), or nothing.
	public static void TextOf(Node node, String outText)
	{
		for (var t = node.GuiType; t != null; t = t.Base)
		{
			for (let property in t.OwnProperties)
			{
				if (property.Name != "Text")
					continue;
				var value = property.Get(node);
				var text = ConvertVariant(value, typeof(String));
				if (IsText(text))
					outText.Append(Sedulous.GUI.TextOf(text));
				text.Dispose();
				value.Dispose();
				return;
			}
		}
	}

	/// The middle of `node` in `root`'s world (device pixels: where the dispatcher takes a pointer),
	/// and whether a pointer there reaches it: the node, or a part of it (a button's label), lies
	/// there; else `over` is what does (null: nothing). What a user's click on it would hit, so the
	/// editor's input tools and the tests cannot disagree.
	public static bool AimAt(SceneRoot root, Node node, out Float2 at, out Node over)
	{
		let @box = node.ScreenBounds;
		at = .(@box.X + @box.Width * 0.5f, @box.Y + @box.Height * 0.5f);
		let hit = root.OverFind(at);
		over = hit;
		for (var n = hit; n != null; n = n.Parent)
		{
			if (n == node)
				return true;
		}
		// A part of it counts; what lies over it does not.
		for (var n = node; (hit != null) && (n != null); n = n.Parent)
		{
			if ((n == hit) && (hit != root))
				return true;
		}
		return false;
	}
}

/// Which nodes a test means: by selector or text, within another finder's match, shown only
/// unless IncludingHidden. A finder is its steps, outermost first: each looks under the first
/// node the step before it found. A value: it holds views of its patterns, so the text it was
/// made from (a literal, or what Parse was given) must outlive it.
struct Finder
{
	/// The most steps a finder holds (a finder within a finder within ...); Within past it asserts.
	public const int cMaxSteps = 8;

	private enum Kind : uint8
	{
		Selector,
		Text,
		TextContaining,
	}

	private struct Step
	{
		public Kind What;
		public StringView Pattern;
		public bool Hidden;

		public this(Kind what, StringView pattern)
		{
			What = what;
			Pattern = pattern;
			Hidden = false;
		}
	}

	private Step[cMaxSteps] mSteps = default;
	private int mCount = 0;

	private this(Kind kind, StringView pattern)
	{
		mSteps[0] = Step(kind, pattern);
		mCount = 1;
	}

	/// The widgets a CSS selector matches ("#ok", "button.primary", "panel > label").
	public static Finder Selector(StringView selector) => Finder(.Selector, selector);
	/// The nodes showing exactly `text` (the outermost of a widget and the parts that show it).
	public static Finder Text(StringView text) => Finder(.Text, text);
	/// The nodes whose text holds `text`.
	public static Finder TextContaining(StringView text) => Finder(.TextContaining, text);

	/// "text=Show" or "text~=Sho" is by text, anything else a selector (the sandbox's --keys).
	public static Finder Parse(StringView spec)
	{
		const String exact = "text=";
		const String containing = "text~=";
		if (spec.StartsWith(exact))
			return Text(spec.Substring(exact.Length));
		if (spec.StartsWith(containing))
			return TextContaining(spec.Substring(containing.Length));
		return Selector(spec);
	}

	/// Only under what `scope` finds (the first of it, when it finds several).
	public Finder Within(Finder @scope)
	{
		var f = @scope;
		for (int i = 0; i < mCount; i++)
			f.Push(mSteps[i]);
		return f;
	}

	/// Hidden nodes too (not shown, or under a node not shown or out of the layout).
	public Finder IncludingHidden()
	{
		var f = this;
		if (f.mCount > 0)
			f.mSteps[f.mCount - 1].Hidden = true;
		return f;
	}

	/// What it finds under `root`, in document order, added to `outNodes`.
	public void All(Node root, List<Node> outNodes)
	{
		Node within = root;
		let found = scope List<Node>();
		for (int i = 0; i < mCount; i++)
		{
			found.Clear();
			Run(mSteps[i], within, found);
			if (i + 1 < mCount)
			{
				if (found.IsEmpty)
					return;
				within = found[0];
			}
		}
		outNodes.AddRange(found);
	}

	/// How a failure names it ("selector #ok within text=Settings"), appended to `outText`.
	public void Describe(String outText)
	{
		for (int i = mCount - 1; i >= 0; i--)
		{
			let step = mSteps[i];
			outText.Append((step.What == .Selector) ? "selector " : ((step.What == .Text) ? "text=" : "text~="));
			outText.Append(step.Pattern);
			if (step.Hidden)
				outText.Append(" (hidden too)");
			if (i > 0)
				outText.Append(" within ");
		}
	}

	private void Push(Step step) mut
	{
		Runtime.Assert(mCount < cMaxSteps, "a finder holds at most cMaxSteps steps");
		mSteps[mCount++] = step;
	}

	private static bool Holds(StringView text, StringView part)
	{
		for (int i = 0; i + part.Length <= text.Length; i++)
		{
			if (text.Substring(i, part.Length) == part)
				return true;
		}
		return false;
	}

	// The by-text walk: `node` and what it holds, the outermost match of each branch.
	private static void Walk(Step step, Node node, bool matchedAbove, List<Node> outNodes)
	{
		let text = scope String();
		TextOf(node, text);
		let match = (step.What == .Text)
			? (StringView(text) == step.Pattern)
			: ((text.Length != 0) && Holds(text, step.Pattern));
		if (match && !matchedAbove)
			outNodes.Add(node);
		for (int i = 0; i < node.ChildCount; i++)
		{
			if (let child = node.GetChildAt(i))
				Walk(step, child, matchedAbove || match, outNodes);
		}
	}

	private static void Run(Step step, Node @scope, List<Node> outNodes)
	{
		let start = outNodes.Count;
		if (step.What == .Selector)
			Sedulous.GUI.Inspector.Query(@scope, step.Pattern, outNodes);
		else
			Walk(step, @scope, false, outNodes);
		if (!step.Hidden)
		{
			for (int i = outNodes.Count - 1; i >= start; i--)
			{
				if (!outNodes[i].IsTreeVisible)
					outNodes.RemoveAt(i);
			}
		}
	}
}

/// Drives one root as a user would, a frame after every action on a fixed clock. It holds the
/// root without a reference of its own: the root must outlive it.
class Tester
{
	private const uint64 cFinger = 1; // the tester's one finger
	private const uint64 cSecondFinger = 2;
	private const int cSteps = 8;

	private SceneRoot mRoot;
	private StyleManager mStyles;
	private TimeSpan mFrame;
	private delegate void(StringView message) mOnFailure ~ delete _;
	private delegate void(StringView name) mCapture ~ delete _;
	private List<String> mFailures = new .() ~ DeleteContainerAndItems!(_);

	/// A sixtieth of a second, by ticks.
	public static TimeSpan DefaultFrame => TimeSpan(TimeSpan.TicksPerSecond / 60);

	/// `styles` styles it each frame (null: the root is styled elsewhere, or not at all).
	public this(SceneRoot root, StyleManager styles = null) : this(root, styles, DefaultFrame)
	{
	}

	public this(SceneRoot root, StyleManager styles, TimeSpan frame)
	{
		mRoot = root;
		mStyles = styles;
		mFrame = frame;
		Frame();
	}

	/// Where failures go as well as into Failures (a test asserts there). OWNERSHIP of `handler`
	/// transfers.
	public void SetFailureHandler(delegate void(StringView message) handler)
	{
		delete mOnFailure;
		mOnFailure = handler;
	}

	/// What saves the screen at a failure, given a name for it (`failure-1`, ...): a host with a
	/// device (the sandbox's image tests) writes the frame there; none, nothing is saved.
	/// OWNERSHIP of `capture` transfers.
	public void SetFailureCapture(delegate void(StringView name) capture)
	{
		delete mCapture;
		mCapture = capture;
	}

	/// Every failure so far, oldest first; the tester owns them.
	public List<String> Failures => mFailures;

	// === Time ===

	/// One frame: the clock moves by the frame's length, then style and layout.
	public void Frame()
	{
		mRoot.Context.Update(mFrame);
		if (mStyles != null)
			mStyles.ApplyTree(mRoot);
		mRoot.UpdateLayout();
	}

	/// Frames until `time` has passed (an animation runs, a held key repeats).
	public void Advance(TimeSpan time)
	{
		let frames = time.TotalSeconds / mFrame.TotalSeconds;
		let count = (int64)(frames + 0.5);
		for (int64 i = 0; i < count; i++)
			Frame();
	}

	// === Finding ===

	/// What `finder` finds, added to `outNodes`.
	public void All(Finder finder, List<Node> outNodes) => finder.All(mRoot, outNodes);

	public bool Exists(Finder finder)
	{
		let found = scope List<Node>();
		finder.All(mRoot, found);
		return !found.IsEmpty;
	}

	/// The one node `finder` finds; a failure (and null) when it finds none or several.
	public Node One(Finder finder)
	{
		let found = scope List<Node>();
		finder.All(mRoot, found);
		if (found.Count == 1)
			return found[0];
		let message = scope String();
		finder.Describe(message);
		message.AppendF(" found {} nodes, expected one", found.Count);
		for (let n in found)
		{
			message.Append("\n  found: ");
			Sedulous.GUI.Inspector.Label(n, message);
		}
		message.Append("\n");
		Dump(message);
		Fail(message);
		return null;
	}

	// === The user's actions (each followed by a frame) ===

	public bool Click(Finder target) => Press(target, .Left, 1);
	public bool RightClick(Finder target) => Press(target, .Right, 1);
	public bool DoubleClick(Finder target) => Press(target, .Left, 2);

	/// The pointer moves over the middle of what `target` finds.
	public bool Hover(Finder target)
	{
		var at = Float2(0.0f, 0.0f);
		if (!Aim(target, out at))
			return false;
		Dispatcher.InjectMouseMove(at);
		Frame();
		return true;
	}

	/// The pointer leaves the root (what it hovered is left).
	public void Leave()
	{
		Dispatcher.InjectMouseMove(.(-1.0f, -1.0f));
		Frame();
	}

	/// The wheel turned over the middle of what `target` finds, by `delta` in notches, as the
	/// platform reports them (a negative y scrolls down, the wheel turned toward the user).
	public bool Scroll(Finder target, Float2 delta, uint32 modifiers = 0)
	{
		var at = Float2(0.0f, 0.0f);
		if (!Aim(target, out at))
			return false;
		Dispatcher.InjectMouseMove(at);
		Dispatcher.InjectMouseWheel(at, delta, modifiers);
		Frame();
		return true;
	}

	/// A finger down and up on the middle of what `target` finds.
	public bool Tap(Finder target)
	{
		var at = Float2(0.0f, 0.0f);
		if (!Aim(target, out at))
			return false;
		let d = Dispatcher;
		d.InjectTouchDown(cFinger, at);
		Frame();
		d.InjectTouchUp(cFinger, at);
		Frame();
		return true;
	}

	/// A finger down on `from`'s middle, moved in steps by `by`, lifted there: a swipe that pans
	/// what it is over (as fast as the steps make it, which flings).
	public bool Swipe(Finder from, Float2 by)
	{
		var start = Float2(0.0f, 0.0f);
		if (!Aim(from, out start))
			return false;
		let d = Dispatcher;
		d.InjectTouchDown(cFinger, start);
		Frame();
		for (int i = 1; i <= cSteps; i++)
		{
			let t = (float)i / (float)cSteps;
			d.InjectTouchMove(cFinger, .(start.X + by.X * t, start.Y + by.Y * t));
			Frame();
		}
		d.InjectTouchUp(cFinger, .(start.X + by.X, start.Y + by.Y));
		Frame();
		return true;
	}

	/// Two fingers on `target`'s middle, `span` apart across, pinched to `toSpan` apart in steps,
	/// lifted there (E17c: a gesture where the target's touch-action takes one).
	public bool Pinch(Finder target, float span, float toSpan) => TwoFingers(target, span, toSpan, 0.0f, .(0.0f, 0.0f));

	/// Two fingers on `target`'s middle turned `radians` about it, clockwise, in steps.
	public bool Rotate(Finder target, float radians, float span = 100.0f) => TwoFingers(target, span, span, radians, .(0.0f, 0.0f));

	/// Two fingers on `target`'s middle moved together by `by` (device pixels), in steps.
	public bool TwoFingerPan(Finder target, Float2 by, float span = 100.0f) => TwoFingers(target, span, span, 0.0f, by);

	/// Pressed on `from`, moved in steps to `to`'s middle, released there.
	public bool DragTo(Finder from, Finder to)
	{
		let target = One(to);
		if (target == null)
			return false;
		let @box = target.ScreenBounds;
		return DragTo(from, Float2(@box.X + @box.Width * 0.5f, @box.Y + @box.Height * 0.5f));
	}

	/// Pressed on `from`, moved in steps to `to` (the root's world), released there.
	public bool DragTo(Finder from, Float2 to)
	{
		var start = Float2(0.0f, 0.0f);
		if (!Aim(from, out start))
			return false;
		let d = Dispatcher;
		d.InjectMouseMove(start);
		d.InjectMouseDown(start, .Left);
		Frame();
		for (int i = 1; i <= cSteps; i++)
		{
			let t = (float)i / (float)cSteps;
			d.InjectMouseMove(.(start.X + (to.X - start.X) * t, start.Y + (to.Y - start.Y) * t));
			Frame();
		}
		d.InjectMouseUp(to, .Left);
		Frame();
		return true;
	}

	/// Text typed into what has the focus.
	public void Type(StringView text)
	{
		Dispatcher.InjectText(text);
		Frame();
	}

	/// A key chord ("return", "ctrl-a", "shift-tab", "pad-south"); false for one it does not know.
	public bool Press(StringView chord)
	{
		let stroke = ParseKeystroke(chord);
		if (!stroke.HasValue)
		{
			Fail(scope String()..AppendF("no such key chord: {}", chord));
			return false;
		}
		let s = stroke.Value;
		if (s.Pad)
			Dispatcher.InjectPadButton((PadButton)s.Code);
		else
		{
			Dispatcher.InjectKeyDown(s.Code, s.Modifiers);
			Dispatcher.InjectKeyUp(s.Code, s.Modifiers);
		}
		Frame();
		return true;
	}

	/// An arrow, the d-pad or the stick held one way for `time` (it repeats as it does for a user).
	public void HoldDirection(NavDirection direction, TimeSpan time)
	{
		Dispatcher.PressDirection(direction);
		Frame();
		Advance(time);
		Dispatcher.ReleaseDirection(direction);
		Frame();
	}

	/// A pad button pressed.
	public void PadPress(PadButton button)
	{
		Dispatcher.InjectPadButton(button);
		Frame();
	}

	/// Files the OS drops on the middle of what `target` finds (the dispatcher copies the paths).
	public bool DropFiles(Finder target, Span<StringView> paths)
	{
		var at = Float2(0.0f, 0.0f);
		if (!Aim(target, out at))
			return false;
		Dispatcher.InjectFileDrop(at, paths);
		Frame();
		return true;
	}

	/// The tree under the root, one node a line, indented by depth, appended to `outText`.
	public void Dump(String outText) => Dump(null, outText);

	/// The tree under `around` (the root when null), one node a line, indented by depth, appended
	/// to `outText`.
	public void Dump(Node around, String outText)
	{
		let entries = scope List<TreeEntry>();
		defer { ClearAndDeleteItems!(entries); }
		Node top = (around != null) ? around : (Node)mRoot;
		Sedulous.GUI.Inspector.Tree(top, entries);
		let text = scope String();
		for (let e in entries)
		{
			for (uint32 d = 0; d < e.Depth; d++)
				outText.Append("  ");
			outText.Append(e.Label);
			text.Clear();
			TextOf(e.Target, text);
			if (text.Length != 0)
			{
				outText.Append(" \"");
				outText.Append(text);
				outText.Append("\"");
			}
			if (!e.Shown)
				outText.Append(" (hidden)");
			outText.Append("\n");
		}
	}

	private EventDispatcher Dispatcher => mRoot.EventDispatcher;

	private void Fail(StringView message)
	{
		mFailures.Add(new String(message));
		if (mOnFailure != null)
			mOnFailure(message);
		if (mCapture != null)
			mCapture(scope String()..AppendF("failure-{}", mFailures.Count));
	}

	// The middle of the one node `target` finds, if a pointer there reaches it (not something
	// over it): AimAt's check.
	private bool Aim(Finder target, out Float2 at)
	{
		at = .(0.0f, 0.0f);
		let node = One(target);
		if (node == null)
			return false;
		if (AimAt(mRoot, node, out at, let over))
			return true;
		let message = scope String();
		target.Describe(message);
		message.Append(" is covered at its middle by ");
		if (over != null)
			Sedulous.GUI.Inspector.Label(over, message);
		else
			message.Append("nothing");
		Fail(message);
		return false;
	}

	private bool Press(Finder target, MouseButton button, int clicks)
	{
		var at = Float2(0.0f, 0.0f);
		if (!Aim(target, out at))
			return false;
		let d = Dispatcher;
		d.InjectMouseMove(at);
		for (int i = 0; i < clicks; i++)
		{
			d.InjectMouseDown(at, button);
			d.InjectMouseUp(at, button);
			Frame();
		}
		return true;
	}

	// Two fingers about `target`'s middle, from `span` apart across to `toSpan`, the line between
	// them turning `turn` and their middle moving `by`, eight steps a frame each.
	private bool TwoFingers(Finder target, float span, float toSpan, float turn, Float2 by)
	{
		var middle = Float2(0.0f, 0.0f);
		if (!Aim(target, out middle))
			return false;
		Float2 Place(float t, float side)
		{
			let half = (span + (toSpan - span) * t) * 0.5f * side;
			let angle = turn * t;
			return .(middle.X + by.X * t + half * Math.Cos(angle), middle.Y + by.Y * t + half * Math.Sin(angle));
		}
		let d = Dispatcher;
		d.InjectTouchDown(cFinger, Place(0.0f, -1.0f));
		d.InjectTouchDown(cSecondFinger, Place(0.0f, 1.0f));
		Frame();
		for (int i = 1; i <= cSteps; i++)
		{
			let t = (float)i / (float)cSteps;
			d.InjectTouchMove(cFinger, Place(t, -1.0f));
			d.InjectTouchMove(cSecondFinger, Place(t, 1.0f));
			Frame();
		}
		d.InjectTouchUp(cSecondFinger, Place(1.0f, 1.0f));
		d.InjectTouchUp(cFinger, Place(1.0f, -1.0f));
		Frame();
		return true;
	}
}

/// How a picture compares with its reference (E8g).
struct ImageComparison
{
	public bool SameSize = false;
	/// Pixels with a channel past the tolerance.
	public uint64 Differing = 0;
	public uint64 Pixels = 0;
	/// The largest channel difference anywhere.
	public uint32 LargestDelta = 0;
	public bool Matches = false;

	public this() { }
}

static
{
	/// Compares `picture` with `reference` (both RGBA8): they match when they are the same size
	/// and every channel is within `tolerance` on all but `allowedShare` of the pixels (eepp's
	/// budget, zed's share). `diff`, when given, is made a picture of the difference: the
	/// reference faded to grey, the differing pixels red (the caller keeps it).
	public static ImageComparison CompareImages(ImageData picture, ImageData reference, uint32 tolerance = 8,
		double allowedShare = 0.001, Sedulous.Image.Image diff = null)
	{
		ImageComparison @out = .();
		@out.SameSize = (picture.Width == reference.Width) && (picture.Height == reference.Height) &&
			(picture.Format == .RGBA8) && (reference.Format == .RGBA8);
		if (!@out.SameSize)
			return @out;
		@out.Pixels = (uint64)picture.Width * (uint64)picture.Height;
		let a = picture.PixelData;
		let b = reference.PixelData;
		let picturedDiff = scope List<uint8>();
		if (diff != null)
			picturedDiff.Resize(a.Length);
		for (int i = 0; i + 3 < a.Length; i += 4)
		{
			uint32 delta = 0;
			for (int c = 0; c < 4; c++)
			{
				let d = (int32)a[i + c] - (int32)b[i + c];
				delta = Math.Max(delta, (uint32)((d < 0) ? -d : d));
			}
			@out.LargestDelta = Math.Max(@out.LargestDelta, delta);
			let differs = delta > tolerance;
			if (differs)
				@out.Differing++;
			if (diff != null)
			{
				let grey = (uint8)(((uint32)b[i] + (uint32)b[i + 1] + (uint32)b[i + 2]) / 9 + 40);
				picturedDiff[i] = differs ? (uint8)255 : grey;
				picturedDiff[i + 1] = differs ? (uint8)0 : grey;
				picturedDiff[i + 2] = differs ? (uint8)0 : grey;
				picturedDiff[i + 3] = 255;
			}
		}
		@out.Matches = (double)@out.Differing <= allowedShare * (double)@out.Pixels;
		if (diff != null)
			diff.ReplaceData(picture.Width, picture.Height, .RGBA8, Span<uint8>(picturedDiff.Ptr, picturedDiff.Count));
		return @out;
	}
}
