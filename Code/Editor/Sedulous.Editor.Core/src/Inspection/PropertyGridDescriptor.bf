namespace Sedulous.Editor.Core;

using System;
using Sedulous.Engine.Core;
using Sedulous.Core.Mathematics;
using Sedulous.Resources;
using Sedulous.UI.Toolkit;
using Sedulous.Inspection;
using Sedulous.Particles;

/// Implements IPropertyDescriptor to build PropertyGrid entries from
/// comptime-generated DescribeProperties calls.
class PropertyGridDescriptor : IPropertyDescriptor
{
	protected PropertyGrid mGrid;
	private String mCurrentCategory = new .() ~ delete _;

	public StringView CurrentCategory => mCurrentCategory;

	public this(PropertyGrid grid)
	{
		mGrid = grid;
	}

	/// Sets displayName on an editor if it differs from name.
	protected void ApplyDisplayName(PropertyEditor editor, StringView name, StringView displayName)
	{
		if (displayName != name)
			editor.SetDisplayName(displayName);
	}

	public void Float(StringView name, StringView displayName, float* ptr, float min, float max)
	{
		let editor = new FloatEditor(name, *ptr, min: min, max: max, decimalPlaces: 4, category: mCurrentCategory);
		editor.Setter = new [=ptr, =min, =max] (v) => {
			*ptr = (float)Math.Clamp(v, min, max);
		};
		ApplyDisplayName(editor, name, displayName);
		mGrid.AddProperty(editor);
	}

	public void Int32(StringView name, StringView displayName, int32* ptr, int32 min, int32 max)
	{
		let editor = new IntEditor(name, (int64)*ptr, min: (int64)min, max: (int64)max, category: mCurrentCategory);
		editor.Setter = new [=ptr, =min, =max] (v) => {
			*ptr = (int32)Math.Clamp(v, min, max);
		};
		ApplyDisplayName(editor, name, displayName);
		mGrid.AddProperty(editor);
	}

	public void UInt32(StringView name, StringView displayName, uint32* ptr, uint32 min, uint32 max)
	{
		let editor = new IntEditor(name, (int64)*ptr, min: (int64)min, max: (int64)max, category: mCurrentCategory);
		editor.Setter = new [=ptr, =min, =max] (v) => {
			*ptr = (uint32)Math.Clamp(v, (int64)min, (int64)max);
		};
		ApplyDisplayName(editor, name, displayName);
		mGrid.AddProperty(editor);
	}

	public void Bool(StringView name, StringView displayName, bool* ptr)
	{
		let editor = new BoolEditor(name, *ptr, category: mCurrentCategory);
		editor.Setter = new [=ptr] (v) => { *ptr = v; };
		ApplyDisplayName(editor, name, displayName);
		mGrid.AddProperty(editor);
	}

	public void Str(StringView name, StringView displayName, String* ptr)
	{
		let strVal = (*ptr != null) ? StringView(*ptr) : "";
		let editor = new StringEditor(name, strVal, category: mCurrentCategory);
		editor.Setter = new [=ptr] (v) => {
			if (*ptr != null)
				(*ptr).Set(v);
		};
		ApplyDisplayName(editor, name, displayName);
		mGrid.AddProperty(editor);
	}

	public void Slider(StringView name, StringView displayName, float* ptr, float min, float max)
	{
		let editor = new RangeEditor(name, *ptr, min: min, max: max, category: mCurrentCategory);
		editor.Setter = new [=ptr, =min, =max] (v) => {
			*ptr = (float)Math.Clamp(v, min, max);
		};
		ApplyDisplayName(editor, name, displayName);
		mGrid.AddProperty(editor);
	}

	public void Vec3(StringView name, StringView displayName, Vector3* ptr)
	{
		let editor = new Vector3Editor(name, *ptr, category: mCurrentCategory);
		editor.Setter = new [=ptr] (v) => { *ptr = v; };
		ApplyDisplayName(editor, name, displayName);
		mGrid.AddProperty(editor);
	}

	/// Vector4 field with no color semantics (4 generic NumericFields).
	/// Used when [Property] has no Color hint.
	public virtual void Vec4(StringView name, StringView displayName, Vector4* ptr)
	{
		// Base implementation: read-only display showing the four floats.
		// EditorPropertyGridDescriptor overrides with a real four-field
		// editor (or a Vector4Editor when one lands).
		let summary = scope String();
		summary.AppendF("({:F3}, {:F3}, {:F3}, {:F3})", ptr.X, ptr.Y, ptr.Z, ptr.W);
		mGrid.AddProperty(new StringEditor(name, summary, category: mCurrentCategory));
	}

	/// Vector4 field tagged with `[Property(.Color)]`. HDR-allowed color
	/// editor - swatch that opens an HDRColorPicker dialog on click.
	public virtual void Color4(StringView name, StringView displayName, Vector4* ptr)
	{
		// Base implementation: read-only RGBA display. Real swatch + HDR
		// picker lives in EditorPropertyGridDescriptor's override.
		let summary = scope String();
		summary.AppendF("rgba ({:F2}, {:F2}, {:F2}, {:F2})", ptr.X, ptr.Y, ptr.Z, ptr.W);
		mGrid.AddProperty(new StringEditor(name, summary, category: mCurrentCategory));
	}

	public void Quat(StringView name, StringView displayName, Quaternion* ptr)
	{
		// Display as euler angles, convert back on set
		let euler = QuaternionToEuler(*ptr);
		let editor = new Vector3Editor(name, euler, min: -360, max: 360, category: mCurrentCategory);
		editor.Setter = new [=ptr] (v) => {
			*ptr = EulerToQuaternion(v);
		};
		ApplyDisplayName(editor, name, displayName);
		mGrid.AddProperty(editor);
	}

