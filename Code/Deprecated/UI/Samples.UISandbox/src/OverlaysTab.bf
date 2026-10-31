using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Samples.UISandbox;

/// Everything that draws OUTSIDE its own view: dropdowns, dialogs, context menus, tooltips and
/// the toast overlay.
///
/// They are grouped because they share one problem, which is who owns the popup and when it
/// goes away.
static class OverlaysTab
{
	public static void Build(UISandboxApp app, TabView tabView)
	{
		let scroll = new ScrollView();
		scroll.VScrollBarPolicy.Value = .Auto;
		tabView.AddTab("Overlays", scroll);

		let demo = SandboxViews.VFlex(8.0f);
		demo.Padding = .(12, 8);
		scroll.AddView(demo);

		AddSection(demo, "ComboBox");
		AddComboBoxes(demo);

		demo.AddView(new Spacer(0.0f, 4.0f));
		AddSection(demo, "Dialog");
		AddDialogs(app, demo);

		demo.AddView(new Spacer(0.0f, 4.0f));
		AddSection(demo, "ContextMenu (right-click below)");
		demo.AddView(new ContextMenuDemoArea(),
			SandboxViews.Sized(SizeSpec.Match(), SizeSpec.Fixed(Unit.Px(80))));

		demo.AddView(new Spacer(0.0f, 4.0f));
		AddSection(demo, "Tooltips (hover below)");
		AddTooltips(demo);

		demo.AddView(new Spacer(0.0f, 4.0f));
		AddSection(demo, "Toasts (bottom-right)");
		AddToasts(app, demo);
	}

	private static void AddSection(FlexLayout demo, StringView title)
	{
		let label = new Label();
		label.SetText(title);
		demo.AddView(label);
		demo.AddView(new Separator());
	}

	private static LayoutStyle Narrow => SandboxViews.Sized(SizeSpec.Fixed(Unit.Px(200)),
		SizeSpec.Wrap());

	private static void AddComboBoxes(FlexLayout demo)
	{
		{
			let combo = new ComboBox();
			combo.AddItem("Option 1");
			combo.AddItem("Option 2");
			combo.AddItem("Option 3");
			demo.AddView(combo, Narrow);
		}
		{
			let combo = new ComboBox();
			combo.AddItem("Red");
			combo.AddItem("Green");
			combo.AddItem("Blue");
			combo.SetSelectedIndex(1);
			demo.AddView(combo, Narrow);
		}
	}

	private static void AddDialogs(UISandboxApp app, FlexLayout demo)
	{
		let row = SandboxViews.HFlex(8.0f);

		let alert = new Button("Alert");
		alert.OnClick.Add(new (sender) =>
			{
				Dialog.Alert("Information", "This is an alert dialog.").Show(app.Host.Context);
			});
		row.AddView(alert);

		let confirm = new Button("Confirm");
		confirm.OnClick.Add(new (sender) =>
			{
				Dialog.Confirm("Confirm", "Are you sure you want to proceed?")
					.Show(app.Host.Context);
			});
		row.AddView(confirm);

		demo.AddView(row);
	}

	private static void AddTooltips(FlexLayout demo)
	{
		let row = SandboxViews.HFlex(8.0f);

		AddTooltipButton(row, "Bottom tooltip", "This appears below", .Bottom, false);
		AddTooltipButton(row, "Top tooltip", "This appears above", .Top, false);
		AddTooltipButton(row, "Right tooltip", "This appears on the right", .Right, false);
		AddTooltipButton(row, "Interactive", "This tooltip stays while you hover it", .Bottom,
			true);
		row.AddView(new RichTooltipButton("Rich content"));

		demo.AddView(row);
	}

	private static void AddTooltipButton(FlexLayout row, StringView text, StringView tip,
		TooltipPlacement placement, bool interactive)
	{
		let button = new Button(text);
		button.TooltipText.Set(tip);
		button.TooltipPlacement = placement;
		button.IsTooltipInteractive = interactive;
		row.AddView(button);
	}

	private static void AddToasts(UISandboxApp app, FlexLayout demo)
	{
		let row = SandboxViews.HFlex(8.0f);

		AddToastButton(app, row, "Info", .Info, "For your information.", 4.0f);
		AddToastButton(app, row, "Success", .Success, "Cook finished: 3 asset(s).", 4.0f);
		AddToastButton(app, row, "Warning", .Warning, "No importer for 'foo.xyz'.", 4.0f);
		// STICKY, because an error the user has not read must not time out.
		AddToastButton(app, row, "Error (sticky)", .Error, "Cook: 1 failed (close me).", 0.0f);

		let withAction = new Button("With action");
		withAction.OnClick.Add(new (sender) =>
			{
				ToastRequest request = .("Scene saved.", .Success);
				// Sticky, so the action stays reachable.
				request.DurationSeconds = 0.0f;
				request.ActionLabel = "Undo";
				request.OnAction = new () =>
					{
						ToastRequest ack = .("Undone.", .Info);
						ack.DurationSeconds = 3.0f;
						app.Toasts.Show(ack);
					};
				app.Toasts.Show(request);
			});
		row.AddView(withAction);

		demo.AddView(row);
	}

	private static void AddToastButton(UISandboxApp app, FlexLayout row, StringView text,
		ToastSeverity severity, StringView message, float duration)
	{
		let button = new Button(text);
		button.OnClick.Add(new (sender) =>
			{
				ToastRequest request = .(message, severity);
				request.DurationSeconds = duration;
				app.Toasts.Show(request);
			});
		row.AddView(button);
	}
}
