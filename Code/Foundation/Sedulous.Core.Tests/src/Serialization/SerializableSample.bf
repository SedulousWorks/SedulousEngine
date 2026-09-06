using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Core.Tests;

/// A type whose Serialize body is generated from its fields.
///
/// Nothing here describes the data: the field declarations are the description, which is
/// the whole point of the attribute.
///
/// Unversioned, so it writes exactly its fields and nothing else. That is what lets the
/// format test read the payload back by hand.
[Serializable]
class SerializableSample
{
	public int32 Id;
	public float Weight;
	public bool Enabled;
	public SampleKind Kind;
	public Float3 Position;
	public String Name = new .() ~ delete _;
}
