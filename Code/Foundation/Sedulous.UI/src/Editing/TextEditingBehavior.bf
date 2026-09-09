using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI;

/// Reusable text editing: the cursor, the selection, keyboard shortcuts, mouse interaction,
/// the clipboard, and undo.
///
/// Works entirely in CHARACTER indices rather than byte offsets, and talks to its host only
/// through ITextEditHost. That is what keeps it independent of View, and what lets the same
/// logic drive a single line box, a password box and a multiline editor.
class TextEditingBehavior
{
	/// How long consecutive character inserts keep merging into one undo entry, in seconds.
	public float UndoCoalesceTime = 1.0f;
	public bool AllowClipboardCopy = true;

	private ITextEditHost mHost;
	private int32 mCursorPos = 0;
	private int32 mAnchorPos = 0;
	private UndoStack mUndoStack = new .() ~ delete _;
	/// OWNED. Null means no filtering.
	private InputFilter mInputFilter ~ delete _;
	private float mLastEditTime = 0.0f;
	private EditActionType mLastActionType = .None;

	/// BORROWS the host, which owns this.
	public this(ITextEditHost host)
	{
		mHost = host;
	}

	// ---- Cursor and selection ------------------------------------------------------------------

	public int32 CursorPosition
	{
		get => mCursorPos;
		set => mCursorPos = Clamp(value, 0, mHost.TextCharCount);
	}

	public int32 AnchorPosition
	{
		get => mAnchorPos;
		set => mAnchorPos = Clamp(value, 0, mHost.TextCharCount);
	}

	public int32 SelectionStart => Min(mAnchorPos, mCursorPos);
	public int32 SelectionEnd => Max(mAnchorPos, mCursorPos);
	public int32 SelectionLength => SelectionEnd - SelectionStart;
	public bool HasSelection => mCursorPos != mAnchorPos;
	public bool IsSelecting => HasSelection;

	public void SelectAll()
	{
		mAnchorPos = 0;
		mCursorPos = mHost.TextCharCount;
	}

	public UndoStack UndoStack => mUndoStack;

	/// Null when nothing is filtering.
	public InputFilter Filter => mInputFilter;

	/// OWNERSHIP transfers, and a second call deletes the first.
	public void SetFilter(InputFilter filter)
	{
		delete mInputFilter;
		mInputFilter = filter;
	}

	// ---- Input handlers ------------------------------------------------------------------------

	public void HandleTextInput(char32 character)
	{
		if (mHost.IsReadOnly)
			return;

		// Control characters are not text. Tab is the exception, being something a person
		// genuinely means to type.
		if (((uint32)character < 32) && (character != '\t'))
			return;

		if ((mInputFilter != null) && !mInputFilter.Accept(character))
			return;

		if (mHost.MaxLength > 0)
		{
			// The selection counts as available, because it is about to be replaced.
			let available = mHost.MaxLength - mHost.TextCharCount + SelectionLength;
			if (available <= 0)
				return;
		}

		PushUndoIfNeeded(.CharInsert);

		if (HasSelection)
			DeleteSelectionText();

		let text = scope String();
		text.Append(character);
		mHost.ReplaceText(mCursorPos, 0, text);
		mCursorPos++;
		mAnchorPos = mCursorPos;
		mLastEditTime = mHost.CurrentTime;
		mHost.OnTextModified();
	}

