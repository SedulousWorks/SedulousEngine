using System;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.UI;

/// A label that becomes a text field when asked: rename in place, in a tree or a list.
///
/// It is an EditText that spends most of its life read only, unfocusable and drawing itself as
/// plain text. Editing turns all three back on, so a row of these costs no focus stops while
/// nobody is renaming anything.
class EditableLabel : EditText
{
	/// A slow double click is two clicks far enough apart not to be a double click, but close
	/// enough to be deliberate. These are the bounds of that window, in seconds.
	private const float SlowClickMin = 0.4f;
	private const float SlowClickMax = 1.5f;

	/// Where the text starts, so a row can leave room for an icon or an indent.
	public Property<float> TextOffsetX = new .(0.0f) ~ delete _;
	public Property<TextAlignment> HAlign = new .(.Left) ~ delete _;
	public Property<bool> Ellipsis = new .(false) ~ delete _;
	/// Null defers to the cascade's font size.
	public Property<float?> FontSize = new .() ~ delete _;
	/// Empty defers to the cascade's family.
	public Property<String> FontFamily = new .(new String()) ~ delete _;
	/// Null defers to the cascade's text colour.
	public Property<Color?> TextColor = new .() ~ delete _;
	public Property<bool> DoubleClickToEdit = new .(true) ~ delete _;
	public Property<bool> SlowClickToEdit = new .(true) ~ delete _;

	/// OWNED, and optional. Answers whether a new name is acceptable; a rejection cancels.
	public delegate bool(StringView) ValidateRename ~ delete _;

	public Event<delegate void(EditableLabel, StringView)> OnRenameCommitted ~ _.Dispose();
	public Event<delegate void(EditableLabel)> OnRenameCancelled ~ _.Dispose();

	private bool mIsEditing = false;
	private String mPreEditText = new .() ~ delete _;
	private float mLastClickTime = 0.0f;
	private bool mWasClickedOnce = false;

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

	public ~this()
	{
		delete FontFamily.Value;
	}

	public bool IsEditing => mIsEditing;

	/// Sets the displayed text, and does NOTHING while editing: the field holds what the user
	/// is typing, and a background update must not yank it away mid rename.
	///
	/// SHADOWS EditText.SetText rather than overriding it, so a caller holding an EditText
	/// reference reaches the base and can still write through.
	public new void SetText(StringView text)
	{
		if (mIsEditing)
			return;

		base.SetText(text);
	}

	// ---- Edit mode --------------------------------------------------------------------------

	/// Turns into a field: focusable, editable, everything selected.
	public void BeginEdit()
	{
		if (mIsEditing)
			return;

		mIsEditing = true;
		mWasClickedOnce = false;
		mPreEditText.Set(Text);

		IsReadOnly.Value = false;
		IsFocusable = true;
		IsTabStop = true;
		Cursor = .IBeam;

		if (Context != null)
			Context.GetFocusManager().SetFocus(this);

		// Everything selected, so typing replaces rather than appends: renaming usually means
		// a new name, not an edit of the old one.
		Behavior.HandleKeyDown(.A, .Ctrl);
	}

	/// Accepts the edit, unless there is nothing worth accepting.
	///
	/// Three refusals, all of which CANCEL rather than commit: an empty name, a name that did
	/// not change, and one a validator turned down. Each leaves the original text in place.
	public void CommitEdit()
	{
		if (!mIsEditing)
			return;

		let newText = Text;

		var trimmed = newText;
		trimmed.Trim();
		if (trimmed.IsEmpty)
		{
			CancelEdit();
			return;
		}

		if (newText == mPreEditText)
		{
			CancelEdit();
			return;
		}

		if ((ValidateRename != null) && !ValidateRename(newText))
		{
			CancelEdit();
			return;
		}

		LeaveEditMode();
		OnRenameCommitted(this, newText);
	}

	/// Abandons the edit and puts the original text back.
	public void CancelEdit()
	{
		if (!mIsEditing)
			return;

		LeaveEditMode();
		base.SetText(mPreEditText);
		OnRenameCancelled(this);
	}

	private void LeaveEditMode()
	{
		mIsEditing = false;
		IsReadOnly.Value = true;
		IsFocusable = false;
		IsTabStop = false;
		Cursor = .Arrow;
	}

