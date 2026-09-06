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
