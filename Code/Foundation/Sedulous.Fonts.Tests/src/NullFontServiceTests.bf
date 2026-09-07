using System;
using Sedulous.Fonts;

namespace Sedulous.Fonts.Tests;

/// The service that has no fonts.
class NullFontServiceTests
{
	/// Every answer is null, which is exactly what a real service returns for a font it
	/// cannot load: code that survives this survives the real failure.
	[Test]
	public static void EveryLookupAnswersNothing()
	{
		let service = scope NullFontService();

		Test.Assert(service.GetFont(16.0f) == null);
		Test.Assert(service.GetFont("Roboto", 16.0f) == null);
		Test.Assert(service.GetAtlasTexture((CachedFont)null) == null);
		Test.Assert(service.GetAtlasTexture("Roboto", 16.0f) == null);

		service.ReleaseFont(null); // Must not trap.

		let family = scope String();
		service.GetDefaultFontFamily(family);
		Test.Assert(family.IsEmpty);
	}
}
