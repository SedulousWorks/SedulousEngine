using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Editor.App.Tests;

/// The batch import dialog's Import gate. The owner assigns DescribeFile after construction
/// and then calls DescribeAll; an inline importer's files are described there and the gate
/// opens. The gate was once computed only in the constructor, with nothing described yet, and
/// never refreshed for inline importers, so a texture import showed the dialog with Import
/// disabled and the detail reading the file for good.
static class ImportDialogTests
{
	/// An importer with a single asset plan; inline or worker prepared as asked.
	private class StubImporter : IFileImporter
	{
		public int Describes = 0;
		private bool mWorker;

		public this(bool worker) { mWorker = worker; }

		public StringView Label => "Stub";
		public bool Accepts(StringView @extension) => @extension == "stub";
		public bool WantsWorkerPrepare => mWorker;

		public void DescribeImport(StringView sourcePath, ImportOptions options, Object prepared,
			ImportPlan outPlan)
		{
			Describes++;
			outPlan.Add(new ImportPlanEntry(.Mesh, "asset", "asset"));
		}

		public Result<Instance, ErrorCode> Import(StringView sourcePath, ImportContext context,
			Group group, ImportOptions options, Object prepared, List<DeferredImportWrite> deferredWrites)
			=> .Err(.Unknown); // never reached here
	}

	private static BatchImportFile Entry(StringView path, IFileImporter importer)
	{
		let entry = new BatchImportFile();
		entry.Path.Set(path);
		entry.Candidates.Add(importer);
		entry.Options = new ImportOptions();
		return entry;
	}

	/// The owner's describe policy: inline importers describe here; worker importers land
	/// through OnFilePrepared.
	private static void InlineDescribe(BatchImportFile entry)
	{
		let importer = entry.Importer;
		if (!importer.WantsWorkerPrepare)
		{
			importer.DescribeImport(entry.Path, entry.Options, null, entry.Plan);
			entry.Described = true;
		}
	}

	[Test]
	public static void DescribeAllDescribesInlineFilesAndOpensTheImportGate()
	{
		let texture = scope StubImporter(false);
		let files = new List<BatchImportFile>();
		files.Add(Entry("/drop/albedo.stub", texture));
		files.Add(Entry("/drop/normal.stub", texture));
		let dialog = new BatchImportDialog("/Assets", files);
		defer dialog.ReleaseRef();

		// Constructed: nothing described yet, so the gate is closed. This is the state the
		// owner must not leave the dialog in.
		Test.Assert(!dialog.ImportEnabled);
		Test.Assert(texture.Describes == 0);

		dialog.DescribeFile = new => InlineDescribe;
		dialog.DescribeAll();
		Test.Assert(texture.Describes == 2);
		Test.Assert(dialog.Files[0].Described);
		Test.Assert(dialog.Files[1].Described);
		Test.Assert(dialog.ImportEnabled);
	}

	[Test]
	public static void AWorkerPreparedFileKeepsTheGateClosedUntilItLands()
	{
		let texture = scope StubImporter(false);
		let model = scope StubImporter(true);
		let files = new List<BatchImportFile>();
		files.Add(Entry("/drop/albedo.stub", texture));
		files.Add(Entry("/drop/hero.stub", model));
		let dialog = new BatchImportDialog("/Assets", files);
		defer dialog.ReleaseRef();
		dialog.DescribeFile = new => InlineDescribe;
		dialog.DescribeAll();
		Test.Assert(dialog.Files[0].Described);
		Test.Assert(!dialog.Files[1].Described); // the worker one is still reading
		Test.Assert(!dialog.ImportEnabled);

		// The worker lands: the owner fills the entry and notifies, and the gate opens.
		let hero = dialog.Files[1];
		model.DescribeImport(hero.Path, hero.Options, null, hero.Plan);
		hero.Described = true;
		dialog.OnFilePrepared(1);
		Test.Assert(dialog.ImportEnabled);

		// A disabled, unchecked, undescribed file does not gate: only ENABLED files must be
		// ready.
		hero.Described = false;
		hero.Enabled = false;
		dialog.OnFilePrepared(1);
		Test.Assert(dialog.ImportEnabled);
	}
}
