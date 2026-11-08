using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Core.Tests;

/// Not reflected: its cases are known only through what its component registers.
enum Lamp : uint8
{
	Off = 0,
	Dim = 3,
	Full = 7
}

/// Not reflected, and held by nothing that registers: registered by hand below.
enum Weather : int32
{
	Rain = -1,
	Sun = 1
}

/// Reflected (its cases are static fields), and held by nothing that registers: its cases come
/// from its reflection.
[Reflect(.StaticFields)]
enum Tide : int32
{
	Low = 0,
	High = 1
}

/// A persisting component holding Lamp alone and as a list's elements.
[SerializableComponent("test.lamppost")]
struct Lamppost
{
	public Lamp Mode = .Off;
	public List<Lamp> Schedule = null;

	public this() {}
}

/// EnumCases: the cases a registration recorded, else the enum's reflection, by name and value.
class EnumCasesTests
{
	private static void Listed(Type enumType, String outText)
	{
		for (let (name, caseValue) in EnumCases.Of(enumType))
			outText.AppendF("{}={} ", name, caseValue);
	}

	/// [SerializableComponent] registers the enums its fields hold, so an enum without
	/// [Reflect] is named in declaration order with its own values.
	[Test]
	public static void AComponentsAttributeRegistersItsEnums()
	{
		let post = Lamppost();
		Test.Assert(post.Mode == .Off, "the component is in the build");
		Test.Assert(EnumCases.IsRegistered(typeof(Lamp)));
		Test.Assert(Listed(typeof(Lamp), .. scope String()) == "Off=0 Dim=3 Full=7 ");
		Test.Assert(EnumCases.NameOf(typeof(Lamp), 7, .. scope String()) == "Full");
		Test.Assert(EnumCases.NameOf(typeof(Lamp), 4, .. scope String()) == "4", "a value no case has is its number");
	}

	/// A registration reads "Name=value" entries, negative values included, and a second one for
	/// the same enum (several types hold it) keeps the first.
	[Test]
	public static void ARegistrationIsReadOnceFromItsEntries()
	{
		Test.Assert(EnumCases.Register(typeof(Weather), "Rain=-1;Sun=1"));
		Test.Assert(EnumCases.Register(typeof(Weather), "Snow=5"));
		Test.Assert(Listed(typeof(Weather), .. scope String()) == "Rain=-1 Sun=1 ");
		Test.Assert(EnumCases.NameOf(typeof(Weather), -1, .. scope String()) == "Rain");
	}

	/// An enum nothing registered falls back to its reflection.
	[Test]
	public static void AnUnregisteredEnumFallsBackToItsReflection()
	{
		Test.Assert(!EnumCases.IsRegistered(typeof(Tide)));
		Test.Assert(Listed(typeof(Tide), .. scope String()) == "Low=0 High=1 ");
		Test.Assert(EnumCases.NameOf(typeof(Tide), 1, .. scope String()) == "High");
	}
}
