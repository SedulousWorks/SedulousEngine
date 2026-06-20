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
public class EditableLabel : EditText
{
	private bool mIsEditing;
	private String mPreEditText = new .() ~ delete _;

	// Slow-click detection
	private float mLastClickTime;
	private bool mWasClickedOnce;

	/// Fired when the user commits a rename (Enter or focus loss).
	public Event<delegate void(EditableLabel, StringView)> OnRenameCommitted ~ _.Dispose();

	/// Fired when the user cancels a rename (Escape).
	public Event<delegate void(EditableLabel)> OnRenameCancelled ~ _.Dispose();

	/// Whether the label is currently in edit mode.
	public bool IsEditing => mIsEditing;

	/// Optional left padding for text (e.g. for tree item indentation).
	public Property<float> TextOffsetX = new .(0) ~ delete _;

	/// Horizontal text alignment in label mode.
	public Property<TextAlignment> HAlign = new .(.Left) ~ delete _;

	/// Whether to truncate text with "..." when it overflows in label mode.
	public Property<bool> Ellipsis = new .(false) ~ delete _;

	/// Override font size. When set, takes precedence over style resolution.
	public Property<float?> FontSize = new .(null) ~ delete _;

	/// Per-instance font family override. When set (and non-empty), overrides the style-resolved FontFamily.
	public Property<String> FontFamily = new .(null, .Visual) ~ { if (_.Value != null) delete _.Value; delete _; };

	/// Override text color. When set, takes precedence over style resolution.
	public Property<Color32?> TextColor = new .(null) ~ delete _;

	/// Whether double-click enters edit mode.
	public Property<bool> DoubleClickToEdit = new .(true) ~ delete _;

	/// Whether slow-click (second single-click after delay) enters edit mode.
	public Property<bool> SlowClickToEdit = new .(true) ~ delete _;

	/// Optional validation delegate. Return true if the name is valid.
	public delegate bool(StringView) ValidateRename ~ delete _;

	public this()
	{
		Cursor = .Arrow;
		IsReadOnly.Value = true;
		IsFocusable = false;
		IsTabStop = false;

		TextOffsetX.SetOwner(this);
		HAlign.SetOwner(this, .Visual);
		Ellipsis.SetOwner(this, .Visual);
		FontSize.SetOwner(this);
		FontFamily.SetOwner(this, .Visual);
		TextColor.SetOwner(this, .Visual);
		DoubleClickToEdit.SetOwner(this);
		SlowClickToEdit.SetOwner(this);
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
		IsReadOnly.Value = false;
		IsFocusable = true;
		IsTabStop = true;
		Cursor = .IBeam;

		Context?.FocusManager.SetFocus(this);
		mBehavior.HandleKeyDown(.A, .Ctrl); // select all
	}

	/// Commit the edit and exit edit mode.
	public void CommitEdit()
	{
		if (!mIsEditing) return;

		let newText = Text;

		// Reject empty/whitespace
		if (newText.Length == 0 || newText.IsWhiteSpace)
		{
			CancelEdit();
			return;
		}

		// Reject unchanged
		if (StringView(newText) == StringView(mPreEditText))
		{
			CancelEdit();
			return;
		}

		// Custom validator
		if (ValidateRename != null && !ValidateRename(newText))
		{
			CancelEdit();
			return;
		}

		mIsEditing = false;
		IsReadOnly.Value = true;
		IsFocusable = false;
		IsTabStop = false;
		Cursor = .Arrow;
		OnRenameCommitted(this, newText);
	}

	/// Cancel the edit, restore original text.
	public void CancelEdit()
	{
		if (!mIsEditing) return;
		mIsEditing = false;
		IsReadOnly.Value = true;
		IsFocusable = false;
		IsTabStop = false;
		Cursor = .Arrow;
		base.SetText(mPreEditText);
		OnRenameCancelled(this);
	}

	public override void OnFocusLost()
	{
		// Don't commit if focus was pushed to stack for a popup.
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
		// Not editing - don't handle keys
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

		// Double-click -> enter edit mode immediately
		if (DoubleClickToEdit.Value && e.ClickCount >= 2)
		{
			BeginEdit();
			e.Handled = true;
			return;
		}

		// Slow-click: second single-click after 0.4-1.5s delay
		if (SlowClickToEdit.Value && e.ClickCount == 1)
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

	public override void OnDraw(UIDrawContext ctx)
	{
		if (mIsEditing)
		{
			// Draw editing state: subtle background + accent border + text content
			let editBounds = RectangleF(TextOffsetX.Value - 2, 0, Width - TextOffsetX.Value + 2, Height);

			let bgDrawable = ResolveStyleDrawable(.Background);
			if (bgDrawable != null)
				bgDrawable.Draw(ctx, editBounds);
			else
				ctx.VG.FillRect(editBounds, .(30, 32, 42, 255));

			let borderColor = ResolveStyleColor(.AccentColor, ResolveStyleColor(.CursorColor, .(80, 160, 255, 255)));
			ctx.VG.StrokeRect(editBounds, borderColor, 1);

			DrawEditContent(ctx, TextOffsetX.Value);
		}
		else
		{
			// Label mode: draw text with optional ellipsis truncation.
			let fontSize = FontSize.Value ?? ResolveStyleFloat(.FontSize, 14);
			if (Text.Length > 0 && ctx.FontService != null)
			{
				let font = ctx.FontService.GetFont(ResolveStyleFontFamily(FontFamily.Value), fontSize);
				if (font != null)
				{
					let textColor = TextColor.Value ?? ResolveStyleColor(.TextColor, .(220, 225, 235, 255));
					let textBounds = RectangleF(TextOffsetX.Value, 0, Width - TextOffsetX.Value, Height);

					if (Ellipsis.Value)
					{
						let textW = font.Font.MeasureString(Text);
						if (textW > textBounds.Width)
						{
							let ellipsisStr = "...";
							let ellipsisW = font.Font.MeasureString(ellipsisStr);
							let availW = textBounds.Width - ellipsisW;

							if (availW <= 0)
							{
								ctx.VG.DrawText(ellipsisStr, font, textBounds, HAlign.Value, .Middle, textColor);
							}
							else
							{
								let truncated = scope String();
								for (let c in Text.RawChars)
								{
									truncated.Append(c);
									if (font.Font.MeasureString(truncated) > availW)
									{
										truncated.RemoveFromEnd(1);
										break;
									}
								}
								truncated.Append(ellipsisStr);
								ctx.VG.DrawText(truncated, font, textBounds, HAlign.Value, .Middle, textColor);
							}
						}
						else
						{
							ctx.VG.DrawText(Text, font, textBounds, HAlign.Value, .Middle, textColor);
						}
					}
					else
					{
						ctx.VG.DrawText(Text, font, textBounds, HAlign.Value, .Middle, textColor);
					}
				}
			}
		}
	}

	/// Draw edit content (selection, glyphs, cursor) offset to the given X.
	private void DrawEditContent(UIDrawContext ctx, float offsetX)
	{
		let fontSize = FontSize.Value ?? ResolveStyleFloat(.FontSize, 14);
		let contentW = Width - offsetX;

		ctx.VG.PushClipRect(.(offsetX, 0, contentW, Height));
		DrawTextContent(ctx, offsetX, 0, contentW, Height, fontSize);
		ctx.VG.PopClip();
	}
}
