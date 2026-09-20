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

/// The UI document page: the linked .sml in a code editor with XML highlighting, tag
/// completion and a well-formedness margin, previewed live on the runtime UI context after
/// a short debounce. Save writes the file back and re-cooks.
class UIDocumentEditorPage : UIEditorPage
{
	/// Borrowed.
	private EditorContext mContext;
	private String mTitle = new .() ~ delete _;
	private String mMarkup = new .() ~ delete _;
	/// Counts down after a keystroke; the preview rebuilds when it reaches zero.
	private float mPreviewDelay = 0.0f;
	/// Borrowed by the editor.
	private MarkupCompletionProvider mMarkupProvider = new .() ~ delete _;
	private UIPreviewSurface mPreview = null ~ delete _;

	/// Borrowed: the content owns them.
	private View mContent = null ~ { if (_ != null) _.ReleaseRef(); };
	private CodeEditView mEditor = null;
	private Label mStatus = null;

	public this(EditorContext context, IApplicationHost host, UIHost uiHost, Instance instance)
	{
		mContext = context;
		mTitle.Set(instance.Name);
		InstanceId = instance.Id;
		mPreview = new UIPreviewSurface(host, uiHost);

		let object = instance.ReadObject();
		defer delete object;
		if (let asset = object as UIDocumentAsset)
		{
			if (!asset.FileName.IsEmpty)
				LinkedSource.Read(mContext, asset.FileName.Value, mMarkup);
			else
				GlobalLog(.Error, "Editor: UI document has no linked source file, the page opens empty (re-import the .sml)");
		}

		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 8.0f;
		mEditor = new CodeEditView();
		mEditor.AllowBreakpoints = false; // markup has no debugger; keep the margin quiet
		mEditor.SetLexer(new XmlLexer());
		mEditor.CompletionTriggerCharacters.Set("<"); // tags open the popup
		mEditor.AddCompletionProvider(mMarkupProvider);
		mEditor.SetText(mMarkup);
		mEditor.OnTextChanged.Add(new [=this]() =>
			{
				mEditor.GetText(mMarkup);
				MarkDirty();
				mPreviewDelay = 0.35f; // rebuild shortly after the typing stops
			});
		var growMatch = LayoutStyle();
		growMatch.FlexGrow = 1.0f;
		growMatch.Height = SizeSpec.Match();
		row.AddView(mEditor, growMatch);

		let right = new FlexLayout();
		right.Direction = .Vertical;
		right.Spacing = 4.0f;
		mStatus = new Label("");
		mStatus.FontSize.Value = 12.0f;
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		right.AddView(mStatus, match);
		var fill = LayoutStyle();
		fill.Width = SizeSpec.Match();
		fill.FlexGrow = 1.0f;
		right.AddView(mPreview.View, fill);
		row.AddView(right, growMatch);
		mContent = row;
		RebuildPreview();
	}

	public override StringView Title => mTitle;
	public override View ContentView => mContent;
	public StringView Markup => mMarkup;

	/// Writes the linked file, then the asset so the cook sees a change.
	public override Result<void, ErrorCode> Save()
	{
		let instance = (mContext.Project != null) ? mContext.Project.SourceDb.GetInstance(InstanceId) : null;
		if (instance == null)
			return .Err(.NotFound);
		let object = instance.ReadObject();
		defer delete object;
		let asset = object as UIDocumentAsset;
		if (asset == null)
			return .Err(.NotFound);
		if (asset.FileName.IsEmpty)
		{
			GlobalLog(.Error, "Editor: UI document has no linked source file, save refused");
			return .Err(.NotSupported);
		}
		if (LinkedSource.Write(mContext, asset.FileName.Value, mMarkup) case .Err(let error))
			return .Err(error);
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
		MarkupDiagnostics.Apply(mMarkup, mEditor);
		let warnings = scope List<String>();
		defer { ClearAndDeleteItems!(warnings); }
		let parsed = MarkupLoader.LoadFromString(mMarkup, null, warnings);
		if (parsed == null)
		{
			mStatus.SetText("Parse FAILED - showing the last good preview.");
			return;
		}
		parsed.ReleaseRef();
		if (!mPreview.HasSubsystem)
		{
			mStatus.SetText("No runtime UI subsystem - preview unavailable.");
			return;
		}
		if (!mPreview.Rebuild(mMarkup))
		{
			mStatus.SetText("Parse FAILED - showing the last good preview.");
			return;
		}
		if (warnings.IsEmpty)
			mStatus.SetText("OK");
		else
			mStatus.SetText(scope $"Warnings: {warnings[0]}{(warnings.Count > 1) ? " (+more)" : ""}");
	}
}
