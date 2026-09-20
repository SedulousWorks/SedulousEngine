using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Render;

namespace Sedulous.Editor.Scene;

/// The display entity and key light a single object thumbnail is staged with, made once on
/// the shared stage and switched off between jobs.
class ThumbnailStageEntities
{
	public EntityHandle Display = .Invalid;
	public EntityHandle Sun = .Invalid;

	/// The display entity's mesh component, creating both entities on first use; null when
	/// the stage lacks the managers.
	public MeshComponent* Ensure(Sedulous.Scene.Scene stage, StringView name)
	{
		let meshes = stage.GetSystem<MeshComponentManager>();
		let lights = stage.GetSystem<LightComponentManager>();
		if ((meshes == null) || (lights == null))
			return null;
		if (!Display.IsAssigned || !stage.IsValid(Display))
		{
			Display = stage.CreateEntity(name);
			meshes.Add(Display);
			Sun = stage.CreateEntity("ThumbSun");
			var t = Transform();
			t.Rotation = Quaternion.FromAxisAngle(.(0, 1, 0), 0.35f)
				* Quaternion.FromAxisAngle(.(1, 0, 0), -1.05f);
			stage.SetLocalTransform(Sun, t);
			let light = lights.Add(Sun);
			light.CastsShadows = false; // a lone preview object has nothing to shadow
		}
		stage.SetActive(Display, true);
		stage.SetActive(Sun, true);
		return meshes.Get(Display);
	}

	public void Deactivate(Sedulous.Scene.Scene stage)
	{
		if (Display.IsAssigned && stage.IsValid(Display))
			stage.SetActive(Display, false);
		if (Sun.IsAssigned && stage.IsValid(Sun))
			stage.SetActive(Sun, false);
	}
}
