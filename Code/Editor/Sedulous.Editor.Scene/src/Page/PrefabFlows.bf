using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Engine.Scene;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Scene;

// The scene page's prefab flows, which write assets and ask first where they cannot be undone: a
// prefab made from an entity and what is under it (under "Prefabs/", named after the entity, the
// original replaced by an instance of it, one undo group); an instance's state written back to its
// prefab and every instance in the open scenes rebuilt from it (not undoable, so asked first); an
// instance's overrides discarded (asked first too: entities parented under it that are not the
// prefab's go); an instance spawned through the asset picker. And the prefab half of a save: what
// refuses it (a prefab has one root and never holds itself), and the other open scenes' instances
// rebuilt once it is saved. Out of the page's class as it was; the page's dialogs, its deferral
// and its picker come in as services.

/// What the flows ask of their page. The flows own the hooks; the rest is borrowed.
class PrefabFlowServices
{
	public EditorContext Context = null;
	public SceneEditContext Edit = null;
	/// The open scenes; null: this one alone.
	public SceneSubsystem Scenes = null;
	/// The asset the page edits (it changes on Save As).
	public delegate Guid() PageAsset ~ delete _;
	/// Asks `text` under `title`; `yes` (given, the asker's) runs when the user takes `verb`.
	public delegate void(StringView title, StringView text, StringView verb, delegate void() yes) Confirm ~ delete _;
	/// Runs `work` (given) after the event that asked for it (a dialog's answer).
	public delegate void(delegate void() work) Later ~ delete _;
	/// Opens the asset picker over `types`; `chosen` (given) gets what is picked.
	public delegate void(Span<String> types, delegate void(Guid id) chosen) PickAsset ~ delete _;
}

class PrefabFlows
{
	private PrefabFlowServices mServices ~ delete _;

	/// Takes `services`.
	public this(PrefabFlowServices services)
	{
		mServices = services;
	}

	private EditorContext Context => mServices.Context;
	private SceneEditContext Edit => mServices.Edit;
	private Sedulous.Scene.Scene Scene => mServices.Edit.Scene;
	private EditorProject Project => mServices.Context.Project;

	/// A prefab asset from `entityId` and everything under it, the entity replaced by an instance,
	/// as one undo step.
	public void CreateFromEntity(Guid entityId)
	{
		let project = Project;
		let scene = Scene;
		if (project == null)
			return;
		let live = Edit.Resolve(entityId);
		if (!live.IsAssigned)
			return;
		let payload = scope MemoryStream();
		if (!(PrefabCapture.Capture(scene, live, payload) case .Ok))
		{
			Context.Notify(.Error, "Prefab capture failed.");
			return;
		}
		let root = project.SourceDb.RootGroup;
		var prefabs = root.GetGroup("Prefabs");
		if (prefabs == null)
			prefabs = root.CreateGroup("Prefabs");
		let baseName = scope String(scene.GetEntityName(live));
		if (baseName.IsEmpty)
			baseName.Set("Prefab");
		let name = prefabs.UniqueInstanceName(baseName, .. scope .());
		let asset = prefabs.CreateInstance(name, typeof(PrefabDocument).GetFullName(.. scope .()));
		if (asset == null)
			return;
		let doc = scope PrefabDocument();
		doc.Name.Set(name);
		if (!(asset.WriteObject(doc) case .Ok) || !(asset.WriteData("scene", payload.Bytes, .Text) case .Ok))
		{
			Context.Notify(.Error, "Prefab asset write failed.");
			return;
		}
		let bytes = new List<uint8>();
		bytes.AddRange(payload.Bytes);
		let instanceRoot = Edit.ReplaceWithPrefabInstance(entityId, asset.Id, bytes);
		if (!instanceRoot.IsNil)
			Context.Notify(.Success, scope $"Created prefab '{name}'.");
	}

