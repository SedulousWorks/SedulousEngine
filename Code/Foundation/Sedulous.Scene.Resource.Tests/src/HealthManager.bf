namespace Sedulous.Scene.Resource.Tests;

/// The pool that persists Health. It states no id of its own: the component carries it.
class HealthManager : SerializableComponentManager<Health>
{
}
