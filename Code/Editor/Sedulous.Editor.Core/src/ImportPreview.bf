using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.Editor.Core;

// What the import window shows of a file before it is imported (Raptor's import-window spec). A
// domain registers a preview factory for the asset types it imports, as it registers pages; the
// window asks for the one nearest the type the file's importer lists it by
// (IFileImporter.ListedTypeName), and shows its view with its facts under it. A type with no
// preview shows its facts alone. A preview reads the source file itself (nothing has been imported
// yet), off the main thread as a task on the editor's TaskPool, so a drop of large files never holds
// the window: it shows that it is reading, then its result; a preview that goes cancels its task, so
// its completion never runs after.

/// One file's preview, made for the window and dropped (deleted) when another file is chosen.
interface IImportPreview
{
	/// What the preview pane shows. BORROWED: the preview keeps a reference, and a parent takes
	/// its own.
	Node View { get; }
	/// The line under it, a fact each ("2048 x 2048", "RGBA, 8-bit"); empty while it reads and when
	/// the file did not read.
	Span<String> Facts { get; }
	/// Set by the window: called when the preview's facts change (its read arrived). TAKES
	/// OWNERSHIP; null clears it.
	void SetOnChanged(delegate void() onChanged);
	/// Called by the window when the file's settings changed, for a preview that shows them.
	void OnSettingsChanged()
	{
	}
	/// Called by the window before it imports or chooses another importer: stop what reads the
	/// file's prepared payload and wait for it, since the import may change that payload (a model's
	/// scale is applied to the model the importer read) and another importer frees it. A preview
	/// that reads none has nothing to stop.
	void StopReading()
	{
	}
}

/// What a preview implements when it can show one part of its file alone (the import window's tree):
/// the window asks for it when a part is selected in the tree, and for the whole file again when the
/// file is.
interface IImportPartPreview
{
	/// Shows `part` (an entry of the file's plan, borrowed) in place of the whole file; false when it
	/// cannot show that part, the whole file then staying in view.
	bool ShowPart(Sedulous.Pipeline.Importer.ImportPlanEntry part);
	/// Shows the whole file again.
	void ShowWhole();
}

/// The file a preview is made for: its path, its settings (null when its importer has none), and
/// what its importer read of it on a worker (null when it reads nothing ahead, or has not yet),
/// which a preview may show rather than read the file again. All BORROWED: the path and the
/// settings stay alive as long as the preview, the read at least through Create.
struct ImportPreviewSource
{
	public StringView Path;
	public Sedulous.Pipeline.Importer.ImportOptions Options;
	public Object Prepared;

	public this(StringView path, Sedulous.Pipeline.Importer.ImportOptions options = null, Object prepared = null)
	{
		Path = path;
		Options = options;
		Prepared = prepared;
	}
}

/// Makes previews of the files an importer lists by one asset type (and, by nearest type
/// dispatch, its subclasses, unless a nearer factory is registered).
interface IImportPreviewFactory
{
	Type AssetType { get; }
	/// A preview of `file`, any read it needs submitted to `tasks` (borrowed: it outlives the
	/// preview), OWNED by the caller; null when it shows nothing of it.
	IImportPreview Create(ImportPreviewSource file, TaskPool tasks);
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
