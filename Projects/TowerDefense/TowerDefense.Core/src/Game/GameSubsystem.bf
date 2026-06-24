namespace TowerDefense;

using System;
using Sedulous.Runtime;
using Sedulous.Engine.Core;
using Sedulous.Messaging;
using Sedulous.Messaging.Runtime;
using Sedulous.Engine;

/// Central game subsystem. Manages game state (gold, lives, phase, speed) and
/// injects all gameplay ComponentManagers into scenes. Owns MapSystem
/// and WaveSystem as plain objects.
class GameSubsystem : Subsystem, ISceneAware
{
	public override int32 UpdateOrder => -200;

	// Game state
	private int32 mGold = 250;
	private int32 mLives = 20;
	private int32 mMaxLives = 20;
	private GamePhase mPhase = .MainMenu;
	private GamePhase mPreviousPhase = .MainMenu;
	private float mGameSpeed = 1.0f;

	// Owned systems
	private MapSystem mMapSystem = new .() ~ delete _;
	private WaveSystem mWaveSystem = new .() ~ delete _;

	// Injected references (set by TowerDefenseApp before startup)
	public ModelManifest Manifest;

	// The scene this subsystem owns at launch (set via SetScene from the
	// module's OnLaunch). Update is a no-op while this is null - guarantees
	// the subsystem does nothing at edit time even though it's registered
	// during Configure so the editor can enumerate Tower Defense component
	// types in its Add Component menu.
	private Scene mScene;

	// Component managers (injected into scene, held for cross-system access)
	private EnemyComponentManager mEnemyMgr;
	private TowerComponentManager mTowerMgr;
	private ProjectileComponentManager mProjectileMgr;

	public TowerComponentManager TowerMgr => mTowerMgr;
	public EnemyComponentManager EnemyMgr => mEnemyMgr;
	public ProjectileComponentManager ProjectileMgr => mProjectileMgr;

	/// The gameplay scene, set by the module after OnLaunch. Null at edit time.
	public Scene Scene => mScene;

	/// Called by TowerDefenseModule once the game scene is created in OnLaunch,
	/// and again with null in OnExit. Untilthis is set the subsystem's Update
	/// is a no-op - critical so it doesn't stomp on editor-owned scenes'
	/// SimulationEnabled flag while the module is sitting idle at edit time.
	public void SetScene(Scene scene)
	{
		mScene = scene;
	}

	// Message bus (resolved in OnReady)
	private MessageBus mBus;
	private SubscriptionHandle mEnemyKilledSub;
	private SubscriptionHandle mEnemyReachedEndSub;
	private SubscriptionHandle mWaveCompletedSub;

	// --- Public API ---

	public int32 Gold => mGold;
	public int32 Lives => mLives;
	public int32 MaxLives => mMaxLives;
	public int32 CurrentWave => mWaveSystem.CurrentWave;
	public int32 TotalWaves => mWaveSystem.TotalWaves;
	public GamePhase Phase => mPhase;
	public float GameSpeed => mGameSpeed;
	public MapSystem Map => mMapSystem;
	public WaveSystem Waves => mWaveSystem;
	public MessageBus Bus => mBus;

	/// Whether the game is in an active gameplay phase (not menu, paused, or ended).
	public bool IsGameplayPhase => mPhase == .WaitingToStart || mPhase == .WaveInProgress || mPhase == .WavePaused;

	/// Attempts to spend gold. Returns true if sufficient, false otherwise.
	public bool SpendGold(int32 amount)
	{
		if (mGold < amount)
			return false;

		mGold -= amount;
		PublishResourceChanged(-amount);
		return true;
	}

	/// Adds gold and publishes resource change.
	public void AddGold(int32 amount)
	{
		mGold += amount;
		PublishResourceChanged(amount);
	}

	/// Sets the game phase and publishes change message.
	public void SetPhase(GamePhase newPhase)
	{
		if (mPhase == newPhase)
			return;

		let oldPhase = mPhase;
		mPhase = newPhase;

		if (mBus != null)
		{
			GamePhaseChangedMsg msg = .() { OldPhase = oldPhase, NewPhase = newPhase };
			mBus.Publish<GamePhaseChangedMsg>(ref msg);
		}
	}

	/// Pause the game from a gameplay phase.
	public void PauseGame()
	{
		if (!IsGameplayPhase)
			return;

		mPreviousPhase = mPhase;
		SetPhase(.Paused);
	}

	/// Resume the game from pause, restoring the previous gameplay phase.
	public void ResumeGame()
	{
		if (mPhase != .Paused)
			return;

		SetPhase(mPreviousPhase);
	}

	/// Sets the game speed multiplier (1.0, 2.0, 3.0).
	public void SetGameSpeed(float speed)
	{
		mGameSpeed = Math.Clamp(speed, 1.0f, 3.0f);

		if (mBus != null)
		{
			GameSpeedChangedMsg msg = .() { NewSpeed = mGameSpeed };
			mBus.Publish<GameSpeedChangedMsg>(ref msg);
		}
	}

	/// Resets game state for a new game.
	public void ResetGame()
	{
		mGold = 250;
		mLives = 20;
		mGameSpeed = 1.0f;
		mPreviousPhase = .MainMenu;
	}

	// --- Lifecycle ---

