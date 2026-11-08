using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Content.Tests;

/// Made from a file, as an asset is, and counting its payload's reads.
[Serializable(0, true)] // afterRead
class SourcedRecord
{
	public String File = new .() ~ delete _;

	public static int Reads;

	public void AfterRead()
	{
		Reads++;
	}

	public StringView SourceName() => File;
}
