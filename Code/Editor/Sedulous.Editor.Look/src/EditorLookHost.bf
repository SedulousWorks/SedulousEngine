using System;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Fonts;
using Sedulous.Fonts.TrueType;
using Sedulous.Fonts.HarfBuzz; // the shaper the fonts get
using Sedulous.Fonts.Bidi; // mixed-direction lines in visual order
using Sedulous.Graphics;
using Sedulous.Profiler;
using Sedulous.Shell;
using Sedulous.VFS;
using Sedulous.GUI; // with GUI.Hosting's host
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Look;

/// The GUI on a window, looking as the editor does: the GUI host (the window's input, frames,
/// renderer and picture baker), the fonts the sheet names, the editor's own files under the data
/// root (EditorResources) and the sheet. The sheet is the editor's (Editor/editor.css over its
/// tokens), the chosen density's after it and a `:root` block of the user's inputs (the accent),
/// then the user's theme overrides (a file in their data folder, so any token or rule is theirs
/// to set); the scheme and less motion go through the GUI's media. A change to those files on
/// disk (the editor's development loop, or the user's overrides) applies at once.
///
/// The editor's window and the project manager's both stand on one, so the two look the same
/// and follow the same appearance preferences. What goes in the window is the caller's: it
/// fills Root, then attaches the window.
class EditorLookHost
{
	/// The editor's own folder under the data root, the one the resources watch for changes: the
	/// data root also holds the sample projects, whose files a sweep of the whole would walk.
	public const String cEditorFolder = "Editor";
	public const String cSheetPath = "Editor/editor.css";
	/// The user's theme overrides: the folder under their data folder, and the file in it.
	public const String cThemeFolder = "theme";
	public const String cThemeOverridesPath = "overrides.css";

	/// About once a second: a sweep is a walk of the editor's folder.
	private const float cSweepSeconds = 1.0f;

	private String mDataRoot = new .() ~ delete _;
	private EditorLook mLook = new .() ~ delete _;
	/// Borrowed (the caller's).
	private GraphicsDevice mDevice = null;
	/// Borrowed (the caller's); null until attached.
	private Sedulous.Graphics.RenderWindow mAttached = null;
	/// The shaders' mount.
	private NativeFileSystem mData = null ~ delete _;
	private VgShaderLibrary mShaders = null ~ delete _;
	private TrueTypeFontService mFonts = null ~ delete _;
	private EditorResources mResources = null ~ delete _;
	/// The user's overrides' folder; null: none.
	private EditorResources mTheme = null ~ delete _;
	private GuiHost mHost = null ~ delete _;
	/// A reference of ours (the window holds its own while attached).
	private SceneRoot mRoot = null ~ _?.ReleaseRef();
	/// The sheet again when the editor's files or the overrides change.
	private Effect mReload = null ~ delete _;
	private float mSinceSweep = 0.0f;

	public ~this()
	{
		Close();
	}

	/// How every editor window presents: vsync, with a third swapchain image, so a compositor late
	/// in giving one back (two images held the frame for whole refreshes) costs nothing; the
	/// frame of latency it adds is no matter in an editor. A game keeps the default.
	public static RenderWindowDesc WindowDesc()
	{
		var desc = RenderWindowDesc();
		desc.PresentMode = .Fifo;
		desc.BufferCount = 3;
		return desc;
	}