	protected override void OnReady()
	{
		// Get message bus from MessagingSubsystem
		let messaging = Context.GetSubsystem<MessagingSubsystem>();
		if (messaging != null)
		{
			mBus = messaging.Bus;

			// Subscribe to game events
			mEnemyKilledSub = mBus.Subscribe<EnemyKilledMsg>(new (msg) =>
				{
					AddGold(msg.Reward);
					Console.WriteLine("[Game] Enemy killed, +{} gold (total: {})", msg.Reward, mGold);
				});

			mEnemyReachedEndSub = mBus.Subscribe<EnemyReachedEndMsg>(new (msg) =>
				{
					if (mPhase != .WaveInProgress)
						return;

					mLives = Math.Max(0, mLives - msg.LivesLost);
					Console.WriteLine("[Game] Enemy reached end, -{} lives (remaining: {})", msg.LivesLost, mLives);
					if (mLives <= 0)
					{
						SetPhase(.GameOver);
						Console.WriteLine("[Game] GAME OVER - lives depleted");
						GameOverMsg gameOverMsg = .() { Won = false };
						mBus.Publish<GameOverMsg>(ref gameOverMsg);
					}
				});

			mWaveCompletedSub = mBus.Subscribe<WaveCompletedMsg>(new (msg) =>
				{
					// Award wave bonus gold
					if (msg.BonusGold > 0)
					{
						AddGold(msg.BonusGold);
						Console.WriteLine("[Game] Wave {} bonus: +{} gold", msg.WaveNumber, msg.BonusGold);
					}

					if (mWaveSystem.CurrentWave >= mWaveSystem.TotalWaves)
					{
						SetPhase(.Victory);
						GameOverMsg gameOverMsg = .() { Won = true };
						mBus.Publish<GameOverMsg>(ref gameOverMsg);
					}
					else
					{
						// Between waves - wait for player to start next
						SetPhase(.WavePaused);
					}
				});
		}
	}

	public override void Update(float deltaTime)
	{
		// No game scene yet -> we're still at edit time (Configure ran, but
		// OnLaunch hasn't). Everything below would either stomp on editor
		// scenes (SimulationEnabled toggle) or run dormant game systems
		// (wave spawning) against nothing.
		if (mScene == null)
			return;

		// Toggle simulation on our scene only - never touch other scenes the
		// runtime context might be hosting (e.g. an editor scene tab). The
		// SimulationOnly update functions on our component managers are
		// skipped when SimulationEnabled is false.
		mScene.SimulationEnabled = IsGameplayPhase;

		// Propagate game speed to component managers
		if (mEnemyMgr != null) mEnemyMgr.GameSpeed = mGameSpeed;
		if (mTowerMgr != null) mTowerMgr.GameSpeed = mGameSpeed;
		if (mProjectileMgr != null) mProjectileMgr.GameSpeed = mGameSpeed;

		// Update wave spawning during active wave
		if (mPhase == .WaveInProgress)
			mWaveSystem.Update(deltaTime * mGameSpeed);
	}

	protected override void OnPrepareShutdown()
	{
		// WaveSystem subs are scoped to the play session - the module's
		// OnExit calls Waves.Shutdown. By the time we get here either no
		// play session ran (subs were never added) or OnExit already
		// fired (already cleared), so we just drop the lifetime subs we
		// own here.
		if (mBus != null)
		{
			mBus.Unsubscribe(mEnemyKilledSub);
			mBus.Unsubscribe(mEnemyReachedEndSub);
			mBus.Unsubscribe(mWaveCompletedSub);
		}
	}

	// --- ISceneAware ---

	public void OnSceneCreated(Scene scene)
	{
		// Injection runs for every scene the runtime context hosts -
		// including editor scene tabs at edit time. That's intentional:
		// the editor needs these managers in any scene the user might
		// add EnemyComponent / TowerComponent / ProjectileComponent to,
		// otherwise the Add Component menu can list the types but the
		// scene can't actually store them.
		//
		// Pure runtime state (WaveSystem subscriptions + per-game
		// counters) is NOT initialized here - the module drives that
		// from OnLaunch / OnExit so it only exists during a play session
		// and only against the actual game scene.

		// Inject enemy component manager
		mEnemyMgr = new EnemyComponentManager();
		mEnemyMgr.Bus = mBus;
		mEnemyMgr.Manifest = Manifest;
		scene.AddModule(mEnemyMgr);

		// Inject projectile component manager
		mProjectileMgr = new ProjectileComponentManager();
		mProjectileMgr.Bus = mBus;
		mProjectileMgr.EnemyMgr = mEnemyMgr;
		mProjectileMgr.Manifest = Manifest;
		scene.AddModule(mProjectileMgr);

		// Inject tower component manager
		mTowerMgr = new TowerComponentManager();
		mTowerMgr.Bus = mBus;
		mTowerMgr.EnemyMgr = mEnemyMgr;
		mTowerMgr.ProjectileMgr = mProjectileMgr;
		scene.AddModule(mTowerMgr);
	}

	public void OnSceneReady(Scene scene)
	{
		// Update enemy waypoints now that the map may have been built
		UpdateWaypoints();
	}

	/// Call after BuildMap to update enemy waypoints.
	public void UpdateWaypoints()
	{
		if (mEnemyMgr != null)
			mEnemyMgr.Waypoints = mMapSystem.GetWaypoints();
	}
	public void OnSceneDestroyed(Scene scene) { }

	// --- Internal ---

	private void PublishResourceChanged(int32 delta)
	{
		if (mBus != null)
		{
			ResourceChangedMsg msg = .() { NewAmount = mGold, Delta = delta };
			mBus.Publish<ResourceChangedMsg>(ref msg);
		}
	}
}
