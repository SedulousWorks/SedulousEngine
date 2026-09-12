using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Scene;

namespace Sedulous.Engine.Render;

/// A camera frustum on an entity.
///
/// These fields are the PROJECTION only: the view transform is the inverse of the entity's
/// world matrix, so moving the entity moves the camera and nothing here has to say so.
[SerializableComponent("camera")]
struct CameraComponent : ISerializable
{
	/// Sixty degrees.
	public float FovYRadians = 1.04719755f;
	public float Aspect = 16.0f / 9.0f;
	public float NearZ = 0.1f;
	public float FarZ = 1000.0f;
	/// The backdrop this view clears to, per camera. Cornflower is the sentinel.
	public Color ClearColor = .(0.392f, 0.584f, 0.929f, 1.0f);
	/// Marks the camera the renderer uses.
	public bool Primary = true;

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "fovYRadians", ref FovYRadians);
		SerializeValue(ar, "aspect", ref Aspect);
		SerializeValue(ar, "nearZ", ref NearZ);
		SerializeValue(ar, "farZ", ref FarZ);
		ar.Key("clearColor");
		Sedulous.Core.Serialization.Serialize(ar, ref ClearColor);
		SerializeValue(ar, "primary", ref Primary);
	}
}
