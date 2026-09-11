using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// A text property: an edit field whose transaction is bounded by FOCUS.
///
/// Taking focus opens the edit and remembers the value; losing it commits; Escape puts the
/// remembered value back and cancels. Focus is the boundary rather than each keystroke, so
/// typing a word is one undo step, not one per letter.
class StringEditor : PropertyEditor
{
	/// An edit field that reports its focus changes back to the editor. Sedulous exposes focus
	/// as overridable methods rather than events, so this is a subclass rather than a handler.
	private class FocusReportingEditText : EditText
	{
		private StringEditor mEditor;

		public this(StringEditor editor)
		{
			mEditor = editor;
		}

		public override void OnFocusGained()
		{
			base.OnFocusGained();
			mEditor.mPreEditValue.Set(mEditor.mValue);
			mEditor.BeginEdit();
		}

		public override void OnFocusLost()
		{
			base.OnFocusLost();
			if (!mEditor.IsEditing)
				return;

			mEditor.CommitFrom(Text);
			mEditor.EndEdit();
		}

		public override void OnKeyDown(KeyEventArgs e)
		{
			if ((e.Key == .Escape) && mEditor.IsEditing)
			{
				mEditor.mValue.Set(mEditor.mPreEditValue);
				SetText(mEditor.mPreEditValue);
				if (mEditor.Setter != null)
					mEditor.Setter(mEditor.mValue);
				mEditor.CancelEdit();
				e.Handled = true;
				return;
			}

			base.OnKeyDown(e);
		}
	}

	/// OWNED.
	public delegate void(StringView) Setter ~ delete _;

	private String mValue = new .() ~ delete _;
	private String mPreEditValue = new .() ~ delete _;
	/// BORROWED: the cached editor view owns it.
	private EditText mEditText = null;
	private bool mSyncing = false;

	/// CONSUMES the setter.
	public this(StringView name, StringView initialValue, delegate void(StringView) setter = null,
		StringView category = default) : base(name, category)
	{
		Setter = setter;
		mValue.Set(initialValue);
	}

	public StringView Value => mValue;

	public void SetValue(StringView value)
	{
		mValue.Set(value);
		if (!mSyncing)
			RefreshView();
	}

	public override void RefreshView()
	{
		if ((mEditText != null) && !mSyncing)
		{
			mSyncing = true;
			mEditText.SetText(mValue);
			mSyncing = false;
		}
	}

	protected override View CreateEditorView()
	{
		mEditText = new FocusReportingEditText(this);
		mEditText.SetText(mValue);
		mEditText.OnSubmit.Add(new [=](sender) =>
			{
				CommitFrom(sender.Text);
				// Submit ENDS the edit whether or not the text changed: pressing Return is the
				// user saying they are finished with this field.
				EndEdit();
			});
		return mEditText;
	}

	/// Takes the control's text as the new value and tells everyone, under the guard so a
	/// refresh writing the control back cannot be read as another edit.
	private void CommitFrom(StringView text)
	{
		if (mSyncing)
			return;

		mSyncing = true;
		mValue.Set(text);
		if (Setter != null)
			Setter(mValue);
		NotifyValueChanged();
		mSyncing = false;
	}
}
