namespace Sedulous.Editor;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;

/// Modal dialog shown when more than one `IAssetImporter` claims a file
/// extension. Lists the importers (by `DisplayName`) as vertical buttons;
/// clicking one selects it and closes the dialog with `DialogResult.OK`.
/// Caller reads `Selected` from the `OnClosed` handler to dispatch the
/// actual import flow.
class ImporterChooserDialog : Dialog
{
	private IAssetImporter mSelected;
	public IAssetImporter Selected => mSelected;

	public this(StringView title, StringView fileLabel, List<IAssetImporter> importers)
		: base(title)
	{
		MinWidth.Value = 320;
		MinHeight.Value = 160;
		MaxWidth.Value = 420;

		let stack = new FlexLayout();
		stack.Direction = .Vertical;
		stack.Spacing = 6;

		let message = scope $"Multiple importers can handle {fileLabel}. Pick one:";
		let label = new Label(message);
		stack.AddView(label, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Wrap
		});

		let dialog = this;
		for (let importer in importers)
		{
			let captured = importer;
			let btn = new Button(importer.DisplayName);
			btn.OnClick.Add(new [=dialog, =captured] (b) => {
				dialog.[Friend]mSelected = captured;
				dialog.Close(.OK);
			});
			stack.AddView(btn, new FlexLayout.LayoutParams() {
				Width = .Match, Height = .Fixed(.Px(28))
			});
		}

		SetContent(stack);
		AddButton("Cancel", .Cancel);
	}
}
