using System;
using System.Collections;
using System.Threading;
using Sedulous.GUI;
using Sedulous.GUI.Pipeline;

namespace Sedulous.GUI.Pipeline.Tests;

/// Validation on several threads at once, as a cook's workers run it. The element types register on
/// the first validation of the process, so this class must run before any other test that
/// validates: tests run class by class in name order, and this name sorts first.
static class ConcurrentRegistrationTests
{
	/// Elements from the end of each library's registration: a worker that went on before the set was
	/// whole would not know them.
	const String cMarkup =
		"""
		<Panel>
		    <TableView/>
		    <TableItem/>
		    <ToolBar/>
		    <CodeEditor/>
		</Panel>
		""";

	const int cThreads = 8;

	/// One thread's validation, started with the others.
	class Worker
	{
		public bool Valid;
		public int Diagnostics = -1;
		public String Said = new .() ~ delete _;

		public void Run(Starter starter)
		{
			Interlocked.Increment(ref starter.Ready);
			while (!Volatile.Read(ref starter.Go))
				Thread.Yield();
			let found = scope List<GuiDiagnostic>();
			Valid = GuiPipeline.ValidateDocument(cMarkup, found);
			Diagnostics = found.Count;
			for (let diagnostic in found)
			{
				Said.AppendF("{} | ", diagnostic.Message);
				delete diagnostic;
			}
		}
	}

	/// Holds the workers until every one is waiting, then lets them go together.
	class Starter
	{
		public int Ready;
		public bool Go;
	}

	[Test]
	public static void ValidationsStartedTogetherEachSeeTheWholeElementSet()
	{
		let starter = scope Starter();
		let workers = scope List<Worker>();
		let threads = scope List<Thread>();
		defer
		{
			ClearAndDeleteItems!(threads);
			ClearAndDeleteItems!(workers);
		}
		for (int i < cThreads)
		{
			let worker = new Worker();
			workers.Add(worker);
			let thread = new Thread(new () => worker.Run(starter));
			threads.Add(thread);
			thread.Start(false);
		}
		while (Volatile.Read(ref starter.Ready) < cThreads)
			Thread.Yield();
		Volatile.Write(ref starter.Go, true);
		for (let thread in threads)
			thread.Join();
		for (let worker in workers)
		{
			Test.Assert(worker.Valid, worker.Said);
			Test.Assert(worker.Diagnostics == 0, worker.Said);
		}
	}
}
