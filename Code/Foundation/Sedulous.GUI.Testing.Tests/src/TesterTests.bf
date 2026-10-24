using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.GUI;
using Sedulous.GUI.Testing;

namespace Sedulous.GUI.Testing.Tests;

/// What the tester's tests share.
static class TesterFixtures
{
	/// A root of a GUI of its own, `width` by `height`, held by the caller: it releases it, and the
	/// GUI goes with it.
	public static SceneRoot NewRoot(float width, float height)
	{
		let context = new GUIContext();
		let root = new SceneRoot(context);
		context.ReleaseRef(); // the root's keeps it
		root.Size = .(width, height);
		return root;
	}

	/// A new `T` with the id `id` at (`x`, `y`), `w` by `h`, under `parent`. The caller holds a
	/// reference of its own and releases it.
	public static T Add<T>(Node parent, StringView id, float x, float y, float w, float h) where T : UIWidget, new
	{
		let node = new T();
		node.Id = id;
		node.Position = .(x, y);
		node.Size = .(w, h);
		parent.AddChild(node);
		return node;
	}

	public static TimeSpan Seconds(double s) => TimeSpan((int64)(s * (double)TimeSpan.TicksPerSecond));

	/// doctest's Approx: within a relative epsilon (scaled by 1 plus the larger magnitude).
	public static bool Near(double a, double b, double epsilon = 1.2e-5) =>
		Math.Abs(a - b) < epsilon * (1.0 + Math.Max(Math.Abs(a), Math.Abs(b)));

	/// A 100 by 100 RGBA8 picture of `shade` (opaque), the red of its first `changed` pixels `to`.
	/// The caller deletes it.
	public static Sedulous.Image.Image Picture(uint8 shade, int changed, uint8 to)
	{
		let rgba = scope List<uint8>();
		rgba.Resize(100 * 100 * 4);
		for (int i = 0; i < rgba.Count; i++)
			rgba[i] = ((i % 4) == 3) ? (uint8)255 : shade;
		for (int p = 0; p < changed; p++)
			rgba[p * 4] = to;
		return new Sedulous.Image.Image(100, 100, .RGBA8, Span<uint8>(rgba.Ptr, rgba.Count));
	}
}

/// The tester (E8f of Specs/gui-lab-evolution.md): finders by selector and text, within a scope,
/// hidden ones only when asked; a finder expecting one that finds none or several fails with what
/// it found and the tree; the user's actions reach what they aim at, or fail when something covers
/// it; the clock steps a frame after each.
class TesterTests
{
	/// A form: a "Show" button, a field, a dialog with its own "OK" beside the form's "OK", and a
	/// hidden "Secret" label. The root (and its tree) goes with it.
	private class Bed
	{
		public SceneRoot Root;
		public Button Show;
		public TextField Field;
		public Panel Dialog;
		public Button Ok;
		public Button DialogOk;
		public Sedulous.GUI.Label Secret;
		public int Clicks = 0;

		public this()
		{
			Root = TesterFixtures.NewRoot(400.0f, 300.0f);
			Show = TesterFixtures.Add<Button>(Root, "show", 10.0f, 10.0f, 80.0f, 30.0f);
			Show.Text = "Show";
			Show.SetOnClick(new () => { Clicks++; });
			Field = TesterFixtures.Add<TextField>(Root, "field", 10.0f, 50.0f, 150.0f, 30.0f);
			Ok = TesterFixtures.Add<Button>(Root, "ok", 10.0f, 90.0f, 80.0f, 30.0f);
			Ok.Text = "OK";
			Dialog = TesterFixtures.Add<Panel>(Root, "dialog", 200.0f, 10.0f, 180.0f, 150.0f);
			DialogOk = TesterFixtures.Add<Button>(Dialog, "dialog-ok", 10.0f, 10.0f, 80.0f, 30.0f);
			DialogOk.Text = "OK";
			Secret = TesterFixtures.Add<Sedulous.GUI.Label>(Root, "secret", 10.0f, 200.0f, 80.0f, 20.0f);
			Secret.Text = "Secret";
			Secret.Visible = false;
		}

