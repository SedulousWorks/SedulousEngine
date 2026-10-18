using System;
using Sedulous.I18N;

namespace Sedulous.I18N.Tests;

/// Plural rules in CLDR's integer syntax: parsed once, then evaluated per count.
class PluralRuleTests
{
	[Test]
	public static void EnglishsRuleOneAndOther()
	{
		let rule = scope PluralRule();
		Test.Assert(rule.Parse("one: n = 1"));
		Test.Assert(rule.CategoryOf(0) == .Other);
		Test.Assert(rule.CategoryOf(1) == .One);
		Test.Assert(rule.CategoryOf(2) == .Other);
		Test.Assert(rule.Uses(.One));
		Test.Assert(rule.Uses(.Other));
		Test.Assert(!rule.Uses(.Few));
	}

	/// Russian's rule, as data.
	[Test]
	public static void ARuleWithModuloRangesAndOr()
	{
		let rule = scope PluralRule();
		Test.Assert(rule.Parse("one: n % 10 = 1 and n % 100 != 11; "
			+ "few: n % 10 = 2..4 and n % 100 != 12..14; "
			+ "many: n % 10 = 0 or n % 10 = 5..9 or n % 100 = 11..14; "
			+ "other:"));
		Test.Assert(rule.CategoryOf(1) == .One);
		Test.Assert(rule.CategoryOf(21) == .One);
		Test.Assert(rule.CategoryOf(11) == .Many);
		Test.Assert(rule.CategoryOf(2) == .Few);
		Test.Assert(rule.CategoryOf(22) == .Few);
		Test.Assert(rule.CategoryOf(12) == .Many);
		Test.Assert(rule.CategoryOf(5) == .Many);
		Test.Assert(rule.CategoryOf(25) == .Many);
		Test.Assert(rule.CategoryOf(-1) == .One, "a negative count counts as its magnitude");
	}

	[Test]
	public static void AnEmptyRuleCountsEverythingAsOtherAndAListOfValuesAndRanges()
	{
		let none = scope PluralRule();
		Test.Assert(none.Parse(""));
		Test.Assert(none.CategoryOf(1) == .Other);

		let list = scope PluralRule();
		Test.Assert(list.Parse("few: n = 3, 5..7, 10"));
		Test.Assert(list.CategoryOf(3) == .Few);
		Test.Assert(list.CategoryOf(6) == .Few);
		Test.Assert(list.CategoryOf(10) == .Few);
		Test.Assert(list.CategoryOf(4) == .Other);
	}

	/// Refused with where, and the old rule stays.
	[Test]
	public static void ARuleThatDoesNotParseIsRefused()
	{
		let rule = scope PluralRule();
		Test.Assert(rule.Parse("one: n = 1"));
		let error = scope PluralRuleError();
		Test.Assert(!rule.Parse("one: n == 1", error));
		Test.Assert(error.Position == 8, "the second =, where a number was due");
		Test.Assert(!rule.Parse("some: n = 1", error));
		Test.Assert(error.Position == 0);
		Test.Assert(!rule.Parse("one: x = 1", error));
		Test.Assert(!rule.Parse("one: n = 4..2", error));
		Test.Assert(!rule.Parse("one: n = 1; one: n = 2", error));
		Test.Assert(!rule.Parse("one: n % 0 = 1", error));
		Test.Assert(rule.Source == "one: n = 1", "unchanged");
		Test.Assert(rule.CategoryOf(1) == .One);
	}
}