	/// Asks, then writes the instance at `rootId` back to its prefab.
	public void Apply(Guid rootId)
	{
		let project = Project;
		let scene = Scene;
		let state = scene.FindPrefabInstanceByRoot(rootId);
		if ((project == null) || (state == null) || (mServices.Confirm == null))
			return;
		let asset = project.SourceDb.GetInstance(state.PrefabId);
		if (asset == null)
		{
			Context.Notify(.Warning, "The instance's prefab asset no longer exists.");
			return;
		}
		let text = scope $"Apply '{scene.GetEntityName(scene.FindEntity(rootId))}' to prefab '{asset.Name}'? The prefab asset is rewritten and every instance in open scenes updates to match. This cannot be undone.";
		// Deferred: rebuilding instances destroys and respawns entities (and their rows), never
		// in the middle of the dialog's event.
		mServices.Confirm("Apply to Prefab", text, "Apply", new [=this, =rootId]() => { Later(new [=this, =rootId]() => { ApplyNow(rootId); }); });
	}

	/// The instance's current state becomes the template (source id keyed, so other instances'
	/// overrides stay valid), then every instance everywhere rebuilds from it, this one too.
	public void ApplyNow(Guid rootId)
	{
		let project = Project;
		let scene = Scene;
		let state = scene.FindPrefabInstanceByRoot(rootId);
		if ((project == null) || (state == null))
			return;
		let asset = project.SourceDb.GetInstance(state.PrefabId);
		if (asset == null)
		{
			Context.Notify(.Warning, "The instance's prefab asset no longer exists.");
			return;
		}
		let payload = scope MemoryStream();
		if (!(PrefabApply.CaptureAsTemplate(scene, state, payload, Edit.PrefabResolver) case .Ok)
			|| !(asset.WriteData("scene", payload.Bytes, .Text) case .Ok))
		{
			Context.Notify(.Error, "Apply to Prefab failed.");
			return;
		}
		let bytes = scope List<uint8>();
		bytes.AddRange(payload.Bytes);
		let prefabId = state.PrefabId;
		RebuildInstances(prefabId, bytes, null);
		// An open page on the prefab itself shows the template (plain entities, not an instance):
		// the rebuild cannot reach it, so it is told to refresh.
		Context.NotifyAssetExternallyModified(prefabId);
		Context.Notify(.Success, scope $"Applied to prefab '{asset.Name}' (not undoable - the asset changed).");
	}

	/// Asks, then discards the instance's overrides.
	public void Revert(Guid rootId)
	{
		let scene = Scene;
		if ((Project == null) || (scene.FindPrefabInstanceByRoot(rootId) == null) || (mServices.Confirm == null))
			return;
		let text = scope $"Revert '{scene.GetEntityName(scene.FindEntity(rootId))}' to its prefab? All overrides on this instance are discarded, and any non-prefab entities parented under it are destroyed. This cannot be undone.";
		mServices.Confirm("Revert Instance", text, "Revert", new [=this, =rootId]() => { Later(new [=this, =rootId]() => { RevertNow(rootId); }); });
	}

	/// The instance respawned from the current template, its placement kept. Not undoable.
	public void RevertNow(Guid rootId)
	{
		let project = Project;
		let scene = Scene;
		let state = scene.FindPrefabInstanceByRoot(rootId);
		if ((project == null) || (state == null))
			return;
		let asset = project.SourceDb.GetInstance(state.PrefabId);
		let payload = (asset != null) ? asset.ReadData("scene") : null;
		if (payload == null)
		{
			Context.Notify(.Warning, "The instance's prefab asset no longer exists.");
			return;
		}
		defer delete payload;
		let bytes = scope List<uint8>();
		ReadAll(payload, bytes);
		if (PrefabRebuild.Revert(scene, rootId, bytes, Edit.PrefabResolver))
		{
			if (Context.Resources != null)
			{
				let async = AsyncBindScope(Context.Resources);
				defer async.Dispose();
				SceneResolve.ResolveSceneResources(scene, Context.Resources);
			}
			Context.Notify(.Info, "Instance reverted to its prefab (not undoable).");
		}
	}

