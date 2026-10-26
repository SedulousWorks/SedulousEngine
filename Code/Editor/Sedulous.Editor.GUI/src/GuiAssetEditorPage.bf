using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Runtime.Client;
using Sedulous.Graphics;
using Sedulous.UI;
using Sedulous.UI.Runtime;
using Sedulous.UI.Toolkit;
using Sedulous.UI.Viewport;
using Sedulous.Pipeline.Core;
using Sedulous.GUI.Pipeline;
using Sedulous.Engine.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.GUI;

/// The engine GUI's asset page: a `.gml` document or a `.css` sheet, its text in the linked
/// Sources/ file, beside a live preview the RUNTIME context's GuiSubsystem draws into the page's
/// offscreen target (CreatePreview / RenderPreview), so the game's fonts, theme and sheets show.
/// A sheet is previewed over markup of its own (a second editor, kept on the asset as editor-only
/// PreviewMarkup, never cooked; "Preview Document..." copies a document's markup in), the sheet
/// applied to that tree alone, never to the game's GUI. Edits rebuild the preview after a short
/// pause; what the cook would report marks the lines; a document that does not build keeps the
/// last good preview. Save writes the source and the asset, then asks for the validating cook.
///
/// The page's own widgets are Sedulous.UI's, as the editor is: Sedulous.GUI's types are named in
/// full, its Button and Label being others.
class GuiAssetEditorPage : UIEditorPage
{
	/// What the page edits: a document (its markup, previewed as it is) or a sheet (its CSS,
	/// previewed over markup of its own).
	public enum Kind : uint8
	{
		case Document;
		case StyleSheet;
	}

	/// Borrowed, as the hosts are.
	private EditorContext mContext;
	private IApplicationHost mHost;
	private UIHost mUiHost;
	/// The RUNTIME context's; null in a headless host.
	private GuiSubsystem mGui;
	private RenderWindow mHostWindow = null;
	private Kind mKind;
	private String mTitle = new .() ~ delete _;
	/// The asset's: the document's markup, or the sheet's CSS.
	private String mText = new .() ~ delete _;
	/// A sheet's: what it is previewed over (editor-only, on the asset).
	private String mPreviewMarkup = new .() ~ delete _;
	private String mStatusText = new .() ~ delete _;
	/// Counts down after a keystroke; the preview rebuilds when it reaches zero.
	private float mPreviewDelay = 0.0f;
	/// OWNED through its reference: in the runtime context's GUI, never in a tier.
	private Sedulous.GUI.SceneRoot mPreviewRoot = null;

	/// Borrowed: the content owns them.
	private View mContent = null ~ { if (_ != null) _.ReleaseRef(); };
	private PageToolbar mToolbar = null;
	private CodeEditView mEditor = null;
	/// A sheet's.
	private CodeEditView mPreviewEditor = null;
	private Label mStatus = null;
	private ViewportView mViewport = null;

	public this(EditorContext context, IApplicationHost host, UIHost uiHost, Instance instance, Kind kind)
	{
		mContext = context;
		mHost = host;
		mUiHost = uiHost;
		mKind = kind;
		mGui = (host != null) ? host.Context.GetSubsystem<GuiSubsystem>() : null;
		mTitle.Set(instance.Name);
		InstanceId = instance.Id;

		let object = instance.ReadObject();
		defer delete object;
		if (let asset = (Object)object as Asset)
		{
			if (!asset.FileName.IsEmpty)
				ReadSource(asset.FileName.Value, mText);
			else
				GlobalLog(.Error, "Editor: GUI asset has no linked source file, the page opens empty (import the file again)");
		}
		if (let sheet = object as GuiStyleSheetAsset)
			mPreviewMarkup.Set(sheet.PreviewMarkup);
		if ((mKind == .StyleSheet) && mPreviewMarkup.IsEmpty)
			mPreviewMarkup.Set(GuiPages.cStockPreviewMarkup); // previewed over something from the start

		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 8.0f;

		// Left: the asset's own text.
		mEditor = MakeEditor(mText, mKind == .Document);
		mEditor.OnTextChanged.Add(new [=this]() =>
			{
				mEditor.GetText(mText);
				MarkDirty();
				mPreviewDelay = 0.35f; // rebuilt shortly after the typing stops
			});
		var growMatch = LayoutStyle();
		growMatch.FlexGrow = 1.0f;
		growMatch.Height = SizeSpec.Match();
		row.AddView(mEditor, growMatch);

		// Right: [a sheet's document picker] and the status, a sheet's preview markup, the preview.
		let right = new FlexLayout();
		right.Direction = .Vertical;
		right.Spacing = 4.0f;
		let bar = new FlexLayout();
		bar.Direction = .Horizontal;
		bar.Spacing = 8.0f;
		if (mKind == .StyleSheet)
		{
			let pick = new Button("Preview Document...");
			pick.OnClick.Add(new [=this](btn) => { PickPreviewDocument(); });
			bar.AddView(pick);
		}
		mStatus = new Label("");
		mStatus.FontSize.Value = 12.0f;
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		bar.AddView(mStatus, grow);
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		right.AddView(bar, match);
		if (mKind == .StyleSheet)
		{
			mPreviewEditor = MakeEditor(mPreviewMarkup, true);
			mPreviewEditor.OnTextChanged.Add(new [=this]() =>
				{
					mPreviewEditor.GetText(mPreviewMarkup);
					MarkDirty(); // kept on the asset
					mPreviewDelay = 0.35f;
				});
			var fill = LayoutStyle();
			fill.Width = SizeSpec.Match();
			fill.FlexGrow = 1.0f;
			right.AddView(mPreviewEditor, fill);
		}
		// The preview: an offscreen target the runtime's GUI draws into; the editor shows it.
		mViewport = new ViewportView();
		mViewport.ClearColor = .(0.313f, 0.332f, 0.366f, 1.0f); // sRGB, like every UI colour
		var render = LayoutStyle();
		render.Width = SizeSpec.Match();
		render.FlexGrow = (mKind == .StyleSheet) ? 2.0f : 1.0f; // a sheet's render shares its column
		right.AddView(mViewport, render);
		row.AddView(right, growMatch);
		mToolbar = new PageToolbar(this, mContext.Actions, .Save);
		mContent = PageToolbar.Frame(mToolbar, row);
		RebuildPreview();
	}

