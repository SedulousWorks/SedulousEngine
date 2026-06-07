namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;

class ViewIdTests
{
	[Test]
	public static void Create_ReturnsValidId()
	{
		let id = ViewId.Create();
		Test.Assert(id.IsValid);
		Test.Assert(id.RawValue > 0);
	}

	[Test]
	public static void Create_ReturnsUniqueIds()
	{
		let a = ViewId.Create();
		let b = ViewId.Create();
		Test.Assert(a != b);
	}

	[Test]
	public static void Invalid_IsNotValid()
	{
		let id = ViewId.Invalid;
		Test.Assert(!id.IsValid);
		Test.Assert(id.RawValue == 0);
	}

	[Test]
	public static void Equality_SameValue()
	{
		let a = ViewId.Create();
		var b = a;
		Test.Assert(a == b);
		Test.Assert(a.Equals(b));
	}

	[Test]
	public static void Inequality_DifferentValues()
	{
		let a = ViewId.Create();
		let b = ViewId.Create();
		Test.Assert(a != b);
		Test.Assert(!a.Equals(b));
	}

	[Test]
	public static void GetHashCode_SameForEqual()
	{
		let a = ViewId.Create();
		var b = a;
		Test.Assert(a.GetHashCode() == b.GetHashCode());
	}

	[Test]
	public static void ToString_ContainsValue()
	{
		let id = ViewId.Create();
		let str = scope String();
		id.ToString(str);
		Test.Assert(str.Contains("ViewId("));
	}
}
