namespace Sedulous.UI;

/// How an ImageView scales its source to fit its bounds.
enum ScaleType
{
	/// Draw at the source's own size, at the origin.
	None,
	/// Uniform scale, whole image visible, centred.
	FitCenter,
	/// Stretch to the bounds, ignoring the aspect ratio.
	FillBounds,
	/// Uniform scale, bounds fully covered, source centre cropped.
	CenterCrop
}
