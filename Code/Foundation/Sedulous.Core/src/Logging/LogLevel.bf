using Sedulous.Core;
namespace Sedulous.Core.Logging;

/// Log severity, ordered so a minimum level filters out everything below it.
///
/// None is the sentinel that filters everything, and sits at the top of the range so the
/// comparison needs no special case.
[Scriptable(.AllPublic)]
enum LogLevel : uint8
{
	Trace = 0,
	Debug = 1,
	Information = 2,
	Warning = 3,
	Error = 4,
	Critical = 5,
	None = uint8.MaxValue,
}
