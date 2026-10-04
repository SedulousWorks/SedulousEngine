using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;
using Sedulous.Render.Pipeline;
using Sedulous.Scene;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// A scene settings block whose values can come from a shared profile asset (the render
/// profiles): making a profile from a block's values, and writing a profile's values back to its
/// asset. Nothing here names a block or a profile type: the block answers its profile's product
/// (SceneSystem.SettingsProfileType), the editor's join of factories and builders answers the
/// asset type that makes it, and the asset takes the values through SettingsProfileAsset.
static class SettingsProfiles
{
	/// The creator that makes `system`'s profile asset, or null: no profile, or no creator.
	public static AssetCreator CreatorFor(EditorContext context, SceneSystem system)
	{
		let product = system.SettingsProfileType;
		if ((product == null) || (context.SourceAssetTypesOf == null))
			return null;
		let assets = scope System.Collections.List<Type>();
		context.SourceAssetTypesOf(product, assets);
		for (let asset in assets)
		{
			let name = asset.GetFullName(.. scope .());
			for (let creator in context.Creators)
			{
				if (creator.TypeName == name)
					return creator;
			}
		}
		return null;
	}

	/// Writes a settings block's `values`, the profile asset's values layout, into the profile
	/// asset `instance`, its other fields kept.
	public static Result<void, ErrorCode> WriteValues(Instance instance, void* values)
	{
		let object = instance.ReadObject();
		defer delete object;
		let asset = object as SettingsProfileAsset;
		if ((asset == null) || (values == null))
			return .Err(.InvalidArgument);
		asset.SetValues(values);
		return instance.WriteObject((ISerializable)object);
	}

	/// An edit made live in `profile`, the values `system` has in effect: the asset's write is
	/// queued for the save flow (EditorContext.RegisterAssetEdit), the values taken now since
	/// the drain may come later.
	public static void QueueEdit(EditorContext context, SceneSystem system, Guid profile)
	{
		let project = context.Project;
		if ((project == null) || (profile == Guid.Empty) || (system.SettingsProfile != profile))
			return;
		let instance = project.SourceDb.GetInstance(profile);
		if (instance == null)
			return;
		let object = instance.ReadObject();
		let asset = object as SettingsProfileAsset;
		if (asset == null)
		{
			delete object;
			return;
		}
		asset.SetValues(system.EffectiveSettingsInstance);
		context.RegisterAssetEdit(profile, new [=object, =profile](db) =>
			{
				let target = db.GetInstance(profile);
				if (target == null)
					return .Err(.NotFound);
				return target.WriteObject((ISerializable)object);
			} ~ delete object);
	}

	/// Make Profile: a new profile asset named `name`, in the creator's default group, holding
	/// the block's values in effect, and the block switched to it as one undo step. The new
	/// instance, or null with a notice.
	public static Instance Make(EditorContext context, SceneEditContext edit, Type settingsType, StringView name)
	{
		let project = context.Project;
		let system = edit.FindSystemBySettingsType(settingsType);
		if ((project == null) || (system == null))
			return null;
		if (context.IsCookBusy)
		{
			context.Notify(.Info, "Make Profile: a cook is running; try again when it finishes.");
			return null;
		}
		let creator = CreatorFor(context, system);
		if (creator == null)
		{
			context.Notify(.Error, "Make Profile: nothing creates this profile.");
			return null;
		}
		let instance = creator.Create(null, project.SourceDb.RootGroup, project.SourcesRoot(.. scope .()), name);
		if ((instance == null) || (WriteValues(instance, system.EffectiveSettingsInstance) case .Err))
		{
			context.Notify(.Error, "Make Profile: the profile could not be written.");
			return instance;
		}
		let id = instance.Id;
		edit.MutateSceneSettings(settingsType, scope [=id](s) => { s.UseSettingsProfile(id); });
		context.RequestCook(); // the profile's product, so the block's reference binds
		return instance;
	}
}
