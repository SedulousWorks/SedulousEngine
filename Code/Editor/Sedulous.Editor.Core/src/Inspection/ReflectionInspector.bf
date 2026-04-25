namespace Sedulous.Editor.Core;

using System;
using System.Reflection;
using System.Collections;
using Sedulous.Engine.Core;
using Sedulous.UI.Toolkit;

/// Holds the pre-edit value for undo command creation.
/// Allocated once per editor, captures avoid stack ref issues.
class EditTransaction
{
	public Variant PreEditValue;

	public ~this()
	{
		PreEditValue.Dispose();
	}

	public void CapturePreEdit(Component component, FieldInfo field)
	{
		PreEditValue.Dispose();
		PreEditValue = default;
		var val = Variant();
		if (field.GetValue(component, out val) case .Ok)
			PreEditValue = val;
	}

	public void Commit(Component component, FieldInfo field, EditorCommandStack commandStack)
	{
		var newVal = Variant();
		if (field.GetValue(component, out newVal) case .Ok)
		{
			let cmd = new PropertyChangeCommand(component, field, PreEditValue, newVal);
			commandStack.Execute(cmd);
			PreEditValue = default; // Ownership transferred to command
		}
	}
}

/// Default inspector that auto-generates PropertyGrid entries from a component's
/// public fields via reflection. Used when no custom IComponentInspector is registered.
class ReflectionInspector : IComponentInspector
{
	private Type mComponentType;
	private List<EditTransaction> mTransactions = new .() ~ DeleteContainerAndItems!(_);

	public this(Type componentType)
	{
		mComponentType = componentType;
	}

	public Type ComponentType => mComponentType;

	public void BuildInspector(Component component, PropertyGrid grid, InspectorContext ctx)
	{
		let type = component.GetType();
		Console.WriteLine("[ReflectionInspector] Building for type: {}", type.GetName(.. scope .()));

		int fieldCount = 0;
		for (let field in type.GetFields(.Public | .Instance))
		{
			fieldCount++;

			// Only inspect fields marked with [Property].
			let propResult = field.GetCustomAttribute<PropertyAttribute>();
			if (propResult case .Err)
			{
				Console.WriteLine("[ReflectionInspector]   SKIP (no [Property]): {}", field.Name);
				continue;
			}
			let propAttr = propResult.Value;

			// Skip fields marked [HideInInspector].
			if (field.HasCustomAttribute<HideInInspectorAttribute>())
			{
				Console.WriteLine("[ReflectionInspector]   SKIP [HideInInspector]: {}", field.Name);
				continue;
			}

			// Display name: attribute override or field name.
			let displayName = (propAttr.DisplayName.Length > 0) ? propAttr.DisplayName : StringView(field.Name);

			// Get category for grouping.
			StringView category = "";
			if (field.GetCustomAttribute<CategoryAttribute>() case .Ok(let catAttr))
				category = catAttr.Name;

			Console.WriteLine("[ReflectionInspector]   Field: '{}' type={} editor={} category='{}'",
				displayName, field.FieldType.GetName(.. scope .()), propAttr.Editor, category);

			AddFieldEditor(grid, component, field, ctx, category, displayName, propAttr.Editor);
		}
		Console.WriteLine("[ReflectionInspector] Total fields scanned: {} for {}", fieldCount, type.GetName(.. scope .()));
	}

	public void TeardownInspector()
	{
		DeleteContainerAndItems!(mTransactions);
		mTransactions = new .();
	}

