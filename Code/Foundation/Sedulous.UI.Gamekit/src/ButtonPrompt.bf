using System;
using Sedulous.Core;
using Sedulous.Input;
using Sedulous.UI;

namespace Sedulous.UI.Gamekit;

/// A device hint: "[E] Deliver". A binding keycap next to what pressing it does.
///
/// Set takes a binding label straight, which is pure display and needs no input module at all.
/// SetFromAction resolves an action's FIRST binding out of an input map and shows that, so a
/// rebound key updates the prompt without the prompt knowing what the binding is.
///
/// NOT YET, and it needs input side work first: switching on the ACTIVE device, so the same
/// prompt reads "[A]" on a pad and "[E]" on a keyboard, and pad button glyphs instead of names.
/// The first binding as text is correct for a single scheme game and a reasonable default
/// otherwise.
class ButtonPrompt : FlexLayout
{
	/// BORROWED: both labels are owned by the child list.
	private Label mKeycap = null;
	private Label mText = null;

	public this()
	{
		Direction = .Horizontal;
		AlignItems = .Center;
		Spacing = 6.0f;
		AddClass("button-prompt");

		mKeycap = new Label();
		mKeycap.AddClass("keycap"); // the theme can draw a key cap chip around it
		AddView(mKeycap);

		mText = new Label();
		AddView(mText);
	}

	/// The "[E]" chip.
	public Label Keycap => mKeycap;

	/// The action description beside it.
	public Label TextLabel => mText;

	/// Shows a binding label and action text directly.
	public void Set(StringView bindingLabel, StringView text)
	{
		mKeycap.SetText(scope $"[{bindingLabel}]");
		mText.SetText(text);
	}

	/// Resolves an action's first binding, searching every set, and shows it.
	///
	/// A missing or unbound action shows "-" rather than an empty chip, so the prompt still
	/// occupies its space and reads as unbound instead of looking like a layout fault.
	public void SetFromAction(InputMap map, StringView actionName, StringView text)
	{
		let resolved = scope String();

		if (map != null)
		{
			for (let set in map.Sets)
			{
				for (let action in set.Actions)
				{
					if ((action.Name == actionName) && !action.Bindings.IsEmpty)
					{
						BindingNames.DescribeBinding(action.Bindings[0], resolved);
						break;
					}
				}

				if (!resolved.IsEmpty)
					break;
			}
		}

		Set(resolved.IsEmpty ? StringView("-") : StringView(resolved), text);
	}
}
