using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Shell;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.Fonts;
using Sedulous.Fonts.TrueType;

namespace Sedulous.Editor.App;

/// What the editor shows from launch until its main window is ready. Startup runs on the main
/// thread with nothing drawn (the graphics device, the shader compiles, the fonts, the project
/// and its pages), and the editor's own interface cannot draw until its shaders exist, so the
/// splash is drawn on the CPU into a software window (WindowSettings.SoftwareSurface,
/// IWindow.PresentPixels), opened before there is a graphics device: the SedulousEngine logo, a
/// line saying what startup is doing, a progress bar and the version. Each Step redraws it and
/// pumps the window events so the window stays responsive. Closed when the main window shows.
/// It draws at the display's scale (a 175% display gets a splash 1.75 times the size, its text
/// rasterized at that size and its logo from a picture big enough), so it is sharp and not small.
///
/// The drawing is a plain RGBA buffer (Pixels), so a test checks it without a window.
class EditorSplash
{
	public const uint32 cWidth = 560;
	public const uint32 cHeight = 300;

	private static readonly Color cBackground = .(0x1F / 255.0f, 0x22 / 255.0f, 0x27 / 255.0f, 1.0f);
	private static readonly Color cBorder = .(0x3A / 255.0f, 0x3D / 255.0f, 0x42 / 255.0f, 1.0f);
	private static readonly Color cTrack = .(0x2E / 255.0f, 0x32 / 255.0f, 0x38 / 255.0f, 1.0f);
	private static readonly Color cAccent = .(0xF5 / 255.0f, 0x8F / 255.0f, 0x42 / 255.0f, 1.0f);
	private static readonly Color cText = .(0.78f, 0.79f, 0.81f, 1.0f);
	private static readonly Color cDim = .(0.50f, 0.51f, 0.53f, 1.0f);
	// The layout at 100%; Scaled takes each to the splash's scale.
	private const int32 cMargin = 40;
	private const int32 cLogoY = 84;
	private const int32 cStatusBaseline = 236;
	private const int32 cBarY = 254;
	private const int32 cBarHeight = 4;
	private const int32 cVersionFromBottom = 18;
	private const float cFontSize = 15.0f;
	private const uint32 cLogoWidth = 420; // the 1x picture's width
	private const uint32 cLogoHeight = 95;

	/// Borrowed; either may be null (a test draws without showing).
	private IShell mShell;
	private IWindow mWindow;
	private List<uint8> mLogo = new .() ~ delete _;
	private uint32 mLogoWidth = 0;
	private uint32 mLogoHeight = 0;
	private TrueTypeFont mFont = null ~ delete _;
	private String mVersion = new .() ~ delete _;
	private String mStatus = new .() ~ delete _;
	private float mProgress = 0.0f;
	private float mScale = 1.0f;
	private uint32 mWidth = cWidth;
	private uint32 mHeight = cHeight;
	private List<uint8> mPixels = new .() ~ delete _;

	/// `scale` is the display's (1 at 100%): the splash is cWidth x cHeight times it.
	/// `logoRgba` is the logo at the size to draw (LoadLogo at `scale`, tightly packed RGBA),
	/// copied; `fontData` a TrueType face for the text, TAKEN. Either may be empty: the splash
	/// draws without it.
	public this(IShell shell, IWindow window, Span<uint8> logoRgba, uint32 logoWidth, uint32 logoHeight, List<uint8> fontData, StringView version, float scale)
	{
		mShell = shell;
		mWindow = window;
		mVersion.Set(version);
		mScale = Math.Max(scale, 1.0f);
		mWidth = (uint32)((float)cWidth * mScale + 0.5f);
		mHeight = (uint32)((float)cHeight * mScale + 0.5f);
		if ((logoWidth > 0) && (logoHeight > 0) && (logoRgba.Length >= (int)logoWidth * (int)logoHeight * 4))
		{
			mLogo.AddRange(logoRgba.Slice(0, (int)logoWidth * (int)logoHeight * 4));
			mLogoWidth = logoWidth;
			mLogoHeight = logoHeight;
		}
		if ((fontData != null) && !fontData.IsEmpty)
		{
			mFont = new TrueTypeFont();
			if (mFont.Initialize(fontData, cFontSize * mScale) != .Success)
				DeleteAndNullify!(mFont);
		}
		else
			delete fontData;
		mPixels.Count = (int)mWidth * (int)mHeight * 4;
		Render();
	}

