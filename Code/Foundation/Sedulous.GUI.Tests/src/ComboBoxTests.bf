namespace Sedulous.GUI.Tests;

using System;

class ComboBoxTests
{
	[Test]
	public static void AddItem_ReturnsIndex()
	{
		let cb = scope ComboBox();
		Test.Assert(cb.AddItem("A") == 0);
		Test.Assert(cb.AddItem("B") == 1);
		Test.Assert(cb.AddItem("C") == 2);
		Test.Assert(cb.ItemCount == 3);
	}

	[Test]
	public static void RemoveItem_DecreasesCount()
	{
		let cb = scope ComboBox();
		cb.AddItem("A");
		cb.AddItem("B");
		cb.AddItem("C");

		cb.RemoveItem(1);
		Test.Assert(cb.ItemCount == 2);
	}

	[Test]
	public static void ClearItems_EmptiesList()
	{
		let cb = scope ComboBox();
		cb.AddItem("A");
		cb.AddItem("B");
		cb.ClearItems();
		Test.Assert(cb.ItemCount == 0);
		Test.Assert(cb.SelectedIndex == -1);
	}

	[Test]
	public static void SelectedIndex_Clamping()
	{
		let cb = scope ComboBox();
		cb.AddItem("A");
		cb.AddItem("B");

		cb.SelectedIndex = 5;
		Test.Assert(cb.SelectedIndex == 1); // clamped to max

		cb.SelectedIndex = -5;
		Test.Assert(cb.SelectedIndex == -1); // clamped to -1
	}

	[Test]
	public static void SelectedText_ReturnsCorrect()
	{
		let cb = scope ComboBox();
		cb.AddItem("Alpha");
		cb.AddItem("Beta");

		Test.Assert(cb.SelectedText == ""); // no selection

		cb.SelectedIndex = 1;
		Test.Assert(cb.SelectedText == "Beta");
	}

	[Test]
	public static void OnSelectionChanged_Fires()
	{
		let cb = scope ComboBox();
		cb.AddItem("A");
		cb.AddItem("B");

		bool fired = false;
		int firedIndex = -1;
		cb.OnSelectionChanged.Add(new [&fired, &firedIndex] (c, idx) =>
		{
			fired = true;
			firedIndex = idx;
		});

		cb.SelectedIndex = 1;
		Test.Assert(fired);
		Test.Assert(firedIndex == 1);
	}

	[Test]
	public static void IsFocusable()
	{
		let cb = scope ComboBox();
		Test.Assert(cb.IsFocusable);
		Test.Assert(cb.IsTabStop);
	}

	[Test]
	public static void DefaultState_NoSelection()
	{
		let cb = scope ComboBox();
		Test.Assert(cb.SelectedIndex == -1);
		Test.Assert(cb.SelectedText == "");
		Test.Assert(!cb.IsOpen);
		Test.Assert(cb.ItemCount == 0);
	}
}
