using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Core.Tests;

/// A serializable type that declares a data version, so its payload carries a version
/// envelope a later build can branch on.
[Serializable(3)]
class VersionedSample
{
	public int32 Value;
}

/// A record whose layout grew at its end: version 2 appended `Added`, and its legacy reader
/// still decodes version 1, so data stored before the field reads with it at its default.
[Serializable(2, false, 1)]
class GrownVersionedSample
{
	public int32 Value;
	[Appended(2)]
	public int32 Added = -2;
}
