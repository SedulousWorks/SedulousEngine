namespace Sedulous.Editor.Terrain;

/// Which optional per layer map a palette edit targets.
enum PaletteMap : uint8
{
	case Normal;
	case Orm;
	case Height;
	case Mask;
}
