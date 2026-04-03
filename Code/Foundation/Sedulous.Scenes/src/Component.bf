namespace Sedulous.Scenes;

/// Base class for all components.
/// Components are ref types, pooled per type in a ComponentManager.
/// Game code defines components by extending this class with data fields.
public abstract class Component
{
	/// The entity this component is attached to. Set by the manager.
	public EntityHandle Owner = .Invalid;

	/// Whether this component is active. Mirrors the owning entity's active state.
	public bool IsActive = true;
}
