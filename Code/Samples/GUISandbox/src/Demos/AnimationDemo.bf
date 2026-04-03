namespace GUISandbox;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.GUI;
using static Sedulous.GUI.UIElementAnimations;

/// Phase 16: Animation Demo - demonstrates property animations, easing, and storyboards.
class AnimationDemo
{
	// Demo panels that we animate
	private Panel mFadePanel;
	private Panel mSlidePanel;
	private Panel mColorPanel;
	private Panel mEasingPanel;
	private Panel mStoryboardPanel;
	private Panel mLoopingPanel;

	// Labels showing status
	private TextBlock mStatusLabel;

	// Track storyboard for restart
	private GUIContext mContext;

	public Panel CreateDemo()
	{
		// Main container with vertical layout
		let mainPanel = new StackPanel();
		mainPanel.Orientation = .Vertical;
		mainPanel.Width = 1200;
		mainPanel.Height = 650;
		mainPanel.Margin = .(20, 70, 20, 20);

		// Title
		let title = new TextBlock("Animation System Demo (Phase 16)");
		title.FontSize = 20;
		title.Margin = .(10, 10, 10, 5);
		mainPanel.AddChild(title);

		// Status label
		mStatusLabel = new TextBlock("Click buttons to trigger animations");
		mStatusLabel.FontSize = 14;
		mStatusLabel.Margin = .(10, 0, 10, 10);
		mainPanel.AddChild(mStatusLabel);

		// Create demo rows
		let demoContainer = new StackPanel();
		demoContainer.Orientation = .Horizontal;
		demoContainer.Margin = .(10, 5, 10, 5);
		mainPanel.AddChild(demoContainer);

		// Left column
		let leftColumn = new StackPanel();
		leftColumn.Orientation = .Vertical;
		leftColumn.Width = 380;
		demoContainer.AddChild(leftColumn);

		// Middle column
		let middleColumn = new StackPanel();
		middleColumn.Orientation = .Vertical;
		middleColumn.Width = 380;
		demoContainer.AddChild(middleColumn);

		// Right column
		let rightColumn = new StackPanel();
		rightColumn.Orientation = .Vertical;
		rightColumn.Width = 380;
		demoContainer.AddChild(rightColumn);

		// Add demo sections
		leftColumn.AddChild(CreateFadeDemo());
		leftColumn.AddChild(CreateSlideDemo());

		middleColumn.AddChild(CreateColorDemo());
		middleColumn.AddChild(CreateEasingDemo());

		rightColumn.AddChild(CreateStoryboardDemo());
		rightColumn.AddChild(CreateLoopingDemo());

		return mainPanel;
	}

	private Panel CreateFadeDemo()
	{
		let section = CreateSection("Fade Animations");

		// Target panel
		mFadePanel = new Panel();
		mFadePanel.Width = 100;
		mFadePanel.Height = 60;
		mFadePanel.Background = Color(100, 150, 220, 255);
		mFadePanel.Margin = .(10, 5, 10, 5);
		section.AddChild(mFadePanel);

		// Buttons
		let buttonRow = new StackPanel();
		buttonRow.Orientation = .Horizontal;
		buttonRow.Margin = .(10, 5, 10, 5);
		section.AddChild(buttonRow);

		let fadeInBtn = new Button("Fade In");
		fadeInBtn.Width = 80;
		fadeInBtn.Margin = .(0, 0, 5, 0);
		fadeInBtn.Click.Subscribe(new (btn) => {
			mFadePanel.Opacity = 0;
			mFadePanel.StartFadeIn(0.5f);
			UpdateStatus("Playing fade-in animation");
		});
		buttonRow.AddChild(fadeInBtn);

		let fadeOutBtn = new Button("Fade Out");
		fadeOutBtn.Width = 80;
		fadeOutBtn.Click.Subscribe(new (btn) => {
			mFadePanel.Opacity = 1;
			mFadePanel.StartFadeOut(0.5f);
			UpdateStatus("Playing fade-out animation");
		});
		buttonRow.AddChild(fadeOutBtn);

		return section;
	}

