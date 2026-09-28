using System;
using Sedulous.Scene.Resource;

namespace Sedulous.Editor.Core;

/// The content database type names of the two scene documents, as an instance carries them.
static class McpDocumentNames
{
	public static readonly String cSceneDocument = typeof(SceneDocument).GetFullName(.. new String()) ~ delete _;
	public static readonly String cPrefabDocument = typeof(PrefabDocument).GetFullName(.. new String()) ~ delete _;
}
