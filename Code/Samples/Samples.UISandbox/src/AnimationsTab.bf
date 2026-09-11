using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Samples.UISandbox;

/// The animation system driving a view, and static transforms on top of it.
///
/// The transformed buttons are here for HIT TESTING rather than for looks: a rotated or scaled
/// control has to answer clicks where it is drawn, not where it was laid out, and the only way
/// to see that is to click one.
static class AnimationsTab
{
	public static void Build(UISandboxApp app, TabView tabView)
	{
		let demo = SandboxViews.VFlex(8.0f);
		demo.Padding = .(12, 8);
		tabView.AddTab("Animations", demo);

		demo.AddView(MakeLabel("Animation Target"));

		let target = new ColorView(Color.Rgb(80, 160, 255), 0.0f, 30.0f);
		demo.AddView(target,
			SandboxViews.Sized(SizeSpec.Match(), SizeSpec.Fixed(Unit.Px(30))));

		demo.AddView(MakeAnimationRow(app, target));

		demo.AddView(new Spacer(0.0f, 8.0f));
		demo.AddView(MakeLabel("Static Transforms (click to verify hit-testing)"));
		demo.AddView(new Separator());

		let clicked = MakeLabel("Click a transformed button...");
		demo.AddView(MakeTransformRow(clicked));
		demo.AddView(clicked);
	}

	private static FlexLayout MakeAnimationRow(UISandboxApp app, View target)
	{
		let row = SandboxViews.HFlex(6.0f);
		let animations = app.Host.Context.Animations;

		AddButton(row, "Fade Out", new [&](sender) =>
			{
				animations.Add(ViewAnimator.FadeOut(target, 0.5f, Easing.EaseOutCubic));
			});
		AddButton(row, "Fade In", new [&](sender) =>
			{
				animations.Add(ViewAnimator.FadeIn(target, 0.5f, Easing.EaseOutCubic));
			});

		// A sequence rather than one curve: the overshoot and the settle are separate motions,
		// and only the second bounces.
		AddButton(row, "Bounce", new [&](sender) =>
			{
				let storyboard = new Storyboard(.Sequential);
				storyboard.Add(ViewAnimator.ScaleTo(target, 1.0f, 1.3f, 0.15f, Easing.EaseOutCubic));
				storyboard.Add(ViewAnimator.ScaleTo(target, 1.3f, 1.0f, 0.3f, Easing.BounceOut));
				animations.Add(storyboard);
			});

		AddButton(row, "Slide", new [&](sender) =>
			{
				let storyboard = new Storyboard(.Sequential);
				storyboard.Add(ViewAnimator.TranslateX(target, 0, 50, 0.3f, Easing.EaseOutCubic));
				storyboard.Add(ViewAnimator.TranslateX(target, 50, 0, 0.3f, Easing.EaseInCubic));
				animations.Add(storyboard);
			});

		return row;
	}

	private static FlexLayout MakeTransformRow(Label clicked)
	{
		let row = SandboxViews.HFlex(16.0f);

		ViewTransform rotated = .();
		rotated.Rotation = 0.15f;
		AddTransformedButton(row, clicked, "Rotated", rotated, "Rotated button clicked!");

		ViewTransform scaled = .();
		scaled.Scale = .(1.2f, 1.2f);
		AddTransformedButton(row, clicked, "Scaled 1.2x", scaled, "Scaled button clicked!");

		ViewTransform translated = .();
		translated.Translation = .(10, 5);
		AddTransformedButton(row, clicked, "Translated", translated, "Translated button clicked!");

		return row;
	}

	private static void AddTransformedButton(FlexLayout row, Label clicked, StringView text,
		ViewTransform transform, StringView message)
	{
		let button = new Button(text);
		button.Transform = transform;
		button.OnClick.Add(new [&](sender) => clicked.SetText(message));
		row.AddView(button);
	}

	private static void AddButton(FlexLayout row, StringView text,
		delegate void(ButtonBase) handler)
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