	private Panel CreateSlideDemo()
	{
		let section = CreateSection("Slide Animations");

		// Container for the sliding panel (tall enough for vertical slides)
		let container = new Border();
		container.Width = 340;
		container.Height = 120;
		container.Margin = .(10, 5, 10, 5);
		section.AddChild(container);

		// Target panel
		mSlidePanel = new Panel();
		mSlidePanel.Width = 60;
		mSlidePanel.Height = 60;
		mSlidePanel.Background = Color(220, 150, 100, 255);
		mSlidePanel.Margin = .(10, 10, 10, 10);
		container.Child = mSlidePanel;

		// Buttons
		let buttonRow = new StackPanel();
		buttonRow.Orientation = .Horizontal;
		buttonRow.Margin = .(10, 5, 10, 5);
		section.AddChild(buttonRow);

		let slideLeftBtn = new Button("Left");
		slideLeftBtn.Width = 55;
		slideLeftBtn.Margin = .(0, 0, 5, 0);
		slideLeftBtn.Click.Subscribe(new (btn) => {
			mSlidePanel.StartSlideInFromLeft(50, 0.4f);
			UpdateStatus("Sliding in from left");
		});
		buttonRow.AddChild(slideLeftBtn);

		let slideRightBtn = new Button("Right");
		slideRightBtn.Width = 55;
		slideRightBtn.Margin = .(0, 0, 5, 0);
		slideRightBtn.Click.Subscribe(new (btn) => {
			mSlidePanel.StartSlideInFromRight(50, 0.4f);
			UpdateStatus("Sliding in from right");
		});
		buttonRow.AddChild(slideRightBtn);

		let slideTopBtn = new Button("Top");
		slideTopBtn.Width = 55;
		slideTopBtn.Margin = .(0, 0, 5, 0);
		slideTopBtn.Click.Subscribe(new (btn) => {
			mSlidePanel.StartSlideInFromTop(30, 0.4f);
			UpdateStatus("Sliding in from top");
		});
		buttonRow.AddChild(slideTopBtn);

		let slideBottomBtn = new Button("Bottom");
		slideBottomBtn.Width = 55;
		slideBottomBtn.Click.Subscribe(new (btn) => {
			mSlidePanel.StartSlideInFromBottom(30, 0.4f);
			UpdateStatus("Sliding in from bottom");
		});
		buttonRow.AddChild(slideBottomBtn);

		return section;
	}

	private Panel CreateColorDemo()
	{
		let section = CreateSection("Color Animations");

		// Target panel (needs to be a Control for color animations)
		mColorPanel = new Panel();
		mColorPanel.Width = 120;
		mColorPanel.Height = 60;
		mColorPanel.Background = Color(100, 100, 100, 255);
		mColorPanel.Margin = .(10, 5, 10, 5);
		section.AddChild(mColorPanel);

		// Buttons
		let buttonRow = new StackPanel();
		buttonRow.Orientation = .Horizontal;
		buttonRow.Margin = .(10, 5, 10, 5);
		section.AddChild(buttonRow);

		let toRedBtn = new Button("Red");
		toRedBtn.Width = 60;
		toRedBtn.Margin = .(0, 0, 5, 0);
		toRedBtn.Click.Subscribe(new (btn) => {
			AnimateColor(Color(220, 80, 80, 255));
			UpdateStatus("Animating to red");
		});
		buttonRow.AddChild(toRedBtn);

		let toGreenBtn = new Button("Green");
		toGreenBtn.Width = 60;
		toGreenBtn.Margin = .(0, 0, 5, 0);
		toGreenBtn.Click.Subscribe(new (btn) => {
			AnimateColor(Color(80, 200, 100, 255));
			UpdateStatus("Animating to green");
		});
		buttonRow.AddChild(toGreenBtn);

		let toBlueBtn = new Button("Blue");
		toBlueBtn.Width = 60;
		toBlueBtn.Click.Subscribe(new (btn) => {
			AnimateColor(Color(80, 120, 220, 255));
			UpdateStatus("Animating to blue");
		});
		buttonRow.AddChild(toBlueBtn);

		return section;
	}

	private void AnimateColor(Color targetColor)
	{
		let context = mColorPanel.Context;
		if (context == null)
			return;

		if (context.GetService<AnimationManager>() case .Ok(let manager))
		{
			let anim = ColorAnimation.Background(targetColor);
			anim.Duration = 0.5f;
			anim.EasingFunction = Easing.EaseOutCubic;
			anim.SetTarget(mColorPanel);
			manager.Start(anim);
		}
	}

