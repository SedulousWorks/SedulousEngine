namespace Sedulous.UI;

/// A bindable command, for the MVVM style of wiring a control to an action.
///
/// ButtonBase.Command runs this on click when CanExecute allows it. Held by reference and
/// implemented outside the view tree, by the application's own command objects.
interface ICommand
{
	bool CanExecute();
	void Execute();
}
