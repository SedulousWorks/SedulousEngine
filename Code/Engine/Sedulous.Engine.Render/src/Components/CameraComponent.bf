namespace Sedulous.Engine.Render;

using Sedulous.Engine.Core;
using Sedulous.Core.Mathematics;
using System;

/// Component for a camera that defines a rendering viewpoint.
[Component]
class CameraComponent : Component, ISerializableComponent
{
	public int32 SerializationVersion => 1;

	public void Serialize(IComponentSerializer s)
	{
		s.Float("FieldOfView", ref FieldOfView);
		s.Float("NearPlane", ref NearPlane);
		s.Float("FarPlane", ref FarPlane);
		s.Float("AspectRatio", ref AspectRatio);
		s.Bool("IsActiveCamera", ref IsActiveCamera);
		var layerMask = (int32)LayerMask;
		s.Int32("LayerMask", ref layerMask);
		if (s.IsReading) LayerMask = (uint32)layerMask;
	}

	/// Field of view in degrees (vertical).
	[Property]
	[Range(1.0f, 179.0f)]
	public float FieldOfView = 60.0f;

	/// Near clip plane distance.
	[Property]
	[Range(0.001f, 1000.0f)]
	public float NearPlane = 0.1f;

	/// Far clip plane distance.
	[Property]
	[Range(1.0f, 100000.0f)]
	public float FarPlane = 1000.0f;

	/// Aspect ratio override (0 = use viewport aspect).
	[Property]
	public float AspectRatio = 0;

	/// Whether this is the active camera for rendering.
	[Property]
	public bool IsActiveCamera = true;

	/// Render layer mask (which layers this camera sees).
	[Property]
	public uint32 LayerMask = 0xFFFFFFFF;

	/// Computes the view matrix from the entity's world transform.
	public Matrix GetViewMatrix(Scene scene)
	{
		let world = scene.GetWorldMatrix(Owner);
		// View matrix is the inverse of the camera's world transform
		Matrix view = .Identity;
		Matrix.Invert(world, out view);
		return view;
	}

	/// Computes the projection matrix.
	public Matrix GetProjectionMatrix(float viewportAspect)
	{
		let aspect = (AspectRatio > 0) ? AspectRatio : viewportAspect;
		return Matrix.CreatePerspectiveFieldOfView(
			Math.DegreesToRadians(FieldOfView),
			aspect,
			NearPlane,
			FarPlane
		);
	}
}
