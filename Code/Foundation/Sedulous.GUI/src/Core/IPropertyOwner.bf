namespace Sedulous.GUI;

/// Interface for objects that own Property<T> instances and respond
/// to property value changes with invalidation. Decouples Property<T>
/// from View so non-View objects could potentially own properties.
public interface IPropertyOwner
{
	/// Called when a property's value changes.
	void OnPropertyChanged(InvalidationKind kind);
}