	private void AddFieldEditor(PropertyGrid grid, Component component,
		FieldInfo field, InspectorContext ctx, StringView category,
		StringView displayName, PropertyEditorHint editorHint)
	{
		let fieldType = field.FieldType;
		let typeName = scope String();
		fieldType.GetName(typeName);

		let ptr = (uint8*)Internal.UnsafeCastToPtr(component) + field.MemberOffset;

		// Check for [Range] constraint
		float rangeMin = -1e9f;
		float rangeMax = 1e9f;
		bool hasRange = false;
		if (field.GetCustomAttribute<RangeAttribute>() case .Ok(let rangeAttr))
		{
			rangeMin = rangeAttr.Min;
			rangeMax = rangeAttr.Max;
			hasRange = true;
		}

		// float
		if (fieldType == typeof(float))
		{
			Console.WriteLine("[ReflectionInspector]     -> float editor for '{}'", field.Name);
			let floatPtr = (float*)ptr;

			if (hasRange && editorHint == .Slider)
			{
				let editor = new RangeEditor(displayName, *floatPtr,
					rangeMin, rangeMax, 0.01f, category: category);
				WireEditor(editor, component, field, ctx);
				editor.Setter = new [=floatPtr, =rangeMin, =rangeMax] (v) => {
					*floatPtr = (float)Math.Clamp(v, rangeMin, rangeMax);
				};
				grid.AddProperty(editor);
			}
			else
			{
				let editor = new FloatEditor(displayName, *floatPtr,
					min: rangeMin, max: rangeMax, category: category);
				WireEditor(editor, component, field, ctx);
				editor.Setter = new [=floatPtr, =rangeMin, =rangeMax] (v) => {
					*floatPtr = (float)Math.Clamp(v, rangeMin, rangeMax);
				};
				grid.AddProperty(editor);
			}
			return;
		}

		// int32
		if (fieldType == typeof(int32))
		{
			Console.WriteLine("[ReflectionInspector]     -> int32 editor for '{}'", field.Name);
			let intPtr = (int32*)ptr;
			let editor = new IntEditor(displayName, (int64)*intPtr,
				min: hasRange ? (int64)rangeMin : int64.MinValue,
				max: hasRange ? (int64)rangeMax : int64.MaxValue,
				category: category);
			WireEditor(editor, component, field, ctx);
			let clampMin = (int32)rangeMin;
			let clampMax = (int32)rangeMax;
			editor.Setter = new [=intPtr, =hasRange, =clampMin, =clampMax] (v) => {
				*intPtr = hasRange ? (int32)Math.Clamp(v, clampMin, clampMax) : (int32)v;
			};
			grid.AddProperty(editor);
			return;
		}

		// uint32
		if (fieldType == typeof(uint32))
		{
			Console.WriteLine("[ReflectionInspector]     -> uint32 editor for '{}'", field.Name);
			let uintPtr = (uint32*)ptr;
			let editor = new IntEditor(displayName, (int64)*uintPtr,
				min: hasRange ? (int64)rangeMin : 0,
				max: hasRange ? (int64)rangeMax : (int64)uint32.MaxValue,
				category: category);
			WireEditor(editor, component, field, ctx);
			let clampMax = hasRange ? (uint32)rangeMax : uint32.MaxValue;
			editor.Setter = new [=uintPtr, =clampMax] (v) => {
				*uintPtr = (uint32)Math.Clamp(v, 0, clampMax);
			};
			grid.AddProperty(editor);
			return;
		}

		// bool
		if (fieldType == typeof(bool))
		{
			Console.WriteLine("[ReflectionInspector]     -> bool editor for '{}'", field.Name);
			let boolPtr = (bool*)ptr;
			let editor = new BoolEditor(displayName, *boolPtr, category: category);
			WireEditor(editor, component, field, ctx);
			editor.Setter = new [=boolPtr] (v) => { *boolPtr = v; };
			grid.AddProperty(editor);
			return;
		}

		// String
		if (fieldType == typeof(String))
		{
			Console.WriteLine("[ReflectionInspector]     -> String editor for '{}'", field.Name);
			let strPtr = (String*)ptr;
			let strVal = (*strPtr != null) ? StringView(*strPtr) : "";
			let editor = new StringEditor(displayName, strVal, category: category);
			editor.Setter = new [=strPtr] (v) => {
				if (*strPtr != null)
					(*strPtr).Set(v);
			};
			grid.AddProperty(editor);
			return;
		}

		// Fallback: show as read-only label
		Console.WriteLine("[ReflectionInspector]     -> FALLBACK (unsupported type '{}') for '{}'", typeName, field.Name);
		grid.AddProperty(new StringEditor(displayName, scope $"({typeName})", category: category));
	}

	/// Wires OnEditBegin/OnEditEnd to create PropertyChangeCommands for undo.
	/// TODO: Re-enable undo once pointer-based value capture is implemented.
	private void WireEditor(PropertyEditor editor, Component component, FieldInfo field, InspectorContext ctx)
	{
	}

	public void Dispose()
	{
		DeleteContainerAndItems!(mTransactions);
		mTransactions = null;
	}
}
