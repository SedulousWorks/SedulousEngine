namespace Sedulous.Editor.PropertyAnimation;

/// The shared dopesheet time transform: pixels per second, scroll, and the label-column
/// gutter width. The curve canvas reads it so it follows the Timeline's zoom and scroll and
/// aligns under the dopesheet lanes.
struct ClipTimeAxis
{
	public float PixelsPerSecond = 100.0f;
	public float ScrollSeconds = 0.0f;
	public float LabelColumnWidth = 0.0f;
}
