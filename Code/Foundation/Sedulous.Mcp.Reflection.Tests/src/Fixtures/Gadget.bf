using System;
using Sedulous.Mcp.Reflection.Tests.Alpha;

namespace Sedulous.Mcp.Reflection.Tests.Alpha;

/// Derives from Widget, so type_info has a base to report.
[Reflect(.All), AlwaysInclude(AssumeInstantiated=true, IncludeAllMethods=true)]
class Gadget : Widget
{
	public bool Enabled;
}
