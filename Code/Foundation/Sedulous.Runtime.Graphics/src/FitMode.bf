namespace Sedulous.RuntimeGraphics;

/// How a render target maps onto a different-sized output when their
/// aspect ratios don't match.
public enum FitMode : uint8
{
	/// Fill the output. Aspect ratio of the source is ignored - if
	/// source and output aspects differ the result distorts.
	Stretch,
	/// Preserve aspect ratio, center the source, fill any leftover with
	/// black bars on the over-sized axis.
	Letterbox,
	/// Preserve aspect ratio, fill the output entirely by overshooting
	/// the under-sized axis (content extends past the output edges and
	/// gets clipped).
	Crop
}
