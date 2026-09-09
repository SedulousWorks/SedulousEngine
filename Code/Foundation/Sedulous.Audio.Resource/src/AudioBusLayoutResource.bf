namespace Sedulous.Audio.Resource;

/// The runtime product a project's default layout id resolves to.
///
/// A thin holder rather than the layout itself, because a resource is what the manager
/// hands out and owns, and the layout is data an engine applies and keeps nothing of.
class AudioBusLayoutResource
{
	public AudioBusLayout Layout = new .() ~ delete _;
}
