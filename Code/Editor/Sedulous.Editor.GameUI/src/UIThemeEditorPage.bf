using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Runtime.Client;
using Sedulous.Graphics;
using Sedulous.UI;
using Sedulous.UI.Runtime;
using Sedulous.UI.Toolkit;
using Sedulous.UI.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.GameUI;

/// The UI theme page: the linked .sss in a code editor, a preview document (stock, or
/// copied from a picked UI document and then the user's to tweak, persisted on the asset)
/// in a second editor, and the document rendered under the theme on the runtime context.
class UIThemeEditorPage : UIEditorPage
{
	/// What the theme previews against out of the box.
	public const String cStockPreviewMarkup = """
		<Panel padding="16">
		  <Label text="Heading" class="heading"/>
		  <Label text="Body text sample."/>
		  <Button text="Primary" class="primary"/>
		  <Button text="Default"/>
		</Panel>
		""";

	/// Borrowed.
	private EditorContext mContext;
	private String mTitle = new .() ~ delete _;
	/// The theme, the linked .sss, the SAVED asset content.
	private String mStylesheet = new .() ~ delete _;
	/// Editor-only scaffolding, persisted on the asset, never cooked.
	private String mPreviewMarkup = new .() ~ delete _;
	private float mPreviewDelay = 0.0f;
	/// Borrowed by the preview editor.
	private MarkupCompletionProvider mMarkupProvider = new .() ~ delete _;
	private UIPreviewSurface mPreview = null ~ delete _;

	/// Borrowed: the content owns them.
	private View mContent = null ~ { if (_ != null) _.ReleaseRef(); };
	private CodeEditView mEditor = null;
	private CodeEditView mPreviewEditor = null;
	private Button mPickButton = null;
	private Label mStatus = null;

	public this(EditorContext context, IApplicationHost host, UIHost uiHost, Instance instance)
	{
		mContext = context;
		mTitle.Set(instance.Name);
		InstanceId = instance.Id;
		mPreview = new UIPreviewSurface(host, uiHost);

		let object = instance.ReadObject();
		defer delete object;
		if (let asset = object as UIThemeAsset)
		{
			if (!asset.FileName.IsEmpty)
				LinkedSource.Read(mContext, asset.FileName.Value, mStylesheet);
			else
				GlobalLog(.Error, "Editor: UI theme has no linked source file, the page opens empty (re-import the .sss)");
			mPreviewMarkup.Set(asset.PreviewMarkup);
		}
		if (mPreviewMarkup.IsEmpty)
			mPreviewMarkup.Set(cStockPreviewMarkup);

		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 8.0f;
		mEditor = new CodeEditView();
		mEditor.AllowBreakpoints = false;
		mEditor.SetText(mStylesheet);
		mEditor.OnTextChanged.Add(new [=this]() =>
			{
				mEditor.GetText(mStylesheet);
				MarkDirty();
				mPreviewDelay = 0.35f;
			});
		var growMatch = LayoutStyle();
		growMatch.FlexGrow = 1.0f;
		growMatch.Height = SizeSpec.Match();
		row.AddView(mEditor, growMatch);

		let right = new FlexLayout();
		right.Direction = .Vertical;
		right.Spacing = 4.0f;
		let bar = new FlexLayout();
		bar.Direction = .Horizontal;
		bar.Spacing = 8.0f;
		mPickButton = new Button("Preview Document...");
		mPickButton.OnClick.Add(new [=this](btn) => { PickPreviewDocument(); });
		bar.AddView(mPickButton);
		mStatus = new Label("");
		mStatus.FontSize.Value = 12.0f;
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		bar.AddView(mStatus, grow);
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		right.AddView(bar, match);

		mPreviewEditor = new CodeEditView();
		mPreviewEditor.AllowBreakpoints = false;
		mPreviewEditor.SetLexer(new XmlLexer());
		mPreviewEditor.CompletionTriggerCharacters.Set("<");
		mPreviewEditor.AddCompletionProvider(mMarkupProvider);
		mPreviewEditor.SetText(mPreviewMarkup);
		mPreviewEditor.OnTextChanged.Add(new [=this]() =>
			{
				mPreviewEditor.GetText(mPreviewMarkup);
				MarkDirty(); // the preview markup is persisted on the asset
				mPreviewDelay = 0.35f;
			});
		var fill = LayoutStyle();
		fill.Width = SizeSpec.Match();
		fill.FlexGrow = 1.0f;
		right.AddView(mPreviewEditor, fill);
		var render = LayoutStyle();
		render.Width = SizeSpec.Match();
		render.FlexGrow = 2.0f; // the render gets the lion's share of the right column
		right.AddView(mPreview.View, render);
		row.AddView(right, growMatch);
		row.AddRef();
		mContent = row;
		RebuildPreview();
	}

