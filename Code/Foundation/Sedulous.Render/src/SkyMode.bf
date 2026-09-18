using Sedulous.Core;

namespace Sedulous.Render;

/// How the scene's environment radiance, which is both the sky and the source of the image
/// based lighting, is produced.
[Scriptable(.AllPublic)]
enum SkyMode : uint32
{
	/// A gradient between horizon, zenith and ground.
	case Procedural;
	/// A physically derived sky model.
	case Analytic;
	/// One flat colour.
	case Color;
	/// An equirectangular high dynamic range image.
	case HDREquirect;
	/// A captured or authored cubemap.
	case Cubemap;
}
