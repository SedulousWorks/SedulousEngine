namespace Sedulous.Engine.Render;

/// How a sprite billboard turns to face the world, mirroring the shader's own modes.
enum SpriteOrientation : uint32
{
	/// A full billboard, always square to the camera.
	case CameraFacing = 0;
	/// Rotates about world Y only, which is what a tree or a standing character wants.
	case CameraFacingY = 1;
	/// Pinned to the world XY plane, for flat art laid onto the scene.
	case WorldAligned = 2;
	/// Spanned by the ENTITY's own right and up axes, for a panel placed in the world.
	case EntityOriented = 3;
}
