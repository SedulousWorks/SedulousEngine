namespace Sedulous.Engine.App;

using Sedulous.Core;
using Sedulous.Core.Mathematics;
using Sedulous.Platform.Input;

/// IMouse adapter that wraps the platform mouse and applies a window-pixel
/// -> canvas-pixel transform to `X` / `Y` on every read. Standalone
/// EngineApplication uses this for `IApplicationHost.Mouse` so module
/// code (raycasts, tower placement, custom hit-tests) consumes
/// coordinates in the same pixel grid the scene is rendered into,
/// regardless of how the swapchain blit letterboxes / crops / stretches.
///
/// The transform is a delegate (not a snapshot) so the adapter stays
/// correct after window resizes, fit-mode changes, or target-resolution
/// switches without needing to be torn down and rebuilt. Pass null to
/// fall back to identity (raw window pixels).
///
/// Mirrors the editor's `GameMouseAdapter` pattern - that one stores
/// viewport-local coords pushed in from an event handler; this one
/// computes them on demand from the active transform. Both produce the
/// same downstream contract: `host.Mouse.X/Y` reads in target-canvas
/// pixels.
///
/// Buttons / scroll / events passthrough to the platform mouse - only
/// position is remapped. RelativeMode + cursor visibility passthrough
/// so platform behavior stays consistent.
class EngineCanvasMouseAdapter : IMouse
{
	private IMouse mPlatform;
	private delegate Vector2(Vector2) mWindowToCanvas;

	public this(IMouse platform)
	{
		mPlatform = platform;
	}

	/// Replace the window-pixel -> canvas-pixel transform. Owned by
	/// the adapter; the previous delegate (if any) is freed. Pass null
	/// to clear (X / Y revert to passthrough).
	public void SetWindowToCanvas(delegate Vector2(Vector2) value)
	{
		if (mWindowToCanvas != null) delete mWindowToCanvas;
		mWindowToCanvas = value;
	}

	public ~this()
	{
		if (mWindowToCanvas != null) delete mWindowToCanvas;
	}

	private Vector2 Transformed
	{
		get
		{
			if (mPlatform == null) return .Zero;
			let raw = Vector2(mPlatform.X, mPlatform.Y);
			if (mWindowToCanvas == null) return raw;
			return mWindowToCanvas(raw);
		}
	}

	public float X => Transformed.X;
	public float Y => Transformed.Y;
	public float GlobalX => mPlatform?.GlobalX ?? 0;
	public float GlobalY => mPlatform?.GlobalY ?? 0;
	public float DeltaX => mPlatform?.DeltaX ?? 0;
	public float DeltaY => mPlatform?.DeltaY ?? 0;
	public Sedulous.Platform.IWindow MouseHoverWindow => mPlatform?.MouseHoverWindow;
	public float ScrollX => mPlatform?.ScrollX ?? 0;
	public float ScrollY => mPlatform?.ScrollY ?? 0;

	public bool IsButtonDown(MouseButton button) =>
		(mPlatform?.IsButtonDown(button)) ?? false;
	public bool IsButtonPressed(MouseButton button) =>
		(mPlatform?.IsButtonPressed(button)) ?? false;
	public bool IsButtonReleased(MouseButton button) =>
		(mPlatform?.IsButtonReleased(button)) ?? false;

	public bool RelativeMode
	{
		get => mPlatform?.RelativeMode ?? false;
		set { if (mPlatform != null) mPlatform.RelativeMode = value; }
	}

	public bool Visible
	{
		get => mPlatform?.Visible ?? true;
		set { if (mPlatform != null) mPlatform.Visible = value; }
	}

	public CursorType Cursor
	{
		get => mPlatform?.Cursor ?? .Default;
		set { if (mPlatform != null) mPlatform.Cursor = value; }
	}

	public EventAccessor<MouseMoveDelegate> OnMove => mPlatform?.OnMove;
	public EventAccessor<MouseButtonDelegate> OnButton => mPlatform?.OnButton;
	public EventAccessor<MouseScrollDelegate> OnScroll => mPlatform?.OnScroll;
}
