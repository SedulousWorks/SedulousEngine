namespace TowerDefense;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;
using Sedulous.Messaging;

/// Full-screen game over / victory overlay with stats and action buttons.
class GameOverUI
{
	private Panel mRoot; // Owned by view tree (parent deletes)
	private Label mTitleLabel;
	private Label mResultLabel;
	private Label mStatsLabel;
	private SubscriptionHandle mGameOverSub;

	public delegate void() OnRestart ~ delete _;
	public delegate void() OnMainMenu ~ delete _;

	public Panel Root => mRoot;

	public void Setup(RootView root, MessageBus bus, delegate void() onRestart, delegate void() onMainMenu)
	{
		OnRestart = onRestart;
		OnMainMenu = onMainMenu;

		// Full-screen dark overlay
		mRoot = new Panel();
		mRoot.Background = new ColorDrawable(.(0, 0, 0, 180));
		mRoot.IsHitTestVisible = true;
		mRoot.Visibility = .Gone;

		// Centered content
		let content = new FlexLayout();
		content.Direction = .Vertical;
		content.Spacing = 12;
		content.AlignItems = .Center;
		content.JustifyContent = .Center;
		mRoot.AddView(content, new LayoutParams() { Width = .Match, Height = .Match });

		// Title (set dynamically)
		mTitleLabel = new Label();
		mTitleLabel.FontSize.Value = 28;
		mTitleLabel.HAlign.Value = .Center;
		content.AddView(mTitleLabel);

		// Result message
		mResultLabel = new Label();
		mResultLabel.FontSize.Value = 16;
		mResultLabel.HAlign.Value = .Center;
		content.AddView(mResultLabel);

		// Stats
		mStatsLabel = new Label();
		mStatsLabel.FontSize.Value = 13;
		mStatsLabel.TextColor.Value = .(180, 180, 180, 255);
		mStatsLabel.HAlign.Value = .Center;
		content.AddView(mStatsLabel);

		content.AddView(new Spacer(0, 12));

		// Buttons
		let btnRow = new FlexLayout() { Direction = .Horizontal, Spacing = 12, AlignItems = .Center };

		let restartBtn = new Button("Restart");
		restartBtn.FontSize.Value = 16;
		restartBtn.Background = new ColorDrawable(.(40, 120, 60, 255));
		restartBtn.OnClick.Add(new (btn) =>
			{
				Hide();
				if (OnRestart != null) OnRestart();
			});
		btnRow.AddView(restartBtn);

		let menuBtn = new Button("Main Menu");
		menuBtn.FontSize.Value = 16;
		menuBtn.Background = new ColorDrawable(.(120, 50, 50, 255));
		menuBtn.OnClick.Add(new (btn) =>
			{
				Hide();
				if (OnMainMenu != null) OnMainMenu();
			});
		btnRow.AddView(menuBtn);

		content.AddView(btnRow);

		// Add to view tree immediately - view tree owns mRoot
		root.AddView(mRoot, new LayoutParams() { Width = .Match, Height = .Match });

		// Subscribe to GameOverMsg
		if (bus != null)
		{
			mGameOverSub = bus.Subscribe<GameOverMsg>(new (msg) =>
				{
					ShowResult(msg.Won);
				});
		}
	}

	private void ShowResult(bool won)
	{
		if (won)
		{
			mTitleLabel.SetText("VICTORY!");
			mTitleLabel.TextColor.Value = .(50, 255, 50, 255);
			mResultLabel.SetText("You defended your base!");
			mResultLabel.TextColor.Value = .(150, 255, 150, 255);
		}
		else
		{
			mTitleLabel.SetText("GAME OVER");
			mTitleLabel.TextColor.Value = .(255, 80, 80, 255);
			mResultLabel.SetText("Your base was overrun!");
			mResultLabel.TextColor.Value = .(255, 150, 150, 255);
		}

		mRoot.Visibility = .Visible;
	}

	/// Update stats display. Call before showing.
	public void UpdateStats(GameSubsystem gameSub)
	{
		let text = scope String();
		text.AppendF("Waves: {}  |  Gold: {}  |  Lives: {}",
			gameSub.Waves.CurrentWave, gameSub.Gold, gameSub.Lives);
		mStatsLabel.SetText(text);
	}

	public void Hide()
	{
		mRoot.Visibility = .Gone;
	}

	public void Shutdown(MessageBus bus)
	{
		if (bus != null)
			bus.Unsubscribe(mGameOverSub);
	}
}
