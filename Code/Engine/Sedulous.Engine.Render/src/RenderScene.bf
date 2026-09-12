using Sedulous.Scene;

namespace Sedulous.Engine.Render;

/// THE render manager set for a scene.
///
/// Injected by the subsystem at runtime AND by a headless consumer that never has one, so a
/// manager added here reaches both rather than only the path someone remembered.
static class RenderScene
{
	public static void AddRenderSceneManagers(Scene scene)
	{
		scene.AddSystem<MeshComponentManager>();
		scene.AddSystem<InstancedMeshComponentManager>();
		scene.AddSystem<SpriteComponentManager>();
		scene.AddSystem<DecalComponentManager>();
		scene.AddSystem<CameraComponentManager>();
		scene.AddSystem<LightComponentManager>();
		scene.AddSystem<ReflectionProbeComponentManager>();
		scene.AddSystem<EnvironmentSystem>();
		scene.AddSystem<PostProcessSystem>();
	}
}
