namespace Sedulous.VG.SVG;

/// What kind of element a parsed node is.
enum SVGElementType
{
	case Path;
	case Group;
	case Rectangle;
	case Circle;
	case Ellipse;
	case Line;
	case Polygon;
	case Polyline;
	case Text;
}
