namespace Sedulous.UI;

using System;
using System.Collections;

/// Type of editing action for undo coalescing.
public enum EditActionType
{
	None,
	CharInsert,
	Delete,
	Paste,
	Cut
}

/// Reusable text editing logic: cursor management, selection, keyboard
/// shortcuts, mouse interaction, clipboard, and undo/redo.
/// Operates on character indices (not byte offsets).
public class TextEditingBehavior
{
	private ITextEditHost mHost;
	private int32 mCursorPos;
	private int32 mAnchorPos;
	private UndoStack mUndoStack = new .() ~ delete _;
	private InputFilter mInputFilter ~ delete _;
	private float mLastEditTime;
	private EditActionType mLastActionType = .None;

	private bool HasSelection => mCursorPos != mAnchorPos;

	public int32 CursorPosition
	{
		get => mCursorPos;
		set => mCursorPos = Math.Clamp(value, 0, mHost.TextCharCount);
	}

	public int32 AnchorPosition
	{
		get => mAnchorPos;
		set => mAnchorPos = Math.Clamp(value, 0, mHost.TextCharCount);
	}

	public int32 SelectionStart => Math.Min(mAnchorPos, mCursorPos);
	public int32 SelectionEnd => Math.Max(mAnchorPos, mCursorPos);
	public int32 SelectionLength => SelectionEnd - SelectionStart;
	public bool IsSelecting => HasSelection;

	public InputFilter Filter
	{
		get => mInputFilter;
		set { delete mInputFilter; mInputFilter = value; }
	}

	public bool AllowClipboardCopy = true;

	public UndoStack UndoStack => mUndoStack;

	public this(ITextEditHost host)
	{
		mHost = host;
	}

	// === Public input handlers ===

	public void HandleTextInput(char32 character)
	{
		if (mHost.IsReadOnly)
			return;

		// Filter control characters.
		if (character < (char32)32 && character != '\t')
			return;

		// Apply input filter.
		if (mInputFilter != null && !mInputFilter.Accept(character))
			return;

		// MaxLength check.
		if (mHost.MaxLength > 0)
		{
			int32 availableChars = mHost.MaxLength - mHost.TextCharCount + SelectionLength;
			if (availableChars <= 0)
				return;
		}

		PushUndoIfNeeded(.CharInsert);

		// Delete selection if any.
		if (HasSelection)
			DeleteSelectionText();

		// Insert character.
		let charStr = scope String();
		charStr.Append(character);
		mHost.ReplaceText(mCursorPos, 0, charStr);
		mCursorPos++;
		mAnchorPos = mCursorPos;
		mLastEditTime = mHost.CurrentTime;
		mHost.OnTextModified();
	}

	public void HandleKeyDown(KeyCode key, KeyModifiers mods)
	{
		let ctrl = mods.HasFlag(.Ctrl);
		let shift = mods.HasFlag(.Shift);

		switch (key)
		{
		case .Left:
			BreakMergeChain();
			if (ctrl) MoveWordLeft(shift);
			else if (!shift && HasSelection)
			{
				let pos = SelectionStart;
				mCursorPos = pos;
				mAnchorPos = pos;
			}
			else
				MoveCursor(mCursorPos - 1, shift);
		case .Right:
			BreakMergeChain();
			if (ctrl) MoveWordRight(shift);
			else if (!shift && HasSelection)
			{
				let pos = SelectionEnd;
				mCursorPos = pos;
				mAnchorPos = pos;
			}
			else
				MoveCursor(mCursorPos + 1, shift);
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
				if (HasSelection) DeleteSelectionText();
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
			if (mHost.IsReadOnly) return;
			if (HasSelection) { PushUndoIfNeeded(.Delete); DeleteSelectionText(); mHost.OnTextModified(); }
			else if (ctrl) { PushUndoIfNeeded(.Delete); DeleteWordBackward(); }
			else { PushUndoIfNeeded(.Delete); DeleteBackward(); }
		case .Delete:
			if (mHost.IsReadOnly) return;
			if (HasSelection) { PushUndoIfNeeded(.Delete); DeleteSelectionText(); mHost.OnTextModified(); }
			else if (ctrl) { PushUndoIfNeeded(.Delete); DeleteWordForward(); }
			else { PushUndoIfNeeded(.Delete); DeleteForward(); }
		case .A:
			if (ctrl) SelectAll();
		case .C:
			if (ctrl) CopyToClipboard();
		case .V:
			if (ctrl && !mHost.IsReadOnly) PasteFromClipboard();
		case .X:
			if (ctrl && !mHost.IsReadOnly) CutToClipboard();
		case .Z:
			if (ctrl && !shift) PerformUndo();
			else if (ctrl && shift) PerformRedo();
		case .Y:
			if (ctrl) PerformRedo();
		default:
		}
	}

