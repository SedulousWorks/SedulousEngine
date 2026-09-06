using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Settings.Tests;

/// Sections with plain fields, so they round trip on any backend.
[Serializable(1)]
class GameSettings
{
	public String Profile = new .("default") ~ delete _;
	public String Locale = new .("en") ~ delete _;
}

[Serializable(1)]
class SectionA
{
	public int32 A;
}

/// The one a build is made to not know about, so the passthrough has something to preserve.
[Serializable(1)]
class SectionX
{
	public int32 X;
	public String Tag = new .() ~ delete _;
}

[Serializable(1)]
class SectionB
{
	public int32 B;
}

[SerializableRegistry]
static class TestSections
{
}
