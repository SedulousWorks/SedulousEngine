using System;

namespace Sedulous.Mcp.Reflection.Tests.Beta;

/// A SECOND type named Widget, in another namespace. Its whole reason to exist is that
/// type_info's `namespace` argument has to be able to tell the two apart.
[Reflect(.All), AlwaysInclude(AssumeInstantiated=true, IncludeAllMethods=true)]
class Widget
{
	public float Depth;
}
