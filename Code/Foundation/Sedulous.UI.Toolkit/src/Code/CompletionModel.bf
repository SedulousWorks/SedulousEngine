using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI.Toolkit;

/// The completion popup's state and key routing, with no UI in it at all.
///
/// The view feeds keys here FIRST while the popup is open, which is the whole reason completion
/// shapes the editor's input design: the popup must route Up, Down, Enter, Tab and Escape
/// WITHOUT taking focus, or the editor would lose the caret and the IME with it.
class CompletionModel
{
	private bool mOpen = false;
	private CodePosition mAnchor = .();
	private List<CompletionCandidate> mAll = new .() ~ DeleteContainerAndItems!(_);
	/// Indices into mAll.
	private List<int32> mFiltered = new .() ~ delete _;
	private int32 mSelected = 0;

	/// CONSUMES `candidates` and everything in it.
	public void Open(CodePosition anchor, List<CompletionCandidate> candidates, StringView prefix)
	{
		ClearAndDeleteItems!(mAll);
		for (let candidate in candidates)
			mAll.Add(candidate);

		candidates.Clear();

		mAnchor = anchor;
		mOpen = true;
		Filter(prefix);
	}

	public void Close()
	{
		mOpen = false;
		ClearAndDeleteItems!(mAll);
		mFiltered.Clear();
		mSelected = 0;
	}

	public bool IsOpen => mOpen;

	public CodePosition Anchor => mAnchor;

	/// Re-filters against the (re)typed prefix: a case-insensitive prefix match, with the
	/// exact-case matches ranked first and stable within each group.
	///
	/// Closes when nothing matches, and also when the ONLY match is the prefix itself, which
	/// leaves nothing to complete.
	public void Filter(StringView prefix)
	{
		if (!mOpen)
			return;

		mFiltered.Clear();
		for (int32 i < (int32)mAll.Count)
		{
			if (StartsWithCaseSensitive(mAll[i].Label, prefix))
				mFiltered.Add(i);
		}

		for (int32 i < (int32)mAll.Count)
		{
			if (!StartsWithCaseSensitive(mAll[i].Label, prefix) &&
				StartsWithCaseInsensitive(mAll[i].Label, prefix))
				mFiltered.Add(i);
		}

		mSelected = 0;
		if (mFiltered.IsEmpty ||
			((mFiltered.Count == 1) && (StringView(mAll[mFiltered[0]].Label) == prefix)))
			Close();
	}

	public CompletionKeyResult HandleKey(KeyCode key)
	{
		if (!mOpen)
			return .Ignored;

		switch (key)
		{
		case .Up:
			mSelected = (mSelected > 0) ? (mSelected - 1) : 0;
			return .Consumed;
		case .Down:
			mSelected = Math.Min(mSelected + 1, (int32)mFiltered.Count - 1);
			return .Consumed;
		case .Return, .Tab:
			return .Accepted;
		case .Escape:
			Close();
			return .Dismissed;
		default:
			return .Ignored;
		}
	}

	public int32 ItemCount => (int32)mFiltered.Count;

	public int32 SelectedIndex => mSelected;

	public void SetSelectedIndex(int32 index) =>
		mSelected = Math.Clamp(index, 0, Math.Max(0, (int32)mFiltered.Count - 1));

	/// BORROWED, and null for an index outside the filtered set.
	public CompletionCandidate Item(int32 index)
	{
		if ((index < 0) || (index >= ItemCount))
			return null;

		return mAll[mFiltered[index]];
	}

	public CompletionCandidate Selected => Item(mSelected);

	private static char8 ToLowerAscii(char8 c) =>
		((c >= 'A') && (c <= 'Z')) ? (char8)((uint8)c + 32) : c;

	private static bool StartsWithCaseSensitive(StringView text, StringView prefix) =>
		text.StartsWith(prefix);

	private static bool StartsWithCaseInsensitive(StringView text, StringView prefix)
	{
		if (prefix.Length > text.Length)
			return false;

		for (int i < prefix.Length)
		{
			if (ToLowerAscii(text[i]) != ToLowerAscii(prefix[i]))
				return false;
		}

		return true;
	}
}
