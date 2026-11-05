using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Runtime;

/// A plugin the host would not enable, and why.
class PluginRefusal
{
	public String Id = new .() ~ delete _;
	public String Reason = new .() ~ delete _;
}

/// What one Load did: the plugins enabled, in load order, and the ones refused, with why.
class PluginLoadReport
{
	public List<String> Loaded = new .() ~ DeleteContainerAndItems!(_);
	public List<PluginRefusal> Refused = new .() ~ DeleteContainerAndItems!(_);

	/// The refusal of `id`, or null. BORROWED.
	public PluginRefusal FindRefusal(StringView id)
	{
		for (let refusal in Refused)
		{
			if (refusal.Id == id)
				return refusal;
		}
		return null;
	}
}

/// The enabled plugins of one process. It knows the plugins compiled into the binary and, given
/// the ids a project enables:
///
///   1. resolves each id;
///   2. checks each manifest, the dependencies (enabled, loadable, recent enough) and the
///      `provides` slots (one provider each), refusing with a message, never faulting;
///   3. loads the parts the host's role takes, in dependency order, through the PluginLoader's
///      recording, and unloads in reverse.
///
/// A plugin that is compiled in but not enabled is never touched: dormant costs nothing.
class PluginHost
{
	/// A plugin the host could enable: its manifest (ours) and the parts compiled in (borrowed).
	private class Candidate
	{
		public PluginManifest Manifest ~ delete _;
		public List<PluginPart> Parts = new .() ~ delete _;

		public StringView Id => Manifest.Id;

		/// The compiled-in part of `kind`, or null.
		public PluginPart Part(PluginPartKind kind)
		{
			for (let part in Parts)
			{
				if (part.Kind == kind)
					return part;
			}
			return null;
		}
	}

	private SubsystemManager mSubsystems;
	private HostRole mRole;
	private String mEngineVersion = new .() ~ delete _;
	private List<Candidate> mCandidates = new .() ~ DeleteContainerAndItems!(_);
	/// One per enabled plugin, alive until its parts unload. Declared before the loader, so the
	/// loader (which unloads through them) goes first.
	private List<PluginContext> mContexts = new .() ~ DeleteContainerAndItems!(_);
	private PluginLoader mLoader ~ delete _;
	private List<String> mLoaded = new .() ~ DeleteContainerAndItems!(_);

	/// `subsystems` is BORROWED and outlives the host. `engineVersion` is the version every
	/// manifest is checked against (the engine's numbers, as compatibility compares them).
	public this(SubsystemManager subsystems, HostRole role, StringView engineVersion)
	{
		mSubsystems = subsystems;
		mRole = role;
		mEngineVersion.Set(engineVersion);
		mLoader = new PluginLoader(subsystems);
	}

	public ~this()
	{
		Unload();
	}

	public HostRole Role => mRole;

	/// The loader the parts load through, for adding recorders before Load.
	public PluginLoader Loader => mLoader;

	/// A plugin compiled into this binary: its manifest's text and its parts linked here
	/// (BORROWED; they outlive the host). A manifest that does not read is a build defect:
	/// Internal, and nothing is added. A second plugin of an id already known is ignored.
	public Result<void, ErrorCode> AddLinked(StringView manifestXml, Span<PluginPart> parts)
	{
		let manifest = new PluginManifest();
		if (PluginManifest.Read(manifestXml, manifest) case .Err)
		{
			delete manifest;
			return .Err(.Internal);
		}
		if (Find(manifest.Id) != null)
		{
			delete manifest;
			return .Ok;
		}
		let candidate = new Candidate();
		candidate.Manifest = manifest;
		for (let part in parts)
		{
			if (part != null)
				candidate.Parts.Add(part);
		}
		mCandidates.Add(candidate);
		return .Ok;
	}

	/// Whether a plugin of this id is compiled in.
	public bool Knows(StringView id) => Find(id) != null;

	public bool IsLoaded(StringView id) => Contains(mLoaded, id);

