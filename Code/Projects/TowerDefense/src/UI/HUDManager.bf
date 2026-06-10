namespace TowerDefense;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Core.Mathematics;
using Sedulous.Messaging;
using Sedulous.Images;

/// In-game HUD using DockLayout: top bar (gold/lives/wave/status),
/// bottom bar (tower buttons + info). Added directly to screen RootView.
class HUDManager
{
	private DockLayout mRoot;
	private Label mGoldLabel;
	private Label mLivesLabel;
	private Label mWaveLabel;
	private Label mStatusLabel;

	// Top bar controls
	private Button mStartWaveBtn;
	private Button mSpeed1Btn;
	private Button mSpeed2Btn;
	private Button mSpeed3Btn;
	private float mCurrentSpeed = 1.0f;

	// Callbacks
	public delegate void() StartWaveCallback ~ delete _;
	public delegate void(float) SetSpeedCallback ~ delete _;

	// Tower preview images (owned).
	private List<OwnedImageData> mTowerImages = new .() ~ DeleteContainerAndItems!(_);

	// Tower info panel (right side)
	private TowerInfoPanel mTowerInfo = new .() ~ delete _;

	// Message subscriptions
	private SubscriptionHandle mResourceSub;
	private SubscriptionHandle mEnemyReachedSub;
	private SubscriptionHandle mWaveStartedSub;
	private SubscriptionHandle mWaveCompletedSub;
	private SubscriptionHandle mGameOverSub;
	private SubscriptionHandle mPhaseChangedSub;

	/// The root DockLayout. Add to RootView with Match.
	public DockLayout Root => mRoot;

	// SVG icon strings
	private static readonly String sCoinSVG = """
		<svg viewBox="0 0 24 24">
		  <circle cx="12" cy="12" r="10" fill="#FFD700" stroke="#B8960F" stroke-width="1.5"/>
		  <text x="12" y="17" text-anchor="middle" font-size="14" font-weight="bold" fill="#8B6914">$</text>
		</svg>
		""";

	private static readonly String sHeartSVG = """
		<svg viewBox="0 0 24 24">
		  <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" fill="#FF4444"/>
		</svg>
		""";

	private static readonly String sWaveSVG = """
		<svg viewBox="0 0 24 24">
		  <path d="M3 12c2-3 4-3 6 0s4 3 6 0 4-3 6 0" fill="none" stroke="#7EB8FF" stroke-width="2.5" stroke-linecap="round"/>
		  <path d="M3 17c2-3 4-3 6 0s4 3 6 0 4-3 6 0" fill="none" stroke="#7EB8FF" stroke-width="2" stroke-linecap="round" opacity="0.5"/>
		</svg>
		""";

