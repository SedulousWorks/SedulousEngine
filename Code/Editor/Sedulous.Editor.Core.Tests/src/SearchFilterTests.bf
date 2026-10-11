using System;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Core.Tests;

/// Every editor filter field finds a thing by its name or its guid.
class SearchFilterTests
{
	[Test]
	public static void ANamePartOrAGuidWholeOrByItsFirstDigits()
	{
		Test.Assert(Guid.Parse("3f2a9c1e-7b44-4d0e-9a51-0c6e2b8d7f13") case .Ok(let id));
		Test.Assert(SearchFilter.NameOrGuidMatches("Crate", id, ""));
		Test.Assert(SearchFilter.NameOrGuidMatches("Crate", id, "RAT"));
		Test.Assert(!SearchFilter.NameOrGuidMatches("Crate", id, "barrel"));
		Test.Assert(SearchFilter.NameOrGuidMatches("Crate", id, "3f2a"));
		Test.Assert(SearchFilter.NameOrGuidMatches("Crate", id, "3F2A9C1E-7B44"));
		Test.Assert(SearchFilter.NameOrGuidMatches("Crate", id, "{3f2a9c1e7b444d0e9a510c6e2b8d7f13}"));
		Test.Assert(!SearchFilter.NameOrGuidMatches("Crate", id, "3f2"), "under four digits: a name only");
		Test.Assert(!SearchFilter.NameOrGuidMatches("Crate", id, "4d0e"), "not the guid's beginning");

		Test.Assert(SearchFilter.FilterAsGuid(" {3F2A9C1E-7B44-4D0E-9A51-0C6E2B8D7F13} ", let whole));
		Test.Assert(whole == id);
		Test.Assert(!SearchFilter.FilterAsGuid("3f2a9c1e", ?));
		Test.Assert(!SearchFilter.FilterAsGuid("Crate", ?));
	}
}
