using Sedulous.Core;

namespace Sedulous.Render;

/// An instanced SET: one mesh and material drawn many times, whose per instance transforms
/// live in a persistent GPU buffer the renderer keys by this set's own id and uploads only
/// when the version changes.
///
/// Extraction emits ONE of these per instanced component rather than one per instance, so the
/// per frame cost does not grow with the crowd. The base carries the shared mesh, material
/// and MERGED bounds, so the set culls as a single volume; the base's world transform is
/// unused, since each instance has its own.
class MultiMeshRenderData : MeshRenderData
{
	/// A stable per component id, which is the renderer's persistent buffer slot.
	public uint64 Key = 0;

	/// The per instance world transforms, borrowed and valid this frame.
	public Float4x4* Transforms = null;
	/// Optional per instance tints. Null uses the shared colour.
	public Color* Tints = null;
	public uint32 InstanceCount = 0;
	/// Instances to UPLOAD when more than InstanceCount are borrowed; nought means the
	/// instance count.
	///
	/// A distance faded set uploads its whole list ONCE and then draws a prefix that moves
	/// with the camera without re-uploading, so Transforms and Tints hold this many entries.
	public uint32 UploadCount = 0;
	/// Bumped when the transforms change, so the renderer re-uploads only then.
	public uint32 Version = 0;

	/// A shared pool of skinning palettes, borrowed for the frame. With these the set draws
	/// skinned, each instance taking one of the palettes.
	public Float4x4* PosePool = null;
	/// Last frame's palettes, for per bone motion vectors. Null reuses the current ones.
	public Float4x4* PreviousPosePool = null;
	/// How many distinct phases there are.
	public uint32 PoseCount = 0;
	/// Bones per palette.
	/// NAMED APART from the base's BoneCount, which belongs to the single mesh path and stays
	/// nought for a crowd. Reading the base field here compiles and silently disables skinning.
	public uint32 PoseBoneCount = 0;

	public PoseAssignment PoseAssignment = .Hashed;
	/// Consumed only under the explicit policy, and borrowed. Null there means the caller's
	/// array was absent or the wrong size, which falls back to hashing.
	public uint32* PoseIndices = null;
}
