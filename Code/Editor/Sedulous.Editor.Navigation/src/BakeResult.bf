namespace Sedulous.Editor.Navigation;

struct BakeResult
{
	/// A navmesh was produced and written.
	public bool Baked = false;
	/// The input triangles collected.
	public int TriangleCount = 0;
}
