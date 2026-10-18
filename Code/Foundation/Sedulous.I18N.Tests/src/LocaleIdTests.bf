using System;
using Sedulous.I18N;

namespace Sedulous.I18N.Tests;

/// Locale ids: their parents, their normal form, and their shape.
class LocaleIdTests
{
	[Test]
	public static void ALocalesParentIsTheIdOneSubtagShorter()
	{
		Test.Assert(LocaleId.Parent("pt-BR") == "pt");
		Test.Assert(LocaleId.Parent("zh-Hans-CN") == "zh-Hans");
		Test.Assert(LocaleId.Parent("en_US") == "en");
		Test.Assert(LocaleId.Parent("en").IsEmpty);
	}

	[Test]
	public static void IdsCompareByTheirNormalForm()
	{
		Test.Assert(LocaleId.Normalize("EN_us", .. scope .()) == "en-us");
		Test.Assert(LocaleId.Normalize("pt-BR", .. scope .()) == "pt-BR");
		Test.Assert(LocaleId.Same("en-US", "en_us"));
		Test.Assert(!LocaleId.Same("en-US", "en-GB"));
	}

	/// The shape, never whether it exists.
	[Test]
	public static void AnIdsShape()
	{
		for (let shaped in StringView[]("en", "fil", "pt-BR", "zh-Hans", "zh-Hans-CN", "es-419", "xx"))
			Test.Assert(LocaleId.IsShaped(shaped), scope $"{shaped}");
		for (let unshaped in StringView[]("", "e", "english", "en-", "en-USA1", "en-US-x", "12"))
			Test.Assert(!LocaleId.IsShaped(unshaped), scope $"{unshaped}");
	}
}