	/// The drawn image, Width x Height RGBA.
	public Span<uint8> Pixels => mPixels;
	/// The drawn image's size: cWidth x cHeight at the scale, in pixels.
	public uint32 Width => mWidth;
	public uint32 Height => mHeight;
	public float Scale => mScale;
	public StringView Status => mStatus;
	public float Progress => mProgress;

	/// Says what startup is doing, `progress` in 0 to 1, and shows it.
	public void Step(StringView status, float progress)
	{
		mStatus.Set(status);
		mProgress = Math.Clamp(progress, 0.0f, 1.0f);
		Render();
		if (mWindow != null)
			mWindow.PresentPixels(Pixels, mWidth, mHeight);
		// Startup holds the main thread: pump the window events here so the desktop does not
		// take the editor for hung while it starts.
		if (mShell != null)
			mShell.ProcessEvents();
	}

	/// Closes the window (the main window is up): the shell frees it at its next flush.
	public void Close()
	{
		if (mWindow == null)
			return;
		if ((mShell != null) && (mShell.WindowManager != null))
			mShell.WindowManager.DestroyWindow(mWindow);
		else
			mWindow.Close();
		mWindow = null;
	}

	/// Draws the current state into Pixels (Step does, then shows it).
	public void Render()
	{
		let w = (int32)mWidth;
		let h = (int32)mHeight;
		let border = Math.Max(1, Scaled(1));
		Fill(0, 0, w, h, cBorder);
		Fill(border, border, w - 2 * border, h - 2 * border, cBackground);

		// The logo, centred in the upper part.
		if (!mLogo.IsEmpty)
		{
			let x0 = (w - (int32)mLogoWidth) / 2;
			let y0 = Scaled(cLogoY);
			for (uint32 y < mLogoHeight)
			{
				for (uint32 x < mLogoWidth)
				{
					let p = &mLogo[((int)y * (int)mLogoWidth + (int)x) * 4];
					if (p[3] != 0)
						Blend(x0 + (int32)x, y0 + (int32)y, Color(p[0] / 255.0f, p[1] / 255.0f, p[2] / 255.0f, 1.0f), p[3] / 255.0f);
				}
			}
		}

		// What startup is doing, the bar under it, and the version.
		let margin = Scaled(cMargin);
		let barY = Scaled(cBarY);
		let barHeight = Math.Max(1, Scaled(cBarHeight));
		DrawText(mStatus, margin, Scaled(cStatusBaseline), cText);
		let barWidth = w - 2 * margin;
		Fill(margin, barY, barWidth, barHeight, cTrack);
		Fill(margin, barY, (int32)((float)barWidth * mProgress + 0.5f), barHeight, cAccent);
		DrawText(mVersion, w - margin, h - Scaled(cVersionFromBottom), cDim, true);
	}

	/// A length of the 100% layout at the splash's scale.
	private int32 Scaled(int32 length) => (int32)((float)length * mScale + 0.5f);

	private void Fill(int32 x, int32 y, int32 w, int32 h, Color color)
	{
		for (var row = Math.Max(0, y); row < Math.Min((int32)mHeight, y + h); row++)
		{
			for (var col = Math.Max(0, x); col < Math.Min((int32)mWidth, x + w); col++)
			{
				let p = &mPixels[((int)row * (int)mWidth + (int)col) * 4];
				p[0] = (uint8)(color.R * 255.0f + 0.5f);
				p[1] = (uint8)(color.G * 255.0f + 0.5f);
				p[2] = (uint8)(color.B * 255.0f + 0.5f);
				p[3] = 255;
			}
		}
	}

	private void Blend(int32 x, int32 y, Color color, float alpha)
	{
		if ((x < 0) || (y < 0) || (x >= (int32)mWidth) || (y >= (int32)mHeight))
			return;
		let p = &mPixels[((int)y * (int)mWidth + (int)x) * 4];
		p[0] = Mix(p[0], color.R, alpha);
		p[1] = Mix(p[1], color.G, alpha);
		p[2] = Mix(p[2], color.B, alpha);
		p[3] = 255;
	}

