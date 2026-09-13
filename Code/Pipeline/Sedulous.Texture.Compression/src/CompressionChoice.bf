namespace Sedulous.Texture.Compression;

/// The compression the asset asked for, as authored.
enum CompressionChoice : uint8
{
	/// Whatever the policy picks.
	Default,
	/// Force uncompressed, which is the escape hatch.
	None,
	/// Force the high quality format and high encoder effort.
	Quality,
}
