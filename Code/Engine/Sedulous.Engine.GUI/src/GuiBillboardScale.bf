namespace Sedulous.Engine.GUI;

/// Whether a billboard's size follows its distance from the camera.
enum GuiBillboardScale : uint8
{
	/// The same size at any distance.
	case Fixed = 0;
	/// The reference distance over the distance, within the minimum and maximum scale.
	case Distance;
}
