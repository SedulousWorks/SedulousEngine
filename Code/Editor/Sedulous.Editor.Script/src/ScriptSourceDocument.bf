using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Script.Resource;
using Sedulous.Script.Pipeline;

namespace Sedulous.Editor.Script;

/// The headless half of the script page: the linked source file under the project's
/// sources, loaded and saved whole, and a compile check through the language's cook that
/// keeps the errors and the class the cook found.
class ScriptSourceDocument
{
	private String mSourcesRoot = new .() ~ delete _;
	private String mFileName = new .() ~ delete _;
	private String mLanguage = new .() ~ delete _;
	private String mSource = new .() ~ delete _;
	private String mSaved = new .() ~ delete _;
	private String mClassName = new .() ~ delete _;
	private List<ScriptCompileError> mErrors = new .() ~ DeleteContainerAndItems!(_);
	private bool mLastCompileOk = true;

	/// An empty language means AngelScript, the default backend.
	public void Bind(StringView sourcesRoot, StringView fileName, StringView language)
	{
		mSourcesRoot.Set(sourcesRoot);
		mFileName.Set(fileName);
		mLanguage.Set(language.IsEmpty ? "angelscript" : language);
	}

	public StringView FileName => mFileName;
	public StringView Language => mLanguage;
	public StringView Source => mSource;
	public bool IsModified => mSource != mSaved;
	public List<ScriptCompileError> Errors => mErrors;
	public StringView ClassName => mClassName;
	public bool LastCompileOk => mLastCompileOk;

	public void SetSource(StringView source) => mSource.Set(source);

	public Result<void, ErrorCode> Load()
	{
		let path = PathJoin(mSourcesRoot, mFileName, .. scope .());
		let bytes = scope List<uint8>();
		if (ReadFile(path, bytes) case .Err(let error))
			return .Err(error);
		mSource.Set(StringView((char8*)bytes.Ptr, bytes.Count));
		mSaved.Set(mSource);
		return .Ok;
	}

	public Result<void, ErrorCode> Save()
	{
		let path = PathJoin(mSourcesRoot, mFileName, .. scope .());
		let written = WriteFile(path, .((uint8*)mSource.Ptr, mSource.Length));
		if (written case .Ok)
			mSaved.Set(mSource);
		return written;
	}

	/// Compile checks the source through the language's cook; false with the errors filled
	/// when it does not compile, or no cook is registered for the language.
	public bool Validate()
	{
		ClearAndDeleteItems!(mErrors);
		mClassName.Clear();
		let cook = ScriptLanguageCooks.Find(mLanguage);
		if (cook == null)
		{
			let error = new ScriptCompileError();
			error.Message.AppendF("no script cook registered for language '{}'", mLanguage);
			mErrors.Add(error);
			mLastCompileOk = false;
			return false;
		}
		let problems = scope List<String>();
		defer { ClearAndDeleteItems!(problems); }
		let record = scope ScriptClassSource();
		let ok = cook.Cook(mSource, mFileName, "", record, problems);
		for (let problem in problems)
			mErrors.Add(ScriptCompileError.Parse(problem));
		if (ok)
			mClassName.Set(record.ClassName);
		mLastCompileOk = ok;
		return ok;
	}
}
