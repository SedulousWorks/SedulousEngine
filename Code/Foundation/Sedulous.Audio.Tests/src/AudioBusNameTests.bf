using System;
using Sedulous.Audio;

namespace Sedulous.Audio.Tests;

/// Naming the fixed buses, which is the seam three readers share: applying a layout,
/// validating a cooked one, and addressing a bus by string.
class AudioBusNameTests
{
	[Test]
	public static void EachFixedBusResolvesFromItsName()
	{
		Test.Assert(AudioBusNames.TryParse("Master", let master) && (master == .Master));
		Test.Assert(AudioBusNames.TryParse("Effects", let effects) && (effects == .Effects));
		Test.Assert(AudioBusNames.TryParse("Music", let music) && (music == .Music));
		Test.Assert(AudioBusNames.TryParse("UI", let ui) && (ui == .UI));
	}

	/// CASE INSENSITIVE, because authored data spells them however it likes and a bus that
	/// silently fails to resolve routes the sound somewhere else entirely.
	[Test]
	public static void TheCaseDoesNotMatter()
	{
		Test.Assert(AudioBusNames.TryParse("effects", let lower) && (lower == .Effects));
		Test.Assert(AudioBusNames.TryParse("EFFECTS", let upper) && (upper == .Effects));
		Test.Assert(AudioBusNames.TryParse("EfFeCtS", let mixed) && (mixed == .Effects));
	}

	/// Anything else is NOT a fixed bus, which is what tells a caller to look among the named
	/// ones instead of routing to Master by accident.
	[Test]
	public static void AnythingElseIsNotAFixedBus()
	{
		Test.Assert(!AudioBusNames.TryParse("", let empty));
		Test.Assert(!AudioBusNames.TryParse("Ambience", let custom));
		// A prefix of a real name is not that name.
		Test.Assert(!AudioBusNames.TryParse("mus", let partial));
		// Nor is a name with something after it.
		Test.Assert(!AudioBusNames.TryParse("musicbox", let longer));
	}

	/// The name and the bus round trip, so a layout written out and read back addresses the
	/// same bus.
	[Test]
	public static void ANameAndItsBusRoundTrip()
	{
		let buses = AudioBus[4](.Master, .Effects, .Music, .UI);
		for (let bus in buses)
		{
			Test.Assert(AudioBusNames.TryParse(AudioBusNames.NameOf(bus), let parsed));
			Test.Assert(parsed == bus);
		}
	}
}
