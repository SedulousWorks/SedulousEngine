namespace Sedulous.Engine.Audio;

using System;
using Sedulous.Engine.Core;
using Sedulous.Audio;
using Sedulous.Core.Mathematics;

/// Manages audio listener components: syncs the active listener's position
/// and orientation from its entity's world transform to the IAudioSystem listener.
///
/// Updates in PostTransform phase - after transforms are finalized.
class AudioListenerComponentManager : ComponentManager<AudioListenerComponent>
{
	/// Audio system whose listener we sync to.
	public IAudioSystem AudioSystem { get; set; }

	public override StringView SerializationTypeId => "Sedulous.AudioListenerComponent";

	protected override void OnRegisterUpdateFunctions()
	{
		RegisterUpdate(.PostTransform, new => SyncListener);
	}

	private void SyncListener(float deltaTime)
	{
		if (AudioSystem == null) return;
		let scene = Scene;
		if (scene == null) return;

		let listener = AudioSystem.Listener;
		if (listener == null) return;

		// Find the first active listener and sync its transform
		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive || !comp.IsActiveListener) continue;

			let worldMatrix = scene.GetWorldMatrix(comp.Owner);
			listener.Position = worldMatrix.Translation;

			// Extract forward and up from world matrix (row-major)
			// Forward is negative Z in our coordinate system
			listener.Forward = -(Vector3(worldMatrix.M31, worldMatrix.M32, worldMatrix.M33));
			listener.Up = Vector3(worldMatrix.M21, worldMatrix.M22, worldMatrix.M23);

			break; // Only use the first active listener
		}
	}
}
