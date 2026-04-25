namespace Sedulous.Editor.App;

using Sedulous.UI;
using Sedulous.Core.Mathematics;
using Sedulous.Fonts;
using System;

/// View for a single item in the scene hierarchy tree.
/// Extends EditText for inline rename support. Draws as a plain label
/// when not editing; shows cursor/selection when focused for rename.
class HierarchyItemView : EditText
{
	public int32 Depth;
	public bool IsEditing;
	private float mIndentWidth = 20;
	private String mPreEditText = new .() ~ delete _;

	/// Fired when the user commits a rename. Parameter: new name.
	public Event<delegate void(HierarchyItemView, StringView)> OnRenameCommitted ~ _.Dispose();

	/// Fired when the user cancels a rename.
	public Event<delegate void(HierarchyItemView)> OnRenameCancelled ~ _.Dispose();

	public this()
	{
		FontSize = 12;
		Padding = .(0);
		Cursor = .Arrow;
		IsReadOnly = true;
		IsFocusable = false;
	}

	public void Set(StringView text, int32 depth)
	{
		Depth = depth;
		// Don't overwrite text or cancel edit if we're actively editing this item
		if (IsEditing)
			return;
		SetText(text);
	}

	/// Enter rename mode: select all text, show cursor.
	public void BeginEdit()
	{
		if (IsEditing) return;
		IsEditing = true;
		mPreEditText.Set(Text);
		IsReadOnly = false;
		IsFocusable = true;
		Cursor = .IBeam;

		// Focus and select all
		Context?.FocusManager.SetFocus(this);
		mBehavior.HandleKeyDown(.A, .Ctrl); // select all
	}

	/// Commit the edit and exit rename mode.
	private void CommitEdit()
	{
		if (!IsEditing) return;
		IsEditing = false;
		IsReadOnly = true;
		IsFocusable = false;
		Cursor = .Arrow;
		OnRenameCommitted(this, Text);
	}

	/// Cancel the edit, restore original text.
	private void CancelEdit()
	{
		if (!IsEditing) return;
		IsEditing = false;
		IsReadOnly = true;
		IsFocusable = false;
		Cursor = .Arrow;
		SetText(mPreEditText);
		OnRenameCancelled(this);
	}

	public override void OnFocusLost()
	{
		if (IsEditing)
			CommitEdit();
		base.OnFocusLost();
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (IsEditing)
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
		// Not editing — don't handle keys (let TreeView/ListView process them)
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (IsEditing)
		{
			base.OnMouseDown(e);
			return;
		}
		// Not editing — don't intercept mouse (let ListView handle selection)
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		let indent = (Depth + 1) * mIndentWidth;

		if (IsEditing)
		{
			// Draw editing state: subtle background + full EditText content
			let editBounds = RectangleF(indent - 2, 0, Width - indent + 2, Height);
			let bgColor = ctx.Theme?.GetColor("EditText.Background", .(30, 32, 42, 255)) ?? .(30, 32, 42, 255);
			ctx.VG.FillRoundedRect(editBounds, 2, bgColor);

			let borderColor = ctx.Theme?.Palette.PrimaryAccent ?? .(80, 160, 255, 255);
			ctx.VG.StrokeRoundedRect(editBounds, 2, borderColor, 1);

			// Offset EditText content drawing to indent position
			// Use the EditText's internal drawing for cursor/selection/text
			DrawEditContent(ctx, indent);
		}
		else
		{
			// Label mode: just draw text
			if (Text.Length > 0 && ctx.FontService != null)
			{
				let font = ctx.FontService.GetFont(FontSize);
				if (font != null)
				{
					let textColor = ctx.Theme?.GetColor("Label.Foreground") ?? .(220, 220, 230, 255);
					ctx.VG.DrawText(Text, font, .(indent, 0, Width - indent, Height), .Left, .Middle, textColor);
				}
			}
		}
	}

	/// Draws EditText content (selection, text glyphs, cursor) offset to indent position.
	private void DrawEditContent(UIDrawContext ctx, float indent)
	{
		if (ctx.FontService == null) return;

		let font = ctx.FontService.GetFont(FontSize);
		if (font == null) return;

		let lineH = font.Font.Metrics.LineHeight;
		let contentX = indent;
		let contentW = Width - indent;
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
			let textColor = ctx.Theme?.GetColor("Label.Foreground") ?? .(220, 220, 230, 255);
			ctx.VG.DrawPositionedGlyphs(mGlyphPositions, font,
				textX, textY + font.Font.Metrics.Ascent, textColor);
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
