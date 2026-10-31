using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// [[CodeEditView]]'s editing core: the primitives every key and every seam goes through, plus
/// the line operations that are one undo entry each.
extension CodeEditView
{
	/// Everything an edit has to put back in order. Kept in one place so no path can forget
	/// half of it: the goal column, the scroll follow, the width cache, the caret blink, the
	/// search spans that just shifted under the edit, and the notification.
	protected void AfterEdit()
	{
		mDesiredColumn = -1;
		mPendingCursorScroll = true;
		mMaxLineDirty = true;
		ResetBlink();

		if ((mFindBarMode == .Find) || (mFindBarMode == .Replace))
			RunSearch();

		Invalidate();
		OnTextChanged();
	}

	protected void InsertText(StringView text, CodeEditKind kind)
	{
		CodeCursorState before = .(mCursor, mAnchor);
		mCursor = mDoc.Edit(Selection, text, kind, before, Now);
		mAnchor = mCursor;
		AfterEdit();
	}

	protected void DeleteSpan(CodeSpan span, CodeEditKind kind)
	{
		CodeCursorState before = .(mCursor, mAnchor);
		mCursor = mDoc.Edit(span, "", kind, before, Now);
		mAnchor = mCursor;
		AfterEdit();
	}

	protected CodePosition LeftOf(CodePosition pos)
	{
		if (pos.Column > 0)
			return .(pos.Line, pos.Column - 1);

		if (pos.Line > 0)
			return .(pos.Line - 1, mDoc.LineLength(pos.Line - 1));

		return pos;
	}

	protected CodePosition RightOf(CodePosition pos)
	{
		if (pos.Column < mDoc.LineLength(pos.Line))
			return .(pos.Line, pos.Column + 1);

		if ((pos.Line + 1) < mDoc.LineCount)
			return .(pos.Line + 1, 0);

		return pos;
	}

	protected void MoveCursor(CodePosition pos, bool extendSelection)
	{
		mCursor = mDoc.ClampPosition(pos);
		if (!extendSelection)
			mAnchor = mCursor;

		mDoc.BreakUndoChain();
		mCompletion.Close();
		mPendingCursorScroll = true;
		ResetBlink();
		Invalidate();
	}

	protected int32 FirstNonSpaceColumn(int32 line)
	{
		let text = mDoc.Line(line);
		int32 column = 0;
		int i = 0;
		while ((i < text.Length) && ((text[i] == ' ') || (text[i] == '\t')))
		{
			i++;
			column++;
		}

		return column;
	}

	/// Tab and Shift+Tab. A single line indents to the next TAB STOP rather than by a fixed
	/// number of spaces, which is what makes ragged indentation line up instead of drifting.
	protected void HandleTab(bool dedent)
	{
		let selection = Selection;
		let multiLine = HasSelection && (selection.Begin.Line != selection.End.Line);
		if (!multiLine && !dedent)
		{
			let spaces = scope String();
			let count = TabWidth - (mCursor.Column % TabWidth);
			for (int32 i < count)
				spaces.Append(' ');

			InsertText(spaces, .Typing);
			return;
		}

		// Indent or dedent every touched line as ONE undoable replacement.
		let firstLine = selection.Begin.Line;
		var lastLine = selection.End.Line;
		if (multiLine && (selection.End.Column == 0))
			lastLine--; // a selection ending at column zero does not touch that line

		let replacement = scope String();
		for (var line = firstLine; line <= lastLine; line++)
		{
			if (line > firstLine)
				replacement.Append('\n');

			let text = mDoc.Line(line);
			if (dedent)
			{
				int drop = 0;
				while ((drop < TabWidth) && (drop < text.Length) && (text[drop] == ' '))
					drop++;

				replacement.Append(text.Substring(drop));
			}
			else
			{
				for (int32 i < TabWidth)
					replacement.Append(' ');

				replacement.Append(text);
			}
		}

		ReplaceLineRange(firstLine, lastLine, replacement);
	}

	/// Replaces whole lines and leaves the range selected, which every line operation wants.
	private void ReplaceLineRange(int32 firstLine, int32 lastLine, StringView replacement)
	{
		CodeSpan lineSpan = .(.(firstLine, 0), .(lastLine, mDoc.LineLength(lastLine)));
		CodeCursorState before = .(mCursor, mAnchor);
		mDoc.Edit(lineSpan, replacement, .Other, before, Now);
		mAnchor = .(firstLine, 0);
		mCursor = .(lastLine, mDoc.LineLength(lastLine));
		AfterEdit();
	}

