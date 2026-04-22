using System;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.GUI;

/// Shared text editing logic for text input controls.
/// This class manages the text buffer, caret, selection, and undo/redo.
/// It does NOT handle rendering - that's the control's responsibility.
public class TextEditingBehavior
{
	// Text buffer
	private String mText = new .() ~ delete _;

	// Caret and selection
	private int32 mCaretPosition = 0;
	private int32 mSelectionAnchor = -1; // -1 = no selection

	// Undo/redo
	private UndoStack mUndoStack = new .() ~ delete _;

	// Caret blinking
	private double mLastCaretResetTime = 0;
	private const double CaretBlinkPeriod = 0.5; // seconds

	// Configuration
	private int32 mMaxLength = 0; // 0 = unlimited
	private bool mIsReadOnly = false;

	// Events
	private EventAccessor<delegate void()> mTextChanged = new .() ~ delete _;
	private EventAccessor<delegate void()> mSelectionChanged = new .() ~ delete _;

	/// The current text content.
	public StringView Text => mText;

	/// Sets the text content, clearing undo history.
	public void SetText(StringView text)
	{
		mText.Set(text);
		mCaretPosition = (int32)Math.Min(mCaretPosition, mText.Length);
		mSelectionAnchor = -1;
		mUndoStack.Clear();
		mTextChanged.[Friend]Invoke();
	}

	/// The current caret position (0 to text length).
	public int32 CaretPosition => mCaretPosition;

	/// Whether there is an active selection.
	public bool HasSelection => mSelectionAnchor >= 0 && mSelectionAnchor != mCaretPosition;

	/// Gets the selection range (normalized so Start <= End).
	public SelectionRange Selection
	{
		get
		{
			if (!HasSelection)
				return .(mCaretPosition, mCaretPosition);
			return .(Math.Min(mSelectionAnchor, mCaretPosition), Math.Max(mSelectionAnchor, mCaretPosition));
		}
	}

	/// Gets the selected text.
	public void GetSelectedText(String outText)
	{
		if (!HasSelection)
			return;
		let sel = Selection;
		// Clamp to valid range to prevent out-of-bounds access
		let start = Math.Min(sel.Start, (int32)mText.Length);
		let length = Math.Min(sel.Length, (int32)mText.Length - start);
		if (length > 0)
			outText.Append(mText, start, length);
	}

	/// Maximum text length (0 = unlimited).
	public int32 MaxLength
	{
		get => mMaxLength;
		set => mMaxLength = Math.Max(0, value);
	}

	/// Whether the text is read-only.
	public bool IsReadOnly
	{
		get => mIsReadOnly;
		set => mIsReadOnly = value;
	}

	/// Event fired when text changes.
	public EventAccessor<delegate void()> TextChanged => mTextChanged;

	/// Event fired when selection changes.
	public EventAccessor<delegate void()> SelectionChanged => mSelectionChanged;

	/// Whether an undo operation is available.
	public bool CanUndo => mUndoStack.CanUndo;

	/// Whether a redo operation is available.
	public bool CanRedo => mUndoStack.CanRedo;

	// === Caret Blinking ===

	/// Checks if the caret should be visible based on blink timing.
	public bool IsCaretVisible(double currentTime)
	{
		let elapsed = currentTime - mLastCaretResetTime;
		let phase = elapsed % (CaretBlinkPeriod * 2);
		return phase < CaretBlinkPeriod;
	}

	/// Resets the caret blink timer (shows caret immediately).
	public void ResetCaretBlink(double currentTime)
	{
		mLastCaretResetTime = currentTime;
	}

	// === Navigation ===

	/// Moves caret left by one character.
	public void MoveLeft(bool extendSelection)
	{
		if (!extendSelection && HasSelection)
		{
			// Move to start of selection
			mCaretPosition = Selection.Start;
			ClearSelection();
		}
		else
		{
			if (extendSelection && !HasSelection)
				mSelectionAnchor = mCaretPosition;

			if (mCaretPosition > 0)
			{
				// Handle UTF-8: move by one codepoint
				mCaretPosition = (int32)GetPrevCharIndex(mCaretPosition);
			}

			if (!extendSelection)
				ClearSelection();
		}
		mSelectionChanged.[Friend]Invoke();
		mUndoStack.BreakMergeChain();
	}

