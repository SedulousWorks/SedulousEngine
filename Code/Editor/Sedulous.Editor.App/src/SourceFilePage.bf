using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.GUI;
using Sedulous.Runtime.Client;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

// A page over a file of the project's own code, which is no asset: a .bf of the game's package
// (Code/) or of a Plugins/ package. The file is read into the code editor of its markup
// (`page-code`), coloured by the language of its extension (Beef's for .bf), and Save writes it
// back; the build is what checks it. The bar's Save, Undo, Redo and Discard Changes are the
// actions over the page, and the code's steps are commands on the page's stack, so the bar, the
// Edit menu and the code's own Ctrl+Z walk one history, as on a code asset's page. A file written
// outside (an agent's edit, then page_reload) is read again when the page has no unsaved edits.
//
// It edits no asset: its InstanceId stays Empty (so the asset actions, cook and reimport, are
// off over it), the page tools find it by its file, and it is not reopened with the project.

class SourceFilePage : UIEditorPage
{
	public const String cMarkupPath = "Editor/SourceFilePage.xml";

	private const int cUndoLimit = 100000;

	// One of the code's steps on the page's stack: done when pushed (the code did it), its undo
	// and redo the code's.
	private class CodeStepCommand : EditorCommand
	{
		private SourceFilePage mPage;
		private bool mDone = false;

		public this(SourceFilePage page)
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

	private EditorContext mContext;
	/// One reference, the page's; null without markup.
	private Node mContent = null ~ { if (_ != null) _.ReleaseRef(); };
	private PageActionBar mBar = null ~ delete _;
	/// The markup's.
	private CodeEditor mCode = null;
	/// The file, absolute.
	private String mPath = new .() ~ delete _;
	/// The file relative to the project, forward slashes: how the page tools name it.
	private String mFile = new .() ~ delete _;
	private String mTitle = new .() ~ delete _;
	/// The file as read or last written.
	private String mSaved = new .() ~ delete _;
	private bool mRead = false;
	private uint32 mListener = 0;
	private uint32 mKeyListener = 0;
	/// The code's steps the page's stack holds.
	private int mSteps = 0;
	/// The page walking the code's history: no new step.
	private bool mStepping = false;
	/// The page putting the file's text in: no step, no edit.
	private bool mLoading = false;

	/// The page over the file at `path` (absolute; Resolve gives it), `file` its path in the
	/// project. TAKES the one reference of `content`, the page's markup (null: none, the page
	/// then shows nothing). `languages` colours it (null: uncoloured).
	public this(EditorContext context, Node content, CodeLanguages languages, StringView path, StringView file)
	{
		mContext = context;
		mContent = content;
		mPath.Set(path);
		mFile.Set(file);
		PathFilename(path, mTitle);
		if (System.IO.File.ReadAllText(mPath, mSaved, true) case .Ok)
			mRead = true;
		else
		{
			mSaved.Clear();
			GlobalLog(.Error, "Editor: '{}' could not be read, its page is read only", mFile);
		}
		if (mContent == null)
			return;
		mBar = new PageActionBar(context.Actions, this);
		mBar.Bind(Find<ButtonBase>("page-save"), "file.save");
		mBar.Bind(Find<ButtonBase>("page-undo"), "edit.undo");
		mBar.Bind(Find<ButtonBase>("page-redo"), "edit.redo");
		mBar.Bind(Find<ButtonBase>("page-discard"), "page.discardChanges");
		if (let kind = Find<Sedulous.GUI.Label>("page-kind"))
			kind.Text = mFile;
		mCode = Find<CodeEditor>("page-code");
		if (mCode == null)
			return;
		if (languages != null)
			mCode.SetLanguage(languages.Find(LanguageOf(mPath)));
		mLoading = true;
		mCode.SetText(mSaved);
		mLoading = false;
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

	public override StringView Title => mTitle;
	public override Node Content => mContent;

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		if (mBar != null)
			mBar.Sync();
	}

	/// Writes the code back to its file.
	public override Result<void, ErrorCode> Save()
	{
		if (!mRead)
		{
			mContext.Notify(.Error, scope $"Not saved: {mFile} could not be read");
			return .Err(.NotFound);
		}
		let text = Text(.. scope .());
		if (System.IO.File.WriteAllText(mPath, text) case .Err)
		{
			GlobalLog(.Error, "Editor: '{}' could not be written", mFile);
			return .Err(.Unknown);
		}
		mSaved.Set(text);
		ClearDirty();
		GlobalLog(.Information, "Editor: saved '{}'", mFile);
		return .Ok;
	}