	public ~this()
	{
		DropPreviewRoot();
	}

	public override StringView Title => mTitle;
	public override View ContentView => mContent;
	public Kind AssetKind => mKind;

	/// What the preview shows now (null before one built), and the text it was built from: for a
	/// test, and a tool. The root is BORROWED.
	public Sedulous.GUI.SceneRoot PreviewRoot => mPreviewRoot;
	public StringView Text => mText;
	public StringView PreviewMarkup => mPreviewMarkup;
	public StringView StatusText => mStatusText;
	/// The asset's text editor, and a sheet's preview markup's (null for a document): BORROWED.
	public CodeEditView Editor => mEditor;
	public CodeEditView PreviewEditor => mPreviewEditor;

	/// The text as if typed, the preview rebuilt now (no pause): a test's and a tool's.
	public void SetText(StringView text)
	{
		mEditor.SetText(text); // fires no OnTextChanged: what it would do is done here
		mText.Set(text);
		MarkDirty();
		RebuildPreview();
		mPreviewDelay = 0.0f;
	}

	/// Writes the linked file, then the asset (a sheet's with its preview markup on it), so the
	/// validating cook sees it, and asks for that cook.
	public override Result<void, ErrorCode> Save()
	{
		let instance = (mContext.Project != null) ? mContext.Project.SourceDb.GetInstance(InstanceId) : null;
		if (instance == null)
			return .Err(.NotFound);
		let object = instance.ReadObject();
		defer delete object;
		let asset = (Object)object as Asset;
		if (asset == null)
			return .Err(.NotFound);
		if (asset.FileName.IsEmpty)
		{
			GlobalLog(.Error, "Editor: GUI asset has no linked source file, save refused");
			return .Err(.NotSupported);
		}
		let sourcesRoot = mContext.Project.SourcesRoot(.. scope .());
		let path = PathJoin(sourcesRoot, asset.FileName.Value, .. scope .());
		if (WriteFile(path, .((uint8*)mText.Ptr, mText.Length)) case .Err(let error))
			return .Err(error);
		if (let sheet = asset as GuiStyleSheetAsset)
			sheet.PreviewMarkup.Set(mPreviewMarkup); // editor-only, kept on the asset
		let written = instance.WriteObject(object);
		if (written case .Ok)
		{
			ClearDirty();
			mContext.RequestCook(false);
		}
		return written;
	}

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		if (mToolbar != null)
			mToolbar.Refresh();
		EnsureViewportBound();
		if (mPreviewDelay > 0.0f)
		{
			mPreviewDelay -= dt;
			if (mPreviewDelay <= 0.0f)
				RebuildPreview();
		}
	}

	public override void OnAfterSceneRender(IApplicationHost host, ref FrameContext frame)
	{
		if (!mViewport.IsReady || !frame.Valid)
			return;
		mViewport.ClearContent(frame.Encoder); // the target defined every frame: the editor samples it
		if ((mGui == null) || (mPreviewRoot == null))
			return;
		let width = mViewport.RenderWidth;
		let height = mViewport.RenderHeight;
		if ((width == 0) || (height == 0))
			return;
		frame.Encoder.TransitionTexture(mViewport.ColorTexture, mViewport.ColorState, .RenderTarget);
		mGui.RenderPreview(mPreviewRoot, frame.Encoder, mViewport.ColorTargetView, mViewport.ColorFormat, width, height,
			frame.FrameIndex);
		frame.Encoder.TransitionTexture(mViewport.ColorTexture, .RenderTarget, .ShaderRead);
		mViewport.ColorState = .ShaderRead;
	}

	public override void OnClose()
	{
		DropPreviewRoot();
		mViewport.Shutdown();
	}

	/// A code editor for `text`; markup is XML, which the toolkit lexes, and CSS is plain text
	/// until it has a lexer.
	private static CodeEditView MakeEditor(StringView text, bool markup)
	{
		let editor = new CodeEditView();
		editor.AllowBreakpoints = false; // nothing to break on
		if (markup)
			editor.SetLexer(new XmlLexer());
		editor.SetText(text);
		return editor;
	}

	/// The linked file under the project's sources, whole; empty when there is no project or the
	/// file does not read.
	private void ReadSource(StringView fileName, String outText)
	{
		outText.Clear();
		if (mContext.Project == null)
			return;
		let sourcesRoot = mContext.Project.SourcesRoot(.. scope .());
		let path = PathJoin(sourcesRoot, fileName, .. scope .());
		let bytes = scope List<uint8>();
		if (ReadFile(path, bytes) case .Ok)
			outText.Append(StringView((char8*)bytes.Ptr, bytes.Count));
	}

	private void SetStatus(StringView text)
	{
		mStatusText.Set(text);
		mStatus.SetText(text);
	}

	/// Binds the viewport to the window it lives in, once it has one.
	private void EnsureViewportBound()
	{
		if (mUiHost == null)
			return;
		let root = mViewport.Root();
		if (root == null)
			return;
		let window = mUiHost.WindowForRoot(root);
		if ((window == null) || (window == mHostWindow))
			return;
		let renderer = mUiHost.RendererFor(window);
		if (renderer == null)
			return;
		if (mHostWindow == null)
			mViewport.Initialize(mHost.Graphics.Raw, renderer, mHost.Shell.Input, window.Window.Id);
		else
			mViewport.AttachToWindow(renderer, window.Window.Id);
		mHostWindow = window;
	}

	private void DropPreviewRoot()
	{
		if (mPreviewRoot == null)
			return;
		mPreviewRoot.ReleaseRef();
		mPreviewRoot = null;
	}

	private void RebuildPreview()
	{
		// What the cook would report, on the lines it is about.
		let found = scope List<Sedulous.GUI.GuiDiagnostic>();
		defer { ClearAndDeleteItems!(found); }
		var builds = true;
		if (mKind == .Document)
			builds = GuiPipeline.ValidateDocument(mText, found);
		else
			GuiPipeline.ValidateStyleSheet(mText, found);
		GuiPages.MarkLines(mEditor, found);
		if (mKind == .StyleSheet)
		{
			let previewFound = scope List<Sedulous.GUI.GuiDiagnostic>();
			defer { ClearAndDeleteItems!(previewFound); }
			builds = GuiPipeline.ValidateDocument(mPreviewMarkup, previewFound);
			GuiPages.MarkLines(mPreviewEditor, previewFound);
		}
		if (!builds)
		{
			SetStatus("Does not build: showing the last good preview.");
			return;
		}
		if (mGui == null)
		{
			SetStatus("No GUI in the runtime: no preview.");
			return;
		}
		// The real preview, in the runtime's GUI (its fonts, theme and the game's sheets).
		let fresh = (mKind == .Document) ? mGui.CreatePreview(mText) : mGui.CreatePreview(mPreviewMarkup, mText);
		if (fresh == null)
		{
			SetStatus("Does not build: showing the last good preview.");
			return;
		}
		DropPreviewRoot();
		mPreviewRoot = fresh; // its reference is the page's
		if (found.IsEmpty)
		{
			SetStatus("OK");
			return;
		}
		let text = scope String((found[0].Level == .Error) ? "Error: " : "Warning: ");
		text.Append(found[0].Message);
		if (found.Count > 1)
			text.AppendF(" (+{} more)", found.Count - 1);
		SetStatus(text);
	}

	/// Copies a GUI document's markup in as the preview, once; it is then the page's to change.
	private void PickPreviewDocument()
	{
		if ((mContext.Project == null) || (mContent == null) || (mContent.Context == null))
			return;
		let dialog = new AssetPickerDialog(mContext, scope StringView[]("GuiDocumentAsset"));
		dialog.OnPicked = new [=this](picked) =>
			{
				if (picked.IsNil || (mContext.Project == null))
					return;
				let inst = mContext.Project.SourceDb.GetInstance(picked);
				if (inst == null)
					return;
				let object = inst.ReadObject();
				defer delete object;
				let document = object as GuiDocumentAsset;
				if ((document == null) || document.FileName.IsEmpty)
					return; // an unlinked document has no text to preview over
				ReadSource(document.FileName.Value, mPreviewMarkup);
				mPreviewEditor.SetText(mPreviewMarkup); // copied once: the page's to change now
				MarkDirty(); // kept on the sheet's asset
				mPreviewDelay = 0.05f; // rebuilt promptly
			};
		dialog.Show(mContent.Context);
	}
}
