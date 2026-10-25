using Sedulous.Scene;

namespace Sedulous.Script;

/// A Service role object whose entities live in one scene it knows: what the entities it
/// answers belong to, and what the entities it takes must belong to. A service reaches no
/// scene through the script (it is the run's, not a scene's), so without this an entity it
/// returns names none and resolves in the ambient scene, which a run never sets: the script
/// holds a handle that reads invalid. Null when it has no scene now (offline, say): then it
/// answers entities naming none and takes any.
interface IScriptEntityScene
{
	Scene EntityScene { get; }
}
