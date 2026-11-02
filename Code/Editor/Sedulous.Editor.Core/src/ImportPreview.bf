using System;
using System.Collections;
using Sedulous.GUI;

namespace Sedulous.Editor.Core;

// What the import window shows of a file before it is imported (Raptor's import-window spec). A
// domain registers a preview factory for the asset types it imports, as it registers pages; the
// window asks for the one nearest the type the file's importer lists it by
// (IFileImporter.ListedTypeName), and shows its view with its facts under it. A type with no
// preview shows its facts alone. A preview reads the source file itself: nothing has been
// imported yet.

/// One file's preview, made for the window and dropped (deleted) when another file is chosen.
interface IImportPreview
{
	/// What the preview pane shows. BORROWED: the preview keeps a reference, and a parent takes
	/// its own.
	Node View { get; }
	/// The line under it, a fact each ("2048 x 2048", "RGBA, 8-bit"); empty when the file did not
	/// read.
	Span<String> Facts { get; }
}

/// Makes previews of the files an importer lists by one asset type (and, by nearest type
/// dispatch, its subclasses, unless a nearer factory is registered).
interface IImportPreviewFactory
{
	Type AssetType { get; }
	/// A preview of the source file at `path`, OWNED by the caller; null when it shows nothing of it.
	IImportPreview Create(StringView path);
}

/// The import previews, by asset type: the factory nearest along a type's base chain wins, as
/// the page factories' does.
class ImportPreviewRegistry
{
	private List<IImportPreviewFactory> mFactories = new .() ~ DeleteContainerAndItems!(_);
	/// FindByName's types by full name, remembered; null is a name no type has. Keys owned.
	private Dictionary<String, Type> mTypesByName = new .() ~ DeleteDictionaryAndKeys!(_);

	/// TAKES OWNERSHIP. A factory with no asset type is dropped.
	public void Register(IImportPreviewFactory factory)
	{
		if ((factory == null) || (factory.AssetType == null))
		{
			delete factory;
			return;
		}
		mFactories.Add(factory);
	}

	public int Count => mFactories.Count;

	/// The factory for `type`'s nearest registered type along its base chain; null when none.
	public IImportPreviewFactory Find(Type type)
	{
		for (var t = type; t != null; t = t.BaseType)
		{
			for (let factory in mFactories)
			{
				if (factory.AssetType == t)
					return factory;
			}
		}
		return null;
	}

	/// Find for the type of FULL name `typeFullName`, as an importer names the type it lists a file
	/// by; null when no type has the name.
	public IImportPreviewFactory FindByName(StringView typeFullName)
	{
		if (typeFullName.IsEmpty)
			return null;
		Type type;
		if (mTypesByName.TryGetValue(scope String(typeFullName), let known))
			type = known;
		else
		{
			type = EditorPageRegistry.FindTypeByFullName(typeFullName);
			mTypesByName[new String(typeFullName)] = type;
		}
		return (type != null) ? Find(type) : null;
	}
}
