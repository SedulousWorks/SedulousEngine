using System;
using Sedulous.Scene;

namespace Sedulous.Engine.Audio;

/// The pool of audio sources.
///
/// It creates and frees each component's bus name, because a component is a struct in a packed
/// pool and cannot own heap data itself.
class AudioSourceComponentManager : ResourceBindingComponentManager<AudioSourceComponent>
{
	protected override void OnComponentCreated(AudioSourceComponent* component,
		EntityHandle entity)
	{
		component.BusName = new String();
	}

	protected override void OnComponentDestroyed(AudioSourceComponent* component,
		EntityHandle entity)
	{
		DeleteAndNullify!(component.BusName);
	}
}
