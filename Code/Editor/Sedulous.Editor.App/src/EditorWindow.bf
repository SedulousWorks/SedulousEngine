using System;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Fonts;
using Sedulous.Fonts.TrueType;
using Sedulous.Fonts.HarfBuzz; // the shaper the editor's fonts get
using Sedulous.Fonts.Bidi; // mixed-direction lines in visual order
using Sedulous.Graphics;
using Sedulous.Runtime.Client; // IApplicationHost
using Sedulous.VFS;
using Sedulous.GUI; // with GUI.Hosting's host, GUI.Docking's, GUI.Toolkit's and GUI.Code's sheets and elements
using Sedulous.Profiler.GUI; // its sheet and elements
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

// EditorWindow: the editor's GUI on its main window (Raptor's editor-gui spec, 5.1, layer 3). It
// owns the GUI host (the window's input, frames, renderer and picture baker), the fonts the
// editor's sheet names, the editor's own files (EditorResources) and the frame read from
// Data/Editor/Shell.gml, with its status bar (EditorStatusBar) and the toast host over its dock.
// Its look is the editor's sheet (Editor/editor.css over its tokens), the chosen density's sheet
// after it and a `:root` block of the user's inputs (the accent), the scheme and less motion
// through the GUI's media; a change to those files on disk (the editor's development loop)
// applies at once.

/// An accent Preferences offers: its name and its fill.
struct EditorAccent
{
	public StringView Name;
	public StringView Fill;

	public this(StringView name, StringView fill)
	{
		Name = name;
		Fill = fill;
	}
}

/// The user's appearance inputs (Preferences): the scheme, the accent, the density, less motion
/// and the UI scale. The defaults are the editor's (rulings 6, 7, 13). A class: it owns its text;
/// Set copies another.
class EditorLook
{
	/// The densities the editor's sheets give (Editor/density-<name>.css), in their order.
	public static readonly StringView[3] Densities = .("compact", "default", "comfortable");
	/// The accents Preferences offers, each a fill white text reads on (ruling 7; azure is the
	/// editor's, ruling 13). Any other #rrggbb is taken too.
	public static readonly EditorAccent[4] Accents = .(
		.("Azure", "#2f6fdf"),
		.("Violet", "#6d5bd8"),
		.("Teal", "#0f8a7e"),
		.("Magenta", "#b03d93"));

	public bool Dark = true;
	public String Accent = new .("#2f6fdf") ~ delete _; // azure
	/// compact, default or comfortable: Editor/density-<name>.css.
	public String Density = new .("compact") ~ delete _;
	public bool ReduceMotion = false;
	public float UiScale = 1.0f;

	public void Set(EditorLook other)
	{
		if (other === this)
			return;
		Dark = other.Dark;
		Accent.Set(other.Accent);
		Density.Set(other.Density);
		ReduceMotion = other.ReduceMotion;
		UiScale = other.UiScale;
	}

	/// The look the user's settings ask for (null: none, the defaults); what they leave unset or
	/// name wrongly (a density with no sheet, an accent that is no colour) is the editor's default.
	public void ReadFrom(EditorUiSettings ui)
	{
		Set(scope EditorLook()); // the defaults, then what the settings say over them
		if (ui == null)
			return;
		Dark = ui.Scheme != "light";
		if (IsHexColor(ui.Accent))
			Accent.Set(ui.Accent);
		for (let density in Densities)
		{
			if (density == (StringView)ui.Density)
				Density.Set(density);
		}
		ReduceMotion = ui.ReduceMotion;
		UiScale = Math.Clamp(ui.UiScale, EditorUiSettings.MinUiScale, EditorUiSettings.MaxUiScale);
	}

	/// The look into the user's settings, the section's other fields kept.
	public void StoreInto(EditorUiSettings ui)
	{
		ui.Scheme.Set(Dark ? "dark" : "light");
		ui.Accent.Set(Accent);
		ui.Density.Set(Density);
		ui.ReduceMotion = ReduceMotion;
		ui.UiScale = UiScale;
	}

