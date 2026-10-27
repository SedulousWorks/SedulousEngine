using Sedulous.Core.Logging;

namespace Sedulous.Editor.App;

/// The Console's levels, a chip each: Info holds the trace, debug and information lines, Error
/// holds the critical ones.
enum LogBucket : uint8
{
	case Info;
	case Warning;
	case Error;

	public const int Count = 3;

	public static LogBucket Of(LogLevel level)
	{
		switch (level)
		{
		case .Trace, .Debug, .Information: return .Info;
		case .Warning: return .Warning;
		default: return .Error;
		}
	}
}
