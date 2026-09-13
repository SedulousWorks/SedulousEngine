using System;
using System.Collections;

namespace Sedulous.Pipeline.Importer;

/// Extension to importer routing.
class ImporterRegistry
{
	/// OWNED: registering hands the importer over.
	private List<IFileImporter> mImporters = new .() ~ DeleteContainerAndItems!(_);

	/// Takes ownership of the importer.
	public void Register(IFileImporter importer)
	{
		if (importer != null)
			mImporters.Add(importer);
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
