namespace Sedulous.Animation.Resource;

/// Which property a cooked track drives. The VALUE is the wire, so a new kind is appended.
enum TrackKind : uint8
{
	case Position = 0;
	case Rotation = 1;
	case Scale = 2;
}
