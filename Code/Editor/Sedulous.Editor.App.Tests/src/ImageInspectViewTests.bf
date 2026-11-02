using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.GUI;
using Sedulous.Image.IO;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The image pages' picture (ImageInspectView): it fits its view, centred, until zoomed or panned;
/// the wheel zooms about the pointer, a drag pans, Fit and 1:1; a picture of another size fits
/// again; a pixel read and said; a channel shown on its own, the picture's pixels untouched; a new
/// picture a new image, so the renderer draws it. The import window's preview of a picture file
/// (ImageFilePreview) shows it with the facts its header gives.
class ImageInspectViewTests
{
	/// A 40x20 picture: every pixel (10, 20, 30, 200) but (5, 2), which is (255, 128, 0, 64).
	static Sedulous.Image.Image Picture()
	{
		let picture = new Sedulous.Image.Image(40, 20, .RGBA8);
		let data = picture.PixelData;
		for (int i = 0; i < data.Length; i += 4)
		{
			data[i] = 10;
			data[i + 1] = 20;
			data[i + 2] = 30;
			data[i + 3] = 200;
		}
		let at = (2 * 40 + 5) * 4;
		data[at] = 255;
		data[at + 1] = 128;
		data[at + 2] = 0;
		data[at + 3] = 64;
		return picture;
	}

	/// The view at 400x400 in a root.
	class Bed
	{
		public SceneRoot Root;
		public ImageInspectView View;

		public this()
		{
			let context = new GUIContext();
			Root = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Root.Size = .(800.0f, 600.0f);
			Root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
			View = new ImageInspectView();
			View.EditLayoutStyle(scope (s) =>
				{
					s.Width = LayoutLength.Px(400.0f);
					s.Height = LayoutLength.Px(400.0f);
				});
			Root.AddChild(View);
			View.SetImage(Picture());
			Root.UpdateLayout();
		}

		public ~this()
		{
			View.ReleaseRef();
			Root.ReleaseRef();
		}
	}

	static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	[Test]
	public static void ItFitsItsViewCentredUntilZoomedOrPanned()
	{
		let bed = scope Bed();
		let view = bed.View;
		Test.Assert(view.Fitting);
		Test.Assert(Near(view.Zoom, 10.0f), "40 wide in 400");
		Test.Assert(Near(view.Origin.X, 0.0f));
		Test.Assert(Near(view.Origin.Y, 100.0f), "200 high, centred in 400");

		// The wheel zooms about the point under it: the pixel there stays there.
		Test.Assert(view.PixelAt(.(55.0f, 125.0f), let x, let y));
		Test.Assert((x == 5) && (y == 2));
		view.WheelAt(.(55.0f, 125.0f), 2.0f);
		Test.Assert(!view.Fitting);
		Test.Assert(Near(view.Zoom, 10.0f * 1.25f * 1.25f));
		Test.Assert(view.PixelAt(.(55.0f, 125.0f), let x2, let y2));
		Test.Assert((x2 == 5) && (y2 == 2));

		// A drag pans; Fit puts it back; 1:1 is one pixel to one, about the middle.
		let before = view.Origin;
		view.DragBy(.(10.0f, 10.0f), .(40.0f, 0.0f));
		Test.Assert(Near(view.Origin.X, before.X + 30.0f));
		Test.Assert(Near(view.Origin.Y, before.Y - 10.0f));
		view.Fit();
		Test.Assert(view.Fitting);
		Test.Assert(Near(view.Zoom, 10.0f));
		view.ActualSize();
		Test.Assert(Near(view.Zoom, 1.0f));
		Test.Assert(Near(view.Origin.X, 180.0f));
		Test.Assert(!view.PixelAt(.(10.0f, 10.0f), ?, ?), "off the picture");

		// A picture of another size fits again.
		view.SetImage(new Sedulous.Image.Image(8, 8, .RGBA8));
		Test.Assert(view.Fitting);
		Test.Assert(Near(view.Zoom, 50.0f));
	}

