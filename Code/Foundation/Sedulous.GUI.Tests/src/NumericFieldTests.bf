namespace Sedulous.GUI.Tests;

using System;

class NumericFieldTests
{
	[Test]
	public static void NumericField_ValueClampingMinMax()
	{
		let nf = scope NumericField();
		nf.Min = 0;
		nf.Max = 100;

		nf.Value = 150;
		Test.Assert(nf.Value == 100);

		nf.Value = -10;
		Test.Assert(nf.Value == 0);

		nf.Value = 50;
		Test.Assert(nf.Value == 50);
	}

	[Test]
	public static void NumericField_StepIncrement()
	{
		let nf = scope NumericField();
		nf.Min = 0;
		nf.Max = 100;
		nf.Step = 5;
		nf.Value = 10;

		nf.Increment();
		Test.Assert(nf.Value == 15);

		nf.Decrement();
		Test.Assert(nf.Value == 10);
	}

	[Test]
	public static void NumericField_StepClamps()
	{
		let nf = scope NumericField();
		nf.Min = 0;
		nf.Max = 10;
		nf.Step = 5;
		nf.Value = 8;

		nf.Increment();
		Test.Assert(nf.Value == 10); // clamped
	}

	[Test]
	public static void NumericField_OnValueChangedFires()
	{
		let nf = scope NumericField();
		nf.Min = 0;
		nf.Max = 100;

		bool fired = false;
		double firedValue = 0;
		nf.OnValueChanged.Add(new [&fired, &firedValue] (field, val) =>
		{
			fired = true;
			firedValue = val;
		});

		nf.Value = 42;
		Test.Assert(fired);
		Test.Assert(firedValue == 42);
	}

	[Test]
	public static void NumericField_DecimalPlacesFormatting()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let nf = new NumericField();
		nf.DecimalPlaces = 2;
		nf.Min = 0;
		nf.Max = 100;
		root.AddView(nf);
		TestSetup.Layout(ctx, root);

		nf.Value = 3.14159;

		// Text should be formatted to 2 decimal places.
		let text = nf.[Friend]mText;
		// Value is clamped to 3.14159, formatted as "3.14"
		Test.Assert(text.Contains('.'));
		let dotIdx = text.IndexOf('.');
		let decimals = text.Length - dotIdx - 1;
		Test.Assert(decimals == 2);
	}

	[Test]
	public static void NumericField_InputFilterRejectsLetters()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let nf = new NumericField();
		nf.Min = 0;
		nf.Max = 100;
		root.AddView(nf);
		TestSetup.Layout(ctx, root);

		// Clear text and type.
		nf.[Friend]mBehavior.HandleKeyDown(.A, .Ctrl); // select all
		nf.[Friend]mBehavior.HandleTextInput('5');
		nf.[Friend]mBehavior.HandleTextInput('a'); // should be rejected
		nf.[Friend]mBehavior.HandleTextInput('3');

		Test.Assert(nf.[Friend]mText == "53");
	}

	[Test]
	public static void NumericField_DefaultValue()
	{
		let nf = scope NumericField();
		Test.Assert(nf.Value == 0);
		Test.Assert(nf.Min == 0);
		Test.Assert(nf.Max == 100);
		Test.Assert(nf.Step == 1);
	}

	[Test]
	public static void NumericField_ShowSpinButtonsDefault()
	{
		let nf = scope NumericField();
		Test.Assert(nf.ShowSpinButtons.Value == true);
	}

}
