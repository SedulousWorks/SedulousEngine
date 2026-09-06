using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Core.Tests;

/// A layout that changed: version one stored Width alone, version two added Height.
///
/// Hand written, because branching on the stored version is exactly the case a generated
/// walker cannot express: the walker describes the fields this build has, and migration is
/// about the fields an older build did not.
class MigratingSample : ISerializable
{
	private const uint64 cTypeId = 0xDEC1A5E5;

	public int32 Width;
	public int32 Height;

	/// What to WRITE as. The test sets it back to one to produce an old payload.
	public uint32 WriteVersion = 2;

	public void Serialize(ISerializer ar)
	{
		BeginVersionedPayload(ar, cTypeId, WriteVersion);
		ar.BeginObject();

		ar.Key("width");
		Sedulous.Core.Serialization.Serialize(ar, ref Width);

		if (ar.Version >= 2)
		{
			ar.Key("height");
			Sedulous.Core.Serialization.Serialize(ar, ref Height);
		}
		else
		{
			// Height did not exist yet, so it takes the value version one implied.
			Height = 1;
		}

		ar.EndObject();
		EndVersionedPayload(ar);
	}
}
