using System;

namespace Sedulous.Editor.Scene;

/// The viewport's frame rate readout.
static class FrameRateOverlay
{
	/// One sample window's readout, "60 fps  16.7 ms", the frame time being the window's
	/// mean. A window with no frames in it yet reads as "-- fps".
	public static void Text(double windowSeconds, uint32 frames, String outText)
	{
		outText.Clear();
		if ((frames == 0) || (windowSeconds <= 0.0))
		{
			outText.Append("-- fps");
			return;
		}
		let fps = (double)frames / windowSeconds;
		let ms = windowSeconds * 1000.0 / (double)frames;
		let tenths = (int64)((ms * 10.0) + 0.5); // one decimal, rounded
		outText.AppendF("{} fps  {}.{} ms", (int64)(fps + 0.5), tenths / 10, tenths % 10);
	}
}
