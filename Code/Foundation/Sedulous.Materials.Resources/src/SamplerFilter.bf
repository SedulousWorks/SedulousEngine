namespace Sedulous.Materials.Resources;

/// Minification filter mode, including mipmap selection.
/// Mirrors glTF/OpenGL filter combinations.
/// Stored on MaterialResource for serialization. Converted to RHI FilterMode at runtime.
public enum SamplerMinFilter : int32
{
	Nearest = 0,
	Linear = 1,
	NearestMipmapNearest = 2,
	LinearMipmapNearest = 3,
	NearestMipmapLinear = 4,
	LinearMipmapLinear = 5
}

/// Magnification filter mode.
/// Stored on MaterialResource for serialization. Converted to RHI FilterMode at runtime.
public enum SamplerMagFilter : int32
{
	Nearest = 0,
	Linear = 1
}
