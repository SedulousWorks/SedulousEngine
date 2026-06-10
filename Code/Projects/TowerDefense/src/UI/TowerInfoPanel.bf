namespace TowerDefense;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;
using Sedulous.Messaging;

/// Right-side panel showing selected tower info with upgrade and sell buttons.
class TowerInfoPanel
{
	private Panel mRoot;
	private Label mNameLabel;
	private Label mDamageLabel;
	private Label mRangeLabel;
	private Label mFireRateLabel;
	private Button mUpgradeBtn;
	private Button mSellBtn;

	private TowerPlacement mPlacement;
	private GameSubsystem mGameSub;

	// Message subscriptions
	private SubscriptionHandle mTowerSelectedSub;
	private SubscriptionHandle mTowerUpgradedSub;
	private SubscriptionHandle mResourceChangedSub;

	public Panel Root => mRoot;

	public void Setup(MessageBus bus, TowerPlacement placement, GameSubsystem gameSub)
	{
		mPlacement = placement;
		mGameSub = gameSub;

		// Right-side panel with dark background
		mRoot = new Panel();
		mRoot.SetStyle(.Background, new ColorDrawable(.(0, 0, 0, 200)));
		mRoot.Padding = .(12, 10, 12, 10);
		mRoot.Visibility = .Gone; // hidden by default

		let layout = new FlexLayout();
		layout.Direction = .Vertical;
		layout.Spacing = 6;
		mRoot.AddView(layout, new LayoutParams() { Width = .Match, Height = .Match });

		// Tower name + level
		mNameLabel = new Label("Tower");
		mNameLabel.FontSize.Value = 16;
		mNameLabel.TextColor.Value = .(220, 230, 240, 255);
		mNameLabel.HAlign.Value = .Center;
		layout.AddView(mNameLabel, new FlexLayout.LayoutParams() { Width = .Match });

		layout.AddView(new Separator());

		// Stats
		mDamageLabel = new Label("Damage: 0");
		mDamageLabel.FontSize.Value = 13;
		mDamageLabel.TextColor.Value = .(255, 180, 80, 255);
		layout.AddView(mDamageLabel);

		mRangeLabel = new Label("Range: 0");
		mRangeLabel.FontSize.Value = 13;
		mRangeLabel.TextColor.Value = .(100, 200, 255, 255);
		layout.AddView(mRangeLabel);

		mFireRateLabel = new Label("Fire Rate: 0/s");
		mFireRateLabel.FontSize.Value = 13;
		mFireRateLabel.TextColor.Value = .(180, 255, 150, 255);
		layout.AddView(mFireRateLabel);

		layout.AddView(new Spacer(0, 4));

		// Upgrade button
		mUpgradeBtn = new Button("Upgrade");
		mUpgradeBtn.FontSize.Value = 13;
		mUpgradeBtn.SetStyle(.Background, new ColorDrawable(.(40, 120, 60, 255)));
		mUpgradeBtn.OnClick.Add(new (btn) =>
			{
				if (mPlacement.UpgradeTower(mGameSub, mGameSub.TowerMgr))
					RefreshInfo();
			});
		layout.AddView(mUpgradeBtn, new FlexLayout.LayoutParams() { Width = .Match });

		// Sell button
		mSellBtn = new Button("Sell");
		mSellBtn.FontSize.Value = 13;
		mSellBtn.SetStyle(.Background, new ColorDrawable(.(150, 50, 50, 255)));
		mSellBtn.OnClick.Add(new (btn) =>
			{
				mPlacement.SellTower(mGameSub, mGameSub.TowerMgr, mGameSub.Context.GetSubsystem<Sedulous.Engine.SceneSubsystem>().ActiveScenes[0]);
			});
		layout.AddView(mSellBtn, new FlexLayout.LayoutParams() { Width = .Match });

		// Subscribe to messages
		if (bus != null)
		{
			mTowerSelectedSub = bus.Subscribe<TowerSelectedMsg>(new (msg) =>
				{
					if (msg.EntityId == .Invalid)
						mRoot.Visibility = .Gone;
					else
						RefreshInfo();
				});

			mTowerUpgradedSub = bus.Subscribe<TowerUpgradedMsg>(new (msg) =>
				{
					if (msg.EntityId == mPlacement.SelectedTower)
						RefreshInfo();
				});

			mResourceChangedSub = bus.Subscribe<ResourceChangedMsg>(new (msg) =>
				{
					if (mRoot.Visibility == .Visible)
						RefreshUpgradeButton();
				});
		}
	}

	private void RefreshInfo()
	{
		let towerMgr = mGameSub.TowerMgr;
		if (towerMgr == null) return;

		let comp = towerMgr.GetForEntity(mPlacement.SelectedTower);
		if (comp == null)
		{
			mRoot.Visibility = .Gone;
			return;
		}

		// Name + level
		let nameText = scope String();
		nameText.AppendF("{} Lv.{}", comp.Type, comp.Level);
		mNameLabel.SetText(nameText);

		// Stats
		let dmgText = scope String();
		dmgText.AppendF("Damage: {:.1}", comp.Damage);
		mDamageLabel.SetText(dmgText);

		let rngText = scope String();
		rngText.AppendF("Range: {:.1}", comp.Range);
		mRangeLabel.SetText(rngText);

		let frText = scope String();
		frText.AppendF("Fire Rate: {:.1}/s", comp.FireRate);
		mFireRateLabel.SetText(frText);

		RefreshUpgradeButton();
		RefreshSellButton(comp);

		mRoot.Visibility = .Visible;
	}

	private void RefreshUpgradeButton()
	{
		let towerMgr = mGameSub.TowerMgr;
		if (towerMgr == null) return;

		let comp = towerMgr.GetForEntity(mPlacement.SelectedTower);
		if (comp == null) return;

		if (comp.Level >= 3)
		{
			mUpgradeBtn.SetText("MAX LEVEL");
			mUpgradeBtn.IsEnabled = false;
		}
		else
		{
			let stats = TowerStats.Get(comp.Type);
			let cost = stats.Levels[comp.Level].Cost;
			let text = scope String();
			text.AppendF("Upgrade (${})", cost);
			mUpgradeBtn.SetText(text);
			mUpgradeBtn.IsEnabled = mGameSub.Gold >= cost;
		}
	}

	private void RefreshSellButton(TowerComponent comp)
	{
		let refund = comp.TotalInvested / 2;
		let text = scope String();
		text.AppendF("Sell (${})", refund);
		mSellBtn.SetText(text);
	}

	public void Shutdown(MessageBus bus)
	{
		if (bus != null)
		{
			bus.Unsubscribe(mTowerSelectedSub);
			bus.Unsubscribe(mTowerUpgradedSub);
			bus.Unsubscribe(mResourceChangedSub);
		}
	}
}
