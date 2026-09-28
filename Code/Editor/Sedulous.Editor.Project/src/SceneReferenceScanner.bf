using Sedulous.Content;

namespace Sedulous.Editor.Core;

/// Fills a scene's or prefab's direct references. Registered by whoever links the scene
/// machinery the editor core does not: the scene editor plugin, or the tool's own scan.
typealias SceneReferenceScanner = delegate void(Instance instance, ContentDatabase db, SceneReferences outReferences);
