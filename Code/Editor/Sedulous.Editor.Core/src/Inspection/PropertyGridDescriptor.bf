namespace Sedulous.Editor.Core;

using System;
using Sedulous.Engine.Core;
using Sedulous.Core.Mathematics;
using Sedulous.UI.Toolkit;

/// Implements IPropertyDescriptor to build PropertyGrid entries from
/// comptime-generated DescribeProperties calls.
class PropertyGridDescriptor : IPropertyDescriptor
{
	private PropertyGrid mGrid;
	private String mCurrentCategory = new .() ~ delete _;

	public this(PropertyGrid grid)
	{
		mGrid = grid;
	}

	public void Float(StringView name, float* ptr, float min, float max)
	{
		let editor = new FloatEditor(name, *ptr, min: min, max: max, category: mCurrentCategory);
		editor.Setter = new [=ptr, =min, =max] (v) => {
			*ptr = (float)Math.Clamp(v, min, max);
		};
		mGrid.AddProperty(editor);
	}

	public void Int32(StringView name, int32* ptr, int32 min, int32 max)
	{
		let editor = new IntEditor(name, (int64)*ptr, min: (int64)min, max: (int64)max, category: mCurrentCategory);
		editor.Setter = new [=ptr, =min, =max] (v) => {
			*ptr = (int32)Math.Clamp(v, min, max);
		};
		mGrid.AddProperty(editor);
	}

	public void UInt32(StringView name, uint32* ptr, uint32 min, uint32 max)
	{
		let editor = new IntEditor(name, (int64)*ptr, min: (int64)min, max: (int64)max, category: mCurrentCategory);
		editor.Setter = new [=ptr, =min, =max] (v) => {
			*ptr = (uint32)Math.Clamp(v, (int64)min, (int64)max);
		};
		mGrid.AddProperty(editor);
	}

	public void Bool(StringView name, bool* ptr)
	{
		let editor = new BoolEditor(name, *ptr, category: mCurrentCategory);
		editor.Setter = new [=ptr] (v) => { *ptr = v; };
		mGrid.AddProperty(editor);
	}

	public void Str(StringView name, String* ptr)
	{
		let strVal = (*ptr != null) ? StringView(*ptr) : "";
		let editor = new StringEditor(name, strVal, category: mCurrentCategory);
		editor.Setter = new [=ptr] (v) => {
			if (*ptr != null)
				(*ptr).Set(v);
		};
		mGrid.AddProperty(editor);
	}

	public void Slider(StringView name, float* ptr, float min, float max)
	{
		let editor = new RangeEditor(name, *ptr, min: min, max: max, category: mCurrentCategory);
		editor.Setter = new [=ptr, =min, =max] (v) => {
			*ptr = (float)Math.Clamp(v, min, max);
		};
		mGrid.AddProperty(editor);
	}

	public void Vec3(StringView name, Vector3* ptr)
	{
		let editor = new Vector3Editor(name, *ptr, category: mCurrentCategory);
		editor.Setter = new [=ptr] (v) => { *ptr = v; };
		mGrid.AddProperty(editor);
	}

	public void Quat(StringView name, Quaternion* ptr)
	{
		// Display as euler angles, convert back on set
		let euler = QuaternionToEuler(*ptr);
		let editor = new Vector3Editor(name, euler, min: -360, max: 360, category: mCurrentCategory);
		editor.Setter = new [=ptr] (v) => {
			*ptr = EulerToQuaternion(v);
		};
		mGrid.AddProperty(editor);
	}

	public void EnumField(StringView name, void* ptr, Type enumType)
	{
		// Get enum value names
		let names = scope System.Collections.List<StringView>();
		for (let field in enumType.GetFields())
		{
			if (field.IsEnumCase)
				names.Add(field.Name);
		}

		let currentVal = *(int32*)ptr;
		let editor = new EnumEditor(name, currentVal, names, category: mCurrentCategory);
		editor.Setter = new [=ptr] (v) => { *(int32*)ptr = v; };
		mGrid.AddProperty(editor);
	}

	public void BeginCategory(StringView name)
	{
		mCurrentCategory.Set(name);
	}

	public void EndCategory()
	{
		mCurrentCategory.Clear();
	}

	// === Euler/Quaternion conversion helpers ===

	public static Vector3 QuaternionToEuler(Quaternion q)
	{
		// Convert to euler angles in degrees
		let sinP = 2.0f * (q.W * q.X - q.Z * q.Y);
		float pitch;
		if (Math.Abs(sinP) >= 1.0f)
			pitch = (sinP >= 0) ? (Math.PI_f / 2.0f) : -(Math.PI_f / 2.0f);
		else
			pitch = Math.Asin(sinP);

		let sinYCosP = 2.0f * (q.W * q.Y + q.X * q.Z);
		let cosYCosP = 1.0f - 2.0f * (q.X * q.X + q.Y * q.Y);
		let yaw = Math.Atan2(sinYCosP, cosYCosP);

		let sinRCosP = 2.0f * (q.W * q.Z + q.X * q.Y);
		let cosRCosP = 1.0f - 2.0f * (q.X * q.X + q.Z * q.Z);
		let roll = Math.Atan2(sinRCosP, cosRCosP);

		return .(pitch * (180.0f / Math.PI_f), yaw * (180.0f / Math.PI_f), roll * (180.0f / Math.PI_f));
	}

	public static Quaternion EulerToQuaternion(Vector3 euler)
	{
		let pitch = euler.X * (Math.PI_f / 180.0f);
		let yaw = euler.Y * (Math.PI_f / 180.0f);
		let roll = euler.Z * (Math.PI_f / 180.0f);

		let cp = Math.Cos(pitch * 0.5f);
		let sp = Math.Sin(pitch * 0.5f);
		let cy = Math.Cos(yaw * 0.5f);
		let sy = Math.Sin(yaw * 0.5f);
		let cr = Math.Cos(roll * 0.5f);
		let sr = Math.Sin(roll * 0.5f);

		return .(
			sp * cy * cr - cp * sy * sr,
			cp * sy * cr + sp * cy * sr,
			cp * cy * sr - sp * sy * cr,
			cp * cy * cr + sp * sy * sr
		);
	}
}