	private Panel CreateEasingDemo()
	{
		let section = CreateSection("Easing Functions");

		// Container
		let container = new Border();
		container.Width = 340;
		container.Height = 60;
		container.Margin = .(10, 5, 10, 5);
		section.AddChild(container);

		// Target panel
		mEasingPanel = new Panel();
		mEasingPanel.Width = 40;
		mEasingPanel.Height = 40;
		mEasingPanel.Background = Color(200, 180, 100, 255);
		mEasingPanel.Margin = .(10, 10, 10, 10);
		container.Child = mEasingPanel;

		// Buttons
		let buttonRow = new StackPanel();
		buttonRow.Orientation = .Horizontal;
		buttonRow.Margin = .(10, 5, 10, 5);
		section.AddChild(buttonRow);

		let bounceBtn = new Button("Bounce");
		bounceBtn.Width = 70;
		bounceBtn.Margin = .(0, 0, 5, 0);
		bounceBtn.Click.Subscribe(new (btn) => {
			AnimateWithEasing(Easing.BounceOut, "Bounce Out");
		});
		buttonRow.AddChild(bounceBtn);

		let elasticBtn = new Button("Elastic");
		elasticBtn.Width = 70;
		elasticBtn.Margin = .(0, 0, 5, 0);
		elasticBtn.Click.Subscribe(new (btn) => {
			AnimateWithEasing(Easing.ElasticOut, "Elastic Out");
		});
		buttonRow.AddChild(elasticBtn);

		let backBtn = new Button("Back");
		backBtn.Width = 70;
		backBtn.Margin = .(0, 0, 5, 0);
		backBtn.Click.Subscribe(new (btn) => {
			AnimateWithEasing(Easing.BackOut, "Back Out");
		});
		buttonRow.AddChild(backBtn);

		let expoBtn = new Button("Expo");
		expoBtn.Width = 70;
		expoBtn.Click.Subscribe(new (btn) => {
			AnimateWithEasing(Easing.ExpoOut, "Expo Out");
		});
		buttonRow.AddChild(expoBtn);

		return section;
	}

	private void AnimateWithEasing(EasingFunction easing, StringView name)
	{
		let context = mEasingPanel.Context;
		if (context == null)
			return;

		if (context.GetService<AnimationManager>() case .Ok(let manager))
		{
			// Reset position
			let currentMargin = mEasingPanel.Margin;
			let startMargin = Thickness(10, currentMargin.Top, currentMargin.Right, currentMargin.Bottom);
			let endMargin = Thickness(280, currentMargin.Top, currentMargin.Right, currentMargin.Bottom);

			mEasingPanel.Margin = startMargin;

			let anim = ThicknessAnimation.Margin(startMargin, endMargin);
			anim.Duration = 1.0f;
			anim.EasingFunction = easing;
			anim.SetTarget(mEasingPanel);
			manager.Start(anim);

			UpdateStatus(scope $"Playing {name} easing");
		}
	}

	private Panel CreateStoryboardDemo()
	{
		let section = CreateSection("Storyboard Sequencing");

		// Target panel
		mStoryboardPanel = new Panel();
		mStoryboardPanel.Width = 80;
		mStoryboardPanel.Height = 50;
		mStoryboardPanel.Background = Color(150, 100, 200, 255);
		mStoryboardPanel.Margin = .(10, 10, 10, 10);
		mStoryboardPanel.Opacity = 1;
		section.AddChild(mStoryboardPanel);

		// Buttons
		let buttonRow = new StackPanel();
		buttonRow.Orientation = .Horizontal;
		buttonRow.Margin = .(10, 5, 10, 5);
		section.AddChild(buttonRow);

		let playBtn = new Button("Play Sequence");
		playBtn.Width = 120;
		playBtn.Margin = .(0, 0, 5, 0);
		playBtn.Click.Subscribe(new (btn) => {
			PlayStoryboard();
		});
		buttonRow.AddChild(playBtn);

		let resetBtn = new Button("Reset");
		resetBtn.Width = 70;
		resetBtn.Click.Subscribe(new (btn) => {
			mStoryboardPanel.Opacity = 1;
			mStoryboardPanel.Margin = .(10, 10, 10, 10);
			mStoryboardPanel.Background = Color(150, 100, 200, 255);
			UpdateStatus("Reset storyboard panel");
		});
		buttonRow.AddChild(resetBtn);

		// Description
		let desc = new TextBlock("Fade in -> Slide -> Color change");
		desc.FontSize = 12;
		desc.Margin = .(10, 5, 10, 5);
		section.AddChild(desc);

		return section;
	}

	private void PlayStoryboard()
	{
		let context = mStoryboardPanel.Context;
		if (context == null)
			return;

		if (context.GetService<AnimationManager>() case .Ok(let manager))
		{
			// Reset state first
			mStoryboardPanel.Opacity = 0;
			mStoryboardPanel.Margin = .(10, 10, 10, 10);
			mStoryboardPanel.Background = Color(150, 100, 200, 255);

			// Create storyboard
			let sb = new Storyboard();
			sb.SetTarget(mStoryboardPanel);

			// 1. Fade in (0.0s - 0.3s)
			let fadeIn = FloatAnimation.Opacity(0, 1);
			fadeIn.Duration = 0.3f;
			sb.Add(fadeIn, 0);

			// 2. Slide right (0.3s - 0.6s)
			let slide = ThicknessAnimation.Margin(.(10, 10, 10, 10), .(200, 10, 10, 10));
			slide.Duration = 0.3f;
			slide.EasingFunction = Easing.EaseOutCubic;
			sb.Add(slide, 0.3f);

			// 3. Color change (0.6s - 0.9s)
			let colorAnim = ColorAnimation.Background(Color(150, 100, 200, 255), Color(100, 200, 150, 255));
			colorAnim.Duration = 0.3f;
			sb.Add(colorAnim, 0.6f);

			// Start storyboard
			manager.Start(sb);
			UpdateStatus("Playing storyboard: Fade -> Slide -> Color");
		}
	}

