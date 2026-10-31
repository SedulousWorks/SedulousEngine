using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// [[CodeEditView]]'s find, replace and go-to-line bar.
///
/// The bar is built LAZILY, because most editors are never searched, and it is a logical child
/// rather than a popup so it keeps its own focus and hit testing while floating over the text.
extension CodeEditView
{
	public CodeFindBarMode FindBar => mFindBarMode;

	/// Ctrl+F and Ctrl+H. A single line selection prefills the query. Focus moves to the find
	/// field, and Escape hands it back to the editor.
	public void OpenFindBar(bool withReplace)
	{
		EnsureFindBar();
		mFindBarMode = withReplace ? .Replace : .Find;
		ApplyFindBarMode();

		let selection = Selection;
		if (HasSelection && (selection.Begin.Line == selection.End.Line))
		{
			let text = scope String();
			mDoc.GetTextInSpan(selection, text);
			mFindField.SetText(text);
		}

		// SetText is a SILENT programmatic setter, so the search has to be run by hand.
		RunSearch();

		if (Context != null)
			Context.GetFocusManager().SetFocus(mFindField);

		Invalidate();
	}

	/// Ctrl+G: type a one based line number, Enter jumps to it.
	public void OpenGoToLine()
	{
		EnsureFindBar();
		mFindBarMode = .GoToLine;
		ApplyFindBarMode();
		mFindField.SetText("");

		if (Context != null)
			Context.GetFocusManager().SetFocus(mFindField);

		Invalidate();
	}

	public void CloseFindBar()
	{
		if (mFindBarMode == .Closed)
			return;

		mFindBarMode = .Closed;
		if (mFindBar != null)
			mFindBar.Visibility = .Gone;

		mMatches.Clear();
		mCurrentMatch = -1;

		if (Context != null)
			Context.GetFocusManager().SetFocus(this);

		Invalidate();
	}

	/// BORROWED.
	public Span<CodeSpan> SearchMatches => mMatches;

	public int32 CurrentMatchIndex => mCurrentMatch;

	/// Programmatic query. EditText.SetText is silent, so the search re-runs explicitly.
	public void SetSearchQuery(StringView query)
	{
		EnsureFindBar();
		mFindField.SetText(query);
		RunSearch();
	}

	public void SetReplaceText(StringView text)
	{
		EnsureFindBar();
		mReplaceField.SetText(text);
	}

	/// F3 and Shift+F3. Both wrap.
	public void FindNext() => GotoMatch(1);
	public void FindPrevious() => GotoMatch(-1);

	/// Replaces the selected match, then advances.
	public void ReplaceCurrent()
	{
		if (ReadOnly || (mCurrentMatch < 0) || (mCurrentMatch >= mMatches.Count))
		{
			FindNext();
			return;
		}

		let replacement = scope String();
		if (mReplaceField != null)
			replacement.Set(mReplaceField.Text);

		let span = mMatches[mCurrentMatch];
		CodeCursorState before = .(mCursor, mAnchor);
		mCursor = mDoc.Edit(span, replacement, .Other, before, Now);
		mAnchor = mCursor;

		// AfterEdit re-runs the search, so the current index already points at what is now
		// the next match.
		AfterEdit();
		if (mCurrentMatch >= 0)
			SelectMatch(mCurrentMatch);
	}

	/// Replaces every match as ONE undo entry.
	public void ReplaceAll()
	{
		if (ReadOnly || mMatches.IsEmpty)
			return;

		let replacement = scope String();
		if (mReplaceField != null)
			replacement.Set(mReplaceField.Text);

		CodeCursorState before = .(mCursor, mAnchor);
		mDoc.BeginCompoundEdit();
		// BACK TO FRONT, so the spans ahead of the one being replaced stay valid.
		for (int i = mMatches.Count; i > 0; i--)
			mCursor = mDoc.Edit(mMatches[i - 1], replacement, .Other, before, Now);

		mDoc.EndCompoundEdit();
		mAnchor = mCursor;
		AfterEdit();
	}

	/// A vertical stack of two rows: find, count, previous, next, the two option toggles and
	/// close, over replace, Replace and All. The second row shows only in replace mode.
	private void EnsureFindBar()
	{
		if (mFindBar != null)
			return;

		mFindBar = new FlexLayout();
		mFindBar.Direction = .Vertical;
		mFindBar.Spacing = 3.0f;
		mFindBar.Padding = .(6, 4);

		mFindRow = new FlexLayout();
		mFindRow.Direction = .Horizontal;
		mFindRow.Spacing = 4.0f;

		mReplaceRow = new FlexLayout();
		mReplaceRow.Direction = .Horizontal;
		mReplaceRow.Spacing = 4.0f;

		mFindField = new EditText();
		mFindField.SetPlaceholder("Find");
		mFindField.OnTextChanged.Add(new (field) =>
			{
				if ((mFindBarMode != .Find) && (mFindBarMode != .Replace))
					return;

				RunSearch();
				if (mCurrentMatch >= 0)
					SelectMatch(mCurrentMatch);
			});

		{
			LayoutStyle style = .();
			style.Width = SizeSpec.Fixed(Unit.Dp(170));
			mFindRow.AddView(mFindField, style);
		}

		mMatchLabel = new Label();
		mMatchLabel.FontSize.Value = 12.0f;
		mFindRow.AddView(mMatchLabel);

		mPrevButton = AddButton(mFindRow, "<", new (sender) => FindPrevious());
		mNextButton = AddButton(mFindRow, ">", new (sender) => FindNext());

		// Real toggle controls, so the checked state is themed rather than drawn by hand.
		mCaseButton = AddToggle(mFindRow, "Aa", new (sender, isChecked) =>
			{
				mSearchCaseSensitive = isChecked;
				RunSearch();
			});
		mWordButton = AddToggle(mFindRow, "W", new (sender, isChecked) =>
			{
				mSearchWholeWord = isChecked;
				RunSearch();
			});
		mCloseButton = AddButton(mFindRow, "x", new (sender) => CloseFindBar());

		mReplaceField = new EditText();
		mReplaceField.SetPlaceholder("Replace");
		{
			LayoutStyle style = .();
			style.Width = SizeSpec.Fixed(Unit.Dp(170));
			mReplaceRow.AddView(mReplaceField, style);
		}

		mReplaceButton = AddButton(mReplaceRow, "Replace", new (sender) => ReplaceCurrent());
		mReplaceAllButton = AddButton(mReplaceRow, "All", new (sender) => ReplaceAll());

		mFindBar.AddView(mFindRow);
		mFindBar.AddView(mReplaceRow);
		mFindBar.Visibility = .Gone;
		AddView(mFindBar);
	}

