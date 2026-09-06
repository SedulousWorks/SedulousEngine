namespace Sedulous.VFS.Pak;

/// The .pak archive format.
///
/// Little-endian as stored, everywhere:
///
///     [Header, 32 bytes]
///       uint32 magic
///       uint32 version
///       uint64 entryCount
///       uint64 tocOffset   bytes from the start of the file
///       uint64 tocSize     bytes
///     [Data heap]          entry bytes back to back, in stored form
///     [TOC at tocOffset]   per entry:
///       uint16 locatorLength, then that many UTF-8 bytes
///       uint64 offset, uint64 storedSize, uint64 originalSize, uint16 compression
///
/// The archive lives in its own project so a compression codec never pulls into the core
/// VFS, which every consumer links.
static
{
	/// 'RPAK', little-endian.
	public const uint32 cPakMagic = 0x4B415052;
	public const uint32 cPakVersion = 1;
	public const uint16 cCompressionNone = 0;

	/// Header size, which is also the smallest a valid archive can be.
	public const int64 cPakHeaderSize = 32;
}
