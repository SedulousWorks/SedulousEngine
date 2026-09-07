namespace Sedulous.RHI;

/// A view onto a subset of a texture's mip levels and array layers.
interface ITextureView
{
	TextureViewDesc Desc { get; }
	ITexture Texture { get; }

	/// A creation stamp that never repeats, taken from TextureViewIds.Next.
	///
	/// A destroyed view's ADDRESS can be handed straight back to the next allocation, so
	/// any cache keyed on the view object MUST check this id on a hit. A bind group cache
	/// that trusted the reference alone handed out descriptors of a destroyed render
	/// target, sampled a dead image view, and lost the device.
	uint64 UniqueId { get; }
}
