using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Samples.UISandbox;

/// What the VG's layers change, for a look: two overlapping cards at half opacity as one group
/// beside the same cards faded each alone, a group fade, `filter: blur(4)` on a group with its
/// label, and a translucent panel with `backdrop-filter: blur(8)` over stripes.
static class LayersTab
{
	static Color Red => .(0.86f, 0.24f, 0.24f, 1.0f);
	static Color Blue => .(0.24f, 0.45f, 0.9f, 1.0f);

	public static void Build(UISandboxApp app, TabView tabView)
	{
		let demo = SandboxViews.VFlex(10.0f);
		demo.Padding = .(12, 8);
		tabView.AddTab("Layers", demo);

		// Group opacity: the group fades as one; the same cards each at half show through each
		// other.
		demo.AddView(MakeLabel("Opacity 50%: as one group (left), each card alone (right)"));
		let row = SandboxViews.HFlex(80.0f);
		let group = MakeCards();
		group.Opacity = 0.5f;
		row.AddView(group, SandboxViews.Sized(.Fixed(.Px(140)), .Fixed(.Px(90))));
		let each = MakeCards();
		for (int i < each.ChildCount)
			each.GetChildAt(i).Opacity = 0.5f;
		row.AddView(each, SandboxViews.Sized(.Fixed(.Px(140)), .Fixed(.Px(90))));
		demo.AddView(row);

		let animations = app.Host.Context.Animations;
		let fades = SandboxViews.HFlex(6.0f);
		AddButton(fades, "Fade group out", new (sender) =>
			{
				animations.Add(ViewAnimator.FadeOut(group, 0.6f, Easing.EaseOutCubic));
			});
		AddButton(fades, "Fade group in", new (sender) =>
			{
				animations.Add(ViewAnimator.FadeIn(group, 0.6f, Easing.EaseOutCubic));
			});
		demo.AddView(fades);

		// filter: blur(4) on the group and its label.
		demo.AddView(MakeLabel("filter: blur(4)"));
		let blurred = MakeCards();
		let caption = MakeLabel("Blurred with its cards");
		caption.Transform.Translation = .(4.0f, 30.0f);
		blurred.AddView(caption);
		blurred.SetStyle(.Filter, 4.0f);
		demo.AddView(blurred, SandboxViews.Sized(.Fixed(.Px(140)), .Fixed(.Px(90))));

		// backdrop-filter: blur(8) on a translucent glass panel over stripes.
		demo.AddView(MakeLabel("backdrop-filter: blur(8) under a translucent panel"));
		let stage = new FrameLayout();
		let stripes = SandboxViews.HFlex(0.0f);
		for (int i < 12)
		{
			let color = ((i % 3) == 0) ? Red : (((i % 3) == 1) ? Blue : Color(0.95f, 0.85f, 0.3f, 1.0f));
			stripes.AddView(new ColorView(color, 20.0f, 100.0f), SandboxViews.Sized(.Fixed(.Px(20)), .Fixed(.Px(100))));
		}
		stage.AddView(stripes);
		let glass = new ColorView(.(1.0f, 1.0f, 1.0f, 0.18f), 150.0f, 60.0f);
		glass.Transform.Translation = .(45.0f, 20.0f);
		glass.SetStyle(.BackdropFilter, 8.0f);
		stage.AddView(glass, SandboxViews.Sized(.Fixed(.Px(150)), .Fixed(.Px(60))));
		demo.AddView(stage, SandboxViews.Sized(.Fixed(.Px(240)), .Fixed(.Px(100))));
	}

	/// Two overlapping cards in a frame, the second offset as it draws.
	private static FrameLayout MakeCards()
	{
		let frame = new FrameLayout();
		frame.AddView(new ColorView(Red, 90.0f, 60.0f));
		let second = new ColorView(Blue, 90.0f, 60.0f);
		second.Transform.Translation = .(45.0f, 25.0f);
		frame.AddView(second);
		return frame;
	}

	private static void AddButton(FlexLayout row, StringView text, delegate void(ButtonBase) handler)
	{
		let button = new Button(text);
		button.OnClick.Add(handler);
		row.AddView(button);
	}

	private static Label MakeLabel(StringView text)
	{
		let label = new Label();
		label.SetText(text);
		return label;
	}
}
