using Sedulous.RHI;

namespace Sedulous.Render;

/// One instanced SET's persistent GPU state, keyed by the component's own stable id.
///
/// The instance data is N BUFFERED, one region per frame in flight, so a runtime change can
/// rewrite this frame's region while the GPU still reads the previous frame's. That is what
/// makes even a per frame dynamic crowd hazard free without a wait. Each region has its own
/// bind group; a draw binds this frame's.
///
/// A static set uploads once and then costs nothing per frame, which is the whole point of
/// keeping the buffer rather than filling one each frame.
class MultiMeshSet
{
	/// An upper bound on the frames in flight, for the per region arrays.
	public const int cMaxFramesInFlight = 4;

	public IBuffer InstanceBuffer = null;
	public IBindGroup[cMaxFramesInFlight] InstanceBindGroups;
	/// This frame's region's group.
	public IBindGroup ActiveInstanceBindGroup = null;

	/// Instances per region.
	public uint32 Capacity = 0;
	/// Live instances this frame.
	public uint32 Count = 0;

	/// PER REGION: the component version its bytes hold, nought meaning never, versions
	/// starting at one, and how many instances were written with it.
	///
	/// A region is rewritten when either falls behind what the frame's item asks for: a new
	/// version, or a draw count that has grown past what this region holds, which a distance
	/// fade opening up within the rounded capacity does. Without the count, the tail draws
	/// whatever that region held before, and since it differs per region, the set flickers.
	public uint32[cMaxFramesInFlight] RegionVersion;
	public uint32[cMaxFramesInFlight] RegionCount;
	/// The last frame this set was extracted, for eviction.
	public uint32 LastFrame = 0;

	/// A skinned crowd needs a PER SET offsets buffer, refilled each frame with the per
	/// instance bone bases; the shared ramp's are always nought. Only allocated when skinned.
	public IBuffer OffsetsBuffer = null;
	public uint32 OffsetsCapacity = 0;
	/// This frame's region's byte offset, rewritten every frame.
	public uint32 OffsetsByteOffset = 0;
	/// Whether it drew skinned this frame, which is to say whether it has a pose pool.
	public bool Skinned = false;
}