	/// The file written outside the page (an agent's edit, page_reload): a page with no unsaved
	/// edits reads it again, its history let go; one with them keeps them and says so.
	public override void OnAssetExternallyModified()
	{
		if (IsDirty)
		{
			mContext.Notify(.Warning, scope $"'{mFile}' changed on disk but has unsaved edits here - not read again.");
			return;
		}
		mSaved.Clear();
		mRead = (System.IO.File.ReadAllText(mPath, mSaved, true) case .Ok);
		if (!mRead)
			mSaved.Clear();
		if (mCode != null)
		{
			mLoading = true;
			mCode.SetText(mSaved);
			mLoading = false;
			mCode.IsReadOnly = !mRead;
			mSteps = mCode.Document.UndoCount;
		}
		Commands.Clear();
		ClearDirty();
	}

	/// Takes the code to `line` and `column`, from 1 as a build's diagnostics name them (0: the
	/// line's start), past the end clamped to it.
	public void GoTo(int line, int column = 0)
	{
		if (mCode == null)
			return;
		mCode.SetCaret(.((uint32)Math.Max(line - 1, 0), (uint32)Math.Max(column - 1, 0)));
		mCode.ScrollToCaret();
		mCode.RequestFocus();
	}

	/// The file, absolute.
	public StringView FilePath => mPath;
	/// The file relative to the project: how the page tools name it.
	public StringView ProjectFile => mFile;
	public bool SourceRead => mRead;
	public CodeEditor Code => mCode;

	/// The code (as read, without a code editor), appended.
	public void Text(String outText)
	{
		if (mCode != null)
			mCode.GetText(outText);
		else
			outText.Append(mSaved);
	}

	/// The code language a file is coloured by, by its extension: Beef's for .bf, XML's for a
	/// manifest; empty for none.
	public static StringView LanguageOf(StringView path)
	{
		let @extension = PathExtension(path, .. scope .());
		if (@extension == ".bf")
			return "beef";
		if (@extension == ".xml")
			return "xml";
		return "";
	}

	/// The file `path` names, relative to the project in `projectDir` or absolute, when it is a file
	/// of the project's own code: under its Code/ or Plugins/ once `.` and `..` are taken by name,
	/// and there. Its absolute path into `outPath` and its path in the project into `outFile`; false,
	/// with why in `outError`, for a file outside them, or none.
	public static bool Resolve(StringView projectDir, StringView path, String outPath, String outFile, String outError)
	{
		if (path.IsEmpty)
		{
			outError.Append("no file named");
			return false;
		}
		let root = Normalized(projectDir, .. scope .());
		let full = Normalized(PathJoin(root, path, .. scope .()), .. scope .());
		if (!full.StartsWith(root) || (full.Length <= root.Length + 1) || (full[root.Length] != '/'))
		{
			outError.AppendF("'{}' is not in the project: a source file opens from its Code/ or Plugins/", path);
			return false;
		}
		let file = full.Substring(root.Length + 1);
		if (!Under(file, Sedulous.Engine.Project.ProjectLayout.CodeDir) && !Under(file, Sedulous.Engine.Project.ProjectLayout.PluginsDir))
		{
			outError.AppendF("'{}' is not the project's code: a source file opens from its Code/ or Plugins/", file);
			return false;
		}
		if (!FileExists(full))
		{
			outError.AppendF("no file '{}' in the project", file);
			return false;
		}
		outPath.Set(full);
		outFile.Set(file);
		return true;
	}

	/// Whether `file`, relative, lies in the folder `folder` (by whole names).
	private static bool Under(StringView file, StringView folder)
	{
		return (file.Length > folder.Length + 1) && file.StartsWith(folder) && (file[folder.Length] == '/');
	}

	/// `path` against the current directory when relative, its separators forward, its `.` and
	/// `..` taken by name (a `..` at the root stays there), with no trailing separator.
	public static void Normalized(StringView path, String outPath)
	{
		let absolute = scope String();
		if (PathIsAbsolute(path))
			absolute.Set(path);
		else
			PathJoin(GetCurrentDirectory(.. scope .()), path, absolute);
		absolute.Replace('\\', '/');
		// The root: "/", or a drive's "X:/".
		int rootLength = (absolute.StartsWith('/')) ? 1 : ((absolute.Length >= 3) && (absolute[1] == ':')) ? 3 : 0;
		let names = scope List<StringView>();
		for (let name in absolute.Substring(rootLength).Split('/'))
		{
			if (name.IsEmpty || (name == "."))
				continue;
			if (name == "..")
			{
				if (!names.IsEmpty)
					names.PopBack();
				continue;
			}
			names.Add(name);
		}
		outPath.Set(absolute.Substring(0, rootLength));
		for (int i < names.Count)
		{
			if (i > 0)
				outPath.Append('/');
			outPath.Append(names[i]);
		}
	}

	private T Find<T>(StringView id) where T : Node
	{
		return (mContent != null) ? (mContent.FindElement(id) as T) : null;
	}

	private void CodeChanged()
	{
		if (mLoading)
			return;
		MarkDirty(); // typing merged into a step already on the stack changes the code too
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
	}
}
