using System;
using Sedulous.Core.Serialization;
using Sedulous.Scene;

using Sedulous.Core;

namespace Sedulous.Engine.Spline;

/// Moves its entity along ANOTHER entity's spline at a constant speed.
///
/// The distance is serialized, so an authored start offset survives a save. A follow that
/// does not loop stops at the end; a closed curve always wraps, whatever the flag says.
[SerializableComponent("path_follow")]
[DisplayName("Path Follow")]
[Category("Utility")]
[Scriptable]
struct PathFollowComponent : ISerializable
{
	/// The entity carrying the spline.
	[Scriptable]
	public EntityRef Spline = .();
	/// World units per second along the curve.
	[Scriptable]
	public float Speed = 1.0f;
	/// Where along the curve it currently is.
	[Scriptable]
	public float Distance = 0.0f;
	[Scriptable]
	public bool Playing = true;
	[Scriptable]
	public bool Loop = true;
	/// Face -Z along the curve direction.
	[Scriptable]
	public bool AlignToTangent = true;

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "spline", ref Spline.Id);
		SerializeValue(ar, "speed", ref Speed);
		SerializeValue(ar, "distance", ref Distance);
		SerializeValue(ar, "playing", ref Playing);
		SerializeValue(ar, "loop", ref Loop);
		SerializeValue(ar, "alignToTangent", ref AlignToTangent);
	}
}
