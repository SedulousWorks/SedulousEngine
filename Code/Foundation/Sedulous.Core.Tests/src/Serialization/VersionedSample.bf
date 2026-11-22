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

/// A record whose layout lost a field: version 2 dropped `oldCount`, which version 1 stored
/// between the other two. Its legacy reader still decodes version 1, the dropped value into
/// `Carried`, which nothing writes.
[Serializable(2, false, 1)]
class ShrunkVersionedSample
{
	public int32 Before;
	[Retired(2, "oldCount")]
	public int32 Carried = 0;
	public int32 After;
}

/// A record whose field took a new key at version 2: version 1 stored `Moved` as `oldName`.
/// Its legacy reader still decodes version 1.
[Serializable(2, false, 1)]
class RenamedVersionedSample
{
	public int32 Before;
	[Renamed(2, "oldName")]
	public int32 Moved;
	public int32 After;
}
