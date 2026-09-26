using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Editor.Core;
using Sedulous.Editor.Mcp;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The editor host's operations over the REAL services on a scratch project: a cook is
/// requested through the cook service and answered not finished until its revision lands; an
/// import runs the two phase path (worker prepare, main thread placement, the deferred flush
/// on the job service) and lands its stream; an export cooks first and then runs the export
/// job, whose failure (no template here) reaches the re-entered call as the tool's error.
/// Every step is pumped the way the editor pumps: the services' Update, then the operation
/// again.
class EditorProjectOperationsTests
{
	/// A two phase importer: the worker "reads" the file into a payload, the main thread
	/// places the asset, and one deferred stream write carries the bulk.
	class TwoPhaseImporter : IFileImporter
	{
		private bool mWorker;
		private bool mFailPlacement;
		public int Prepares = 0;
		public int Imports = 0;
		public bool SawPrepared = false;

		public this(bool worker, bool failPlacement = false)
		{
			mWorker = worker;
			mFailPlacement = failPlacement;
		}

		public StringView Label => "TwoPhase";
		public bool Accepts(StringView @extension) => @extension == "two";
		public bool WantsWorkerPrepare => mWorker;

		public Object PrepareOnWorker(StringView sourcePath)
		{
			Prepares++;
			return new Object();
		}

		public Result<Instance, ErrorCode> Import(StringView sourcePath, ImportContext context, Group group,
			ImportOptions options, Object prepared, List<DeferredImportWrite> deferredWrites)
		{
			Imports++;
			SawPrepared = (prepared != null);
			if (mFailPlacement)
				return .Err(.InvalidArgument);
			let instance = group.CreateInstance("Imported", "Tests.Blob");
			if (deferredWrites != null)
			{
				let write = new DeferredImportWrite();
				write.Instance = instance;
				write.StreamName.Set("bulk");
				write.Owned.Add(7);
				write.Owned.Add(9);
				deferredWrites.Add(write);
			}
			return instance;
		}
	}

	/// Everything an operations object runs on, over a scratch project.
	class Bench
	{
		public EditorProject Project ~ delete _;
		public EditorContext Context = new .() ~ delete _;
		public BuilderRegistry Builders = new .() ~ delete _;
		public EditorCookService Cook = new .() ~ delete _;
		public EditorJobService Jobs = new .() ~ delete _;
		public String Dir = new .() ~ delete _;

		public this(StringView leaf)
		{
			Dir.Set(leaf);
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "Ops") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Cook.Initialize(Project, Builders);
			// The app's wiring: a running job holds the databases like a cook does.
			let jobs = Jobs;
			Cook.ExternalMutationLock = new [=jobs]() => jobs.IsBusy;
		}

		public ~this()
		{
			Cook.Shutdown();
			Jobs.Shutdown();
			DeleteAndNullify!(Project);
			RemoveDirectoryRecursive(Dir);
		}

		/// The seams over this bench; the caller hands them to the operations, which own them.
		public EditorProjectOperationsSeams Seams(double timeoutSeconds = 30.0)
		{
			let seams = new EditorProjectOperationsSeams();
			seams.Project = Project;
			seams.Context = Context;
			seams.Cook = Cook;
			seams.Jobs = Jobs;
			seams.Builders = Builders;
			seams.TimeoutSeconds = timeoutSeconds;
			return seams;
		}

