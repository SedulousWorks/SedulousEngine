using Sedulous.Core;
using Sedulous.Shell;

namespace Samples.Common;

/// The free fly camera every dev sample uses: WASD and QE to move, hold the right button or press
/// Tab to look, Shift to move fast, Alt with the left button to orbit, the middle button to pan
/// and the wheel to dolly.
///
/// It is driven from DEVICES rather than from a window, so passing an input surface's gated
/// keyboard and mouse confines it to one viewport: the camera stops the moment the pointer
/// leaves, with no knowledge of the viewport on its part.
struct FlyCamera
{
	public Float3 Position = .(0.0f, 14.0f, 30.0f);
	/// Zero looks down negative Z.
	public float Yaw = 0.0f;
	public float Pitch = -0.3f;
	public bool MouseCaptured = false;

	public float MoveSpeed = 50.0f;
	public float FastSpeed = 200.0f;
	public float LookSensitivity = 0.003f;
	/// World units per wheel notch.
	public float ZoomSpeed = 3.0f;
	/// How far ahead the orbit pivot sits.
	public float FocusDistance = 20.0f;
	/// Scaled by the focus distance, so a pan feels the same however far out the camera is.
	public float PanSensitivity = 0.0015f;

	public this() {}

	/// Yaw about world up, then pitch about the camera's own right.
	public Quaternion Rotation =>
		Quaternion.FromAxisAngle(.(0.0f, 1.0f, 0.0f), Yaw) *
		Quaternion.FromAxisAngle(.(1.0f, 0.0f, 0.0f), Pitch);

	public Float3 Up => RotateVector(Rotation, .(0.0f, 1.0f, 0.0f));
	public Float3 Forward => RotateVector(Rotation, .(0.0f, 0.0f, -1.0f));
	public Float3 Right => RotateVector(Rotation, .(1.0f, 0.0f, 0.0f));

	/// A frame of input. A null keyboard means the camera is not being driven at all this
	/// frame, which is what a gated surface hands over when the pointer is elsewhere.
	public void Update(IKeyboard keyboard, IMouse mouse, float deltaTime) mut
	{
		if (keyboard == null)
			return;

		if (mouse != null)
			ApplyMouse(keyboard, mouse);

		ApplyMovement(keyboard, deltaTime);
	}

	private void ApplyMouse(IKeyboard keyboard, IMouse mouse) mut
	{
		if (keyboard.IsKeyPressed(.Tab))
		{
			MouseCaptured = !MouseCaptured;
			mouse.SetRelativeMode(MouseCaptured);
			mouse.SetCursorVisible(!MouseCaptured);
		}

		let alt = keyboard.IsKeyDown(.LeftAlt) || keyboard.IsKeyDown(.RightAlt);

		if (alt && mouse.IsButtonDown(.Left))
		{
			// Turntable orbit: the pivot ahead of the camera stays put while the camera swings
			// around it.
			let focus = Position + (Forward * FocusDistance);
			Look(mouse);
			Position = focus - (Forward * FocusDistance);
		}
		else if (MouseCaptured || mouse.IsButtonDown(.Right))
		{
			Look(mouse);
		}

		// The content follows the cursor, so the camera moves the other way.
		if (mouse.IsButtonDown(.Middle))
		{
			let scale = PanSensitivity * FocusDistance;
			Position = Position - (Right * (mouse.DeltaX * scale)) + (Up * (mouse.DeltaY * scale));
		}

		let scroll = mouse.ScrollY;
		if (scroll != 0.0f)
		{
			Position = Position + (Forward * (scroll * ZoomSpeed));
			// The pivot tracks the zoom, or orbiting after a dolly swings around nothing.
			FocusDistance = Max(1.0f, FocusDistance - (scroll * ZoomSpeed));
		}
	}

	private void Look(IMouse mouse) mut
	{
		Yaw -= mouse.DeltaX * LookSensitivity;
		Pitch -= mouse.DeltaY * LookSensitivity;
		// Just shy of straight up or down, because either flips the horizon.
		Pitch = Clamp(Pitch, -1.55f, 1.55f);
	}

	private void ApplyMovement(IKeyboard keyboard, float deltaTime) mut
	{
		let forward = Forward;
		let right = Right;
		let speed = (keyboard.IsKeyDown(.LeftShift) ? FastSpeed : MoveSpeed) * deltaTime;

		Float3 move = .Zero;
		if (keyboard.IsKeyDown(.W))
			move += forward;
		if (keyboard.IsKeyDown(.S))
			move -= forward;
		if (keyboard.IsKeyDown(.D))
			move += right;
		if (keyboard.IsKeyDown(.A))
			move -= right;
		if (keyboard.IsKeyDown(.E))
			move += Float3(0.0f, 1.0f, 0.0f);
		if (keyboard.IsKeyDown(.Q))
			move -= Float3(0.0f, 1.0f, 0.0f);

		// NORMALISED, so moving diagonally is not faster than moving straight.
		if (Dot(move, move) > 0.0f)
			Position += Normalized(move) * speed;
	}
}
