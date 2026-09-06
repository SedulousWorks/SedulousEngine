using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Settings;
using Sedulous.Xml.Serialization;

namespace Sedulous.Settings.Tests;

/// The typed settings store. Both backends are exercised, because the store's whole point
/// is that it is not tied to one, and the two disagree in exactly the place that matters:
/// a text backend describes its own structure, a binary one does not.
class SettingsTests
{
	private static SerializerFactory Binary() => new (stream, mode) => new BinarySerializerContext(stream, mode);
	private static SerializerFactory Xml() => XmlSerializerFactory();

	[Test]
	public static void AFreshSectionReadsItsDeclaredDefaults()
	{
		TestSections.RegisterAll();
		let settings = scope Settings();

		Test.Assert(settings.SectionCount == 0);
		Test.Assert(settings.Find<GameSettings>() == null, "peeking does not create it");

		let section = settings.Section<GameSettings>();
		Test.Assert(section.Profile == "default");
		Test.Assert(section.Locale == "en");
		Test.Assert(settings.SectionCount == 1);
		Test.Assert(settings.Find<GameSettings>() != null);
		Test.Assert(settings.Find<GameSettings>() === section, "the same instance, not a copy");
	}

	/// Accessing twice returns the SAME object, since a caller holds the reference and
	/// writes through it.
	[Test]
	public static void AccessingASectionTwiceReturnsTheSameObject()
	{
		TestSections.RegisterAll();
		let settings = scope Settings();

		let first = settings.Section<GameSettings>();
		first.Profile.Set("changed");
		let second = settings.Section<GameSettings>();

		Test.Assert(first === second);
		Test.Assert(second.Profile == "changed");
		Test.Assert(settings.SectionCount == 1, "it was not created twice");
	}

	private static void RoundTrip(SerializerFactory factory)
	{
		TestSections.RegisterAll();
		let stream = scope MemoryStream();

		{
			let source = scope Settings();
			source.Section<GameSettings>().Profile.Set("robert");
			source.Section<GameSettings>().Locale.Set("en-GB");
			source.Section<SectionA>().A = 17;
			Test.Assert(source.Save(stream, factory) case .Ok);
		}

		Test.Assert(stream.Seek(0, .Begin) == 0);
		let target = scope Settings();
		Test.Assert(target.Load(stream, factory) case .Ok);

		Test.Assert(target.SectionCount == 2);
		Test.Assert(target.UnknownSectionCount == 0);
		Test.Assert(target.Find<GameSettings>().Profile == "robert");
		Test.Assert(target.Find<GameSettings>().Locale == "en-GB");
		Test.Assert(target.Find<SectionA>().A == 17);
	}

	[Test]
	public static void SectionsRoundTripThroughTheBinaryBackend()
	{
		let factory = Binary();
		defer delete factory;
		RoundTrip(factory);
	}

	[Test]
	public static void SectionsRoundTripThroughTheTextBackend()
	{
		let factory = Xml();
		defer delete factory;
		RoundTrip(factory);
	}

	/// Loading REPLACES a live section rather than merging into it, so a stale field from
	/// before the load cannot survive underneath the loaded values.
	[Test]
	public static void LoadingReplacesALiveSection()
	{
		TestSections.RegisterAll();
		let factory = Binary();
		defer delete factory;

		let stream = scope MemoryStream();
		{
			let source = scope Settings();
			source.Section<GameSettings>().Profile.Set("stored");
			source.Section<GameSettings>().Locale.Set("fr");
			Test.Assert(source.Save(stream, factory) case .Ok);
		}

		let target = scope Settings();
		target.Section<GameSettings>().Profile.Set("live");
		target.Section<GameSettings>().Locale.Set("de");

		Test.Assert(stream.Seek(0, .Begin) == 0);
		Test.Assert(target.Load(stream, factory) case .Ok);

		Test.Assert(target.SectionCount == 1, "replaced, not added alongside");
		Test.Assert(target.Find<GameSettings>().Profile == "stored");
		Test.Assert(target.Find<GameSettings>().Locale == "fr", "no field survived from before the load");
	}

	[Test]
	public static void MarkChangedNamesTheSectionThatChanged()
	{
		TestSections.RegisterAll();
		let settings = scope Settings();
		let seen = scope String();
		var fired = 0;

		settings.OnChanged.Add(new [&] (name) => { seen.Set(name); fired++; });
		defer settings.OnChanged.Dispose();

		settings.Section<GameSettings>().Profile.Set("x");
		Test.Assert(fired == 0, "the store cannot see a write through the reference it handed out");

		settings.MarkChanged<GameSettings>();
		Test.Assert(fired == 1);
		Test.Assert(seen == "Sedulous.Settings.Tests.GameSettings", scope $"got '{seen}'");
	}

	/// A positional stream carries a format version, and one that does not match is
	/// refused rather than misparsed into plausible nonsense.
	[Test]
	public static void ABinaryStreamOfTheWrongVersionIsRefused()
	{
		TestSections.RegisterAll();
		let factory = Binary();
		defer delete factory;

		let stream = scope MemoryStream();
		{
			let source = scope Settings();
			source.Section<SectionA>().A = 5;
			Test.Assert(source.Save(stream, factory) case .Ok);
		}

		// The version is the first thing written, so corrupting it is a one word edit.
		Test.Assert(stream.Seek(0, .Begin) == 0);
		uint32 wrong = Settings.FormatVersion + 1;
		stream.Write(.((uint8*)&wrong, 4));

		Test.Assert(stream.Seek(0, .Begin) == 0);
		let target = scope Settings();
		Test.Assert(target.Load(stream, factory) case .Err, "a stream from another format version");
	}

	/// A text backend describes its own structure, so it carries no version stamp and a
	/// file written before the stamp existed still loads.
	[Test]
	public static void TheTextBackendCarriesNoVersionStamp()
	{
		TestSections.RegisterAll();
		let factory = Xml();
		defer delete factory;

		let stream = scope MemoryStream();
		{
			let source = scope Settings();
			source.Section<SectionA>().A = 9;
			Test.Assert(source.Save(stream, factory) case .Ok);
		}

		let text = scope String();
		text.Append((char8*)stream.Bytes.Ptr, stream.Bytes.Length);
		Test.Assert(!text.Contains("formatVersion"), scope $"the text backend stamped a version:\n{text}");
	}
}
