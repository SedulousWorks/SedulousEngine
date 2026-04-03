namespace Sedulous.Physics.Jolt;

using joltc_Beef;
using Sedulous.Core.Mathematics;

/// Utility class for converting between Sedulous and Jolt types.
static class JoltConversions
{
	// === Vector3 Conversions ===

	public static Vector3 ToVector3(JPH_Vec3 v) => .(v.x, v.y, v.z);
	//public static Vector3 ToVector3(JPH_RVec3 v) => .((.)v.x, (.)v.y, (.)v.z);

	public static JPH_Vec3 ToJPHVec3(Vector3 v) => .() { x = v.X, y = v.Y, z = v.Z };
	public static JPH_RVec3 ToJPHRVec3(Vector3 v) => .() { x = v.X, y = v.Y, z = v.Z };

	// === Quaternion Conversions ===

	public static Quaternion ToQuaternion(JPH_Quat q) => .(q.x, q.y, q.z, q.w);
	public static JPH_Quat ToJPHQuat(Quaternion q) => .() { x = q.X, y = q.Y, z = q.Z, w = q.W };

	// === BodyType Conversions ===

	public static JPH_MotionType ToJPHMotionType(BodyType bodyType)
	{
		switch (bodyType)
		{
		case .Static: return .JPH_MotionType_Static;
		case .Kinematic: return .JPH_MotionType_Kinematic;
		case .Dynamic: return .JPH_MotionType_Dynamic;
		}
	}

	public static BodyType ToBodyType(JPH_MotionType motionType)
	{
		switch (motionType)
		{
		case .JPH_MotionType_Static: return .Static;
		case .JPH_MotionType_Kinematic: return .Kinematic;
		case .JPH_MotionType_Dynamic: return .Dynamic;
		default: return .Static;
		}
	}

	// === Activation Conversions ===

	public static JPH_Activation ToJPHActivation(bool activate)
	{
		return activate ? .JPH_Activation_Activate : .JPH_Activation_DontActivate;
	}

	// === Matrix Conversions ===

	/// Creates a JPH_Mat4 from position and rotation (column-major).
	public static JPH_Mat4 ToJPHMat4(Vector3 position, Quaternion rotation)
	{
		// Convert quaternion to rotation matrix
		let m = Matrix.CreateFromQuaternion(rotation);

		JPH_Mat4 result = default;

		// Column 0 (X axis)
		result.column[0].x = m.M11;
		result.column[0].y = m.M21;
		result.column[0].z = m.M31;
		result.column[0].w = 0;

		// Column 1 (Y axis)
		result.column[1].x = m.M12;
		result.column[1].y = m.M22;
		result.column[1].z = m.M32;
		result.column[1].w = 0;

		// Column 2 (Z axis)
		result.column[2].x = m.M13;
		result.column[2].y = m.M23;
		result.column[2].z = m.M33;
		result.column[2].w = 0;

		// Column 3 (Translation)
		result.column[3].x = position.X;
		result.column[3].y = position.Y;
		result.column[3].z = position.Z;
		result.column[3].w = 1;

		return result;
	}
}
