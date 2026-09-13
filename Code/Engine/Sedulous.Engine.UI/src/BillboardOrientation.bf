namespace Sedulous.Engine.UI;

/// What frame a billboard's offset is measured in.
enum BillboardOrientation : uint8
{
	/// ENTITY LOCAL, so the offset rides the entity's rotation.
	case Screen = 0;
	/// WORLD, so the offset is a fixed lift above the anchor however it turns.
	case Cylindrical;
}
