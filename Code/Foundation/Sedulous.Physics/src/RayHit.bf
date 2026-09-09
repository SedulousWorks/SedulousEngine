using Sedulous.Core;

namespace Sedulous.Physics;

/// What a ray or a shape sweep found.
struct RayHit
{
	public BodyId Body = .();
	public uint64 UserData = 0;
	public Float3 Position = .(0, 0, 0);
	public Float3 Normal = .(0, 0, 0);
	public float Fraction = 1.0f;

	/// The material slot of the face that was hit, for a cooked TRIANGLE MESH: whatever the
	/// cooker stored per triangle, which is the source mesh's own slot. Nought otherwise.
	public uint32 Surface = 0;

	public this() {}
}
