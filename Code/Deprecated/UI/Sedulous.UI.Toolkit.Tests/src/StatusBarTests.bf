using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// The status strip: its defaults, and that the default label is created once and stays first.
class StatusBarTests
{
	[Test]
	public static void TheDefaultsAreAHorizontalStrip()
	{
		let bar = new StatusBar();
		defer bar.ReleaseRef();

		Test.Assert(bar.Direction == .Horizontal);
	}

	[Test]
	public static void SetTextAndAddSectionEachAddOneChild()
	{
		let bar = new StatusBar();
		defer bar.ReleaseRef();

		bar.SetText("Ready");
		Test.Assert(bar.ChildCount == 1);

		let section = bar.AddSection("Ln 1, Col 1");
		Test.Assert(section != null);
		Test.Assert(bar.ChildCount == 2);
	}

	/// The default label is built on first use and REUSED after, so repeated status updates do
	/// not stack up labels.
	[Test]
	public static void SetTextReusesItsLabel()
	{
		let bar = new StatusBar();
		defer bar.ReleaseRef();

		bar.SetText("Ready");
		bar.SetText("Saving");
		bar.SetText("Saved");
		Test.Assert(bar.ChildCount == 1);
	}

	/// A REGRESSION GATE: the default label is INSERTED at the front, so a status bar that was
	/// given sections before its first SetText still reads left to right.
	[Test]
	public static void TheDefaultLabelStaysLeftmost()
	{
		let bar = new StatusBar();
		defer bar.ReleaseRef();

		let section = bar.AddSection("UTF-8");
		bar.SetText("Ready");

		Test.Assert(bar.ChildCount == 2);
		Test.Assert(bar.GetChildAt(0) != section);
		Test.Assert(bar.GetChildAt(1) == section);
	}
}
