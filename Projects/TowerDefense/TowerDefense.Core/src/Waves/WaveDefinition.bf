namespace TowerDefense;

using System;
using System.Collections;

/// A single spawn entry within a wave.
struct WaveEntry
{
	public EnemyType Type;
	public int32 Count;
	public float SpawnInterval;  // seconds between each spawn in this entry
	public float DelayBefore;    // seconds to wait before this entry starts
}

/// Defines the content of a single wave.
class WaveDefinition
{
	public int32 WaveNumber;
	public List<WaveEntry> Entries = new .() ~ delete _;

	public this(int32 waveNumber)
	{
		WaveNumber = waveNumber;
	}

	/// Creates the default wave definitions (10 waves, scaling difficulty).
	public static List<WaveDefinition> CreateDefaultWaves()
	{
		let waves = new List<WaveDefinition>();

		// Wave 1: Easy intro - just a few slow UFOs
		let w1 = new WaveDefinition(1);
		w1.Entries.Add(.() { Type = .UfoA, Count = 5, SpawnInterval = 1.5f, DelayBefore = 0 });
		waves.Add(w1);

		// Wave 2: More UFOs, slightly faster spawn
		let w2 = new WaveDefinition(2);
		w2.Entries.Add(.() { Type = .UfoA, Count = 8, SpawnInterval = 1.2f, DelayBefore = 0 });
		waves.Add(w2);

		// Wave 3: Introduce UfoB
		let w3 = new WaveDefinition(3);
		w3.Entries.Add(.() { Type = .UfoA, Count = 5, SpawnInterval = 1.0f, DelayBefore = 0 });
		w3.Entries.Add(.() { Type = .UfoB, Count = 3, SpawnInterval = 1.5f, DelayBefore = 2.0f });
		waves.Add(w3);

		// Wave 4: Mixed A and B
		let w4 = new WaveDefinition(4);
		w4.Entries.Add(.() { Type = .UfoA, Count = 6, SpawnInterval = 0.8f, DelayBefore = 0 });
		w4.Entries.Add(.() { Type = .UfoB, Count = 5, SpawnInterval = 1.0f, DelayBefore = 1.0f });
		waves.Add(w4);

		// Wave 5: Introduce UfoC
		let w5 = new WaveDefinition(5);
		w5.Entries.Add(.() { Type = .UfoB, Count = 6, SpawnInterval = 0.8f, DelayBefore = 0 });
		w5.Entries.Add(.() { Type = .UfoC, Count = 2, SpawnInterval = 2.0f, DelayBefore = 2.0f });
		waves.Add(w5);

		// Wave 6: Swarm
		let w6 = new WaveDefinition(6);
		w6.Entries.Add(.() { Type = .UfoA, Count = 15, SpawnInterval = 0.5f, DelayBefore = 0 });
		waves.Add(w6);

		// Wave 7: Heavy hitters
		let w7 = new WaveDefinition(7);
		w7.Entries.Add(.() { Type = .UfoB, Count = 8, SpawnInterval = 0.8f, DelayBefore = 0 });
		w7.Entries.Add(.() { Type = .UfoC, Count = 4, SpawnInterval = 1.5f, DelayBefore = 1.0f });
		waves.Add(w7);

		// Wave 8: Introduce UfoD
		let w8 = new WaveDefinition(8);
		w8.Entries.Add(.() { Type = .UfoA, Count = 10, SpawnInterval = 0.6f, DelayBefore = 0 });
		w8.Entries.Add(.() { Type = .UfoC, Count = 3, SpawnInterval = 1.2f, DelayBefore = 1.0f });
		w8.Entries.Add(.() { Type = .UfoD, Count = 1, SpawnInterval = 0, DelayBefore = 3.0f });
		waves.Add(w8);

		// Wave 9: Full mix
		let w9 = new WaveDefinition(9);
		w9.Entries.Add(.() { Type = .UfoB, Count = 10, SpawnInterval = 0.6f, DelayBefore = 0 });
		w9.Entries.Add(.() { Type = .UfoC, Count = 5, SpawnInterval = 1.0f, DelayBefore = 0.5f });
		w9.Entries.Add(.() { Type = .UfoD, Count = 2, SpawnInterval = 2.0f, DelayBefore = 2.0f });
		waves.Add(w9);

		// Wave 10: Final boss wave
		let w10 = new WaveDefinition(10);
		w10.Entries.Add(.() { Type = .UfoA, Count = 20, SpawnInterval = 0.3f, DelayBefore = 0 });
		w10.Entries.Add(.() { Type = .UfoC, Count = 6, SpawnInterval = 0.8f, DelayBefore = 0 });
		w10.Entries.Add(.() { Type = .UfoD, Count = 4, SpawnInterval = 1.5f, DelayBefore = 1.0f });
		waves.Add(w10);

		return waves;
	}
}