	public void HandleKeyDown(KeyCode key, KeyModifiers modifiers)
	{
		let ctrl = modifiers.HasAny(.Ctrl);
		let shift = modifiers.HasAny(.Shift);

		switch (key)
		{
		case .Left:
			BreakMergeChain();
			if (ctrl)
			{
				MoveWordLeft(shift);
			}
			else if (!shift && HasSelection)
			{
				// An unshifted arrow COLLAPSES a selection to its near edge rather than
				// moving from the cursor, which is what every editor does.
				let position = SelectionStart;
				mCursorPos = position;
				mAnchorPos = position;
			}
			else
			{
				MoveCursor(mCursorPos - 1, shift);
			}

		case .Right:
			BreakMergeChain();
			if (ctrl)
			{
				MoveWordRight(shift);
			}
			else if (!shift && HasSelection)
			{
				let position = SelectionEnd;
				mCursorPos = position;
				mAnchorPos = position;
			}
			else
			{
				MoveCursor(mCursorPos + 1, shift);
			}

		case .Up:
			if (mHost.IsMultiline)
			{
				BreakMergeChain();
				MoveLineUp(shift);
			}

		case .Down:
			if (mHost.IsMultiline)
			{
				BreakMergeChain();
				MoveLineDown(shift);
			}

		case .Return:
			if (mHost.IsMultiline && !mHost.IsReadOnly)
			{
				PushUndoIfNeeded(.CharInsert);
				if (HasSelection)
					DeleteSelectionText();
				mHost.ReplaceText(mCursorPos, 0, "\n");
				mCursorPos++;
				mAnchorPos = mCursorPos;
				mLastEditTime = mHost.CurrentTime;
				mHost.OnTextModified();
			}

		case .Home:
			BreakMergeChain();
			MoveHome(shift);

		case .End:
			BreakMergeChain();
			MoveEnd(shift);

		case .Backspace:
			if (mHost.IsReadOnly)
				return;
			PushUndoIfNeeded(.Delete);
			if (HasSelection)
			{
				DeleteSelectionText();
				mHost.OnTextModified();
			}
			else if (ctrl)
			{
				DeleteWordBackward();
			}
			else
			{
				DeleteBackward();
			}

		case .Delete:
			if (mHost.IsReadOnly)
				return;
			PushUndoIfNeeded(.Delete);
			if (HasSelection)
			{
				DeleteSelectionText();
				mHost.OnTextModified();
			}
			else if (ctrl)
			{
				DeleteWordForward();
			}
			else
			{
				DeleteForward();
			}

		case .A:
			if (ctrl)
				SelectAll();

		case .C:
			if (ctrl)
				CopyToClipboard();

		case .V:
			if (ctrl && !mHost.IsReadOnly)
				PasteFromClipboard();

		case .X:
			if (ctrl && !mHost.IsReadOnly)
				CutToClipboard();

		case .Z:
			if (ctrl && !shift)
				PerformUndo();
			else if (ctrl && shift)
				PerformRedo();

		case .Y:
			if (ctrl)
				PerformRedo();

		default:
		}
	}

	public void HandleMouseDown(float localX, float localY, int32 clickCount,
		KeyModifiers modifiers)
	{
		BreakMergeChain();
		let position = mHost.HitTestPosition(localX, localY);

		if (clickCount == 3)
		{
			SelectAll();
		}
		else if (clickCount == 2)
		{
			SelectWord(position);
		}
		else if (modifiers.HasAny(.Shift))
		{
			// Extends the selection: the anchor stays where it was.
			mCursorPos = position;
		}
		else
		{
			mCursorPos = position;
			mAnchorPos = position;
		}
	}

	/// Extends the selection during a drag.
	public void HandleMouseMove(float localX, float localY)
	{
		mCursorPos = mHost.HitTestPosition(localX, localY);
	}

	/// Resets when the text is set from code rather than typed.
	public void Reset()
	{
		mCursorPos = 0;
		mAnchorPos = 0;
		mUndoStack.Clear();
		mLastActionType = .None;
	}

	// ---- Text operations -----------------------------------------------------------------------

	private void CollectChars(List<char32> outChars)
	{
		for (let character in mHost.Text.DecodedChars)
			outChars.Add(character);
	}

	/// The number of CHARACTERS in a string, not bytes.
	private static int32 CharCount(StringView text)
	{
		var count = 0;
		for (let character in text.DecodedChars)
			count++;
		return (int32)count;
	}

