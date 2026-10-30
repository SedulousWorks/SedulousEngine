using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Runtime.Client;
using Sedulous.Script;
using Sedulous.Script.Pipeline;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Script;

/// A behaviour script's code on the GUI from its markup (Data/Editor/ScriptPage.gml; Raptor's
/// editor-gui spec, 5.4, layer 6, part 3), on the code pages' base (the source file, its language's
/// colours, a check a moment after each edit into the problems list, one history, Save then a cook).
/// Its check compiles the code as the cook does, running none of it (a failing one leaves the last
/// good class running); completion and hover come from what the runtime binds for its language
/// (ScriptLanguageService), which the API browser shows as a tree beside the code, opened from the
/// page's bar. The gutter's breakpoints are the editor's (a Game run applies them), and while a run
/// is paused in this script its line is marked and a name's value shows on hover.
///
/// Backend-neutral: the page never names a language. Its cook, its API and its colours are found by
/// the asset's language id.
class ScriptEditorPage : CodeAssetPage
{
	public const String cMarkupPath = "Editor/ScriptPage.gml";

	/// The compile check, as the cook checks.
	private ScriptSourceDocument mDoc = new .() ~ delete _;
	private ScriptApiSurface mSurface = new .() ~ delete _;
	/// The code editor borrows it: cleared from it in the destructor.
	private ScriptLanguageService mService = null ~ delete _;
	private ScriptApiTree mApiTree = new .() ~ delete _;
	private String mApiSearch = new .() ~ delete _;
	private bool mApiShown = false;
	private bool mApiBuilt = false;
	private TreeModel mApiModel = null ~ delete _;
	/// The browser, out of the splitter while closed: a reference of the page's own.
	private Node mApiPane = null ~ { if (_ != null) _.ReleaseRef(); };
	/// Borrowed, all: the markup's.
	private Splitter mBody = null;
	private TreeView mApiView = null;
	private ButtonBase mApiToggle = null;
	/// A model node's tree node, by the model's id.
	private List<int32> mApiNodes = new .() ~ delete _;
	/// The gutter's marks.
	private List<uint32> mBreakpoints = new .() ~ delete _;
	/// The paused line's mark (0: none).
	private uint32 mExecutionMark = 0;
	private uint64 mExecutionSeen = uint64.MaxValue;

	/// `surface` is the script surface the API is described against, borrowed; null leaves
	/// completion and the browser without the bound API.
	public this(EditorContext context, AssetPageServices services, Instance instance, ScriptSurface surface)
		: base(context, services, instance, typeof(ScriptClassAsset), cMarkupPath)
	{
		HideAssetRows(); // the code is the page: no grid
		if (let asset = ObjectAs<ScriptClassAsset>())
		{
			let sourcesRoot = scope String();
			if (context.Project != null)
				context.Project.SourcesRoot(sourcesRoot);
			mDoc.Bind(sourcesRoot, asset.FileName.Value, asset.Language);
		}
		mSurface.SetLanguage(mDoc.Language);
		mSurface.SetSurface(surface);
		let language = (Services.Languages != null) ? Services.Languages.Find(mDoc.Language) : null;
		mService = new ScriptLanguageService(mSurface, language);
		// While a run is paused in this script, a name's value on hover.
		mService.SetValueProbe(new [=this] (name, outText) =>
			{
				let point = Context.ScriptExecution;
				if (!point.Active || (point.File != mDoc.FileName) || (Context.ScriptValueProbe == null))
					return;
				Context.ScriptValueProbe(name, outText);
			});
		if (let code = Code)
		{
			code.LanguageService = mService;
			// The breakpoints are the editor's (a Game run applies them; the store is 1-based).
			for (let breakpoint in context.Breakpoints)
			{
				if ((breakpoint.File == mDoc.FileName) && (breakpoint.Line >= 1))
					mBreakpoints.Add(code.AddMarker((uint32)(breakpoint.Line - 1), "breakpoint"));
			}
			code.SetOnGutterClick(new [=this] (line) => { ToggleBreakpoint(line); });
		}

		// The API browser: its parts found while it is in the page, then out of the splitter until
		// it is opened.
		mBody = Find<Splitter>("script-body");
		mApiPane = Find<Node>("script-api-pane");
		if (mApiPane != null)
			mApiPane.AddRef();
		mApiView = Find<TreeView>("script-api-tree");
		let apiSearch = Find<TextField>("script-api-search");
		if (mApiView != null)
		{
			mApiModel = new TreeModel();
			mApiView.Model = mApiModel;
			mApiView.SetOnActivated(new [=this] (index) =>
				{
					if (index.IsValid)
						InsertApi((int32)index.InternalId);
				});
		}
		if (apiSearch != null)
			apiSearch.SetOnTextChanging(new [=this] (text) => { SearchApi(text); });
		if ((mBody != null) && (mApiPane != null))
			mBody.RemoveChild(mApiPane);
		mApiToggle = Find<ButtonBase>("script-api");
		if (mApiToggle != null)
			mApiToggle.SetOnClick(new [=this] () => { ShowApi(!mApiShown); });

		OpenCode(mDoc.Language);
	}

