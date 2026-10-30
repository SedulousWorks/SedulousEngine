using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Script;

namespace Sedulous.Editor.Script;

/// What a script may call, as the runtime binds it for one language: a throwaway runtime for the
/// language, bound against the script surface, asked to describe what it bound. Built once per page
/// and read by its completion, its hover and its API browser alike, so they cannot disagree. Built
/// on first use; a language without a backend, or no surface, stays empty.
class ScriptApiSurface
{
	private String mLanguage = new .() ~ delete _;
	/// Borrowed; null describes nothing.
	private ScriptSurface mSurface = null;
	private bool mBuilt = false;
	private List<ScriptApiType> mTypes = new .() ~ DeleteContainerAndItems!(_);

	public void SetLanguage(StringView languageId)
	{
		mLanguage.Set(languageId);
		Reset();
	}

	public void SetSurface(ScriptSurface surface)
	{
		mSurface = surface;
		Reset();
	}

	public ScriptSurface Surface => mSurface;

	public List<ScriptApiType> Types
	{
		get
		{
			if (mBuilt || mLanguage.IsEmpty || (mSurface == null))
				return mTypes;
			mBuilt = true; // one attempt
			let runtime = ScriptBackends.Create(mLanguage);
			if (runtime == null)
				return mTypes;
			defer delete runtime;
			runtime.Bind(mSurface);
			runtime.DescribeBoundApi(mTypes);
			return mTypes;
		}
	}

	/// The type or namespace bound under `name`; null when none is.
	public ScriptApiType FindType(StringView name)
	{
		for (let type in Types)
		{
			if (type.ScriptName == name)
				return type;
		}
		return null;
	}

	/// A binding whose surface type is outside the runtime domain, which a shipped player
	/// will not have.
	public bool IsEditorOnly(ScriptApiType type)
	{
		if ((mSurface == null) || type.TypeFullName.IsEmpty)
			return false;
		let info = mSurface.Find(type.TypeFullName);
		return (info != null) && (info.Domain != ScriptDomains.Runtime);
	}

	private void Reset()
	{
		mBuilt = false;
		ClearAndDeleteItems!(mTypes);
	}
}