	protected void DuplicateLine()
	{
		let line = mCursor.Line;
		let insert = scope String();
		insert.Append('\n');
		insert.Append(mDoc.Line(line));

		CodePosition lineEnd = .(line, mDoc.LineLength(line));
		CodeCursorState before = .(mCursor, mAnchor);
		mDoc.Edit(.(lineEnd, lineEnd), insert, .Other, before, Now);
		mCursor = .(line + 1, mCursor.Column);
		mAnchor = mCursor;
		AfterEdit();
	}

	protected void MoveLine(bool down)
	{
		let line = mCursor.Line;
		let other = down ? (line + 1) : (line - 1);
		if ((other < 0) || (other >= mDoc.LineCount))
			return;

		let first = Math.Min(line, other);
		let swapped = scope String();
		swapped.Append(mDoc.Line(first + 1));
		swapped.Append('\n');
		swapped.Append(mDoc.Line(first));

		CodeSpan span = .(.(first, 0), .(first + 1, mDoc.LineLength(first + 1)));
		CodeCursorState before = .(mCursor, mAnchor);
		mDoc.Edit(span, swapped, .Other, before, Now);
		mCursor = .(other, mCursor.Column);
		mAnchor = mCursor;
		AfterEdit();
	}

	protected void CopySelection(bool cut)
	{
		if (!HasSelection || (Context == null) || (Context.Clipboard == null))
			return;

		let text = scope String();
		GetSelectedText(text);
		Context.Clipboard.SetText(text).IgnoreError();

		if (cut)
			DeleteSpan(Selection, .Other);
	}

	protected void Paste()
	{
		if ((Context == null) || (Context.Clipboard == null))
			return;

		let text = scope String();
		if ((Context.Clipboard.GetText(text) case .Err) || text.IsEmpty)
			return;

		InsertText(text, .Paste);
	}

	/// Toggles the language's line comment on the cursor line, or on every selected line.
	///
	/// A language without one, such as markup, is a NO-OP rather than a guess: inserting the
	/// wrong marker would corrupt the file quietly.
	public void ToggleLineComment()
	{
		let prefix = (mLexer != null) ? mLexer.LineCommentPrefix : "//";
		if (prefix.IsEmpty || ReadOnly)
			return;

		let selection = Selection;
		let firstLine = selection.Begin.Line;
		var lastLine = selection.End.Line;
		if ((lastLine > firstLine) && (selection.End.Column == 0))
			lastLine--; // a selection ending at column zero does not touch that line

		// Uncomment only when EVERY non blank line already carries the prefix, so a mixed
		// block comments the stragglers rather than uncommenting half of it.
		var allCommented = true;
		var anyContent = false;
		for (var line = firstLine; line <= lastLine; line++)
		{
			let text = mDoc.Line(line);
			let indent = IndentBytes(text);
			if (indent >= text.Length)
				continue; // blank line, ignored by the decision

			anyContent = true;
			if (!text.Substring(indent).StartsWith(prefix))
			{
				allCommented = false;
				break;
			}
		}

		if (!anyContent)
			return;

		let replacement = scope String();
		for (var line = firstLine; line <= lastLine; line++)
		{
			if (line > firstLine)
				replacement.Append('\n');

			let text = mDoc.Line(line);
			let indent = IndentBytes(text);

			if (allCommented)
			{
				if ((indent < text.Length) && text.Substring(indent).StartsWith(prefix))
				{
					var drop = indent + prefix.Length;
					if ((drop < text.Length) && (text[drop] == ' '))
						drop++; // the space the toggle itself inserted

					replacement.Append(text.Substring(0, indent));
					replacement.Append(text.Substring(drop));
				}
				else
				{
					replacement.Append(text); // blank line, untouched
				}
			}
			else if (indent >= text.Length)
			{
				replacement.Append(text); // blank line, untouched
			}
			else
			{
				replacement.Append(text.Substring(0, indent));
				replacement.Append(prefix);
				replacement.Append(' ');
				replacement.Append(text.Substring(indent));
			}
		}

		ReplaceLineRange(firstLine, lastLine, replacement);
	}

	private static int IndentBytes(StringView text)
	{
		int i = 0;
		while ((i < text.Length) && ((text[i] == ' ') || (text[i] == '\t')))
			i++;

		return i;
	}

	// ---- completion --------------------------------------------------------------------------

