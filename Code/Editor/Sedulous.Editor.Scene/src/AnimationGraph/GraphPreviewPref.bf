using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Scene;

/// One graph's stored preview rig, keyed by the graph asset's guid: the skeleton it plays
/// on and the skinned mesh drawn over the wireframe, either nil for none.
[Serializable(1)]
class GraphPreviewPref
{
	public Guid Asset = .();
	public Guid Skeleton = .();
	public Guid Mesh = .();
}
