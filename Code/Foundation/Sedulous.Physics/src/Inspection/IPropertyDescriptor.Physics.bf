namespace Sedulous.Inspection;

using Sedulous.Physics;
using System;

/// Physics-side extension of IPropertyDescriptor: adds descriptor methods
/// for the awkward types the codegen will encounter on physics components.
/// Lives in Sedulous.Physics so the descriptor interface in
/// Sedulous.Inspection doesn't need to know about physics types - the
/// extension mechanism stitches them together at compile time. Mirrors
/// the Sedulous.Particles precedent (RangeFloat / CurveFloat / EmissionShape).
///
/// Any IPropertyDescriptor implementation (e.g. the editor's
/// EditorPropertyGridDescriptor) must also implement these extension methods
/// to be usable with comptime-generated DescribeProperties on physics
/// components.
extension IPropertyDescriptor
{
	/// ShapeConfig field (Box / Sphere / Capsule / Cylinder / Plane with
	/// a type discriminator and per-type sub-fields). The editor's
	/// implementation shows the type combo and only the sub-fields
	/// relevant to the selected type; v1 fallback in
	/// `PropertyGridDescriptor` is a read-only summary.
	///
	/// `onChanged` fires after each user edit so the component can
	/// flag its physics body for shape rebuild. Optional; null is fine
	/// for one-off inspectors that don't need rebuild notification.
	/// The implementation owns the delegate.
	void ShapeConfig(StringView name, ShapeConfig* ptr, delegate void() onChanged = null);
}