	/// Moves caret right by one character.
	public void MoveRight(bool extendSelection)
	{
		if (!extendSelection && HasSelection)
		{
			// Move to end of selection
			mCaretPosition = Selection.End;
			ClearSelection();
		}
		else
		{
			if (extendSelection && !HasSelection)
				mSelectionAnchor = mCaretPosition;

			if (mCaretPosition < mText.Length)
			{
				// Handle UTF-8: move by one codepoint
				mCaretPosition = (int32)GetNextCharIndex(mCaretPosition);
			}

			if (!extendSelection)
				ClearSelection();
		}
		mSelectionChanged.[Friend]Invoke();
		mUndoStack.BreakMergeChain();
	}

	/// Moves caret to the start of the line/text.
	public void MoveToLineStart(bool extendSelection)
	{
		if (extendSelection && !HasSelection)
			mSelectionAnchor = mCaretPosition;

		mCaretPosition = 0;

		if (!extendSelection)
			ClearSelection();

		mSelectionChanged.[Friend]Invoke();
		mUndoStack.BreakMergeChain();
	}

	/// Moves caret to the end of the line/text.
	public void MoveToLineEnd(bool extendSelection)
	{
		if (extendSelection && !HasSelection)
			mSelectionAnchor = mCaretPosition;

		mCaretPosition = (int32)mText.Length;

		if (!extendSelection)
			ClearSelection();

		mSelectionChanged.[Friend]Invoke();
		mUndoStack.BreakMergeChain();
	}

	/// Moves caret to the previous word boundary.
	public void MoveToPreviousWord(bool extendSelection)
	{
		if (extendSelection && !HasSelection)
			mSelectionAnchor = mCaretPosition;

		mCaretPosition = FindPreviousWordBoundary(mCaretPosition);

		if (!extendSelection)
			ClearSelection();

		mSelectionChanged.[Friend]Invoke();
		mUndoStack.BreakMergeChain();
	}

	/// Moves caret to the next word boundary.
	public void MoveToNextWord(bool extendSelection)
	{
		if (extendSelection && !HasSelection)
			mSelectionAnchor = mCaretPosition;

		mCaretPosition = FindNextWordBoundary(mCaretPosition);

		if (!extendSelection)
			ClearSelection();

		mSelectionChanged.[Friend]Invoke();
		mUndoStack.BreakMergeChain();
	}

	// === Selection ===

	/// Selects all text.
	public void SelectAll()
	{
		mSelectionAnchor = 0;
		mCaretPosition = (int32)mText.Length;
		mSelectionChanged.[Friend]Invoke();
	}

	/// Clears the selection without moving the caret.
	public void ClearSelection()
	{
		mSelectionAnchor = -1;
	}

	/// Sets the selection range.
	public void SetSelection(int32 start, int32 length)
	{
		var start;
		start = (int32)Math.Clamp(start, 0, mText.Length);
		let end = (int32)Math.Clamp(start + length, 0, mText.Length);
		mSelectionAnchor = start;
		mCaretPosition = end;
		mSelectionChanged.[Friend]Invoke();
	}

	// === Editing ===

	/// Inserts text at the current caret position.
	/// If there's a selection, it replaces the selection.
	public bool InsertText(StringView text, double timestamp)
	{
		if (mIsReadOnly)
			return false;

		// Check max length
		if (mMaxLength > 0)
		{
			let available = mMaxLength - (int32)mText.Length + (HasSelection ? Selection.Length : 0);
			if (text.Length > available)
				return false;
		}

		let oldCaret = mCaretPosition;

		if (HasSelection)
		{
			// Replace selection
			let sel = Selection;
			let oldText = scope String();
			oldText.Append(mText, sel.Start, sel.Length);

			mText.Remove(sel.Start, sel.Length);
			mText.Insert(sel.Start, text);
			mCaretPosition = sel.Start + (int32)text.Length;
			mSelectionAnchor = -1;

			mUndoStack.RecordReplace(sel.Start, oldText, text, oldCaret, mCaretPosition, mSelectionAnchor, timestamp);
		}
		else
		{
			// Simple insert
			mText.Insert(mCaretPosition, text);
			mCaretPosition += (int32)text.Length;
			mSelectionAnchor = -1; // Clear any dormant selection

			mUndoStack.RecordInsert(oldCaret, text, oldCaret, mCaretPosition, timestamp);
		}

		mTextChanged.[Friend]Invoke();
		mSelectionChanged.[Friend]Invoke();
		return true;
	}

	/// Inserts a single character.
	public bool InsertCharacter(char32 c, double timestamp)
	{
		let str = scope String();
		str.Append(c);
		return InsertText(str, timestamp);
	}