		public ~this()
		{
			Secret.ReleaseRef();
			DialogOk.ReleaseRef();
			Dialog.ReleaseRef();
			Ok.ReleaseRef();
			Field.ReleaseRef();
			Show.ReleaseRef();
			Root.ReleaseRef();
		}
	}

	[Test]
	public static void FindersBySelectorAndByTextWithinAScopeHiddenOnesOnlyWhenAsked()
	{
		let bed = scope Bed();
		let t = scope Tester(bed.Root);
		Test.Assert(t.One(Finder.Selector("#show")) == bed.Show);
		Test.Assert(t.One(Finder.Text("Show")) == bed.Show); // the button, not its label part too
		Test.Assert(t.One(Finder.TextContaining("Sho")) == bed.Show);
		Test.Assert(t.One(Finder.Text("OK").Within(Finder.Selector("#dialog"))) == bed.DialogOk);
		Test.Assert(!t.Exists(Finder.Text("Secret")));
		Test.Assert(t.One(Finder.Text("Secret").IncludingHidden()) == bed.Secret);
		Test.Assert(t.Failures.IsEmpty);
		let described = scope String();
		Finder.Parse("text=OK").Within(Finder.Parse("#dialog")).Describe(described);
		Test.Assert(described == "text=OK within selector #dialog");
	}

	[Test]
	public static void ExpectingOneAndFindingSeveralOrNoneFailsNamingWhatItFoundWithTheTree()
	{
		let bed = scope Bed();
		let t = scope Tester(bed.Root);
		let seen = scope List<String>();
		defer { ClearAndDeleteItems!(seen); }
		t.SetFailureHandler(new [&] (message) => { seen.Add(new String(message)); });
		Test.Assert(t.One(Finder.Text("OK")) == null);
		Test.Assert(seen.Count == 1);
		let message = seen[0];
		Test.Assert(message.StartsWith("text=OK found 2 nodes, expected one"));
		Test.Assert(message.Contains("found: Button #ok", true));
		Test.Assert(message.Contains("Button #dialog-ok \"OK\"", true)); // the tree, with texts
		Test.Assert(t.One(Finder.Selector("#nothing")) == null);
		Test.Assert(t.Failures.Count == 2);
	}

	[Test]
	public static void ClicksReachWhatTheyAimAtAndFailWhenSomethingLiesOverIt()
	{
		let bed = scope Bed();
		let t = scope Tester(bed.Root);
		Test.Assert(t.Click(Finder.Text("Show")));
		Test.Assert(bed.Clicks == 1);
		uint32 most = 0;
		bed.Show.AddEventListener(.MouseClick, new [&] (e) => { most = Math.Max(most, ((MouseEvent)e).ClickCount); });
		t.Advance(TesterFixtures.Seconds(1.0)); // the click before is no part of it
		Test.Assert(t.DoubleClick(Finder.Selector("#show")));
		Test.Assert(most == 2);
		// A panel laid over the button: the click would land on it.
		let cover = TesterFixtures.Add<Panel>(bed.Root, "cover", 0.0f, 0.0f, 120.0f, 60.0f);
		defer cover.ReleaseRef();
		t.Frame();
		let before = bed.Clicks;
		Test.Assert(!t.Click(Finder.Selector("#show")));
		Test.Assert(bed.Clicks == before);
		Test.Assert(!t.Failures.IsEmpty);
		Test.Assert(t.Failures[t.Failures.Count - 1].Contains("covered at its middle by Panel #cover", true));
	}

