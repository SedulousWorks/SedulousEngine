using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.I18N;

namespace Sedulous.I18N.Tests;

/// The string table: texts per locale, plural entries, keys and locales edited, rules and
/// directions, and the payload's round trip.
class StringTableTests
{
	private static void Sample(StringTable t)
	{
		Test.Assert(t.AddLocale("en"));
		Test.Assert(t.AddLocale("he"));
		Test.Assert(t.SetPluralRule("en", "one: n = 1"));
		Test.Assert(t.SetPluralRule("he", "one: n = 1"));
		t.SetDirection("en", .LeftToRight);
		t.SetDirection("he", .RightToLeft);
		Test.Assert(t.Set("menu.play", "en", "Play"));
		Test.Assert(t.Set("menu.play", "he", "שחק"));
		Test.Assert(t.SetPlural("files.count", "en", .One, "{0} file"));
		Test.Assert(t.SetPlural("files.count", "en", .Other, "{0} files"));
		Test.Assert(t.SetPlural("files.count", "he", .Other, "{0} קבצים"));
	}

	/// A missing cell is not an empty string.
	[Test]
	public static void PlainTextsPerLocale()
	{
		let t = scope StringTable();
		Sample(t);
		Test.Assert(t.Text("menu.play", "en") == "Play");
		Test.Assert(t.Set("menu.quit", "en", ""));
		Test.Assert(t.HasText("menu.quit", "en"), "an empty translation");
		Test.Assert(!t.HasText("menu.quit", "he"), "a missing one");
		Test.Assert(t.Text("menu.quit", "he") == null);
		Test.Assert(t.Set("menu.play", "en-GB", "Play"), "a new locale, added");
		Test.Assert(t.HasLocale("en_gb"));
		Test.Assert(!t.Set("menu.play", "not a locale", "x"));
	}

	/// A plural key holds its forms, and it is plural in every locale.
	[Test]
	public static void APluralKeyHoldsItsForms()
	{
		let t = scope StringTable();
		Sample(t);
		Test.Assert(t.IsPlural("files.count"));
		Test.Assert(t.PluralForm("files.count", "en", .One) == "{0} file");
		Test.Assert(t.Text("files.count", "en") == "{0} files", "its other form");
		Test.Assert(!t.Set("files.count", "en", "plain"), "plural stays plural");
		Test.Assert(!t.SetPlural("menu.play", "en", .One, "x"), "plain stays plain");

		// What a locale's rule needs that an entry lacks.
		let heMissing = t.MissingForms("files.count", "he", t.GetPluralRule("he"), .. scope .());
		Test.Assert(heMissing.Count == 1);
		Test.Assert(heMissing[0] == .One);
		Test.Assert(t.MissingForms("files.count", "en", t.GetPluralRule("en"), .. scope .()).IsEmpty);
	}

	/// Keys renamed, every form with them, and removed; locales removed.
	[Test]
	public static void KeysRenamedAndRemovedAndLocalesRemoved()
	{
		let t = scope StringTable();
		Sample(t);
		Test.Assert(t.RenameKey("files.count", "files.total"));
		Test.Assert(!t.HasKey("files.count"));
		Test.Assert(t.PluralForm("files.total", "en", .One) == "{0} file");
		Test.Assert(!t.RenameKey("menu.play", "files.total"), "taken");
		Test.Assert(t.Remove("menu.play"));
		Test.Assert(!t.HasKey("menu.play"));
		Test.Assert(t.RemoveLocale("he"));
		Test.Assert(t.LocaleCount == 1);
		Test.Assert(t.Text("files.total", "en") == "{0} files");
	}

	/// A locale's rule and direction: set, left unset, and refused when the rule does not parse.
	[Test]
	public static void ALocalesRuleAndDirection()
	{
		let t = scope StringTable();
		Sample(t);
		Test.Assert(t.GetDirection("he") == .RightToLeft);
		t.SetDirection("he", .Unset);
		Test.Assert(t.GetDirection("he") == .Unset);

		let error = scope PluralRuleError();
		Test.Assert(!t.SetPluralRule("en", "one: n ==", error));
		Test.Assert(t.GetPluralRule("en") != null);
		Test.Assert(t.GetPluralRule("en").Source == "one: n = 1", "the old rule stays");
		t.ClearPluralRule("en");
		Test.Assert(t.GetPluralRule("en") == null);
		Test.Assert(!t.SetPluralRule("fr", "one: n = 1"), "not the table's locale");
	}