	/// Whether `text` is a colour as #rrggbb.
	public static bool IsHexColor(StringView text)
	{
		if ((text.Length != 7) || (text[0] != '#'))
			return false;
		for (int i = 1; i < 7; i++)
		{
			let c = text[i];
			if (!(((c >= '0') && (c <= '9')) || ((c >= 'a') && (c <= 'f')) || ((c >= 'A') && (c <= 'F'))))
				return false;
		}
		return true;
	}
}

class EditorWindow
{
	/// The frame's markup and the editor's sheet, under the data root.
	public const String cFramePath = "Editor/Shell.gml";
	public const String cSheetPath = "Editor/editor.css";

	/// About once a second: a sweep is a walk of the editor's folder.
	private const float cSweepSeconds = 1.0f;

	// Close lets each go, in the order the GUI needs (the trees, the host, then what it
	// borrowed); the field cleanups find them gone.
	private String mDataRoot = new .() ~ delete _;
	private EditorLook mLook = new .() ~ delete _;
	/// Borrowed (the runtime host's).
	private GraphicsDevice mDevice = null;
	/// Borrowed (the runtime host's).
	private Sedulous.Graphics.RenderWindow mWindow = null;
	/// The shaders' mount.
	private NativeFileSystem mData = null ~ delete _;
	private VgShaderLibrary mShaders = null ~ delete _;
	private TrueTypeFontService mFonts = null ~ delete _;
	private EditorResources mResources = null ~ delete _;
	private GuiHost mHost = null ~ delete _;
	/// References of ours (the tree holds its own).
	private SceneRoot mRoot = null ~ _?.ReleaseRef();
	private Node mFrame = null ~ _?.ReleaseRef();
	private ToastHost mToasts = null ~ _?.ReleaseRef();
	/// Over the window in place of the frame while shown (the project manager): a reference of
	/// ours, the tree holding its own.
	private Node mScreen = null ~ _?.ReleaseRef();
	/// Over the frame's items: it goes before the frame.
	private EditorStatusBar mStatus = null ~ delete _;
	/// The sheet again when the editor's files change.
	private Effect mReload = null ~ delete _;
	private float mSinceSweep = 0.0f;

	public ~this()
	{
		Close();
	}

