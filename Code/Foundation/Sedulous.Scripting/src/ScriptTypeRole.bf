namespace Sedulous.Scripting;

/// How a script reaches an instance of a class on the surface. Recognised by the walker
/// from the type's bases and attributes, so the generated glue knows what to resolve
/// before it can call.
enum ScriptTypeRole
{
	/// A plain type: constructed, or handed over.
	case Plain;
	/// A SceneSystem: reached through the scene, `scene.GetSystem<T>()`.
	case SceneSystem;
	/// A ComponentManager<T>: reached through the scene, and its components by entity.
	case ComponentManager;
	/// Component data: a struct in a manager's pool, reached through its manager and an
	/// entity handle. ManagerTypeName names the manager.
	case Component;
	/// A Subsystem or other engine level service, reached through the context.
	case Service;
}
