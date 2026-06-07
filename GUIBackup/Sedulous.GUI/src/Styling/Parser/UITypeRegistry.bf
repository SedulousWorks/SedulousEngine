namespace Sedulous.GUI;

using System;
using System.Collections;

/// Maps short string names to Beef types. Used by the .sss parser for
/// element selectors and by the .sml loader for element resolution.
/// One source of truth for "what type does the string 'Button' refer to?"
///
/// Built-in controls auto-register. User controls register theirs via
/// UITypeRegistry.Register("MyControl", typeof(MyControl)).
public static class UITypeRegistry
{
	private static Dictionary<String, Type> sTypes ~ DeleteDictionaryAndKeys!(_);

	static this()
	{
		EnsureRegistry();
	}

	private static void EnsureRegistry()
	{
		if(sTypes == null)
		{
			sTypes = new .();
		}
	}

	/// Register a type with a name. Overwrites if name already exists.
	public static void Register(StringView name, Type type)
	{
		EnsureRegistry();

		// Check for existing key to avoid duplicate string alloc
		for (let kv in sTypes)
		{
			if (StringView(kv.key) == name)
			{
				sTypes[kv.key] = type;
				return;
			}
		}
		sTypes[new String(name)] = type;
	}

	/// Register a type with its short name (type.GetName()).
	public static void Register(Type type)
	{
		let name = scope String();
		type.GetName(name);
		Register(name, type);
	}

	/// Look up a type by name. Returns null if not found.
	public static Type Resolve(StringView name)
	{
		for (let kv in sTypes)
		{
			if (StringView(kv.key) == name)
				return kv.value;
		}
		return null;
	}

	/// Returns the number of registered types.
	public static int Count => sTypes.Count;

	/// Register all built-in GUI types. Called during framework init.
	public static void RegisterBuiltins()
	{
		// Core
		Register("View", typeof(View));
		Register("ViewGroup", typeof(ViewGroup));
		Register("RootView", typeof(RootView));
		Register("Panel", typeof(Panel));

		// Layouts
		Register("FlexLayout", typeof(FlexLayout));
		Register("Flex", typeof(FlexLayout));  // alias
		Register("GridLayout", typeof(GridLayout));
		Register("Grid", typeof(GridLayout));  // alias
		Register("DockLayout", typeof(DockLayout));
		Register("Dock", typeof(DockLayout));  // alias
		Register("FrameLayout", typeof(FrameLayout));
		Register("Frame", typeof(FrameLayout));  // alias
		Register("AbsoluteLayout", typeof(AbsoluteLayout));
		Register("Absolute", typeof(AbsoluteLayout));  // alias
		Register("FlowLayout", typeof(FlowLayout));
		Register("Flow", typeof(FlowLayout));  // alias

		// Controls will register themselves as they are implemented
		// in the control phases (C1-C8).
	}
}
