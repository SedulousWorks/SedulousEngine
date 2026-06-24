namespace TowerDefense;

using System;
using System.Collections;
using Sedulous.Messaging;

/// Manages wave spawning and progression. Owned by GameSubsystem.
class WaveSystem
{
	private List<WaveDefinition> mWaves ~ DeleteContainerAndItems!(_);
	private MessageBus mBus;
	private EnemyComponentManager mEnemyMgr;

	// Current wave state
	private int32 mCurrentWave = 0;
	private int32 mCurrentEntryIndex = 0;
	private int32 mSpawnedInEntry = 0;
	private float mSpawnTimer = 0;
	private float mEntryDelayTimer = 0;
	private bool mWaveActive = false;
	private int32 mEnemiesAlive = 0;
	private int32 mTotalSpawnedThisWave = 0;
	private bool mAllSpawned = false;

	// Message subscriptions
	private SubscriptionHandle mEnemyKilledSub;
	private SubscriptionHandle mEnemyReachedEndSub;

	public int32 CurrentWave => mCurrentWave;
	public int32 TotalWaves => (int32)(mWaves?.Count ?? 0);
	public bool IsWaveActive => mWaveActive;
	public int32 EnemiesAlive => mEnemiesAlive;

	public void Initialize(MessageBus bus, EnemyComponentManager enemyMgr)
	{
		// Drop any stale subscriptions from a previous Initialize before
		// rewiring. In the editor, GameSubsystem.OnSceneCreated fires
		// once per Scene the runtime context creates - including the
		// editor's open SceneEditorPage scene - so this Initialize runs
		// for the editor scene at edit-time AND again for the game
		// scene at Play. Without this unsubscribe, both delegates fire
		// per EnemyKilledMsg / EnemyReachedEndMsg, mEnemiesAlive
		// decrements by 2 per kill, and a wave with N enemies ends
		// after N-1 kills. Standalone has only one scene so the bug
		// doesn't manifest there.
		if (mBus != null)
		{
			mBus.Unsubscribe(mEnemyKilledSub);
			mBus.Unsubscribe(mEnemyReachedEndSub);
		}

		mBus = bus;
		mEnemyMgr = enemyMgr;
		// Editor flow can fire GameSubsystem.OnSceneCreated multiple times
		// (one per scene tab). Free the previous wave set before rebuilding
		// so we don't leak the prior allocation each time.
		if (mWaves != null)
		{
			DeleteContainerAndItems!(mWaves);
			mWaves = null;
		}
		mWaves = WaveDefinition.CreateDefaultWaves();

		// Reset all per-game wave state - a second OnLaunch in the editor
		// (or any reinitialize path) otherwise inherits whatever state the
		// previous run finished in. mCurrentWave especially: if a prior
		// run reached the last wave, StartNextWave bails on its
		// `mCurrentWave >= mWaves.Count` guard and the Start Wave button
		// stops responding.
		mCurrentWave = 0;
		mCurrentEntryIndex = 0;
		mSpawnedInEntry = 0;
		mSpawnTimer = 0;
		mEntryDelayTimer = 0;
		mWaveActive = false;
		mEnemiesAlive = 0;
		mTotalSpawnedThisWave = 0;
		mAllSpawned = false;

		// Subscribe to enemy death/arrival to track alive count
		if (mBus != null)
		{
			mEnemyKilledSub = mBus.Subscribe<EnemyKilledMsg>(new (msg) =>
				{
					mEnemiesAlive = Math.Max(0, mEnemiesAlive - 1);
				});

			mEnemyReachedEndSub = mBus.Subscribe<EnemyReachedEndMsg>(new (msg) =>
				{
					mEnemiesAlive = Math.Max(0, mEnemiesAlive - 1);
				});
		}
	}

	public void Shutdown()
	{
		if (mBus != null)
		{
			mBus.Unsubscribe(mEnemyKilledSub);
			mBus.Unsubscribe(mEnemyReachedEndSub);
		}
	}

	/// Starts the next wave. Call from game logic when player is ready.
	public void StartNextWave()
	{
		if (mWaves == null || mCurrentWave >= mWaves.Count)
			return;

		mCurrentEntryIndex = 0;
		mSpawnedInEntry = 0;
		mSpawnTimer = 0;
		mEntryDelayTimer = 0;
		mWaveActive = true;
		mAllSpawned = false;
		mTotalSpawnedThisWave = 0;
		mEnemiesAlive = 0;

		mCurrentWave++;
		Console.WriteLine("[Wave] Wave {}/{} started", mCurrentWave, mWaves.Count);

		if (mBus != null)
		{
			WaveStartedMsg msg = .() { WaveNumber = mCurrentWave };
			mBus.Queue<WaveStartedMsg>(msg);
		}
	}

	/// Update spawning logic. Called each frame by GameSubsystem.
	public void Update(float deltaTime)
	{
		if (!mWaveActive || mWaves == null)
			return;

		let waveDef = mWaves[mCurrentWave - 1]; // 1-based wave number

		// Check if wave is complete (all spawned and all dead)
		if (mAllSpawned && mEnemiesAlive <= 0)
		{
			mWaveActive = false;
			let bonusGold = (int32)(25 + mCurrentWave * 5);
			Console.WriteLine("[Wave] Wave {}/{} completed, bonus: {} gold", mCurrentWave, mWaves.Count, bonusGold);

			if (mBus != null)
			{
				WaveCompletedMsg msg = .() { WaveNumber = mCurrentWave, BonusGold = bonusGold };
				mBus.Queue<WaveCompletedMsg>(msg);
			}
			return;
		}

		// All entries spawned?
		if (mCurrentEntryIndex >= waveDef.Entries.Count)
		{
			mAllSpawned = true;
			return;
		}

		let entry = waveDef.Entries[mCurrentEntryIndex];

		// Handle delay before this entry starts
		if (mSpawnedInEntry == 0 && entry.DelayBefore > 0)
		{
			mEntryDelayTimer += deltaTime;
			if (mEntryDelayTimer < entry.DelayBefore)
				return;
			// Delay done, proceed to spawning
		}

		// Spawn timer
		mSpawnTimer += deltaTime;
		if (mSpawnTimer >= entry.SpawnInterval)
		{
			mSpawnTimer -= entry.SpawnInterval;

			// Spawn one enemy
			if (mEnemyMgr != null)
			{
				mEnemyMgr.SpawnEnemy(entry.Type);
				mEnemiesAlive++;
				Console.WriteLine("[Wave] Spawned {} ({} alive)", entry.Type, mEnemiesAlive);
				mSpawnedInEntry++;
				mTotalSpawnedThisWave++;
			}

			// Check if this entry is done
			if (mSpawnedInEntry >= entry.Count)
			{
				mCurrentEntryIndex++;
				mSpawnedInEntry = 0;
				mSpawnTimer = 0;
				mEntryDelayTimer = 0;
			}
		}
	}
}
