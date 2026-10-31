using Sedulous.Core;

namespace Sedulous.UI.Toolkit;

/// What a port carries, for validating connections and colouring them.
///
/// The type is a caller defined NUMBER rather than an enum of the canvas's own, so an animation
/// graph, an audio graph and a shader graph can each define their own set without the canvas
/// knowing any of them. Zero means untyped and connects to anything.
struct NodeGraphPortType
{
	public int32 TypeId = 0;
	/// The port circle and any compatible edge take this.
	public Color Color = .();

	public this() {}

	public this(int32 typeId, Color color)
	{
		TypeId = typeId;
		Color = color;
	}

	/// QUALIFIED: the Color field shadows the type inside this struct.
	public static NodeGraphPortType Untyped() =>
		.(0, Sedulous.Core.Color.Rgb(180, 180, 190));
}
