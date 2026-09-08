using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Scene.Resource;

/// The primary object of a scene instance.
///
/// Deliberately minimal: it carries the NAME so the instance materialises and can be
/// discovered, and the world itself lives in the instance's "scene" data stream. A
/// database browsing a thousand scenes reads a thousand names, not a thousand worlds.
[Serializable]
class SceneDocument
{
	public String Name = new .() ~ delete _;
}
