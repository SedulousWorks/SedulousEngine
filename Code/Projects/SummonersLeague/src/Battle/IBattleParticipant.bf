namespace SummonersLeague.Battle;

/// Interface for anything that controls a team's decisions during battle.
/// The battle runner asks the participant to choose an action when one of
/// its monsters' turn comes up. Implementations can be AI, player input,
/// remote network player, or automated test bots.
interface IBattleParticipant
{
	/// Choose an action for the given monster. The actor is guaranteed to be
	/// alive and not incapacitated. The implementation must return a valid
	/// ability index and target list.
	BattleAction ChooseAction(MonsterInstance actor, BattleState state);
}
