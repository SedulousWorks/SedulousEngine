namespace Sedulous.GUI;

/// Command binding interface (MVVM pattern).
/// Used by ButtonBase to bind click actions with enable/disable state.
public interface ICommand
{
	/// Returns true if the command can currently execute.
	bool CanExecute();

	/// Executes the command.
	void Execute();
}
