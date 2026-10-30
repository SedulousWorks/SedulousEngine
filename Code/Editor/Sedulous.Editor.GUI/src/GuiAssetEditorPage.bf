using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Runtime.Client;
using Sedulous.RHI;
using Sedulous.Settings;
using Sedulous.GUI;
using Sedulous.GUI.Pipeline;
using Sedulous.Engine.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.GUI;

/// The engine GUI's asset page: a `.gml` document or a `.css` sheet on the GUI from its markup
/// (Data/Editor/GuiPage.gml; Raptor's editor-gui spec, 5.4, layer 6, part 5), on the code pages'
/// base (the source file, the shared XML or CSS colours, one history, the problems list). Its check
/// is what the cook would report (the loader's and the parser's diagnostics), and beside the code a
/// live preview the RUNTIME context's GuiSubsystem draws into a viewport of the page (CreatePreview /
/// RenderPreview): the game's fonts, theme and sheets, so what shows is what the game will show. A
/// sheet is previewed over markup of the page's own (edited above the preview, "Preview Over a
/// Document" copying a document's in), kept for the sheet in the project's editor settings: never an
/// edit of the asset (the old page wrote it into the asset and dirtied it), its problems in the list
/// under its own name. Markup that does not build keeps the last good preview, and says so.
class GuiAssetEditorPage : CodeAssetPage
{
	public const String cMarkupPath = "Editor/GuiPage.gml";

	/// What the page edits: a document (its markup, previewed as it is) or a sheet (its CSS,
	/// previewed over markup of the page's own).
	public enum Kind : uint8
	{
		case Document;
		case StyleSheet;
	}

	private Kind mKind;
	/// The RUNTIME context's; null in a headless host.
	private GuiSubsystem mGui = null;
	/// A reference of the page's own (the stage holds another).
	private Viewport mViewport = null ~ { if (_ != null) _.ReleaseRef(); };
	/// OWNED through its reference: in the runtime context's GUI, never in a tier.
	private Sedulous.GUI.SceneRoot mPreviewRoot = null ~ { if (_ != null) _.ReleaseRef(); };
	/// A sheet's preview markup (the markup's; null on a document's page).
	private CodeEditor mMarkup = null;
	private uint32 mMarkupListener = 0;
	private bool mStale = false;

	public this(EditorContext context, AssetPageServices services, Instance instance, Kind kind)
		: base(context, services, instance, (kind == .Document) ? typeof(GuiDocumentAsset) : typeof(GuiStyleSheetAsset), cMarkupPath)
	{
		mKind = kind;
		mGui = (Services.Host != null) ? Services.Host.Context.GetSubsystem<GuiSubsystem>() : null;

		// A sheet's preview markup: the page's, kept for the sheet in the project's editor settings
		// (first from what an older page kept on the asset, else a little of everything).
		mMarkup = Find<CodeEditor>("gui-preview-markup");
		let document = Find<ButtonBase>("gui-preview-document");
		if (mKind == .StyleSheet)
		{
			let markup = scope String();
			if (let store = Context.ProjectEditorSettings)
			{
				if (let kept = store.Find<GuiSheetPreviewSettings>())
				{
					if (let sheet = kept.Find(InstanceId))
						markup.Set(sheet.Markup);
				}
			}
			if (markup.IsEmpty)
			{
				if (let sheet = ObjectAs<GuiStyleSheetAsset>())
					markup.Set(sheet.PreviewMarkup);
			}
			if (markup.IsEmpty)
				markup.Set(GuiPages.cStockPreviewMarkup);
			if (mMarkup != null)
			{
				mMarkup.SetText(markup);
				if (Services.Languages != null)
					mMarkup.SetLanguage(Services.Languages.Find("xml"));
				// Its edits are the page's preview, not the asset: checked again, never dirtying it.
				mMarkupListener = mMarkup.Document.AddChangeListener(new [=this] (change) => { CheckSoon(); });
			}
			if (document != null)
				document.SetOnClick(new [=this] () => { PickPreviewDocument(); });
		}
		else
		{
			// A document is previewed as it is: no markup of the page's, no document to choose.
			if (let side = Find<Node>("gui-preview-side"))
			{
				if (let pane = Find<Node>("gui-markup-pane"))
					side.RemoveChild(pane);
			}
			mMarkup = null;
			if (document != null)
				document.Displayed = false;
		}

		// The preview: a viewport of the page's, the runtime's GUI drawing into it each frame.
		mViewport = new Viewport();
		mViewport.AddClass("preview-view"); // fills its stage, as the preview pages' viewports do
		mViewport.ClearColor = .(0.313f, 0.332f, 0.366f, 1.0f); // sRGB, like every GUI colour
		mViewport.OnRender = new [=this] (view, encoder, frameIndex) => { RenderPreview(view, encoder, frameIndex); };
		if (let stage = Find<Node>("gui-preview-stage"))
			stage.AddChild(mViewport);
		if (Services.Gui != null)
			mViewport.HostIn(Services.Gui);

		OpenCode((mKind == .Document) ? "xml" : "css");
	}

