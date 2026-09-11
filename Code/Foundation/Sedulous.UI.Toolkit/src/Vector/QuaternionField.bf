using System;
using Sedulous.Core;

namespace Sedulous.UI.Toolkit;

/// A rotation, edited as three EULER ANGLES in degrees: X is pitch, Y is yaw, Z is roll.
///
/// The QUATERNION is the value; the angles are only how it is typed. But the angles are also
/// CACHED rather than recomputed from the quaternion each time, because the mapping is many to
/// one: 370 degrees and 10 degrees are the same rotation, and so are a pitch past ninety and
/// its mirrored triple. Reading the angles back from the quaternion mid edit would make the
/// numbers jump under the cursor while the user is still typing them.
class QuaternionField : AggregatingVectorField
{
	public Event<delegate void(Quaternion)> OnValueChanged ~ _.Dispose();

	private Quaternion mValue = .Identity;
	private Float3 mEulerDegrees = .Zero;

	public this()
	{
		BuildFields(-360, 360, 1, 2);
	}

	public Quaternion Value => mValue;

	public void SetValue(Quaternion value)
	{
		mValue = value;
		mEulerDegrees = ToEulerDegrees(value);
		SyncToFields();
	}

	/// The angles behind the fields, which need not be the only triple naming this rotation.
	public Float3 EulerDegrees => mEulerDegrees;

	protected override int32 AxisCount => 3;

	protected override float GetComponent(int32 axis) => mEulerDegrees[axis];

	protected override void SetComponentFromField(int32 axis, float value)
	{
		mEulerDegrees[axis] = value;
		mValue = FromEulerDegrees(mEulerDegrees);
		OnValueChanged(mValue);
	}

	// ---- Conversion -----------------------------------------------------------------------------

	/// DIVERGES FROM RAPTOR, which is wrong here.
	///
	/// The forward composition is Z then Y then X, so the MIDDLE axis is Y, and the middle axis
	/// is the one that must be extracted with an arcsine while the outer two come from an
	/// arctangent. The C++ puts the arcsine on X and the arctangents on Y and Z, which inverts
	/// correctly for a rotation about one axis and is wrong for every combination of two or
	/// more: a rotation typed as 30, 45, 60 reads back as -16.3, 50.4, 39.6.
	///
	/// That matters because the field caches these angles and rebuilds the quaternion from
	/// them, so a compound rotation would show wrong numbers and then be REWRITTEN to match
	/// them on the first keystroke in any axis.
	///
	/// GIMBAL LOCK is handled by pinning the middle angle to the pole rather than letting the
	/// arcsine take an argument outside its domain and come back a NaN that poisons everything
	/// downstream.
	public static Float3 ToEulerDegrees(Quaternion q)
	{
		let sinYaw = 2.0f * ((q.W * q.Y) - (q.Z * q.X));
		let yaw = (Abs(sinYaw) >= 1.0f)
			? ((sinYaw >= 0.0f) ? HalfPi : -HalfPi)
			: Asin(sinYaw);

		let pitch = Atan2(2.0f * ((q.W * q.X) + (q.Y * q.Z)),
			1.0f - (2.0f * ((q.X * q.X) + (q.Y * q.Y))));
		let roll = Atan2(2.0f * ((q.W * q.Z) + (q.X * q.Y)),
			1.0f - (2.0f * ((q.Y * q.Y) + (q.Z * q.Z))));

		return .(pitch * RadToDeg, yaw * RadToDeg, roll * RadToDeg);
	}

	public static Quaternion FromEulerDegrees(Float3 eulerDegrees)
	{
		let halfPitch = eulerDegrees.X * DegToRad * 0.5f;
		let halfYaw = eulerDegrees.Y * DegToRad * 0.5f;
		let halfRoll = eulerDegrees.Z * DegToRad * 0.5f;

		let cp = Cos(halfPitch);
		let sp = Sin(halfPitch);
		let cy = Cos(halfYaw);
		let sy = Sin(halfYaw);
		let cr = Cos(halfRoll);
		let sr = Sin(halfRoll);

		return .((sp * cy * cr) - (cp * sy * sr), (cp * sy * cr) + (sp * cy * sr),
			(cp * cy * sr) - (sp * sy * cr), (cp * cy * cr) + (sp * sy * sr));
	}
}
