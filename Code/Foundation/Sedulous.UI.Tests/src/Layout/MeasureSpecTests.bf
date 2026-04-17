namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;

class MeasureSpecTests
{
	[Test]
	public static void Exactly_ReturnsSize()
	{
		let spec = MeasureSpec.Exactly(100);
		Test.Assert(spec.Resolve(50) == 100);
		Test.Assert(spec.Resolve(200) == 100);
	}

	[Test]
	public static void AtMost_ClampsToSize()
	{
		let spec = MeasureSpec.AtMost(100);
		Test.Assert(spec.Resolve(50) == 50);
		Test.Assert(spec.Resolve(200) == 100);
	}

	[Test]
	public static void Unspecified_ReturnsDesired()
	{
		let spec = MeasureSpec.Unspecified();
		Test.Assert(spec.Resolve(50) == 50);
		Test.Assert(spec.Resolve(200) == 200);
	}
}
