namespace Sedulous.Scene.Tests;

/// Creates and frees each component's payload through the lifecycle hooks, and counts both
/// so a teardown that skips them is visible.
class OwningManager : ComponentManager<Owning>
{
	public int Created = 0;
	public int Destroyed = 0;

	protected override void OnComponentCreated(Owning* component, EntityHandle entity)
	{
		component.Payload = new System.Collections.List<int32>();
		Created++;
	}

	protected override void OnComponentDestroyed(Owning* component, EntityHandle entity)
	{
		delete component.Payload;
		component.Payload = null;
		Destroyed++;
	}
}
