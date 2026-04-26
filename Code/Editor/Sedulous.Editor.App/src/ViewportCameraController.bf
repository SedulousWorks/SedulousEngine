namespace Sedulous.Editor.App;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.UI;
using Sedulous.Shell.Input;
using Sedulous.UI.Viewport;

/// Orbit/fly camera controller for viewport views.
/// Operates on an EditorCamera (not a scene entity).
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
public class ViewportCameraController
{
	private EditorCamera mCamera;
	private ViewportView mViewport;
	private IKeyboard mKeyboard;

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

	public EditorCamera Camera => mCamera;

	public this(EditorCamera camera, IKeyboard keyboard)
	{
		mCamera = camera;
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
		if (mCamera == null || mKeyboard == null) return;

		// WASD movement only while flying (RMB held)
		if (!mIsFlying) return;

		let forward = mCamera.Forward;
		let right = mCamera.Right;
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
			mCamera.Target = mCamera.Target + delta;
		}
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
			mCamera.Yaw += deltaX * mLookSensitivity;
			mCamera.Pitch = Math.Clamp(mCamera.Pitch - deltaY * mLookSensitivity, mCamera.MinPitch, mCamera.MaxPitch);
			e.Handled = true;
		}
		else if (mIsFlying)
		{
			// RMB: free look - rotate in place, target follows camera
			let pos = mCamera.Position;
			mCamera.Yaw += deltaX * mLookSensitivity;
			mCamera.Pitch = Math.Clamp(mCamera.Pitch - deltaY * mLookSensitivity, mCamera.MinPitch, mCamera.MaxPitch);
			// Recompute target so camera stays at the same position
			mCamera.Target = pos + mCamera.Forward * mCamera.Distance;
			e.Handled = true;
		}
		else if (mIsPanning)
		{
			// MMB: pan - move target + camera laterally
			let right = mCamera.Right;
			let up = Vector3.Cross(right, mCamera.Forward);
			let panScale = mCamera.Distance * 0.005f;
			mCamera.Target = mCamera.Target + right * (-deltaX * panScale) + up * (deltaY * panScale);
			e.Handled = true;
		}
	}

	private void OnMouseWheel(MouseWheelEventArgs e)
	{
		// Zoom: adjust distance
		mCamera.Distance = Math.Clamp(mCamera.Distance - e.DeltaY * mCamera.Distance * 0.1f,
			mCamera.MinDistance, mCamera.MaxDistance);
		e.Handled = true;
	}
}