	private void DeleteSelectionText()
	{
		if (!HasSelection)
			return;

		let start = SelectionStart;
		let length = SelectionLength;
		mHost.ReplaceText(start, length, "");
		mCursorPos = start;
		mAnchorPos = start;
	}

	private void DeleteBackward()
	{
		if (mCursorPos <= 0)
			return;
		mHost.ReplaceText(mCursorPos - 1, 1, "");
		mCursorPos--;
		mAnchorPos = mCursorPos;
		mHost.OnTextModified();
	}

	private void DeleteForward()
	{
		if (mCursorPos >= mHost.TextCharCount)
			return;
		mHost.ReplaceText(mCursorPos, 1, "");
		mAnchorPos = mCursorPos;
		mHost.OnTextModified();
	}

	private void DeleteWordBackward()
	{
		if (mCursorPos <= 0)
			return;
		let boundary = FindWordBoundaryLeft(mCursorPos);
		mHost.ReplaceText(boundary, mCursorPos - boundary, "");
		mCursorPos = boundary;
		mAnchorPos = mCursorPos;
		mHost.OnTextModified();
	}

	private void DeleteWordForward()
	{
		if (mCursorPos >= mHost.TextCharCount)
			return;
		let boundary = FindWordBoundaryRight(mCursorPos);
		mHost.ReplaceText(mCursorPos, boundary - mCursorPos, "");
		mAnchorPos = mCursorPos;
		mHost.OnTextModified();
	}

	// ---- Cursor movement -----------------------------------------------------------------------

	private void MoveCursor(int32 newPosition, bool extendSelection)
	{
		mCursorPos = Clamp(newPosition, 0, mHost.TextCharCount);
		if (!extendSelection)
			mAnchorPos = mCursorPos;
	}

	private void MoveWordLeft(bool extendSelection) =>
		MoveCursor(FindWordBoundaryLeft(mCursorPos), extendSelection);

	private void MoveWordRight(bool extendSelection) =>
		MoveCursor(FindWordBoundaryRight(mCursorPos), extendSelection);

	private void MoveLineUp(bool extendSelection)
	{
		let currentY = mHost.GetCursorYPosition(mCursorPos);
		let lineHeight = mHost.LineHeight;
		// Already on the first line.
		if (currentY < lineHeight * 0.5f)
			return;

		let currentX = mHost.GetCursorXPosition(mCursorPos);
		MoveCursor(mHost.HitTestGlyphPosition(currentX, currentY - lineHeight * 0.5f),
			extendSelection);
	}

	private void MoveLineDown(bool extendSelection)
	{
		let currentY = mHost.GetCursorYPosition(mCursorPos);
		let lineHeight = mHost.LineHeight;

		var totalLines = 1;
		for (let character in mHost.Text.DecodedChars)
		{
			if (character == '\n')
				totalLines++;
		}

		let currentLine = (lineHeight > 0) ? (int32)(currentY / lineHeight) : 0;
		// Already on the last line.
		if (currentLine >= totalLines - 1)
			return;

		let currentX = mHost.GetCursorXPosition(mCursorPos);
		MoveCursor(mHost.HitTestGlyphPosition(currentX, currentY + lineHeight * 1.5f),
			extendSelection);
	}

	private void MoveHome(bool extendSelection)
	{
		if (mHost.IsMultiline)
			MoveCursor(GetLineStart(mCursorPos), extendSelection);
		else
			MoveCursor(0, extendSelection);
	}

	private void MoveEnd(bool extendSelection)
	{
		if (mHost.IsMultiline)
			MoveCursor(GetLineEnd(mCursorPos), extendSelection);
		else
			MoveCursor(mHost.TextCharCount, extendSelection);
	}

	/// The character index of the start of the line holding `charIndex`.
	private int32 GetLineStart(int32 charIndex)
	{
		var lineStart = 0;
		var index = 0;
		for (let character in mHost.Text.DecodedChars)
		{
			if (index >= charIndex)
				break;
			if (character == '\n')
				lineStart = index + 1;
			index++;
		}
		return (int32)lineStart;
	}

