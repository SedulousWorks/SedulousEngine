namespace Sedulous.UI;

/// Whether a ScrollView's bars sit over the content or beside it.
enum ScrollBarMode
{
	/// The bar floats over the content, which keeps the full width and height.
	Overlay,
	/// Room is set aside for the bar, and the content shrinks to make it.
	Reserved
}
