namespace Sedulous.Editor;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Engine.App;
using Sedulous.RuntimeGraphics;

/// Builds the form layout for a ProjectSettingsPage:
///   Toolbar (Save)
///   Preview Resolution: TargetWidth, TargetHeight
///   Display: FitMode
///
/// Per page-layout convention each editor page lays out independently.
static class ProjectSettingsPageBuilder
{
	private const float kLabelWidth = 140;
	private const float kFieldWidth = 120;
	private const float kRowHeight = 26;
	private const float kSectionGap = 12;

	public static View Build(ProjectSettingsPage page)
	{
		let container = new FlexLayout();
		container.Direction = .Vertical;

		// === Toolbar ===
		// Save is enabled only while dirty. Button text also swaps between
		// "Save" / "Saved" since ToolbarButton doesn't recolor on disable
		// today - the user needs a glanceable signal that the click landed.
		// The durable "Project Settings saved" message goes to the editor
		// shell's status bar via EditorContext.SetStatus inside page.Save.
		let toolbar = new Toolbar();
		let saveBtn = toolbar.AddButton(page.IsDirty ? "Save" : "Saved");
		saveBtn.IsEnabled = page.IsDirty;
		saveBtn.OnClick.Add(new [=page] (btn) => { page.Save(); });
		page.OnDirtyChanged.Add(new [=saveBtn] (p) => {
			saveBtn.IsEnabled = p.IsDirty;
			saveBtn.SetText(p.IsDirty ? "Save" : "Saved");
		});

		container.AddView(toolbar, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Wrap
		});

		// === Preview Resolution section ===
		AppendSectionHeader(container, "Preview Resolution");

		let widthField = new NumericField();
		widthField.DecimalPlaces = 0;
		widthField.Min = 0;
		widthField.Max = 16384;
		widthField.Step = 1;
		widthField.Value = page.Working.TargetWidth;
		widthField.OnValueChanged.Add(new [=page] (f, v) => {
			page.SetTargetWidth((int32)v);
		});
		AppendFieldRow(container, "Target Width", widthField);

		let heightField = new NumericField();
		heightField.DecimalPlaces = 0;
		heightField.Min = 0;
		heightField.Max = 16384;
		heightField.Step = 1;
		heightField.Value = page.Working.TargetHeight;
		heightField.OnValueChanged.Add(new [=page] (f, v) => {
			page.SetTargetHeight((int32)v);
		});
		AppendFieldRow(container, "Target Height", heightField);

		// Hint text - zero on either axis disables target rendering and the
		// preview falls back to the page tab's layout size. Lets users opt
		// into match-viewport mode by clearing the field instead of having
		// to pick a separate enum.
		AppendHint(container,
			"0 on either axis disables target rendering (preview falls back to match-viewport).");

		// === Display section ===
		AppendSectionHeader(container, "Display");

		let fitCombo = new ComboBox();
		fitCombo.AddItem("Stretch");
		fitCombo.AddItem("Letterbox");
		fitCombo.AddItem("Crop");
		fitCombo.SelectedIndex = (int)page.Working.FitMode;
		fitCombo.OnSelectionChanged.Add(new [=page] (cb, idx) => {
			page.SetFitMode((FitMode)idx);
		});
		AppendFieldRow(container, "Fit Mode", fitCombo);

		// Spacer at the bottom so the form hugs the top of the page.
		let spacer = new Panel();
		container.AddView(spacer, new FlexLayout.LayoutParams() {
			Width = .Match, Grow = 1
		});

		return container;
	}

	private static void AppendSectionHeader(FlexLayout container, StringView text)
	{
		let header = new Label(text);
		container.AddView(header, new FlexLayout.LayoutParams() {
			Width = .Match,
			Height = .Fixed(.Px(kRowHeight)),
			Margin = .(8, kSectionGap, 8, 0)
		});

		let sep = new Separator();
		container.AddView(sep, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(1))
		});
	}

	private static void AppendFieldRow(FlexLayout container, StringView labelText, View field)
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;

		let label = new Label(labelText);
		row.AddView(label, new FlexLayout.LayoutParams() {
			Width = .Fixed(.Px(kLabelWidth)),
			Height = .Match
		});
		row.AddView(field, new FlexLayout.LayoutParams() {
			Width = .Fixed(.Px(kFieldWidth)),
			Height = .Match
		});

		container.AddView(row, new FlexLayout.LayoutParams() {
			Width = .Match,
			Height = .Fixed(.Px(kRowHeight)),
			Margin = .(8, 4, 0, 0)
		});
	}

	private static void AppendHint(FlexLayout container, StringView text)
	{
		let hint = new Label(text);
		container.AddView(hint, new FlexLayout.LayoutParams() {
			Width = .Match,
			Height = .Fixed(.Px(kRowHeight)),
			Margin = .(8, 2, 0, 0)
		});
	}
}