	/// The character index of the end of the line holding `charIndex`.
	private int32 GetLineEnd(int32 charIndex)
	{
		var index = 0;
		for (let character in mHost.Text.DecodedChars)
		{
			if ((index >= charIndex) && (character == '\n'))
				return (int32)index;
			index++;
		}
		return mHost.TextCharCount;
	}

	// ---- Selection -----------------------------------------------------------------------------

	private void SelectWord(int32 position)
	{
		if (mHost.Text.IsEmpty)
			return;

		let charCount = mHost.TextCharCount;
		let clamped = Clamp(position, 0, charCount);

		let chars = scope List<char32>();
		CollectChars(chars);

		// A double click lands BETWEEN characters, so the word to take is the one just
		// before the caret.
		var start = ((clamped > 0) && (clamped <= charCount)) ? clamped - 1 : clamped;
		if ((start < charCount) && (start >= 0) && IsWordChar(chars[start]))
		{
			while ((start > 0) && IsWordChar(chars[start - 1]))
				start--;
		}
		else
		{
			start = clamped;
		}

		var end = start;
		while ((end < charCount) && IsWordChar(chars[end]))
			end++;

		mAnchorPos = start;
		mCursorPos = end;
	}

	// ---- Clipboard -----------------------------------------------------------------------------

	private void CopyToClipboard()
	{
		if (!HasSelection || !AllowClipboardCopy)
			return;

		let clipboard = mHost.Clipboard;
		if (clipboard == null)
			return;

		let selected = scope String();
		GetSelectedText(selected);
		clipboard.SetText(selected).IgnoreError();
	}

	private void CutToClipboard()
	{
		if (!HasSelection || mHost.IsReadOnly || !AllowClipboardCopy)
			return;

		CopyToClipboard();
		PushUndoIfNeeded(.Cut);
		DeleteSelectionText();
		mHost.OnTextModified();
	}

	private void PasteFromClipboard()
	{
		let clipboard = mHost.Clipboard;
		if ((clipboard == null) || !clipboard.HasText)
			return;

		let pasted = scope String();
		if (clipboard.GetText(pasted) case .Err)
			return;
		if (pasted.IsEmpty)
			return;

		// A single line control turns newlines into spaces rather than refusing the paste.
		// Safe byte wise: neither is ever a UTF-8 continuation byte.
		if (!mHost.IsMultiline)
		{
			for (int i < pasted.Length)
			{
				if ((pasted[i] == '\n') || (pasted[i] == '\r'))
					pasted[i] = ' ';
			}
		}

		if (mInputFilter != null)
		{
			let filtered = scope String();
			for (let character in pasted.DecodedChars)
			{
				if (mInputFilter.Accept(character))
					filtered.Append(character);
			}
			pasted.Set(filtered);
		}
		if (pasted.IsEmpty)
			return;

		if (mHost.MaxLength > 0)
		{
			let available = mHost.MaxLength - mHost.TextCharCount + SelectionLength;
			if (available <= 0)
				return;

			// Too long to fit: take what does, rather than dropping the paste entirely.
			if (CharCount(pasted) > available)
			{
				let truncated = scope String();
				var count = 0;
				for (let character in pasted.DecodedChars)
				{
					if (count >= available)
						break;
					truncated.Append(character);
					count++;
				}
				pasted.Set(truncated);
			}
		}

		PushUndoIfNeeded(.Paste);

		if (HasSelection)
			DeleteSelectionText();

		let inserted = CharCount(pasted);
		mHost.ReplaceText(mCursorPos, 0, pasted);
		mCursorPos += inserted;
		mAnchorPos = mCursorPos;
		mHost.OnTextModified();
	}

