namespace SummonersLeague.Battle;

using System.Collections;

/// Outcome of a completed battle.
enum BattleOutcome
{
	/// Team A (typically player) won.
	TeamAVictory,
	/// Team B (typically enemy) won.
	TeamBVictory,
	/// Battle hit the turn limit without resolution.
	Draw
}

/// Full result of a battle, including turn log.
class BattleResult
{
	public BattleOutcome Outcome;
	public int32 TotalTurns;
	public List<TurnResult> TurnLog = new .() ~ DeleteContainerAndItems!(_);
}
