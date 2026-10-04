using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Settings;
using Sedulous.Xml.Serialization;

namespace Sedulous.Settings.Tests;

/// A game's keyed saved values: typed by key, kept in key order, and a section like any other.
class SaveValuesTests
{
	[Test]
	public static void SaveValuesAnswerWhatWasSetAFallbackOtherwiseAndReportChanges()
	{
		let values = scope SaveValues();
		Test.Assert(values.SetInt("best.level2", 4210));
		Test.Assert(!values.SetInt("best.level2", 4210), "the same value is no change");
		Test.Assert(values.SetInt("best.level2", 4000));
		Test.Assert(values.SetFloat("time.level2", 41.5f));
		Test.Assert(values.SetBool("unlocked.level3", true));
		Test.Assert(values.SetText("name", "Hopper"));
		Test.Assert(values.SetBool("zero", false), "a new key is a change even at the default");

		Test.Assert(values.GetInt("best.level2", 0) == 4000);
		Test.Assert(values.GetFloat("time.level2", 0.0f) == 41.5f);
		Test.Assert(values.GetBool("unlocked.level3", false));
		Test.Assert(values.GetText("name", "") == "Hopper");

		// Absent, or read as another kind: the fallback. An int still reads as a float.
		Test.Assert(values.GetInt("missing", -1) == -1);
		Test.Assert(values.GetInt("time.level2", -1) == -1);
		Test.Assert(values.GetText("best.level2", "none") == "none");
		Test.Assert(values.GetFloat("best.level2", 0.0f) == 4000.0f);

		// A key written as another kind takes the new kind.
		Test.Assert(values.SetText("best.level2", "gold"));
		Test.Assert(values.GetText("best.level2", "") == "gold");
		Test.Assert(values.GetInt("best.level2", -1) == -1);

		// Kept in key order, whatever order they were set in.
		Test.Assert(values.Count == 5);
		for (int i = 1; i < values.Count; i++)
			Test.Assert(StringView.Compare(values[i - 1].Key, values[i].Key) < 0);

		Test.Assert(values.Remove("name"));
		Test.Assert(!values.Remove("name"));
		Test.Assert(!values.Has("name"));
		Test.Assert(values.Clear());
		Test.Assert(!values.Clear());
		Test.Assert(values.Count == 0);
	}

	private static void RoundTrip(SerializerFactory factory)
	{
		SaveValues.Register();
		let stream = scope MemoryStream();
		{
			let store = scope Settings();
			let values = store.Section<SaveValues>();
			values.SetInt("coins", 37);
			values.SetFloat("best.time", 62.25f);
			values.SetBool("won", true);
			values.SetText("last.level", "Level 3");
			Test.Assert(store.Save(stream, factory) case .Ok);
		}
		Test.Assert(stream.Seek(0, .Begin) == 0);
		let store = scope Settings();
		Test.Assert(store.Load(stream, factory) case .Ok);
		let values = store.Find<SaveValues>();
		Test.Assert(values != null);
		Test.Assert(values.Count == 4);
		Test.Assert(values.GetInt("coins", 0) == 37);
		Test.Assert(values.GetFloat("best.time", 0.0f) == 62.25f);
		Test.Assert(values.GetBool("won", false));
		Test.Assert(values.GetText("last.level", "") == "Level 3");
	}

	[Test]
	public static void SaveValuesRoundTripAsASectionThroughTheBinaryBackend()
	{
		SerializerFactory factory = new (stream, mode) => new BinarySerializerContext(stream, mode);
		defer delete factory;
		RoundTrip(factory);
	}

	[Test]
	public static void SaveValuesRoundTripAsASectionThroughTheTextBackendKindsWrittenByName()
	{
		let factory = XmlSerializerFactory();
		defer delete factory;
		RoundTrip(factory);

		let store = scope Settings();
		store.Section<SaveValues>().SetFloat("best.time", 1.5f);
		let stream = scope MemoryStream();
		Test.Assert(store.Save(stream, factory) case .Ok);
		let text = scope String((char8*)stream.Bytes.Ptr, stream.Bytes.Length);
		Test.Assert(text.Contains(">float<"));
		Test.Assert(text.Contains("best.time"));
	}
}