	/// Texts, plural entries, rules and directions survive the payload's round trip.
	[Test]
	public static void TheTableSurvivesThePayloadsRoundTrip()
	{
		let written = scope StringTable();
		Sample(written);
		let stream = scope MemoryStream();
		{
			let ar = scope BinarySerializer(stream, .Write);
			written.Serialize(ar);
			Test.Assert(ar.IsPayloadOk);
		}

		Test.Assert(stream.Seek(0, .Begin) == 0);
		let read = scope StringTable();
		{
			let ar = scope BinarySerializer(stream, .Read);
			read.Serialize(ar);
			Test.Assert(ar.IsPayloadOk);
		}
		Test.Assert(read.LocaleCount == 2);
		Test.Assert(read.Text("menu.play", "he") == "שחק");
		Test.Assert(read.IsPlural("files.count"));
		Test.Assert(read.PluralForm("files.count", "en", .One) == "{0} file");
		Test.Assert(read.GetPluralRule("en") != null);
		Test.Assert(read.GetPluralRule("en").CategoryOf(1) == .One);
		Test.Assert(read.GetDirection("he") == .RightToLeft);
		Test.Assert(read.HasKey("menu.play"), "the index rebuilt");
	}

	/// A payload shaped as a table's, but whose one entry has a cell for one of its two locales:
	/// what a damaged file, or a fuzzer, hands the reader.
	private static void WriteShortEntry(ISerializer ar)
	{
		BeginVersionedPayload(ar, StringTable.TypeId, StringTable.DataVersion);
		var locales = (uint32)2;
		ar.Key("locales");
		ar.BeginArray(ref locales);
		for (let id in StringView[?]("en", "fr"))
		{
			let localeId = scope String(id);
			var hasRule = false;
			let rule = scope String();
			let direction = scope String("unset");
			ar.BeginObject();
			Sedulous.Core.Serialization.Serialize(ar, "id", localeId);
			SerializeValue(ar, "hasRule", ref hasRule);
			Sedulous.Core.Serialization.Serialize(ar, "rule", rule);
			Sedulous.Core.Serialization.Serialize(ar, "direction", direction);
			ar.EndObject();
		}
		ar.EndArray();
		var entries = (uint32)1;
		ar.Key("entries");
		ar.BeginArray(ref entries);
		let key = scope String("menu.play");
		var plural = false;
		ar.BeginObject();
		Sedulous.Core.Serialization.Serialize(ar, "key", key);
		SerializeValue(ar, "plural", ref plural);
		var cells = (uint32)1;
		ar.Key("cells");
		ar.BeginArray(ref cells);
		var present = true;
		let text = scope String("Play");
		uint8 forms = 0;
		ar.BeginObject();
		SerializeValue(ar, "present", ref present);
		Sedulous.Core.Serialization.Serialize(ar, "text", text);
		SerializeValue(ar, "forms", ref forms);
		for (int f < PluralCategory.Count)
		{
			let form = scope String();
			ar.Key(((PluralCategory)f).Name);
			ar.Text(form);
		}
		ar.EndObject();
		ar.EndArray();
		ar.EndObject();
		ar.EndArray();
		EndVersionedPayload(ar);
	}

	/// An entry short of its locales' cells fails the read and leaves the table safe to ask:
	/// the read used to keep the short entry, and a caller that did not check asked a locale
	/// past its cells (found by the GUI lab's string table fuzzer).
	[Test]
	public static void AnEntryShortOfItsLocalesCellsFailsTheReadAndStaysSafe()
	{
		let stream = scope MemoryStream();
		{
			let ar = scope BinarySerializer(stream, .Write);
			WriteShortEntry(ar);
			Test.Assert(ar.IsPayloadOk);
		}
		Test.Assert(stream.Seek(0, .Begin) == 0);
		let read = scope StringTable();
		let ar = scope BinarySerializer(stream, .Read);
		read.Serialize(ar);
		Test.Assert(!ar.IsPayloadOk);
		Test.Assert(read.Text("menu.play", "en") == "Play");
		Test.Assert(read.Text("menu.play", "fr") == null, "the missing cell: missing, not past the end");
	}
}
