namespace UISandbox;

using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Demo page: Fade, slide, bounce animations, transformed buttons.
class AnimationPage : DemoPage
{
	public this(DemoContext demo) : base(demo)
	{
		AddSection("Animation");

		let animTarget = new ColorView();
		animTarget.Color = .(80, 160, 255, 255);
		mLayout.AddView(animTarget, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 30 });

		let animRow = new LinearLayout();
		animRow.Orientation = .Horizontal;
		animRow.Spacing = 6;
		mLayout.AddView(animRow, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 28 });

		let fadeOutBtn = new Button();
		fadeOutBtn.SetText("Fade Out");
		fadeOutBtn.OnClick.Add(new (b) => {
			mDemo.UI.UIContext.Animations.Add(ViewAnimator.FadeOut(animTarget, 0.5f, Easing.EaseOutCubic));
		});
		animRow.AddView(fadeOutBtn, new LinearLayout.LayoutParams() { Height = Sedulous.UI.LayoutParams.MatchParent });

		let fadeInBtn = new Button();
		fadeInBtn.SetText("Fade In");
		fadeInBtn.OnClick.Add(new (b) => {
			mDemo.UI.UIContext.Animations.Add(ViewAnimator.FadeIn(animTarget, 0.5f, Easing.EaseOutCubic));
		});
		animRow.AddView(fadeInBtn, new LinearLayout.LayoutParams() { Height = Sedulous.UI.LayoutParams.MatchParent });

		let bounceBtn = new Button();
		bounceBtn.SetText("Bounce");
		bounceBtn.OnClick.Add(new (b) => {
			let sb = new Storyboard(.Sequential);
			sb.Add(ViewAnimator.ScaleTo(animTarget, 1.0f, 1.3f, 0.15f, Easing.EaseOutCubic));
			sb.Add(ViewAnimator.ScaleTo(animTarget, 1.3f, 1.0f, 0.3f, Easing.BounceOut));
			mDemo.UI.UIContext.Animations.Add(sb);
		});
		animRow.AddView(bounceBtn, new LinearLayout.LayoutParams() { Height = Sedulous.UI.LayoutParams.MatchParent });

		let slideBtn = new Button();
		slideBtn.SetText("Slide");
		slideBtn.OnClick.Add(new (b) => {
			let sb = new Storyboard(.Sequential);
			sb.Add(ViewAnimator.TranslateX(animTarget, 0, 50, 0.3f, Easing.EaseOutCubic));
			sb.Add(ViewAnimator.TranslateX(animTarget, 50, 0, 0.3f, Easing.EaseInCubic));
			mDemo.UI.UIContext.Animations.Add(sb);
		});
		animRow.AddView(slideBtn, new LinearLayout.LayoutParams() { Height = Sedulous.UI.LayoutParams.MatchParent });

		AddSeparator();
		AddSection("Transformed Buttons (hit-test aware)");

		let transformRow = new LinearLayout();
		transformRow.Orientation = .Horizontal;
		transformRow.Spacing = 20;
		mLayout.AddView(transformRow, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 40 });

		let rotBtn = new Button();
		rotBtn.SetText("Rotated");
		rotBtn.RenderTransform = Matrix.CreateRotationZ(0.15f);
		rotBtn.OnClick.Add(new (b) => { mDemo.ClickLabel?.SetText("Rotated button clicked!"); });
		transformRow.AddView(rotBtn, new LinearLayout.LayoutParams() { Height = Sedulous.UI.LayoutParams.MatchParent });

		let scaleBtn = new Button();
		scaleBtn.SetText("Scaled 1.2x");
		scaleBtn.RenderTransform = Matrix.CreateScale(1.2f);
		scaleBtn.OnClick.Add(new (b) => { mDemo.ClickLabel?.SetText("Scaled button clicked!"); });
		transformRow.AddView(scaleBtn, new LinearLayout.LayoutParams() { Height = Sedulous.UI.LayoutParams.MatchParent });

		let skewBtn = new Button();
		skewBtn.SetText("Skewed");
		var skew = Matrix.Identity;
		skew.M21 = 0.2f;
		skewBtn.RenderTransform = skew;
		skewBtn.OnClick.Add(new (b) => { mDemo.ClickLabel?.SetText("Skewed button clicked!"); });
		transformRow.AddView(skewBtn, new LinearLayout.LayoutParams() { Height = Sedulous.UI.LayoutParams.MatchParent });
	}
}
