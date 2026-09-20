using System;
using Sedulous.Core.Serialization;
using Sedulous.Scene;

namespace Sedulous.Editor.Scene.Tests;

/// A system with a settings block, for the scene setting commands.
class WindSystem : SceneSystem
{
	public WindSettings Settings = .();

	public override Type SettingsType => typeof(WindSettings);
	public override void* SettingsInstance => &Settings;
	public override StringView SettingsId => "wind";

	public override void SerializeSettings(ISerializer ar)
	{
		SerializeValue(ar, "speed", ref Settings.Speed);
	}
}
