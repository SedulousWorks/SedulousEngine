namespace TowerDefense;

using System;
using System.Collections;
using Sedulous.Audio;
using Sedulous.Engine.Audio;
using Sedulous.Core.Mathematics;
using Sedulous.Messaging;

/// Procedural audio system for the tower defense game.
/// All sounds are generated algorithmically - no external audio files needed.
class GameAudio
{
	private AudioSubsystem mAudio;
	private MessageBus mBus;

	// Pre-generated clips (owned)
	private AudioClip mCannonFire ~ delete _;
	private AudioClip mBallistaFire ~ delete _;
	private AudioClip mCatapultFire ~ delete _;
	private AudioClip mTurretFire ~ delete _;
	private AudioClip mEnemyDeath ~ delete _;
	private AudioClip mEnemyExit ~ delete _;
	private AudioClip mWaveStart ~ delete _;
	private AudioClip mWaveComplete ~ delete _;
	private AudioClip mVictory ~ delete _;
	private AudioClip mGameOver ~ delete _;
	private AudioClip mTowerPlace ~ delete _;
	private AudioClip mNoMoney ~ delete _;
	private AudioClip mUIClick ~ delete _;

	// Music
	private AudioClip mMusicLoop ~ delete _;
	private IAudioSource mMusicSource;

	// Message subscriptions
	private SubscriptionHandle mTowerShotSub;
	private SubscriptionHandle mEnemyKilledSub;
	private SubscriptionHandle mEnemyReachedEndSub;
	private SubscriptionHandle mWaveStartedSub;
	private SubscriptionHandle mWaveCompletedSub;
	private SubscriptionHandle mGameOverSub;
	private SubscriptionHandle mTowerPlacedSub;
	private SubscriptionHandle mPhaseChangedSub;

	private const int32 SAMPLE_RATE = 44100;

	public void Initialize(AudioSubsystem audio, MessageBus bus)
	{
		mAudio = audio;
		mBus = bus;

		// Generate all clips
		mCannonFire = GenerateBoom(100, 0.15f);
		mBallistaFire = GenerateClick(1200, 0.05f);
		mCatapultFire = GenerateBoom(60, 0.25f);
		mTurretFire = GenerateSweep(400, 1200, 0.08f);
		mEnemyDeath = GenerateNoiseBurst(0.1f);
		mEnemyExit = GenerateSweep(400, 200, 0.2f);
		mWaveStart = GenerateArpeggio(.(523, 659, 784), 0.1f, true);   // C5-E5-G5 ascending
		mWaveComplete = GenerateArpeggio(.(784, 659, 523), 0.1f, true); // G5-E5-C5 descending
		mVictory = GenerateChord(scope float[](523, 659, 784, 1047), 0.8f);        // C major
		mGameOver = GenerateChord(scope float[](311, 262, 208), 0.6f);              // Eb-C-Ab minor
		mTowerPlace = GenerateClick(400, 0.08f);
		mNoMoney = GenerateBuzz(200, 0.15f);
		mUIClick = GenerateClick(800, 0.03f);
		mMusicLoop = GenerateAmbientLoop(4.0f);

		// Subscribe to game events
		if (mBus != null)
		{
			mTowerShotSub = mBus.Subscribe<TowerShotMsg>(new (msg) =>
				{
					let clip = GetTowerFireClip(msg);
					if (clip != null)
						mAudio.PlayOneShot(clip, 0.3f);
				});

			mEnemyKilledSub = mBus.Subscribe<EnemyKilledMsg>(new (msg) =>
				{
					mAudio.PlayOneShot(mEnemyDeath, 0.25f);
				});

			mEnemyReachedEndSub = mBus.Subscribe<EnemyReachedEndMsg>(new (msg) =>
				{
					mAudio.PlayOneShot(mEnemyExit, 0.3f);
				});

			mWaveStartedSub = mBus.Subscribe<WaveStartedMsg>(new (msg) =>
				{
					mAudio.PlayOneShot(mWaveStart, 0.4f);
				});

			mWaveCompletedSub = mBus.Subscribe<WaveCompletedMsg>(new (msg) =>
				{
					mAudio.PlayOneShot(mWaveComplete, 0.4f);
				});

			mGameOverSub = mBus.Subscribe<GameOverMsg>(new (msg) =>
				{
					StopMusic();
					mAudio.PlayOneShot(msg.Won ? mVictory : mGameOver, 0.5f);
				});

			mTowerPlacedSub = mBus.Subscribe<TowerPlacedMsg>(new (msg) =>
				{
					mAudio.PlayOneShot(mTowerPlace, 0.3f);
				});

			mPhaseChangedSub = mBus.Subscribe<GamePhaseChangedMsg>(new (msg) =>
				{
					if (msg.NewPhase == .WaitingToStart && msg.OldPhase == .MainMenu)
						StartMusic();
					else if (msg.NewPhase == .Paused)
						PauseMusic();
					else if (msg.OldPhase == .Paused)
						ResumeMusic();
					else if (msg.NewPhase == .MainMenu)
						StopMusic();
				});
		}
	}