	[Test]
	public static void APixelReadAndSaidAChannelShownOnItsOwn()
	{
		let bed = scope Bed();
		let view = bed.View;
		Test.Assert(view.ValueAt(5, 2, var pixel));
		Test.Assert((pixel.R == 255) && (pixel.G == 128) && (pixel.B == 0) && (pixel.A == 64));
		Test.Assert(!view.ValueAt(40, 0, ?));
		Test.Assert(ImagePreview.DescribePixel(5, 2, &pixel, .. scope .()) == "x 5  y 2  ·  R 255 G 128 B 0 A 64");
		Test.Assert(ImagePreview.DescribePixel(-1, -1, null, .. scope .()).IsEmpty);

		// A channel is the picture's own pixels, untouched; what is drawn is the channel as grey.
		view.SetChannel(.Green);
		Test.Assert(view.Channel == .Green);
		Test.Assert(view.ValueAt(5, 2, out pixel));
		Test.Assert((pixel.G == 128) && (pixel.R == 255));
	}

	/// A new picture of the same size is a new image, so the renderer draws it and not the last
	/// one's texture (its cache keys on the image's identity): a font rebaked at the same size.
	[Test]
	public static void ANewPictureOfTheSameSizeIsANewImage()
	{
		let bed = scope Bed();
		let view = bed.View;
		let first = view.Pixels.InstanceId;
		view.SetImage(Picture());
		Test.Assert(view.Pixels.InstanceId != first);
		Test.Assert(view.Fitting, "the same size: kept as it was");
	}

	/// The import window's preview of a picture file: read off the main thread, saying so, then
	/// shown with its size, its channels as the file stores them and, when it has alpha, whether that
	/// is used; one gone before its read comes back is dropped; a file that does not decode shows
	/// why, and no facts.
	[Test]
	public static void APictureFileIsReadOffTheMainThreadThenShownWithItsSizeItsChannelsAsStoredAndWhetherItsAlphaIsUsed()
	{
		let path = scope $"scratch_image_file_preview.png";
		defer DeleteFile(path);
		let picture = Picture();
		defer delete picture;
		Test.Assert(ImageIO.SaveImage(picture, path, .PNG) case .Ok);
		let reader = scope ImportPreviewReader();
		{
			let preview = scope ImageFilePreview(path, reader);
			int changed = 0;
			preview.SetOnChanged(new [&changed] () => { changed++; });
			// Reading: no picture and no facts until the read is handed back.
			Test.Assert(!preview.Picture.View.HasImage);
			Test.Assert(preview.Facts.IsEmpty);
			reader.Finish();
			Test.Assert(changed == 1);
			Test.Assert(preview.Picture.View.HasImage);
			let facts = preview.Facts;
			Test.Assert(facts.Length == 3);
			Test.Assert(facts[0] == "40 × 20");
			Test.Assert(facts[1] == "RGBA, 8-bit");
			Test.Assert(facts[2] == "Uses alpha");
		}

		// A preview gone before its read comes back: the result is dropped.
		{
			let gone = scope ImageFilePreview(path, reader);
			Test.Assert(!gone.Picture.View.HasImage);
		}
		reader.Finish();
		Test.Assert(reader.InFlight == 0);

		// One grey channel: no alpha to speak of.
		let grey = scope $"scratch_image_file_preview_grey.png";
		defer DeleteFile(grey);
		uint8[4] values = .(0, 80, 160, 240);
		let narrow = scope Sedulous.Image.Image(2, 2, .R8, .(&values[0], 4));
		Test.Assert(ImageIO.SaveImage(narrow, grey, .PNG) case .Ok);
		{
			let preview = scope ImageFilePreview(grey, reader);
			reader.Finish();
			Test.Assert(preview.Picture.View.HasImage);
			Test.Assert((preview.Facts.Length == 2) && (preview.Facts[0] == "2 × 2") && (preview.Facts[1] == "Grey, 8-bit"));
		}

		let missing = scope ImageFilePreview("scratch_image_file_preview_missing.png", reader);
		reader.Finish();
		Test.Assert(!missing.Picture.View.HasImage);
		Test.Assert(missing.Facts.IsEmpty);
		Test.Assert(missing.View != null);
	}
}
