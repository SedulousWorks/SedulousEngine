namespace Sedulous.Editor;

using Sedulous.UI;
using Sedulous.UI.Viewport;
using Sedulous.Engine.UI;
using Sedulous.Editor.Core;

/// Forwards mouse events the editor dispatches into a GameEditorPage's
/// viewport into the runtime context's EngineUISubsystem via its
/// Dispatch* methods. The subsystem routes through the same priority
/// chain (screen UI -> scene HUDs -> billboards) that standalone uses,
/// so anything the game's module attached lights up - not just the
/// screen view.
///
/// Coordinates from the viewport input handler are already viewport-
/// local pixels, which is what the screen view lays out against - no
/// transform needed. Events are gated on `page.IsRunning`: when the
/// game isn't running the runtime UI is empty / partially attached,
/// and forwarding clicks would only fire stale handlers.
///
/// Keyboard / gamepad routing isn't wired here yet - `IViewportInputHandler`
/// only declares mouse callbacks. The editor will need to either capture
/// shell keyboard while the viewport is focused, or extend the viewport
/// input interface, before TD's keyboard shortcuts (Space to start wave,
/// P to pause, etc.) become reachable inside the page.
class GameInputHandler : IViewportInputHandler
{
	private GameEditorPage mPage;
	private EngineUISubsystem mUISubsystem;

	public this(GameEditorPage page, EngineUISubsystem uiSubsystem)
	{
		mPage = page;
		mUISubsystem = uiSubsystem;
	}

	public void OnMouseDown(MouseEventArgs e, ViewportView viewport)
	{
		if (!mPage.IsRunning || mUISubsystem == null) return;
		mUISubsystem.DispatchMouseDown(e.Button, e.X, e.Y, e.Timestamp);
	}

	public void OnMouseUp(MouseEventArgs e, ViewportView viewport)
	{
		if (!mPage.IsRunning || mUISubsystem == null) return;
		mUISubsystem.DispatchMouseUp(e.Button, e.X, e.Y);
	}

	public void OnMouseMove(MouseEventArgs e, ViewportView viewport)
	{
		if (!mPage.IsRunning || mUISubsystem == null) return;
		mUISubsystem.DispatchMouseMove(e.X, e.Y);
	}

	public void OnMouseWheel(MouseWheelEventArgs e, ViewportView viewport)
	{
		if (!mPage.IsRunning || mUISubsystem == null) return;
		mUISubsystem.DispatchMouseWheel(e.X, e.Y, e.DeltaX, e.DeltaY, e.Modifiers);
	}
}
