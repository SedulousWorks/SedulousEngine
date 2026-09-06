namespace Sedulous.Core.Logging;

/// One retained log line.
///
/// Fixed-capacity text, so retaining messages costs no allocation per record and a long
/// line is truncated rather than growing the buffer.
///
/// There is deliberately no property returning a StringView of the message. A record is
/// a value: handing out a view into one would point into whatever copy the caller
/// happened to be holding, and that copy dies at the end of the expression. RingLogger
/// reads the text out instead, from storage it knows is alive.
struct LogRecord
{
	public const int MessageCapacity = 256;

	public LogLevel Level;
	/// Characters used in message, never more than MessageCapacity.
	public int32 Length;
	public char8[MessageCapacity] Message;
}
