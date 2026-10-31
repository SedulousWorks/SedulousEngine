using System;
using System.Text;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// [[CodeEditView]]'s keyboard and mouse.
///
/// The ordering here is the design: while the completion popup is open it routes keys FIRST,
/// and while a find bar field holds focus the capture phase claims only the few keys the editor
/// and the field would otherwise fight over. Everything the editor does not act on is left
/// unhandled so application shortcuts keep working.
extension CodeEditView
{
	/// The gutter is a click target for breakpoints, so it gets the arrow; the text area gets
	/// the I-beam. The scrollbars are children carrying their own cursor.
	public override CursorType CursorAt(Float2 localPoint) =>
		(localPoint.X < GutterWidth) ? CursorType.Arrow : CursorType.IBeam;

	public override bool WantsTextInput() => IsEffectivelyEnabled() && !ReadOnly;

	/// The find bar's fields consume most keys themselves, so Escape, F3 and Enter are claimed
	/// on the way DOWN, before they reach the field.
	public override void OnKeyDownCapture(KeyEventArgs e)
	{
		if ((mFindBarMode == .Closed) || (Context == null))
			return;

		let focused = Context.GetFocusManager().FocusedView;
		if ((focused == null) || (focused == this) || !IsInFindBar(focused))
			return;

		switch (e.Key)
		{
		case .Escape:
			CloseFindBar();
			e.Handled = true;
		case .F3:
			if (e.Modifiers.HasFlag(.Shift))
				FindPrevious();
			else
				FindNext();

			e.Handled = true;
		case .Return:
			if (mFindBarMode == .GoToLine)
				JumpToTypedLine();
			else if (focused == mReplaceField)
				ReplaceCurrent();
			else
				FindNext();

			e.Handled = true;
		default:
		}
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEffectivelyEnabled())
			return;

		// A focused find bar field owns the keyboard; anything bubbling up from it stays its
		// business, since the capture handler above already took the interplay keys.
		if (Context != null)
		{
			let focused = Context.GetFocusManager().FocusedView;
			if ((focused != null) && (focused != this))
				return;
		}

		// The popup routes its keys FIRST while open, WITHOUT stealing focus.
		let routed = mCompletion.HandleKey(e.Key);
		if (routed == .Accepted)
		{
			AcceptCompletion();
			e.Handled = true;
			return;
		}

		if ((routed == .Consumed) || (routed == .Dismissed))
		{
			Invalidate();
			e.Handled = true;
			return;
		}

