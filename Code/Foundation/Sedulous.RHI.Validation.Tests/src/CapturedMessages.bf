using System;
using System.Collections;
using Sedulous.RHI.Validation;

namespace Sedulous.RHI.Validation.Tests;

/// Catches what the validation layer reports, so a test can drive misuse and assert on the
/// diagnosis rather than on a side effect.
///
/// Installs itself on construction and takes itself back off when it goes, so one test
/// cannot leave the callback pointing at its own freed storage.
class CapturedMessages
{
	private List<ValidationSeverity> mSeverities = new .() ~ delete _;
	private List<String> mMessages = new .() ~ DeleteContainerAndItems!(_);
	private ValidationCallback mCallback ~ delete _;

	public this()
	{
		mCallback = new (severity, message) =>
			{
				mSeverities.Add(severity);
				mMessages.Add(new String(message));
			};
		ValidationLog.SetCallback(mCallback);
	}

	public ~this()
	{
		ValidationLog.SetCallback(null);
	}

	public int Count => mMessages.Count;

	public void Clear()
	{
		mSeverities.Clear();
		ClearAndDeleteItems!(mMessages);
	}

	/// Whether anything reported contains `fragment`, at `severity`.
	public bool Has(ValidationSeverity severity, StringView fragment)
	{
		for (int i < mMessages.Count)
		{
			if ((mSeverities[i] == severity) && (mMessages[i].Contains(fragment)))
				return true;
		}
		return false;
	}

	public bool HasError(StringView fragment) => Has(.Error, fragment);
	public bool HasWarning(StringView fragment) => Has(.Warning, fragment);

	public int CountOf(ValidationSeverity severity)
	{
		int n = 0;
		for (let s in mSeverities)
		{
			if (s == severity)
				n++;
		}
		return n;
	}

	/// Everything captured, for a failure message that says what WAS reported.
	public void Describe(String outText)
	{
		if (mMessages.IsEmpty)
		{
			outText.Append("(nothing was reported)");
			return;
		}
		for (int i < mMessages.Count)
			outText.AppendF("\n    [{}] {}", mSeverities[i], mMessages[i]);
	}
}