	/// Play UI click sound (for button presses).
	public void PlayUIClick()
	{
		mAudio?.PlayOneShot(mUIClick, 0.2f);
	}

	/// Play "not enough money" sound.
	public void PlayNoMoney()
	{
		mAudio?.PlayOneShot(mNoMoney, 0.3f);
	}

	public void StartMusic()
	{
		if (mAudio == null || mMusicLoop == null) return;

		if (mMusicSource == null)
		{
			mMusicSource = mAudio.AudioSystem?.CreateSource();
			if (mMusicSource != null)
			{
				mMusicSource.Volume = 0.08f;
				mMusicSource.Loop = true;
				mMusicSource.Play(mMusicLoop);
			}
		}
	}

	public void StopMusic()
	{
		if (mMusicSource != null)
		{
			mMusicSource.Stop();
			mAudio.AudioSystem?.DestroySource(mMusicSource);
			mMusicSource = null;
		}
	}

	public void PauseMusic()
	{
		mMusicSource?.Pause();
	}

	public void ResumeMusic()
	{
		mMusicSource?.Resume();
	}

	public void Shutdown()
	{
		StopMusic();

		if (mBus != null)
		{
			mBus.Unsubscribe(mTowerShotSub);
			mBus.Unsubscribe(mEnemyKilledSub);
			mBus.Unsubscribe(mEnemyReachedEndSub);
			mBus.Unsubscribe(mWaveStartedSub);
			mBus.Unsubscribe(mWaveCompletedSub);
			mBus.Unsubscribe(mGameOverSub);
			mBus.Unsubscribe(mTowerPlacedSub);
			mBus.Unsubscribe(mPhaseChangedSub);
		}
	}

	// ==================== Sound Selection ====================

	private AudioClip GetTowerFireClip(TowerShotMsg msg)
	{
		switch (msg.TowerType)
		{
		case .Cannon:   return mCannonFire;
		case .Ballista: return mBallistaFire;
		case .Catapult: return mCatapultFire;
		case .Turret:   return mTurretFire;
		}
	}

	// ==================== Procedural Sound Generation ====================

	/// Low-frequency boom with exponential decay (cannon, catapult).
	private static AudioClip GenerateBoom(float freq, float duration)
	{
		let sampleCount = (int32)(SAMPLE_RATE * duration);
		let samples = new int16[sampleCount];
		defer delete samples;

		for (int32 i = 0; i < sampleCount; i++)
		{
			let t = (float)i / SAMPLE_RATE;
			let envelope = Math.Exp(-t * 20.0f / duration);
			let sample = Math.Sin(t * freq * Math.PI_f * 2.0f) * envelope;
			samples[i] = (int16)(sample * 16000);
		}

		return AudioClip.FromInt16(samples, SAMPLE_RATE, 1);
	}

	/// Short click/tick sound (ballista, UI).
	private static AudioClip GenerateClick(float freq, float duration)
	{
		let sampleCount = (int32)(SAMPLE_RATE * duration);
		let samples = new int16[sampleCount];
		defer delete samples;

		for (int32 i = 0; i < sampleCount; i++)
		{
			let t = (float)i / SAMPLE_RATE;
			let envelope = Math.Max(0, 1.0f - t / duration);
			let sample = Math.Sin(t * freq * Math.PI_f * 2.0f) * envelope * envelope;
			samples[i] = (int16)(sample * 12000);
		}

		return AudioClip.FromInt16(samples, SAMPLE_RATE, 1);
	}

	/// Frequency sweep (turret whoosh, enemy exit).
	private static AudioClip GenerateSweep(float startFreq, float endFreq, float duration)
	{
		let sampleCount = (int32)(SAMPLE_RATE * duration);
		let samples = new int16[sampleCount];
		defer delete samples;

		for (int32 i = 0; i < sampleCount; i++)
		{
			let t = (float)i / SAMPLE_RATE;
			let progress = t / duration;
			let freq = startFreq + (endFreq - startFreq) * progress;
			let envelope = 1.0f - progress;
			let sample = Math.Sin(t * freq * Math.PI_f * 2.0f) * envelope;
			samples[i] = (int16)(sample * 12000);
		}

		return AudioClip.FromInt16(samples, SAMPLE_RATE, 1);
	}

	/// White noise burst (enemy death).
	private static AudioClip GenerateNoiseBurst(float duration)
	{
		let sampleCount = (int32)(SAMPLE_RATE * duration);
		let samples = new int16[sampleCount];
		defer delete samples;

		uint32 seed = 12345;
		for (int32 i = 0; i < sampleCount; i++)
		{
			let t = (float)i / SAMPLE_RATE;
			let envelope = Math.Max(0, 1.0f - t / duration);
			// Simple LCG noise
			seed = seed * 1103515245 + 12345;
			let noise = ((float)(seed & 0x7FFF) / 16384.0f - 1.0f);
			samples[i] = (int16)(noise * envelope * 10000);
		}

		return AudioClip.FromInt16(samples, SAMPLE_RATE, 1);
	}

