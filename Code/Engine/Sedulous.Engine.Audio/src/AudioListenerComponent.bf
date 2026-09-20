using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Scene;

namespace Sedulous.Engine.Audio;

/// The ears. The FIRST active one is the scene's primary; every active one collects, which is
/// what a split screen needs.
[SerializableComponent("audio.Listener")]
[DisplayName("Audio Listener")]
[Category("Audio")]
[Scriptable]
struct AudioListenerComponent : ISerializable
{
	[Scriptable]
	public bool IsActive = true;

	// ---- runtime ----

	[Hidden]
	public Float3 PreviousPosition = .(0.0f, 0.0f, 0.0f);
	[Hidden]
	public bool HasPreviousPosition = false;

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "isActive", ref IsActive);
	}
}