	/// Opens the GUI for `device` and `shell` over the data root: the shaders, the fonts, the
	/// sheet with `look` (copied) and the user's theme overrides from `themeFolder` (made if it is
	/// not there; empty: none), and an empty Root. `userAgent` is the sheet under the editor's (the
	/// widgets' theme, then the sheets of the GUI satellites the caller's elements come from); the
	/// caller registers those elements before. `opener` opens a float's own OS window (null: none);
	/// TAKES OWNERSHIP of it. False (logged, and nothing kept) when the device or the shaders are
	/// missing.
	public bool Open(GraphicsDevice device, IShell shell, StringView dataRoot, EditorLook look, StringView themeFolder = default,
		StringView userAgent = default, GuiHost.WindowOpener opener = null)
	{
		Close(); // opened again: the last GUI goes first
		if ((device == null) || (device.Raw == null) || (shell == null))
		{
			GlobalLog(.Error, "Editor: no window or device: no interface");
			delete opener;
			return false;
		}
		mDevice = device;
		mDataRoot.Set(dataRoot);
		mData = new NativeFileSystem(dataRoot);
		mShaders = new VgShaderLibrary();
		if (!mShaders.Load(mDevice.Raw, mData))
		{
			GlobalLog(.Error, "Editor: the GUI's shaders did not load from '{}'", dataRoot);
			delete opener;
			Close();
			return false;
		}
		RegisterGuiElements();
		// Shaped by HarfBuzz and reordered by the bidirectional algorithm, installed before a font
		// loads so its atlas takes what shaping reaches.
		HarfBuzzShaping.Install();
		BidiAlgorithm.Install();
		mFonts = new TrueTypeFontService();
		mResources = new EditorResources(dataRoot, cEditorFolder);
		if (!themeFolder.IsEmpty)
		{
			// A place for the file the user writes (the data folder first, should it be new).
			CreateDirectory(PathParent(themeFolder, .. scope .()));
			CreateDirectory(themeFolder);
			mTheme = new EditorResources(themeFolder);
		}

		mHost = new GuiHost(mDevice, shell, mFonts, mShaders.Set);
		if (opener != null)
			mHost.SetWindowOpener(opener);
		let styles = mHost.Styles;
		styles.ResourceProvider = mResources;
		mHost.Context.ResourceProvider = mResources;
		styles.SetFontFaceLoader(new (face, source) => LoadFontFace(face, source));
		let theme = scope String(Sedulous.GUI.Theme.DefaultThemeCSS);
		if (!userAgent.IsEmpty)
		{
			theme.Append('\n');
			theme.Append(userAgent);
		}
		let sheet = scope StyleSheet();
		CSSParser.Parse(theme, "theme", sheet);
		styles.UserAgentSheet = sheet; // copied

		mRoot = new SceneRoot(mHost.Context);
		SetLook(look);
		// The editor's own files or the user's overrides changed on disk: the sheet applies again.
		mReload = new Effect(new () =>
			{
				mResources.TrackChanges();
				if (mTheme != null)
					mTheme.TrackChanges();
				if (mHost != null)
					ApplySheet();
			});
		return true;
	}

	/// Puts Root on `window`, for the host to draw and feed input to. Borrowed until Close.
	public void Attach(Sedulous.Graphics.RenderWindow window)
	{
		if ((mHost == null) || (window == null) || (mAttached != null))
			return;
		mAttached = window;
		mHost.AttachWindow(window, mRoot);
	}

	/// The look (copied): the sheets for the density, the accent as an input, the scheme and
	/// motion through the media, the UI scale through the host.
	public void SetLook(EditorLook look)
	{
		mLook.Set(look);
		if (mHost == null)
			return;
		mHost.UiScale = mLook.UiScale;
		mHost.Context.DarkScheme = mLook.Dark;
		mHost.Context.ReducedMotion = mLook.ReduceMotion;
		ApplySheet();
	}

	/// The look in effect. The host's.
	public EditorLook Look => mLook;

	/// A file's text by its path under the data root, appended; false when it is not there.
	public bool LoadText(StringView path, String outText) => (mResources != null) && mResources.LoadText(path, outText);

	/// A page's or a panel's markup by its path under the data root (Editor/...): a node with one
	/// reference, the caller's, or null (logged) when it does not load.
	public Node LoadMarkup(StringView path)
	{
		let text = scope String();
		if ((mHost == null) || !mResources.LoadText(path, text))
		{
			GlobalLog(.Error, "Editor: markup '{}' is not there", path);
			return null;
		}
		let loader = scope MarkupLoader(mHost.Context.ElementSet, null, mFonts);
		loader.SetDataModel(mHost.Context.Data);
		return loader.LoadFromString(text);
	}

