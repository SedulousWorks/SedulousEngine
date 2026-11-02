using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Pipeline.Importer.Tests;

/// An importer's settings, declared by its options' reflected fields: each labelled by its
/// [DisplayName] (else its name) and found by that label, case and spaces ignored; the base's
/// review selection is none of them.
class ImportSettingsTests
{
	[Reflect(.NonStaticFields | .DefaultConstructor)]
	class CrateOptions : ImportOptions
	{
		[DisplayName("Hollow"), Description("Leaves the inside empty")]
		public bool Hollow = false;
		public bool Lid = true;
		[Hidden]
		public bool Cached = false;
	}

	[Test]
	public static void TheOptionsReflectedFieldsAreTheSettingsFoundByTheirLabels()
	{
		let options = scope CrateOptions();
		let settings = options.GetSettings(.. scope .());
		Test.Assert(settings.Count == 2, "Hollow and Lid; the hidden one and the base's selection are none");
		Test.Assert(ImportOptions.SettingLabel(settings[0], .. scope .()) == "Hollow");
		Test.Assert(ImportOptions.SettingLabel(settings[1], .. scope .()) == "Lid", "no display name: its name");
		Test.Assert(options.HasSettings);

		Test.Assert(options.FindSetting("hol LOW", let found), "case and spaces ignored");
		Test.Assert(found.Name == "Hollow");
		Test.Assert(!options.FindSetting("Cached", ?));
		Test.Assert(!options.FindSetting("Selection", ?));

		let none = scope ImportOptions();
		Test.Assert(!none.HasSettings, "the base declares none");
	}

	[Test]
	public static void SettingsCopyToOptionsOfTheSameTypeAndNotToAnother()
	{
		let from = scope CrateOptions();
		from.Hollow = true;
		from.Lid = false;
		from.Cached = true;
		let to = scope CrateOptions();
		Test.Assert(to.CopySettingsFrom(from));
		Test.Assert(to.Hollow && !to.Lid);
		Test.Assert(!to.Cached, "a hidden field is no setting: it stays");
		let bare = scope ImportOptions();
		Test.Assert(!bare.CopySettingsFrom(from), "another type: nothing changes");
		Test.Assert(to.CopySettingsFrom(to));
	}
}