	public ~this()
	{
		if (mApiView != null)
			mApiView.Model = null;
		if (let code = Code)
			code.LanguageService = null;
	}

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		base.OnUpdate(host, dt);
		if (mExecutionSeen != Context.ScriptExecutionVersion)
		{
			mExecutionSeen = Context.ScriptExecutionVersion;
			ShowExecution();
		}
	}

	/// Opens the API browser beside the code, or closes it.
	public void ShowApi(bool show)
	{
		mApiShown = show;
		if (mApiToggle != null)
			mApiToggle.Checked = show;
		if ((mBody == null) || (mApiPane == null))
			return;
		let isIn = mApiPane.Parent == mBody;
		if (show && !isIn)
			mBody.AddChild(mApiPane);
		else if (!show && isIn)
			mBody.RemoveChild(mApiPane);
		// Built the first time it opens: the API is described by a runtime made for it.
		if (show && !mApiBuilt)
		{
			mApiBuilt = true;
			ShowApiTree();
		}
	}

	public bool ApiShown => mApiShown;

	/// Keeps the API rows whose type or member holds `text` (empty: every one).
	public void SearchApi(StringView text)
	{
		mApiSearch.Set(text);
		mApiSearch.Trim();
		if (mApiBuilt)
			ShowApiTree();
	}

	/// Types the name of the API browser's row `modelNode` (its tree model's id) at the caret.
	public void InsertApi(int32 modelNode)
	{
		if ((modelNode < 0) || (modelNode >= mApiNodes.Count))
			return;
		let node = mApiNodes[modelNode];
		let code = Code;
		if ((node < 0) || (code == null) || code.IsReadOnly)
			return;
		code.Type(mApiTree.Nodes[node].InsertText);
		code.RequestFocus();
	}

	// === For tests ===

	public StringView Language => mDoc.Language;
	public StringView ClassName => mDoc.ClassName;
	public ScriptApiTree ApiTree => mApiTree;
	public TreeModel ApiModel => mApiModel;
	public ScriptLanguageService Service => mService;

	/// The gutter's breakpoint on `line` (from 0) set, or taken away.
	public void ToggleBreakpoint(uint32 line)
	{
		let code = Code;
		if ((code == null) || mDoc.FileName.IsEmpty)
			return;
		Context.ToggleBreakpoint(mDoc.FileName, (int32)line + 1);
		for (int i < mBreakpoints.Count)
		{
			if (code.MarkerLine(mBreakpoints[i]) == line)
			{
				code.RemoveMarker(mBreakpoints[i]);
				mBreakpoints.RemoveAt(i);
				return;
			}
		}
		mBreakpoints.Add(code.AddMarker(line, "breakpoint"));
	}

	public bool HasBreakpointMark(uint32 line) => (Code != null) && Code.HasMarker(line, "breakpoint");

	/// "No problems: compiles class Player": the class the check compiled (the old page's).
	protected override void CleanSummary(String outText)
	{
		if (!mDoc.ClassName.IsEmpty)
			outText.AppendF("No problems: compiles class {}", mDoc.ClassName);
	}

	protected override void CheckCode(StringView text, List<CodeProblem> outProblems)
	{
		// Compiled as the cook compiles it, none of it run.
		mDoc.SetSource(text);
		mDoc.Validate();
		for (let e in mDoc.Errors)
		{
			let own = e.Module.IsEmpty || (e.Module == mDoc.FileName);
			outProblems.Add(new CodeProblem(.Error, e.Message, own ? "" : (StringView)e.Module, (e.Line > 0) ? (uint32)(e.Line - 1) : 0,
				(e.Column > 0) ? (uint32)(e.Column - 1) : 0, e.Column > 0));
		}
	}

	// A Game run paused in this script: its line marked and brought into view; else no mark.
	private void ShowExecution()
	{
		let code = Code;
		if (code == null)
			return;
		if (mExecutionMark != 0)
		{
			code.RemoveMarker(mExecutionMark);
			mExecutionMark = 0;
		}
		let point = Context.ScriptExecution;
		if (!point.Active || (point.File != mDoc.FileName) || (point.Line < 1))
			return;
		let line = (uint32)(point.Line - 1);
		mExecutionMark = code.AddMarker(line, "execution");
		code.SetCaret(.(line, 0));
		code.ScrollToCaret();
	}

	private void ShowApiTree()
	{
		mApiTree.Build(mSurface.Types, mApiSearch, scope (type) => mSurface.IsEditorOnly(type));
		if (mApiModel == null)
			return;
		// The model's ids are the tree's node indices: nodes are added in their index order.
		mApiModel.Clear();
		let modelOf = scope List<int32>();
		for (int i < mApiTree.Nodes.Count)
			modelOf.Add(-1);
		for (let root in mApiTree.Roots)
		{
			let type = mApiTree.Nodes[root];
			modelOf[root] = mApiModel.AddNode(TreeModel.Root, type.Label);
			for (let child in type.Children)
				modelOf[child] = mApiModel.AddNode(modelOf[root], mApiTree.Nodes[child].Label);
		}
		mApiNodes.Clear();
		for (int i < mApiTree.Nodes.Count)
			mApiNodes.Add(-1);
		for (int i < modelOf.Count)
		{
			if (modelOf[i] >= 0)
				mApiNodes[modelOf[i]] = (int32)i;
		}
		// A search opens what it kept.
		if ((mApiView != null) && !mApiSearch.IsEmpty)
		{
			for (let root in mApiTree.Roots)
				mApiView.SetIdExpanded((ItemId)modelOf[root], true);
		}
	}
}
