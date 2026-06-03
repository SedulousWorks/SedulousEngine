namespace SummonersLeague.Battle;

using System;
using System.Collections;
using SummonersLeague.Data;

/// Current phase of a battle.
enum BattlePhase
{
	Setup,
	InProgress,
	Finished
}

/// Owns the full state of a battle in progress.
class BattleState
{
	/// Team A monsters (typically player).
	public List<MonsterInstance> TeamA = new .() ~ DeleteContainerAndItems!(_);

	/// Team B monsters (typically enemy/AI).
	public List<MonsterInstance> TeamB = new .() ~ DeleteContainerAndItems!(_);

	/// Current battle phase.
	public BattlePhase Phase = .Setup;

	/// Current turn number (increments each time a monster acts).
	public int32 TurnNumber;

	/// Maximum turns before draw (prevents infinite battles).
	public int32 MaxTurns = 200;

	/// Add a monster to team A. Creates a MonsterInstance from def + level.
	public MonsterInstance AddToTeamA(MonsterDef def, int32 level)
	{
		let instance = new MonsterInstance();
		instance.Initialize(def, level);
		instance.TeamIndex = 0;
		instance.SlotIndex = (int32)TeamA.Count;
		TeamA.Add(instance);
		return instance;
	}

	/// Add a monster to team B. Creates a MonsterInstance from def + level.
	public MonsterInstance AddToTeamB(MonsterDef def, int32 level)
	{
		let instance = new MonsterInstance();
		instance.Initialize(def, level);
		instance.TeamIndex = 1;
		instance.SlotIndex = (int32)TeamB.Count;
		TeamB.Add(instance);
		return instance;
	}

	/// Get the opposing team for a monster.
	public List<MonsterInstance> GetOpposingTeam(MonsterInstance monster)
	{
		return (monster.TeamIndex == 0) ? TeamB : TeamA;
	}

	/// Get the allied team for a monster.
	public List<MonsterInstance> GetAlliedTeam(MonsterInstance monster)
	{
		return (monster.TeamIndex == 0) ? TeamA : TeamB;
	}

	/// Get alive monsters on a team.
	public void GetAlive(List<MonsterInstance> team, List<MonsterInstance> result)
	{
		result.Clear();
		for (let m in team)
			if (m.IsAlive) result.Add(m);
	}

	/// Check if a team is fully wiped.
	public bool IsTeamDefeated(List<MonsterInstance> team)
	{
		for (let m in team)
			if (m.IsAlive) return false;
		return true;
	}

	/// Check if the battle is over. Updates Phase if so.
	public BattleOutcome? CheckWinCondition()
	{
		if (IsTeamDefeated(TeamA))
		{
			Phase = .Finished;
			return .TeamBVictory;
		}
		if (IsTeamDefeated(TeamB))
		{
			Phase = .Finished;
			return .TeamAVictory;
		}
		if (TurnNumber >= MaxTurns)
		{
			Phase = .Finished;
			return .Draw;
		}
		return null;
	}
}