		/// One editor frame: the services' main thread pumps.
		public void Pump()
		{
			Cook.Update();
			Jobs.Update();
			Thread.Sleep(1);
		}
	}

	/// Re-enters the step after each pump until it answers, as the host's pump does; waited
	/// counts the not finished answers, the frames the caller waited.
	private static OperationStep Drive(Bench bench, delegate OperationStep() step, out int waited)
	{
		waited = 0;
		for (int i < 5000)
		{
			let result = step();
			if (result != .NotYet)
				return result;
			waited++;
			bench.Pump();
		}
		return .Failed;
	}

	[Test]
	public static void ACookRidesTheCookServiceUntilItsRevisionLands()
	{
		let bench = scope Bench("mcp_ops_cook");
		let ops = scope EditorProjectOperations(bench.Seams());
		CookOutcome outcome = .();
		let error = scope String();
		int waited;
		Test.Assert(Drive(bench, scope [&]() => ops.Cook(false, ref outcome, error), out waited) == .Finished, error);
		Test.Assert(waited >= 1); // the first entry only requested; the worker answered later
		Test.Assert(outcome.Planned == 0);
		Test.Assert(bench.Cook.Revision == 1);

		// The state resets: a second cook starts a new wait rather than answering from the old.
		Test.Assert(Drive(bench, scope [&]() => ops.Cook(true, ref outcome, error), out waited) == .Finished, error);
		Test.Assert(waited >= 1);
		Test.Assert(bench.Cook.Revision == 2);
	}

	[Test]
	public static void AnImportRunsTheTwoPhasePathAndLandsItsStream()
	{
		let bench = scope Bench("mcp_ops_import");
		let ops = scope EditorProjectOperations(bench.Seams());
		let importer = scope TwoPhaseImporter(true);
		ImportRequest request = .();
		request.Source = "anything.two";
		request.Importer = importer;

		let outcome = scope ImportOutcome();
		let error = scope String();
		int waited;
		Test.Assert(Drive(bench, scope [&]() => ops.Import(request, outcome, error), out waited) == .Finished, error);
		Test.Assert(waited >= 2); // the prepare job, then the flush job, each landed through a pump
		Test.Assert(importer.Prepares == 1);
		Test.Assert(importer.Imports == 1);
		Test.Assert(importer.SawPrepared);
		Test.Assert(outcome.Name == "Imported");
		// The bulk write reached the instance's stream.
		let instance = bench.Project.SourceDb.GetInstance(outcome.Id);
		Test.Assert(instance != null);
		let bulk = instance.ReadData("bulk");
		Test.Assert(bulk != null);
		defer delete bulk;
		Test.Assert(bulk.Size() == 2);

		// An inline importer (no worker prepare) places at once and still flushes on the job.
		let inlineImporter = scope TwoPhaseImporter(false);
		request.Importer = inlineImporter;
		Test.Assert(Drive(bench, scope [&]() => ops.Import(request, outcome, error), out waited) == .Finished, error);
		Test.Assert(inlineImporter.Prepares == 0);
		Test.Assert(!inlineImporter.SawPrepared);

		// A placement failure is the tool's error, and the state is clean for the next call.
		let failing = scope TwoPhaseImporter(false, true);
		request.Importer = failing;
		Test.Assert(Drive(bench, scope [&]() => ops.Import(request, outcome, error), out waited) == .Failed);
		Test.Assert(error.StartsWith("import of 'anything.two' failed"), error);
		error.Clear();
		request.Importer = inlineImporter;
		Test.Assert(Drive(bench, scope [&]() => ops.Import(request, outcome, error), out waited) == .Finished, error);
	}

	[Test]
	public static void AnExportCooksFirstThenRunsTheJobWhoseFailureReachesTheCall()
	{
		let bench = scope Bench("mcp_ops_export");
		let ops = scope EditorProjectOperations(bench.Seams());
		let presets = scope ExportPresetSet();
		ExportPresetsFile.Defaults(presets);
		Test.Assert(presets.Presets.Count > 0);
		ExportRequest request = .();
		request.Preset = presets.Presets[0];
		request.OutRoot = "mcp_ops_export/Dist";

		let result = scope ExportResult();
		let error = scope String();
		int waited;
		// No template is installed here, so the job fails: after the cook landed and the job ran.
		Test.Assert(Drive(bench, scope [&]() => ops.Export(request, result, error), out waited) == .Failed);
		Test.Assert(error.StartsWith("export of preset '"), error);
		Test.Assert(waited >= 2);
		Test.Assert(bench.Cook.Revision == 1); // the export's cook went through the cook service
		Test.Assert(!bench.Jobs.IsBusy);
	}
}
