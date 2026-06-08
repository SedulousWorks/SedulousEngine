namespace Sedulous.UI;

using System;
using Sedulous.Images;

/// Interface for loading external resources referenced by .sss stylesheets.
/// The runtime layer provides an implementation that bridges to VFS.
/// If no provider is given, @import and resource-loading factories
/// (image, nine-slice, svg from file) fail gracefully.
public interface IResourceProvider
{
	/// Load text content from a path (for @import .sss files and @icon SVG files).
	/// Path is relative to the importing file or resource root.
	Result<void> LoadText(StringView path, String outText);

	/// Load image data from a path (for image() and nine-slice() factories).
	Result<IImageData> LoadImage(StringView path);
}
