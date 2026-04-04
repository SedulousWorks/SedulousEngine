namespace Sedulous.Engine.Audio;

using Sedulous.Runtime;
using Sedulous.Scenes;
using Sedulous.Engine;

/// Owns the audio device and mixer.
/// Per-scene spatial audio contexts are managed by AudioSourceManager (scene module), injected via ISceneAware.
class AudioSubsystem : Subsystem, ISceneAware
{
	public override int32 UpdateOrder => 200;

	protected override void OnInit()
	{
	}

	protected override void OnShutdown()
	{
	}

	public void OnSceneCreated(Scene scene)
	{
		// TODO: inject AudioSourceManager into scene
	}

	public void OnSceneDestroyed(Scene scene)
	{
	}
}
