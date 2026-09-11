using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// The toolbar and its three item kinds.
class ToolbarTests
{
	[Test]
	public static void ItemsAreAddedAsChildren()
	{
		let bar = new Toolbar();
		defer bar.ReleaseRef();

		Test.Assert(bar.Direction == .Horizontal);

		let button = bar.AddButton("File");
		let separator = bar.AddSeparator();
		let toggle = bar.AddToggle("Bold");

		Test.Assert(button != null);
		Test.Assert(separator != null);
		Test.Assert(toggle != null);
		Test.Assert(bar.ChildCount == 3);
	}

	[Test]
	public static void AToggleRoundTripsAndFiresOnlyOnAChange()
	{
		let bar = new Toolbar();
		defer bar.ReleaseRef();

		let toggle = bar.AddToggle("Bold");

		var fired = 0;
		var lastValue = false;
		toggle.OnCheckedChanged.Add(new [&](sender, value) =>
			{
				fired++;
				lastValue = value;
			});

		Test.Assert(!toggle.IsChecked);
		toggle.IsChecked = true;
		Test.Assert(toggle.IsChecked);
		Test.Assert(fired == 1);
		Test.Assert(lastValue);

		// Writing the same value again changes nothing, so it reports nothing.
		toggle.IsChecked = true;
		Test.Assert(fired == 1);
	}

	[Test]
	public static void AButtonsClickEventIsWired()
	{
		let bar = new Toolbar();
		defer bar.ReleaseRef();

		let button = bar.AddButton("Save");
		var clicked = false;
		button.OnClick.Add(new [&](sender) => { clicked = true; });

		button.OnClick(button);
		Test.Assert(clicked);
	}

	[Test]
	public static void SetTextAndSetIconAreReadBack()
	{
		let button = new ToolbarButton();
		defer button.ReleaseRef();

		button.SetText("Save");
		Test.Assert(button.Text == "Save");

		// A second icon REPLACES the first rather than leaking it.
		button.SetIcon(new (ctx, rect) => {});
		button.SetIcon(new (ctx, rect) => {});
	}
}
