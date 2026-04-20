namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

class PanelPaddingTests
{
	[Test]
	public static void EffectivePadding_MaxMerge()
	{
		let panel = scope Panel();
		panel.Padding = .(4);

		// Drawable contributes larger padding.
		let nsd = scope NineSliceDrawable(null, .(10, 10, 10, 10));
		panel.Background = nsd;

		let eff = panel.EffectivePadding;
		// max(4, 10) = 10 on each side.
		Test.Assert(eff.Left == 10);
		Test.Assert(eff.Top == 10);
		Test.Assert(eff.Right == 10);
		Test.Assert(eff.Bottom == 10);

		panel.Background = null; // don't let scope delete it - it's scope-allocated
	}

	[Test]
	public static void EffectivePadding_ExplicitLarger()
	{
		let panel = scope Panel();
		panel.Padding = .(20);

		let nsd = scope NineSliceDrawable(null, .(8, 8, 8, 8));
		panel.Background = nsd;

		let eff = panel.EffectivePadding;
		// max(20, 8) = 20 on each side.
		Test.Assert(eff.Left == 20);

		panel.Background = null;
	}

	[Test]
	public static void EffectivePadding_NoDrawable()
	{
		let panel = scope Panel();
		panel.Padding = .(6);

		let eff = panel.EffectivePadding;
		Test.Assert(eff.Left == 6);
		Test.Assert(eff.Top == 6);
	}
}
