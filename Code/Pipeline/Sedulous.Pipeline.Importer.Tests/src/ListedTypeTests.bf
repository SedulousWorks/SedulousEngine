using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Pipeline.Importer.Tests;

/// The type a file is listed by (its icon in the import window): its one asset's, unless the
/// importer names another.
class ListedTypeTests
{
	/// Makes one asset of a made up type, and refuses to run.
	class SingleAssetImporter : IFileImporter
	{
		public StringView Label => "Single";

		public bool Accepts(StringView @extension) => @extension == "one";

		public StringView AssetTypeName(StringView sourcePath) => "Test.OneAsset";

		public Result<Instance, ErrorCode> Import(StringView sourcePath, ImportContext context,
			Group group, ImportOptions options, Object prepared,
			List<DeferredImportWrite> deferredWrites) => .Err(.NotSupported);
	}

	[Test]
	public static void AFileIsListedByTheOneAssetItsImporterMakes()
	{
		IFileImporter single = scope SingleAssetImporter();
		Test.Assert(single.ListedTypeName("a.one") == "Test.OneAsset", "the default follows the asset it makes");
		IFileImporter none = scope FakeImporter("Fake");
		Test.Assert(none.ListedTypeName("a.fak").IsEmpty, "an importer naming no type lists by none");
	}
}
