using System;
using Sedulous.Core;

namespace Sedulous.Shell;

/// Owns the windows of one shell run.
///
/// Destruction is DEFERRED: DestroyWindow marks a window closed and FlushDestroyed, called
/// at frame end once the GPU is done with it, actually frees it. So a window is never torn
/// down mid frame, which is what makes closing one from inside a frame safe.
interface IWindowManager
{
	Result<IWindow, ErrorCode> CreateWindow(WindowSettings settings);

	/// Marks a window for destruction at the next flush. Safe mid frame, and does nothing
	/// for a window it does not know.
	void DestroyWindow(IWindow window);

	/// Every live window, in creation order. A window marked for destruction is still here
	/// until the flush.
	Span<IWindow> Windows { get; }

	/// The FIRST window created, tracked by identity. Null once destroyed, and never
	/// reassigned to another window: closing the main window is not masked by other windows
	/// still being open.
	IWindow MainWindow { get; }

	IWindow GetWindow(uint32 id);

	/// Events from the last pump, valid until the next one.
	Span<WindowEvent> Events { get; }

	/// Frees what DestroyWindow marked. Once a frame, at the end.
	void FlushDestroyed();
}
