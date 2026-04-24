namespace Sedulous.Tools.ModelViewer;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.UI;
using Sedulous.UI.Viewport;
using Sedulous.Shell.Input;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;

/// Orbit/fly camera controller for the model viewer.
///
/// Controls:
///   LMB drag        - Turntable orbit (rotate around target)
///   Alt + LMB drag  - Turntable orbit (same, for consistency with editor)
///   RMB + drag      - Fly look (yaw + pitch, target follows camera)
///   WASD            - Fly move (while RMB held)
///   E / Space       - Up (while RMB held)
///   Q               - Down (while RMB held)
///   Shift           - 3x speed
///   MMB + drag      - Pan (move target + camera laterally)
///   Scroll wheel    - Zoom (move along forward axis)
class ViewportCameraController
{
	private Scene mScene;
	private EntityHandle mCameraEntity = .Invalid;
	private ViewportView mViewport;
	private IKeyboard mKeyboard;

	// Orbit camera state: position derived from target + distance + yaw + pitch
	private Vector3 mTarget = .Zero;
	private float mDistance = 5.0f;
	private float mYaw = 0;
	private float mPitch = 0.3f;
	private float mMinPitch = -Math.PI_f * 0.49f;
	private float mMaxPitch = Math.PI_f * 0.49f;
	private float mMinDistance = 0.01f;
	private float mMaxDistance = 10000.0f;

	// Speed
	private float mMoveSpeed = 5.0f;
	private float mShiftMultiplier = 3.0f;
	private float mLookSensitivity = 0.005f;

	// Mouse state
	private bool mIsFlying;   // RMB held
	private bool mIsOrbiting; // LMB or Alt+LMB held
	private bool mIsPanning;  // MMB held
	private float mLastMouseX;
	private float mLastMouseY;

	public this(Scene scene, IKeyboard keyboard)
	{
		mScene = scene;
		mKeyboard = keyboard;
		FindCamera();
	}

	/// Wire input delegates on the viewport view.
	public void Attach(ViewportView viewport)
	{
		mViewport = viewport;
		viewport.OnMouseDownHandler = new => OnMouseDown;
		viewport.OnMouseUpHandler = new => OnMouseUp;
		viewport.OnMouseMoveHandler = new => OnMouseMove;
		viewport.OnMouseWheelHandler = new => OnMouseWheel;
	}

	/// Fit the camera to frame a bounding box.
	public void FitToBounds(BoundingBox bounds)
	{
		FindCamera();

		let center = (bounds.Min + bounds.Max) * 0.5f;
		let halfExtents = (bounds.Max - bounds.Min) * 0.5f;
		let idealDistance = halfExtents.Length() * 2.5f;

		// Update camera far plane to accommodate large models
		if (mCameraEntity != .Invalid)
		{
			let camMgr = mScene.GetModule<CameraComponentManager>();
			if (camMgr != null)
			{
				let cam = camMgr.GetActiveCamera();
				if (cam != null)
					cam.FarPlane = Math.Max(cam.FarPlane, idealDistance * 4.0f);
			}
		}

		mTarget = center;
		mDistance = Math.Max(idealDistance, mMinDistance);
		mYaw = 0;
		mPitch = 0.3f;
		mMoveSpeed = Math.Max(5.0f, idealDistance * 0.05f);
		ApplyTransform();
	}

	/// Print current camera state for debugging.
	public void PrintState()
	{
		Console.WriteLine("Camera state:");
		Console.WriteLine("  Target: ({0:F2}, {1:F2}, {2:F2})", mTarget.X, mTarget.Y, mTarget.Z);
		Console.WriteLine("  Distance: {0:F2}", mDistance);
		Console.WriteLine("  Yaw: {0:F4}, Pitch: {1:F4}", mYaw, mPitch);
		Console.WriteLine("  Position: ({0:F2}, {1:F2}, {2:F2})", Position.X, Position.Y, Position.Z);
	}

	/// Call each frame for WASD fly movement.
	public void Update(float deltaTime)
	{
		if (mScene == null || mKeyboard == null) return;
		if (mCameraEntity == .Invalid) FindCamera();

		// WASD movement only while flying (RMB held)
		if (!mIsFlying) return;

		let forward = Forward;
		let right = Right;
		let speed = (mKeyboard.IsKeyDown(.LeftShift) ? mMoveSpeed * mShiftMultiplier : mMoveSpeed) * deltaTime;

		Vector3 move = .Zero;
		if (mKeyboard.IsKeyDown(.W)) move += forward;
		if (mKeyboard.IsKeyDown(.S)) move -= forward;
		if (mKeyboard.IsKeyDown(.D)) move += right;
		if (mKeyboard.IsKeyDown(.A)) move -= right;
		if (mKeyboard.IsKeyDown(.E) || mKeyboard.IsKeyDown(.Space)) move += .(0, 1, 0);
		if (mKeyboard.IsKeyDown(.Q)) move -= .(0, 1, 0);

		if (move.LengthSquared() > 0)
		{
			let delta = Vector3.Normalize(move) * speed;
			mTarget = mTarget + delta;
			ApplyTransform();
		}
	}