	private static uint8 Mix(uint8 under, float over, float alpha) => (uint8)((float)under * (1.0f - alpha) + over * 255.0f * alpha + 0.5f);

	private void DrawText(StringView text, int32 x, int32 baseline, Color color, bool alignRight = false)
	{
		if ((mFont == null) || text.IsEmpty)
			return;
		var pen = (float)(alignRight ? x - (int32)(mFont.MeasureString(text) + 0.5f) : x);
		let coverage = scope List<uint8>();
		int32 previous = 0;
		for (let c in text.DecodedChars)
		{
			let code = (int32)c;
			if (previous != 0)
				pen += mFont.GetKerning(previous, code);
			if (mFont.RasterizeGlyph(code, coverage, let gw, let gh, let gx, let gy))
			{
				let left = (int32)(pen + 0.5f) + gx;
				for (int32 row < gh)
				{
					for (int32 col < gw)
					{
						let a = coverage[row * gw + col];
						if (a != 0)
							Blend(left + col, baseline + gy + row, color, a / 255.0f);
					}
				}
			}
			pen += mFont.GetGlyphInfo(code).AdvanceWidth;
			previous = code;
		}
	}

	/// The SedulousEngine logo (mark and wordmark, for a dark background), relative to the
	/// data root: what a page's markup shows (`<Image src="...">`, through the editor's
	/// resources). Its aspect is cEditorLogoAspect.
	public const String cEditorLogoPath = "Branding/sedulous-logo.svg";

	/// The aspect of the logo at cEditorLogoPath (width over height).
	public const float cEditorLogoAspect = 885.0f / 200.0f;

	/// Opens the splash over a new software window of `shell` (after the main window: the
	/// shell's first window is its main one), with the logo from <dataRoot>/Branding
	/// and the text in the font at `fontPath`, else `embeddedFont` (the face built into the
	/// editor). Null when the window cannot open: the editor then starts without one.
	public static EditorSplash Open(IShell shell, StringView dataRoot, StringView fontPath, Span<uint8> embeddedFont, StringView version)
	{
		let windows = shell.WindowManager;
		if (windows == null)
			return null;
		var settings = WindowSettings();
		settings.Title = "SedulousEngine";
		settings.Width = cWidth;
		settings.Height = cHeight;
		settings.Resizable = false;
		settings.Borderless = true;
		settings.SoftwareSurface = true;
		if (!(windows.CreateWindow(settings) case .Ok(let window)) || (window == null))
			return null;
		ApplyWindowIcon(window, dataRoot);

		// The display's scale (1.75 at 175%): the splash draws at it, and the window takes the size
		// that shows it pixel for pixel. A window already counted in units larger than its pixels
		// (macOS, Wayland) grows by the rest of the scale only; one that cannot say draws at 100%.
		let scale = Math.Max(window.ContentScale, 1.0f);
		if ((scale > 1.0f) && (window.Width > 0))
		{
			let density = (float)window.PixelWidth / (float)window.Width;
			let units = scale / Math.Max(density, 1.0f);
			if (units > 1.0f)
			{
				let width = (uint32)((float)cWidth * units + 0.5f);
				let height = (uint32)((float)cHeight * units + 0.5f);
				// Grown about its middle, so it stays where the shell centred it.
				window.SetPosition(window.X - (int32)(width - window.Width) / 2, window.Y - (int32)(height - window.Height) / 2);
				window.SetSize(width, height);
			}
		}

		let logo = scope Image();
		let hasLogo = LoadLogo(dataRoot, scale, logo);
		let font = new List<uint8>();
		if (System.IO.File.ReadAll(scope String(fontPath), font) case .Err)
		{
			font.Clear();
			font.AddRange(embeddedFont);
		}
		return new EditorSplash(shell, window, hasLogo ? logo.PixelData : Span<uint8>(), hasLogo ? logo.Width : 0, hasLogo ? logo.Height : 0, font, version, scale);
	}

