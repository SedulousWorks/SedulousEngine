using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Scene;

namespace Sedulous.Engine.Audio;

/// The ears. The FIRST active one is the scene's primary; every active one collects, which is
/// what a split screen needs.
[SerializableComponent("audio.Listener")]
struct AudioListenerComponent : ISerializable
{
	public bool IsActive = true;

	// ---- runtime ----

	public Float3 PreviousPosition = .(0.0f, 0.0f, 0.0f);
	public bool HasPreviousPosition = false;

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "isActive", ref IsActive);
	}
}
