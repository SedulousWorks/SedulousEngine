using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// The horizontal strip of buttons above an editor's content.
///
/// Items stretch to the bar's height so a button, a toggle and a separator all line up without
/// any of them naming a size.
class Toolbar : FlexLayout
{
	public this()
	{
		Direction = .Horizontal;
		Spacing = 2.0f;
		Padding = .(4.0f);
	}

	/// Adds any view as an item. CONSUMES the caller's reference.
	public void AddItem(View item)
	{
		LayoutStyle style = .();
		style.Height = SizeSpec.Match();
		AddView(item, style);
	}

	/// Adds a text button, returned BORROWED for further wiring.
	public ToolbarButton AddButton(StringView text)
	{
		let button = new ToolbarButton();
		button.SetText(text);
		AddItem(button);
		return button;
	}

	/// Adds a divider, returned BORROWED.
	public ToolbarSeparator AddSeparator()
	{
		let separator = new ToolbarSeparator();
		AddItem(separator);
		return separator;
	}

	/// Adds a toggle, returned BORROWED.
	public ToolbarToggle AddToggle(StringView text)
	{
		let toggle = new ToolbarToggle();
		toggle.SetText(text);
		AddItem(toggle);
		return toggle;
	}

	/// Adds a dropdown button, returned BORROWED; wire OnClick to show the menu.
	public ToolbarMenuButton AddMenuButton(StringView text)
	{
		let button = new ToolbarMenuButton();
		button.SetText(text);
		AddItem(button);
		return button;
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = Rectangle(0, 0, Width, Height);

		if (let background = ResolveStyleDrawable(.Background))
			background.Draw(ctx, bounds);
		else
			ctx.VG.FillRect(bounds, Color.Rgb(35, 37, 46));

		// The bottom border, which is what separates the bar from the content below it.
		let borderColor = ResolveStyleColor(.BorderColor, Color.Rgb(65, 70, 85));
		ctx.VG.FillRect(Rectangle(0, Height - 1.0f, Width, 1.0f), borderColor);

		DrawChildren(ctx);
	}
}
