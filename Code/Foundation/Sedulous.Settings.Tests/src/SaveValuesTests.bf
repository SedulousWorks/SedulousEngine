using System;
using System.Collections;
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
			values.SetFloats("ghost", scope float[](1.5f, -2.25f, 0.0f, 1e6f));
			Test.Assert(store.Save(stream, factory) case .Ok);
		}
		Test.Assert(stream.Seek(0, .Begin) == 0);
		let store = scope Settings();
		Test.Assert(store.Load(stream, factory) case .Ok);
		let values = store.Find<SaveValues>();
		Test.Assert(values != null);
		Test.Assert(values.Count == 5);
		Test.Assert(values.GetInt("coins", 0) == 37);
		Test.Assert(values.GetFloat("best.time", 0.0f) == 62.25f);
		Test.Assert(values.GetBool("won", false));
		Test.Assert(values.GetText("last.level", "") == "Level 3");
		let ghost = scope List<float>();
		Test.Assert(values.GetFloats("ghost", ghost));
		Test.Assert((ghost.Count == 4) && (ghost[0] == 1.5f) && (ghost[1] == -2.25f) && (ghost[2] == 0.0f) && (ghost[3] == 1e6f));
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

		store.Section<SaveValues>().SetFloats("ghost", scope float[](2.0f));
		let again = scope MemoryStream();
		Test.Assert(store.Save(again, factory) case .Ok);
		Test.Assert(scope String((char8*)again.Bytes.Ptr, again.Bytes.Length).Contains(">floats<"));
	}

	/// Snowline's ghost is a recorded run, a few thousand numbers: a list is a value of its own
	/// kind, set and read whole.
	[Test]
	public static void AListOfNumbersIsASaveValueOfItsOwnKind()
	{
		let values = scope SaveValues();
		let run = scope float[](0.0f, 1.0f, 2.5f);
		Test.Assert(values.SetFloats("ghost", run));
		Test.Assert(!values.SetFloats("ghost", run), "the same list is no change");
		let other = scope float[](0.0f, 1.0f, 2.75f);
		Test.Assert(values.SetFloats("ghost", other), "one number differs");
		Test.Assert(values.SetFloats("ghost", Span<float>(other, 0, 2)), "a shorter list");
		let read = scope List<float>();
		Test.Assert(values.GetFloats("ghost", read));
		Test.Assert((read.Count == 2) && (read[1] == 1.0f));

		// Absent, or another kind: false and an empty list; and the list is not a number to GetFloat.
		read.Add(9.0f);
		Test.Assert(!values.GetFloats("missing", read) && read.IsEmpty);
		values.SetInt("best", 3);
		Test.Assert(!values.GetFloats("best", read) && read.IsEmpty);
		Test.Assert(values.GetFloat("ghost", -1.0f) == -1.0f);
		// An empty list is a value too.
		Test.Assert(values.SetFloats("empty", Span<float>()));
		Test.Assert(values.Has("empty") && values.GetFloats("empty", read) && read.IsEmpty);
	}

	/// A newer build's kind failed the whole section, so its save reset an older build's: the
	/// entry is skipped and the rest reads (exact in XML, a save file's format).
	[Test]
	public static void ASaveValueOfAKindThisBuildDoesNotKnowIsSkippedTheRestRead()
	{
		SaveValues.Register();
		let factory = XmlSerializerFactory();
		defer delete factory;
		let store = scope Settings();
		store.Section<SaveValues>().SetInt("a.before", 1);
		store.Section<SaveValues>().SetText("m.marker", "zzzz");
		store.Section<SaveValues>().SetInt("z.after", 3);
		let written = scope MemoryStream();
		Test.Assert(store.Save(written, factory) case .Ok);
		let text = scope String((char8*)written.Bytes.Ptr, written.Bytes.Length);
		// A newer build's kind in place of the text one, with a value this build cannot read as text.
		Test.Assert(text.Contains(">text<"));
		text.Replace(">text<", ">sound<");

		let edited = scope MemoryStream();
		edited.Write(Span<uint8>((uint8*)text.Ptr, text.Length));
		Test.Assert(edited.Seek(0, .Begin) == 0);
		let read = scope Settings();
		Test.Assert(read.Load(edited, factory) case .Ok);
		let values = read.Find<SaveValues>();
		Test.Assert(values != null);
		Test.Assert(values.Count == 2);
		Test.Assert(values.GetInt("a.before", 0) == 1);
		Test.Assert(values.GetInt("z.after", 0) == 3);
		Test.Assert(!values.Has("m.marker"));
	}
}