	/// Enables the plugins `enabled` names (ids, in the project's order), the report appended to
	/// `outReport`. Call once; Unload first to enable another set.
	public void Load(Span<StringView> enabled, PluginLoadReport outReport)
	{
		let accepted = scope List<Candidate>();

		// 1. Resolve and check each manifest; then the slots, first come first served.
		for (let id in enabled)
		{
			if ((FindIn(accepted, id) != null) || (outReport.FindRefusal(id) != null))
				continue; // listed twice
			let candidate = Find(id);
			if (candidate == null)
			{
				Refuse(outReport, id, scope $"plugin '{id}' is not in this build");
				continue;
			}
			let whyNot = scope String();
			if (!candidate.Manifest.Check(mEngineVersion, whyNot))
			{
				Refuse(outReport, id, whyNot);
				continue;
			}
			let missing = MissingPart(candidate, .. scope .());
			if (!missing.IsEmpty)
			{
				Refuse(outReport, id, missing);
				continue;
			}
			String taken = null;
			StringView slot = default;
			for (let provided in candidate.Manifest.Provides)
			{
				for (let other in accepted)
				{
					for (let otherSlot in other.Manifest.Provides)
					{
						if (otherSlot == provided)
						{
							taken = other.Manifest.Id;
							slot = provided;
						}
					}
				}
			}
			if (taken != null)
			{
				Refuse(outReport, id, scope $"plugin '{id}' provides '{slot}', which '{taken}' already provides");
				continue;
			}
			accepted.Add(candidate);
		}

		// 2. Dependencies, to a fixed point: refusing one plugin may strand its dependents.
		for (bool changed = true; changed;)
		{
			changed = false;
			for (int i < accepted.Count)
			{
				let why = UnmetDependency(accepted[i].Manifest, accepted, outReport, .. scope .());
				if (!why.IsEmpty)
				{
					Refuse(outReport, accepted[i].Id, why);
					accepted.RemoveAt(i);
					changed = true;
					break;
				}
			}
		}

		// 3. Dependency order (depth first, dependencies before dependents); a cycle is refused.
		let order = scope List<Candidate>();
		let visiting = scope List<Candidate>();
		let cyclic = scope List<String>();
		defer { ClearAndDeleteItems!(cyclic); }
		for (let candidate in accepted)
			Visit(candidate, accepted, order, visiting, cyclic);

		// 4. Each plugin's parts for this role, a plugin whose dependency did not load skipped.
		for (let candidate in order)
		{
			let manifest = candidate.Manifest;
			if (Contains(cyclic, manifest.Id))
			{
				Refuse(outReport, manifest.Id, scope $"plugin '{manifest.Id}' is in a dependency cycle");
				continue;
			}
			PluginDependency failed = null;
			for (let dependency in manifest.DependsOn)
			{
				if (!IsLoaded(dependency.Id))
				{
					failed = dependency;
					break;
				}
			}
			if (failed != null)
			{
				Refuse(outReport, manifest.Id, scope $"plugin '{manifest.Id}' needs '{failed.Id}', which did not load");
				continue;
			}
			let why = LoadParts(candidate, .. scope .());
			if (!why.IsEmpty)
			{
				Refuse(outReport, manifest.Id, why);
				continue;
			}
			mLoaded.Add(new .(manifest.Id));
			outReport.Loaded.Add(new .(manifest.Id));
		}
	}

	/// Unloads every enabled part in reverse load order, reversing what each registered.
	public void Unload()
	{
		mLoader.UnloadAll();
		ClearAndDeleteItems!(mContexts);
		ClearAndDeleteItems!(mLoaded);
	}

	private static void Refuse(PluginLoadReport report, StringView id, StringView reason)
	{
		if (report.FindRefusal(id) != null)
			return;
		let refusal = new PluginRefusal();
		refusal.Id.Set(id);
		refusal.Reason.Set(reason);
		report.Refused.Add(refusal);
	}

	private Candidate Find(StringView id) => FindIn(mCandidates, id);

