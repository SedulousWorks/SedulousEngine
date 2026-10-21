using System;
using System.Collections;
using System.IO;
using Sedulous.Core.IO;
using Sedulous.Shell;
using Sedulous.UI;

namespace Sedulous.Editor.App.Tests;

/// The splash the editor shows while it starts (drawn on the CPU: its logo, its status line
/// and its progress bar), the logo the Welcome page shows, and the window icon, all from the
/// repository's branding files.
class EditorSplashTests
{
	/// The repository's Data folder, found by the font the tests already walk up to.
	private static bool DataRoot(String outPath)
	{
		let font = scope String();
		if (!TestFont.FindPath(font))
			return false;
		// <Data>/Assets/fonts/roboto/Roboto-Regular.ttf: four levels up.
		outPath.Set(font);
		for (int i < 4)
		{
			let parent = PathParent(outPath, .. scope .());
			outPath.Set(parent);
		}
		return true;
	}

	private struct Pixel : this(uint8 R, uint8 G, uint8 B);

	private static Pixel At(EditorSplash splash, uint32 x, uint32 y)
	{
		let i = ((int)y * (int)EditorSplash.cWidth + (int)x) * 4;
		return .(splash.Pixels[i], splash.Pixels[i + 1], splash.Pixels[i + 2]);
	}

	/// A window that keeps the icon it is given.
	private class IconWindow : IWindow
	{
		public List<uint32> Sizes = new .() ~ delete _;

		public uint32 Id => 1;
		public uint32 Width => 100;
		public uint32 Height => 100;
		public int32 X => 0;
		public int32 Y => 0;
		public float ContentScale => 1.0f;
		public bool IsOpen => true;
		public bool IsMinimized => false;
		public NativeWindow Native => .();

		public void SetPosition(int32 x, int32 y) {}
		public void SetSize(uint32 width, uint32 height) {}
		public void Close() {}
		public void Raise() {}
		public void SetTitle(StringView title) {}
		public void StartTextInput(TextInputKind kind = .Text) {}
		public void StopTextInput() {}
		public bool IsTextInputActive => false;
		public TextInputKind ActiveTextInputKind => .Text;

		public void SetIcon(Span<WindowIconImage> images)
		{
			Sizes.Clear();
			for (let image in images)
			{
				Test.Assert(image.Rgba != null);
				Test.Assert(image.Width == image.Height);
				Sizes.Add(image.Width);
			}
		}
	}

	[Test]
	public static void TheLogoTheStatusLineAndTheProgressBarAreDrawnOnTheCpu()
	{
		let fontPath = scope String();
		Test.Assert(TestFont.FindPath(fontPath));
		let font = new List<uint8>();
		Test.Assert(File.ReadAll(fontPath, font) case .Ok);
		// A small stand-in logo: an opaque red block.
		let logo = scope List<uint8>();
		for (int i < 20 * 10)
			logo..Add(255)..Add(0)..Add(0)..Add(255);
		let splash = scope EditorSplash(null, null, logo, 20, 10, font, "Version 0.1.0");
		Test.Assert(splash.Pixels.Length == (int)EditorSplash.cWidth * (int)EditorSplash.cHeight * 4);
		let background = At(splash, EditorSplash.cWidth / 2, 20);

		// The logo, centred near the top.
		let logoPixel = At(splash, EditorSplash.cWidth / 2, 89);
		Test.Assert((logoPixel.R == 255) && (logoPixel.G == 0));

		splash.Step("Opening Level1", 0.5f);
		Test.Assert(splash.Status == "Opening Level1");
		Test.Assert(splash.Progress == 0.5f);
		// The bar: filled (the accent) up to half its width, the track after.
		const uint32 cBarY = 255;
		let filled = At(splash, 40 + 120, cBarY);
		let track = At(splash, 40 + 360, cBarY);
		Test.Assert((filled.R == 0xF5) && (filled.G == 0x8F));
		Test.Assert(track.R == 0x2E);
		// The status text drew something on its line (a lighter pixel than the background).
		var inked = false;
		for (uint32 x = 40; (x < 200) && !inked; x++)
		{
			for (uint32 y = 222; (y < 240) && !inked; y++)
				inked = At(splash, x, y).R > background.R + 40;
		}
		Test.Assert(inked);

		splash.Step("Ready", 2.0f); // clamped
		Test.Assert(splash.Progress == 1.0f);
		Test.Assert(At(splash, 40 + 470, cBarY).R == 0xF5);
	}

	[Test]
	public static void TheLogoAndTheWindowIconLoadFromTheBrandingFiles()
	{
		let data = scope String();
		Test.Assert(DataRoot(data));
		let logo = EditorSplash.LoadLogo(data);
		Test.Assert(logo != null);
		logo.ReleaseRef();
		Test.Assert(EditorSplash.LoadLogo("/nowhere") == null);

		let window = scope IconWindow();
		Test.Assert(EditorSplash.ApplyWindowIcon(window, data));
		Test.Assert(window.Sizes.Count == 4);
		Test.Assert(window.Sizes[0] == 32, "the normal scale's first");
		Test.Assert(window.Sizes[3] == 256);
		let none = scope IconWindow();
		Test.Assert(!EditorSplash.ApplyWindowIcon(none, "/nowhere"));
		Test.Assert(none.Sizes.IsEmpty);
	}
}
