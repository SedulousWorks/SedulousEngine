using System;

namespace Sedulous.Script;

/// The full names of the scene types the core matches by string. The core reads them off
/// reflection rather than naming the types, so it builds without the scene: one place to
/// change when a scene type moves, and a test pins each against the type it names.
static class ScriptSceneNames
{
	public const String cEntityHandle = "Sedulous.Scene.EntityHandle";
	public const String cScene = "Sedulous.Scene.Scene";
	public const String cSceneSystem = "Sedulous.Scene.SceneSystem";
	/// A prefix: the pooled component's name follows it, then `>`.
	public const String cComponentManagerPrefix = "Sedulous.Scene.ComponentManager<";
	/// A prefix, as for ComponentManager.
	public const String cResourceBindingComponentManagerPrefix = "Sedulous.Scene.ResourceBindingComponentManager<";
	public const String cEntitySceneInterface = "Sedulous.Script.IScriptEntityScene";
}
