using System;

namespace Sedulous.Scene.Tests;

/// A system a plugin would contribute, carrying a settings block, since a contributed
/// system may be a plain system as easily as a manager.
class ContributedSystem : SceneSystem
{
	public ContributedSettings Settings = .();

	public override Type SettingsType => typeof(ContributedSettings);
	public override void* SettingsInstance => &Settings;
	public override StringView SettingsId => "contrib";
}
