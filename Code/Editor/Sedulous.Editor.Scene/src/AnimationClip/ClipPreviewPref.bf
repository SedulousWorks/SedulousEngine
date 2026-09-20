using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Scene;

/// One clip's stored preview rig, keyed by the clip asset's guid: the skeleton it samples
/// on and the skinned mesh drawn over the wireframe, either nil for none.
[Serializable(1)]
class ClipPreviewPref
{
	public Guid Asset = .();
	public Guid Skeleton = .();
	public Guid Mesh = .();
}