	public void HandleMouseDown(float localX, float localY, int32 clickCount, KeyModifiers mods)
	{
		BreakMergeChain();
		let pos = mHost.HitTestPosition(localX, localY);

		if (clickCount == 3)
		{
			// Triple-click: select all.
			SelectAll();
		}
		else if (clickCount == 2)
		{
			// Double-click: select word.
			SelectWord(pos);
		}
		else
		{
			if (mods.HasFlag(.Shift))
			{
				// Extend selection.
				mCursorPos = pos;
			}
			else
			{
				// Set cursor, clear selection.
				mCursorPos = pos;
				mAnchorPos = pos;
			}
		}
	}

	public void HandleMouseMove(float localX, float localY)
	{
		// Extend selection during drag.
		let pos = mHost.HitTestPosition(localX, localY);
		mCursorPos = pos;
	}

	/// Reset state when text is set programmatically.
	public void Reset()
	{
		mCursorPos = 0;
		mAnchorPos = 0;
		mUndoStack.Clear();
		mLastActionType = .None;
	}

	// === Text operations ===

	private void DeleteSelectionText()
	{
		if (!HasSelection) return;

		let start = SelectionStart;
		let length = SelectionLength;
		mHost.ReplaceText(start, length, "");
		mCursorPos = start;
		mAnchorPos = start;
	}

	private void DeleteBackward()
	{
		if (mCursorPos > 0)
		{
			mHost.ReplaceText(mCursorPos - 1, 1, "");
			mCursorPos--;
			mAnchorPos = mCursorPos;
			mHost.OnTextModified();
		}
	}

	private void DeleteForward()
	{
		if (mCursorPos < mHost.TextCharCount)
		{
			mHost.ReplaceText(mCursorPos, 1, "");
			mAnchorPos = mCursorPos;
			mHost.OnTextModified();
		}
	}

	private void DeleteWordBackward()
	{
		if (mCursorPos > 0)
		{
			let boundary = FindWordBoundaryLeft(mCursorPos);
			let count = mCursorPos - boundary;
			mHost.ReplaceText(boundary, count, "");
			mCursorPos = boundary;
			mAnchorPos = mCursorPos;
			mHost.OnTextModified();
		}
	}

	private void DeleteWordForward()
	{
		if (mCursorPos < mHost.TextCharCount)
		{
			let boundary = FindWordBoundaryRight(mCursorPos);
			let count = boundary - mCursorPos;
			mHost.ReplaceText(mCursorPos, count, "");
			mAnchorPos = mCursorPos;
			mHost.OnTextModified();
		}
	}

	// === Cursor movement ===

	private void MoveCursor(int32 newPos, bool extendSelection)
	{
		mCursorPos = Math.Clamp(newPos, 0, mHost.TextCharCount);
		if (!extendSelection)
			mAnchorPos = mCursorPos;
	}

	private void MoveWordLeft(bool extendSelection)
	{
		MoveCursor(FindWordBoundaryLeft(mCursorPos), extendSelection);
	}

	private void MoveWordRight(bool extendSelection)
	{
		MoveCursor(FindWordBoundaryRight(mCursorPos), extendSelection);
	}

	private void MoveLineUp(bool extendSelection)
	{
		let curY = mHost.GetCursorYPosition(mCursorPos);
		let lineH = mHost.LineHeight;

		// Already on the first line — do nothing.
		if (curY < lineH * 0.5f)
			return;

		let curX = mHost.GetCursorXPosition(mCursorPos);
		let newPos = mHost.HitTestGlyphPosition(curX, curY - lineH * 0.5f);
		MoveCursor(newPos, extendSelection);
	}