	[Test]
	public static void TypingGoesToTheFocusKeysMoveItAndAHeldArrowRepeats()
	{
		let bed = scope Bed();
		let t = scope Tester(bed.Root);
		Test.Assert(t.Click(Finder.Selector("#field")));
		t.Type("hello");
		Test.Assert(bed.Field.Text == "hello");
		Test.Assert(t.Press("tab"));
		Test.Assert(bed.Root.EventDispatcher.FocusNode != bed.Field);
		Test.Assert(!t.Press("no-such-key"));

		// A column of buttons: Down held for a second walks focus down several of them.
		let column = TesterFixtures.NewRoot(200.0f, 600.0f);
		defer column.ReleaseRef();
		let buttons = scope List<Button>();
		defer
		{
			for (let b in buttons)
				b.ReleaseRef();
		}
		for (int i = 0; i < 12; i++)
		{
			let id = scope String()..Append('b')..Append((char8)((int)'a' + i));
			buttons.Add(TesterFixtures.Add<Button>(column, id, 10.0f, 10.0f + 40.0f * (float)i, 80.0f, 30.0f));
		}
		let c = scope Tester(column);
		column.EventDispatcher.FocusNode = buttons[0];
		c.HoldDirection(.Down, TesterFixtures.Seconds(1.0));
		int at = 0;
		for (int i = 0; i < buttons.Count; i++)
		{
			if (column.EventDispatcher.FocusNode == buttons[i])
				at = i;
		}
		Test.Assert(at >= 3);
	}

	[Test]
	public static void ADragPressesOnOneNodeMovesInStepsAndReleasesOverAnother()
	{
		let bed = scope Bed();
		let t = scope Tester(bed.Root);
		int moves = 0;
		Float2 released = .(0.0f, 0.0f);
		bed.Show.AddEventListener(.MouseMove, new [&] (e) => { moves++; });
		bed.Show.AddEventListener(.MouseUp, new [&] (e) => { released = ((MouseEvent)e).Position; });
		Test.Assert(t.DragTo(Finder.Selector("#show"), Finder.Selector("#ok")));
		Test.Assert(moves >= 8); // the press captures the pointer: every step reaches it
		Test.Assert(TesterFixtures.Near(released.Y, 105.0)); // over the OK button's middle
	}

	[Test]
	public static void APictureMatchesItsReferenceWithinAToleranceOnAllButAShareOfItsPixels()
	{
		let reference = TesterFixtures.Picture(100, 0, 0);
		defer delete reference;
		{
			let p = TesterFixtures.Picture(108, 0, 0);
			defer delete p;
			Test.Assert(CompareImages(p, reference).Matches); // every channel within 8
		}
		{
			let p = TesterFixtures.Picture(109, 0, 0);
			defer delete p;
			Test.Assert(!CompareImages(p, reference).Matches); // past it everywhere
		}
		{
			let p = TesterFixtures.Picture(100, 10, 200);
			defer delete p;
			Test.Assert(CompareImages(p, reference).Matches); // 10 of 10,000: within 0.1%
		}
		let diff = scope Sedulous.Image.Image();
		let p = TesterFixtures.Picture(100, 11, 200);
		defer delete p;
		let far = CompareImages(p, reference, 8, 0.001, diff); // 11: past it
		Test.Assert(!far.Matches);
		Test.Assert(far.Differing == 11);
		Test.Assert(far.LargestDelta == 100);
		Test.Assert(diff.GetPixel(0, 0).R == 255); // a differing pixel shows red
		Test.Assert(diff.GetPixel(50, 50).G == diff.GetPixel(50, 50).R); // an equal one grey
		Test.Assert(!CompareImages(scope Sedulous.Image.Image(10, 10, .RGBA8), reference).SameSize);
	}

