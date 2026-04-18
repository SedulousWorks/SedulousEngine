namespace Sedulous.UI.Toolkit;

using System;
using Sedulous.UI;

/// Abstract base for typed property editors used by PropertyGrid.
/// Subclasses implement CreateEditorView() to return the editing control
/// and RefreshView() to update it from external state.
public abstract class PropertyEditor
{
	private String mName ~ delete _;
	private String mCategory ~ delete _;
	private View mEditorView;

	public Event<delegate void(PropertyEditor)> OnValueChanged ~ _.Dispose();

	public StringView Name => mName;
	public StringView Category => (mCategory != null) ? mCategory : "";

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
}