	private void MoveLineDown(bool extendSelection)
	{
		let curY = mHost.GetCursorYPosition(mCursorPos);
		let lineH = mHost.LineHeight;

		// Count total lines to check if we're on the last line.
		int32 totalLines = 1;
		for (let c in mHost.Text.DecodedChars)
			if (c == '\n') totalLines++;
		let currentLine = (int32)(curY / lineH);

		// Already on the last line — do nothing.
		if (currentLine >= totalLines - 1)
			return;

		let curX = mHost.GetCursorXPosition(mCursorPos);
		let newPos = mHost.HitTestGlyphPosition(curX, curY + lineH * 1.5f);
		MoveCursor(newPos, extendSelection);
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

	/// Get the char index of the start of the line containing charIndex.
	private int32 GetLineStart(int32 charIndex)
	{
		let text = mHost.Text;
		int32 lineStart = 0;
		int32 idx = 0;
		for (let c in text.DecodedChars)
		{
			if (idx >= charIndex) break;
			if (c == '\n') lineStart = idx + 1;
			idx++;
		}
		return lineStart;
	}

	/// Get the char index of the end of the line containing charIndex
	/// (the position of the \n, or TextCharCount if last line).
	private int32 GetLineEnd(int32 charIndex)
	{
		let text = mHost.Text;
		int32 idx = 0;
		for (let c in text.DecodedChars)
		{
			if (idx >= charIndex)
			{
				if (c == '\n') return idx;
			}
			idx++;
		}
		return mHost.TextCharCount;
	}

	// === Selection ===

	private void SelectAll()
	{
		mAnchorPos = 0;
		mCursorPos = mHost.TextCharCount;
	}

	private void SelectWord(int32 position)
	{
		let text = mHost.Text;
		if (text.IsEmpty) return;

		let charCount = mHost.TextCharCount;
		let pos = Math.Clamp(position, 0, charCount);

		var chars = scope List<char32>();
		for (let c in text.DecodedChars)
			chars.Add(c);

		// Find word start.
		var start = (pos > 0 && pos <= charCount) ? pos - 1 : pos;
		if (start < charCount && start >= 0 && IsWordChar(chars[start]))
		{
			while (start > 0 && IsWordChar(chars[start - 1]))
				start--;
		}
		else
		{
			start = pos;
		}

		// Find word end.
		var end = start;
		while (end < charCount && IsWordChar(chars[end]))
			end++;

		mAnchorPos = (int32)start;
		mCursorPos = (int32)end;
	}

	// === Clipboard ===

	private void CopyToClipboard()
	{
		if (!HasSelection || !AllowClipboardCopy) return;

		let clipboard = mHost.Clipboard;
		if (clipboard == null) return;

		let selectedText = scope String();
		GetSelectedText(selectedText);
		clipboard.SetText(selectedText);
	}

	private void CutToClipboard()
	{
		if (!HasSelection || mHost.IsReadOnly || !AllowClipboardCopy) return;

		CopyToClipboard();
		PushUndoIfNeeded(.Cut);
		DeleteSelectionText();
		mHost.OnTextModified();
	}

	private void PasteFromClipboard()
	{
		let clipboard = mHost.Clipboard;
		if (clipboard == null || !clipboard.HasText) return;

		let pasteText = scope String();
		if (clipboard.GetText(pasteText) case .Err) return;
		if (pasteText.IsEmpty) return;

		// Strip newlines for single-line.
		if (!mHost.IsMultiline)
		{
			pasteText.Replace('\n', ' ');
			pasteText.Replace('\r', ' ');
		}

		// Apply input filter to each character.
		if (mInputFilter != null)
		{
			let filtered = scope String();
			for (let c in pasteText.DecodedChars)
			{
				if (mInputFilter.Accept(c))
					filtered.Append(c);
			}
			pasteText.Set(filtered);
		}

		if (pasteText.IsEmpty) return;

		// MaxLength enforcement.
		if (mHost.MaxLength > 0)
		{
			int32 available = mHost.MaxLength - mHost.TextCharCount + SelectionLength;
			if (available <= 0) return;

			int32 pasteCharCount = 0;
			for (let c in pasteText.DecodedChars)
				pasteCharCount++;

			if (pasteCharCount > available)
			{
				let truncated = scope String();
				int32 count = 0;
				for (let c in pasteText.DecodedChars)
				{
					if (count >= available) break;
					truncated.Append(c);
					count++;
				}
				pasteText.Set(truncated);
			}
		}

		PushUndoIfNeeded(.Paste);

		if (HasSelection)
			DeleteSelectionText();

		// Count chars being inserted.
		int32 insertedChars = 0;
		for (let c in pasteText.DecodedChars)
			insertedChars++;

		mHost.ReplaceText(mCursorPos, 0, pasteText);
		mCursorPos += insertedChars;
		mAnchorPos = mCursorPos;
		mHost.OnTextModified();
	}

	// === Undo / Redo ===

	private void PushUndoIfNeeded(EditActionType actionType)
	{
		let time = mHost.CurrentTime;
		bool shouldPush = false;

		if (actionType != mLastActionType)
			shouldPush = true;
		else if (actionType != .CharInsert)
			shouldPush = true;
		else if (time - mLastEditTime > 1.0f) // coalescing window
			shouldPush = true;

		if (shouldPush)
			mUndoStack.PushState(mHost.Text, mCursorPos, mAnchorPos);

		mLastActionType = actionType;
		mLastEditTime = time;
	}

	/// Break the undo merge chain (called on navigation).
	private void BreakMergeChain()
	{
		mLastActionType = .None;
	}

	private void PerformUndo()
	{
		let restoredText = scope String();
		int32 restoredCursor = 0;
		int32 restoredAnchor = 0;

		if (mUndoStack.Undo(mHost.Text, mCursorPos, mAnchorPos,
			restoredText, out restoredCursor, out restoredAnchor))
		{
			mHost.ReplaceText(0, mHost.TextCharCount, restoredText);
			mCursorPos = Math.Clamp(restoredCursor, 0, mHost.TextCharCount);
			mAnchorPos = Math.Clamp(restoredAnchor, 0, mHost.TextCharCount);
			mLastActionType = .None;
			mHost.OnTextModified();
		}
	}

	private void PerformRedo()
	{
		let restoredText = scope String();
		int32 restoredCursor = 0;
		int32 restoredAnchor = 0;

		if (mUndoStack.Redo(mHost.Text, mCursorPos, mAnchorPos,
			restoredText, out restoredCursor, out restoredAnchor))
		{
			mHost.ReplaceText(0, mHost.TextCharCount, restoredText);
			mCursorPos = Math.Clamp(restoredCursor, 0, mHost.TextCharCount);
			mAnchorPos = Math.Clamp(restoredAnchor, 0, mHost.TextCharCount);
			mLastActionType = .None;
			mHost.OnTextModified();
		}
	}

	// === Word boundary helpers ===

	private int32 FindWordBoundaryLeft(int32 pos)
	{
		if (pos <= 0) return 0;

		let text = mHost.Text;
		var chars = scope List<char32>();
		for (let c in text.DecodedChars)
			chars.Add(c);

		// Skip non-word chars going left (stop at newlines).
		var p = pos - 1;
		while (p >= 0 && !IsWordChar(chars[p]) && chars[p] != '\n')
			p--;

		// If we hit a newline, stop after it.
		if (p >= 0 && chars[p] == '\n')
			return p + 1;

		// Skip word chars going left.
		while (p >= 0 && IsWordChar(chars[p]))
			p--;

		return p + 1;
	}

	private int32 FindWordBoundaryRight(int32 pos)
	{
		let text = mHost.Text;
		let charCount = mHost.TextCharCount;
		if (pos >= charCount) return charCount;

		var chars = scope List<char32>();
		for (let c in text.DecodedChars)
			chars.Add(c);

		// Skip word chars going right.
		var p = pos;
		while (p < charCount && IsWordChar(chars[p]))
			p++;

		// Skip non-word chars going right (stop at newlines).
		while (p < charCount && !IsWordChar(chars[p]) && chars[p] != '\n')
			p++;

		// If we hit a newline, stop at it (don't skip to next line).
		if (p < charCount && chars[p] == '\n')
			return p;

		return p;
	}

	private static bool IsWordChar(char32 c)
	{
		return c.IsLetterOrDigit || c == '_';
	}

	// === Helpers ===

	private void GetSelectedText(String outText)
	{
		if (!HasSelection) return;

		let text = mHost.Text;
		let start = SelectionStart;
		let end = SelectionEnd;

		int32 charIdx = 0;
		for (let c in text.DecodedChars)
		{
			if (charIdx >= start && charIdx < end)
				outText.Append(c);
			if (charIdx >= end) break;
			charIdx++;
		}
	}
}
