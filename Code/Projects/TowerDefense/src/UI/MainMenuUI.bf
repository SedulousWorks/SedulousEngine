namespace TowerDefense;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Full-screen main menu overlay. Added to RootView, removed when game starts.
class MainMenuUI
{
	private Panel mRoot; // Owned by view tree (parent deletes)
	public delegate void() OnStartGame ~ delete _;

	public Panel Root => mRoot;

	public void Setup(RootView root, delegate void() onStartGame)
	{
		OnStartGame = onStartGame;

		// Full-screen dark overlay
		mRoot = new Panel();
		mRoot.Background = new ColorDrawable(.(15, 20, 25, 255));
		mRoot.IsHitTestVisible = true;
		mRoot.Visibility = .Gone;

		// Centered content
		let content = new FlexLayout();
		content.Direction = .Vertical;
		content.Spacing = 16;
		content.AlignItems = .Center;
		content.JustifyContent = .Center;
		mRoot.AddView(content, new LayoutParams() { Width = .Match, Height = .Match });

		// Title
		let title = new Label("TOWER DEFENSE");
		title.FontSize.Value = 32;
		title.TextColor.Value = .(220, 230, 240, 255);
		title.HAlign.Value = .Center;
		content.AddView(title);

		// Subtitle
		let subtitle = new Label("Defend your base against waves of enemies!");
		subtitle.FontSize.Value = 14;
		subtitle.TextColor.Value = .(150, 160, 170, 255);
		subtitle.HAlign.Value = .Center;
		content.AddView(subtitle);

		// Spacer
		content.AddView(new Spacer(0, 20));

		// Start button
		let startBtn = new Button("Start Game");
		startBtn.FontSize.Value = 18;
		startBtn.Background = new ColorDrawable(.(40, 120, 60, 255));
		startBtn.OnClick.Add(new (btn) =>
			{
				if (OnStartGame != null)
					OnStartGame();
			});
		content.AddView(startBtn);

		// Controls hint
		content.AddView(new Spacer(0, 20));
		let controls = new Label("1-4: Select tower  |  Click: Place  |  Space: Start wave  |  P: Pause");
		controls.FontSize.Value = 11;
		controls.TextColor.Value = .(120, 125, 130, 255);
		controls.HAlign.Value = .Center;
		content.AddView(controls);

		// Add to view tree immediately - view tree owns mRoot
		root.AddView(mRoot, new LayoutParams() { Width = .Match, Height = .Match });
	}

	public void Show()
	{
		mRoot.Visibility = .Visible;
	}

	public void Hide()
	{
		mRoot.Visibility = .Gone;
	}
}
