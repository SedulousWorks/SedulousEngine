using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Scene;

/// One mesh's stored preview material, keyed by the mesh asset's guid; nil is the default.
[Serializable(1)]
class MeshPreviewPref
{
	public Guid Asset = .();
	public Guid Material = .();
}
