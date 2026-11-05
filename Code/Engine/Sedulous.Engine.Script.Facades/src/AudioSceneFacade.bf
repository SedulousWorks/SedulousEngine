using System;
using Sedulous.Core;
using Sedulous.Audio;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Engine.Audio;

namespace Sedulous.Engine.Script.Facades;

/// `scene.Audio`: the sound source on an entity.
[Scriptable, SceneFacade("Audio")]
class AudioSceneFacade : SceneFacade
{
	private AudioSceneSystem System => Scene.GetSystem<AudioSceneSystem>();

	/// Plays the entity's source; the voice, for a later stop or check.
	[Scriptable]
	public VoiceHandle Play(EntityHandle entity) => System?.Play(entity) ?? .();
	[Scriptable]
	public void Stop(EntityHandle entity) => System?.Stop(entity);
	[Scriptable]
	public void SetPaused(EntityHandle entity, bool paused) => System?.SetPaused(entity, paused);
	[Scriptable]
	public bool IsPlaying(EntityHandle entity) => System?.IsPlaying(entity) ?? false;
	/// The source's volume, eased onto its playing voice over `seconds` and kept for its next
	/// play. The component's volume is otherwise read only when the source starts.
	[Scriptable]
	public void SetVolume(EntityHandle entity, float volume, float seconds = 0.0f) => System?.SetVolume(entity, volume, seconds);
	/// The source's pitch, eased and kept the same way.
	[Scriptable]
	public void SetPitch(EntityHandle entity, float pitch, float seconds = 0.0f) => System?.SetPitch(entity, pitch, seconds);
	/// The clip by asset id.
	[Scriptable]
	public void SetClip(EntityHandle entity, Guid clip) => System?.SetClip(entity, clip);
}
