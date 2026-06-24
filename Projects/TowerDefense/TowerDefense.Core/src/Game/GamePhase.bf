namespace TowerDefense;

/// Current phase of the game.
public enum GamePhase
{
	/// At main menu screen.
	MainMenu,
	/// In game, waiting for player to start the first wave or next wave.
	WaitingToStart,
	/// A wave is actively spawning enemies / enemies still alive.
	WaveInProgress,
	/// Between waves, all enemies dead, waiting for player to start next.
	WavePaused,
	/// Game paused via P/Escape (overlay shown).
	Paused,
	/// All lives depleted.
	GameOver,
	/// All waves completed.
	Victory
}
