using System;
using Sedulous.Core;

namespace Sedulous.Script.Resource;

/// The name hashing an override is keyed by. Stable across builds and platforms, since it
/// is written into scene files.
static class ScriptPropertyNames
{
	public static uint64 HashOf(StringView name) => HashText(name);

	/// The parsed "float" / "asset:AudioClip" type text a script declares a property with,
	/// to its kind and, for an asset, the product type name. False for anything else.
	public static bool Parse(StringView text, out ScriptPropertyType outKind, String outAssetType)
	{
		outAssetType.Clear();
		outKind = .None;
		switch (text)
		{
		case "float": outKind = .Float; return true;
		case "int": outKind = .Int; return true;
		case "bool": outKind = .Bool; return true;
		case "string": outKind = .String; return true;
		case "color": outKind = .Color; return true;
		case "vec3": outKind = .Vec3; return true;
		case "entity": outKind = .Entity; return true;
		}
		const String cAssetPrefix = "asset:";
		if (text.StartsWith(cAssetPrefix) && (text.Length > cAssetPrefix.Length))
		{
			outKind = .Asset;
			outAssetType.Append(text.Substring(cAssetPrefix.Length));
			return true;
		}
		return false;
	}
}
