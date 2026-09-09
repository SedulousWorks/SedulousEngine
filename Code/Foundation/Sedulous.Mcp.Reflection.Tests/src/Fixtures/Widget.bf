using System;

namespace Sedulous.Mcp.Reflection.Tests.Alpha;

/// A reflected fixture with fields, methods and a base, so type_info has something real to
/// describe. Reflection in Beef is opt-in per type, which is why the attribute is here and not
/// a workspace setting: a test that relies on a global switch passes for the wrong reason.
[Reflect(.All), AlwaysInclude(AssumeInstantiated=true, IncludeAllMethods=true)]
class Widget
{
	public int32 Width;
	public int32 Height;
	/// Also what reifies Mode: AlwaysInclude is not allowed on an enum, so the enum reaches the
	/// type table by being referenced from a type that is included.
	public Mode State;

	public int32 Area()
	{
		return Width * Height;
	}

	public void Resize(int32 width, int32 height)
	{
		Width = width;
		Height = height;
	}
}
