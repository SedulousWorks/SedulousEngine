namespace SummonersLeague.Battle;

using System;
using System.Collections;

/// SPD-based turn order system. Each monster's turn bar fills based on
/// their SPD stat. When a bar reaches 100, that monster acts.
static class TurnBar
{
	public const float Threshold = 100.0f;

	/// Tick all monsters' turn bars by their SPD. Returns the monster that
	/// should act next (first to reach threshold, ties broken by highest SPD).
	/// Returns null if no monster reached the threshold (shouldn't happen in practice).
	public static MonsterInstance Tick(List<MonsterInstance> allMonsters)
	{
		// Keep ticking until someone reaches the threshold
		for (int safety = 0; safety < 1000; safety++)
		{
			MonsterInstance ready = null;
			float highestBar = 0;

			for (let m in allMonsters)
			{
				if (!m.IsAlive) continue;

				m.TurnBar += (float)m.SPD;

				if (m.TurnBar >= Threshold && (ready == null || m.TurnBar > highestBar ||
					(m.TurnBar == highestBar && m.SPD > ready.SPD)))
				{
					ready = m;
					highestBar = m.TurnBar;
				}
			}

			if (ready != null)
			{
				ready.TurnBar -= Threshold;
				return ready;
			}
		}

		return null; // Safety fallback
	}
}
