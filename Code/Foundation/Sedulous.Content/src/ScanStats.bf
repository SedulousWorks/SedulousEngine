namespace Sedulous.Content;

/// What the open-time scan cost.
///
/// A scan reads three header fields out of every envelope, but a serializer may have to
/// consume the whole file to reach them: the XML backend parses the entire document before
/// the first read. These numbers are the evidence for or against doing something cleverer.
struct ScanStats
{
	public int Envelopes;
	/// The total size of every envelope the scan opened, not the bytes it needed.
	public int64 BytesOpened;
}
