namespace SummonersLeague.Battle;

using System;
using System.Collections;

/// Orchestrates the battle loop. Completely agnostic about who controls
/// each side — delegates all decisions to IBattleParticipant implementations.
class BattleRunner
{
	/// Run a battle to completion. Returns the full result with turn log.
	public static BattleResult RunBattle(BattleState state,
		IBattleParticipant participantA, IBattleParticipant participantB)
	{
		let result = new BattleResult();
		state.Phase = .InProgress;

		// Combine all monsters into one list for turn bar ticking
		let allMonsters = scope List<MonsterInstance>();
		for (let m in state.TeamA) allMonsters.Add(m);
		for (let m in state.TeamB) allMonsters.Add(m);

		while (state.Phase == .InProgress)
		{
			// Tick turn bars until someone is ready to act
			let actor = TurnBar.Tick(allMonsters);
			if (actor == null) break; // Safety

			state.TurnNumber++;

			// Determine which participant controls this monster
			let participant = (actor.TeamIndex == 0) ? participantA : participantB;

			// Execute turn — AbilityExecutor handles status ticks, stun checks,
			// and DoT deaths internally before the ability resolves.
			TurnResult turnResult;
			if (actor.IsIncapacitated)
			{
				let emptyTargets = new MonsterInstance[0];
				turnResult = AbilityExecutor.Execute(actor, 0, emptyTargets, state);
				delete emptyTargets;
			}
			else
			{
				// Ask participant for an action
				let action = participant.ChooseAction(actor, state);
				turnResult = AbilityExecutor.Execute(actor, action.AbilityIndex, action.Targets, state);
				delete action.Targets;
			}

			result.TurnLog.Add(turnResult);

			// Check win condition
			if (let outcome = state.CheckWinCondition())
			{
				result.Outcome = outcome;
				break;
			}
		}

		result.TotalTurns = state.TurnNumber;
		return result;
	}

	/// Print a battle result to the console for debugging.
	public static void PrintBattleLog(BattleResult result)
	{
		Console.WriteLine("=== BATTLE LOG ===\n");

		for (let turn in result.TurnLog)
		{
			let actorName = turn.Actor.Def.Name;
			let teamStr = (turn.Actor.TeamIndex == 0) ? "A" : "B";

			Console.Write(scope $"Turn {turn.TurnNumber}: [{teamStr}] {actorName}");

			// Status ticks
			for (let tick in turn.StatusTicks)
			{
				switch (tick.Type)
				{
				case .Poison: Console.Write(scope $" [Poison: -{tick.Value} HP]");
				case .Burn: Console.Write(scope $" [Burn: -{tick.Value} HP]");
				case .ContinuousHeal: Console.Write(scope $" [Heal: +{tick.Value} HP]");
				default:
				}
			}

			if (turn.DiedFromDoT)
			{
				Console.WriteLine(" - DIED from DoT!");
				continue;
			}

			if (turn.WasStunned)
			{
				Console.WriteLine(" - SKIPPED (stunned/frozen)");
				continue;
			}

			if (turn.Ability != null)
				Console.Write(scope $" uses {turn.Ability.Name}");

			Console.WriteLine();

			for (let hit in turn.Hits)
			{
				let targetName = hit.Target.Def.Name;
				let targetTeam = (hit.Target.TeamIndex == 0) ? "A" : "B";

				if (hit.WasDodged)
				{
					Console.WriteLine(scope $"  -> [{targetTeam}] {targetName}: DODGED");
					continue;
				}

				if (hit.Damage > 0)
				{
					let critStr = hit.WasCrit ? " CRIT!" : "";
					let typeStr = (hit.TypeMultiplier > 1.0f) ? " (super effective)" :
						(hit.TypeMultiplier < 1.0f) ? " (resisted)" : "";
					Console.Write(scope $"  -> [{targetTeam}] {targetName}: {hit.Damage} damage{critStr}{typeStr}");

					if (hit.TargetKO)
						Console.Write(" - KO!");
					Console.WriteLine();
				}

				if (hit.Healed > 0)
					Console.WriteLine(scope $"  -> [{targetTeam}] {targetName}: healed {hit.Healed} HP");

				if (hit.StatusLanded)
					Console.WriteLine(scope $"  -> [{targetTeam}] {targetName}: inflicted {hit.AppliedStatus}");
			}
		}

		Console.WriteLine();
		let outcomeStr = (result.Outcome == .TeamAVictory) ? "Team A WINS!" :
			(result.Outcome == .TeamBVictory) ? "Team B WINS!" : "DRAW!";
		Console.WriteLine(scope $"Result: {outcomeStr} ({result.TotalTurns} turns)");
		Console.WriteLine("==================\n");
	}
}