	private static Candidate FindIn(List<Candidate> candidates, StringView id)
	{
		for (let candidate in candidates)
		{
			if (candidate.Id == id)
				return candidate;
		}
		return null;
	}

	private static bool Contains(List<String> ids, StringView id)
	{
		for (let entry in ids)
		{
			if (entry == id)
				return true;
		}
		return false;
	}

	/// Appends why a part the manifest lists for this role is not compiled in; nothing when
	/// every one is.
	private void MissingPart(Candidate candidate, String outWhy)
	{
		for (int i < PluginPartKind.Count)
		{
			let kind = (PluginPartKind)i;
			if (!mRole.Loads(kind) || !candidate.Manifest.HasPart(kind))
				continue;
			if (candidate.Part(kind) == null)
			{
				outWhy.AppendF("plugin '{}': its {} part is not in this build", candidate.Id, kind);
				return;
			}
		}
	}

	/// Appends why a dependency of `manifest` is not met among `accepted`; nothing when all are.
	private static void UnmetDependency(PluginManifest manifest, List<Candidate> accepted, PluginLoadReport report, String outWhy)
	{
		for (let dependency in manifest.DependsOn)
		{
			let found = FindIn(accepted, dependency.Id);
			if (found == null)
			{
				if (report.FindRefusal(dependency.Id) != null)
					outWhy.AppendF("plugin '{}' needs '{}', which was refused", manifest.Id, dependency.Id);
				else
					outWhy.AppendF("plugin '{}' needs '{}', which is not enabled", manifest.Id, dependency.Id);
				return;
			}
			let have = PluginVersion.Parse(found.Manifest.Version);
			let want = PluginVersion.Parse(dependency.Version);
			if ((have case .Err) || (want case .Err) || !PluginVersion.AtLeast(have.Value, want.Value))
			{
				outWhy.AppendF("plugin '{}' needs '{}' {} or later; it is {}", manifest.Id, dependency.Id, dependency.Version, found.Manifest.Version);
				return;
			}
		}
	}

	private static void Visit(Candidate candidate, List<Candidate> accepted, List<Candidate> order, List<Candidate> visiting, List<String> cyclic)
	{
		if (order.Contains(candidate))
			return;
		if (visiting.Contains(candidate))
		{
			// Back on a plugin still being visited: everything from it to here is a cycle.
			bool inCycle = false;
			for (let member in visiting)
			{
				inCycle = inCycle || (member == candidate);
				if (inCycle && !Contains(cyclic, member.Id))
					cyclic.Add(new .(member.Id));
			}
			return;
		}
		visiting.Add(candidate);
		for (let dependency in candidate.Manifest.DependsOn)
		{
			let next = FindIn(accepted, dependency.Id);
			if (next != null)
				Visit(next, accepted, order, visiting, cyclic);
		}
		visiting.PopBack();
		order.Add(candidate);
	}

	/// Loads the candidate's parts for this role in kind order; appends why not, and loads
	/// nothing, when one is not this plugin's.
	private void LoadParts(Candidate candidate, String outWhy)
	{
		let manifest = candidate.Manifest;
		// Every part is checked before any loads, so a plugin refused here leaves nothing behind.
		for (int i < PluginPartKind.Count)
		{
			let kind = (PluginPartKind)i;
			if (!mRole.Loads(kind) || !manifest.HasPart(kind))
				continue;
			let part = candidate.Part(kind);
			if ((part == null) || (part.PluginId != manifest.Id))
			{
				outWhy.AppendF("plugin '{}': its {} part is not this plugin's", manifest.Id, kind);
				return;
			}
		}
		let context = new PluginContext(mRole, mSubsystems, manifest.Id);
		mContexts.Add(context);
		for (int i < PluginPartKind.Count)
		{
			let kind = (PluginPartKind)i;
			if (mRole.Loads(kind) && manifest.HasPart(kind))
				mLoader.AddPart(candidate.Part(kind), context);
		}
	}
}
