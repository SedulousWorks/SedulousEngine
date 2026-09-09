using Sedulous.Core;

namespace Sedulous.Render;

/// Picking a skinned instance's pose out of the shared palettes, and the helpers for
/// authoring a layout aware pick.
///
/// Factored out pure, so the choice can be tested without a GPU.
static class PoseSelection
{
	/// The pose for one instance of a set. Every branch answers within the palette count, and
	/// no palettes at all answers the first.
	public static uint32 SelectPose(PoseAssignment policy, uint32 index, uint32 poseCount,
		uint32* explicitIndices)
	{
		if (poseCount == 0)
			return 0;

		// A null array means the caller's was absent or mismatched, which degrades to hashing
		// rather than reading past the end of it.
		if ((policy == .Explicit) && (explicitIndices != null))
			return explicitIndices[index] % poseCount;

		if (policy == .Sequential)
			return index % poseCount;

		return (uint32)(HashInteger(index) % (uint64)poseCount);
	}

	/// A whole column shares a phase, which reads as a formation.
	public static uint32 ColumnPose(uint32 column, uint32 poseCount) => column % poseCount;

	/// A diagonal gradient, which reads as a wave crossing the crowd.
	public static uint32 WavePose(uint32 column, uint32 row, uint32 poseCount) =>
		(column + row) % poseCount;

	/// Cells of a given size share a phase, and the cells themselves are scattered.
	public static uint32 ClusterPose(uint32 column, uint32 row, uint32 cellSize, uint32 poseCount)
	{
		let cellX = column / cellSize;
		let cellZ = row / cellSize;
		return (uint32)(HashInteger(((uint64)cellX << 32) ^ (uint64)cellZ) % (uint64)poseCount);
	}
}
