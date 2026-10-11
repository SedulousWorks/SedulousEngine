using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Shell;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.Fonts;
using Sedulous.Fonts.TrueType;
using Sedulous.UI;

namespace Sedulous.Editor.App;

/// What the editor shows from launch until its main window is ready. Startup runs on the main
/// thread with nothing drawn (the graphics device, the shader compiles, the fonts, the project
/// and its pages), and the editor's own interface cannot draw until its shaders exist, so the
/// splash is drawn on the CPU into a software window (WindowSettings.SoftwareSurface,
/// IWindow.PresentPixels), opened before there is a graphics device: the SedulousEngine logo, a
/// line saying what startup is doing, a progress bar and the version. Each Step redraws it and
/// pumps the window events so the window stays responsive. Closed when the main window shows.
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
	private const int32 cMargin = 40;
	private const int32 cLogoY = 84;
	private const int32 cStatusBaseline = 236;
	private const int32 cBarY = 254;
	private const int32 cBarHeight = 4;

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
	private List<uint8> mPixels = new .() ~ delete _;

	/// `logoRgba` is the logo at the splash's size (Assets/branding/sedulous-logo-splash.png,
	/// tightly packed RGBA), copied; `fontData` a TrueType face for the text, TAKEN. Either may
	/// be empty: the splash draws without it.
	public this(IShell shell, IWindow window, Span<uint8> logoRgba, uint32 logoWidth, uint32 logoHeight, List<uint8> fontData, StringView version)
	{
		mShell = shell;
		mWindow = window;
		mVersion.Set(version);
		if ((logoWidth > 0) && (logoHeight > 0) && (logoRgba.Length >= (int)logoWidth * (int)logoHeight * 4))
		{
			mLogo.AddRange(logoRgba.Slice(0, (int)logoWidth * (int)logoHeight * 4));
			mLogoWidth = logoWidth;
			mLogoHeight = logoHeight;
		}
		if ((fontData != null) && !fontData.IsEmpty)
		{
			mFont = new TrueTypeFont();
			if (mFont.Initialize(fontData, 15.0f) != .Success)
				DeleteAndNullify!(mFont);
		}
		else
			delete fontData;
		mPixels.Count = (int)cWidth * (int)cHeight * 4;
		Render();
	}

	/// The drawn image, cWidth x cHeight RGBA.
	public Span<uint8> Pixels => mPixels;
	public StringView Status => mStatus;
	public float Progress => mProgress;

	/// Says what startup is doing, `progress` in 0 to 1, and shows it.
	public void Step(StringView status, float progress)
	{
		mStatus.Set(status);
		mProgress = Math.Clamp(progress, 0.0f, 1.0f);
		Render();
		if (mWindow != null)
			mWindow.PresentPixels(Pixels, cWidth, cHeight);
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
		let w = (int32)cWidth;
		let h = (int32)cHeight;
		Fill(0, 0, w, h, cBorder);
		Fill(1, 1, w - 2, h - 2, cBackground);

		// The logo, centred in the upper part.
		if (!mLogo.IsEmpty)
		{
			let x0 = (w - (int32)mLogoWidth) / 2;
			for (uint32 y < mLogoHeight)
			{
				for (uint32 x < mLogoWidth)
				{
					let p = &mLogo[((int)y * (int)mLogoWidth + (int)x) * 4];
					if (p[3] != 0)
						Blend(x0 + (int32)x, cLogoY + (int32)y, Color(p[0] / 255.0f, p[1] / 255.0f, p[2] / 255.0f, 1.0f), p[3] / 255.0f);
				}
			}
		}

		// What startup is doing, the bar under it, and the version.
		DrawText(mStatus, cMargin, cStatusBaseline, cText);
		let barWidth = w - 2 * cMargin;
		Fill(cMargin, cBarY, barWidth, cBarHeight, cTrack);
		Fill(cMargin, cBarY, (int32)((float)barWidth * mProgress + 0.5f), cBarHeight, cAccent);
		DrawText(mVersion, w - cMargin, h - 18, cDim, true);
	}

	private void Fill(int32 x, int32 y, int32 w, int32 h, Color color)
	{
		for (var row = Math.Max(0, y); row < Math.Min((int32)cHeight, y + h); row++)
		{
			for (var col = Math.Max(0, x); col < Math.Min((int32)cWidth, x + w); col++)
			{
				let p = &mPixels[((int)row * (int)cWidth + (int)col) * 4];
				p[0] = (uint8)(color.R * 255.0f + 0.5f);
				p[1] = (uint8)(color.G * 255.0f + 0.5f);
				p[2] = (uint8)(color.B * 255.0f + 0.5f);
				p[3] = 255;
			}
		}
	}

	private void Blend(int32 x, int32 y, Color color, float alpha)
	{
		if ((x < 0) || (y < 0) || (x >= (int32)cWidth) || (y >= (int32)cHeight))
			return;
		let p = &mPixels[((int)y * (int)cWidth + (int)x) * 4];
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

	/// The aspect of the logo LoadEditorLogo gives (width over height).
	public const float cEditorLogoAspect = 885.0f / 200.0f;

	/// Opens the splash over a new software window of `shell` (after the main window: the
	/// shell's first window is its main one), with the logo from <dataRoot>/Assets/branding
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

		let logo = scope Image();
		let logoPath = PathJoin(dataRoot, "Assets/branding/sedulous-logo-splash.png", .. scope .());
		let hasLogo = (ImageIO.LoadImage(logoPath, logo) case .Ok) && (logo.Format == .RGBA8);
		let font = new List<uint8>();
		if (System.IO.File.ReadAll(scope String(fontPath), font) case .Err)
		{
			font.Clear();
			font.AddRange(embeddedFont);
		}
		return new EditorSplash(shell, window, hasLogo ? logo.PixelData : Span<uint8>(), hasLogo ? logo.Width : 0, hasLogo ? logo.Height : 0, font, version);
	}

	/// The SedulousEngine logo (mark and wordmark, for a dark background) as a drawable, from
	/// <dataRoot>/Assets/branding/sedulous-logo.svg, the caller's reference; null when it does
	/// not load. Its aspect is cEditorLogoAspect.
	public static SVGDrawable LoadLogo(StringView dataRoot)
	{
		let svg = scope String();
		if (System.IO.File.ReadAllText(PathJoin(dataRoot, "Assets/branding/sedulous-logo.svg", .. scope .()), svg) case .Err)
			return null;
		return SVGDrawable.FromString(svg);
	}

	/// The SedulousEngine icon on `window` (its title bar, the taskbar), from
	/// <dataRoot>/Assets/branding/sedulous-icon-<size>.png: 32 px at the normal scale, the
	/// larger sizes for scaled displays. False when none of them loads.
	public static bool ApplyWindowIcon(IWindow window, StringView dataRoot)
	{
		uint32[4] sizes = .(32, 64, 128, 256); // the first at the normal scale
		let images = scope List<Image>();
		defer { ClearAndDeleteItems(images); }
		let icon = scope List<WindowIconImage>();
		for (let size in sizes)
		{
			let path = PathJoin(dataRoot, scope $"Assets/branding/sedulous-icon-{size}.png", .. scope .());
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
