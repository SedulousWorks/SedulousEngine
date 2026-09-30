using System;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Pipeline.Core;

namespace Sedulous.Navigation.Pipeline;

/// The navigation domain's New Asset creator: an empty zone, which Bake fills with its navmesh
/// sidecar later.
static class NavigationCreators
{
	public static void Register(AssetCreatorRegistry registry)
	{
		registry.Register(new AssetCreator("Navigation Zone", "", typeof(NavigationZoneAsset), new (context) =>
			{
				let target = context.Target;
				if (target == null)
					return null;
				let instance = target.CreateInstance(target.UniqueInstanceName(context.NameOr("NavZone"), .. scope .()), typeof(NavigationZoneAsset).GetFullName(.. scope .()));
				if (instance == null)
					return null;
				if (NavigationZoneStorage.Write(instance, scope NavigationZoneAsset()) case .Err)
					return null;
				return instance;
			}));
	}
}