	public ~this()
	{
		if (mMarkup != null)
			mMarkup.Document.RemoveChangeListener(mMarkupListener);
		if (mViewport != null)
			mViewport.OnRender = null; // it may outlive the page in the content's tree
	}

	public override void OnClose()
	{
		DropPreviewRoot(); // before the runtime's GUI goes
		if (mViewport != null)
			mViewport.OnRender = null;
	}

	/// A sheet's preview over a copy of document `id`'s markup (the page's from then on).
	public void PreviewOverDocument(Guid id)
	{
		if ((mMarkup == null) || id.IsNil || (Context.Project == null))
			return;
		let instance = Context.Project.SourceDb.GetInstance(id);
		let object = (instance != null) ? instance.ReadObject() : null;
		defer delete object;
		let document = object as GuiDocumentAsset;
		if ((document == null) || document.FileName.IsEmpty)
			return; // an unlinked document has no markup to preview over
		let text = scope String();
		if (System.IO.File.ReadAllText(PathJoin(Context.Project.SourcesRoot(.. scope .()), document.FileName.Value, .. scope .()), text, true) case .Err)
			return;
		// Copied once: the page's to change from now on (the document is not touched).
		mMarkup.SetText(text);
		CheckNow();
	}

	// === For tests ===

	public Kind AssetKind => mKind;
	/// What the preview shows now (null before one built, or without the runtime's GUI): BORROWED.
	public Sedulous.GUI.SceneRoot PreviewRoot => mPreviewRoot;
	/// Whether the preview shows an older version than the code (the code does not build).
	public bool PreviewStale => mStale;
	/// A sheet's preview markup, appended (nothing on a document's page).
	public void PreviewMarkup(String outText)
	{
		if (mMarkup != null)
			mMarkup.GetText(outText);
	}
	public CodeEditor PreviewMarkupEditor => mMarkup;

	protected override void CheckCode(StringView text, List<CodeProblem> outProblems)
	{
		// What the cook would report, on the lines it is about; a sheet's preview markup's under its name.
		let found = scope List<GuiDiagnostic>();
		defer { ClearAndDeleteItems!(found); }
		var builds = true;
		if (mKind == .Document)
			builds = GuiPipeline.ValidateDocument(text, found);
		else
			GuiPipeline.ValidateStyleSheet(text, found);
		GuiPages.AddProblems(found, "", outProblems);
		if (mKind == .StyleSheet)
		{
			let markup = PreviewMarkup(.. scope .());
			let markupFound = scope List<GuiDiagnostic>();
			defer { ClearAndDeleteItems!(markupFound); }
			builds = GuiPipeline.ValidateDocument(markup, markupFound);
			GuiPages.AddProblems(markupFound, GuiPages.cPreviewMarkupName, outProblems);
			// Its own lines marked in its own editor.
			if (mMarkup != null)
			{
				let marks = scope List<CodeDiagnostic>();
				defer { ClearAndDeleteItems!(marks); }
				let doc = mMarkup.Document;
				for (let d in markupFound)
				{
					let line = (uint32)((d.Line > 0) ? d.Line - 1 : 0);
					let end = (line < doc.LineCount) ? (uint32)doc.LineText(line).Length : 0u;
					marks.Add(new CodeDiagnostic(.(.(line, 0), .(line, end)), (d.Level == .Error) ? CodeSeverity.Error : .Warning, d.Message));
				}
				mMarkup.SetDiagnostics(marks);
			}
			KeepPreviewMarkup(markup);
		}
		RebuildPreview(text, builds);
	}

