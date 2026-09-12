using System;
using Sedulous.Scene;
using Sedulous.Net.Replication;

namespace Sedulous.Engine.Net;

/// The engine level net module install.
///
/// Foundation's component managers PLUS the fixed lane driver, so replication ships with the
/// managers as ONE composition module rather than two that could be added separately.
static class NetworkScene
{
	public static void AddNetworkSceneManagers(Scene scene)
	{
		ReplicationScene.AddNetworkSceneManagers(scene);
		scene.AddSystem<NetworkSceneSystem>();
	}
}
