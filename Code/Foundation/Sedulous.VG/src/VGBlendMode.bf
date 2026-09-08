namespace Sedulous.VG;

/// How a draw command combines with what is already there.
enum VGBlendMode
{
	case Normal;
	case Additive;
	case Multiply;
	case Screen;
}
