using System;
using Sedulous.Core;

namespace Sedulous.GUI;

/// Interface for commands that can be executed and have enabled state.
/// Commands decouple UI controls from the actions they trigger.
public interface GUICommand
{
	/// Executes the command with an optional parameter.
	void Execute(Object parameter = null);

	/// Returns whether the command can currently be executed.
	bool CanExecute(Object parameter = null);

	/// Event raised when CanExecute may have changed.
	/// Controls should re-query CanExecute when this fires.
	EventAccessor<delegate void()> CanExecuteChanged { get; }

	/// Raises the CanExecuteChanged event.
	/// Call this when conditions affecting CanExecute have changed.
	void RaiseCanExecuteChanged();
}
