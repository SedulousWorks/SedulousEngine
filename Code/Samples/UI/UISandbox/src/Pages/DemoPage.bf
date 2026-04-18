namespace UISandbox;

using Sedulous.UI;
using Sedulous.Core.Mathematics;
using System;

/// Base class for demo pages. Each page is a vertical LinearLayout
/// inside a ScrollView, with helpers for common patterns.
class DemoPage : ScrollView
{
	protected LinearLayout mLayout;
	protected DemoContext mDemo;

	public this(DemoContext demo)
	{
		mDemo = demo;
		VScrollPolicy = .Auto;
		HScrollPolicy = .Never;

		mLayout = new LinearLayout();
		mLayout.Orientation = .Vertical;
		mLayout.Padding = .(12);
		mLayout.Spacing = 6;
		AddView(mLayout, new Sedulous.UI.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent });
	}

	protected void AddSection(StringView title)
	{
		let label = new Label();
		label.SetText(title);
		label.StyleId = new String("SectionLabel");
		mLayout.AddView(label, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 22 });
	}

	protected void AddSeparator()
	{
		let sep = new Separator();
		mLayout.AddView(sep, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 1 });
	}

	protected void AddLabel(StringView text)
	{
		let label = new Label();
		label.SetText(text);
		mLayout.AddView(label, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 22 });
	}
}
