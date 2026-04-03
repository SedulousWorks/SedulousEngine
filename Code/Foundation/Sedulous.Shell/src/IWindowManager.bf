using System;
using Sedulous.Core;

namespace Sedulous.Shell;

/// Manages window creation and lifecycle.
public interface IWindowManager
{
	/// Creates a new window with the specified settings.
	Result<IWindow> CreateWindow(WindowSettings settings);

	/// Destroys a window.
	void DestroyWindow(IWindow window);

	/// Gets a window by its ID.
	IWindow GetWindow(uint32 id);

	/// Gets the number of active windows.
	int WindowCount { get; }

	/// Called when a window event occurs.
	EventAccessor<WindowEventDelegate> OnWindowEvent { get; }
}
