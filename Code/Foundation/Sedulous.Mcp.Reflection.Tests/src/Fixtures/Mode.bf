using System;

namespace Sedulous.Mcp.Reflection.Tests.Alpha;

/// An enum with explicit values, so type_info has a value list to report.
[Reflect(.All)]
enum Mode
{
	Off = 0,
	Idle = 3,
	Running = 7
}
