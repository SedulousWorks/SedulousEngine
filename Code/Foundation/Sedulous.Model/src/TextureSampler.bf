namespace Sedulous.Model;

/// Sampler settings a model's textures refer to by index.
struct TextureSampler
{
	public TextureWrap WrapS = .Repeat;
	public TextureWrap WrapT = .Repeat;
	public TextureMinFilter MinFilter = .LinearMipmapLinear;
	public TextureMagFilter MagFilter = .Linear;

	public this()
	{
		WrapS = .Repeat; WrapT = .Repeat;
		MinFilter = .LinearMipmapLinear; MagFilter = .Linear;
	}
}
