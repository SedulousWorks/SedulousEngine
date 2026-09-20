using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.Editor.Scene;

/// An amber advisory in a property row, for a component whose state cannot work as set.
class NoticeEditor : PropertyEditor
{
	public String Message = new .() ~ delete _;

	public this(StringView name, StringView category) : base(name, category) {}

	public override void RefreshView() {}

	protected override View CreateEditorView()
	{
		let label = new Label(Message);
		label.WordWrap.Value = true;
		label.TextColor.Value = Color(0.95f, 0.75f, 0.2f, 1.0f);
		return label;
	}
}
