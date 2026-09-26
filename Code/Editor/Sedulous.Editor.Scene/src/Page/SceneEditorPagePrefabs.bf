using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Resource;
using Sedulous.UI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Scene;

/// The page's prefab verbs: an entity into a new prefab asset, an instance applied back to
/// its asset, an instance reverted, and a picked prefab spawned.
extension SceneEditorPage
{
	/// Captures the entity's subtree as a new prefab under Prefabs/ and replaces it with an
	/// instance, as one undo step.
	public void CreatePrefabFromEntity(Guid entityId)
	{
		if ((mScene == null) || (mContext.Project == null))
			return;
		let live = mEditContext.Resolve(entityId);
		if (!live.IsAssigned)
			return;

		let payload = scope MemoryStream();
		if (!(PrefabCapture.Capture(mScene, live, payload) case .Ok))
		{
			mContext.Notify(.Error, "Prefab capture failed.");
			return;
		}

		let root = mContext.Project.SourceDb.RootGroup;
		var prefabs = root.GetGroup("Prefabs");
		if (prefabs == null)
			prefabs = root.CreateGroup("Prefabs");
		let baseName = scope String(mScene.GetEntityName(live));
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
			mContext.Notify(.Error, "Prefab asset write failed.");
			return;
		}

		let bytes = new List<uint8>();
		bytes.AddRange(payload.Bytes);
		let instanceRoot = mEditContext.ReplaceWithPrefabInstance(entityId, asset.Id, bytes);
		if (!instanceRoot.IsNil)
			mContext.Notify(.Success, scope $"Created prefab '{name}'.");
	}

	/// Confirms, then writes the instance back over its prefab asset.
	public void ApplyInstanceToPrefab(Guid rootId)
	{
		if ((mScene == null) || (mContext.Project == null) || (mContent.Context == null))
			return;
		let state = mScene.FindPrefabInstanceByRoot(rootId);
		if (state == null)
			return;
		let asset = mContext.Project.SourceDb.GetInstance(state.PrefabId);
		if (asset == null)
		{
			mContext.Notify(.Warning, "The instance's prefab asset no longer exists.");
			return;
		}
		let root = mScene.FindEntity(rootId);
		let message = scope $"Apply '{mScene.GetEntityName(root)}' to prefab '{asset.Name}'? The prefab asset is rewritten and every instance in open scenes updates to match. This cannot be undone.";
		let dialog = Dialog.Confirm("Apply to Prefab", message);
		dialog.OnClosed.Add(new [=this, =rootId](d, result) =>
		{
			if (result != .OK)
				return;
			let ctx = mContent.Context;
			if (ctx == null)
				return;
			ctx.MutationQueue.QueueAction(new [=this, =rootId]() => { ApplyInstanceToPrefabNow(rootId); });
		});
		dialog.Show(mContent.Context);
	}

	/// Rewrites the prefab asset from the instance, rebuilds every instance of it in every
	/// open scene, and tells any page editing the prefab.
	public void ApplyInstanceToPrefabNow(Guid rootId)
	{
		if ((mScene == null) || (mContext.Project == null))
			return;
		let state = mScene.FindPrefabInstanceByRoot(rootId);
		if (state == null)
			return;
		let asset = mContext.Project.SourceDb.GetInstance(state.PrefabId);
		if (asset == null)
		{
			mContext.Notify(.Warning, "The instance's prefab asset no longer exists.");
			return;
		}
		let payload = scope MemoryStream();
		if (!(PrefabApply.CaptureAsTemplate(mScene, state, payload, mEditContext.PrefabResolver) case .Ok)
			|| !(asset.WriteData("scene", payload.Bytes, .Text) case .Ok))
		{
			mContext.Notify(.Error, "Apply to Prefab failed.");
			return;
		}
		let bytes = scope List<uint8>();
		bytes.AddRange(payload.Bytes);
		let prefabId = state.PrefabId;
		if (mScenes != null)
		{
			mScenes.ForEachScene(scope [&](scene) =>
			{
				let rebuilt = PrefabRebuild.Rebuild(scene, prefabId, bytes, mEditContext.PrefabResolver);
				if ((rebuilt > 0) && (mContext.Resources != null))
				{
					let async = AsyncBindScope(mContext.Resources);
					defer async.Dispose();
					SceneResolve.ResolveSceneResources(scene, mContext.Resources);
				}
			});
		}
		mContext.NotifyAssetExternallyModified(prefabId);
		mContext.Notify(.Success, scope $"Applied to prefab '{asset.Name}' (not undoable - the asset changed).");
	}

	/// Confirms, then discards the instance's overrides.
	public void RevertInstance(Guid rootId)
	{
		if ((mScene == null) || (mContext.Project == null) || (mContent.Context == null))
			return;
		if (mScene.FindPrefabInstanceByRoot(rootId) == null)
			return;
		let root = mScene.FindEntity(rootId);
		let message = scope $"Revert '{mScene.GetEntityName(root)}' to its prefab? All overrides on this instance are discarded, and any non-prefab entities parented under it are destroyed. This cannot be undone.";
		let dialog = Dialog.Confirm("Revert Instance", message);
		dialog.OnClosed.Add(new [=this, =rootId](d, result) =>
		{
			if (result != .OK)
				return;
			let ctx = mContent.Context;
			if (ctx == null)
				return;
			ctx.MutationQueue.QueueAction(new [=this, =rootId]() => { RevertInstanceNow(rootId); });
		});
		dialog.Show(mContent.Context);
	}

	public void RevertInstanceNow(Guid rootId)
	{
		if ((mScene == null) || (mContext.Project == null))
			return;
		let state = mScene.FindPrefabInstanceByRoot(rootId);
		if (state == null)
			return;
		let asset = mContext.Project.SourceDb.GetInstance(state.PrefabId);
		let payload = (asset != null) ? asset.ReadData("scene") : null;
		if (payload == null)
		{
			mContext.Notify(.Warning, "The instance's prefab asset no longer exists.");
			return;
		}
		defer delete payload;
		let bytes = scope List<uint8>();
		ReadAll(payload, bytes);
		if (PrefabRebuild.Revert(mScene, rootId, bytes, mEditContext.PrefabResolver))
		{
			if (mContext.Resources != null)
			{
				let async = AsyncBindScope(mContext.Resources);
				defer async.Dispose();
				SceneResolve.ResolveSceneResources(mScene, mContext.Resources);
			}
			mContext.Notify(.Info, "Instance reverted to its prefab (not undoable).");
		}
	}

	/// Picks a prefab asset and spawns an instance under `parent`.
	public void PickAndSpawnPrefab(Guid parent)
	{
		if ((mContext.Project == null) || (mContent.Context == null))
			return;
		let dialog = new AssetPickerDialog(mContext, scope StringView[]("PrefabDocument"));
		dialog.OnPicked = new [=this, =parent](picked) =>
		{
			if (picked.IsNil || (mContext.Project == null))
				return;
			let prefab = mContext.Project.SourceDb.GetInstance(picked);
			let payload = (prefab != null) ? prefab.ReadData("scene") : null;
			if (payload == null)
			{
				mContext.Notify(.Warning, "Prefab has no content yet (save it once first).");
				return;
			}
			defer delete payload;
			if (picked == InstanceId)
			{
				mContext.Notify(.Warning, "A prefab cannot contain an instance of itself.");
				return;
			}
			let bytes = new List<uint8>();
			ReadAll(payload, bytes);
			mEditContext.SpawnPrefabInstance(picked, bytes, parent);
		};
		dialog.Show(mContent.Context);
	}
}
