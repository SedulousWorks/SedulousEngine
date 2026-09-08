namespace Sedulous.Scene.Resource.Tests;

/// The pool that persists Health, under a stable id on disk.
class HealthManager : SerializableComponentManager<Health>
{
	public this() : base("test.Health") {}
}
