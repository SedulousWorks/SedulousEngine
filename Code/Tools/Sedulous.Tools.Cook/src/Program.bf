using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.VFS;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Cook;
using Sedulous.Pipeline.Registration;
using Sedulous.Editor.Core;

namespace Sedulous.Tools.Cook;

/// The command line cooker. Headless: opens the project, registers every builder, plans and
/// executes the incremental cook.
///
/// Usage: Sedulous.Tools.Cook <projectDirectory> [--rebuild] [--dry-run] [--target <id>]
///   --rebuild      force cooks every buildable asset, the big hammer for a forgotten
///                  version bump
///   --dry-run      prints the plan, the dirty set and the orphans, without cooking
///   --target <id>  cooks a per target database beside the host's instead of the host's
///                  alone: the host first, then the platform invariant products carried
///                  forward and only the variant ones, the textures, cooked again for the
///                  target. "web-astc" is the ASTC mobile web target; everything else is BC
///                  desktop, and "host" is the default.
/// The exit code is the number of failed cooks, so 0 is success.
class Program
{
	public static int Main(String[] args)
	{
		if (args.Count < 1)
		{
			Console.Error.WriteLine("usage: Sedulous.Tools.Cook <projectDirectory> [--rebuild] [--dry-run] [--target <id>]");
			return 1;
		}
		bool rebuild = false;
		bool dryRun = false;
		let targetId = scope String("host");
		for (int i = 1; i < args.Count; i++)
		{
			if (args[i] == "--rebuild")
				rebuild = true;
			else if (args[i] == "--dry-run")
				dryRun = true;
			else if (args[i] == "--target")
			{
				if (i + 1 >= args.Count)
				{
					Console.Error.WriteLine("--target needs an id (e.g. web-astc)");
					return 1;
				}
				targetId.Set(args[++i]);
			}
			else
			{
				Console.Error.WriteLine("unknown option: {}", args[i]);
				return 1;
			}
		}

		InitGlobalLogger(new ConsoleLogger(.Information, "Cook"), true);
		defer ShutdownGlobalLogger();

		let projectDir = args[0];
		let project = EditorProject.Open(projectDir);
		if (project == null)
		{
			Console.Error.WriteLine("Sedulous.Tools.Cook: failed to open project '{}'", projectDir);
			return 1;
		}
		defer delete project;

		// The composition root: every type, backend and cook, then every builder. The
		// script cooks compile against the pipeline surface, which contains the runtime's.
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(builders);

		let sourcesMount = scope NativeFileSystem(project.SourcesRoot(.. scope .()));
		let cacheMount = scope NativeFileSystem(project.CacheRoot(.. scope .()));
		let jobs = scope JobSystem();

		let progress = scope CookProgress();
		progress.OnItem = new (done, total, path, ok) =>
			{
				Console.WriteLine("[{}/{}] {} {}", done, total, ok ? "ok  " : "FAIL", path);
			};
		defer delete progress.OnItem;

		let hostOnly = targetId == "host";

		// The host cook always runs: it is the editor's database AND the copy forward
		// source for any target.
		let host = scope CookDriver(project.SourceDb, project.CookedDb, builders, sourcesMount, cacheMount, jobs);
		let hostPlan = scope CookPlan();
		host.Plan(hostPlan, rebuild);
		Console.WriteLine("cook plan (host): {} dirty, {} up to date, {} orphan(s), {} without builders",
			hostPlan.Dirty.Count, hostPlan.UpToDate, hostPlan.Orphans.Count, hostPlan.Unbuildable);
		if (dryRun && hostOnly)
		{
			for (let item in hostPlan.Dirty)
				Console.WriteLine("  dirty: {}", item.Path);
			return 0;
		}
		let hostStats = scope CookStats();
		host.Execute(hostPlan, hostStats, progress);
		Console.WriteLine("host cooked {}, failed {}, swept {} orphan(s)", hostStats.Cooked, hostStats.Failed, hostStats.OrphansSwept);

		int totalFailed = hostStats.Failed;

		if (!hostOnly)
		{
			// The per target database roots at a SIBLING Cooked-<id>/, not Cooked/<id>/: the
			// desktop pack walks Cooked/ recursively, so a nested target subtree would leak
			// into the desktop Content.pak. Its cook records live under .cache/<id>/.
			let cookedDir = scope String(project.Directory);
			cookedDir.Append("/Cooked-");
			cookedDir.Append(targetId);
			let cacheDir = PathJoin(project.CacheRoot(.. scope .()), targetId, .. scope .());
			CreateDirectory(cookedDir);
			CreateDirectory(cacheDir);

			let targetCookedMount = scope NativeFileSystem(cookedDir);
			let targetCacheMount = scope NativeFileSystem(cacheDir);
			SerializerFactory binary = scope (stream, mode) => new BinarySerializerContext(stream, mode);
			let targetDb = scope ContentDatabase(targetCookedMount, binary, project.CookedDb.Extension);

			let targetStats = scope CookStats();
			CookDriver.CookForTarget(project.SourceDb, targetDb, project.CookedDb, host.Db, builders,
				sourcesMount, targetCacheMount, CookTarget.For(targetId), targetStats, jobs, rebuild, progress);
			Console.WriteLine("target '{}' cooked {}, copied forward {}, failed {}", targetId,
				targetStats.Cooked, targetStats.CopiedForward, targetStats.Failed);
			totalFailed += targetStats.Failed;
		}

		return totalFailed;
	}
}
