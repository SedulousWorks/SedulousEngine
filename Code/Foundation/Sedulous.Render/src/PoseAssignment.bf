namespace Sedulous.Render;

/// How a skinned instance picks its pose out of the shared palettes.
enum PoseAssignment : uint8
{
	/// Scattered, and decorrelated from any spatial layout: the natural default for a crowd
	/// of independent agents.
	case Hashed;
	/// The instance's index modulo the palette count, which makes a phase gradient, though
	/// only where the instances are laid out in the order that gradient should follow.
	case Sequential;
	/// The CALLER supplies a per instance index, for a layout aware look the renderer cannot
	/// work out from a flat index: columns, spatial clusters, or gameplay state.
	case Explicit;
}