	/// Deletes the character before the caret (backspace).
	public bool Backspace(double timestamp)
	{
		if (mIsReadOnly)
			return false;

		if (HasSelection)
		{
			return DeleteSelection(timestamp);
		}

		if (mCaretPosition == 0)
			return false;

		let oldCaret = mCaretPosition;
		let prevPos = GetPrevCharIndex(mCaretPosition);
		let deleteLen = mCaretPosition - (int32)prevPos;

		let deleted = scope String();
		deleted.Append(mText, (int)prevPos, deleteLen);

		mText.Remove((int)prevPos, deleteLen);
		mCaretPosition = (int32)prevPos;
		mSelectionAnchor = -1; // Clear any dormant selection

		mUndoStack.RecordDelete((int32)prevPos, deleted, oldCaret, mCaretPosition, timestamp);

		mTextChanged.[Friend]Invoke();
		mSelectionChanged.[Friend]Invoke();
		return true;
	}

	/// Deletes the character after the caret (delete key).
	public bool Delete(double timestamp)
	{
		if (mIsReadOnly)
			return false;

		if (HasSelection)
		{
			return DeleteSelection(timestamp);
		}

		if (mCaretPosition >= mText.Length)
			return false;

		let oldCaret = mCaretPosition;
		let nextPos = GetNextCharIndex(mCaretPosition);
		let deleteLen = (int32)nextPos - mCaretPosition;

		let deleted = scope String();
		deleted.Append(mText, mCaretPosition, deleteLen);

		mText.Remove(mCaretPosition, deleteLen);
		mSelectionAnchor = -1; // Clear any dormant selection

		mUndoStack.RecordDelete(mCaretPosition, deleted, oldCaret, mCaretPosition, timestamp);

		mTextChanged.[Friend]Invoke();
		mSelectionChanged.[Friend]Invoke();
		return true;
	}

	/// Deletes the word before the caret (Ctrl+Backspace).
	public bool DeleteWordBackward(double timestamp)
	{
		if (mIsReadOnly)
			return false;

		if (HasSelection)
			return DeleteSelection(timestamp);

		if (mCaretPosition == 0)
			return false;

		let oldCaret = mCaretPosition;
		let wordStart = FindPreviousWordBoundary(mCaretPosition);
		let deleteLen = mCaretPosition - wordStart;

		let deleted = scope String();
		deleted.Append(mText, wordStart, deleteLen);

		mText.Remove(wordStart, deleteLen);
		mCaretPosition = wordStart;
		mSelectionAnchor = -1; // Clear any dormant selection

		mUndoStack.RecordDelete(wordStart, deleted, oldCaret, mCaretPosition, timestamp);

		mTextChanged.[Friend]Invoke();
		mSelectionChanged.[Friend]Invoke();
		return true;
	}

	/// Deletes the word after the caret (Ctrl+Delete).
	public bool DeleteWordForward(double timestamp)
	{
		if (mIsReadOnly)
			return false;

		if (HasSelection)
			return DeleteSelection(timestamp);

		if (mCaretPosition >= mText.Length)
			return false;

		let oldCaret = mCaretPosition;
		let wordEnd = FindNextWordBoundary(mCaretPosition);
		let deleteLen = wordEnd - mCaretPosition;

		let deleted = scope String();
		deleted.Append(mText, mCaretPosition, deleteLen);

		mText.Remove(mCaretPosition, deleteLen);
		mSelectionAnchor = -1; // Clear any dormant selection

		mUndoStack.RecordDelete(mCaretPosition, deleted, oldCaret, mCaretPosition, timestamp);

		mTextChanged.[Friend]Invoke();
		mSelectionChanged.[Friend]Invoke();
		return true;
	}

	/// Deletes the current selection.
	private bool DeleteSelection(double timestamp)
	{
		if (!HasSelection)
			return false;

		let sel = Selection;
		let oldCaret = mCaretPosition;

		let deleted = scope String();
		deleted.Append(mText, sel.Start, sel.Length);

		mText.Remove(sel.Start, sel.Length);
		mCaretPosition = sel.Start;
		mSelectionAnchor = -1;

		mUndoStack.RecordDelete(sel.Start, deleted, oldCaret, mCaretPosition, timestamp);

		mTextChanged.[Friend]Invoke();
		mSelectionChanged.[Friend]Invoke();
		return true;
	}

	// === Clipboard ===

	/// Copies selected text to clipboard.
	public bool Copy(IClipboard clipboard)
	{
		if (clipboard == null || !HasSelection)
			return false;

		let text = scope String();
		GetSelectedText(text);
		return clipboard.SetText(text) case .Ok;
	}

