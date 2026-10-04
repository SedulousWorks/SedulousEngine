using System;
using Sedulous.Core.Serialization;
using Sedulous.Render;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Engine.Render;

/// Holds the scene's post process block and presents it through the settings seam, the same
/// shape the environment uses.
class PostProcessSystem : SceneSystem
{
	private PostProcessSettings mPost = .();

	public PostProcessSettings* Post => &mPost;

	public override Type SettingsType => typeof(PostProcessSettings);
	public override void* SettingsInstance => &mPost;
	public override StringView SettingsId => "postprocess";
	/// Version 2 adds the source and its profile; a version 1 block reads the source Scene.
	public override uint32 SettingsDataVersion => 2;
	public override uint32 SettingsMinReadDataVersion => 1;

	/// The values in effect, as the environment's: the profile's while the source is Profile
	/// and it is loaded, the scene's own otherwise.
	public PostProcessSettings* Effective
	{
		get
		{
			if (mPost.Source == .Profile)
			{
				if (let profile = mPost.Profile.Get)
					return &profile.Values;
			}
			return &mPost;
		}
	}

	public override void ResolveResources(ResourceManager manager)
	{
		mPost.GradingLut.Bind(manager);
		mPost.Profile.Bind(manager);
		// A profile edit's new reference: the loaded profile's values bind as a load's do.
		if (let profile = mPost.Profile.Get)
			profile.Values.GradingLut.Bind(manager);
	}

	public override Type SettingsProfileType => typeof(PostProcessProfile);
	public override void* EffectiveSettingsInstance => Effective;

	public override Guid SettingsProfile
		=> ((mPost.Source == .Profile) && (mPost.Profile.Get != null)) ? mPost.Profile.Id : .();

	/// Bound by the next ResolveResources.
	public override void UseSettingsProfile(Guid profile)
	{
		mPost.Source = (profile == Guid.Empty) ? .Scene : .Profile;
		mPost.Profile.SetId(profile);
		mPost.Profile.ClearBinding();
	}

	public override void CopySettingsProfileIntoScene()
	{
		let values = *Effective; // a copy: Effective may be this block
		let profile = mPost.Profile;
		mPost = values;
		mPost.Source = .Scene;
		mPost.Profile = profile; // kept, so the profile is a pick away
	}

	public override void SerializeSettings(ISerializer ar)
	{
		RenderSettingsValues.SerializePost(ar, ref mPost);
		if ((ar.Mode == .Read) && (ar.Version < 2))
			return;
		RenderSettingsValues.SerializeEnum(ar, "source", ref mPost.Source);
		SerializeValue(ar, "profile", ref mPost.Profile.Id);
	}
}
