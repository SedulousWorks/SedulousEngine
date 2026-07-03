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
/// IViewportInputHandler delivers coords in *layout pixels* of the
/// page tab (e.g. the page is rendered into a 600x400 screen rect).
/// When the page uses a preview resolution (e.g. 1280x720), the
/// runtime UI is laid out at 1280x720 - so a click at layout (300, 200)
/// needs to be scaled to texture (640, 360) before dispatch. The
/// transform is the inverse of VG.DrawImage's stretch.
///
/// Events are gated on `page.IsRunning`: when the game isn't running
/// the runtime UI is empty / partially attached, and forwarding clicks
/// would only fire stale handlers.
///
/// Keyboard / gamepad routing isn't wired here yet - `IViewportInputHandler`
/// only declares mouse callbacks. The editor will need to either capture
/// platform keyboard while the viewport is focused, or extend the viewport
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
		float tx, ty;
		if (!viewport.ScreenToTexture(e.X, e.Y, out tx, out ty)) return;
		mUISubsystem.DispatchMouseDown(e.Button, tx, ty, e.Timestamp);
	}

	public void OnMouseUp(MouseEventArgs e, ViewportView viewport)
	{
		if (!mPage.IsRunning || mUISubsystem == null) return;
		float tx, ty;
		if (!viewport.ScreenToTexture(e.X, e.Y, out tx, out ty)) return;
		mUISubsystem.DispatchMouseUp(e.Button, tx, ty);
	}

	public void OnMouseMove(MouseEventArgs e, ViewportView viewport)
	{
		if (!mPage.IsRunning) return;
		// Feed texture-space coords into the page's mouse adapter so
		// the module's host.Mouse.X/Y reads where the cursor lands in
		// the render target's pixel space (which the module's raycast
		// / tower placement logic operates on). Independent of UI
		// dispatch - even with the UI subsystem disconnected, gameplay
		// code still needs the right coords.
		float tx, ty;
		if (!viewport.ScreenToTexture(e.X, e.Y, out tx, out ty)) return;
		if (mPage.MouseAdapter != null)
			mPage.MouseAdapter.OnViewportPointerMove(tx, ty);
		if (mUISubsystem != null)
			mUISubsystem.DispatchMouseMove(tx, ty);
	}

	public void OnMouseWheel(MouseWheelEventArgs e, ViewportView viewport)
	{
		if (!mPage.IsRunning) return;
		// Feed the page's mouse adapter so the module's host.Mouse
		// reads this wheel delta. Platform IMouse.ScrollY accumulates the
		// wheel anywhere in the window, so passthrough would let
		// scrolling inside the scene editor (or another docked panel)
		// drive the game's camera - the bug we're avoiding here.
		if (mPage.MouseAdapter != null)
			mPage.MouseAdapter.OnViewportPointerWheel(e.DeltaX, e.DeltaY);
		if (mUISubsystem != null)
		{
			float tx, ty;
			if (viewport.ScreenToTexture(e.X, e.Y, out tx, out ty))
				mUISubsystem.DispatchMouseWheel(tx, ty, e.DeltaX, e.DeltaY, e.Modifiers);
		}
	}
}
