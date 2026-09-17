namespace Sedulous.Shell.Web;

/// What every emscripten_* HTML5 entry point returns. Zero is success and the failures are
/// NEGATIVE, so a caller checks against Success rather than for non-zero.
enum EmscriptenResult : int32
{
	case Success = 0;
	case Deferred = 1;
	case NotSupported = -1;
	case FailedNotDeferred = -2;
	case InvalidTarget = -3;
	case UnknownTarget = -4;
	case InvalidParam = -5;
	case Failed = -6;
	case NoData = -7;
	case TimedOut = -8;
}
