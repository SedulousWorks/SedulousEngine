using System;
using Sedulous.Image;

namespace Sedulous.UI;

/// Loads the external resources a style sheet refers to.
///
/// The runtime supplies an implementation bridging to the virtual file system. With no
/// provider, `@import` and the file loading factories fail GRACEFULLY rather than refusing to
/// parse: a sheet that mentions a file is still useful for everything else it declares.
interface IResourceProvider
{
	/// Text, for an imported sheet or an icon's SVG. The path is relative to the importing
	/// file or the resource root. False when it could not be read.
	bool LoadText(StringView path, String outText);

	/// An image, for the image and nine slice factories. BORROWED, the provider owning its
	/// lifetime, and null when not found.
	ImageData LoadImage(StringView path);
}
