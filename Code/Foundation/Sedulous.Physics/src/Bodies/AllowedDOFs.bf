namespace Sedulous.Physics;

/// Allowed degrees of freedom for a physics body.
/// Use to constrain motion to specific axes.
enum AllowedDOFs : uint8
{
	/// No movement allowed (effectively static).
	None = 0,

	/// Allow translation along X axis.
	TranslationX = 1 << 0,

	/// Allow translation along Y axis.
	TranslationY = 1 << 1,

	/// Allow translation along Z axis.
	TranslationZ = 1 << 2,

	/// Allow rotation around X axis.
	RotationX = 1 << 3,

	/// Allow rotation around Y axis.
	RotationY = 1 << 4,

	/// Allow rotation around Z axis.
	RotationZ = 1 << 5,

	/// Allow all translation.
	Translation = TranslationX | TranslationY | TranslationZ,

	/// Allow all rotation.
	Rotation = RotationX | RotationY | RotationZ,

	/// Allow all degrees of freedom.
	All = Translation | Rotation,

	/// 2D movement: XY translation + Z rotation only.
	Plane2D = TranslationX | TranslationY | RotationZ
}
