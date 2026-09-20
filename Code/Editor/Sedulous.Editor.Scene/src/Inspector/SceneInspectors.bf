using Sedulous.Engine.Render;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Audio;
using Sedulous.Engine.Navigation;
using Sedulous.Engine.Particles;
using Sedulous.Engine.Spline;
using Sedulous.Engine.Terrain;
using Sedulous.Engine.UI;
using Sedulous.Engine.Script;

namespace Sedulous.Editor.Scene;

/// Registers every engine component and settings type the scene editor inspects.
static class SceneInspectors
{
	public static void RegisterBuiltin()
	{
		// Rendering.
		InspectorRegistry.Register<MeshComponent>();
		InspectorRegistry.Register<InstancedMeshComponent>();
		InspectorRegistry.Register<CameraComponent>();
		InspectorRegistry.Register<LightComponent>();
		InspectorRegistry.Register<SpriteComponent>();
		InspectorRegistry.Register<DecalComponent>();
		InspectorRegistry.Register<ReflectionProbeComponent>();
		InspectorRegistry.Register<EnvironmentSettings>();
		InspectorRegistry.Register<PostProcessSettings>();
		// Physics.
		InspectorRegistry.Register<RigidBodyComponent>();
		InspectorRegistry.Register<ColliderComponent>();
		InspectorRegistry.Register<CharacterComponent>();
		InspectorRegistry.Register<JointComponent>();
		InspectorRegistry.Register<PhysicsSceneSettings>();
		// Animation.
		InspectorRegistry.Register<SkeletalAnimationComponent>();
		InspectorRegistry.Register<AnimationGraphComponent>();
		InspectorRegistry.Register<InstancedSkinningComponent>();
		InspectorRegistry.Register<PropertyAnimatorComponent>();
		// Audio.
		InspectorRegistry.Register<AudioSourceComponent>();
		InspectorRegistry.Register<AudioListenerComponent>();
		InspectorRegistry.Register<AudioReverbZoneComponent>();
		// Navigation.
		InspectorRegistry.Register<NavMeshZoneComponent>();
		InspectorRegistry.Register<NavAgentComponent>();
		InspectorRegistry.Register<NavigationSceneSettings>();
		// Effects, utility, terrain, UI, script.
		InspectorRegistry.Register<ParticleEffectComponent>();
		InspectorRegistry.Register<SplineComponent>();
		InspectorRegistry.Register<PathFollowComponent>();
		InspectorRegistry.Register<TerrainComponent>();
		InspectorRegistry.Register<UIBillboardComponent>();
		InspectorRegistry.Register<UICanvasComponent>();
		InspectorRegistry.Register<UIWorldPanelComponent>();
		InspectorRegistry.Register<ScriptComponent>();
		InspectorRegistry.Register<SceneScriptSettings>();
	}
}
