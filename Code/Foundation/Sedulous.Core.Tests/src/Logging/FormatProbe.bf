using System;

namespace Sedulous.Core.Tests;

/// An argument that counts how often it is asked to render itself.
///
/// This is how a test can tell that a filtered-out log never formatted its message: the
/// probe reaches Log as an argument either way, but only a message that is actually
/// built asks it for its text.
class FormatProbe
{
	public static int sRenderCount = 0;

	public static void Reset() => sRenderCount = 0;

	public override void ToString(String strBuffer)
	{
		sRenderCount++;
		strBuffer.Append("probe");
	}
}
