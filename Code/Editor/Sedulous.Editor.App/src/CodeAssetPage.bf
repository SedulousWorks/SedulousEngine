using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.GUI;
using Sedulous.Runtime.Client;
using Sedulous.Pipeline.Core;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

// What a page over an asset written as code does whatever its code is: a script, a shader, a GUI
// document or sheet. The asset names its source file (under
// the project's Sources); the page reads it into the code editor of its markup (`page-code`),
// coloured by the language the page names (CodeLanguages), and checks it a moment after each edit,
// the problems (its own the page's to find) shown in the problems list of its markup
// (`page-problems`) and on their lines; choosing one takes the code there. Save writes the source
// when it changed, then the asset, and asks for a cook; a check after it says whether the game takes
// the new code or keeps the last that built.
//
// One history: each step the code's document keeps (typing merges as the document merges it) is a
// command on the page's stack, so the bar's Undo and Redo, the Edit menu and the code's own Ctrl+Z
// walk one history with the page's other edits (a shader's entry points), and Discard Changes puts
// the code back with the rest. A source that is not there is a problem in the list, the code read
// only.

abstract class CodeAssetPage : AssetObjectPage
{
	/// How long the code rests after an edit before it is checked, in seconds.
	public const float cCheckDelay = 0.6f;

	private const int cUndoLimit = 100000;

	// One of the code's steps on the page's stack: done when pushed (the code did it), its undo
	// and redo the code's.
	private class CodeStepCommand : EditorCommand
	{
		private CodeAssetPage mPage;
		private bool mDone = false;

		public this(CodeAssetPage page)
		{
			mPage = page;
		}

		public override bool Execute()
		{
			if (mDone)
				mPage.Step(.Redo);
			mDone = true;
			return true;
		}

		public override void Undo() => mPage.Step(.Undo);
		public override StringView TypeId => "code_text";
	}

	/// The markup's.
	private CodeEditor mCode = null;
	private ProblemsList mProblems = null ~ delete _;
	private String mFileName = new .() ~ delete _;
	private String mSourcePath = new .() ~ delete _;
	/// The source as read or last written.
	private String mSaved = new .() ~ delete _;
	private bool mRead = false;
	private uint32 mListener = 0;
	private uint32 mKeyListener = 0;
	/// The code's steps the page's stack holds.
	private int mSteps = 0;
	/// The page walking the code's history: no new step.
	private bool mStepping = false;
	private float mCheckIn = 0.0f;
	private List<CodeProblem> mFound = new .() ~ DeleteContainerAndItems!(_);

	public this(EditorContext context, AssetPageServices services, Instance instance, Type type, StringView markupPath)
		: base(context, services, instance, type, markupPath)
	{
		mCode = Find<CodeEditor>("page-code");
		if (let host = Find<UIWidget>("page-problems"))
		{
			mProblems = new ProblemsList(host);
			mProblems.SetOnChoose(new [=this] (problem) => { GoTo(problem); });
		}
		let asset = ObjectAs<Asset>();
		if ((asset != null) && !asset.FileName.IsEmpty && (context.Project != null))
		{
			mFileName.Set(asset.FileName.Value);
			PathJoin(context.Project.SourcesRoot(.. scope .()), mFileName, mSourcePath);
			if (System.IO.File.ReadAllText(mSourcePath, mSaved, true) case .Ok)
				mRead = true;
			else
				mSaved.Clear();
		}
		if (mCode == null)
			return;
		mCode.SetText(mSaved);
		mCode.IsReadOnly = !mRead;
		let doc = mCode.Document;
		doc.SetUndoLimit(cUndoLimit); // the page's stack holds every step: none dropped under it
		mSteps = doc.UndoCount;
		mListener = doc.AddChangeListener(new [=this] (change) => { CodeChanged(); });
		// The code's own undo keys walk the page's one history.
		mKeyListener = mCode.AddEventListener(.KeyDown, new [=this] (e) =>
			{
				let key = (KeyEvent)e;
				let ctrl = (key.Modifiers & KeyModCtrl) != 0;
				let shift = (key.Modifiers & KeyModShift) != 0;
				let code = (Sedulous.GUI.KeyCode)key.KeyCode;
				if (!ctrl || ((key.Modifiers & (KeyModAlt | KeyModSuper)) != 0))
					return;
				if ((code == .Z) && !shift)
					Commands.Undo();
				else if (((code == .Z) && shift) || ((code == .Y) && !shift))
					Commands.Redo();
				else
					return;
				e.Handled = true;
			}, true);
	}

