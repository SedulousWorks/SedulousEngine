namespace Sedulous.RHI;

/// What one slot of a bind group layout holds.
///
/// Read only and read write are separate entries rather than a flag because the two need
/// different descriptor types and different barriers, and a layout that claimed both would
/// force every backend to assume the stricter one.
enum BindingType : uint32
{
	UniformBuffer,
	StorageBufferReadOnly,
	StorageBufferReadWrite,
	SampledTexture,
	StorageTextureReadOnly,
	StorageTextureReadWrite,
	Sampler,
	ComparisonSampler,

	/// Unbounded arrays, indexed by a shader at runtime. Their contents are set through
	/// BindGroup.UpdateBindless rather than at creation, and the device must report the
	/// bindless feature before a layout may use them.
	BindlessTextures,
	BindlessSamplers,
	BindlessStorageBuffers,
	BindlessStorageTextures,

	AccelerationStructure
}
