using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Scene.Resource.Tests;

/// A plain system carrying settings rather than components, which is the other half of
/// what a scene stream has to persist.
class WorldSystem : SceneSystem
{
	public WorldSettings Settings = .();

	public override Type SettingsType => typeof(WorldSettings);
	public override void* SettingsInstance => &Settings;
	public override StringView SettingsId => "test.World";

	public override void SerializeSettings(ISerializer ar)
	{
		SerializeValue(ar, "gravity", ref Settings.Gravity);
		SerializeValue(ar, "wind", ref Settings.Wind);
	}
}
