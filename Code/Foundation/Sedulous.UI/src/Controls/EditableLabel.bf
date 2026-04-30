namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Fonts;

/// Reusable control that displays as a plain text label and switches to an
/// editable text field when BeginEdit() is called. Extends EditText for
/// cursor, selection, and clipboard support in edit mode.
///
/// In label mode: read-only, not focusable, draws plain text.
/// In edit mode: editable, focusable, draws cursor/selection/border.
///
/// Usage:
///   let label = new EditableLabel();
///   label.SetText("Hello");
///   label.OnRenameCommitted.Add(new (view, newText) => { ... });
///   // Later:
///   label.BeginEdit();
public class EditableLabel : EditText
{
	private bool mIsEditing;
	private String mPreEditText = new .() ~ delete _;

	// Slow-click detection (second single-click after delay on already-focused label)
	private float mLastClickTime;
	private bool mWasClickedOnce;

	/// Fired when the user commits a rename (Enter or focus loss).
	public Event<delegate void(EditableLabel, StringView)> OnRenameCommitted ~ _.Dispose();

	/// Fired when the user cancels a rename (Escape).
	public Event<delegate void(EditableLabel)> OnRenameCancelled ~ _.Dispose();

	/// Whether the label is currently in edit mode.
	public bool IsEditing => mIsEditing;

	/// Optional left padding for text (e.g. for tree item indentation).
	public float TextOffsetX;

	/// Horizontal text alignment in label mode. Default: Left.
	public TextAlignment HAlign = .Left;

	/// Whether double-click enters edit mode. Default true for standalone use.
	/// Disable when inside a ListView where double-click has a different meaning (e.g. navigate).
	public bool DoubleClickToEdit = true;

	/// Whether slow-click (second single-click after delay) enters edit mode.
	/// Default true. Disable if the control is not expected to be renamed by clicking.
	public bool SlowClickToEdit = true;

	public this()
	{
		FontSize = 12;
		Cursor = .Arrow;
		IsReadOnly = true;
		IsFocusable = false;
	}

	/// Set the display text. Does not interrupt an active edit.
	public new void SetText(StringView text)
	{
		if (mIsEditing)
			return;
		base.SetText(text);
	}

	/// Enter edit mode: select all text, show cursor.
	public void BeginEdit()
	{
		if (mIsEditing) return;
		mIsEditing = true;
		mWasClickedOnce = false;
		mPreEditText.Set(Text);
		IsReadOnly = false;
		IsFocusable = true;
		Cursor = .IBeam;

		// Focus and select all
		Context?.FocusManager.SetFocus(this);
		mBehavior.HandleKeyDown(.A, .Ctrl); // select all
	}

	/// Optional validation delegate. Return true if the name is valid.
	/// If null, only empty text is rejected.
	public delegate bool(StringView) ValidateRename ~ delete _;

	/// Commit the edit and exit edit mode.
	private void CommitEdit()
	{
		if (!mIsEditing) return;

		let newText = Text;

		// Validate: reject empty text
		if (newText.Length == 0 || newText.IsWhiteSpace)
		{
			CancelEdit();
			return;
		}

		// Validate: reject if unchanged
		if (StringView(newText) == StringView(mPreEditText))
		{
			CancelEdit();
			return;
		}

		// Validate: custom validator
		if (ValidateRename != null && !ValidateRename(newText))
		{
			CancelEdit();
			return;
		}

		mIsEditing = false;
		IsReadOnly = true;
		IsFocusable = false;
		Cursor = .Arrow;
		OnRenameCommitted(this, newText);
	}

	/// Cancel the edit, restore original text.
	private void CancelEdit()
	{
		if (!mIsEditing) return;
		mIsEditing = false;
		IsReadOnly = true;
		IsFocusable = false;
		Cursor = .Arrow;
		base.SetText(mPreEditText);
		OnRenameCancelled(this);
	}

