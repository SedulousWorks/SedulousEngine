using System;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Image widget tests: object-fit and object-position place the picture as CSS places a replaced
/// element's (fill, contain, cover, none, scale-down), sized by one axis it keeps its aspect ratio,
/// and image-color tints it.
class ImageWidgetTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	/// A new Image `w` by `h` (unsized for 0 by 0) showing `drawable` (when given), held by the
	/// caller.
	private static Sedulous.GUI.Image NewImage(Drawable drawable, float w, float h)
	{
		let image = new Sedulous.GUI.Image();
		if ((w > 0.0f) || (h > 0.0f))
			image.Size = .(w, h);
		if (drawable != null)
			image.SetDrawable(drawable);
		return image;
	}

	[Test]
	public static void StretchFillsTheContentBox()
	{
		let img = WidgetFixtures.MakeImage();
		defer delete img;
		let drawable = new ImageDrawable(img);
		defer drawable.ReleaseRef();
		let w = NewImage(drawable, 100.0f, 100.0f);
		defer w.ReleaseRef();
		w.Fit = .Fill;

		let r = w.DrawnBounds;
		Test.Assert(Near(r.X, 0.0f));
		Test.Assert(Near(r.Y, 0.0f));
		Test.Assert(Near(r.Width, 100.0f));
		Test.Assert(Near(r.Height, 100.0f));
	}

	[Test]
	public static void ContainPreservesAspectInsideTheBoxCentered()
	{
		let img = WidgetFixtures.MakeImage(); // 4x2 -> aspect 2:1
		defer delete img;
		let drawable = new ImageDrawable(img);
		defer drawable.ReleaseRef();
		let w = NewImage(drawable, 100.0f, 100.0f);
		defer w.ReleaseRef();
		w.Fit = .Contain; // scale = min(100/4, 100/2) = 25 -> 100x50

		let r = w.DrawnBounds;
		Test.Assert(Near(r.Width, 100.0f));
		Test.Assert(Near(r.Height, 50.0f));
		Test.Assert(Near(r.X, 0.0f));
		Test.Assert(Near(r.Y, 25.0f)); // centered vertically
	}

	[Test]
	public static void CoverCoversTheBoxCenteredOverflowNegative()
	{
		let img = WidgetFixtures.MakeImage(); // 4x2
		defer delete img;
		let drawable = new ImageDrawable(img);
		defer drawable.ReleaseRef();
		let w = NewImage(drawable, 100.0f, 100.0f);
		defer w.ReleaseRef();
		w.Fit = .Cover; // scale = max(25, 50) = 50 -> 200x100

		let r = w.DrawnBounds;
		Test.Assert(Near(r.Width, 200.0f));
		Test.Assert(Near(r.Height, 100.0f));
		Test.Assert(Near(r.X, -50.0f)); // centered -> overflows horizontally
		Test.Assert(Near(r.Y, 0.0f));
	}

	[Test]
	public static void NoneUsesItsNaturalSizeCentredOrWhereObjectPositionPutsIt()
	{
		let img = WidgetFixtures.MakeImage(); // 4x2
		defer delete img;
		let drawable = new ImageDrawable(img);
		defer drawable.ReleaseRef();
		let w = NewImage(drawable, 100.0f, 100.0f);
		defer w.ReleaseRef();

		w.Fit = .None; // natural, centred
		var r = w.DrawnBounds;
		Test.Assert(Near(r.Width, 4.0f));
		Test.Assert(Near(r.Height, 2.0f));
		Test.Assert(Near(r.X, 48.0f)); // (100-4)/2
		Test.Assert(Near(r.Y, 49.0f)); // (100-2)/2

		w.ObjectPositionName = "left top";
		r = w.DrawnBounds;
		Test.Assert(Near(r.X, 0.0f));
		Test.Assert(Near(r.Y, 0.0f));
		Test.Assert(Near(r.Width, 4.0f));
		Test.Assert(Near(r.Height, 2.0f));
	}

	[Test]
	public static void NoDrawableFallsBackToTheContentBoxAndDrawsNothing()
	{
		let w = NewImage(null, 60.0f, 40.0f);
		defer w.ReleaseRef();
		w.Fit = .Contain;

		let r = w.DrawnBounds; // no intrinsic -> the box
		Test.Assert(Near(r.Width, 60.0f));
		Test.Assert(Near(r.Height, 40.0f));
		Test.Assert(!w.IntrinsicSize.HasValue);

		Test.Assert(WidgetFixtures.DrawnVertices(w) == 0); // nothing drawn
	}

	[Test]
	public static void ObjectPositionPlacesItByKeywordPercentageOrPixelsScaleDownNeverEnlarges()
	{
		let img = WidgetFixtures.MakeImage(); // 4x2
		defer delete img;
		let drawable = new ImageDrawable(img);
		defer drawable.ReleaseRef();
		let w = NewImage(drawable, 100.0f, 100.0f);
		defer w.ReleaseRef();
		w.Fit = .Contain; // 100x50

		w.ObjectPositionName = "bottom";
		Test.Assert(Near(w.DrawnBounds.Y, 50.0f));
		Test.Assert(Near(w.DrawnBounds.X, 0.0f));
		w.ObjectPositionName = "0% 25%";
		Test.Assert(Near(w.DrawnBounds.Y, 12.5f));
		w.ObjectPositionName = "10px 4px";
		Test.Assert(Near(w.DrawnBounds.X, 10.0f));
		Test.Assert(Near(w.DrawnBounds.Y, 4.0f));

		w.ObjectPositionName = "center";
		w.FitName = "scale-down"; // 4x2 fits: its own size
		Test.Assert(w.Fit == .ScaleDown);
		Test.Assert(Near(w.DrawnBounds.Width, 4.0f));
		w.Size = .(2.0f, 2.0f); // too small: contained
		Test.Assert(Near(w.DrawnBounds.Width, 2.0f));
		Test.Assert(Near(w.DrawnBounds.Height, 1.0f));
	}

	[Test]
	public static void SizedByOneAxisItKeepsItsPicturesAspectRatioOnTheOther()
	{
		let img = WidgetFixtures.MakeImage(); // 2:1
		defer delete img;
		let drawable = new ImageDrawable(img);
		defer drawable.ReleaseRef();
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		let wide = NewImage(drawable, 0.0f, 0.0f);
		defer wide.ReleaseRef();
		wide.EditLayoutStyle(scope (s) => { s.Width = LayoutLength.Px(120.0f); });
		root.AddChild(wide);
		let tall = NewImage(drawable, 0.0f, 0.0f);
		defer tall.ReleaseRef();
		tall.EditLayoutStyle(scope (s) => { s.Height = LayoutLength.Px(30.0f); });
		root.AddChild(tall);
		let natural = NewImage(drawable, 0.0f, 0.0f);
		defer natural.ReleaseRef();
		root.AddChild(natural);
		root.UpdateLayout();
		Test.Assert(Near(wide.Size.Y, 60.0f));
		Test.Assert(Near(tall.Size.X, 60.0f));
		Test.Assert(Near(natural.Size.X, 4.0f));
	}

	[Test]
	public static void ImageColorDrawsItTintedWhiteDrawsItAsItIs()
	{
		let probe = new CountingDrawable();
		defer probe.ReleaseRef();
		let w = NewImage(probe, 20.0f, 20.0f);
		defer w.ReleaseRef();
		let canvas = scope VGContext();
		let dc = scope DrawContext(canvas);
		w.Draw(dc);
		Test.Assert(probe.Plain == 1);
		Test.Assert(probe.Tinted == 0);
		w.ImageColor = Color.Red;
		w.Draw(dc);
		Test.Assert(probe.Tinted == 1);
		Test.Assert(probe.Tint == Color.Red);
	}

	[Test]
	public static void SrcLoadsThroughTheGUIsResourcesWhenFirstNeededMarkupAndSheetsSetThemAll()
	{
		let resources = scope OnePicture();
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		root.Context.ResourceProvider = resources;
		let w = new Sedulous.GUI.Image();
		defer w.ReleaseRef();
		w.Source = "pic.png";
		Test.Assert(resources.Loads == 0); // not yet in a GUI
		root.AddChild(w);
		root.UpdateLayout();
		Test.Assert(resources.Loads == 1);
		Test.Assert(Near(w.Size.X, 4.0f));
		root.UpdateLayout();
		Test.Assert(resources.Loads == 1); // once

		let m = MarkupFixtures.Load("<Image src=\"pic.png\" object-fit=\"cover\" object-position=\"right top\" image-color=\"#ff000080\"/>");
		Test.Assert(m != null);
		defer m.ReleaseRef();
		let img = m as Sedulous.GUI.Image;
		Test.Assert(img != null);
		Test.Assert(img.Source == "pic.png");
		Test.Assert(img.Fit == .Cover);
		Test.Assert(img.ObjectPositionName == "100% 0%");
		Test.Assert(Near(img.ImageColor.A, 128.0f / 255.0f));
	}

	/// A host's pictures load in their own time (a texture a game names, still loading): an image
	/// that got nothing asks again as it is laid out next, and shows the picture once there is one.
	[Test]
	public static void APictureNotThereYetIsAskedForAgainUntilItComes()
	{
		let resources = scope OnePicture();
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		root.Context.ResourceProvider = resources;
		let w = new Sedulous.GUI.Image();
		defer w.ReleaseRef();
		w.Source = "later.png"; // the provider has none yet
		root.AddChild(w);
		root.UpdateLayout();
		let first = resources.Loads;
		Test.Assert(first >= 1);
		Test.Assert(Near(w.Size.X, 0.0f));
		w.RequestLayout(); // as the host does when a picture arrives
		root.UpdateLayout();
		Test.Assert(resources.Loads > first, "asked again");
		w.Source = "pic.png";
		root.UpdateLayout();
		Test.Assert(Near(w.Size.X, 4.0f));
		let loaded = resources.Loads;
		w.RequestLayout();
		root.UpdateLayout();
		Test.Assert(resources.Loads == loaded, "once it has it, never again");

		// A box its style sizes (a HUD's portrait) takes the picture as the host lays out again
		// when it arrives, though its size does not change.
		let boxed = new Sedulous.GUI.Image();
		defer boxed.ReleaseRef();
		boxed.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(72.0f);
				s.Height = LayoutLength.Px(72.0f);
			});
		boxed.Source = "later.png";
		root.AddChild(boxed);
		root.UpdateLayout();
		Test.Assert(boxed.Drawable == null);
		resources.LateReady = true;
		root.RequestLayoutTree(); // the host, as a texture arrives
		root.UpdateLayout();
		Test.Assert(boxed.Drawable != null);
		Test.Assert(boxed.NeedsRedraw, "drawn again with it");
	}
}
