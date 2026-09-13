using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Pipeline.Importer.Tests;

/// An importer that claims one made up extension and refuses to run.
///
/// The routing cases measure the REGISTRY, so an importer that actually imported something
/// would only add a filesystem to the test.
class FakeImporter : IFileImporter
{
	private String mLabel = new .() ~ delete _;

	public this(StringView label)
	{
		mLabel.Set(label);
	}

	public StringView Label => mLabel;

	public bool Accepts(StringView @extension) => @extension == "fak";

	public Result<Instance, ErrorCode> Import(StringView sourcePath, ImportContext context,
		Group group, ImportOptions options, Object prepared,
		List<DeferredImportWrite> deferredWrites) => .Err(.NotSupported);
}