	/// The splash's logo at `scale` (1 at 100%), from <dataRoot>/Branding: the 1x picture
	/// (sedulous-logo-splash.png, 420 x 95) at 100%, else the 2x one (sedulous-logo-splash@2x.png,
	/// rendered from the SVG by Code/Tools/logo-splash.py) resampled to the size the scale asks
	/// for, into `outImage`. False when the picture does not load.
	public static bool LoadLogo(StringView dataRoot, float scale, Image outImage)
	{
		let s = Math.Max(scale, 1.0f);
		let large = s > 1.0f;
		let picture = scope Image();
		let path = PathJoin(dataRoot, large ? "Branding/sedulous-logo-splash@2x.png" : "Branding/sedulous-logo-splash.png", .. scope .());
		if (!(ImageIO.LoadImage(path, picture) case .Ok) || (picture.Format != .RGBA8))
			return false;
		let width = (uint32)((float)cLogoWidth * s + 0.5f);
		let height = (uint32)((float)cLogoHeight * s + 0.5f);
		if ((picture.Width == width) && (picture.Height == height))
			outImage.ReplaceData(picture.Width, picture.Height, .RGBA8, picture.PixelData);
		else
			Resample(picture.PixelData, picture.Width, picture.Height, width, height, outImage);
		return true;
	}

	/// `src` (sw x sh straight RGBA) resampled to dw x dh into `outImage`: bilinear, in
	/// premultiplied alpha so the logo's edges do not take the colour of its transparent pixels.
	/// From the 2x picture to anything between 1x and 2x, so no step skips a source pixel.
	private static void Resample(Span<uint8> src, uint32 sw, uint32 sh, uint32 dw, uint32 dh, Image outImage)
	{
		let output = scope List<uint8>();
		output.Count = (int)dw * (int)dh * 4;
		float Texel(int32 x, int32 y, int32 c)
		{
			let cx = Math.Clamp(x, 0, (int32)sw - 1);
			let cy = Math.Clamp(y, 0, (int32)sh - 1);
			let i = ((int)cy * (int)sw + (int)cx) * 4;
			let alpha = src[i + 3] / 255.0f;
			return (c == 3) ? alpha : (src[i + c] / 255.0f) * alpha;
		}
		for (uint32 y < dh)
		{
			let fy = ((float)y + 0.5f) * (float)sh / (float)dh - 0.5f;
			let y0 = (int32)Math.Floor(fy);
			let ty = fy - (float)y0;
			for (uint32 x < dw)
			{
				let fx = ((float)x + 0.5f) * (float)sw / (float)dw - 0.5f;
				let x0 = (int32)Math.Floor(fx);
				let tx = fx - (float)x0;
				float[4] value = default;
				for (int32 c < 4)
				{
					let top = Texel(x0, y0, c) * (1.0f - tx) + Texel(x0 + 1, y0, c) * tx;
					let bottom = Texel(x0, y0 + 1, c) * (1.0f - tx) + Texel(x0 + 1, y0 + 1, c) * tx;
					value[c] = top * (1.0f - ty) + bottom * ty;
				}
				let q = ((int)y * (int)dw + (int)x) * 4;
				let alpha = value[3];
				for (int32 c < 3)
					output[q + c] = (uint8)(Math.Clamp((alpha > 0.0f) ? value[c] / alpha : 0.0f, 0.0f, 1.0f) * 255.0f + 0.5f);
				output[q + 3] = (uint8)(Math.Clamp(alpha, 0.0f, 1.0f) * 255.0f + 0.5f);
			}
		}
		outImage.ReplaceData(dw, dh, .RGBA8, output);
	}

	/// The SedulousEngine icon on `window` (its title bar, the taskbar), from
	/// <dataRoot>/Branding/sedulous-icon-<size>.png: 32 px at the normal scale, the
	/// larger sizes for scaled displays. False when none of them loads.
	public static bool ApplyWindowIcon(IWindow window, StringView dataRoot)
	{
		uint32[4] sizes = .(32, 64, 128, 256); // the first at the normal scale
		let images = scope List<Image>();
		defer { ClearAndDeleteItems(images); }
		let icon = scope List<WindowIconImage>();
		for (let size in sizes)
		{
			let path = PathJoin(dataRoot, scope $"Branding/sedulous-icon-{size}.png", .. scope .());
			let image = new Image();
			if ((ImageIO.LoadImage(path, image) case .Ok) && (image.Format == .RGBA8) && (image.Width == size))
			{
				images.Add(image);
				icon.Add(.(image.PixelData.Ptr, image.Width, image.Height));
			}
			else
				delete image;
		}
		if (icon.IsEmpty)
			return false;
		window.SetIcon(icon);
		return true;
	}
}
