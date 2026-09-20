using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Editor.App;

/// The rows the single-file and batch import dialogs share: a label/value info line, the
/// "Into: <group> [Change...]" destination line, and one check box per option toggle.
static class ImportDialogRows
{
	public static void AddInfoRow(FlexLayout column, StringView label, StringView value)
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 6.0f;
		let name = new Label(label);
		name.FontSize.Value = 11.0f;
		row.AddView(name, FixedWidth(52.0f));
		let text = new Label(value);
		text.FontSize.Value = 11.0f;
		text.Ellipsis.Value = true;
		row.AddView(text, Grow());
		column.AddView(row, RowStyle(18.0f));
	}

	/// The destination line; answers the borrowed path label so SetDestination can update
	/// it. Takes ownership of the change delegate.
	public static Label AddDestinationRow(FlexLayout column, StringView destination, delegate void() onChange)
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 6.0f;
		let name = new Label("Into:");
		name.FontSize.Value = 11.0f;
		row.AddView(name, FixedWidth(52.0f));
		let text = new Label(destination);
		text.FontSize.Value = 11.0f;
		text.Ellipsis.Value = true;
		row.AddView(text, Grow());
		let change = new Button("Change...");
		change.FontSize.Value = 11.0f;
		change.OnClick.Add(new [=onChange](b) => { onChange(); } ~ delete onChange);
		row.AddView(change, FixedWidth(72.0f));
		column.AddView(row, RowStyle(22.0f));
		return text;
	}

	/// One check box per toggle, writing straight through the toggle's pointer.
	public static void AddToggles(FlexLayout column, ImportOptions options)
	{
		let toggles = scope List<ImportToggle>();
		options.GetToggles(toggles);
		for (let toggle in toggles)
		{
			if (toggle.Value == null)
				continue;
			let check = new CheckBox(toggle.Label, *toggle.Value);
			check.FontSize.Value = 12.0f;
			if (!toggle.Description.IsEmpty)
				check.TooltipText.Set(toggle.Description);
			let value = toggle.Value;
			check.OnCheckedChanged.Add(new [=value](c, on) => { *value = on; });
			column.AddView(check, RowStyle(22.0f));
		}
	}

	public static LayoutStyle RowStyle(float height)
	{
		var style = LayoutStyle();
		style.Width = SizeSpec.Match();
		style.Height = SizeSpec.Fixed(Unit.Dp(height));
		return style;
	}

	private static LayoutStyle FixedWidth(float width)
	{
		var style = LayoutStyle();
		style.Width = SizeSpec.Fixed(Unit.Dp(width));
		style.Height = SizeSpec.Match();
		return style;
	}

	private static LayoutStyle Grow()
	{
		var style = LayoutStyle();
		style.FlexGrow = 1.0f;
		style.Height = SizeSpec.Match();
		return style;
	}
}
