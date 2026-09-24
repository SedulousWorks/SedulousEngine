namespace Sedulous.Image.DDS;

/// What a DDS header states, without the payload.
///
/// Enough for an importer to decide a texture's usage, a BC5 being a normal map and a BC4 a
/// mask, and its colour space. Learning those used to mean reading the whole file, which on a
/// project of a few hundred DDS textures is gigabytes off the disk to read a few hundred
/// bytes; ReadDdsHeader reads cDdsHeaderBytes instead.
class DdsHeader
{
	public uint32 Width = 0;
	public uint32 Height = 0;
	public uint32 MipLevels = 1;
	/// Six times the array size for a cubemap.
	public uint32 ArrayLayers = 1;
	public bool Cubemap = false;
	public DdsFormat Format = .Unknown;
	/// A DX10 header NAMES its colour space; a legacy one leaves it to be guessed.
	public bool ColorSpaceKnown = false;

	public this() {}
}