	private Panel CreateLoopingDemo()
	{
		let section = CreateSection("Looping & Auto-Reverse");

		// Target panel
		mLoopingPanel = new Panel();
		mLoopingPanel.Width = 60;
		mLoopingPanel.Height = 60;
		mLoopingPanel.Background = Color(100, 180, 180, 255);
		mLoopingPanel.Margin = .(10, 10, 10, 10);
		section.AddChild(mLoopingPanel);

		// Buttons
		let buttonRow = new StackPanel();
		buttonRow.Orientation = .Horizontal;
		buttonRow.Margin = .(10, 5, 10, 5);
		section.AddChild(buttonRow);

		let pulseBtn = new Button("Pulse");
		pulseBtn.Width = 70;
		pulseBtn.Margin = .(0, 0, 5, 0);
		pulseBtn.Click.Subscribe(new (btn) => {
			StartPulseAnimation();
		});
		buttonRow.AddChild(pulseBtn);

		let bounceBtn = new Button("Bounce");
		bounceBtn.Width = 70;
		bounceBtn.Margin = .(0, 0, 5, 0);
		bounceBtn.Click.Subscribe(new (btn) => {
			StartBounceAnimation();
		});
		buttonRow.AddChild(bounceBtn);

		let stopBtn = new Button("Stop");
		stopBtn.Width = 70;
		stopBtn.Click.Subscribe(new (btn) => {
			StopLoopingAnimations();
		});
		buttonRow.AddChild(stopBtn);

		return section;
	}

	private void StartPulseAnimation()
	{
		let context = mLoopingPanel.Context;
		if (context == null)
			return;

		if (context.GetService<AnimationManager>() case .Ok(let manager))
		{
			// Stop existing animations on this element
			manager.StopAllFor(mLoopingPanel);

			let pulse = FloatAnimation.Opacity(1, 0.3f);
			pulse.Duration = 0.5f;
			pulse.IsLooping = true;
			pulse.AutoReverse = true;
			pulse.EasingFunction = Easing.SineInOut;
			pulse.SetTarget(mLoopingPanel);
			manager.Start(pulse);

			UpdateStatus("Playing pulse animation (opacity loop)");
		}
	}

	private void StartBounceAnimation()
	{
		let context = mLoopingPanel.Context;
		if (context == null)
			return;

		if (context.GetService<AnimationManager>() case .Ok(let manager))
		{
			// Stop existing animations on this element
			manager.StopAllFor(mLoopingPanel);

			// Reset opacity
			mLoopingPanel.Opacity = 1;

			let bounce = ThicknessAnimation.Margin(.(10, 10, 10, 10), .(10, 50, 10, 10));
			bounce.Duration = 0.4f;
			bounce.IsLooping = true;
			bounce.AutoReverse = true;
			bounce.EasingFunction = Easing.BounceOut;
			bounce.SetTarget(mLoopingPanel);
			manager.Start(bounce);

			UpdateStatus("Playing bounce animation (margin loop)");
		}
	}

	private void StopLoopingAnimations()
	{
		let context = mLoopingPanel.Context;
		if (context == null)
			return;

		if (context.GetService<AnimationManager>() case .Ok(let manager))
		{
			manager.StopAllFor(mLoopingPanel);
			mLoopingPanel.Opacity = 1;
			mLoopingPanel.Margin = .(10, 10, 10, 10);
			UpdateStatus("Stopped looping animations");
		}
	}

	private Panel CreateSection(StringView title)
	{
		let section = new StackPanel();
		section.Orientation = .Vertical;
		section.Margin = .(5, 5, 5, 5);
		section.Padding = .(5, 5, 5, 5);

		let label = new TextBlock(title);
		label.FontSize = 14;
		label.Margin = .(5, 5, 5, 5);
		section.AddChild(label);

		return section;
	}

	private void UpdateStatus(StringView text)
	{
		if (mStatusLabel != null)
			mStatusLabel.Text = text;
	}
}