	// === Orbit camera math ===

	private Vector3 Position
	{
		get
		{
			let cosP = Math.Cos(mPitch);
			return mTarget + Vector3(
				mDistance * cosP * Math.Sin(mYaw),
				mDistance * Math.Sin(mPitch),
				mDistance * cosP * Math.Cos(mYaw));
		}
	}

	private Vector3 Forward => Vector3.Normalize(mTarget - Position);

	private Vector3 Right
	{
		get
		{
			let fwd = Forward;
			return Vector3.Normalize(Vector3.Cross(fwd, Vector3.Up));
		}
	}

	private void ApplyTransform()
	{
		if (mCameraEntity == .Invalid || mScene == null) return;

		let pos = Position;
		mScene.SetLocalTransform(mCameraEntity, Transform.CreateLookAt(pos, mTarget));
	}

	// === Input handlers ===

	private void SetCapture()
	{
		mViewport?.Context?.FocusManager.SetCapture(mViewport);
	}

	private void ReleaseCapture()
	{
		mViewport?.Context?.FocusManager.ReleaseCapture();
	}

	private void OnMouseDown(MouseEventArgs e)
	{
		if (e.Button == .Right)
		{
			mIsFlying = true;
			mLastMouseX = e.X;
			mLastMouseY = e.Y;
			SetCapture();
			e.Handled = true;
		}
		else if (e.Button == .Left)
		{
			// LMB: turntable orbit (with or without Alt)
			mIsOrbiting = true;
			mLastMouseX = e.X;
			mLastMouseY = e.Y;
			SetCapture();
			e.Handled = true;
		}
		else if (e.Button == .Middle)
		{
			mIsPanning = true;
			mLastMouseX = e.X;
			mLastMouseY = e.Y;
			SetCapture();
			e.Handled = true;
		}
	}

	private void OnMouseUp(MouseEventArgs e)
	{
		if (e.Button == .Right && mIsFlying)
		{
			mIsFlying = false;
			ReleaseCapture();
			e.Handled = true;
		}
		else if (e.Button == .Left && mIsOrbiting)
		{
			mIsOrbiting = false;
			ReleaseCapture();
			e.Handled = true;
		}
		else if (e.Button == .Middle && mIsPanning)
		{
			mIsPanning = false;
			ReleaseCapture();
			e.Handled = true;
		}
	}

	private void OnMouseMove(MouseEventArgs e)
	{
		if (!mIsFlying && !mIsOrbiting && !mIsPanning)
		{
			mLastMouseX = e.X;
			mLastMouseY = e.Y;
			return;
		}

		float deltaX = e.X - mLastMouseX;
		float deltaY = e.Y - mLastMouseY;
		mLastMouseX = e.X;
		mLastMouseY = e.Y;

		if (mIsOrbiting && !mIsFlying)
		{
			// LMB: turntable orbit - rotate around target
			mYaw += deltaX * mLookSensitivity;
			mPitch = Math.Clamp(mPitch - deltaY * mLookSensitivity, mMinPitch, mMaxPitch);
			ApplyTransform();
			e.Handled = true;
		}
		else if (mIsFlying)
		{
			// RMB: free look - rotate in place, target follows camera
			let pos = Position;
			mYaw += deltaX * mLookSensitivity;
			mPitch = Math.Clamp(mPitch - deltaY * mLookSensitivity, mMinPitch, mMaxPitch);
			mTarget = pos + Forward * mDistance;
			ApplyTransform();
			e.Handled = true;
		}
		else if (mIsPanning)
		{
			// MMB: pan - move target + camera laterally
			let right = Right;
			let up = Vector3.Cross(right, Forward);
			let panScale = mDistance * 0.005f;
			mTarget = mTarget + right * (-deltaX * panScale) + up * (deltaY * panScale);
			ApplyTransform();
			e.Handled = true;
		}
	}

	private void OnMouseWheel(MouseWheelEventArgs e)
	{
		// Zoom: adjust distance
		mDistance = Math.Clamp(mDistance - e.DeltaY * mDistance * 0.1f, mMinDistance, mMaxDistance);
		ApplyTransform();
		e.Handled = true;
	}

	// === Init ===

	private void FindCamera()
	{
		if (mScene == null) return;

		let cameraMgr = mScene.GetModule<CameraComponentManager>();
		if (cameraMgr == null) return;

		let camera = cameraMgr.GetActiveCamera();
		if (camera != null)
			mCameraEntity = camera.Owner;
	}
}
