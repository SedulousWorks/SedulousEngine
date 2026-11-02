using System;

namespace Sedulous.Pipeline.Importer;

/// One fact about a part a file would make, read from the file (IFileImporter.DescribePart):
/// "Triangles", "4,992".
class ImportPartFact
{
	public String Label = new .() ~ delete _;
	public String Value = new .() ~ delete _;

	public this(StringView label, StringView value)
	{
		Label.Set(label);
		Value.Set(value);
	}
}
