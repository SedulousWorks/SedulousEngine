using System;
using Sedulous.Core.Logging;
using Sedulous.Graphics;
using Sedulous.Runtime.Client; // IApplicationHost
using Sedulous.Fonts.TrueType;
using Sedulous.GUI; // with GUI.Hosting's host, GUI.Docking's, GUI.Toolkit's and GUI.Code's sheets and elements
using Sedulous.Profiler.GUI; // its sheet and elements
using Sedulous.Editor.Core;
using Sedulous.Editor.Look;

namespace Sedulous.Editor.App;

// EditorWindow: the editor's GUI on its main window. The GUI host, the fonts, the editor's own
// files and the sheet are an EditorLookHost's, the look the project manager shares; the window
// adds the frame read from Data/Editor/Shell.xml with the dock's host, its status bar
// (EditorStatusBar) and the toast host over its dock.

class EditorWindow
{
	/// How every editor window presents (EditorLookHost.WindowDesc).
	public static RenderWindowDesc EditorRenderWindowDesc() => EditorLookHost.WindowDesc();

	/// The frame's markup, under the data root.
	public const String cFramePath = "Editor/Shell.xml";
	/// The look's paths (EditorLookHost's), named here too for the editor's callers.
	public const String cEditorFolder = EditorLookHost.cEditorFolder;
	public const String cSheetPath = EditorLookHost.cSheetPath;
	public const String cThemeFolder = EditorLookHost.cThemeFolder;
	public const String cThemeOverridesPath = EditorLookHost.cThemeOverridesPath;

	/// The GUI with the editor's look; the frame and what hangs on it are the window's.
	private EditorLookHost mGui = new .() ~ delete _;
	/// Kept while closed too, for when it opens (the host keeps its own while open).
	private EditorLook mLook = new .() ~ delete _;
	/// References of ours (the tree holds its own).
	private Node mFrame = null ~ _?.ReleaseRef();
	private ToastHost mToasts = null ~ _?.ReleaseRef();
	/// Over the frame's items: it goes before the frame.
	private EditorStatusBar mStatus = null ~ delete _;

	public ~this()
	{
		Close();
	}

	/// Opens the GUI on the host's main window over the data root: the shaders, the fonts, the
	/// frame and the sheet, with the user's theme overrides from `themeFolder` (made if it is not
	/// there; empty: none). `look` is copied. False (logged, and nothing kept) when the window, the
	/// device, the shaders or the frame are missing; the editor then runs with no interface.
	public bool Open(IApplicationHost host, StringView dataRoot, EditorLook look, StringView themeFolder = default)
	{
		Close(); // opened again: the last GUI goes first
		mLook.Set(look);
		let window = host.MainRenderWindow;
		if ((window == null) || (host.Graphics == null) || (host.Graphics.Raw == null) || (host.Shell == null))
		{
			GlobalLog(.Error, "Editor: no window or device: the editor runs without its interface");
			return false;
		}
		RegisterToolkitElements();
		RegisterCodeElements();
		RegisterProfilerElements();
		// A float in an OS window of its own: the runtime host's.
		let opener = new GuiHost.WindowOpener();
		opener.Open = new (settings) => host.OpenWindow(settings, EditorRenderWindowDesc());
		opener.Close = new (opened) => host.CloseWindow(opened);
		// The satellites' sheets over the widgets'.
		let satellites = scope $"{DockingSheetCSS()}\n{ToolkitSheetCSS()}\n{CodeSheetCSS()}\n{ProfilerSheetCSS()}";
		if (!mGui.Open(host.Graphics, host.Shell, dataRoot, mLook, themeFolder, satellites, opener))
			return false;

		mFrame = LoadMarkup(cFramePath);
		if (mFrame == null)
		{
			GlobalLog(.Error, "Editor: the editor's frame ({}) did not load", cFramePath);
			Close();
			return false;
		}
		mGui.Root.AddChild(mFrame);
		mStatus = new EditorStatusBar(mFrame);
		mToasts = new ToastHost();
		ToastsInto(mFrame).AddChild(mToasts);
		mGui.Attach(window);
		return true;
	}

