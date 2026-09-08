using Sedulous.Core.Serialization;

namespace Sedulous.Scene;

/// Identity only, and byte identical to a bare Guid: a field migrated from Guid to
/// EntityRef leaves the format on disk unchanged.
///
/// A free function beside the type rather than an ISerializable on it, matching how Core
/// serializes its own value types.
static
{
	public static void Serialize(ISerializer ar, ref EntityRef value)
		=> Sedulous.Core.Serialization.Serialize(ar, ref value.Id);
}
