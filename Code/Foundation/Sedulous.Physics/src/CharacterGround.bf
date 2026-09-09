namespace Sedulous.Physics;

enum CharacterGround : uint8
{
	case OnGround;
	/// Touching ground too steep to stand on, which is a slide rather than a stand.
	case OnSteepGround;
	case NotSupported;
	case InAir;
}
