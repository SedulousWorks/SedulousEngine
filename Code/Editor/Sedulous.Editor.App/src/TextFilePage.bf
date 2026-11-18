using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.GUI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

// TextFilePage: a file in the project's Code folder that is no asset (a .csproj, a .luaurc), as
// plain text in a code editor. Save writes the file; Discard Changes reads it again. A file that
// does not read shows empty and read-only, and is never saved over. The code editor keeps its own
// undo, so the page's history stays empty and an edit only marks the page unsaved.

class TextFilePage : UIEditorPage, ICodePage
{
	private String mFile = new .() ~ delete _;
	private String mTitle = new .() ~ delete _;
	/// A reference of ours (the dock takes its own).
	private Panel mContent = null ~ _?.ReleaseRef();
	/// A reference of ours (the content holds its own).
	private CodeEditor mCode = null;
	private uint32 mListener = 0;
	private bool mRead = false;
	private bool mLoading = false;

	public this(StringView file)
	{
		mFile.Set(file);
		PathFilename(file, mTitle);
		mContent = new Panel();
		mContent.AddClass("page");
		mContent.AddClass("code-page");
		mCode = new CodeEditor();
		mCode.AddClass("page-code");
		mContent.AddChild(mCode);
		ReloadFromSource();
		mListener = mCode.Document.AddChangeListener(new [=this] (change) =>
			{
				if (!mLoading)
					MarkDirty();
			});
	}

	public ~this()
	{
		if (mCode != null)
		{
			if (mListener != 0)
				mCode.Document.RemoveChangeListener(mListener);
			mCode.ReleaseRef();
		}
	}

	public override StringView Title => mTitle;
	public override Node Content => mContent;

	public override Result<void, ErrorCode> Save()
	{
		// What did not read is not written over.
		if (!mRead)
			return .Err(.NotSupported);
		let text = mCode.GetText(.. scope .());
		if (System.IO.File.WriteAllText(mFile, text) case .Err)
		{
			GlobalLog(.Error, "Editor: {} could not be written", mFile);
			return .Err(.Unknown);
		}
		ClearDirty();
		return .Ok;
	}

	public override bool ReloadFromSource()
	{
		let text = scope String();
		mRead = System.IO.File.ReadAllText(mFile, text, true) case .Ok;
		mLoading = true;
		mCode.SetText(mRead ? text : "");
		mLoading = false;
		mCode.IsReadOnly = !mRead;
		if (!mRead)
			GlobalLog(.Warning, "Editor: {} could not be read", mFile);
		return mRead;
	}

	public void ShowLine(uint32 line, uint32 column)
	{
		mCode.SetCaret(.((line > 0) ? line - 1 : 0, (column > 0) ? column - 1 : 0));
		mCode.ScrollToCaret();
		mCode.RequestFocus();
	}

	/// The file it shows, on disk.
	public StringView File => mFile;

	// === For tests ===

	public CodeEditor Code => mCode;
}
