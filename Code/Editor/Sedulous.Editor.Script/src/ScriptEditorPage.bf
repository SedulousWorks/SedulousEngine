using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Runtime.Client;
using Sedulous.Script;
using Sedulous.Script.Pipeline;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Script;

/// The script text page over ScriptSourceDocument: a code editor with the language's
/// lexer, bound API completion and an API browser, a debounced compile check in the
/// margin and the error pane, breakpoints shared with the context and the execution line
/// followed while a run is paused in this file.
class ScriptEditorPage : UIEditorPage
{
	/// Borrowed.
	private EditorContext mContext;
	private ScriptSourceDocument mDoc = new .() ~ delete _;
	private String mTitle = new .() ~ delete _;
	private float mValidateDelay = 0.0f;
	/// The execution point stamp last synced.
	private uint64 mExecutionVersionSeen = uint64.MaxValue;
	/// The one bound API source, for completion and the browser.
	private ScriptApiSurface mApiSurface = new .() ~ delete _;
	/// Outlives the editor that borrows it.
	private ScriptApiCompletionProvider mApiProvider = new .() ~ delete _;
	private ScriptApiBrowserView mApiBrowser = new .() ~ delete _;

	/// Borrowed: the content owns them.
	private View mContent = null ~ { if (_ != null) _.ReleaseRef(); };
	private CodeEditView mEditor = null;
	private Label mStatus = null;
	private EditText mErrorView = null;

	/// `surface` is the script surface the API is described against, borrowed; null leaves
	/// completion and the browser empty.
	public this(EditorContext context, Instance instance, ScriptSurface surface)
	{
		mContext = context;
		mTitle.Set(instance.Name);
		InstanceId = instance.Id;
		let sourcesRoot = scope String();
		if (mContext.Project != null)
			mContext.Project.SourcesRoot(sourcesRoot);
		let language = scope String();
		let object = instance.ReadObject();
		defer delete object;
		if (let asset = object as ScriptClassAsset)
		{
			mDoc.Bind(sourcesRoot, asset.FileName.Value, asset.Language);
			language.Set(asset.Language);
		}
		mDoc.Load().IgnoreError(); // an unreadable file just leaves an empty buffer

		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 4.0f;
		mEditor = new CodeEditView();
		mEditor.SetLexer(CodeLexerRegistry.Create(language));
		mApiSurface.SetLanguage(language);
		mApiSurface.SetSurface(surface);
		mApiProvider.SetSurface(mApiSurface);
		mEditor.AddCompletionProvider(mApiProvider);
		mEditor.SetText(mDoc.Source);
		mEditor.OnTextChanged.Add(new [=this]() =>
			{
				mDoc.SetSource(mEditor.GetText(.. scope .()));
				MarkDirty();
				mValidateDelay = 0.6f; // debounce a background compile check
			});
		for (let breakpoint in context.Breakpoints)
		{
			if ((breakpoint.File == mDoc.FileName) && (breakpoint.Line >= 1))
				mEditor.Document.SetMarker(breakpoint.Line - 1, .Breakpoint);
		}
		mEditor.OnBreakpointToggled.Add(new [=this](line, on) => { mContext.ToggleBreakpoint(mDoc.FileName, line + 1); });
		mEditor.HoverValueProvider = new [=this](identifier, outText) =>
			{
				let point = mContext.ScriptExecution;
				if (!point.Active || (point.File != mDoc.FileName) || (mContext.ScriptValueProbe == null))
					return;
				mContext.ScriptValueProbe(identifier, outText);
			};
		var growMatch = LayoutStyle();
		growMatch.FlexGrow = 1.0f;
		growMatch.Width = SizeSpec.Match();
		column.AddView(mEditor, growMatch);

		let statusRow = new FlexLayout();
		statusRow.Direction = .Horizontal;
		statusRow.Spacing = 6.0f;
		mStatus = new Label("");
		mStatus.FontSize.Value = 12.0f;
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		statusRow.AddView(mStatus, grow);
		let apiToggle = new ToggleButton("API");
		apiToggle.OnCheckedChanged.Add(new [=this](toggle, isChecked) =>
			{
				mApiBrowser.Root.Visibility = isChecked ? Sedulous.UI.Visibility.Visible : Sedulous.UI.Visibility.Gone;
				mApiBrowser.Root.Invalidate();
			});
		statusRow.AddView(apiToggle);
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		column.AddView(statusRow, match);

		mErrorView = new EditText();
		mErrorView.Multiline.Value = true;
		mErrorView.IsReadOnly.Value = true;
		var errorStyle = LayoutStyle();
		errorStyle.Width = SizeSpec.Match();
		errorStyle.Height = SizeSpec.Fixed(Unit.Dp(96));
		column.AddView(mErrorView, errorStyle);

		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 4.0f;
		var growHeight = LayoutStyle();
		growHeight.FlexGrow = 1.0f;
		growHeight.Height = SizeSpec.Match();
		row.AddView(column, growHeight);
		mApiBrowser.SetSurface(mApiSurface);
		mApiBrowser.OnInsert = new [=this](text) => { mEditor.InsertAtCursor(text); };
		mApiBrowser.Root.Visibility = .Gone;
		var browserStyle = LayoutStyle();
		browserStyle.Width = SizeSpec.Fixed(Unit.Dp(300));
		browserStyle.Height = SizeSpec.Match();
		row.AddView(mApiBrowser.Root, browserStyle);
		mContent = row;
		RefreshCompileStatus(); // the page opens with live state
	}

