using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;

namespace Sedulous.Editor.Core;

/// The page factories, with Traktor's nearest type dispatch: the factory whose PrimaryType
/// is closest along the asset type's base chain wins, so a generic form page registered on
/// the Asset base serves everything a bespoke page does not claim.
class EditorPageRegistry
{
	private List<IEditorPageFactory> mFactories = new .() ~ DeleteContainerAndItems!(_);
	/// A content instance names its type by full name; the scan of the type table that
	/// resolves one is remembered.
	private Dictionary<String, Type> mTypesByName = new .() ~ DeleteDictionaryAndKeys!(_);

	/// TAKES OWNERSHIP. A factory with no primary type is dropped.
	public void Register(IEditorPageFactory factory)
	{
		if ((factory == null) || (factory.PrimaryType == null))
		{
			delete factory;
			return;
		}
		mFactories.Add(factory);
	}

	public int Count => mFactories.Count;

	public IEditorPageFactory FindFactory(Type type)
	{
		IEditorPageFactory best = null;
		int bestDistance = 0;
		for (let factory in mFactories)
		{
			int distance = 0;
			for (var t = type; t != null; t = BaseOf(t), distance++)
			{
				if (t == factory.PrimaryType)
				{
					if ((best == null) || (distance < bestDistance))
					{
						best = factory;
						bestDistance = distance;
					}
					break;
				}
			}
		}
		return best;
	}

	/// By the full type name a content instance carries.
	public IEditorPageFactory FindFactory(StringView typeFullName)
	{
		let type = ResolveType(typeFullName);
		return (type != null) ? FindFactory(type) : null;
	}

	/// The Beef type for a full name, or null; scanned once and remembered.
	public Type ResolveType(StringView typeFullName)
	{
		if (mTypesByName.TryGetValue(scope String(typeFullName), let known))
			return known;
		Type found = null;
		let name = scope String();
		for (let type in Type.Types)
		{
			if (!(type is TypeInstance) || type.IsBoxed || type.IsPointer || type.IsArray || type.IsGenericParam)
				continue;
			name.Clear();
			type.GetFullName(name);
			if (name == typeFullName)
			{
				found = type;
				break;
			}
		}
		mTypesByName[new String(typeFullName)] = found;
		return found;
	}

	private static Type BaseOf(Type type)
	{
		if (let instance = type as TypeInstance)
			return instance.BaseType;
		return null;
	}
}
