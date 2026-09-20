using Sedulous.Core.Logging;

namespace Sedulous.Editor.App;

/// The Console's display buckets: Trace and Debug fold into Debug, Error and Critical into
/// Error.
enum LogBucket : uint8
{
	case Debug;
	case Info;
	case Warning;
	case Error;

	public const int Count = 4;

	public static LogBucket Of(LogLevel level)
	{
		switch (level)
		{
		case .Trace, .Debug: return .Debug;
		case .Information: return .Info;
		case .Warning: return .Warning;
		default: return .Error;
		}
	}
}
