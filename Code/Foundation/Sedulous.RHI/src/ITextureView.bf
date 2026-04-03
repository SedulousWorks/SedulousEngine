namespace Sedulous.RHI;

/// A view into a texture, specifying a subset of mip levels and array layers.
/// Destroyed via IDevice.DestroyTextureView().
interface ITextureView
{
	/// The descriptor this view was created with.
	TextureViewDesc Desc { get; }

	/// The texture this view references.
	ITexture Texture { get; }
}