	/// Cuts selected text to clipboard.
	public bool Cut(IClipboard clipboard, double timestamp)
	{
		if (mIsReadOnly || clipboard == null || !HasSelection)
			return false;

		if (!Copy(clipboard))
			return false;

		return DeleteSelection(timestamp);
	}

	/// Pastes text from clipboard.
	public bool Paste(IClipboard clipboard, double timestamp)
	{
		if (mIsReadOnly || clipboard == null)
			return false;

		let text = scope String();
		if (clipboard.GetText(text) case .Err)
			return false;

		if (text.IsEmpty)
			return false;

		return InsertText(text, timestamp);
	}

	// === Undo/Redo ===

	/// Undoes the last action.
	public bool Undo()
	{
		let action = mUndoStack.PopUndo();
		if (action == null)
			return false;

		// Apply the inverse of the action
		switch (action.Type)
		{
		case .Insert:
			// Remove the inserted text
			mText.Remove(action.Position, action.NewText.Length);
			break;
		case .Delete:
			// Re-insert the deleted text
			mText.Insert(action.Position, action.OldText);
			break;
		case .Replace:
			// Remove new text, insert old text
			mText.Remove(action.Position, action.NewText.Length);
			mText.Insert(action.Position, action.OldText);
			break;
		}

		mCaretPosition = action.OldCaretPos;
		mSelectionAnchor = action.OldSelectionAnchor;

		delete action;

		mTextChanged.[Friend]Invoke();
		mSelectionChanged.[Friend]Invoke();
		return true;
	}

	/// Redoes the last undone action.
	public bool Redo()
	{
		let action = mUndoStack.PopRedo();
		if (action == null)
			return false;

		// Re-apply the action
		switch (action.Type)
		{
		case .Insert:
			mText.Insert(action.Position, action.NewText);
			break;
		case .Delete:
			mText.Remove(action.Position, action.OldText.Length);
			break;
		case .Replace:
			mText.Remove(action.Position, action.OldText.Length);
			mText.Insert(action.Position, action.NewText);
			break;
		}

		mCaretPosition = action.NewCaretPos;
		mSelectionAnchor = -1;

		delete action;

		mTextChanged.[Friend]Invoke();
		mSelectionChanged.[Friend]Invoke();
		return true;
	}

	// === Input Handling ===

	/// Handles a key down event. Returns true if handled.
	public bool HandleKeyDown(KeyCode key, KeyModifiers modifiers, IClipboard clipboard, double timestamp)
	{
		let shift = modifiers.HasFlag(.Shift);
		let ctrl = modifiers.HasFlag(.Ctrl);

		switch (key)
		{
		case .Left:
			if (ctrl)
				MoveToPreviousWord(shift);
			else
				MoveLeft(shift);
			return true;

		case .Right:
			if (ctrl)
				MoveToNextWord(shift);
			else
				MoveRight(shift);
			return true;

		case .Home:
			MoveToLineStart(shift);
			return true;

		case .End:
			MoveToLineEnd(shift);
			return true;

		case .Backspace:
			if (ctrl)
				DeleteWordBackward(timestamp);
			else
				Backspace(timestamp);
			return true;

		case .Delete:
			if (ctrl)
				DeleteWordForward(timestamp);
			else
				Delete(timestamp);
			return true;

		case .A:
			if (ctrl)
			{
				SelectAll();
				return true;
			}

		case .C:
			if (ctrl)
			{
				Copy(clipboard);
				return true;
			}

		case .X:
			if (ctrl)
			{
				Cut(clipboard, timestamp);
				return true;
			}

		case .V:
			if (ctrl)
			{
				Paste(clipboard, timestamp);
				return true;
			}

		case .Z:
			if (ctrl)
			{
				if (shift)
					Redo();
				else
					Undo();
				return true;
			}

		case .Y:
			if (ctrl)
			{
				Redo();
				return true;
			}

		default:
		}

		return false;
	}

	/// Handles a text input event. Returns true if handled.
	public bool HandleTextInput(char32 character, double timestamp)
	{
		// Filter control characters
		if ((uint32)character < 32 && character != '\t')
			return false;

		return InsertCharacter(character, timestamp);
	}

	/// Handles a mouse click at a character index.
	public void HandleClick(int32 charIndex, bool extendSelection)
	{
		var charIndex;
		charIndex = (int32)Math.Clamp(charIndex, 0, mText.Length);

		if (extendSelection)
		{
			if (!HasSelection)
				mSelectionAnchor = mCaretPosition;
			mCaretPosition = charIndex;
		}
		else
		{
			mCaretPosition = charIndex;
			mSelectionAnchor = -1;
		}

		mSelectionChanged.[Friend]Invoke();
		mUndoStack.BreakMergeChain();
	}