	public void Setup(MessageBus bus, GameSubsystem gameSub, TowerPlacement placement, StringView previewDir)
	{
		mRoot = new DockLayout();
		mRoot.LastChildFill = false; // don't stretch bottom bar to fill
		mRoot.IsHitTestVisible = false; // let clicks pass through to 3D

		// === Top bar ===
		let topBar = new Panel();
		topBar.Background = new ColorDrawable(.(0, 0, 0, 180));
		topBar.Padding = .(16, 6, 16, 6);

		let topLayout = new FlexLayout();
		topLayout.Direction = .Horizontal;
		topLayout.Spacing = 20;
		topLayout.AlignItems = .Center;
		topBar.AddView(topLayout, new LayoutParams() { Width = .Match, Height = .Match });

		// Gold: coin icon + label
		let goldGroup = new FlexLayout() { Direction = .Horizontal, Spacing = 6, AlignItems = .Center };
		if (let coinIcon = SVGDrawable.FromString(sCoinSVG))
			goldGroup.AddView(new DrawableView(coinIcon, 20, 20, ownsDrawable: true));
		mGoldLabel = new Label();
		mGoldLabel.FontSize.Value = 16;
		mGoldLabel.TextColor.Value = .(255, 220, 50, 255);
		goldGroup.AddView(mGoldLabel);
		topLayout.AddView(goldGroup);

		// Lives: heart icon + label
		let livesGroup = new FlexLayout() { Direction = .Horizontal, Spacing = 6, AlignItems = .Center };
		if (let heartIcon = SVGDrawable.FromString(sHeartSVG))
			livesGroup.AddView(new DrawableView(heartIcon, 20, 20, ownsDrawable: true));
		mLivesLabel = new Label();
		mLivesLabel.FontSize.Value = 16;
		mLivesLabel.TextColor.Value = .(255, 80, 80, 255);
		livesGroup.AddView(mLivesLabel);
		topLayout.AddView(livesGroup);

		// Wave: wave icon + label
		let waveGroup = new FlexLayout() { Direction = .Horizontal, Spacing = 6, AlignItems = .Center };
		if (let waveIcon = SVGDrawable.FromString(sWaveSVG))
			waveGroup.AddView(new DrawableView(waveIcon, 20, 20, ownsDrawable: true));
		mWaveLabel = new Label();
		mWaveLabel.FontSize.Value = 16;
		mWaveLabel.TextColor.Value = .(150, 180, 255, 255);
		waveGroup.AddView(mWaveLabel);
		topLayout.AddView(waveGroup);

		mStatusLabel = new Label();
		mStatusLabel.FontSize.Value = 14;
		mStatusLabel.TextColor.Value = .(180, 180, 180, 255);
		mStatusLabel.HAlign.Value = .Right;
		topLayout.AddView(mStatusLabel, new FlexLayout.LayoutParams() { Grow = 1 });

		// Start Wave button
		mStartWaveBtn = new Button("Start Wave");
		mStartWaveBtn.FontSize.Value = 12;
		mStartWaveBtn.Background = new ColorDrawable(.(40, 120, 60, 255));
		mStartWaveBtn.OnClick.Add(new (btn) => { if (StartWaveCallback != null) StartWaveCallback(); });
		topLayout.AddView(mStartWaveBtn);

		// Speed controls
		let speedGroup = new FlexLayout() { Direction = .Horizontal, Spacing = 2, AlignItems = .Center };
		mSpeed1Btn = new Button("1x");
		mSpeed1Btn.FontSize.Value = 11;
		mSpeed1Btn.Background = new ColorDrawable(.(80, 140, 200, 255)); // active by default
		mSpeed1Btn.OnClick.Add(new (btn) => SetSpeed(1.0f));
		speedGroup.AddView(mSpeed1Btn);

		mSpeed2Btn = new Button("2x");
		mSpeed2Btn.FontSize.Value = 11;
		mSpeed2Btn.OnClick.Add(new (btn) => SetSpeed(2.0f));
		speedGroup.AddView(mSpeed2Btn);

		mSpeed3Btn = new Button("3x");
		mSpeed3Btn.FontSize.Value = 11;
		mSpeed3Btn.OnClick.Add(new (btn) => SetSpeed(3.0f));
		speedGroup.AddView(mSpeed3Btn);

		topLayout.AddView(speedGroup);

		mRoot.AddView(topBar, new DockLayout.LayoutParams(.Top) { Height = .Fixed(.Px(36)) });

		// === Bottom bar ===
		let bottomBar = new Panel();
		bottomBar.Background = new ColorDrawable(.(0, 0, 0, 180));
		bottomBar.Padding = .(16, 4, 16, 4);

		let bottomLayout = new FlexLayout();
		bottomLayout.Direction = .Horizontal;
		bottomLayout.Spacing = 8;
		bottomLayout.AlignItems = .Center;
		bottomBar.AddView(bottomLayout, new LayoutParams() { Width = .Match, Height = .Match });

		AddTowerButton(bottomLayout, .Ballista, "Ballista", placement, previewDir);
		AddTowerButton(bottomLayout, .Cannon, "Cannon", placement, previewDir);
		AddTowerButton(bottomLayout, .Catapult, "Catapult", placement, previewDir);
		AddTowerButton(bottomLayout, .Turret, "Turret", placement, previewDir);

		let infoLabel = new Label("Click to place | RMB cancel | Space = wave");
		infoLabel.FontSize.Value = 12;
		infoLabel.TextColor.Value = .(150, 150, 150, 255);
		infoLabel.HAlign.Value = .Right;
		infoLabel.VAlign.Value = .Middle;
		bottomLayout.AddView(infoLabel, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });

		mRoot.AddView(bottomBar, new DockLayout.LayoutParams(.Bottom) { Height = .Fixed(.Px(60)) });

		// Tower info panel (right side, hidden by default)
		mTowerInfo.Setup(bus, placement, gameSub);
		mRoot.AddView(mTowerInfo.Root, new DockLayout.LayoutParams(.Right) { Width = .Fixed(.Px(180)) });

		// Initial values
		UpdateLabels(gameSub);
		mStatusLabel.SetText("Place towers, then start wave");

