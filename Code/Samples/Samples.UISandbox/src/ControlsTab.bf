using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Samples.UISandbox;

/// The control showcase: every button shape, the toggles, a radio group, a slider and a
/// progress bar down the left; expanders on a themed panel in the middle; the image scale modes,
/// colour swatches and SVG drawables down the right.
static class ControlsTab
{
	public static void Build(UISandboxApp app, TabView tabView)
	{
		let body = SandboxViews.HFlex(4.0f);
		tabView.AddTab("Controls", body);

		BuildLeftPanel(app, body);
		BuildCenterPanel(body);
		BuildRightPanel(app, body);
	}

	private static void BuildLeftPanel(UISandboxApp app, FlexLayout body)
	{
		let panel = SandboxViews.VFlex(8.0f);
		panel.Padding = .(12, 8);
		body.AddView(panel,
			SandboxViews.Sized(SizeSpec.Fixed(Unit.Px(300)), SizeSpec.Wrap()));

		let buttonRow = SandboxViews.HFlex(6.0f);
		buttonRow.AddView(new Button("Click Me"));
		{
			let disabled = new Button("Disabled");
			disabled.IsEnabled = false;
			buttonRow.AddView(disabled);
		}
		buttonRow.AddView(new ToggleButton("Toggle"));
		panel.AddView(buttonRow);

		panel.AddView(MakeContentButtonRow());
		panel.AddView(MakeRepeatRow(app));

		panel.AddView(new Spacer(0.0f, 4.0f));

		panel.AddView(new CheckBox("Enable sounds", true));
		panel.AddView(new CheckBox("Fullscreen"));
		panel.AddView(new ToggleSwitch("VSync"));

		panel.AddView(new Separator());

		{
			let radioGroup = new RadioGroup();
			radioGroup.AddRadioButton(new RadioButton("Low"));
			radioGroup.AddRadioButton(new RadioButton("Medium"));
			radioGroup.AddRadioButton(new RadioButton("High"));
			radioGroup.CheckAt(1);
			panel.AddView(radioGroup);
		}

		panel.AddView(new Separator());

		panel.AddView(MakeLabel("Volume"));
		panel.AddView(new Slider(0.0f, 100.0f, 75.0f));
		panel.AddView(MakeLabel("Loading..."));
		{
			let progress = new ProgressBar();
			progress.Value.Value = 0.65f;
			panel.AddView(progress);
		}
	}

	/// A button whose content is a view rather than a string: an icon beside a caption, and a
	/// two line variant.
	private static FlexLayout MakeContentButtonRow()
	{
		let row = SandboxViews.HFlex(6.0f);

		let iconText = SandboxViews.HFlex(6.0f);
		iconText.AlignItems = .Center;
		iconText.AddView(new ColorView(Color.Rgb(80, 180, 80), 12.0f, 12.0f));
		iconText.AddView(MakeLabel("Icon + Text"));
		row.AddView(new ContentButton(iconText));

		let multi = SandboxViews.VFlex(2.0f);
		multi.AlignItems = .Center;

		let first = MakeLabel("Line 1");
		first.FontSize.Value = 12.0f;
		multi.AddView(first);

		let second = MakeLabel("Line 2");
		second.FontSize.Value = 10.0f;
		multi.AddView(second);
		row.AddView(new ContentButton(multi));

		return row;
	}

	/// Hold to repeat, with a live count beside it. The button is handed to the application
	/// because repeating is driven from the frame rather than from an input event.
	private static FlexLayout MakeRepeatRow(UISandboxApp app)
	{
		let row = SandboxViews.HFlex(6.0f);

		let label = MakeLabel("Count: 0");
		let button = new RepeatButton("Hold Me");
		button.OnClick.Add(new [&](sender) =>
			{
				label.SetText(scope $"Count: {app.BumpRepeatCount()}");
			});

		row.AddView(button);
		row.AddView(label);
		app.SetRepeatButton(button);
		return row;
	}

