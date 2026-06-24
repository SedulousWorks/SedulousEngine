namespace TowerDefense;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Engine.Core;
using Sedulous.Shell.Input;

/// Top-down camera controller for tower defense.
/// WASD to pan, scroll wheel to zoom, fixed viewing angle.
class TDCameraController
{
	/// World position the camera looks at (on the ground plane).
	public Vector3 LookTarget = .(6, 0, 6);

	/// Camera height above the ground.
	public float Zoom = 12.0f;

	/// Min/max zoom limits.
	public float MinZoom = 5.0f;
	public float MaxZoom = 25.0f;

	/// Pan speed in world units per second.
	public float PanSpeed = 8.0f;

	/// Zoom speed per scroll tick.
	public float ZoomSpeed = 2.0f;

	/// Viewing angle from vertical (radians). ~55 degrees for classic TD view.
	public float ViewAngle = 55.0f * (Math.PI_f / 180.0f);

	/// The entity this controller manages.
	public EntityHandle CameraEntity;

	/// Updates camera position from input.
	public void Update(float deltaTime, IKeyboard keyboard, IMouse mouse)
	{
		// Pan with WASD
		float moveX = 0;
		float moveZ = 0;

		if (keyboard.IsKeyDown(.W) || keyboard.IsKeyDown(.Up))
			moveZ -= 1;
		if (keyboard.IsKeyDown(.S) || keyboard.IsKeyDown(.Down))
			moveZ += 1;
		if (keyboard.IsKeyDown(.A) || keyboard.IsKeyDown(.Left))
			moveX -= 1;
		if (keyboard.IsKeyDown(.D) || keyboard.IsKeyDown(.Right))
			moveX += 1;

		if (moveX != 0 || moveZ != 0)
		{
			let dir = Vector3.Normalize(.(moveX, 0, moveZ));
			LookTarget += dir * PanSpeed * deltaTime;
		}

		// Zoom with scroll wheel
		let scroll = mouse.ScrollY;
		if (scroll != 0)
		{
			Zoom -= scroll * ZoomSpeed;
			Zoom = Math.Clamp(Zoom, MinZoom, MaxZoom);
		}
	}

	/// Computes the camera transform and applies it to the scene.
	public void ApplyToScene(Scene scene)
	{
		if (!scene.IsValid(CameraEntity))
			return;

		// Camera positioned behind and above the look target
		let offsetY = Zoom * Math.Cos(ViewAngle);
		let offsetZ = Zoom * Math.Sin(ViewAngle);
		let cameraPos = LookTarget + Vector3(0, offsetY, offsetZ);

		// Use Transform.CreateLookAt for camera placement
		scene.SetLocalTransform(CameraEntity, Transform.CreateLookAt(cameraPos, LookTarget));
	}
}
