using System.Collections;

namespace Sedulous.Texture.Resource;

/// What the worker produced, waiting for the main thread to turn it into a GPU texture.
///
/// Both halves of a cooked texture are read off the content database, which opens
/// independent streams and whose registries are read only during a load, so both are safe
/// to do on a worker. Nothing in here touches the RHI: that is the whole point of the
/// split.
class DecodedTexture
{
	/// The cooked record. OWNED.
	public TextureResource Record ~ delete _;
	/// The cooked "data" stream.
	public List<uint8> Pixels = new .() ~ delete _;
}
