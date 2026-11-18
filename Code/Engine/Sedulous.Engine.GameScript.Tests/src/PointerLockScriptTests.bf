using System;
using Sedulous.Input;
using Sedulous.Shell;
using Sedulous.Engine.GameInstance;

namespace Sedulous.Engine.GameScript.Tests;

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

/// `Input.LockPointer` to a game script: the lock reaches the calling run's own mouse at its next
/// input drive, reads back once granted, and frees with false; the run's end frees it too.
class PointerLockScriptTests
{
	[Test]
	public static void AScriptLocksItsOwnRunsPointerReadsTheLockAndFreesIt()
	{
		const String cLooker = """
			class Game
			{
				int step = 0;
				bool lockedAsked = true;
				bool lockedHeld = false;
				void launch() {}
				void update(float dt)
				{
					step++;
					if (step == 1) { Input.LockPointer(true); lockedAsked = Input.PointerLocked(); }
					if (step == 2) { lockedHeld = Input.PointerLocked(); Input.LockPointer(false); }
					if (step == 3) { Input.LockPointer(true); }
				}
			}
			""";
		let runA = scope GameRun("scratch_game_pointer_lock_a");
		let runB = scope GameRun("scratch_game_pointer_lock_b");
		let sourceA = scope LockMouseSource();
		let sourceB = scope LockMouseSource();
		runA.Instance.SetInputSource(sourceA);
		runB.Instance.SetInputSource(sourceB);
		Test.Assert(runA.Instance.StartScript(runA.Class("Game", cLooker)), scope String(runA.Instance.ScriptFault));

		// Asked in the update, not yet applied; the next input drive locks the run's own mouse.
		runA.Step();
		Test.Assert(!runA.PropBool("lockedAsked"), "asked, not yet applied");
		runA.Instance.DriveInput(1.0f / 60.0f, 1.0f);
		runB.Instance.DriveInput(1.0f / 60.0f, 1.0f);
		Test.Assert(sourceA.Locking.Relative);
		Test.Assert(!sourceA.Locking.Visible);
		Test.Assert(!sourceB.Locking.Relative, "another run's pointer is not touched");

		// Read back once granted, then freed.
		runA.Step();
		Test.Assert(runA.PropBool("lockedHeld"));
		runA.Instance.DriveInput(1.0f / 60.0f, 1.0f);
		Test.Assert(!sourceA.Locking.Relative);
		Test.Assert(sourceA.Locking.Visible);

		// Locked at the run's end: stopping the script frees it at once.
		runA.Step();
		runA.Instance.DriveInput(1.0f / 60.0f, 1.0f);
		Test.Assert(sourceA.Locking.Relative);
		runA.Instance.StopScript();
		Test.Assert(!sourceA.Locking.Relative);
		Test.Assert(sourceA.Locking.Visible);
	}
}
