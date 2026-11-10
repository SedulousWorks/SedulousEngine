using System;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Scene;

/// The scene's half of the JSON the MCP tools speak (FieldJson, in Editor.App, is the values'):
/// an entity found by what an agent names it with.
static class ComponentJson
{
	/// An entity by guid, slash path or name; invalid when none.
	public static EntityHandle FindEntity(Sedulous.Scene.Scene scene, StringView text)
	{
		Guid id;
		if (Guid.Parse(text) case .Ok(out id))
			return scene.FindEntity(id);
		if (text.Contains('/'))
			return scene.FindEntityByPath(text);
		return scene.FindEntityByName(text);
	}
}
