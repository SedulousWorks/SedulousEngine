namespace Sedulous.Engine.Core;

/// Base class for all components.
/// Components are ref types, pooled per type in a ComponentManager.
/// Game code defines components by extending this class with data fields.
///
/// Lifecycle:
///   1. CreateComponent()         - allocates slot, sets Owner, calls OnComponentCreated
///   2. [app sets properties]     - Shape, BodyType, clip refs, etc.
///   3. OnComponentInitialized()  - called at start of next Scene update, all properties set
///   4. [simulation runs]         - FixedUpdate, Update phases, etc.
///   5. OnComponentDestroyed()    - called on destroy or entity destroy
public abstract class Component
{
	/// The entity this component is attached to. Set by the manager.
	public EntityHandle Owner = .Invalid;

	/// Whether this component is active. Mirrors the owning entity's active state.
	public bool IsActive = true;

	/// Whether this component has been initialized (OnComponentInitialized called).
	/// Set automatically by ComponentManager - do not modify.
	public bool Initialized = false;
}
