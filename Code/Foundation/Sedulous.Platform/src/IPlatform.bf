using System;
using Sedulous.Platform.Input;

namespace Sedulous.Platform;

/// Main platform interface providing access to windowing and input systems.
public interface IPlatform
{
	/// Gets the window manager.
	IWindowManager WindowManager { get; }

	/// Gets the input manager.
	IInputManager InputManager { get; }

	/// Gets the clipboard.
	IClipboard Clipboard { get; }

	/// Gets the dialog service for native file/folder dialogs.
	IDialogService Dialogs { get; }

	/// Initializes the platform subsystems.
	Result<void> Initialize();

	/// Shuts down the platform subsystems.
	void Shutdown();

	/// Processes pending platform events.
	/// Should be called once per frame.
	void ProcessEvents();

	/// Gets whether the platform is still running.
	bool IsRunning { get; }

	/// Requests the platform to exit.
	void RequestExit();

	/// Opens a URL or file path with the system default handler.
	Result<void> OpenURL(StringView url);

	/// Opens the system file manager and reveals (selects) the given path.
	Result<void> RevealInFileManager(StringView path);
}
