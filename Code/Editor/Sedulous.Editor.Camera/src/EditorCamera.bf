using System;
using Sedulous.Core;
using Sedulous.Shell;

namespace Sedulous.Editor.Camera;

/// The scene page's fly camera, one per page: a position with yaw and pitch, so the horizon
/// stays level. Right mouse, or Tab captured, flies with WASD and QE, Shift fast; Alt with
/// the left button orbits the pivot ahead at FocusDistance; the middle button pans; the
/// wheel zooms toward the pivot. W belongs to the gizmo shortcuts when not flying.
class EditorCamera
{
	/// How far the look tilts, radians: short of straight up or down, so the up vector stays
	/// defined. The mouse look and a scripted pose both keep to it.
	public const float cPitchLimit = 1.55f;

	public Float3 Position = .(6.0f, 5.0f, 10.0f);
	/// 0 looks down -Z; the defaults aim at the origin.
	public float Yaw = 0.54f;
	public float Pitch = -0.41f;
	public bool MouseCaptured = false;
	public float MoveSpeed = 8.0f;
	public float FastSpeed = 30.0f;
	public float LookSensitivity = 0.003f;
	/// The fraction of the pivot distance per wheel notch.
	public float ZoomFraction = 0.12f;
	/// The pivot distance ahead, the Alt+LMB turntable's centre.
	public float FocusDistance = 12.0f;
	public float PanSensitivity = 0.0015f;
	/// The last Update dollied on the wheel, for the scene view's zoom readout. Turning,
	/// panning and a wheel a tool owns leave it clear.
	public bool ZoomedThisUpdate = false;
	/// A frame eases over this long; nought jumps.
	public float GlideSeconds = 0.3f;

	private bool mGliding = false;
	private float mGlideElapsed = 0.0f;
	private Float3 mGlideFrom = .Zero;
	private Float3 mGlideTo = .Zero;
	private float mGlideFromFocus = 0.0f;
	private float mGlideToFocus = 0.0f;

	public Quaternion Rotation => Quaternion.FromAxisAngle(.(0.0f, 1.0f, 0.0f), Yaw) * Quaternion.FromAxisAngle(.(1.0f, 0.0f, 0.0f), Pitch);
	public Float3 Forward => RotateVector(Rotation, Float3(0.0f, 0.0f, -1.0f));
	public Float3 Right => RotateVector(Rotation, Float3(1.0f, 0.0f, 0.0f));
	public Float3 Up => RotateVector(Rotation, Float3(0.0f, 1.0f, 0.0f));

	/// Aims Forward at `target` with a level horizon; the target becomes the pivot.
	public void LookAt(Float3 target)
	{
		let delta = target - Position;
		let length = Length(delta);
		if (length < 0.0001f)
			return;
		let dir = delta * (1.0f / length);
		Pitch = Math.Asin(Math.Clamp(dir.Y, -1.0f, 1.0f));
		Yaw = Math.Atan2(-dir.X, -dir.Z);
		FocusDistance = length;
	}

	/// Backs off to see a bounding sphere whole and aims at its centre; a tiny radius is
	/// floored so degenerate content still frames.
	public void FrameBounds(Float3 center, float radius)
	{
		let r = Math.Max(0.25f, radius);
		Position = center + Float3(0.0f, 0.4f, 1.0f) * (r * 2.6f);
		LookAt(center);
	}

	/// Frames a sphere in a view of vertical field of view `fovY` (radians): keeps the view
	/// direction, stands back far enough that the sphere fits with a margin, and puts the orbit
	/// pivot on its centre, so Alt+drag orbits it afterwards. Eases there over GlideSeconds when
	/// `ease` (Advance moves the glide on); any input that moves the camera stops the glide where
	/// it is. The scene view's frame the selection.
	public void FrameSphere(Float3 center, float radius, float fovY, bool ease = true)
	{
		let r = Math.Max(0.25f, radius);
		let distance = 1.1f * r / Math.Max(0.05f, Math.Sin(0.5f * fovY));
		let target = center - Forward * distance;
		if (!ease || (GlideSeconds <= 0.0f))
		{
			Position = target;
			FocusDistance = distance;
			mGliding = false;
			return;
		}
		mGlideFrom = Position;
		mGlideFromFocus = FocusDistance;
		mGlideTo = target;
		mGlideToFocus = distance;
		mGlideElapsed = 0.0f;
		mGliding = true;
	}

