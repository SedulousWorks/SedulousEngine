using System;
using Sedulous.Content;
using Sedulous.Resource;

namespace Sedulous.Navigation.Resource;

/// Builds a cooked zone into the loaded navmesh a zone component binds.
///
/// SYNCHRONOUS: loading a blob builds the backend's own mesh and adds its tiles, which is not
/// a pure function of the bytes and does not belong on a worker beside every other decode.
class NavigationZoneFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<NavigationZoneResource>();

	public Object Create(ResourceManager manager, Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;

		let source = stored as NavigationZoneSource;
		if (source == null)
		{
			// Something else was stored under this type name, so this is not a zone rather
			// than a zone that failed to read.
			delete stored;
			return null;
		}
		defer delete source;

		let zone = new NavigationZoneResource();
		if (!source.NavMeshBlob.IsEmpty)
		{
			// A malformed blob leaves the mesh INVALID and the product still built, so the
			// bind resolves and the subsystem skips that zone rather than the load failing.
			zone.Mesh.Load(source.NavMeshBlob).IgnoreError();
		}
		return zone;
	}
}