	/// Handles mouse drag to a character index.
	public void HandleDrag(int32 charIndex)
	{
		var charIndex;
		charIndex = (int32)Math.Clamp(charIndex, 0, mText.Length);

		if (!HasSelection)
			mSelectionAnchor = mCaretPosition;

		mCaretPosition = charIndex;
		mSelectionChanged.[Friend]Invoke();
	}

	/// Handles a double-click at a character index (select word).
	public void HandleDoubleClick(int32 charIndex)
	{
		var charIndex;
		charIndex = (int32)Math.Clamp(charIndex, 0, mText.Length);

		// Find word boundaries
		let wordStart = FindWordStart(charIndex);
		let wordEnd = FindWordEnd(charIndex);

		mSelectionAnchor = wordStart;
		mCaretPosition = wordEnd;
		mSelectionChanged.[Friend]Invoke();
	}

	/// Handles a triple-click (select all).
	public void HandleTripleClick()
	{
		SelectAll();
	}

	// === Helper Methods ===

	/// Gets the byte index of the previous character (UTF-8 aware).
	private int GetPrevCharIndex(int32 pos)
	{
		if (pos <= 0)
			return 0;

		var p = pos - 1;
		// Skip continuation bytes (10xxxxxx)
		while (p > 0 && ((uint8)mText[p] & 0xC0) == 0x80)
			p--;
		return p;
	}

	/// Gets the byte index after the current character (UTF-8 aware).
	private int GetNextCharIndex(int32 pos)
	{
		if (pos >= mText.Length)
			return mText.Length;

		var p = pos;
		// Get first byte to determine char length
		let firstByte = (uint8)mText[p];
		if ((firstByte & 0x80) == 0)
			return p + 1; // ASCII
		else if ((firstByte & 0xE0) == 0xC0)
			return Math.Min(p + 2, (.)mText.Length); // 2-byte UTF-8
		else if ((firstByte & 0xF0) == 0xE0)
			return Math.Min(p + 3, (.)mText.Length); // 3-byte UTF-8
		else if ((firstByte & 0xF8) == 0xF0)
			return Math.Min(p + 4, (.)mText.Length); // 4-byte UTF-8
		return p + 1;
	}

	/// Finds the previous word boundary.
	private int32 FindPreviousWordBoundary(int32 pos)
	{
		if (pos <= 0)
			return 0;

		var p = pos;

		// Skip any trailing whitespace
		while (p > 0 && IsWhitespace(mText[(int)GetPrevCharIndex((.)p)]))
			p = (int32)GetPrevCharIndex((.)p);

		// Skip the word
		while (p > 0 && !IsWhitespace(mText[(int)GetPrevCharIndex((.)p)]))
			p = (int32)GetPrevCharIndex((.)p);

		return p;
	}

	/// Finds the next word boundary.
	private int32 FindNextWordBoundary(int32 pos)
	{
		if (pos >= mText.Length)
			return (int32)mText.Length;

		var p = pos;

		// Skip current word
		while (p < mText.Length && !IsWhitespace(mText[p]))
			p = (int32)GetNextCharIndex((.)p);

		// Skip whitespace
		while (p < mText.Length && IsWhitespace(mText[p]))
			p = (int32)GetNextCharIndex((.)p);

		return p;
	}

	/// Finds the start of the word containing the given position.
	private int32 FindWordStart(int32 pos)
	{
		if (pos <= 0)
			return 0;

		var p = pos;

		// If on whitespace, go back to previous word
		if (p < mText.Length && IsWhitespace(mText[p]))
		{
			while (p > 0 && IsWhitespace(mText[(int)GetPrevCharIndex((.)p)]))
				p = (int32)GetPrevCharIndex((.)p);
		}

		// Go back to start of word
		while (p > 0 && !IsWhitespace(mText[(int)GetPrevCharIndex((.)p)]))
			p = (int32)GetPrevCharIndex((.)p);

		return p;
	}

	/// Finds the end of the word containing the given position.
	private int32 FindWordEnd(int32 pos)
	{
		if (pos >= mText.Length)
			return (int32)mText.Length;

		var p = pos;

		// Skip to end of word
		while (p < mText.Length && !IsWhitespace(mText[p]))
			p = (int32)GetNextCharIndex((.)p);

		return p;
	}

	/// Checks if a character is whitespace.
	private static bool IsWhitespace(char8 c)
	{
		return c == ' ' || c == '\t' || c == '\n' || c == '\r';
	}
}
