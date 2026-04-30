namespace UISandbox;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Demo page: CheckBox, RadioButton, ToggleSwitch, ProgressBar, Slider,
/// ToggleButton, ComboBox, TabView, NumericField, Expander.
class ControlsPage : DemoPage
{
	private ProgressBar mProgressBar;

	public this(DemoContext demo) : base(demo)
	{
		AddSection("CheckBox & ToggleSwitch");
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 12;
			mLayout.AddView(row, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 24 });
			let cb = new CheckBox(); cb.SetText("Check me"); row.AddView(cb);
			let sw = new ToggleSwitch(); sw.SetText("Switch"); row.AddView(sw);
		}

		AddSection("RadioGroup");
		{
			let group = new RadioGroup();
			group.Orientation = .Horizontal;
			group.Spacing = 12;
			let r1 = new RadioButton(); r1.SetText("Option A");
			let r2 = new RadioButton(); r2.SetText("Option B");
			let r3 = new RadioButton(); r3.SetText("Option C");
			group.AddRadioButton(r1);
			group.AddRadioButton(r2);
			group.AddRadioButton(r3);
			group.CheckAt(0);
			mLayout.AddView(group, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 22 });
		}

		AddSection("ProgressBar");
		{
			mProgressBar = new ProgressBar();
			mProgressBar.Progress = 0;
			mLayout.AddView(mProgressBar, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 12 });
		}

		AddSection("Slider");
		{
			let slider = new Slider();
			slider.Min = 0; slider.Max = 100; slider.Value = 40;
			mLayout.AddView(slider, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 24 });
		}

		AddSection("ToggleButton");
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 6;
			mLayout.AddView(row, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 30 });
			let tb1 = new ToggleButton(); tb1.SetText("Bold");
			let tb2 = new ToggleButton(); tb2.SetText("Italic");
			row.AddView(tb1, new LinearLayout.LayoutParams() { Height = Sedulous.UI.LayoutParams.MatchParent });
			row.AddView(tb2, new LinearLayout.LayoutParams() { Height = Sedulous.UI.LayoutParams.MatchParent });
		}

		AddSection("ComboBox");
		{
			let combo = new ComboBox();
			combo.AddItem("Apple"); combo.AddItem("Banana");
			combo.AddItem("Cherry"); combo.AddItem("Date");
			combo.SelectedIndex = 0;
			mLayout.AddView(combo, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 30 });
		}

		AddSection("NumericField");
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 8;
			mLayout.AddView(row, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 28 });

			let numField = new NumericField();
			numField.Min = 0; numField.Max = 100; numField.Value = 42; numField.Step = 1;
			row.AddView(numField, new LinearLayout.LayoutParams() { Width = 120, Height = Sedulous.UI.LayoutParams.MatchParent });

			let numFieldDec = new NumericField();
			numFieldDec.Min = 0; numFieldDec.Max = 1; numFieldDec.Value = 0.5;
			numFieldDec.Step = 0.05; numFieldDec.DecimalPlaces = 2;
			row.AddView(numFieldDec, new LinearLayout.LayoutParams() { Width = 120, Height = Sedulous.UI.LayoutParams.MatchParent });
		}

		AddSection("EditableLabel");
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 8;
			mLayout.AddView(row, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 24 });

			let editableLabel = new EditableLabel();
			editableLabel.SetText("Double-click or slow-click to rename");
			row.AddView(editableLabel, new LinearLayout.LayoutParams() { Width = 0, Height = Sedulous.UI.LayoutParams.MatchParent, Weight = 1 });

			let editBtn = new Button();
			editBtn.SetText("Edit");
			editBtn.OnClick.Add(new (b) => {
				editableLabel.BeginEdit();
			});
			row.AddView(editBtn, new LinearLayout.LayoutParams() { Height = Sedulous.UI.LayoutParams.MatchParent });

			let statusLabel = new Label();
			statusLabel.FontSize = 11;
			statusLabel.TextColor = .(140, 145, 165, 255);
			mLayout.AddView(statusLabel, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 18 });

			editableLabel.OnRenameCommitted.Add(new (label, newText) => {
				statusLabel.SetText(scope $"Renamed to: {newText}");
			});
			editableLabel.OnRenameCancelled.Add(new (label) => {
				statusLabel.SetText("Rename cancelled");
			});
		}

		AddSection("Expander");
		{
			let expander = new Expander();
			expander.SetHeaderText("Expandable Section");
			let content = new Label();
			content.SetText("Hidden content revealed!");
			expander.SetContent(content, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 24 });
			mLayout.AddView(expander, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent });
		}

		AddSection("TabView");
		{
			let tabRow = new LinearLayout();
			tabRow.Orientation = .Vertical;
			tabRow.Spacing = 4;
			mLayout.AddView(tabRow, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 110 });

			let tabs = new TabView();
			tabs.AddTab("Tab 1", new Label() { }..SetText("Content of Tab 1"));
			tabs.AddTab("Tab 2", new Label() { }..SetText("Content of Tab 2"));
			tabs.AddTab("Tab 3", new Label() { }..SetText("Content of Tab 3"));
			tabRow.AddView(tabs, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 80 });

			let placeBtn = new Button();
			placeBtn.SetText("Placement: Top");
			placeBtn.OnClick.Add(new (b) =>
			{
				switch (tabs.Placement)
				{
				case .Top:    tabs.Placement = .Bottom; placeBtn.SetText("Placement: Bottom");
				case .Bottom: tabs.Placement = .Left;   placeBtn.SetText("Placement: Left");
				case .Left:   tabs.Placement = .Right;  placeBtn.SetText("Placement: Right");
				case .Right:  tabs.Placement = .Top;    placeBtn.SetText("Placement: Top");
				}
			});
			tabRow.AddView(placeBtn, new LinearLayout.LayoutParams() { Height = 26 });
		}
	}

	/// Tick the progress bar animation.
	public void Update(float deltaTime)
	{
		if (mProgressBar != null)
		{
			var p = mProgressBar.Progress + deltaTime * 0.15f;
			if (p > 1) p -= 1;
			mProgressBar.Progress = p;
		}
	}
}
