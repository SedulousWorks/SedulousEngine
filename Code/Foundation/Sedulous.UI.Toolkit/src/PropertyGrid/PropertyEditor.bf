namespace Sedulous.UI.Toolkit;

using System;
using Sedulous.UI;

/// Abstract base for typed property editors used by PropertyGrid.
/// Subclasses implement CreateEditorView() to return the editing control
/// and RefreshView() to update it from external state.
///
/// Supports transactional editing for undo/redo integration:
///   OnEditBegin    - fired once when an edit gesture starts (drag begins, text field focused)
///   OnValueChanged - fired each time the value changes during the edit
///   OnEditEnd      - fired once when the edit gesture completes (drag ends, Enter pressed)
///   OnEditCancelled - fired if the edit is cancelled (Escape pressed)
///
/// Consumers should create one undo entry per Begin->End transaction, not per value change.
public abstract class PropertyEditor
{
	private String mName ~ delete _;
	private String mCategory ~ delete _;
	private View mEditorView;
	private bool mIsEditing;

	/// Fired each time the value changes (may fire multiple times per edit gesture).
	public Event<delegate void(PropertyEditor)> OnValueChanged ~ _.Dispose();

	/// Fired once when an edit gesture begins (drag start, text field focus, etc.).
	public Event<delegate void(PropertyEditor)> OnEditBegin ~ _.Dispose();

	/// Fired once when an edit gesture completes successfully.
	public Event<delegate void(PropertyEditor)> OnEditEnd ~ _.Dispose();

	/// Fired if an edit gesture is cancelled (Escape key, etc.).
	public Event<delegate void(PropertyEditor)> OnEditCancelled ~ _.Dispose();

	public StringView Name => mName;
	public StringView Category => (mCategory != null) ? mCategory : "";

	/// Whether an edit gesture is currently in progress.
	public bool IsEditing => mIsEditing;

	public this(StringView name, StringView category = default)
	{
		mName = new String(name);
		if (category.Length > 0)
			mCategory = new String(category);
	}

	/// Get or create the editor view (lazy).
	public View EditorView
	{
		get
		{
			if (mEditorView == null)
				mEditorView = CreateEditorView();
			return mEditorView;
		}
	}

	/// Create the editing control. Called once, lazily.
	protected abstract View CreateEditorView();

	/// Refresh the view from the current value (for external state changes).
	public abstract void RefreshView();

	/// Notify that the value changed (call from subclasses).
	protected void NotifyValueChanged()
	{
		OnValueChanged(this);
	}

	/// Call when an edit gesture begins. Subclasses should call this at the start
	/// of a drag, when a text field gains focus, etc.
	protected void BeginEdit()
	{
		if (!mIsEditing)
		{
			mIsEditing = true;
			OnEditBegin(this);
		}
	}

	/// Call when an edit gesture completes successfully. Subclasses should call this
	/// when a drag ends, Enter is pressed, text field loses focus, etc.
	protected void EndEdit()
	{
		if (mIsEditing)
		{
			mIsEditing = false;
			OnEditEnd(this);
		}
	}

	/// Call when an edit gesture is cancelled (Escape pressed, etc.).
	protected void CancelEdit()
	{
		if (mIsEditing)
		{
			mIsEditing = false;
			OnEditCancelled(this);
		}
	}
}
