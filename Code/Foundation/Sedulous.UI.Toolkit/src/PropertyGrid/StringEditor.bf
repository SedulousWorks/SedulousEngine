using System;
namespace Sedulous.UI.Toolkit;

/// String property editor - EditText with focus-based edit transactions.
/// BeginEdit on focus gained, EndEdit on focus lost or Enter.
/// Escape cancels the edit and restores the pre-edit value.
public class StringEditor : PropertyEditor
{
	private String mValue = new .() ~ delete _;
	private EditText mEditText;
	private String mPreEditValue = new .() ~ delete _;
	private bool mSyncing;

	public StringView Value
	{
		get => mValue;
		set { mValue.Set(value); if (!mSyncing) RefreshView(); }
	}

	public delegate void(StringView) Setter ~ delete _;

	public this(StringView name, StringView initialValue, delegate void(StringView) setter = null, StringView category = default)
		: base(name, category)
	{
		mValue.Set(initialValue);
		Setter = setter;
	}

	protected override View CreateEditorView()
	{
		let editText = new StringEditorEditText(this);
		mEditText = editText;
		mEditText.SetText(mValue);
		mEditText.OnSubmit.Add(new (et) =>
		{
			if (!mSyncing)
			{
				mSyncing = true;
				mValue.Set(et.Text);
				Setter?.Invoke(mValue);
				NotifyValueChanged();
				mSyncing = false;
			}
			EndEdit();
		});
		return mEditText;
	}

	/// EditText subclass that notifies the StringEditor on focus changes.
	private class StringEditorEditText : EditText
	{
		private StringEditor mEditor;

		public this(StringEditor editor) { mEditor = editor; }

		public override void OnFocusGained()
		{
			base.OnFocusGained();
			mEditor.mPreEditValue.Set(mEditor.mValue);
			mEditor.BeginEdit();
		}

		public override void OnFocusLost()
		{
			base.OnFocusLost();
			if (mEditor.IsEditing)
			{
				mEditor.mSyncing = true;
				mEditor.mValue.Set(Text);
				mEditor.Setter?.Invoke(mEditor.mValue);
				mEditor.NotifyValueChanged();
				mEditor.mSyncing = false;
				mEditor.EndEdit();
			}
		}

		public override void OnKeyDown(KeyEventArgs e)
		{
			if (e.Key == .Escape && mEditor.IsEditing)
			{
				mEditor.mValue.Set(mEditor.mPreEditValue);
				SetText(mEditor.mPreEditValue);
				mEditor.Setter?.Invoke(mEditor.mValue);
				mEditor.CancelEdit();
				e.Handled = true;
				return;
			}
			base.OnKeyDown(e);
		}
	}

	public override void RefreshView()
	{
		if (mEditText != null && !mSyncing) { mSyncing = true; mEditText.SetText(mValue); mSyncing = false; }
	}
}
