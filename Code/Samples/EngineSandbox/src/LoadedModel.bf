namespace EngineSandbox;

using System;
using System.Collections;
using Sedulous.Resources;
using Sedulous.Geometry.Resources;

/// A cached imported model: mesh resource + per-slot material resource refs.
class LoadedModel
{
	public String Name ~ delete _;
	public StaticMeshResource MeshResource;
	public List<ResourceRef> MaterialRefs = new .() ~ { for (var r in _) r.Dispose(); delete _; };

	public void ReleaseRefs()
	{
		MeshResource?.ReleaseRef();
	}
}