	[Test]
	public static void RightClicksHoverAndLeavePadPressesAndFileDropsReachWhatTheyAimAt()
	{
		let bed = scope Bed();
		let tester = scope Tester(bed.Root);
		int menus = 0;
		bed.Show.AddEventListener(.ContextMenu, new [&] (e) => { menus++; });
		Test.Assert(tester.RightClick(Finder.Text("Show")));
		Test.Assert(menus == 1);
		Test.Assert(bed.Clicks == 0); // a right click is not a click

		Test.Assert(tester.Hover(Finder.Selector("#ok")));
		Test.Assert(bed.Ok.Hovered);
		tester.Leave();
		Test.Assert(!bed.Ok.Hovered);

		bed.Show.RequestFocus();
		tester.PadPress(.South); // the pad's A activates the focus
		Test.Assert(bed.Clicks == 1);

		bed.Dialog.DropTypes = "files";
		let dropped = scope List<String>();
		defer { ClearAndDeleteItems!(dropped); }
		bed.Dialog.AddEventListener(.Drop, new [&] (e) =>
			{
				ClearAndDeleteItems!(dropped);
				DroppedPaths(((DragEvent)e).Payload, dropped);
			});
		StringView[1] paths = .("/tmp/level.map");
		Test.Assert(tester.DropFiles(Finder.Selector("#dialog"), Span<StringView>(&paths[0], 1)));
		Test.Assert(dropped.Count == 1);
		Test.Assert(dropped[0] == "/tmp/level.map");
	}

	[Test]
	public static void TwoFingersPinchTurnAndPanWhatTakesGestures()
	{
		let bed = scope Bed();
		let pad = TesterFixtures.Add<Panel>(bed.Root, "pad", 200.0f, 10.0f, 200.0f, 200.0f);
		defer pad.ReleaseRef();
		pad.TouchActions = 0; // its fingers its own
		float scale = 0.0f;
		float rotation = 0.0f;
		Float2 moved = .(0.0f, 0.0f);
		pad.AddEventListener(.GestureEnd, new [&] (e) =>
			{
				let g = (GestureEvent)e;
				scale = g.Scale;
				rotation = g.Rotation;
				moved = g.Translation;
			});
		let tester = scope Tester(bed.Root);
		Test.Assert(tester.Pinch(Finder.Selector("#pad"), 60.0f, 120.0f));
		Test.Assert(TesterFixtures.Near(scale, 2.0));
		Test.Assert(tester.Rotate(Finder.Selector("#pad"), 0.5f));
		Test.Assert(TesterFixtures.Near(rotation, 0.5, 0.01));
		Test.Assert(tester.TwoFingerPan(Finder.Selector("#pad"), .(30.0f, -10.0f)));
		Test.Assert(TesterFixtures.Near(moved.X, 30.0));
		Test.Assert(TesterFixtures.Near(moved.Y, -10.0));
	}

	[Test]
	public static void TheWheelAndAFingerScrollWhatTheyAreOverAndATapClicks()
	{
		let bed = scope Bed();
		let list = TesterFixtures.Add<Panel>(bed.Root, "list", 10.0f, 130.0f, 150.0f, 60.0f);
		defer list.ReleaseRef();
		list.EditLayoutStyle(scope (style) => { style.OverflowY = .Scroll; });
		let tall = TesterFixtures.Add<Panel>(list, "tall", 0.0f, 0.0f, 150.0f, 600.0f);
		defer tall.ReleaseRef();
		let tester = scope Tester(bed.Root);

		Test.Assert(tester.Scroll(Finder.Selector("#list"), .(0.0f, -3.0f))); // toward the user: down
		let wheeled = list.ScrollOffset.Y;
		Test.Assert(wheeled > 0.0f);
		Test.Assert(tester.Swipe(Finder.Selector("#list"), .(0.0f, -40.0f))); // a finger up pans down
		Test.Assert(list.ScrollOffset.Y > wheeled);

		Test.Assert(tester.Tap(Finder.Text("Show")));
		Test.Assert(bed.Clicks == 1);
	}

	[Test]
	public static void AFailureIsHandedToTheCaptureWithANameSoAHostWithADeviceSavesTheScreen()
	{
		let bed = scope Bed();
		let tester = scope Tester(bed.Root);
		let captured = scope List<String>();
		defer { ClearAndDeleteItems!(captured); }
		tester.SetFailureCapture(new [&] (name) => { captured.Add(new String(name)); });
		Test.Assert(tester.One(Finder.Text("Nowhere")) == null);
		Test.Assert(!tester.Click(Finder.Text("Also nowhere")));
		Test.Assert(captured.Count == 2);
		Test.Assert(captured[0] == "failure-1");
		Test.Assert(captured[1] == "failure-2");
		Test.Assert(tester.Failures.Count == 2);
	}

