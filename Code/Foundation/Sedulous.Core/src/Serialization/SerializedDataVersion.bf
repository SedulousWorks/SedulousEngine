namespace Sedulous.Core.Serialization;

/// One entry of a data-version scope: a stable type id, and the version the DATA carries.
///
/// Writing records the type's current version; reading records whatever the stream stored,
/// so a Serialize body can branch on the version its data was written with.
struct SerializedDataVersion
{
	public uint64 TypeId;
	public uint32 Version;

	public this(uint64 typeId, uint32 version)
	{
		TypeId = typeId;
		Version = version;
	}
}
