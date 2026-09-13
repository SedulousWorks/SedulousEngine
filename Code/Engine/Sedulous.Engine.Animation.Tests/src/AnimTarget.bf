using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation.Tests;

/// What a clip animates in these tests: a vector and a scalar, so a track can be pointed at
/// either and a mismatched kind has somewhere to go wrong.
[SerializableComponent("anim_target")]
struct AnimTarget : ISerializable
{
	public Float3 Position = .(0, 0, 0);
	public float Value = 0.0f;

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		ar.Key("position");
		Sedulous.Core.Serialization.Serialize(ar, ref Position);
		SerializeValue(ar, "value", ref Value);
	}
}
