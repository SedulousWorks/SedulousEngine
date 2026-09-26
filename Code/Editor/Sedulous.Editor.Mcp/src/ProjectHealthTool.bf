using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.VFS;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Cook;
using Sedulous.Audio.Pipeline;

namespace Sedulous.Editor.Mcp;

/// project_health: one call = "is this project sound". Sweeps the whole source database with
/// the SAME live machinery the other tools trust: dangling references (every forward edge
/// whose target no longer exists in the source database), broken sources (a buildable
/// asset whose envelope no longer deserializes, a scene whose stream no longer loads), and
/// the cook state (the plan's dirty split, orphaned products, sources with no builder, and
/// records whose last cook FAILED). `sound` is true only when nothing is broken: dirty is
/// normal workflow state and never unsounds a project.
static class ProjectHealthTool
{
	private class Context
	{
		public ProjectSession Session;
		public BuilderRegistry Builders;
	}

	/// One broken forward edge: `From` points at `To`, which is not in the source database.
	private class Dangling
	{
		public Instance From;
		public Guid To;
		public String Edge = new .() ~ delete _;
	}

	private class Sweep
	{
		public List<Dangling> DanglingRefs = new .() ~ DeleteContainerAndItems!(_);
		/// Buildable, but ReadObject fails.
		public List<Instance> Undeserializable = new .() ~ delete _;
		/// Scene or prefab whose stream does not load.
		public List<Instance> UnreadableScenes = new .() ~ delete _;
		/// A sound cue with no clip in any slot: a WARNING, it cooks to a valid silent product.
		public List<Instance> EmptyCues = new .() ~ delete _;
		/// No registered builder; scenes and prefabs excluded, they stage rather than cook.
		public int Unbuildable = 0;
	}

	public static void Register(McpServer server, ProjectSession session, BuilderRegistry builders)
	{
		let context = new Context();
		context.Session = session;
		context.Builders = builders;
		server.RegisterTool("project_health",
			"""
			Full project soundness sweep: dangling references (any asset/scene/settings edge whose target is missing from the source database), sources that no longer deserialize, scenes/prefabs that no longer load, plus the cook state (dirty vs up-to-date, orphaned products, sources with no builder, last-cook failures). Also warns (without flipping sound) on emptyCues: sound cues with no clip assigned. Returns sound=true only when nothing is broken; a dirty count alone is normal - run asset_cook to clear it. Call after destructive changes (delete/rename) or before an export to catch breakage early; fix dangling refs by re-pointing or restoring the missing asset (asset_uses on the missing guid's users shows impact).
			""",
			scope SchemaBuilder().Build(), .ReadOnly,
			new (arguments, outResult, outError) => Health(context, outResult, outError),
			context);
	}

