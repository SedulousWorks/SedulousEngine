namespace Sedulous.Content;

/// How a data stream's bytes sit on disk.
///
/// A text stream takes a ".data" suffix so external tools treat it as text; a binary one
/// keeps ".bin". Readers accept either suffix for any stream, so changing a stream's
/// encoding does not orphan what was already written.
enum StreamEncoding : uint8
{
	Binary,
	Text
}
