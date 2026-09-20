using System;
using Sedulous.UI;

namespace Sedulous.Editor.App;

/// A small modal question with two or three labelled choices, delivered through OnChosen
/// before the dialog closes. First consumer: the property-animation panel's dirty guard
/// (Save / Discard / Cancel before loading over a modified clip); reusable for any
/// destructive-choice prompt. Escape is the last choice, conventionally Cancel.
class ConfirmDialog : Dialog
{
	/// The chosen button's index into the constructor's choices (Escape and close: the last).
	/// Owned.
	public delegate void(int index) OnChosen ~ delete _;

	private int mChoiceCount = 0;
	private bool mDelivered = false;

	public this(StringView title, StringView message, Span<StringView> choices) : base(title)
	{
		MinWidth.Value = 340.0f;
		MaxWidth.Value = 460.0f;

		let label = new Label(message);
		label.FontSize.Value = 12.0f;
		label.WordWrap.Value = true;
		SetContent(label);

		mChoiceCount = choices.Length;
		for (int i < choices.Length)
		{
			let button = AddButton(choices[i], .None);
			button.OnClick.Add(new [=i, =this](b) =>
				{
					Deliver(i);
					Close(.OK);
				});
		}
		// Any non-button dismissal (Escape) counts as the last choice.
		OnClosed.Add(new (dialog, result) =>
			{
				if (!mDelivered && (mChoiceCount > 0))
					Deliver(mChoiceCount - 1);
			});
	}

	private void Deliver(int index)
	{
		if (mDelivered)
			return;
		mDelivered = true;
		if (OnChosen != null)
			OnChosen(index);
	}
}
