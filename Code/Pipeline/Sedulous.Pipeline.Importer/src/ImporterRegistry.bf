using System;
using System.Collections;

namespace Sedulous.Pipeline.Importer;

/// Extension to importer routing.
class ImporterRegistry
{
	/// OWNED: registering hands the importer over.
	private List<IFileImporter> mImporters = new .() ~ DeleteContainerAndItems!(_);
	/// Beside mImporters: each one's key.
	private List<uint64> mKeys = new .() ~ delete _;
	private uint64 mNextKey = 1;

	/// Takes ownership of the importer; its key for Unregister (0, nothing added, for null).
	public uint64 Register(IFileImporter importer)
	{
		if (importer == null)
			return 0;
		mImporters.Add(importer);
		mKeys.Add(mNextKey);
		return mNextKey++;
	}

	/// Removes (and deletes) the importer Register gave `key` for; false when there is none. A
	/// plugin's importers leave with it this way.
	public bool Unregister(uint64 key)
	{
		let index = mKeys.IndexOf(key);
		if (index < 0)
			return false;
		delete mImporters[index];
		mImporters.RemoveAt(index);
		mKeys.RemoveAt(index);
		return true;
	}

	/// The FIRST importer claiming the extension, or null.
	public IFileImporter FindFor(StringView @extension)
	{
		for (let importer in mImporters)
		{
			if (importer.Accepts(@extension))
				return importer;
		}
		return null;
	}

	/// EVERY importer claiming the extension, in registration order, appended to the list. More
	/// than one match is what makes a chooser worth offering, an image and a texture importer
	/// over the same extension being the usual case.
	public void FindAllFor(StringView @extension, List<IFileImporter> outMatches)
	{
		for (let importer in mImporters)
		{
			if (importer.Accepts(@extension))
				outMatches.Add(importer);
		}
	}

	public int Count => mImporters.Count;
}