	public void EnumField(StringView name, StringView displayName, void* ptr, Type enumType)
	{
		// Get enum value names
		let names = scope System.Collections.List<StringView>();
		for (let field in enumType.GetFields())
		{
			if (field.IsEnumCase)
				names.Add(field.Name);
		}

		// Read at the enum's actual storage size. Previously this code
		// hard-coded `*(int32*)ptr`, which for a uint8 / uint16 enum reads
		// 3-7 unrelated bytes of struct padding into the upper bits,
		// producing a garbage SelectedIndex (combo box renders no
		// selection). Same problem on write would clobber adjacent fields.
		let size = enumType.Size;
		int32 currentVal = ReadEnumValue(ptr, size);

		let editor = new EnumEditor(name, currentVal, names, category: mCurrentCategory);
		editor.Setter = new [=ptr, =size] (v) => { WriteEnumValue(ptr, size, v); };
		ApplyDisplayName(editor, name, displayName);
		mGrid.AddProperty(editor);
	}

	private static int32 ReadEnumValue(void* ptr, int size)
	{
		switch (size)
		{
		case 1: return *(uint8*)ptr;
		case 2: return *(uint16*)ptr;
		case 4: return *(int32*)ptr;
		case 8: return (int32)*(int64*)ptr;
		default: return *(int32*)ptr;
		}
	}

	private static void WriteEnumValue(void* ptr, int size, int32 value)
	{
		switch (size)
		{
		case 1: *(uint8*)ptr = (uint8)value;
		case 2: *(uint16*)ptr = (uint16)value;
		case 4: *(int32*)ptr = value;
		case 8: *(int64*)ptr = value;
		default: *(int32*)ptr = value;
		}
	}

	public virtual void ResRef(StringView name, StringView displayName, delegate ResourceRef() getter, delegate void(ResourceRef) setter,
		StringView extensionFilter = default)
	{
		// Base implementation: read-only display. Override in Editor.App for full editor.
		let @ref = getter();
		let display = scope String();
		if (@ref.HasPath)
			System.IO.Path.GetFileName(@ref.Path, display);
		else if (@ref.HasId)
			@ref.Id.ToString(display);
		else
			display.Set("(none)");
		mGrid.AddProperty(new StringEditor(name, display, category: mCurrentCategory));
		delete getter;
		delete setter;
	}

	public virtual void ResRefList(StringView name, StringView displayName, delegate int32() countGetter,
		delegate ResourceRef(int32) getter, delegate void(int32, ResourceRef) setter,
		StringView extensionFilter = default)
	{
		// Base implementation: read-only count display. Override in Editor.App for full editor.
		let count = countGetter();
		mGrid.AddProperty(new StringEditor(name, scope $"{count} refs", category: mCurrentCategory));
		delete countGetter;
		delete getter;
		delete setter;
	}

	public void BeginCategory(StringView name)
	{
		mCurrentCategory.Set(name);
	}

	public void EndCategory()
	{
		mCurrentCategory.Clear();
	}

	// ===== Particle IPropertyDescriptor extension methods =====
	// These must live on the base PropertyGridDescriptor so the interface
	// vtable carries slots for them everywhere PropertyGridDescriptor is
	// used (including projects like Sedulous.Particles that emit calls
	// through the extension). v1 implementations are read-only labels;
	// EditorPropertyGridDescriptor overrides them with real editors.

	public virtual void RangeFloat(StringView name, RangeFloat* ptr)
	{
		let summary = scope String();
		summary.AppendF("{:F3} .. {:F3}", ptr.Min, ptr.Max);
		mGrid.AddProperty(new StringEditor(name, summary, category: mCurrentCategory));
	}

	public virtual void RangeVector2(StringView name, RangeVector2* ptr)
	{
		let summary = scope String();
		summary.AppendF("({:F2},{:F2}) .. ({:F2},{:F2})",
			ptr.Min.X, ptr.Min.Y, ptr.Max.X, ptr.Max.Y);
		mGrid.AddProperty(new StringEditor(name, summary, category: mCurrentCategory));
	}

	public virtual void RangeColor(StringView name, RangeColor* ptr)
	{
		let summary = scope String();
		summary.AppendF("rgba ({:F2},{:F2},{:F2},{:F2}) .. ({:F2},{:F2},{:F2},{:F2})",
			ptr.Min.X, ptr.Min.Y, ptr.Min.Z, ptr.Min.W,
			ptr.Max.X, ptr.Max.Y, ptr.Max.Z, ptr.Max.W);
		mGrid.AddProperty(new StringEditor(name, summary, category: mCurrentCategory));
	}

	public virtual void CurveFloat(StringView name, ParticleCurveFloat* ptr, float displayMin = 0, float displayMax = 0)
	{
		let summary = scope $"({ptr.KeyCount} keys)";
		mGrid.AddProperty(new StringEditor(name, summary, category: mCurrentCategory));
	}

	public virtual void CurveColor(StringView name, ParticleCurveColor* ptr)
	{
		let summary = scope $"({ptr.KeyCount} keys)";
		mGrid.AddProperty(new StringEditor(name, summary, category: mCurrentCategory));
	}

	public virtual void CurveVector2(StringView name, ParticleCurveVector2* ptr, float displayMin = 0, float displayMax = 0)
	{
		let summary = scope $"({ptr.KeyCount} keys)";
		mGrid.AddProperty(new StringEditor(name, summary, category: mCurrentCategory));
	}

	public virtual void EmissionShape(StringView name, EmissionShape* ptr)
	{
		let summary = scope $"{ptr.Type}";
		mGrid.AddProperty(new StringEditor(name, summary, category: mCurrentCategory));
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