	public override StringView Title => mTitle;
	public override View ContentView => mContent;
	public StringView Stylesheet => mStylesheet;
	public StringView PreviewMarkup => mPreviewMarkup;

	/// Writes the linked file, then the asset with the preview markup on it.
	public override Result<void, ErrorCode> Save()
	{
		let instance = (mContext.Project != null) ? mContext.Project.SourceDb.GetInstance(InstanceId) : null;
		if (instance == null)
			return .Err(.NotFound);
		let object = instance.ReadObject();
		defer delete object;
		let asset = object as UIThemeAsset;
		if (asset == null)
			return .Err(.NotFound);
		if (asset.FileName.IsEmpty)
		{
			GlobalLog(.Error, "Editor: UI theme has no linked source file, save refused");
			return .Err(.NotSupported);
		}
		if (LinkedSource.Write(mContext, asset.FileName.Value, mStylesheet) case .Err(let error))
			return .Err(error);
		asset.PreviewMarkup.Set(mPreviewMarkup);
		let written = instance.WriteObject(asset);
		if (written case .Ok)
		{
			ClearDirty();
			mContext.RequestCook(false);
		}
		return written;
	}

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		mPreview.EnsureBound();
		if (mPreviewDelay > 0.0f)
		{
			mPreviewDelay -= dt;
			if (mPreviewDelay <= 0.0f)
				RebuildPreview();
		}
	}

	public override void OnAfterSceneRender(IApplicationHost host, ref FrameContext frame) => mPreview.Render(ref frame);

	public override void OnClose() => mPreview.Shutdown();

	private void RebuildPreview()
	{
		MarkupLoader.Initialize();
		MarkupDiagnostics.Apply(mPreviewMarkup, mPreviewEditor);
		if (!mPreview.HasSubsystem)
		{
			mStatus.SetText("No runtime UI subsystem - preview unavailable.");
			return;
		}
		let loader = scope StyleSheetLoader();
		loader.SetPalette(ThemePalette.Dark());
		let sheet = loader.Load(mStylesheet);
		if (!mPreview.Rebuild(mPreviewMarkup, sheet))
		{
			mStatus.SetText("Preview markup parse FAILED - showing the last good preview.");
			return;
		}
		mStatus.SetText((sheet != null) ? "OK" : "Stylesheet parse FAILED - preview uses the default theme.");
	}

	/// Copies a UI document's markup in as the preview, once; it is then the user's to tweak.
	private void PickPreviewDocument()
	{
		if ((mContext.Project == null) || (mContent == null) || (mContent.Context == null))
			return;
		let dialog = new AssetPickerDialog(mContext, scope StringView[]("UIDocumentAsset"));
		dialog.OnPicked = new [=this](picked) =>
			{
				if (picked.IsNil || (mContext.Project == null))
					return;
				let inst = mContext.Project.SourceDb.GetInstance(picked);
				if (inst == null)
					return;
				let object = inst.ReadObject();
				defer delete object;
				let doc = object as UIDocumentAsset;
				if ((doc == null) || doc.FileName.IsEmpty)
					return; // an unlinked document has no text to preview against
				LinkedSource.Read(mContext, doc.FileName.Value, mPreviewMarkup);
				mPreviewEditor.SetText(mPreviewMarkup);
				MarkDirty(); // persisted on the theme asset
				mPreviewDelay = 0.05f; // rebuild promptly
			};
		dialog.Show(mContent.Context);
	}
}