	public ~this()
	{
		if (mCode != null)
		{
			mCode.RemoveEventListener(mKeyListener);
			mCode.Document.RemoveChangeListener(mListener);
		}
	}

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		base.OnUpdate(host, dt);
		if (mCheckIn > 0.0f)
		{
			mCheckIn -= dt;
			if (mCheckIn <= 0.0f)
				CheckNow();
		}
	}

	/// The source written when it changed, then the asset; the code checked again, and the user
	/// told whether the game takes it or keeps the last that built.
	public override Result<void, ErrorCode> Save()
	{
		if (!mRead)
		{
			Context.Notify(.Error, scope String()..AppendF("Not saved: {} is not there", mFileName.IsEmpty ? "its source" : (StringView)mFileName));
			return .Err(.NotFound);
		}
		let text = Text(.. scope .());
		if (text != mSaved)
		{
			if (System.IO.File.WriteAllText(mSourcePath, text) case .Err)
			{
				Context.Notify(.Error, scope String()..AppendF("Could not write {}", mFileName));
				return .Err(.Unknown);
			}
			mSaved.Set(text);
		}
		let saved = base.Save(); // the asset, and a cook asked for
		if (saved case .Err)
			return saved;
		CheckNow();
		let clean = ErrorCount == 0;
		Context.Notify(clean ? NoticeKind.Success : .Warning,
			clean ? "Saved: it cooks again now" : "Saved with errors: the game keeps the last version that built");
		return saved;
	}

	/// Checks the code now (the page's own check), the problems shown in the list and on their lines.
	public void CheckNow()
	{
		mCheckIn = 0.0f;
		ClearAndDeleteItems!(mFound);
		if (mRead)
			CheckCode(Text(.. scope .()), mFound);
		else
		{
			let message = scope String();
			if (mFileName.IsEmpty)
				message.Append("The asset names no source file");
			else
				message.AppendF("The source file {} is not there (the code cannot be edited)", mFileName);
			mFound.Add(new CodeProblem(.Error, message, "", 0, 0, false));
		}
		let marks = scope List<CodeDiagnostic>();
		defer { ClearAndDeleteItems!(marks); }
		for (let p in mFound)
		{
			if (p.File.IsEmpty && mRead && (mCode != null))
				marks.Add(new CodeDiagnostic(RangeOf(p), p.Severity, p.Message));
		}
		if (mCode != null)
			mCode.SetDiagnostics(marks);
		if (mProblems != null)
		{
			let clean = scope String();
			if (mRead)
				CleanSummary(clean);
			mProblems.SetClean(clean);
			mProblems.Show(mFound);
		}
		OnCodeChecked();
	}

	/// Takes the code to `problem` (its own code's: an include's has no place here).
	public void GoTo(CodeProblem problem)
	{
		if ((mCode == null) || !problem.File.IsEmpty)
			return;
		mCode.SetCaret(.(problem.Line, problem.AtColumn ? problem.Column : 0));
		mCode.ScrollToCaret();
		mCode.RequestFocus();
	}

	// === For tests ===

	public CodeEditor Code => mCode;
	public ProblemsList Problems => mProblems;
	public bool SourceRead => mRead;
	public StringView SourceFileName => mFileName;
	public Span<CodeProblem> Found => mFound;

	/// The code (as read, without a code editor), appended.
	public void Text(String outText)
	{
		if (mCode != null)
			mCode.GetText(outText);
		else
			outText.Append(mSaved);
	}

	public int ErrorCount
	{
		get
		{
			int errors = 0;
			for (let p in mFound)
				errors += (p.Severity == .Error) ? 1 : 0;
			return errors;
		}
	}

	/// Colours the code as `languageId` (the derived page's, once it knows it) and checks it, so
	/// the page opens with its problems.
	protected void OpenCode(StringView languageId)
	{
		if ((mCode != null) && (Services.Languages != null))
			mCode.SetLanguage(Services.Languages.Find(languageId));
		CheckNow();
	}

	/// What the page's check of `text` finds (a compile's errors), appended; the page deletes them.
	protected abstract void CheckCode(StringView text, List<CodeProblem> outProblems);

	/// After each check (a status, a preview following the code).
	protected virtual void OnCodeChecked() { }

	/// What the problems line says when the check found none (empty: "No problems"), appended;
	/// asked after CheckCode.
	protected virtual void CleanSummary(String outText) { }

	protected StringView SourcePath => mSourcePath;

	/// A check a moment from now, as after an edit (a page's other code changed: a sheet's preview
	/// markup).
	protected void CheckSoon()
	{
		mCheckIn = cCheckDelay;
	}

	private static bool IsWordByte(char8 c)
	{
		return ((c >= 'a') && (c <= 'z')) || ((c >= 'A') && (c <= 'Z')) || ((c >= '0') && (c <= '9')) || (c == '_') || ((uint8)c >= 0x80);
	}

	// Where a problem is marked: the word at its place, or one character; its line's text when the
	// check named no column.
	private CodeRange RangeOf(CodeProblem p)
	{
		let doc = mCode.Document;
		uint32 l = (doc.LineCount == 0) ? 0 : Math.Min(p.Line, doc.LineCount - 1);
		let text = doc.LineText(l);
		if (!p.AtColumn)
		{
			int first = 0;
			while ((first < text.Length) && ((text[first] == ' ') || (text[first] == '\t')))
				++first;
			return .(.(l, (uint32)first), .(l, (uint32)text.Length));
		}
		let c = Math.Min((int)p.Column, text.Length);
		var end = c;
		while ((end < text.Length) && IsWordByte(text[end]))
			++end;
		if ((end == c) && (end < text.Length))
			++end;
		return .(.(l, (uint32)c), .(l, (uint32)end));
	}

	private void CodeChanged()
	{
		MarkDirty(); // typing merged into a step already on the stack changes the code too
		mCheckIn = cCheckDelay;
		if (mStepping)
			return;
		let steps = mCode.Document.UndoCount;
		if (steps > mSteps)
			Commands.Execute(new CodeStepCommand(this));
		mSteps = steps;
	}

	private void Step(TextEditCommand command)
	{
		if (mCode == null)
			return;
		mStepping = true;
		mCode.Run(command);
		mStepping = false;
		mCode.Document.BreakMerge(); // typing after an undo starts a step of its own
		mSteps = mCode.Document.UndoCount;
		mCheckIn = cCheckDelay;
	}
}
