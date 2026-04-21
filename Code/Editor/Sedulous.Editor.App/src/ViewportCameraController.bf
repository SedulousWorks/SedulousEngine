namespace Sedulous.Editor.App;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.UI;
using Sedulous.Shell.Input;
using Sedulous.Scenes;
using Sedulous.Engine.Render;

/// Fly camera controller for the editor viewport.
/// Uses delegate-based input from ViewportView.
/// Controls match EngineSandbox:
///   RMB held + mouse — look (yaw/pitch)
///   WASD             — move (while RMB held)
///   E / Space        — up (while RMB held)
///   Q / LeftCtrl     — down (while RMB held)
///   Shift            — 3x speed
///   Scroll wheel     — move forward/back
class ViewportCameraController
{
	private Scene mScene;
	private EntityHandle mCameraEntity;
	private ViewportView mViewport;
	private IKeyboard mKeyboard;

	// Camera state
	private Vector3 mPosition = .(0, 2, 5);
	private float mYaw = 0;
	private float mPitch = 0;
	private float mMoveSpeed = 5.0f;
	private float mShiftMultiplier = 3.0f;
	private float mLookSensitivity = 0.005f;

	// Mouse state
	private bool mIsLooking; // RMB held
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

	/// Call each frame for WASD movement.
	public void Update(float deltaTime)
	{
		if (mScene == null || mKeyboard == null) return;

		// Lazy init — camera component isn't available until after first BeginFrame.
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

		if (!mIsLooking) return;

		let cosP = Math.Cos(mPitch);
		let forward = Vector3(cosP * Math.Sin(mYaw), Math.Sin(mPitch), cosP * Math.Cos(mYaw));
		let right = Vector3.Normalize(Vector3.Cross(forward, .(0, 1, 0)));
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
			mPosition += Vector3.Normalize(move) * speed;
			ApplyTransform();
		}
	}

	// === Input handlers ===

	private void OnMouseDown(MouseEventArgs e)
	{
		if (e.Button == .Right)
		{
			mIsLooking = true;
			mLastMouseX = e.X;
			mLastMouseY = e.Y;
			// Set capture so we receive OnMouseUp even if mouse leaves the viewport.
			mViewport?.Context?.FocusManager.SetCapture(mViewport);
			e.Handled = true;
		}
	}

	private void OnMouseUp(MouseEventArgs e)
	{
		if (e.Button == .Right && mIsLooking)
		{
			mIsLooking = false;
			mViewport?.Context?.FocusManager.ReleaseCapture();
			e.Handled = true;
		}
	}

	private void OnMouseMove(MouseEventArgs e)
	{
		if (!mIsLooking)
		{
			mLastMouseX = e.X;
			mLastMouseY = e.Y;
			return;
		}

		float deltaX = e.X - mLastMouseX;
		float deltaY = e.Y - mLastMouseY;
		mLastMouseX = e.X;
		mLastMouseY = e.Y;

		mYaw += deltaX * mLookSensitivity;
		mPitch -= deltaY * mLookSensitivity;
		mPitch = Math.Clamp(mPitch, -Math.PI_f * 0.49f, Math.PI_f * 0.49f);

		ApplyTransform();
		e.Handled = true;
	}

	private void OnMouseWheel(MouseWheelEventArgs e)
	{
		let cosP = Math.Cos(mPitch);
		let forward = Vector3(cosP * Math.Sin(mYaw), Math.Sin(mPitch), cosP * Math.Cos(mYaw));
		mPosition += forward * e.DeltaY * mMoveSpeed * 0.5f;
		ApplyTransform();
		e.Handled = true;
	}

	// === Transform ===

	private void ApplyTransform()
	{
		if (mCameraEntity == .Invalid || mScene == null) return;

		let cosP = Math.Cos(mPitch);
		let forward = Vector3(cosP * Math.Sin(mYaw), Math.Sin(mPitch), cosP * Math.Cos(mYaw));
		let target = mPosition + forward;
		mScene.SetLocalTransform(mCameraEntity, Transform.CreateLookAt(mPosition, target));
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
		mPosition = worldMat.Translation;

		// Set yaw/pitch to look toward origin from initial position,
		// matching EngineSandbox's convention.
		mYaw = Math.PI_f;
		mPitch = -0.38f; // slight downward tilt

		// Apply so camera transform matches our state.
		ApplyTransform();
	}
}