	private static bool Health(Context context, JsonValue outResult, String outError)
	{
		let session = context.Session;
		if (!session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return false;
		}
		let project = session.Project;
		let db = project.SourceDb;
		let sourcesMount = scope NativeFileSystem(project.SourcesRoot(.. scope .()));

		let sweep = scope Sweep();
		SweepGroup(db.RootGroup, db, context.Builders, sourcesMount, sweep);

		// Settings edges: manifest fields pointing at instances that no longer exist.
		let settingsDangling = JsonValue.MakeArray();
		let refs = scope List<(StringView name, Guid id)>();
		AssetUsesTool.SettingsReferences(project.Settings, refs);
		for (let reference in refs)
			if (reference.id.IsSet && (db.GetInstance(reference.id) == null))
				settingsDangling.Add(JsonValue.MakeString(reference.name));

		// Cook state: the plan only, no build, plus the persisted records' failure flags.
		let cacheMount = scope NativeFileSystem(project.CacheRoot(.. scope .()));
		let driver = scope CookDriver(db, project.CookedDb, context.Builders, sourcesMount, cacheMount);
		let plan = scope CookPlan();
		driver.Plan(plan, false);
		int failedCooks = 0;
		driver.Db.ForEach(scope [&](record) => { if (record.Failed) failedCooks++; });

		let dangling = JsonValue.MakeArray();
		for (let d in sweep.DanglingRefs)
		{
			let entry = JsonValue.MakeObject();
			entry.Set("from", McpTools.InstanceToJson(d.From));
			entry.Set("to", McpTools.GuidToJson(d.To));
			entry.Set("edge", JsonValue.MakeString(d.Edge));
			dangling.Add(entry);
		}
		let sound = sweep.DanglingRefs.IsEmpty && sweep.Undeserializable.IsEmpty
			&& sweep.UnreadableScenes.IsEmpty && (settingsDangling.Count == 0)
			&& plan.Orphans.IsEmpty && (failedCooks == 0);

		outResult.Set("sound", JsonValue.MakeBool(sound));
		outResult.Set("danglingRefs", dangling);
		outResult.Set("projectSettingsDangling", settingsDangling);
		outResult.Set("undeserializable", Instances(sweep.Undeserializable));
		outResult.Set("unreadableScenes", Instances(sweep.UnreadableScenes));
		outResult.Set("emptyCues", Instances(sweep.EmptyCues));
		outResult.Set("dirty", JsonValue.MakeNumber((double)plan.Dirty.Count));
		outResult.Set("upToDate", JsonValue.MakeNumber((double)plan.UpToDate));
		outResult.Set("orphans", JsonValue.MakeNumber((double)plan.Orphans.Count));
		outResult.Set("unbuildable", JsonValue.MakeNumber((double)sweep.Unbuildable));
		outResult.Set("failedCooks", JsonValue.MakeNumber((double)failedCooks));
		return true;
	}

	private static JsonValue Instances(List<Instance> instances)
	{
		let array = JsonValue.MakeArray();
		for (let instance in instances)
			array.Add(McpTools.InstanceToJson(instance));
		return array;
	}

	private static void AppendDangling(Instance from, List<Guid> targets, StringView edge,
		ContentDatabase db, Sweep sweep)
	{
		for (let id in targets)
		{
			if (id.IsSet && (db.GetInstance(id) == null))
			{
				let dangling = new Dangling();
				dangling.From = from;
				dangling.To = id;
				dangling.Edge.Set(edge);
				sweep.DanglingRefs.Add(dangling);
			}
		}
	}

	/// Depth first over every source instance's forward edges and deserializability.
	private static void SweepGroup(Group group, ContentDatabase db, BuilderRegistry builders,
		IFileSystem sourcesMount, Sweep sweep)
	{
		for (let instance in group.Instances)
		{
			if (McpTools.IsSceneDocument(instance) || McpTools.IsPrefabDocument(instance))
			{
				let resources = scope List<Guid>();
				let prefabs = scope List<Guid>();
				if (!SceneReferences.Collect(instance, db, resources, prefabs))
				{
					sweep.UnreadableScenes.Add(instance);
					continue;
				}
				AppendDangling(instance, resources, "scene-resource", db, sweep);
				AppendDangling(instance, prefabs, "prefab-instance", db, sweep);
				continue;
			}
			let builder = builders.FindByTypeName(instance.TypeName);
			if (builder == null)
			{
				sweep.Unbuildable++;
				continue;
			}
			let object = instance.ReadObject();
			defer { if (object != null) delete object; }
			let asset = McpTools.AsAsset(object);
			if (asset == null)
			{
				sweep.Undeserializable.Add(instance);
				continue;
			}
			// The empty cue audit, a warning: a forgot to assign mistake almost every time.
			if (let cue = asset as SoundCueAsset)
			{
				bool anyClip = false;
				for (let slot in cue.Slots)
					if (slot.ClipId.IsSet)
						anyClip = true;
				if (!anyClip)
					sweep.EmptyCues.Add(instance);
			}
			let scanContext = scope AssetBuildContext();
			scanContext.Sources = sourcesMount;
			scanContext.Database = db;
			let deps = scope AssetDependencies();
			builder.ScanDependencies(asset, scanContext, deps);
			AppendDangling(instance, deps.Reads, "reads", db, sweep);
			AppendDangling(instance, deps.References, "references", db, sweep);
		}
		for (let child in group.Groups)
			SweepGroup(child, db, builders, sourcesMount, sweep);
	}
}