	/// Buzzing error sound (no money).
	private static AudioClip GenerateBuzz(float freq, float duration)
	{
		let sampleCount = (int32)(SAMPLE_RATE * duration);
		let samples = new int16[sampleCount];
		defer delete samples;

		for (int32 i = 0; i < sampleCount; i++)
		{
			let t = (float)i / SAMPLE_RATE;
			let envelope = Math.Max(0, 1.0f - t / duration);
			// Square-ish wave for harsh buzz
			let phase = Math.Sin(t * freq * Math.PI_f * 2.0f);
			let sample = (phase > 0 ? 1.0f : -1.0f) * envelope * 0.5f;
			samples[i] = (int16)(sample * 8000);
		}

		return AudioClip.FromInt16(samples, SAMPLE_RATE, 1);
	}

	/// Ascending or descending arpeggio (wave start/complete).
	private static AudioClip GenerateArpeggio(float[3] notes, float noteLength, bool ascending)
	{
		let totalDuration = noteLength * 3;
		let sampleCount = (int32)(SAMPLE_RATE * totalDuration);
		let samples = new int16[sampleCount];
		defer delete samples;

		for (int32 i = 0; i < sampleCount; i++)
		{
			let t = (float)i / SAMPLE_RATE;
			let noteIndex = Math.Min((int32)(t / noteLength), 2);
			let noteT = t - noteIndex * noteLength;
			let freq = notes[noteIndex];
			let envelope = Math.Max(0, 1.0f - noteT / noteLength) * 0.8f;
			let sample = Math.Sin(noteT * freq * Math.PI_f * 2.0f) * envelope;
			samples[i] = (int16)(sample * 10000);
		}

		return AudioClip.FromInt16(samples, SAMPLE_RATE, 1);
	}

	/// Chord with staggered attack (victory, game over).
	private static AudioClip GenerateChord(Span<float> frequencies, float duration)
	{
		let sampleCount = (int32)(SAMPLE_RATE * duration);
		let samples = new int16[sampleCount];
		defer delete samples;

		for (int32 i = 0; i < sampleCount; i++)
		{
			let t = (float)i / SAMPLE_RATE;
			float sum = 0;

			for (int f = 0; f < frequencies.Length; f++)
			{
				let stagger = (float)f * 0.05f; // slight stagger per note
				let noteT = Math.Max(0, t - stagger);
				let envelope = Math.Exp(-noteT * 3.0f / duration);
				sum += Math.Sin(noteT * frequencies[f] * Math.PI_f * 2.0f) * envelope;
			}

			let normalized = sum / (float)frequencies.Length;
			samples[i] = (int16)(normalized * 10000);
		}

		return AudioClip.FromInt16(samples, SAMPLE_RATE, 1);
	}

	/// Ambient drone loop for background music.
	private static AudioClip GenerateAmbientLoop(float duration)
	{
		let sampleCount = (int32)(SAMPLE_RATE * duration);
		let samples = new int16[sampleCount];
		defer delete samples;

		for (int32 i = 0; i < sampleCount; i++)
		{
			let t = (float)i / SAMPLE_RATE;

			// Layered drone: A2 + E3 + A3
			float sum = 0;
			sum += Math.Sin(t * 110.0f * Math.PI_f * 2.0f) * 0.3f;  // A2
			sum += Math.Sin(t * 165.0f * Math.PI_f * 2.0f) * 0.2f;  // E3
			sum += Math.Sin(t * 220.0f * Math.PI_f * 2.0f) * 0.15f; // A3

			// High shimmer with slow modulation
			let lfo = Math.Sin(t * 0.5f * Math.PI_f * 2.0f) * 0.3f + 0.7f;
			sum += Math.Sin(t * 880.0f * Math.PI_f * 2.0f) * 0.05f * lfo;

			// Subtle noise texture
			uint32 seed = (uint32)(i * 1103515245 + 12345);
			seed = (seed >> 16) ^ seed;
			let noise = ((float)(seed & 0x7FFF) / 16384.0f - 1.0f);
			sum += noise * 0.02f;

			// Crossfade at loop boundary (last 0.1s)
			let fadeZone = 0.1f;
			if (t > duration - fadeZone)
			{
				let fadeProgress = (t - (duration - fadeZone)) / fadeZone;
				sum *= (1.0f - fadeProgress);
			}

			samples[i] = (int16)(Math.Clamp(sum, -1.0f, 1.0f) * 12000);
		}

		return AudioClip.FromInt16(samples, SAMPLE_RATE, 1);
	}
}