	private static void BuildCenterPanel(FlexLayout body)
	{
		let center = SandboxViews.VFlex(8.0f);
		center.Padding = .(8);
		body.AddView(center, SandboxViews.Grow(1));

		let settings = new Panel();
		settings.Padding = .(8);
		settings.AddClass("panel");

		let layout = SandboxViews.VFlex(4.0f);
		settings.AddView(layout);
		center.AddView(settings);

		{
			let graphics = new Expander("Graphics Settings");
			let content = SandboxViews.VFlex(4.0f);
			content.AddView(new CheckBox("Anti-Aliasing"));
			content.AddView(new CheckBox("Shadows", true));
			content.AddView(new CheckBox("Bloom", true));
			graphics.SetContent(content);
			layout.AddView(graphics);
		}

		{
			let audio = new Expander("Audio Settings");
			let content = SandboxViews.VFlex(4.0f);
			content.AddView(MakeLabel("Master Volume"));
			content.AddView(new Slider(0.0f, 100.0f, 80.0f));
			content.AddView(MakeLabel("Music Volume"));
			content.AddView(new Slider(0.0f, 100.0f, 50.0f));
			audio.SetContent(content);
			layout.AddView(audio);
		}
	}

	private static void BuildRightPanel(UISandboxApp app, FlexLayout body)
	{
		let panel = SandboxViews.VFlex(4.0f);
		panel.Padding = .(4);
		body.AddView(panel,
			SandboxViews.Sized(SizeSpec.Fixed(Unit.Px(200)), SizeSpec.Wrap()));

		AddImage(app, panel, "None", .None, true, null);
		AddImage(app, panel, "FitCenter", .FitCenter, false, null);
		AddImage(app, panel, "FillBounds", .FillBounds, false, null);
		AddImage(app, panel, "CenterCrop", .CenterCrop, false, null);
		AddImage(app, panel, "Tinted", .FitCenter, false, Color.Rgb(255, 100, 100));

		panel.AddView(new Separator());

		panel.AddView(MakeLabel("ColorView"));
		{
			let swatches = new FlowLayout();
			swatches.HSpacing = 4.0f;
			swatches.VSpacing = 4.0f;

			Color[8] colors = .(
				Color.Rgb(220, 60, 60), Color.Rgb(60, 180, 60),
				Color.Rgb(60, 60, 220), Color.Rgb(220, 180, 40),
				Color.Rgb(180, 60, 180), Color.Rgb(60, 180, 180),
				Color.Rgb(220, 120, 60), Color.Rgb(120, 60, 220));

			for (let color in colors)
				swatches.AddView(new ColorView(color, 40.0f, 40.0f));

			panel.AddView(swatches);
		}

		panel.AddView(new Separator());

		panel.AddView(MakeLabel("DrawableView + SVG"));
		panel.AddView(MakeSvgRow());
	}

	private static void AddImage(UISandboxApp app, FlexLayout panel, StringView caption,
		ScaleType scale, bool clip, Color? tint)
	{
		panel.AddView(MakeLabel(caption));

		let view = new ImageView(app.TestImage);
		view.ScaleType.Value = scale;
		view.ClipsContent = clip;
		if (tint.HasValue)
			view.Tint.Value = tint.Value;

		panel.AddView(view,
			SandboxViews.Sized(SizeSpec.Match(), SizeSpec.Fixed(Unit.Px(48))));
	}

	private static FlowLayout MakeSvgRow()
	{
		let row = new FlowLayout();
		row.HSpacing = 6.0f;
		row.VSpacing = 6.0f;

		AddSvg(row, """
			<svg viewBox="0 0 48 48"><circle cx="24" cy="24" r="22" fill="#2A6BC0" stroke="#1A4A90" stroke-width="2"/><text x="24" y="30" text-anchor="middle" font-size="18" font-weight="bold" fill="#FFFFFF">UI</text></svg>
			""", 40.0f, null);

		AddSvg(row, """
			<svg viewBox="0 0 24 24"><path d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z" fill="#FFD700" stroke="#B8960F" stroke-width="0.8"/></svg>
			""", 32.0f, null);

		// The same heart twice, the second tinted, so the tint is read as a drawable property
		// rather than as part of the source.
		let heart = """
			<svg viewBox="0 0 24 24"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" fill="#FF4444"/></svg>
			""";
		AddSvg(row, heart, 32.0f, null);
		AddSvg(row, heart, 32.0f, Color.Rgb(100, 200, 255));

		return row;
	}

	private static void AddSvg(FlowLayout row, StringView svg, float size, Color? tint)
	{
		let drawable = tint.HasValue ? SVGDrawable.FromString(svg, tint.Value)
			: SVGDrawable.FromString(svg);
		if (drawable == null)
			return;

		row.AddView(new DrawableView(drawable, size, size));
	}

	private static Label MakeLabel(StringView text)
	{
		let label = new Label();
		label.SetText(text);
		return label;
	}
}
