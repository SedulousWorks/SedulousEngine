using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// A row that is an ACTION rather than a value: "Add Condition", "Reset". It has no value, so
/// RefreshView has nothing to do.
class ButtonEditor : PropertyEditor
{
	/// OWNED.
	public delegate void() Action ~ delete _;

	/// BORROWED: the cached editor view owns it.
	private Button mButton = null;
	private bool mButtonEnabled = true;

	/// CONSUMES the action.
	public this(StringView name, delegate void() action, StringView category = default)
		: base(name, category)
	{
		Action = action;
	}

	public override void RefreshView() {}

	/// Greys the button and makes it click inert. Safe BEFORE the view exists: the state is
	/// applied when it is built, so an editor disabled at construction never flashes enabled.
	public void SetButtonEnabled(bool enabled)
	{
		mButtonEnabled = enabled;
		if ((mButton != null) && (mButton.IsEnabled != enabled))
		{
			mButton.IsEnabled = enabled;
			mButton.Invalidate();
		}
	}

	public bool ButtonEnabled => mButtonEnabled;

	protected override View CreateEditorView()
	{
		mButton = new Button(Name);
		mButton.IsEnabled = mButtonEnabled;
		// QUALIFIED: corlib names a delegate type Action, which wins over the field otherwise.
		mButton.OnClick.Add(new (sender) =>
			{
				if (this.Action != null)
					this.Action();
			});
		return mButton;
	}
}
