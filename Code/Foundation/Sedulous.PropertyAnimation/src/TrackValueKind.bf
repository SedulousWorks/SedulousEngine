namespace Sedulous.PropertyAnimation;

/// What a track animates.
///
/// A float, a vector and a colour are PER COMPONENT SCALAR CURVES; a rotation is keyframed
/// quaternions, spherically interpolated. Never per component Euler angles: interpolating
/// those independently does not describe the rotation between two orientations at all.
enum TrackValueKind : uint8
{
	case Float;
	case Float3;
	case Quat;
	case Color;

	/// How many scalar channels this kind drives. A rotation drives NONE: it uses its own
	/// keys rather than curves.
	public uint32 ChannelCount
	{
		get
		{
			switch (this)
			{
			case .Float: return 1;
			case .Float3: return 3;
			case .Color: return 4;
			case .Quat: return 0;
			}
		}
	}
}
