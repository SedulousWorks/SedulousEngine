using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Thickness: a box's padding, margins and borders, per side.
class ThicknessTests
{
	[Test]
	public static void DefaultsAndConstructors()
	{
		Test.Assert(Thickness().IsZero);

		let all = Thickness(4.0f);
		Test.Assert(all.Left == 4.0f);
		Test.Assert(all.Bottom == 4.0f);
		Test.Assert(all.TotalHorizontal == 8.0f);
		Test.Assert(all.TotalVertical == 8.0f);

		let hv = Thickness(2.0f, 6.0f);
		Test.Assert(hv.Left == 2.0f);
		Test.Assert(hv.Right == 2.0f);
		Test.Assert(hv.Top == 6.0f);
		Test.Assert(hv.Bottom == 6.0f);

		let each = Thickness(1.0f, 2.0f, 3.0f, 4.0f);
		Test.Assert(each.Left == 1.0f);
		Test.Assert(each.Top == 2.0f);
		Test.Assert(each.Right == 3.0f);
		Test.Assert(each.Bottom == 4.0f);
		Test.Assert(!each.IsZero);
		Test.Assert(each == Thickness(1.0f, 2.0f, 3.0f, 4.0f));
	}
}