		if (ProcessKey(e.Key, e.Modifiers))
			e.Handled = true;
	}

	public override void OnTextInput(TextInputEventArgs e)
	{
		if (!IsEffectivelyEnabled() || ReadOnly || ((uint32)e.Character < 0x20) ||
			((uint32)e.Character == 0x7F))
			return;

		let text = scope String();
		text.Append((char32)e.Character);
		InsertText(text, .Typing);

		// A trigger character reopens completion with an EMPTY prefix, so providers see the
		// receiver word left of the cursor. That is member completion, with no language
		// knowledge in the editor.
		if ((uint32)e.Character < 128)
		{
			for (let trigger in CompletionTriggerCharacters.RawChars)
			{
				if ((uint32)trigger == (uint32)e.Character)
				{
					OpenCompletion(true);
					e.Handled = true;
					return;
				}
			}
		}

		// Refilter while open; auto open once the identifier fragment is long enough. Word
		// characters only, so punctuation closes the popup through the empty prefix below.
		let prefix = PrefixView();
		if (mCompletion.IsOpen)
		{
			if ((mCursor.Line != mCompletion.Anchor.Line) || prefix.IsEmpty)
				mCompletion.Close();
			else
				mCompletion.Filter(prefix);
		}
		else if (Utf8Text.CharCount(prefix) >= AutoCompleteMinPrefix)
		{
			OpenCompletion(false);
		}

		e.Handled = true;
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled())
			return;

		if (Context != null)
			Context.GetFocusManager().SetFocus(this);

		mCompletion.Close();
		if (e.Button != .Left)
			return;

		// A click in the marker margin toggles a breakpoint on that line.
		if (ShowGutter && AllowBreakpoints && (e.X < MarkerMargin))
		{
			let line = (int32)((e.Y + mScrollY - PadTop) / LineHeight);
			if ((line >= 0) && (line < mDoc.LineCount))
			{
				let set = mDoc.ToggleMarker(line, .Breakpoint);
				OnBreakpointToggled(line, set);
				Invalidate();
			}

			e.Handled = true;
			return;
		}

		let pos = PositionAt(e.X, e.Y);
		if (e.ClickCount >= 3)
		{
			mAnchor = .(pos.Line, 0);
			mCursor = ((pos.Line + 1) < mDoc.LineCount)
				? CodePosition(pos.Line + 1, 0)
				: mDoc.EndPosition;
		}
		else if (e.ClickCount == 2)
		{
			let word = mDoc.WordAt(pos);
			mAnchor = word.Begin;
			mCursor = word.End;
		}
		else
		{
			if (!e.Modifiers.HasFlag(.Shift))
				mAnchor = pos;

			mCursor = pos;
			mDragging = true;
			if (Context != null)
				Context.GetFocusManager().SetCapture(this);
		}

		mDesiredColumn = -1;
		ResetBlink();
		Invalidate();
		e.Handled = true;
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		mLastHover = .(e.X, e.Y); // the diagnostics tooltip reads the hovered line
		if (!mDragging)
			return;

		mCursor = PositionAt(e.X, e.Y);
		mPendingCursorScroll = true;
		Invalidate();
		e.Handled = true;
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (!mDragging)
			return;

		mDragging = false;
		if (Context != null)
			Context.GetFocusManager().ReleaseCapture();

		e.Handled = true;
	}

	public override void OnMouseWheel(MouseWheelEventArgs e)
	{
		if (e.Modifiers.HasFlag(.Shift))
			mScrollX -= e.DeltaY * ColumnAdvance * 6.0f;
		else
			mScrollY -= e.DeltaY * LineHeight * 3.0f;

		ClampScroll();
		Invalidate();
		e.Handled = true;
	}

	public override void OnFocusGained() => ResetBlink();

	public override void OnFocusLost()
	{
		mDragging = false;
		mCompletion.Close();
		// Coming back to the editor starts a NEW undo unit: an edit made before leaving and
		// one made after are separate actions to the person doing them.
		mDoc.BreakUndoChain();
		Invalidate();
	}

	/// True when the key was consumed.
	private bool ProcessKey(KeyCode key, KeyModifiers mods)
	{
		let shift = mods.HasFlag(.Shift);
		let ctrl = mods.HasFlag(.Ctrl);
		let alt = mods.HasFlag(.Alt);

		switch (key)
		{
		// -- navigation --
		case .Left:
			if (HasSelection && !shift && !ctrl)
				MoveCursor(Selection.Begin, false);
			else
				MoveCursor(ctrl ? mDoc.PrevWordBoundary(mCursor) : LeftOf(mCursor), shift);

			return true;

		case .Right:
			if (HasSelection && !shift && !ctrl)
				MoveCursor(Selection.End, false);
			else
				MoveCursor(ctrl ? mDoc.NextWordBoundary(mCursor) : RightOf(mCursor), shift);

			return true;

		case .Up, .Down:
			if (alt && !ReadOnly)
			{
				MoveLine(key == .Down);
				return true;
			}

			int32 delta = (key == .Down) ? 1 : -1;
			let targetLine = mCursor.Line + delta;
			if ((targetLine < 0) || (targetLine >= mDoc.LineCount))
			{
				MoveCursor((delta < 0) ? CodePosition(0, 0) : mDoc.EndPosition, shift);
				return true;
			}

			if (mDesiredColumn < 0)
				mDesiredColumn = mCursor.Column;

			let keepColumn = mDesiredColumn;
			MoveCursor(.(targetLine, keepColumn), shift);
			// MoveCursor clamps to the new line's length; the GOAL column survives, so
			// stepping past a short line and back lands where it started.
			mDesiredColumn = keepColumn;
			return true;

		case .Home:
			if (ctrl)
			{
				MoveCursor(.(0, 0), shift);
				return true;
			}

			// Smart home: the first non space, then hard column zero.
			let indent = FirstNonSpaceColumn(mCursor.Line);
			MoveCursor(.(mCursor.Line, (mCursor.Column == indent) ? 0 : indent), shift);
			return true;

		case .End:
			MoveCursor(ctrl ? mDoc.EndPosition
				: CodePosition(mCursor.Line, mDoc.LineLength(mCursor.Line)), shift);
			return true;

		case .PageUp, .PageDown:
			let page = Math.Max(1, (int32)(mViewportH / LineHeight) - 1);
			let pageDelta = (key == .PageDown) ? page : -page;
			MoveCursor(.(mCursor.Line + pageDelta, mCursor.Column), shift);
			return true;

		// -- edits --
		case .Return:
			if (ReadOnly)
				return false;

			InsertNewline();
			return true;

		case .Backspace:
			if (ReadOnly)
				return false;

			if (HasSelection)
			{
				DeleteSpan(Selection, .Backspace);
			}
			else
			{
				let from = ctrl ? mDoc.PrevWordBoundary(mCursor) : LeftOf(mCursor);
				if (!(from == mCursor))
					DeleteSpan(.(from, mCursor), .Backspace);
			}

			if (mCompletion.IsOpen)
			{
				let prefix = PrefixView();
				if (prefix.IsEmpty)
					mCompletion.Close();
				else
					mCompletion.Filter(prefix);
			}

			return true;

		case .Delete:
			if (ReadOnly)
				return false;

			if (HasSelection)
			{
				DeleteSpan(Selection, .Delete);
			}
			else
			{
				let to = ctrl ? mDoc.NextWordBoundary(mCursor) : RightOf(mCursor);
				if (!(to == mCursor))
					DeleteSpan(.(mCursor, to), .Delete);
			}

			return true;

		case .Tab:
			if (ReadOnly)
				return false;

			HandleTab(shift);
			return true;

		case .Escape:
			if (mFindBarMode != .Closed)
			{
				CloseFindBar();
				return true;
			}

			if (HasSelection)
			{
				mAnchor = mCursor;
				Invalidate();
				return true;
			}

			return false;

		// -- find --
		case .F3:
			if (shift)
				FindPrevious();
			else
				FindNext();

			return true;

		case .F:
			if (!ctrl)
				return false;

			OpenFindBar(false);
			return true;

		case .H:
			if (!ctrl)
				return false;

			OpenFindBar(!ReadOnly);
			return true;

		case .G:
			if (!ctrl)
				return false;

			OpenGoToLine();
			return true;

		case .Slash:
			if (!ctrl || ReadOnly)
				return false;

			ToggleLineComment();
			return true;

		// -- chords --
		case .A:
			if (!ctrl)
				return false;

			SelectAll();
			return true;

		case .C:
			if (!ctrl)
				return false;

			CopySelection(false);
			return true;

		case .X:
			if (!ctrl)
				return false;

			CopySelection(!ReadOnly);
			return true;

		case .V:
			if (!ctrl || ReadOnly)
				return false;

			Paste();
			return true;

		case .Z:
			if (!ctrl || ReadOnly)
				return false;

			ApplyHistory(shift);
			return true;

		case .Y:
			if (!ctrl || ReadOnly)
				return false;

			ApplyHistory(true);
			return true;

		case .D:
			if (!ctrl || ReadOnly)
				return false;

			DuplicateLine();
			return true;

		case .Space:
			if (!ctrl)
				return false;

			OpenCompletion(true);
			return true;

		default:
			return false;
		}
	}

	/// Newline plus the current line's leading whitespace, and one extra indent step after an
	/// open brace. The brace rule is the only language shaped thing in the key handling, which
	/// is why it is a flag rather than a lexer question.
	private void InsertNewline()
	{
		let insert = scope String();
		insert.Append('\n');

		let line = mDoc.Line(mCursor.Line);
		let indentBytes = mDoc.ColumnToByte(mCursor.Line,
			Math.Min(FirstNonSpaceColumn(mCursor.Line), mCursor.Column));
		insert.Append(line.Substring(0, indentBytes));

		if (IndentAfterOpenBrace && (mCursor.Column > 0) &&
			(mDoc.CodepointAt(.(mCursor.Line, mCursor.Column - 1)) == (uint32)'{'))
		{
			for (int32 i < TabWidth)
				insert.Append(' ');
		}

		InsertText(insert, .Newline);
	}

	private void ApplyHistory(bool redo)
	{
		CodeCursorState state = .();
		if (!(redo ? mDoc.Redo(out state) : mDoc.Undo(out state)))
			return;

		mCursor = mDoc.ClampPosition(state.Cursor);
		mAnchor = mDoc.ClampPosition(state.Anchor);
		AfterEdit();
	}
}