	public override void OnFocusLost()
	{
		// Don't commit if focus was pushed to the stack for a popup (e.g. right-click
		// context menu). Focus will be restored when the popup closes via PopFocus.
		if (mIsEditing && Context?.FocusManager.FocusStackDepth == 0)
			CommitEdit();
		base.OnFocusLost();
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (mIsEditing)
		{
			if (e.Key == .Return)
			{
				CommitEdit();
				e.Handled = true;
				return;
			}
			if (e.Key == .Escape)
			{
				CancelEdit();
				e.Handled = true;
				return;
			}
			base.OnKeyDown(e);
			return;
		}
		// Not editing - don't handle keys (let parent ListView/TreeView process them)
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (mIsEditing)
		{
			base.OnMouseDown(e);
			return;
		}

		if (e.Button != .Left)
			return;

		// Double-click -> enter edit mode immediately (if enabled)
		if (DoubleClickToEdit && e.ClickCount >= 2)
		{
			BeginEdit();
			e.Handled = true;
			return;
		}

		// Slow-click: second single-click on an already-clicked label after a delay.
		// Only on single-click (ClickCount == 1) to avoid triggering on double-click.
		// Threshold: 0.4 - 1.5 seconds (fast enough to be intentional, slow enough
		// to not be a double-click). Matches the hierarchy view's rename pattern.
		if (SlowClickToEdit && e.ClickCount == 1)
		{
			let now = Context?.TotalTime ?? 0;
			if (mWasClickedOnce)
			{
				let elapsed = now - mLastClickTime;
				if (elapsed > 0.4f && elapsed < 1.5f)
				{
					BeginEdit();
					mWasClickedOnce = false;
					e.Handled = true;
					return;
				}
			}

			mWasClickedOnce = true;
			mLastClickTime = now;
		}
		// Don't set e.Handled - let parent handle selection
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		if (mIsEditing)
		{
			// Draw editing state: subtle background + EditText content
			let editBounds = RectangleF(TextOffsetX - 2, 0, Width - TextOffsetX + 2, Height);
			let bgColor = ctx.Theme?.GetColor("EditText.Background", .(30, 32, 42, 255)) ?? .(30, 32, 42, 255);
			ctx.VG.FillRoundedRect(editBounds, 2, bgColor);

			let borderColor = ctx.Theme?.Palette.PrimaryAccent ?? .(80, 160, 255, 255);
			ctx.VG.StrokeRoundedRect(editBounds, 2, borderColor, 1);

			DrawEditContent(ctx, TextOffsetX);
		}
		else
		{
			// Label mode: just draw text
			if (Text.Length > 0 && ctx.FontService != null)
			{
				let font = ctx.FontService.GetFont(FontSize);
				if (font != null)
				{
					let textBounds = RectangleF(TextOffsetX, 0, Width - TextOffsetX, Height);
					ctx.VG.DrawText(Text, font, textBounds, HAlign, .Middle, TextColor);
				}
			}
		}
	}

	/// Draws EditText content (selection, text glyphs, cursor) offset to the given X position.
	private void DrawEditContent(UIDrawContext ctx, float offsetX)
	{
		if (ctx.FontService == null) return;

		let font = ctx.FontService.GetFont(FontSize);
		if (font == null) return;

		let lineH = font.Font.Metrics.LineHeight;
		let contentX = offsetX;
		let contentW = Width - offsetX;
		let contentH = Height;
		let textY = (contentH - lineH) * 0.5f;

		ctx.PushClip(.(contentX, 0, contentW, contentH));

		EnsureGlyphsValid();

		let textX = contentX;

		// Selection highlight
		if (IsFocused && mBehavior.IsSelecting && font.Shaper != null)
		{
			let selColor = ctx.Theme?.GetColor("EditText.Selection", .(60, 120, 200, 100)) ?? .(60, 120, 200, 100);
			let selStart = font.Shaper.GetCursorPosition(font.Font, mGlyphPositions, mBehavior.SelectionStart);
			let selEnd = font.Shaper.GetCursorPosition(font.Font, mGlyphPositions, mBehavior.SelectionEnd);
			ctx.VG.FillRect(.(textX + selStart, textY, selEnd - selStart, lineH), selColor);
		}

		// Text glyphs
		if (mGlyphPositions.Count > 0)
		{
			ctx.VG.DrawPositionedGlyphs(mGlyphPositions, font,
				textX, textY + font.Font.Metrics.Ascent, TextColor);
		}

		// Cursor
		if (IsFocused)
		{
			let elapsed = (Context?.TotalTime ?? 0) - mCursorBlinkResetTime;
			let cursorVisible = ((int)(elapsed / 0.5f) % 2) == 0;
			if (cursorVisible && font.Shaper != null)
			{
				let cursorX = font.Shaper.GetCursorPosition(font.Font, mGlyphPositions, mBehavior.CursorPosition);
				let cursorColor = ctx.Theme?.Palette.Text ?? .(220, 225, 235, 255);
				ctx.VG.FillRect(.(textX + cursorX - 1, textY, 2, lineH), cursorColor);
			}
		}

		ctx.PopClip();
	}
}