	/// Appends the selected characters to `outText`.
	private void GetSelectedText(String outText)
	{
		if (!HasSelection)
			return;

		let start = SelectionStart;
		let end = SelectionEnd;

		var index = 0;
		for (let character in mHost.Text.DecodedChars)
		{
			if ((index >= start) && (index < end))
				outText.Append(character);
			if (index >= end)
				break;
			index++;
		}
	}

	// ---- Undo ----------------------------------------------------------------------------------

	private void PushUndoIfNeeded(EditActionType actionType)
	{
		let time = mHost.CurrentTime;
		var shouldPush = false;

		if (actionType != mLastActionType)
			shouldPush = true;
		else if (actionType != .CharInsert)
			// Only typing coalesces. Repeated deletes and pastes each get their own entry.
			shouldPush = true;
		else if (time - mLastEditTime > UndoCoalesceTime)
			shouldPush = true;

		if (shouldPush)
			mUndoStack.PushState(mHost.Text, mCursorPos, mAnchorPos);

		mLastActionType = actionType;
		mLastEditTime = time;
	}

	/// Ends the run of merging edits, which navigation does.
	private void BreakMergeChain()
	{
		mLastActionType = .None;
	}

	private void PerformUndo()
	{
		let restored = scope String();
		int32 cursor = 0;
		int32 anchor = 0;

		if (!mUndoStack.Undo(mHost.Text, mCursorPos, mAnchorPos, restored, ref cursor, ref anchor))
			return;

		mHost.ReplaceText(0, mHost.TextCharCount, restored);
		mCursorPos = Clamp(cursor, 0, mHost.TextCharCount);
		mAnchorPos = Clamp(anchor, 0, mHost.TextCharCount);
		mLastActionType = .None;
		mHost.OnTextModified();
	}

	private void PerformRedo()
	{
		let restored = scope String();
		int32 cursor = 0;
		int32 anchor = 0;

		if (!mUndoStack.Redo(mHost.Text, mCursorPos, mAnchorPos, restored, ref cursor, ref anchor))
			return;

		mHost.ReplaceText(0, mHost.TextCharCount, restored);
		mCursorPos = Clamp(cursor, 0, mHost.TextCharCount);
		mAnchorPos = Clamp(anchor, 0, mHost.TextCharCount);
		mLastActionType = .None;
		mHost.OnTextModified();
	}

	// ---- Word boundaries -----------------------------------------------------------------------

	private int32 FindWordBoundaryLeft(int32 position)
	{
		if (position <= 0)
			return 0;

		let chars = scope List<char32>();
		CollectChars(chars);

		// Skip the gap to the left, but never across a line break: Ctrl+Left should stop at
		// the start of the line rather than run into the previous one.
		var p = position - 1;
		while ((p >= 0) && !IsWordChar(chars[p]) && (chars[p] != '\n'))
			p--;

		if ((p >= 0) && (chars[p] == '\n'))
			return p + 1;

		while ((p >= 0) && IsWordChar(chars[p]))
			p--;

		return p + 1;
	}

	private int32 FindWordBoundaryRight(int32 position)
	{
		let charCount = mHost.TextCharCount;
		if (position >= charCount)
			return charCount;

		let chars = scope List<char32>();
		CollectChars(chars);

		var p = position;
		while ((p < charCount) && IsWordChar(chars[p]))
			p++;

		while ((p < charCount) && !IsWordChar(chars[p]) && (chars[p] != '\n'))
			p++;

		return p;
	}

	/// DIVERGES from Raptor, which approximates this as ASCII alphanumerics plus anything at
	/// or above 0x80, and says so: C++ has no Unicode classification to hand. Beef does, and
	/// Raptor's comment names it as the thing being approximated, so the real test is used
	/// here. The two agree on ASCII, which is what Raptor's tests cover; they differ on
	/// non-ASCII punctuation, where treating an em dash as a letter is simply wrong.
	private static bool IsWordChar(char32 character) =>
		character.IsLetterOrDigit || (character == '_');
}