	/// CONSUMES `handler`. The button comes back BORROWED: the row owns it.
	private static Button AddButton(FlexLayout row, StringView text,
		delegate void(ButtonBase) handler)
	{
		let button = new Button(text);
		button.FontSize.Value = 12.0f;
		button.OnClick.Add(handler);
		row.AddView(button);
		return button;
	}

	/// CONSUMES `handler`. The toggle comes back BORROWED.
	private static ToggleButton AddToggle(FlexLayout row, StringView text,
		delegate void(ToggleButton, bool) handler)
	{
		let toggle = new ToggleButton(text);
		toggle.OnCheckedChanged.Add(handler);
		row.AddView(toggle);
		return toggle;
	}

	private void ApplyFindBarMode()
	{
		mFindBar.Visibility = .Visible;

		let searching = (mFindBarMode == .Find) || (mFindBarMode == .Replace);
		let searchControls = searching ? Sedulous.UI.Visibility.Visible : Sedulous.UI.Visibility.Gone;
		mPrevButton.Visibility = searchControls;
		mNextButton.Visibility = searchControls;
		mCaseButton.Visibility = searchControls;
		mWordButton.Visibility = searchControls;
		mReplaceRow.Visibility = ((mFindBarMode == .Replace) && !ReadOnly)
			? Sedulous.UI.Visibility.Visible
			: Sedulous.UI.Visibility.Gone;
		mFindField.SetPlaceholder((mFindBarMode == .GoToLine) ? "Line" : "Find");
		UpdateMatchLabel();
	}

	protected bool IsInFindBar(View view)
	{
		for (var v = view; v != null; v = v.Parent)
		{
			if (v == mFindBar)
				return true;
		}

		return false;
	}

	/// Reads whatever digits the field holds, so a stray character does not refuse the jump.
	protected void JumpToTypedLine()
	{
		let text = mFindField.Text;
		int32 line = 0;
		var any = false;
		for (int i < text.Length)
		{
			let c = text[i];
			if ((c < '0') || (c > '9'))
				continue;

			any = true;
			line = (line * 10) + (int32)(c - '0');
			if (line > 100000000)
				break;
		}

		if (!any)
			return;

		CloseFindBar();
		ScrollToLine(line - 1); // one based entry
	}

	/// Recomputes the matches and the current index, which is the first match at or after the
	/// cursor. It does NOT move the selection: typing selects, an edit keeps its position.
	protected void RunSearch()
	{
		mMatches.Clear();
		mCurrentMatch = -1;

		if ((mFindField != null) && ((mFindBarMode == .Find) || (mFindBarMode == .Replace)))
		{
			mDoc.FindAll(mFindField.Text, mSearchCaseSensitive, mSearchWholeWord, mMatches);

			for (int32 i < (int32)mMatches.Count)
			{
				if ((mCursor <= mMatches[i].Begin) ||
					((mMatches[i].Begin <= mCursor) && (mCursor <= mMatches[i].End)))
				{
					mCurrentMatch = i;
					break;
				}
			}

			if ((mCurrentMatch < 0) && !mMatches.IsEmpty)
				mCurrentMatch = 0; // wrap
		}

		UpdateMatchLabel();
		Invalidate();
	}

	protected void SelectMatch(int32 index)
	{
		if ((index < 0) || (index >= mMatches.Count))
			return;

		mCurrentMatch = index;
		mAnchor = mMatches[index].Begin;
		mCursor = mMatches[index].End;
		mDesiredColumn = -1;
		mPendingCursorScroll = true;
		ResetBlink();
		UpdateMatchLabel();
		Invalidate();
	}

	private void GotoMatch(int32 delta)
	{
		if (mMatches.IsEmpty)
			return;

		let count = (int32)mMatches.Count;
		var target = mCurrentMatch;
		if (target < 0)
			target = (delta > 0) ? 0 : (count - 1);
		else
			target = (target + (delta % count) + count) % count;

		SelectMatch(target);
	}

	private void UpdateMatchLabel()
	{
		if (mMatchLabel == null)
			return;

		mScratch.Clear();
		if (mFindBarMode == .GoToLine)
			mScratch.AppendF("1-{}", mDoc.LineCount);
		else
			mScratch.AppendF("{}/{}", (mCurrentMatch >= 0) ? (mCurrentMatch + 1) : 0,
				mMatches.Count);

		mMatchLabel.SetText(mScratch);
	}
}