	// ---- Input ------------------------------------------------------------------------------

	public override void OnFocusLost()
	{
		// NOT committed when the focus went onto the stack for a popup: the rename is still in
		// progress, and the field will get its focus back when the popup closes.
		if (mIsEditing && (Context != null) && (Context.GetFocusManager().FocusStackDepth == 0))
			CommitEdit();

		base.OnFocusLost();
	}

	/// Return commits through OnKeyDown; this is the OTHER way in, for a gamepad or a
	/// programmatic activation, with the same meaning.
	public override void OnActivate()
	{
		if (mIsEditing)
		{
			CommitEdit();
			return;
		}

		base.OnActivate();
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		// Not editing, so no keys are ours: a label in a list leaves navigation to the list.
		if (!mIsEditing)
			return;

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

		if (DoubleClickToEdit.Value && (e.ClickCount >= 2))
		{
			BeginEdit();
			e.Handled = true;
			return;
		}

		if (SlowClickToEdit.Value && (e.ClickCount == 1) && TrySlowClick())
		{
			e.Handled = true;
			return;
		}

		// Left UNHANDLED, so the press still reaches the row and selects it. A click on a name
		// selects; only a second, deliberate click renames.
	}

	/// Two clicks too far apart to be a double click but close enough to be meant.
	private bool TrySlowClick()
	{
		let now = (Context != null) ? Context.TotalTime : 0.0f;

		if (mWasClickedOnce)
		{
			let elapsed = now - mLastClickTime;
			if ((elapsed > SlowClickMin) && (elapsed < SlowClickMax))
			{
				BeginEdit();
				mWasClickedOnce = false;
				return true;
			}
		}

		mWasClickedOnce = true;
		mLastClickTime = now;
		return false;
	}

	// ---- Draw -------------------------------------------------------------------------------

	public override void OnDraw(UIDrawContext ctx)
	{
		if (mIsEditing)
		{
			DrawEditMode(ctx);
			return;
		}

		DrawLabelMode(ctx);
	}

	private void DrawEditMode(UIDrawContext ctx)
	{
		// The box starts two pixels LEFT of the text, so the border does not sit against the
		// first glyph.
		let offsetX = TextOffsetX.Value;
		let editBounds = Rectangle(offsetX - 2.0f, 0, Width - offsetX + 2.0f, Height);

		if (let background = ResolveStyleDrawable(.Background))
			background.Draw(ctx, editBounds);
		else
			ctx.VG.FillRect(editBounds, Color(30 / 255.0f, 32 / 255.0f, 42 / 255.0f, 1.0f));

		let borderColor = ResolveStyleColor(.AccentColor,
			ResolveStyleColor(.CursorColor, Color(80 / 255.0f, 160 / 255.0f, 1.0f, 1.0f)));
		ctx.VG.StrokeRect(editBounds, borderColor, 1.0f);

		let contentWidth = Width - offsetX;
		ctx.PushClip(.(offsetX, 0, contentWidth, Height));
		// Reuses EditText's own text drawing, so the caret and selection behave identically.
		DrawTextContent(ctx, offsetX, 0, contentWidth, Height, EffectiveFontSize);
		ctx.PopClip();
	}

	private void DrawLabelMode(UIDrawContext ctx)
	{
		let text = Text;
		if (text.IsEmpty || (ctx.FontService == null))
			return;

		let family = scope String();
		ResolveStyleFontFamily(family, FontFamily.Value);
		let font = ctx.FontService.GetFont(family, EffectiveFontSize);
		if (font == null)
			return;

		let color = (TextColor.Value != null)
			? TextColor.Value.Value
			: ResolveStyleColor(.TextColor, Color(220 / 255.0f, 225 / 255.0f, 235 / 255.0f, 1.0f));

		let offsetX = TextOffsetX.Value;
		let textBounds = Rectangle(offsetX, 0, Width - offsetX, Height);

		let shown = scope String();
		if (Ellipsis.Value)
			TruncateToWidth(font.Font, text, textBounds.Width, shown);
		else
			shown.Set(text);

		ctx.VG.DrawText(shown, font, textBounds, HAlign.Value, .Middle, color);
	}

	private float EffectiveFontSize =>
		(FontSize.Value != null) ? FontSize.Value.Value : ResolveStyleFloat(.FontSize, 14.0f);
}
