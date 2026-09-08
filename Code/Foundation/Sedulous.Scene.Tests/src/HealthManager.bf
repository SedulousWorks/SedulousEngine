namespace Sedulous.Scene.Tests;

/// A concrete manager that COUNTS its lifecycle hooks, which is how the deferred
/// initialisation and the destroy on remove are observed at all.
class HealthManager : ComponentManager<Health>
{
	public int Created = 0;
	public int Initialized = 0;
	public int Destroyed = 0;

	protected override void OnComponentCreated(Health* component, EntityHandle entity)
		{ Created++; }
	protected override void OnComponentInitialized(Health* component, EntityHandle entity)
		{ Initialized++; }
	protected override void OnComponentDestroyed(Health* component, EntityHandle entity)
		{ Destroyed++; }
}