	/// Opens the GUI on the host's main window over the data root: the shaders, the fonts, the
	/// frame and the sheet. `look` is copied. False (logged, and nothing kept) when the window, the
	/// device, the shaders or the frame are missing; the editor then runs with no interface.
	public bool Open(IApplicationHost host, StringView dataRoot, EditorLook look)
	{
		Close(); // opened again: the last GUI goes first
		let window = host.MainRenderWindow;
		if ((window == null) || (host.Graphics == null) || (host.Graphics.Raw == null) || (host.Shell == null))
		{
			GlobalLog(.Error, "Editor: no window or device: the editor runs without its interface");
			return false;
		}
		mWindow = window;
		mDevice = host.Graphics;
		mDataRoot.Set(dataRoot);
		mData = new NativeFileSystem(dataRoot);
		mShaders = new VgShaderLibrary();
		if (!mShaders.Load(mDevice.Raw, mData))
		{
			GlobalLog(.Error, "Editor: the GUI's shaders did not load from '{}'", dataRoot);
			Close();
			return false;
		}
		RegisterGuiElements();
		RegisterToolkitElements();
		RegisterCodeElements();
		RegisterProfilerElements();
		// Shaped by HarfBuzz and reordered by the bidirectional algorithm, installed before a font
		// loads so its atlas takes what shaping reaches.
		HarfBuzzShaping.Install();
		BidiAlgorithm.Install();
		mFonts = new TrueTypeFontService();
		mResources = new EditorResources(dataRoot);

		mHost = new GuiHost(mDevice, host.Shell, mFonts, mShaders.Set);
		{
			// A float in an OS window of its own: the runtime host's.
			let opener = new GuiHost.WindowOpener();
			opener.Open = new (settings) => host.OpenWindow(settings, RenderWindowDesc());
			opener.Close = new (opened) => host.CloseWindow(opened);
			mHost.SetWindowOpener(opener);
		}
		let styles = mHost.Styles;
		styles.ResourceProvider = mResources;
		mHost.Context.ResourceProvider = mResources;
		styles.SetFontFaceLoader(new (face, source) => LoadFontFace(face, source));
		// The satellites' sheets over the widgets'.
		let theme = scope $"{Sedulous.GUI.Theme.DefaultThemeCSS}\n{DockingSheetCSS()}\n{ToolkitSheetCSS()}\n{CodeSheetCSS()}\n{ProfilerSheetCSS()}";
		let userAgent = scope StyleSheet();
		CSSParser.Parse(theme, "theme", userAgent);
		styles.UserAgentSheet = userAgent; // copied

		mRoot = new SceneRoot(mHost.Context);
		mFrame = LoadMarkup(cFramePath);
		if (mFrame == null)
		{
			GlobalLog(.Error, "Editor: the editor's frame ({}) did not load", cFramePath);
			Close();
			return false;
		}
		mRoot.AddChild(mFrame);
		mStatus = new EditorStatusBar(mFrame);
		mToasts = new ToastHost();
		ToastsInto(mFrame).AddChild(mToasts);
		SetLook(look);
		// The editor's own files changed on disk: its sheet applies again.
		mReload = new Effect(new () =>
			{
				mResources.TrackChanges();
				if (mFrame != null)
					ApplySheet();
			});
		mHost.AttachWindow(mWindow, mRoot);
		return true;
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

	/// The look in effect. The window's.
	public EditorLook Look => mLook;

	/// A file's text by its path under the data root (a code language's), appended; false when it
	/// is not there.
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

	/// A toast over the dock, its severity the notice's; the same message again counts on the one
	/// shown. An error stays until it is dismissed; the rest go after five seconds.
	public void ShowToast(NoticeKind kind, StringView message)
	{
		if (mToasts != null)
			PostNotice(mToasts, kind, message);
	}

	/// Posts a notice on `toasts` as ShowToast does: keyed by its message, so a repeat counts on
	/// the one shown rather than stacking another.
	public static ToastId PostNotice(ToastHost toasts, NoticeKind kind, StringView message)
	{
		let request = scope ToastRequest();
		switch (kind)
		{
		case .Success: request.Severity = .Success;
		case .Warning: request.Severity = .Warning;
		case .Error: request.Severity = .Error;
		default: request.Severity = .Info;
		}
		request.Title = message;
		request.Key = message;
		request.Duration = (kind == .Error) ? 0.0f : 5.0f;
		return toasts.Post(request); // copied
	}

	/// Where the toasts stack in `frame`: over its dock (`frame-dock`), at its bottom right, so
	/// they sit above the status bar; the frame itself when it has no dock.
	public static Node ToastsInto(Node frame)
	{
		let dock = frame.FindElement("frame-dock");
		return (dock != null) ? dock : frame;
	}

	/// The status bar's message.
	public void SetStatus(StringView message)
	{
		if (mStatus != null)
			mStatus.SetMessage(message);
	}

	/// The status bar: its message, the job running, the agent; null with no interface. The
	/// window's.
	public EditorStatusBar StatusBar => mStatus;

	/// A screen over the whole window in place of the frame (the project manager); null puts the
	/// frame back. The window takes a reference of its own. Nothing with no interface.
	public void ShowScreen(Node screen)
	{
		if ((mRoot == null) || (mFrame == null))
			return;
		if (screen != null)
			screen.AddRef(); // first: the screen shown again is not let go below
		if (mScreen != null)
		{
			mScreen.RemoveFromParent();
			mScreen.ReleaseRef();
		}
		mScreen = screen;
		mFrame.Displayed = mScreen == null;
		if (mScreen != null)
			mRoot.AddChild(mScreen);
	}

	/// A screen shows in place of the frame.
	public bool ShowsScreen => mScreen != null;

	/// A frame's node by its id (the dock's host, the status bar's items); null when none is.
	/// The tree's.
	public Node FindById(StringView id) => (mFrame != null) ? mFrame.FindElement(id) : null;

	/// One frame: the editor's files swept for changes (about once a second), then the GUI.
	public void Update(float deltaTime)
	{
		if (mHost == null)
			return;
		mSinceSweep += deltaTime;
		if (mSinceSweep >= cSweepSeconds)
		{
			mSinceSweep = 0.0f;
			mResources.Poll();
		}
		mHost.Update(deltaTime);
	}

	/// Draws the GUI into `frame`'s window (the main window and any float's).
	public void Render(ref FrameContext frame)
	{
		if (mHost != null)
			mHost.RenderWindow(ref frame);
	}

	/// Takes the GUI down, before the device goes: the frames in flight finish first, since the
	/// host's renderer and the shaders it draws with go.
	public void Close()
	{
		if ((mHost != null) && (mDevice != null) && (mDevice.Raw != null))
			mDevice.Raw.WaitIdle();
		DeleteAndNullify!(mReload);
		if ((mHost != null) && (mWindow != null))
			mHost.DetachWindow(mWindow);
		if (mScreen != null)
		{
			mScreen.ReleaseRef();
			mScreen = null;
		}
		if (mToasts != null)
		{
			mToasts.ReleaseRef();
			mToasts = null;
		}
		DeleteAndNullify!(mStatus);
		if (mFrame != null)
		{
			mFrame.ReleaseRef();
			mFrame = null;
		}
		if (mRoot != null)
		{
			mRoot.ReleaseRef();
			mRoot = null;
		}
		if (mHost != null)
		{
			// The GUI lets go of what it borrows from the window before it goes.
			mHost.Context.ResourceProvider = null;
			mHost.Styles.ResourceProvider = null;
		}
		DeleteAndNullify!(mHost);
		DeleteAndNullify!(mResources);
		DeleteAndNullify!(mFonts);
		DeleteAndNullify!(mShaders);
		DeleteAndNullify!(mData);
		mWindow = null;
		mDevice = null;
		mSinceSweep = 0.0f;
	}

	public bool IsOpen => mHost != null;
	/// The window's, as are the rest; null while closed.
	public GuiHost Host => mHost;
	public SceneRoot Root => mRoot;
	public EditorResources Resources => mResources;
	public TrueTypeFontService Fonts => mFonts;

	/// The sheet `look` makes from the editor's files, appended to `outSheet`: the editor's sheet,
	/// the density's after it (its sizes win), then a `:root` block of the inputs (the accent).
	public static void SheetFor(IResourceProvider resources, EditorLook look, String outSheet)
	{
		resources.LoadText(cSheetPath, outSheet);
		let density = scope String();
		if (resources.LoadText(scope $"Editor/density-{look.Density}.css", density))
		{
			outSheet.Append('\n');
			outSheet.Append(density);
		}
		outSheet.AppendF("\n:root {{ --accent-input: {}; }}\n", look.Accent);
	}

	private void ApplySheet()
	{
		let text = SheetFor(mResources, mLook, .. scope String());
		let sheet = scope StyleSheet();
		CSSParser.Parse(text, cSheetPath, sheet);
		mHost.Styles.StyleSheet = sheet; // copied
	}

	/// A face a sheet's @font-face names, from its file under the data root.
	private bool LoadFontFace(StringView face, StringView source)
	{
		var options = FontLoadOptions.ExtendedLatin();
		options.PixelHeight = 16.0f;
		options.LastCodepoint = 0x17F;
		if (mFonts.LoadFont(face, PathJoin(mDataRoot, source, .. scope String()), options) == .Success)
			return true;
		GlobalLog(.Error, "Editor: the @font-face {} ({}) did not load", face, source);
		return false;
	}
}
