using System;

namespace Sedulous.Editor.Scene;

static class PropertyNames
{
	/// "castsShadows" to "Casts Shadows", "fovYRadians" to "Fov Y Radians", "IBL" stays.
	/// Callable at comptime, so a generated label costs nothing at run time.
	public static void Prettify(StringView name, String outName)
	{
		outName.Clear();
		var prevLower = false;
		var prevUpper = false;
		for (int i < name.Length)
		{
			var c = name[i];
			let upper = (c >= 'A') && (c <= 'Z');
			let lower = (c >= 'a') && (c <= 'z');
			if ((i == 0) && lower)
			{
				c = (char8)(c - ('a' - 'A'));
			}
			else if (upper)
			{
				let nextLower = (i + 1 < name.Length) && (name[i + 1] >= 'a') && (name[i + 1] <= 'z');
				if (prevLower || (prevUpper && nextLower))
					outName.Append(' ');
			}
			outName.Append(c);
			prevLower = lower;
			prevUpper = upper;
		}
	}

	/// A component type's label: its [DisplayName], else the name minus "Component", prettified.
	public static void ComponentLabel(StringView typeName, String outLabel)
	{
		var n = typeName;
		let suffix = "Component";
		if ((n.Length > suffix.Length) && n.EndsWith(suffix))
			n = n.Substring(0, n.Length - suffix.Length);
		Prettify(n, outLabel);
	}
}
