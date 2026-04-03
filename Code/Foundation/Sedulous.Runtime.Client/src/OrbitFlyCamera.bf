namespace Sedulous.Runtime.Client;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Shell.Input;

/// Reusable orbital/flythrough camera controller.
/// Handles keyboard and mouse input for two camera modes:
/// - Orbital: orbits a target point (right-click drag, scroll zoom, WASD rotate, Q/E zoom)
/// - Flythrough: free movement (WASD move, Q/E up/down, mouse look, Shift sprint)
///
/// Mode switching: Tab (orbital->fly or toggle mouse capture), Backtick (->orbital)
public class OrbitFlyCamera
{
	public enum Mode { Orbital, Flythrough }

	// --- Configuration ---
	public float MoveSpeed = 15.0f;
	public float LookSpeed = 0.003f;
	public float OrbitalRotSpeed = 0.02f;
	public float MinDistance = 2.0f;
	public float MaxDistance = 50.0f;
	public float ScrollZoomStep = 1.5f;
	public bool ProportionalZoom = false;
	public float ProportionalZoomFactor = 0.1f;
	public float KeyboardZoomStep = 0.1f;

	// --- State ---
	public Mode CurrentMode = .Orbital;
	public float OrbitalYaw = 0.5f;
	public float OrbitalPitch = 0.4f;
	public float OrbitalDistance = 12.0f;
	public Vector3 OrbitalTarget = .(0, 0.5f, 0);
	public Vector3 FlyPosition = .(0, 5, 15);
	public float FlyYaw = Math.PI_f;
	public float FlyPitch = -0.3f;
	public bool MouseCaptured = false;

	// --- Output ---
	public Vector3 Position;
	public Vector3 Forward;

	/// The active yaw value (orbital or flythrough depending on mode).
	public float ViewYaw => (CurrentMode == .Flythrough) ? FlyYaw : OrbitalYaw;

	/// Processes input and updates Position/Forward.
	public void HandleInput(IKeyboard keyboard, IMouse mouse, float deltaTime)
	{
		// Tab: orbital->flythrough, or toggle mouse capture in flythrough
		if (keyboard.IsKeyPressed(.Tab))
		{
			if (CurrentMode == .Orbital)
			{
				CurrentMode = .Flythrough;
				// Initialize fly position from current orbital view
				FlyPosition = Position;
				FlyYaw = Math.Atan2(Forward.X, Forward.Z);
				FlyPitch = Math.Asin(Forward.Y);
			}
			else
			{
				MouseCaptured = !MouseCaptured;
				mouse.RelativeMode = MouseCaptured;
				mouse.Visible = !MouseCaptured;
			}
		}

		// Backtick returns to orbital
		if (keyboard.IsKeyPressed(.Grave) && CurrentMode == .Flythrough)
		{
			CurrentMode = .Orbital;
			if (MouseCaptured)
			{
				MouseCaptured = false;
				mouse.RelativeMode = false;
				mouse.Visible = true;
			}
		}

		switch (CurrentMode)
		{
		case .Orbital:
			HandleOrbitalInput(keyboard, mouse);
		case .Flythrough:
			HandleFlythroughInput(keyboard, mouse, deltaTime);
		}

		Update();
	}

	/// Computes Position and Forward from current state.
	public void Update()
	{
		switch (CurrentMode)
		{
		case .Orbital:
			float x = OrbitalDistance * Math.Cos(OrbitalPitch) * Math.Sin(OrbitalYaw);
			float y = OrbitalDistance * Math.Sin(OrbitalPitch);
			float z = OrbitalDistance * Math.Cos(OrbitalPitch) * Math.Cos(OrbitalYaw);
			Position = OrbitalTarget + Vector3(x, y, z);
			Forward = Vector3.Normalize(OrbitalTarget - Position);
		case .Flythrough:
			Position = FlyPosition;
			float cosP = Math.Cos(FlyPitch);
			Forward = Vector3.Normalize(.(
				cosP * Math.Sin(FlyYaw),
				Math.Sin(FlyPitch),
				cosP * Math.Cos(FlyYaw)
			));
		}
	}

