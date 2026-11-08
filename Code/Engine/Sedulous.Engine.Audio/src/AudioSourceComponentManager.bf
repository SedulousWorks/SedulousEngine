using System;
using Sedulous.Scene;

namespace Sedulous.Engine.Audio;

/// The pool of audio sources.
///
/// It creates and frees each component's bus name, because a component is a struct in a packed
/// pool and cannot own heap data itself.
class AudioSourceComponentManager : ResourceBindingComponentManager<AudioSourceComponent>
{
	/// BORROWED: the scene's audio system while the scene plays, else null.
	private IAudioReleaser mReleaser = null;

	/// The base's destructor sweeps the components through OnComponentDestroyed; mid teardown the
	/// audio system may be gone, so no voice is handed over then.
	public ~this()
	{
		mReleaser = null;
	}

	public void SetReleaser(IAudioReleaser releaser)
	{
		mReleaser = releaser;
	}

	protected override void OnComponentCreated(AudioSourceComponent* component,
		EntityHandle entity)
	{
		component.BusName = new String();
	}

	/// A removed source's voice stops with it.
	protected override void OnComponentDestroyed(AudioSourceComponent* component,
		EntityHandle entity)
	{
		if ((mReleaser != null) && component.Voice.IsValid)
			mReleaser.ReleaseVoice(component.Voice);
		component.Voice = .();
		DeleteAndNullify!(component.BusName);
	}
}
