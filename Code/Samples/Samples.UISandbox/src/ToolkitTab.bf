using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Samples.UISandbox;

/// The editor chrome: a menu bar over a toolbar over a breadcrumb trail, a working area, and a
/// status bar along the bottom.
///
/// Assembled as a whole window rather than as a list of controls, because what these have to
/// prove is that they STACK: each takes its natural height and the middle takes the rest.
static class ToolkitTab
{
	public static void Build(UISandboxApp app, TabView tabView)
	{
		let demo = SandboxViews.VFlex(0.0f);
		tabView.AddTab("Toolkit", demo);

		demo.AddView(MakeMenuBar(), Full);
		demo.AddView(MakeToolbar(), Full);

		let breadcrumb = new BreadcrumbBar();
		breadcrumb.SetPath("Project/Assets/Textures/Environment");
		demo.AddView(breadcrumb, Full);

		demo.AddView(MakeCenterRow(app), Stretch);

		let status = new StatusBar();
		status.SetText("Ready");
		status.AddSection("Ln 42, Col 8");
		status.AddSection("UTF-8");
		demo.AddView(status, Full);
	}

	private static LayoutStyle Full => SandboxViews.Sized(SizeSpec.Match(), SizeSpec.Wrap());

	private static LayoutStyle Stretch
	{
		get
		{
			var style = SandboxViews.Grow(1.0f);
			style.Width = SizeSpec.Match();
			return style;
		}
	}

	private static MenuBar MakeMenuBar()
	{
		let bar = new MenuBar();

		let file = bar.AddMenu("File");
		file.AddItem("New", new () => {});
		file.AddItem("Open", new () => {});
		file.AddSeparator();
		file.AddItem("Exit", new () => {});

		let edit = bar.AddMenu("Edit");
		edit.AddItem("Undo", new () => {});
		edit.AddItem("Redo", new () => {});
		edit.AddSeparator();
		edit.AddItem("Cut", new () => {});
		edit.AddItem("Copy", new () => {});
		edit.AddItem("Paste", new () => {});

		let view = bar.AddMenu("View");
		view.AddItem("Zoom In", new () => {});
		view.AddItem("Zoom Out", new () => {});

		return bar;
	}

	private static Toolbar MakeToolbar()
	{
		let toolbar = new Toolbar();
		toolbar.AddButton("New");
		toolbar.AddButton("Open");
		toolbar.AddButton("Save");
		toolbar.AddSeparator();
		toolbar.AddToggle("Bold");
		toolbar.AddToggle("Italic");
		return toolbar;
	}

	private static FlexLayout MakeCenterRow(UISandboxApp app)
	{
		let row = SandboxViews.HFlex(4.0f);

		let split = new SplitView(.Horizontal);
		split.SetPanes(MakeLabel("Left Pane"), MakeLabel("Right Pane"));
		split.SplitRatio = 0.4f;
		row.AddView(split, SandboxViews.Grow(1));

		let dragColumn = SandboxViews.VFlex(4.0f);
		dragColumn.AddView(MakeLabel("Drag to reorder:"));

		let tree = new DraggableTreeView();
		tree.SetAdapter(app.ReorderAdapter);
		tree.ItemHeight = 22.0f;
		dragColumn.AddView(tree, SandboxViews.Grow(1));
		row.AddView(dragColumn,
			SandboxViews.Sized(SizeSpec.Fixed(Unit.Px(200)), SizeSpec.Wrap()));

		let picker = new ColorPicker();
		let start = Color.Rgb(80, 160, 240);
		picker.SetColor(start);
		// The original is what the picker's before-and-after swatch compares against.
		picker.SetOriginalColor(start);
		row.AddView(picker);

		return row;
	}

	private static Label MakeLabel(StringView text)
	{
		let label = new Label();
		label.SetText(text);
		return label;
	}
}