	/// The look (copied): the sheets for the density, the accent as an input, the scheme and
	/// motion through the media, the UI scale through the host.
	public void SetLook(EditorLook look)
	{
		mLook.Set(look);
		mGui.SetLook(look);
	}

	/// The look in effect. The window's.
	public EditorLook Look => mLook;

	/// A file's text by its path under the data root (a code language's), appended; false when it
	/// is not there.
	public bool LoadText(StringView path, String outText) => mGui.LoadText(path, outText);

	/// A page's or a panel's markup by its path under the data root (Editor/...): a node with one
	/// reference, the caller's, or null (logged) when it does not load.
	public Node LoadMarkup(StringView path) => mGui.LoadMarkup(path);

	/// A toast over the dock, its severity the notice's; the same message again counts on the one
	/// shown. An error stays until it is dismissed, and so does one with an action (Open Folder on
	/// an export), its button running `action`; the rest go after five seconds. TAKES OWNERSHIP of
	/// `action`.
	public void ShowToast(NoticeKind kind, StringView message, StringView actionText = default, delegate void() action = null)
	{
		if (mToasts == null)
		{
			delete action;
			return;
		}
		PostNotice(mToasts, kind, message, actionText, action);
	}

	/// Posts a notice on `toasts` as ShowToast does: keyed by its message, so a repeat counts on
	/// the one shown rather than stacking another. TAKES OWNERSHIP of `action`.
	public static ToastId PostNotice(ToastHost toasts, NoticeKind kind, StringView message, StringView actionText = default,
		delegate void() action = null)
	{
		let request = scope ToastRequest();
		MakeToast(kind, message, actionText, request);
		if (action == null)
			return toasts.Post(request); // copied
		return toasts.Post(request, new [=action] (pressed) => { action(); } ~ delete action);
	}

	/// The toast a notice shows, into `outRequest`: its severity, the message as its title and its
	/// key; an error until closed, the rest five seconds; with an action's text, a button and no
	/// time out.
	public static void MakeToast(NoticeKind kind, StringView message, StringView actionText, ToastRequest outRequest)
	{
		switch (kind)
		{
		case .Success: outRequest.Severity = .Success;
		case .Warning: outRequest.Severity = .Warning;
		case .Error: outRequest.Severity = .Error;
		default: outRequest.Severity = .Info;
		}
		outRequest.Title = message;
		outRequest.Key = message;
		outRequest.Duration = (kind == .Error) ? 0.0f : 5.0f;
		if (!actionText.IsEmpty)
		{
			outRequest.AddAction("action", actionText, "");
			outRequest.Duration = 0.0f; // until closed: its button is there to be used
		}
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

	/// A frame's node by its id (the dock's host, the status bar's items); null when none is.
	/// The tree's.
	public Node FindById(StringView id) => (mFrame != null) ? mFrame.FindElement(id) : null;

	/// One frame: the editor's files swept for changes (about once a second), then the GUI.
	public void Update(float deltaTime) => mGui.Update(deltaTime);

	/// Draws the GUI into `frame`'s window (the main window and any float's).
	public void Render(ref FrameContext frame) => mGui.Render(ref frame);

	/// Takes the GUI down, before the device goes: the frames in flight finish first, the
	/// window's nodes go while the tree is there, then the GUI.
	public void Close()
	{
		mGui.Detach();
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
		mGui.Close();
	}

	public bool IsOpen => mGui.IsOpen;
	/// The window's, as are the rest; null while closed.
	public GuiHost Host => mGui.Host;
	public SceneRoot Root => mGui.Root;
	public EditorResources Resources => mGui.Resources;
	public TrueTypeFontService Fonts => mGui.Fonts;

	/// The sheet `look` makes from the editor's files (EditorLookHost.SheetFor), appended to
	/// `outSheet`.
	public static void SheetFor(IResourceProvider resources, EditorLook look, String outSheet) => EditorLookHost.SheetFor(resources, look, outSheet);

	/// The same, then the user's overrides from `theme` (null: none), last so what they set wins.
	public static void SheetFor(IResourceProvider resources, EditorLook look, IResourceProvider theme, String outSheet) =>
		EditorLookHost.SheetFor(resources, look, theme, outSheet);
}