	// Added in the port: what Raptor's tests leave uncovered.

	[Test]
	public static void ParseReadsTextTildeEqualsAsContainingAHiddenStepIsNamedAndTextOfReadsTheReflectedText()
	{
		let bed = scope Bed();
		let t = scope Tester(bed.Root);
		Test.Assert(t.One(Finder.Parse("text~=Sho")) == bed.Show);
		Test.Assert(t.One(Finder.Parse("#field")) == bed.Field);
		Test.Assert(t.One(Finder.Parse("text~=Secr").IncludingHidden()) == bed.Secret);
		let described = scope String();
		Finder.Parse("text~=Secr").IncludingHidden().Describe(described);
		Test.Assert(described == "text~=Secr (hidden too)");
		// A field's text is its reflected Text too; a panel shows none.
		bed.Field.Text = "typed";
		Test.Assert(t.One(Finder.Text("typed")) == bed.Field);
		let text = scope String();
		TextOf(bed.Show, text);
		Test.Assert(text == "Show");
		text.Clear();
		TextOf(bed.Dialog, text);
		Test.Assert(text.IsEmpty);
		// The dump marks what is hidden.
		let dump = scope String();
		t.Dump(dump);
		Test.Assert(dump.Contains("Label #secret \"Secret\" (hidden)"));
		Test.Assert(t.Failures.IsEmpty);
	}

	[Test]
	public static void AnEqualPictureMatchesWithAnAllGreyDiffAndOneNotRgba8IsNotTheSameSize()
	{
		let reference = TesterFixtures.Picture(100, 0, 0);
		defer delete reference;
		let same = TesterFixtures.Picture(100, 0, 0);
		defer delete same;
		let diff = scope Sedulous.Image.Image();
		let equal = CompareImages(same, reference, 8, 0.001, diff);
		Test.Assert(equal.SameSize && equal.Matches);
		Test.Assert(equal.Differing == 0);
		Test.Assert(equal.LargestDelta == 0);
		Test.Assert(equal.Pixels == 10000);
		Test.Assert(diff.Width == 100 && diff.Height == 100);
		let grey = diff.GetPixel(0, 0); // (100 + 100 + 100) / 9 + 40
		Test.Assert(grey.R == 73 && grey.G == 73 && grey.B == 73 && grey.A == 255);
		let rgb = scope Sedulous.Image.Image(100, 100, .RGB8);
		Test.Assert(!CompareImages(rgb, reference).SameSize);
		Test.Assert(!CompareImages(rgb, reference).Matches);
	}

	private class FrameCountingRoot : SceneRoot
	{
		public int Frames = 0;

		public this(GUIContext context) : base(context) { }

		public override void OnUpdate(TimeSpan elapsed)
		{
			Frames++;
		}
	}

	[Test]
	public static void AdvanceRunsTheNearestWholeNumberOfFrames()
	{
		let context = new GUIContext();
		let root = new FrameCountingRoot(context);
		context.ReleaseRef();
		defer root.ReleaseRef();
		let t = scope Tester(root, null, TimeSpan(TimeSpan.TicksPerSecond / 10));
		Test.Assert(root.Frames == 1); // the tester's first, so the tree is styled and laid out
		t.Advance(TimeSpan(TimeSpan.TicksPerSecond * 26 / 100)); // 2.6 frames: three
		Test.Assert(root.Frames == 4);
		t.Advance(TimeSpan(TimeSpan.TicksPerSecond * 12 / 100)); // 1.2 frames: one
		Test.Assert(root.Frames == 5);
		t.Advance(TimeSpan(TimeSpan.TicksPerSecond / 50)); // 0.2 of a frame: none
		Test.Assert(root.Frames == 5);
	}
}
