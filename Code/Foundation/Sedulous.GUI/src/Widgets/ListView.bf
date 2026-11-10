using System;
using Sedulous.Core;

namespace Sedulous.GUI;

// ListView: a virtualised list over a model (eepp's UIListView in role). Everything but its
// default row lives in ItemView; its default row is one label (`listcell`) showing the item's
// display text. A row factory (native or a markup template) replaces it.

[GuiReflect(true)]
class ListView : ItemView
{
	public this()
	{
		Tag = "listview";
		AccessRoleName = "list"; // what a screen reader takes it for
		using (StyleWriteScope(this)) // its own values, which a sheet returns to
		{
			TextColor = .(0.88f, 0.90f, 0.94f, 1.0f);
		}
	}

	protected override StringView RowTag => "listviewrow";

	protected override Node CreateContent(uint32 type)
	{
		let label = new Label();
		label.Tag = "listcell"; // a row's, not a sheet's generic label
		using (StyleWriteScope(label))
		{
			label.SetTextAlignment(.Start, .Middle);
			label.Padding = .(8.0f, 0.0f, 8.0f, 0.0f);
			label.HitTestVisible = false; // a press on it is the row's
		}
		return label;
	}

	protected override void BindContent(Node content, int32 item, ModelIndex index)
	{
		let text = scope String();
		Model.Data(index).ToString(text);
		((Label)content).Text = text;
	}
}
