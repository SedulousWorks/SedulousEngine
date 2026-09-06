using System;

namespace Sedulous.Image;

/// One image waiting to be packed, under the name it will be found by. The image is
/// BORROWED: the caller keeps it alive until the atlas is built.
class AtlasEntry
{
	public String Name = new .() ~ delete _;
	public ImageData Image;
}
