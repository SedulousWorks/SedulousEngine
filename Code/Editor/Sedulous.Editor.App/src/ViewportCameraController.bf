namespace Sedulous.Editor.App;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.UI;
using Sedulous.Shell.Input;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;

/// Orbit/fly camera controller for the editor viewport.
/// Uses delegate-based input from ViewportView.
///
/// Controls:
///   Alt + LMB drag  - Orbit rotate (yaw + pitch around target)
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
	private EntityHandle mCameraEntity;
	private ViewportView mViewport;
	private IKeyboard mKeyboard;

	// Orbit camera state: position derived from target + distance + yaw + pitch
	private Vector3 mTarget = .Zero;
	private float mDistance = 5.0f;
	private float mYaw = Math.PI_f;
	private float mPitch = -0.38f;
	private float mMinPitch = -Math.PI_f * 0.49f;
	private float mMaxPitch = Math.PI_f * 0.49f;
	private float mMinDistance = 0.5f;
	private float mMaxDistance = 500.0f;

	// Speed
	private float mMoveSpeed = 5.0f;
	private float mShiftMultiplier = 3.0f;
	private float mLookSensitivity = 0.005f;

	// Mouse state
	private bool mIsFlying;   // RMB held
	private bool mIsOrbiting; // Alt+LMB held
	private bool mIsPanning;  // MMB held
	private float mLastMouseX;
	private float mLastMouseY;
	private bool mInitialized;

	public this(Scene scene, IKeyboard keyboard)
	{
		mScene = scene;
		mKeyboard = keyboard;
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

	/// Call each frame for WASD fly movement.
	public void Update(float deltaTime)
	{
		if (mScene == null || mKeyboard == null) return;

		// Lazy init - camera component isn't available until after first BeginFrame.
		if (!mInitialized)
		{
			FindCamera();
			if (mCameraEntity != .Invalid)
			{
				InitFromCamera();
				mInitialized = true;
			}
			return;
		}

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
		if (!mInitialized) return;

		if (e.Button == .Right)
		{
			mIsFlying = true;
			mLastMouseX = e.X;
			mLastMouseY = e.Y;
			SetCapture();
			e.Handled = true;
		}
		else if (e.Button == .Left && e.Modifiers.HasFlag(.Alt))
		{
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
			// Alt+LMB: orbit - rotate around target
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
			// Recompute target so camera stays at the same position
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
		if (!mInitialized) return;

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

	private void InitFromCamera()
	{
		if (mCameraEntity == .Invalid || mScene == null) return;

		let worldMat = mScene.GetWorldMatrix(mCameraEntity);
		let pos = worldMat.Translation;

		// Default orbit: look toward origin from initial position
		mTarget = .(0, 0, 0);
		let offset = pos - mTarget;
		mDistance = offset.Length();
		if (mDistance < mMinDistance) mDistance = 5.0f;

		let horizontalDist = Math.Sqrt(offset.X * offset.X + offset.Z * offset.Z);
		mPitch = Math.Clamp((float)Math.Atan2(offset.Y, horizontalDist), mMinPitch, mMaxPitch);
		mYaw = (float)Math.Atan2(offset.X, offset.Z);

		ApplyTransform();
	}
}
