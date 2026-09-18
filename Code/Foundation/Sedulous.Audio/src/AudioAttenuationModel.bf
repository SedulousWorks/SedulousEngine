using Sedulous.Core;

namespace Sedulous.Audio;

/// How a spatial voice falls off with distance.
[Scriptable(.AllPublic)]
enum AudioAttenuationModel : uint8
{
	/// No falloff at all. It is still panned, and still shifted by movement.
	case None = 0;
	case Inverse = 1;
	case Linear = 2;
	case Exponential = 3;
}
