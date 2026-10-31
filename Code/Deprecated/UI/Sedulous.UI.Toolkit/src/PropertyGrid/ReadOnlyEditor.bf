using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// A value shown and never edited: a count, a derived length. A label in the value column,
/// refreshed like any editor, so a computed row reads the same as the rows around it.
class ReadOnlyEditor : PropertyEditor
{
	private String mText = new .() ~ delete _;
	/// BORROWED: the cached editor view owns it.
	private Label mLabel = null;

	public this(StringView name, StringView initialText, StringView category = default) : base(name, category)
	{
		mText.Set(initialText);
	}

	public StringView Value => mText;

	public void SetValue(StringView text)
	{
		if (mText == text)
			return;
		mText.Set(text);
		RefreshView();
	}

	public override void RefreshView()
	{
		if (mLabel != null)
			mLabel.SetText(mText);
	}

	protected override View CreateEditorView()
	{
		mLabel = new Label(mText);
		return mLabel;
	}
}