	private void HandleOrbitalInput(IKeyboard keyboard, IMouse mouse)
	{
		// Right-click drag to orbit
		if (mouse.IsButtonDown(.Right))
		{
			OrbitalYaw -= mouse.DeltaX * LookSpeed;
			OrbitalPitch = Math.Clamp(OrbitalPitch - mouse.DeltaY * LookSpeed, -1.4f, 1.4f);
		}

		// Scroll zoom
		if (mouse.ScrollY != 0)
		{
			if (ProportionalZoom)
				OrbitalDistance = Math.Clamp(OrbitalDistance - mouse.ScrollY * OrbitalDistance * ProportionalZoomFactor, MinDistance, MaxDistance);
			else
				OrbitalDistance = Math.Clamp(OrbitalDistance - mouse.ScrollY * ScrollZoomStep, MinDistance, MaxDistance);
		}

		// WASD rotate, Q/E zoom
		if (keyboard.IsKeyDown(.A))
			OrbitalYaw -= OrbitalRotSpeed;
		if (keyboard.IsKeyDown(.D))
			OrbitalYaw += OrbitalRotSpeed;
		if (keyboard.IsKeyDown(.W))
			OrbitalPitch = Math.Clamp(OrbitalPitch + OrbitalRotSpeed, -1.4f, 1.4f);
		if (keyboard.IsKeyDown(.S))
			OrbitalPitch = Math.Clamp(OrbitalPitch - OrbitalRotSpeed, -1.4f, 1.4f);

		if (ProportionalZoom)
		{
			if (keyboard.IsKeyDown(.Q))
				OrbitalDistance = Math.Max(MinDistance, OrbitalDistance - OrbitalDistance * 0.02f);
			if (keyboard.IsKeyDown(.E))
				OrbitalDistance = Math.Min(MaxDistance, OrbitalDistance + OrbitalDistance * 0.02f);
		}
		else
		{
			if (keyboard.IsKeyDown(.Q))
				OrbitalDistance = Math.Clamp(OrbitalDistance - KeyboardZoomStep, MinDistance, MaxDistance);
			if (keyboard.IsKeyDown(.E))
				OrbitalDistance = Math.Clamp(OrbitalDistance + KeyboardZoomStep, MinDistance, MaxDistance);
		}
	}

	private void HandleFlythroughInput(IKeyboard keyboard, IMouse mouse, float deltaTime)
	{
		// Mouse look (when captured or right-click held)
		if (MouseCaptured || mouse.IsButtonDown(.Right))
		{
			FlyYaw -= mouse.DeltaX * LookSpeed;
			FlyPitch -= mouse.DeltaY * LookSpeed;
			FlyPitch = Math.Clamp(FlyPitch, -Math.PI_f * 0.49f, Math.PI_f * 0.49f);
		}

		// Movement
		float cosP = Math.Cos(FlyPitch);
		Vector3 forward = Vector3.Normalize(.(
			cosP * Math.Sin(FlyYaw),
			Math.Sin(FlyPitch),
			cosP * Math.Cos(FlyYaw)
		));
		Vector3 right = Vector3.Normalize(Vector3.Cross(forward, .(0, 1, 0)));

		float speed = MoveSpeed * deltaTime;
		if (keyboard.IsKeyDown(.LeftShift) || keyboard.IsKeyDown(.RightShift))
			speed *= 2.0f;

		if (keyboard.IsKeyDown(.W))
			FlyPosition = FlyPosition + forward * speed;
		if (keyboard.IsKeyDown(.S))
			FlyPosition = FlyPosition - forward * speed;
		if (keyboard.IsKeyDown(.A))
			FlyPosition = FlyPosition - right * speed;
		if (keyboard.IsKeyDown(.D))
			FlyPosition = FlyPosition + right * speed;
		if (keyboard.IsKeyDown(.Q))
			FlyPosition = FlyPosition - Vector3(0, 1, 0) * speed;
		if (keyboard.IsKeyDown(.E))
			FlyPosition = FlyPosition + Vector3(0, 1, 0) * speed;
	}
}