	/// Moves a FrameSphere glide on by `dt`, eased in and out; a no-op when none runs. Called
	/// every frame whether or not the viewport has the input, so a frame from the hierarchy
	/// glides while the mouse is over the hierarchy.
	public void Advance(float dt)
	{
		if (!mGliding)
			return;
		mGlideElapsed += dt;
		var t = Math.Clamp(mGlideElapsed / GlideSeconds, 0.0f, 1.0f);
		let done = t >= 1.0f;
		t = t * t * (3.0f - 2.0f * t);
		Position = mGlideFrom + (mGlideTo - mGlideFrom) * t;
		FocusDistance = mGlideFromFocus + (mGlideToFocus - mGlideFromFocus) * t;
		mGliding = !done;
	}

	public bool IsGliding => mGliding;

	public void ReleaseCapture(IMouse mouse)
	{
		if (!MouseCaptured)
			return;
		MouseCaptured = false;
		if (mouse != null)
		{
			mouse.SetRelativeMode(false);
			mouse.SetCursorVisible(true);
		}
	}

	/// `allowZoom` goes false while a modal viewport tool owns the scroll, a brush resizing
	/// on SHIFT and the wheel: the first consumer rule keeps that same scroll from dollying
	/// the camera as well. The bare wheel stays the camera's, brush or no brush.
	public void Update(IKeyboard keyboard, IMouse mouse, float dt, bool allowZoom = true)
	{
		ZoomedThisUpdate = false;
		if (keyboard == null)
			return;
		if (mouse != null)
		{
			if (keyboard.IsKeyPressed(.Tab))
			{
				MouseCaptured = !MouseCaptured;
				mouse.SetRelativeMode(MouseCaptured);
				mouse.SetCursorVisible(!MouseCaptured);
			}
			if (MouseCaptured && keyboard.IsKeyPressed(.Escape))
				ReleaseCapture(mouse);
			let alt = keyboard.IsKeyDown(.LeftAlt) || keyboard.IsKeyDown(.RightAlt);
			if (alt && mouse.IsButtonDown(.Left))
			{
				// The turntable: orbit the pivot ahead.
				mGliding = false; // the user takes the camera
				let focus = Position + Forward * FocusDistance;
				Yaw -= mouse.DeltaX * LookSensitivity;
				Pitch -= mouse.DeltaY * LookSensitivity;
				Pitch = Math.Clamp(Pitch, -cPitchLimit, cPitchLimit);
				Position = focus - Forward * FocusDistance;
			}
			else if (MouseCaptured || mouse.IsButtonDown(.Right))
			{
				mGliding = false;
				Yaw -= mouse.DeltaX * LookSensitivity;
				Pitch -= mouse.DeltaY * LookSensitivity;
				Pitch = Math.Clamp(Pitch, -cPitchLimit, cPitchLimit);
			}
			if (mouse.IsButtonDown(.Middle))
			{
				mGliding = false;
				let s = PanSensitivity * FocusDistance;
				Position = Position - Right * (mouse.DeltaX * s) + Up * (mouse.DeltaY * s);
			}
			let scroll = allowZoom ? mouse.ScrollY : 0.0f;
			if (scroll != 0.0f)
			{
				mGliding = false;
				let focus = Position + Forward * FocusDistance;
				let factor = Math.Clamp(1.0f - ZoomFraction * scroll, 0.2f, 5.0f);
				FocusDistance = Math.Max(0.05f, FocusDistance * factor);
				Position = focus - Forward * FocusDistance;
				ZoomedThisUpdate = true;
			}
		}
		let flying = MouseCaptured || ((mouse != null) && mouse.IsButtonDown(.Right));
		if (!flying)
			return;
		let forward = Forward;
		let right = Right;
		let speed = (keyboard.IsKeyDown(.LeftShift) ? FastSpeed : MoveSpeed) * dt;
		var move = Float3.Zero;
		if (keyboard.IsKeyDown(.W))
			move = move + forward;
		if (keyboard.IsKeyDown(.S))
			move = move - forward;
		if (keyboard.IsKeyDown(.D))
			move = move + right;
		if (keyboard.IsKeyDown(.A))
			move = move - right;
		if (keyboard.IsKeyDown(.E))
			move = move + Float3(0.0f, 1.0f, 0.0f);
		if (keyboard.IsKeyDown(.Q))
			move = move - Float3(0.0f, 1.0f, 0.0f);
		if (Dot(move, move) > 0.0f)
			Position = Position + Normalized(move) * speed;
	}
}
