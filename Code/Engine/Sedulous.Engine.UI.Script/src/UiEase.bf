using Sedulous.Core;

namespace Sedulous.Engine.UI.Script;

/// How a scripted tween moves through its time (`label.ScaleTo(1.4f, 0.2f, Ease.OutBack)`).
/// InOut, the default, starts and ends gently; Out arrives gently; OutBack overshoots and
/// settles; OutBounce and OutElastic bounce and spring into place.
[Scriptable(.AllPublic)]
enum Ease : uint8
{
	case Linear;
	case In;
	case Out;
	case InOut;
	case OutBack;
	case OutBounce;
	case OutElastic;
}
