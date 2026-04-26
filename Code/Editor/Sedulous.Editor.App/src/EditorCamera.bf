namespace Sedulous.Editor.App;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Engine.Render;

/// Independent editor camera that is NOT a scene entity.
/// Provides orbit/fly camera state and computes view/projection matrices directly.
class EditorCamera
{
	// Orbit state: position derived from target + distance + yaw + pitch
	public Vector3 Target = .Zero;
	public float Distance = 5.0f;
	public float Yaw = Math.PI_f;
	public float Pitch = 0.38f;
	public float MinPitch = -Math.PI_f * 0.49f;
	public float MaxPitch = Math.PI_f * 0.49f;
	public float MinDistance = 0.5f;
	public float MaxDistance = 500.0f;

	// Projection
	public float FieldOfView = 60.0f;
	public float NearPlane = 0.1f;
	public float FarPlane = 1000.0f;

	/// Computed camera position from orbit parameters.
	public Vector3 Position
	{
		get
		{
			let cosP = Math.Cos(Pitch);
			return Target + Vector3(
				Distance * cosP * Math.Sin(Yaw),
				Distance * Math.Sin(Pitch),
				Distance * cosP * Math.Cos(Yaw));
		}
	}

	/// Forward direction (from camera toward target).
	public Vector3 Forward => Vector3.Normalize(Target - Position);

	/// Right direction.
	public Vector3 Right
	{
		get
		{
			let fwd = Forward;
			return Vector3.Normalize(Vector3.Cross(fwd, Vector3.Up));
		}
	}

	/// Up direction (perpendicular to forward and right).
	public Vector3 Up => Vector3.Cross(Right, Forward);

	/// Computes the view matrix (camera look-at).
	public Matrix GetViewMatrix()
	{
		let pos = Position;
		return Matrix.CreateLookAt(pos, Target, Vector3.Up);
	}

	/// Computes the perspective projection matrix.
	public Matrix GetProjectionMatrix(float aspect)
	{
		return Matrix.CreatePerspectiveFieldOfView(
			FieldOfView * (Math.PI_f / 180.0f),
			aspect, NearPlane, FarPlane);
	}

	/// Builds a CameraOverride for passing to the renderer.
	public CameraOverride GetCameraOverride(float aspect)
	{
		return .()
		{
			ViewMatrix = GetViewMatrix(),
			ProjectionMatrix = GetProjectionMatrix(aspect),
			CameraPosition = Position,
			NearPlane = NearPlane,
			FarPlane = FarPlane
		};
	}
}
