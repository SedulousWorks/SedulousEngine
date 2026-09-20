namespace Sedulous.Editor.Scene;

static class BuiltinGizmoRenderers
{
	/// Every renderer the scene page ships with.
	public static void Register(GizmoRendererRegistry registry)
	{
		registry.Register(new LightGizmoRenderer());
		registry.Register(new ReflectionProbeGizmoRenderer());
		registry.Register(new CameraGizmoRenderer());
		registry.Register(new DecalGizmoRenderer());
		registry.Register(new NavMeshZoneGizmoRenderer());
		registry.Register(new LodOverlayGizmoRenderer());
		registry.Register(new PhysicsColliderGizmoRenderer());
		registry.Register(new ChildColliderGizmoRenderer());
		registry.Register(new CharacterColliderGizmoRenderer());
		registry.Register(new JointGizmoRenderer());
		registry.Register(new SplineGizmoRenderer());
	}
}
