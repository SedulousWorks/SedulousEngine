namespace Sedulous.Core.IO;

/// How a file is opened.
///
/// Four modes, as in Raptor. Corlib spreads the same ground over FileMode, FileAccess and
/// FileShare, which is more than a stream needs to be told; FileStream maps these onto
/// that triple.
enum FileMode
{
	/// An existing file, read only.
	Read,
	/// Created, or truncated if it exists. Write only.
	Write,
	/// Created if missing. Read and write.
	ReadWrite,
	/// Created if missing. Written at the end.
	Append
}
