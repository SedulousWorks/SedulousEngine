using System;
using Sedulous.Shell.Input;

namespace Sedulous.Shell;

/// Main shell interface providing access to windowing and input systems.
public interface IShell
{
	/// Gets the window manager.
	IWindowManager WindowManager { get; }

	/// Gets the input manager.
	IInputManager InputManager { get; }

	/// Gets the clipboard.
	IClipboard Clipboard { get; }

	/// Gets the dialog service for native file/folder dialogs.
	IDialogService Dialogs { get; }

	/// Initializes the shell subsystems.
	Result<void> Initialize();

	/// Shuts down the shell subsystems.
	void Shutdown();

	/// Processes pending platform events.
	/// Should be called once per frame.
	void ProcessEvents();

	/// Gets whether the shell is still running.
	bool IsRunning { get; }

	/// Requests the shell to exit.
	void RequestExit();
}