		// Message subscriptions for live updates
		if (bus != null)
		{
			mResourceSub = bus.Subscribe<ResourceChangedMsg>(new (msg) => { UpdateGold(gameSub); });
			mEnemyReachedSub = bus.Subscribe<EnemyReachedEndMsg>(new (msg) => { UpdateLives(gameSub); });
			mWaveStartedSub = bus.Subscribe<WaveStartedMsg>(new (msg) => { UpdateWave(gameSub); mStatusLabel.SetText("Wave in progress..."); });
			mWaveCompletedSub = bus.Subscribe<WaveCompletedMsg>(new (msg) =>
				{
					UpdateWave(gameSub);
					if (msg.BonusGold > 0)
					{
						let bonusText = scope String();
						bonusText.AppendF("Wave complete! +{} bonus gold", msg.BonusGold);
						mStatusLabel.SetText(bonusText);
					}
					else
						mStatusLabel.SetText("Wave complete! Start next wave");
				});
			mGameOverSub = bus.Subscribe<GameOverMsg>(new (msg) => { mStatusLabel.SetText(msg.Won ? "VICTORY!" : "GAME OVER"); });
			mPhaseChangedSub = bus.Subscribe<GamePhaseChangedMsg>(new (msg) =>
				{
					if (msg.NewPhase == .WaitingToStart) { mStatusLabel.SetText("Place towers, then start wave"); UpdateLabels(gameSub); }
					else if (msg.NewPhase == .WavePaused) { mStatusLabel.SetText("Start next wave when ready"); }

					// Show/hide Start Wave button based on phase
					if (mStartWaveBtn != null)
					{
						if (msg.NewPhase == .WaitingToStart || msg.NewPhase == .WavePaused)
							mStartWaveBtn.Visibility = .Visible;
						else
							mStartWaveBtn.Visibility = .Gone;
					}
				});
		}
	}

	public void Shutdown(MessageBus bus)
	{
		mTowerInfo.Shutdown(bus);

		if (bus != null)
		{
			bus.Unsubscribe(mResourceSub);
			bus.Unsubscribe(mEnemyReachedSub);
			bus.Unsubscribe(mWaveStartedSub);
			bus.Unsubscribe(mWaveCompletedSub);
			bus.Unsubscribe(mGameOverSub);
			bus.Unsubscribe(mPhaseChangedSub);
		}
	}

	private void AddTowerButton(FlexLayout layout, TowerType type, StringView name, TowerPlacement placement, StringView previewDir)
	{
		let stats = TowerStats.Get(type);
		let cost = stats.Levels[0].Cost;

		// Load preview image.
		OwnedImageData previewImage = null;
		let previewPath = scope String();
		previewPath.AppendF("{}/{}.png", previewDir, stats.WeaponModel);
		if (ImageLoaderFactory.LoadImage(previewPath) case .Ok(let img))
		{
			previewImage = new OwnedImageData(img.Width, img.Height, img.Format, img.Data);
			mTowerImages.Add(previewImage);
			delete img;
		}

		// Build content: image on left, name + cost stacked on right.
		let content = new FlexLayout();
		content.Direction = .Horizontal;
		content.Spacing = 6;
		content.AlignItems = .Center;

		if (previewImage != null)
		{
			let imgView = new ImageView(previewImage);
			imgView.ScaleType.Value = .FitCenter;
			content.AddView(imgView, new FlexLayout.LayoutParams() {
				Width = .Fixed(.Px(36)), Height = .Fixed(.Px(36))
			});
		}

		let textCol = new FlexLayout();
		textCol.Direction = .Vertical;
		textCol.Spacing = 1;

		let nameLabel = new Label(name);
		nameLabel.FontSize.Value = 12;
		textCol.AddView(nameLabel);

		let costText = scope String();
		costText.AppendF("${}", cost);
		let costLabel = new Label(costText);
		costLabel.FontSize.Value = 10;
		costLabel.TextColor.Value = .(255, 220, 50, 200);
		textCol.AddView(costLabel);

		content.AddView(textCol);

		let btn = new ContentButton(content);
		let capturedType = type;
		btn.OnClick.Add(new (b) => { placement.SelectedType = capturedType; });
		layout.AddView(btn, new FlexLayout.LayoutParams() { Height = .Fixed(.Px(48)) });
	}

	private void SetSpeed(float speed)
	{
		mCurrentSpeed = speed;
		UpdateSpeedButtons();
		if (SetSpeedCallback != null)
			SetSpeedCallback(speed);
	}

	private void UpdateSpeedButtons()
	{
		// Highlight active speed button, reset others. Field assignment
		// to a RefCounted Drawable consumes the ref; releasing the
		// previous one keeps the field from leaking on overwrite.
		let activeColor = new ColorDrawable(.(80, 140, 200, 255));
		if (mSpeed1Btn != null) { mSpeed1Btn.Background?.ReleaseRef(); mSpeed1Btn.Background = (mCurrentSpeed == 1.0f) ? activeColor : null; }
		if (mSpeed2Btn != null) { mSpeed2Btn.Background?.ReleaseRef(); mSpeed2Btn.Background = (mCurrentSpeed == 2.0f) ? new ColorDrawable(.(80, 140, 200, 255)) : null; }
		if (mSpeed3Btn != null) { mSpeed3Btn.Background?.ReleaseRef(); mSpeed3Btn.Background = (mCurrentSpeed == 3.0f) ? new ColorDrawable(.(80, 140, 200, 255)) : null; }
		if (mCurrentSpeed != 1.0f) activeColor.ReleaseRef();
	}

	private void UpdateLabels(GameSubsystem gs) { UpdateGold(gs); UpdateLives(gs); UpdateWave(gs); }
	private void UpdateGold(GameSubsystem gs) { let s = scope String(); s.AppendF("{}", gs.Gold); mGoldLabel.SetText(s); }
	private void UpdateLives(GameSubsystem gs) { let s = scope String(); s.AppendF("{}/{}", gs.Lives, gs.MaxLives); mLivesLabel.SetText(s); }
	private void UpdateWave(GameSubsystem gs) { let s = scope String(); s.AppendF("{}/{}", gs.Waves.CurrentWave, gs.Waves.TotalWaves); mWaveLabel.SetText(s); }
}