	/// An instance of the prefab the picker gives, under `parent` (nil: the scene's root).
	public void PickAndSpawn(Guid parent)
	{
		if ((Project == null) || (mServices.PickAsset == null))
			return;
		let types = scope String[](scope String("PrefabDocument"));
		mServices.PickAsset(types, new [=this, =parent](picked) => { Spawn(picked, parent); });
	}

	/// An instance of prefab `prefabId` under `parent`; false, said, when it cannot be.
	public bool Spawn(Guid prefabId, Guid parent)
	{
		let project = Project;
		if (prefabId.IsNil || (project == null))
			return false;
		if ((mServices.PageAsset != null) && (prefabId == mServices.PageAsset()))
		{
			Context.Notify(.Warning, "A prefab cannot contain an instance of itself.");
			return false;
		}
		let prefab = project.SourceDb.GetInstance(prefabId);
		let payload = (prefab != null) ? prefab.ReadData("scene") : null;
		if (payload == null)
		{
			Context.Notify(.Warning, "Prefab has no content yet (save it once first).");
			return false;
		}
		defer delete payload;
		let bytes = new List<uint8>();
		ReadAll(payload, bytes);
		return !Edit.SpawnPrefabInstance(prefabId, bytes, parent).IsNil;
	}

	/// Why the scene, as the prefab `prefabId`, may not be saved, appended to `outWhy`; false when
	/// it may.
	public static bool SaveRefusal(Sedulous.Scene.Scene scene, Guid prefabId, String outWhy)
	{
		var roots = 0;
		for (var r = scene.FirstRoot; r.IsAssigned; r = scene.GetNextSibling(r))
			roots++;
		if (roots > 1)
		{
			outWhy.Append("A prefab needs exactly one root entity - parent everything under a single root, then save.");
			return true;
		}
		var self = false;
		scene.ForEachPrefabInstance(scope [&](state) =>
		{
			if (state.PrefabId == prefabId)
				self = true;
		});
		if (self)
		{
			outWhy.Append("A prefab cannot contain an instance of itself - remove it, then save.");
			return true;
		}
		return false;
	}

	/// The prefab `asset` was saved: its instances in every other open scene rebuild, their
	/// overrides kept (captured, respawned, applied again).
	public void RebuildOtherInstances(Instance asset)
	{
		let payload = asset.ReadData("scene");
		if (payload == null)
			return;
		defer delete payload;
		let bytes = scope List<uint8>();
		ReadAll(payload, bytes);
		RebuildInstances(asset.Id, bytes, Scene);
	}

	/// The whole of a stream into a list.
	public static void ReadAll(IStream stream, List<uint8> outBytes)
	{
		outBytes.Clear();
		let size = (int)stream.Size();
		if (size <= 0)
			return;
		outBytes.Resize(size);
		stream.Seek(0, .Begin);
		let read = stream.Read(Span<uint8>(outBytes.Ptr, size));
		if (read < size)
			outBytes.Resize(Math.Max(read, 0));
	}

	/// Runs `work` (taken) after the event that asked for it, or now with no page to defer to.
	private void Later(delegate void() work)
	{
		if (mServices.Later != null)
		{
			mServices.Later(work);
			return;
		}
		work();
		delete work;
	}

	/// Every open scene's instances of `prefabId` from `payload`, but `skip`'s.
	private void RebuildInstances(Guid prefabId, List<uint8> payload, Sedulous.Scene.Scene skip)
	{
		let context = Context;
		let resolver = Edit.PrefabResolver;
		delegate void(Sedulous.Scene.Scene) rebuild = scope [&](scene) =>
		{
			if (scene == skip)
				return;
			let rebuilt = PrefabRebuild.Rebuild(scene, prefabId, payload, resolver);
			if ((rebuilt > 0) && (context.Resources != null))
			{
				let async = AsyncBindScope(context.Resources);
				defer async.Dispose();
				SceneResolve.ResolveSceneResources(scene, context.Resources);
			}
		};
		if (mServices.Scenes != null)
			mServices.Scenes.ForEachScene(rebuild);
		else
			rebuild(Scene);
	}
}