	private void RenderPreview(Viewport view, ICommandEncoder encoder, int32 frameIndex)
	{
		// The target defined every frame (the editor samples it), then the preview over it.
		var pass = RenderPassDesc();
		var color = ColorAttachment();
		color.View = view.ColorView;
		color.LoadOp = .Clear;
		color.StoreOp = .Store;
		color.ClearValue = view.LinearClearColor;
		pass.ColorAttachments.Add(color);
		if (let clear = encoder.BeginRenderPass(pass))
			clear.End();
		if ((mGui == null) || (mPreviewRoot == null) || (view.RenderWidth == 0) || (view.RenderHeight == 0))
			return;
		mGui.RenderPreview(mPreviewRoot, encoder, view.ColorView, view.ColorFormat, view.RenderWidth, view.RenderHeight, (uint32)frameIndex);
	}

	private void RebuildPreview(StringView text, bool builds)
	{
		if (!builds)
		{
			mStale = mPreviewRoot != null; // the last good one stays
			ShowPreviewState();
			return;
		}
		if (mGui != null)
		{
			let markup = scope String();
			if (mKind == .Document)
				markup.Set(text);
			else
				PreviewMarkup(markup);
			let root = mGui.CreatePreview(markup, (mKind == .StyleSheet) ? text : "");
			if (root != null)
			{
				DropPreviewRoot();
				mPreviewRoot = root; // its reference is the page's
			}
		}
		mStale = false;
		ShowPreviewState();
	}

	private void ShowPreviewState()
	{
		if (let stale = Find<Node>("gui-preview-stale"))
			stale.Displayed = mStale;
		let showing = mPreviewRoot != null;
		if (let stage = Find<Node>("gui-preview-stage"))
			stage.Displayed = showing;
		if (let empty = Find<Node>("gui-preview-empty"))
			empty.Displayed = !showing;
		if (!showing)
		{
			if (let why = Find<Sedulous.GUI.Label>("gui-preview-empty-text"))
				why.Text = (mGui == null) ? "The runtime has no GUI: nothing draws a preview." : "It shows once the markup builds.";
		}
	}

	private void KeepPreviewMarkup(StringView markup)
	{
		let store = Context.ProjectEditorSettings;
		if ((store == null) || (mMarkup == null) || InstanceId.IsNil)
			return;
		let kept = store.Section<GuiSheetPreviewSettings>();
		var mine = kept.Find(InstanceId);
		if ((mine != null) && (mine.Markup == markup))
			return; // unchanged: nothing to write
		if (mine == null)
		{
			mine = new GuiSheetPreview();
			mine.Asset = InstanceId;
			kept.Sheets.Add(mine);
		}
		mine.Markup.Set(markup);
		store.MarkChanged<GuiSheetPreviewSettings>();
		Context.RequestProjectEditorSettingsSave();
	}

	private void PickPreviewDocument()
	{
		let refs = Services.Refs;
		if ((refs == null) || (refs.Pick == null))
			return;
		String[1] types = .("GuiDocumentAsset");
		refs.Pick(types, .(), new [=this] (id) => { PreviewOverDocument(id); });
	}

	private void DropPreviewRoot()
	{
		if (mPreviewRoot == null)
			return;
		mPreviewRoot.ReleaseRef();
		mPreviewRoot = null;
	}
}
