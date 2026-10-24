using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

// The parts a widget places or draws itself mirror in right to left: a part at the inline start
// moves to the other edge with its shape mirrored, and text aligned to its start goes with it.
// Each widget is drawn running left to right and right to left, and what it draws in each colour
// must cover, in right to left, the mirror of what it covers in left to right.

/// The mirroring helpers a widget places its parts with in right to left, and the widgets that
/// mirror their own parts.
class MirrorTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	/// What one colour covers.
	private struct Ink
	{
		public uint32 Colour;
		public Rect Bounds;

		public this(uint32 colour, Rect bounds)
		{
			Colour = colour;
			Bounds = bounds;
		}
	}

	private static uint32 Key(Color c)
	{
		uint32 Q(float v) => (uint32)(Math.Clamp(v, 0.0f, 1.0f) * 255.0f + 0.5f);
		return (Q(c.R) << 24) | (Q(c.G) << 16) | (Q(c.B) << 8) | Q(c.A);
	}

	private static void Cover(List<Ink> inks, Color colour, Float2 p)
	{
		if (colour.A <= 0.0f)
			return;
		let key = Key(colour);
		for (int i = 0; i < inks.Count; i++)
		{
			if (inks[i].Colour == key)
			{
				inks[i].Bounds = Rect.Merge(inks[i].Bounds, .(p.X, p.Y, 0.0f, 0.0f));
				return;
			}
		}
		inks.Add(.(key, .(p.X, p.Y, 0.0f, 0.0f)));
	}

	/// A widget `make` makes, drawn in a root running as `rightToLeft` says: what each colour covers,
	/// into `outInks`.
	private static void Drawn(delegate UIWidget() make, Float2 size, bool rightToLeft, List<Ink> outInks)
	{
		let widget = make();
		defer widget.ReleaseRef();
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		root.SetLayoutDirection(rightToLeft ? .RightToLeft : .LeftToRight);
		widget.Size = size;
		root.AddChild(widget);
		// Styled by the default theme either way, so its colours are its theme's in both.
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, Theme.DefaultThemeCSS);
		styles.ApplyTree(root);
		root.UpdateLayout();
		let canvas = scope VGContext();
		let dc = scope DrawContext(canvas);
		widget.Draw(dc);
		// In the widget's own space: the root's layout places it at the other side too.
		let at = widget.ConvertToRootSpace(.(0.0f, 0.0f));
		for (let v in canvas.GetBatch().Vertices)
			Cover(outInks, v.Color, .(v.Position.X - at.X, v.Position.Y - at.Y));
		for (let v in canvas.GetBatch().BoxVertices)
			Cover(outInks, v.Fill, .(v.Position.X - at.X, v.Position.Y - at.Y));
		root.RemoveChild(widget);
	}

	/// Every colour's ink in right to left is the mirror of its ink in left to right across the
	/// widget; and there is something mirrored to see (at least one ink not centred).
	private static void CheckMirrored(delegate UIWidget() make, Float2 size)
	{
		bool Approx(float a, float b, float epsilon) => Math.Abs(a - b) < epsilon * (1.0f + Math.Max(Math.Abs(a), Math.Abs(b)));
		let ltr = scope List<Ink>();
		Drawn(make, size, false, ltr);
		let rtl = scope List<Ink>();
		Drawn(make, size, true, rtl);
		Test.Assert(ltr.Count == rtl.Count);
		let area = Rect(0.0f, 0.0f, size.X, size.Y);
		bool asymmetric = false;
		for (let a in ltr)
		{
			Ink? b = null;
			for (let c in rtl)
			{
				if (c.Colour == a.Colour)
					b = c;
			}
			Test.Assert(b.HasValue, scope $"colour {a.Colour:X} not drawn in right to left");
			let mirrored = Rect.MirroredIn(a.Bounds, area, true);
			Test.Assert(Approx(b.Value.Bounds.X, mirrored.X, 0.02f), scope $"colour {a.Colour:X}: x {b.Value.Bounds.X}, expected {mirrored.X}");
			Test.Assert(Approx(b.Value.Bounds.Width, mirrored.Width, 0.02f), scope $"colour {a.Colour:X}: width {b.Value.Bounds.Width}, expected {mirrored.Width}");
			Test.Assert(Near(b.Value.Bounds.Y, a.Bounds.Y));
			Test.Assert(Near(b.Value.Bounds.Height, a.Bounds.Height));
			if (Math.Abs(a.Bounds.X - mirrored.X) > 1.0f)
				asymmetric = true;
		}
		Test.Assert(asymmetric);
	}

	[Test]
	public static void TheHelpersPlaceAPartAsFarFromTheRightAsItWasFromTheLeft()
	{
		let area = Rect(10.0f, 0.0f, 100.0f, 20.0f);
		Test.Assert(Near(Rect.MirroredX(15.0f, area, true), 105.0f));
		Test.Assert(Near(Rect.MirroredX(15.0f, area, false), 15.0f));
		let part = Rect.MirroredIn(Rect(12.0f, 2.0f, 20.0f, 10.0f), area, true);
		Test.Assert(Near(part.X, 88.0f));
		Test.Assert(Near(part.Y, 2.0f));
		Test.Assert(Near(part.Width, 20.0f));
	}

	[Test]
	public static void AProgressBarFillsAndAHorizontalScrollbarsThumbRunsFromTheInlineStart()
	{
		CheckMirrored(scope () =>
			{
				let bar = new ProgressBar();
				bar.Value = 0.3;
				return bar;
			}, .(200.0f, 10.0f));
		CheckMirrored(scope () =>
			{
				let bar = new ScrollBar();
				bar.Orientation = .Horizontal;
				bar.Max = 100.0;
				bar.Page = 20.0;
				bar.Value = 10.0;
				return bar;
			}, .(200.0f, 12.0f));
	}

	[Test]
	public static void ASwitchIsOnAtItsInlineEndAClosedChevronPointsTowardIt()
	{
		CheckMirrored(scope () =>
			{
				let toggle = new ToggleSwitch();
				toggle.Checked = true;
				return toggle;
			}, .(120.0f, 24.0f));
		CheckMirrored(scope () => new Expander(), .(200.0f, 24.0f));
	}

	[Test]
	public static void AHorizontalScrollbarPressedNearItsRightEndInRightToLeftGoesTowardItsStart()
	{
		let root = SceneFixtures.NewScene(200.0f, 100.0f);
		defer root.ReleaseRef();
		root.SetLayoutDirection(.RightToLeft);
		let bar = new ScrollBar();
		defer bar.ReleaseRef();
		bar.Orientation = .Horizontal;
		bar.Max = 100.0;
		bar.Page = 10.0;
		bar.Value = 50.0;
		bar.Size = .(200.0f, 12.0f);
		root.AddChild(bar);
		root.UpdateLayout();
		let at = bar.ConvertToRootSpace(.(195.0f, 6.0f));
		let d = root.EventDispatcher;
		d.InjectMouseDown(at, .Left);
		d.InjectMouseUp(at, .Left);
		Test.Assert(bar.Value < 50.0); // the right end is its start
	}

	[Test]
	public static void AMenuItemsCheckLabelAndShortcutAndASubmenusArrow()
	{
		CheckMirrored(scope () =>
			{
				let item = new MenuItem();
				item.Checkable = true;
				item.Checked = true;
				item.Shortcut = "Ctrl+S";
				return item;
			}, .(200.0f, 24.0f));
		CheckMirrored(scope () => new MenuSubItem(), .(200.0f, 24.0f));
	}

	[Test]
	public static void AComboBoxsArrowAtItsInlineEnd()
	{
		CheckMirrored(scope () => new ComboBox(), .(160.0f, 24.0f));
	}

	[Test]
	public static void AWindowsGripIsAtItsBottomLeftInRightToLeftAndPullingItMovesTheLeftEdge()
	{
		let root = SceneFixtures.NewScene(800.0f, 600.0f);
		defer root.ReleaseRef();
		root.SetLayoutDirection(.RightToLeft);
		let window = new Window();
		defer window.ReleaseRef();
		window.Position = .(300.0f, 100.0f);
		window.Size = .(300.0f, 200.0f);
		root.AddChild(window);
		root.UpdateLayout();
		let at = window.ConvertToRootSpace(.(0.0f, 0.0f));
		let grip = window.ConvertToRootSpace(.(4.0f, 196.0f)); // in its bottom-left corner
		let d = root.EventDispatcher;
		d.InjectMouseDown(grip, .Left);
		d.InjectMouseMove(.(grip.X - 40.0f, grip.Y + 20.0f));
		d.InjectMouseUp(.(grip.X - 40.0f, grip.Y + 20.0f), .Left);
		root.UpdateLayout();
		Test.Assert(Near(window.Size.X, 340.0f));
		Test.Assert(Near(window.Size.Y, 220.0f));
		// The right edge stays where it was.
		Test.Assert(Near(window.ConvertToRootSpace(.(window.Size.X, 0.0f)).X, at.X + 300.0f));
	}
}