	/// One frame: the editor's files swept for changes (about once a second), then the GUI.
	public void Update(float deltaTime)
	{
		if (mHost == null)
			return;
		mSinceSweep += deltaTime;
		if (mSinceSweep >= cSweepSeconds)
		{
			using (ProfileScope("Editor.Sweep"))
			{
				mSinceSweep = 0.0f;
				mResources.Poll();
				if ((mTheme != null) && mTheme.Poll())
					GlobalLog(.Information, "Editor: the theme overrides applied again ({})", cThemeOverridesPath);
			}
		}
		mHost.Update(deltaTime);
	}

	/// Draws the GUI into `frame`'s window (the attached one and any float's).
	public void Render(ref FrameContext frame)
	{
		if (mHost != null)
			mHost.RenderWindow(ref frame);
	}

	/// The first half of Close, for a caller holding nodes of the tree: the frames in flight
	/// finished (the host's renderer and the shaders it draws with go next), the reload stopped and
	/// the window let go. The caller releases its nodes after it, before Close.
	public void Detach()
	{
		if ((mHost != null) && (mDevice != null) && (mDevice.Raw != null))
			mDevice.Raw.WaitIdle();
		DeleteAndNullify!(mReload);
		if ((mHost != null) && (mAttached != null))
			mHost.DetachWindow(mAttached);
		mAttached = null;
	}

	/// Takes the GUI down, before the device goes, in the order it needs: the tree, the host, then
	/// what it borrowed.
	public void Close()
	{
		Detach();
		if (mRoot != null)
		{
			mRoot.ReleaseRef();
			mRoot = null;
		}
		if (mHost != null)
		{
			// The GUI lets go of what it borrows from the host before it goes.
			mHost.Context.ResourceProvider = null;
			mHost.Styles.ResourceProvider = null;
		}
		DeleteAndNullify!(mHost);
		DeleteAndNullify!(mTheme);
		DeleteAndNullify!(mResources);
		DeleteAndNullify!(mFonts);
		DeleteAndNullify!(mShaders);
		DeleteAndNullify!(mData);
		mDevice = null;
		mSinceSweep = 0.0f;
	}

	public bool IsOpen => mHost != null;
	/// The host's, as are the rest; null while closed.
	public GuiHost Host => mHost;
	public SceneRoot Root => mRoot;
	public EditorResources Resources => mResources;
	public TrueTypeFontService Fonts => mFonts;

	/// The sheet `look` makes from the editor's files, appended to `outSheet`: the editor's sheet,
	/// the density's after it (its sizes win), then a `:root` block of the inputs (the accent).
	public static void SheetFor(IResourceProvider resources, EditorLook look, String outSheet) => SheetFor(resources, look, null, outSheet);

	/// The same, then the user's overrides from `theme` (null: none), last so what they set wins.
	public static void SheetFor(IResourceProvider resources, EditorLook look, IResourceProvider theme, String outSheet)
	{
		resources.LoadText(cSheetPath, outSheet);
		let density = scope String();
		if (resources.LoadText(scope $"Editor/density-{look.Density}.css", density))
		{
			outSheet.Append('\n');
			outSheet.Append(density);
		}
		outSheet.AppendF("\n:root {{ --accent-input: {}; }}\n", look.Accent);
		let overrides = scope String();
		if ((theme != null) && theme.LoadText(cThemeOverridesPath, overrides))
		{
			outSheet.Append(overrides);
			outSheet.Append('\n');
		}
	}

	private void ApplySheet()
	{
		let text = SheetFor(mResources, mLook, mTheme, .. scope String());
		let sheet = scope StyleSheet();
		CSSParser.Parse(text, cSheetPath, sheet);
		mHost.Styles.StyleSheet = sheet; // copied
	}

	/// A face a sheet's @font-face names, from its file under the data root, at the size and
	/// range every editor face is baked with.
	public static FontLoadOptions FaceOptions()
	{
		var options = FontLoadOptions.ExtendedLatin();
		options.PixelHeight = 16.0f;
		options.LastCodepoint = 0x17F;
		return options;
	}

	private bool LoadFontFace(StringView face, StringView source)
	{
		if (mFonts.LoadFont(face, PathJoin(mDataRoot, source, .. scope String()), FaceOptions()) == .Success)
			return true;
		GlobalLog(.Error, "Editor: the @font-face {} ({}) did not load", face, source);
		return false;
	}
}
