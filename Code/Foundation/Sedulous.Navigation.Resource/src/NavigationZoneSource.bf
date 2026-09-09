using System;
using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Navigation.Resource;

/// The cooked record for a zone: the serialized navmesh blob, and nothing else.
///
/// Baked in the ZONE'S own frame, which is where the runtime places it too: a navmesh baked in
/// one frame and queried in another puts every wall in the wrong place.
// 2: the frame stamp left the record; the blob alone is what a zone carries now.
[Serializable(2)]
class NavigationZoneSource
{
	/// The header and the Detour tiles behind it.
	public List<uint8> NavMeshBlob = new .() ~ delete _;
}
