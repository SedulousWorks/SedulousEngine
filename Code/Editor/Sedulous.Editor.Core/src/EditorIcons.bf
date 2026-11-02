using System;
using System.Collections;
using Sedulous.Core; // CategoryAttribute

namespace Sedulous.Editor.Core;

/// A type's icon as a list row shows it: the image's source and the class that tints it.
class TypeIcon
{
	/// "Editor/Icons/Types/MeshComponent.svg", or empty: no icon anywhere.
	public String Source = new .() ~ delete _;
	/// "cat-rendering", or empty: no category, the plain icon colour.
	public String Class = new .() ~ delete _;
}

/// A type's icon, found by asking the type, never from a list of type names: the icon named
/// after it (Editor/Icons/Types/<Name>.svg), else its base's, up the chain, else a generic one
/// the caller names (Component, Asset). Its tint is a class a sheet styles, from the category the type
/// declares ([Category], its own or its nearest base's): "Rendering" is `cat-rendering`. A type
/// with no category keeps the plain icon colour.
///
/// A component is a struct, so its chain is ValueType and Object, which have no icons: a
/// component without its own icon takes the generic one. An asset's chain is its classes
/// (EnvironmentProfileAsset, SettingsProfileAsset, Asset).
class EditorIcons
{
	/// The folder type icons are in, relative to the editor's resources.
	public const String cTypeIconFolder = "Editor/Icons/Types/";

	/// What was found for one type, by the fallback it was asked with.
	private class Known
	{
		public String Fallback = new .() ~ delete _;
		public TypeIcon Icon = new .() ~ delete _;
	}

	private delegate bool(StringView path) mExists ~ delete _;
	/// By the type; freed in ~this, its lists' items with them.
	private Dictionary<Type, List<Known>> mCache = new .();
	/// The types ForTypeName looked for, by full name; null is a name no type has. Keys owned.
	private Dictionary<String, Type> mTypesByName = new .() ~ DeleteDictionaryAndKeys!(_);
	/// ForTypeName's answers for a name no type has, by fallback; freed by Forget.
	private Dictionary<String, TypeIcon> mUnnamed = new .();

	/// `exists` says whether a file is there (the editor's resources answer it). OWNERSHIP
	/// transfers.
	public this(delegate bool(StringView path) exists)
	{
		mExists = exists;
	}

	public ~this()
	{
		Forget();
		delete mCache;
		delete mUnnamed;
	}

	/// The icon of `type`: its own, else its nearest base's, else `fallback`'s (a generic type
	/// name: Component, Asset), else none; its class from the nearest category. Borrowed: kept
	/// until Forget.
	public TypeIcon For(Type type, StringView fallback)
	{
		List<Known> known;
		if (mCache.TryGetValue(type, out known))
		{
			for (let k in known)
			{
				if (k.Fallback == fallback)
					return k.Icon;
			}
		}
		else
		{
			known = new .();
			mCache[type] = known;
		}

		let entry = new Known();
		entry.Fallback.Set(fallback);
		known.Add(entry);
		let icon = entry.Icon;

		let name = scope String();
		let path = scope String();
		for (Type t = type; (t != null) && icon.Source.IsEmpty; t = t.BaseType)
		{
			name.Clear();
			t.GetName(name);
			if (name.IsEmpty)
				continue;
			IconPath(name, path);
			if (Exists(path))
				icon.Source.Set(path);
		}
		if (icon.Source.IsEmpty && !fallback.IsEmpty)
		{
			IconPath(fallback, path);
			if (Exists(path))
				icon.Source.Set(path);
		}
		// [Category] is not inherited, so the nearest one up the chain is looked for here.
		for (Type t = type; (t != null) && icon.Class.IsEmpty; t = t.BaseType)
		{
			if (t.GetCustomAttribute<CategoryAttribute>() case .Ok(let category))
				CategoryClass(category.Name, icon.Class);
		}
		return icon;
	}

	/// The icon of the type named `typeFullName` (as an importer names the asset type it makes:
	/// IFileImporter.ListedTypeName), as For finds it; `fallback`'s when no type has that name, else
	/// none. Borrowed: kept until Forget.
	public TypeIcon ForTypeName(StringView typeFullName, StringView fallback)
	{
		Type type = null;
		if (!typeFullName.IsEmpty)
		{
			if (mTypesByName.TryGetValue(scope String(typeFullName), let known))
				type = known;
			else
			{
				type = EditorPageRegistry.FindTypeByFullName(typeFullName);
				mTypesByName[new String(typeFullName)] = type;
			}
		}
		if (type != null)
			return For(type, fallback);

		if (mUnnamed.TryGetValue(scope String(fallback), let shown))
			return shown;
		let icon = new TypeIcon();
		mUnnamed[new String(fallback)] = icon;
		if (!fallback.IsEmpty)
		{
			let path = IconPath(fallback, .. scope .());
			if (Exists(path))
				icon.Source.Set(path);
		}
		return icon;
	}

	/// Forgets what it found (the icon files changed on disk). What For and ForTypeName returned
	/// is freed.
	public void Forget()
	{
		for (let list in mCache.Values)
			DeleteContainerAndItems!(list);
		mCache.Clear();
		for (let pair in mUnnamed)
		{
			delete pair.key;
			delete pair.value;
		}
		mUnnamed.Clear();
	}

	/// The class a category tints by: "cat-" and its letters and digits in lower case
	/// ("Rendering": cat-rendering; "Visual Effects": cat-visualeffects), appended to `outClass`;
	/// nothing when the category has neither.
	public static void CategoryClass(StringView category, String outClass)
	{
		let start = outClass.Length;
		outClass.Append("cat-");
		bool any = false;
		for (let c in category.RawChars)
		{
			if ((c >= 'A') && (c <= 'Z'))
				outClass.Append((char8)((uint8)c - (uint8)'A' + (uint8)'a'));
			else if (((c >= 'a') && (c <= 'z')) || ((c >= '0') && (c <= '9')))
				outClass.Append(c);
			else
				continue;
			any = true;
		}
		if (!any)
			outClass.RemoveToEnd(start);
	}

	private bool Exists(StringView path) => (mExists != null) && mExists(path);

	private static void IconPath(StringView typeName, String outPath)
	{
		outPath.Set(cTypeIconFolder);
		outPath.Append(typeName);
		outPath.Append(".svg");
	}
}
