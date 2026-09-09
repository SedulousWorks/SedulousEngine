namespace Sedulous.Navigation.Resource;

/// The runtime product a zone binds: the loaded navmesh.
///
/// NOT VALID when the blob was empty or would not load, and the subsystem then simply has no
/// navmesh for that zone. The product still exists either way, so the bind resolves and the
/// zone is skipped rather than the whole load failing.
class NavigationZoneResource
{
	public NavigationMesh Mesh = new .() ~ delete _;

	public bool IsValid => Mesh.IsValid;
}
