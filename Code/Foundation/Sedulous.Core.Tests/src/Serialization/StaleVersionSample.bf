using Sedulous.Core.Serialization;

namespace Sedulous.Core.Tests;

/// A versioned type that can be made to write under an OLD version, so a test can produce
/// the stale payload the reader has to refuse.
///
/// Its body reads both fields unconditionally. There is no migration to model: one
/// supported layout per type, and anything else is refused before a field is touched.
class StaleVersionSample : ISerializable
{
	public const uint64 TypeId = 0xDEC1A5E5;
	/// The version the CODE is at.
	public const uint32 CurrentVersion = 2;

	public int32 Width;
	public int32 Height;

	/// What to WRITE as. A test sets it back to produce a payload from an older build.
	public uint32 WriteVersion = CurrentVersion;

	public void Serialize(ISerializer ar)
	{
		BeginVersionedPayload(ar, TypeId, WriteVersion);
		ar.BeginObject();

		ar.Key("width");
		Sedulous.Core.Serialization.Serialize(ar, ref Width);
		ar.Key("height");
		Sedulous.Core.Serialization.Serialize(ar, ref Height);

		ar.EndObject();
		EndVersionedPayload(ar);
	}
}