	public override StringView Title => mTitle;
	public override View ContentView => mContent;
	public ScriptSourceDocument Document => mDoc;

	public override Result<void, ErrorCode> Save()
	{
		let written = mDoc.Save();
		if (written case .Ok)
		{
			ClearDirty();
			mContext.RequestCook(false);
			RefreshCompileStatus();
			if (mDoc.LastCompileOk)
				mContext.Notify(.Success, "Script saved - recooking");
			else
				mContext.Notify(.Warning, "Script saved with compile errors - last good kept");
		}
		return written;
	}

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		mApiBrowser.Update(); // a filter edit only marks it dirty
		if (mValidateDelay > 0.0f)
		{
			mValidateDelay -= dt;
			if (mValidateDelay <= 0.0f)
				RefreshCompileStatus();
		}
		if (mExecutionVersionSeen != mContext.ScriptExecutionVersion)
		{
			mExecutionVersionSeen = mContext.ScriptExecutionVersion;
			let point = mContext.ScriptExecution;
			if (point.Active && (point.File == mDoc.FileName) && (point.Line >= 1))
			{
				mEditor.Document.SetExecutionLine(point.Line - 1);
				mEditor.ScrollToLine(point.Line - 1);
			}
			else
			{
				mEditor.Document.SetExecutionLine(-1);
				mEditor.Invalidate();
			}
		}
	}

	/// Compile checks the buffer: errors into the margin and the pane, the class into the
	/// status line.
	private void RefreshCompileStatus()
	{
		let ok = mDoc.Validate();
		let errors = mDoc.Errors;
		let diagnostics = new List<CodeDiagnostic>();
		for (let e in errors)
			diagnostics.Add(new CodeDiagnostic(true, (e.Line > 0) ? e.Line - 1 : 0, e.Message)); // the check path only reports compile errors
		mEditor.Document.SetDiagnostics(diagnostics);
		mEditor.Invalidate();
		if (ok)
		{
			let line = scope String("Compiled OK");
			if (!mDoc.ClassName.IsEmpty)
				line.AppendF(" - class {}", mDoc.ClassName);
			mStatus.SetText(line);
			mErrorView.SetText("");
			return;
		}
		mStatus.SetText(scope $"{errors.Count} compile error{(errors.Count == 1) ? "" : "s"}");
		let detail = scope String();
		for (let e in errors)
		{
			if (!detail.IsEmpty)
				detail.Append('\n');
			detail.Append(e.Module.IsEmpty ? mDoc.FileName : StringView(e.Module));
			if (e.Line > 0)
				detail.AppendF(":{}", e.Line);
			detail.AppendF(": {}", e.Message);
		}
		mErrorView.SetText(detail);
	}
}
