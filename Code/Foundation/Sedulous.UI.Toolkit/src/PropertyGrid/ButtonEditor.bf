namespace Sedulous.UI.Toolkit;

using System;
using Sedulous.UI;

/// Property editor that displays a clickable button.
/// Used for actions like "Add Condition" in list-editing contexts.
public class ButtonEditor : PropertyEditor
{
	public delegate void() Action ~ delete _;

	public this(StringView name, delegate void() action, StringView category = default)
		: base(name, category)
	{
		Action = action;
	}

	protected override View CreateEditorView()
	{
		let btn = new Button(Name);
		btn.OnClick.Add(new (b) => { Action?.Invoke(); });
		return btn;
	}

	public override void RefreshView() { }
}
