namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;

class PropertyTests
{
	[Test]
	public static void InitialValue()
	{
		let prop = scope Property<float>(42);
		Test.Assert(prop.Value == 42);
	}

	[Test]
	public static void DefaultValue()
	{
		let prop = scope Property<int32>();
		Test.Assert(prop.Value == 0);
	}

	[Test]
	public static void SetValue_FiresChanged()
	{
		let prop = scope Property<float>(0);
		float received = -1;
		prop.Changed.Add(new [&received] (val) => { received = val; });

		prop.Value = 100;
		Test.Assert(received == 100);
	}

	[Test]
	public static void SetValue_SameValue_DoesNotFire()
	{
		let prop = scope Property<int32>(42);
		int fireCount = 0;
		prop.Changed.Add(new [&fireCount] (val) => { fireCount++; });

		prop.Value = 42; // same value
		Test.Assert(fireCount == 0);
	}

	[Test]
	public static void SetValue_DifferentValue_Fires()
	{
		let prop = scope Property<int32>(0);
		int fireCount = 0;
		prop.Changed.Add(new [&fireCount] (val) => { fireCount++; });

		prop.Value = 1;
		prop.Value = 2;
		prop.Value = 3;
		Test.Assert(fireCount == 3);
	}

	[Test]
	public static void SetSilent_DoesNotFire()
	{
		let prop = scope Property<float>(0);
		int fireCount = 0;
		prop.Changed.Add(new [&fireCount] (val) => { fireCount++; });

		prop.SetSilent(100);
		Test.Assert(prop.Value == 100);
		Test.Assert(fireCount == 0);
	}

	[Test]
	public static void BindTo_OneWay()
	{
		let source = scope Property<float>(0);
		let target = scope Property<float>(0);
		source.BindTo(target);

		source.Value = 50;
		Test.Assert(target.Value == 50);

		// Reverse should not propagate back
		target.Value = 99;
		Test.Assert(source.Value == 50);
	}

	[Test]
	public static void BindTwoWay_BothDirections()
	{
		let a = scope Property<int32>(0);
		let b = scope Property<int32>(0);
		a.BindTwoWay(b);

		a.Value = 10;
		Test.Assert(b.Value == 10);

		b.Value = 20;
		Test.Assert(a.Value == 20);
	}

	[Test]
	public static void BindTwoWay_LoopGuard()
	{
		let a = scope Property<int32>(0);
		let b = scope Property<int32>(0);
		a.BindTwoWay(b);

		// Should not infinite loop
		a.Value = 42;
		Test.Assert(a.Value == 42);
		Test.Assert(b.Value == 42);
	}

	[Test]
	public static void Bool_Property()
	{
		let prop = scope Property<bool>(false);
		bool received = false;
		prop.Changed.Add(new [&received] (val) => { received = val; });

		prop.Value = true;
		Test.Assert(received == true);
		Test.Assert(prop.Value == true);
	}
}
