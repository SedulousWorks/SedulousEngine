using System;
using Sedulous.Engine.Run;
using Sedulous.Input;
using Sedulous.Shell;

namespace Sedulous.Engine.Run.Tests;

/// A mouse that records the lock asked of it, and no other device.
class LockMouseSource : IInputSourceProvider
{
	public class LockMouse : IMouse
	{
		public bool Relative = false;
		public bool Visible = true;

		public float X => 0.0f;
		public float Y => 0.0f;
		public float GlobalX => 0.0f;
		public float GlobalY => 0.0f;
		public float DeltaX => 0.0f;
		public float DeltaY => 0.0f;
		public float ScrollX => 0.0f;
		public float ScrollY => 0.0f;
		public bool IsButtonDown(MouseButton button) => false;
		public bool IsButtonPressed(MouseButton button) => false;
		public bool IsButtonReleased(MouseButton button) => false;
		public bool RelativeMode => Relative;
		public void SetRelativeMode(bool enabled) => Relative = enabled;
		public bool CursorVisible => Visible;
		public void SetCursorVisible(bool visible) => Visible = visible;
		public void SetCursor(CursorType cursor) {}
		public void SetGlobalCapture(bool enabled) {}
	}

	public LockMouse Locking = new .() ~ delete _;

	public IKeyboard Keyboard => null;
	public IMouse Mouse => Locking;
	public int32 GamepadCount => 0;
	public IGamepad GetGamepad(int32 index) => null;
}

/// A run's end frees a pointer its game locked.
class PointerLockRunTests
{
	/// A run ends through StopRunBehavior (the player's and the editor's stop, and a restart), the path
	/// that stops its pads too.
	[Test]
	public static void ARunsEndFreesAPointerItsGameLocked()
	{
		let instance = scope ApplicationRun();
		let source = scope LockMouseSource();
		instance.SetInputSource(source);
		instance.InputRuntime.SetPointerLock(true); // as Input.LockPointer asks it
		instance.DriveInput(0.016f, 1.0f);
		Test.Assert(source.Locking.Relative);
		Test.Assert(!source.Locking.Visible);

		instance.StopRunBehavior();
		Test.Assert(!source.Locking.Relative);
		Test.Assert(source.Locking.Visible);
		Test.Assert(!instance.InputRuntime.PointerLockApplied, "the next run starts unlocked");

		// A run that never locked leaves a pointer someone else holds alone (an editor viewport's).
		source.Locking.Relative = true;
		instance.DriveInput(0.016f, 1.0f);
		instance.StopRunBehavior();
		Test.Assert(source.Locking.Relative);
	}
}