	/// The identifier fragment immediately left of the cursor.
	protected StringView PrefixView()
	{
		let word = mDoc.WordAt(mCursor);
		if (word.IsEmpty || (word.Begin.Line != mCursor.Line) ||
			(word.Begin.Column >= mCursor.Column))
			return default;

		let fromByte = mDoc.ColumnToByte(mCursor.Line, word.Begin.Column);
		let toByte = mDoc.ColumnToByte(mCursor.Line, mCursor.Column);
		return mDoc.Line(mCursor.Line).Substring(fromByte, toByte - fromByte);
	}

	protected void OpenCompletion(bool explicitRequest)
	{
		let prefix = PrefixView();
		if (!explicitRequest && prefix.IsEmpty)
			return;

		let merged = scope List<CompletionCandidate>();
		defer { ClearAndDeleteItems!(merged); }

		if (DocumentWordCompletion)
			mWordProvider.Collect(mDoc, mCursor, prefix, merged);

		for (let provider in mProviders)
			provider.Collect(mDoc, mCursor, prefix, merged);

		DedupeAndSort(merged);
		if (merged.IsEmpty)
		{
			mCompletion.Close();
			return;
		}

		CodePosition anchor = .(mCursor.Line, mCursor.Column - Utf8Text.CharCount(prefix));
		mCompletion.Open(anchor, merged, prefix);
		Invalidate();
	}

	protected void AcceptCompletion()
	{
		let candidate = mCompletion.Selected;
		if (candidate == null)
		{
			mCompletion.Close();
			return;
		}

		let insert = scope String(candidate.InsertText);
		CodeSpan replaced = .(mCompletion.Anchor, mCursor);
		mCompletion.Close();

		CodeCursorState before = .(mCursor, mAnchor);
		mCursor = mDoc.Edit(replaced, insert, .Other, before, Now);
		mAnchor = mCursor;
		AfterEdit();
	}

	/// Insertion sort by (priority, label), then a dedupe that keeps the FIRST occurrence.
	///
	/// Context providers rank above the document's own words so member and attribute results
	/// are never buried below the fold. Because priority comes first, equal labels are
	/// scattered rather than adjacent, so the dedupe scans everything kept so far. The lists
	/// are small.
	private static void DedupeAndSort(List<CompletionCandidate> items)
	{
		for (int i = 1; i < items.Count; i++)
		{
			let value = items[i];
			var j = i;
			while ((j > 0) && RanksBefore(value, items[j - 1]))
			{
				items[j] = items[j - 1];
				j--;
			}

			items[j] = value;
		}

		int write = 0;
		for (int i = 0; i < items.Count; i++)
		{
			var seen = false;
			for (int k < write)
			{
				if (StringView(items[k].Label) == StringView(items[i].Label))
				{
					seen = true;
					break;
				}
			}

			if (seen)
			{
				delete items[i];
				continue;
			}

			items[write] = items[i];
			write++;
		}

		while (items.Count > write)
			items.PopBack();
	}

	private static bool RanksBefore(CompletionCandidate a, CompletionCandidate b)
	{
		if (a.Priority != b.Priority)
			return a.Priority < b.Priority;

		return Less(a.Label, b.Label);
	}

	private static bool Less(StringView a, StringView b)
	{
		let n = Math.Min(a.Length, b.Length);
		for (int i < n)
		{
			if (a[i] != b[i])
				return a[i] < b[i];
		}

		return a.Length < b.Length;
	}

	// ---- bracket matching ---------------------------------------------------------------------

	/// Cached against the document version AND the caret, because the pair only changes when
	/// one of those does and the search runs on every frame otherwise.
	protected void RefreshBracketMatch()
	{
		if ((mBracketVersion == mDoc.Version) && (mBracketCursor == mCursor) &&
			(mBracketAnchor == mAnchor))
			return;

		mBracketVersion = mDoc.Version;
		mBracketCursor = mCursor;
		mBracketAnchor = mAnchor;
		mBracketValid = false;

		if (HasSelection)
			return;

		// Either side of the caret: sitting just after a closing bracket should light the pair
		// as readily as sitting just before an opening one.
		CodePosition[2] probes = .(mCursor, .(mCursor.Line, mCursor.Column - 1));
		for (let probe in probes)
		{
			if (probe.Column < 0)
				continue;

			if (mDoc.FindMatchingBracket(probe, let match))
			{
				mBracketA = probe;
				mBracketB = match;
				mBracketValid = true;
				return;
			}
		}
	}
}
