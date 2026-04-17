namespace Sedulous.UI;

/// Command interface for MVVM-style command binding on controls.
/// Button.Command executes this when clicked if CanExecute returns true.
public interface ICommand
{
	/// Whether the command can currently execute.
	bool CanExecute();

	/// Execute the command.
	void Execute();
}
