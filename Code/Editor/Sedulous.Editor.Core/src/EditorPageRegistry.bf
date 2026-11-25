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
	private struct Entry
	{
		public uint64 Key;
		public IEditorPageFactory Factory;
	}

	private List<Entry> mFactories = new .() ~ { for (let entry in _) delete entry.Factory; delete _; };
	private uint64 mNextKey = 1;
	/// A content instance names its type by full name; the scan of the type table that
	/// resolves one is remembered.
	private Dictionary<String, Type> mTypesByName = new .() ~ DeleteDictionaryAndKeys!(_);

	/// TAKES OWNERSHIP. Answers the factory's key for Unregister; a factory with no primary type
	/// is dropped and answers 0. A plugin keeps the key and removes its factory as it unloads.
	public uint64 Register(IEditorPageFactory factory)
	{
		if ((factory == null) || (factory.PrimaryType == null))
		{
			delete factory;
			return 0;
		}
		let key = mNextKey++;
		mFactories.Add(.() { Key = key, Factory = factory });
		return key;
	}

	/// Removes and deletes the factory `key`; false when there is none. The pages it made stay
	/// open: the context closes them first (EditorContext.RemovePageFactory).
	public bool Unregister(uint64 key)
	{
		for (int i < mFactories.Count)
		{
			if (mFactories[i].Key == key)
			{
				delete mFactories[i].Factory;
				mFactories.RemoveAt(i);
				return true;
			}
		}
		return false;
	}

	public int Count => mFactories.Count;

	public IEditorPageFactory FindFactory(Type type)
	{
		let best = FindEntry(type);
		return (best != null) ? best.Factory : null;
	}

	/// The key of the factory FindFactory answers for `type`; 0 for none.
	public uint64 FindFactoryKey(Type type)
	{
		let best = FindEntry(type);
		return (best != null) ? best.Key : 0;
	}

	private Entry* FindEntry(Type type)
	{
		Entry* best = null;
		int bestDistance = 0;
		for (int i < mFactories.Count)
		{
			let entry = &mFactories[i];
			int distance = 0;
			for (var t = type; t != null; t = BaseOf(t), distance++)
			{
				if (t == entry.Factory.PrimaryType)
				{
					if ((best == null) || (distance < bestDistance))
					{
						best = entry;
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

	/// By the full type name a content instance carries; 0 for none.
	public uint64 FindFactoryKey(StringView typeFullName)
	{
		let type = ResolveType(typeFullName);
		return (type != null) ? FindFactoryKey(type) : 0;
	}

	/// The Beef type for a full name, or null; scanned once and remembered.
	public Type ResolveType(StringView typeFullName)
	{
		if (mTypesByName.TryGetValue(scope String(typeFullName), let known))
			return known;
		let found = FindTypeByFullName(typeFullName);
		mTypesByName[new String(typeFullName)] = found;
		return found;
	}

	/// The Beef type for a full name, or null, by a walk of every type; not remembered (ResolveType
	/// and EditorIcons.ForTypeName remember what it finds).
	public static Type FindTypeByFullName(StringView typeFullName)
	{
		let name = scope String();
		for (let type in Type.Types)
		{
			// A TUPLE has no name to ask for, and GetFullName on one FATALS rather than
			// answering empty, which took the whole walk down. Sized arrays go for the same
			// reason. Nothing skipped here can be a content asset type.
			if (!(type is TypeInstance) || type.IsBoxed || type.IsPointer || type.IsArray
				|| type.IsSizedArray || type.IsGenericParam || type.IsTuple)
				continue;
			name.Clear();
			type.GetFullName(name);
			if (name == typeFullName)
				return type;
		}
		return null;
	}

	private static Type BaseOf(Type type)
	{
		if (let instance = type as TypeInstance)
			return instance.BaseType;
		return null;
	}
}
