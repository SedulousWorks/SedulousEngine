namespace Sedulous.Editor.Core;

using System;
using System.Reflection;
using System.Collections;
using Sedulous.Scenes;
using Sedulous.UI.Toolkit;

/// Default inspector that auto-generates PropertyGrid entries from a component's
/// public fields via reflection. Used when no custom IComponentInspector is registered.
class ReflectionInspector : IComponentInspector
{
	private Type mComponentType;

	public this(Type componentType)
	{
		mComponentType = componentType;
	}

	public Type ComponentType => mComponentType;

	public void BuildInspector(Component component, PropertyGrid grid, InspectorContext ctx)
	{
		let type = component.GetType();

		// Group by [Category] attribute if present.
		for (let field in type.GetFields(.Public | .Instance))
		{
			// Skip fields marked [HideInInspector].
			if (field.HasCustomAttribute<HideInInspectorAttribute>())
				continue;

			// Skip internal/runtime fields (Initialized, Owner, IsActive).
			if (field.Name == "Initialized" || field.Name == "Owner" || field.Name == "IsActive")
				continue;

			// Get category for grouping.
			StringView category = "";
			if (field.GetCustomAttribute<CategoryAttribute>() case .Ok(let catAttr))
				category = catAttr.Name;

			// Get tooltip.
			StringView tooltip = "";
			if (field.GetCustomAttribute<TooltipAttribute>() case .Ok(let tipAttr))
				tooltip = tipAttr.Text;

			// Add property editor based on field type.
			AddFieldEditor(grid, component, field, ctx, category, tooltip);
		}
	}

	public void TeardownInspector()
	{
		// Editors are owned by the PropertyGrid - nothing to clean up here.
	}

	private void AddFieldEditor(PropertyGrid grid, Component component,
		FieldInfo field, InspectorContext ctx, StringView category, StringView tooltip)
	{
		let fieldType = field.FieldType;

		// TODO: Map field types to PropertyEditor subclasses:
		// - float, int32, uint32 -> FloatEditor/IntEditor (with [Range] -> RangeEditor)
		// - bool -> BoolEditor
		// - String -> StringEditor
		// - Vector3 -> Vector3Editor
		// - Color -> ColorEditor
		// - enum -> ComboBoxEditor (not yet)
		// - ResourceRef -> ResourceRefEditor (not yet)
		//
		// Wire OnEditBegin/OnEditEnd to PropertyChangeCommand creation.
		// Placeholder: add a StringEditor showing field name + type (read-only display).
		let label = scope String();
		label.AppendF("{} ({})", field.Name, fieldType.GetName(.. scope .()));
		grid.AddProperty(new StringEditor(label, "", category: category));
	}

	public void Dispose() { }
}
