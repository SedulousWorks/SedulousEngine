using Sedulous.Core;

namespace Sedulous.Geometry;

/// The token a StaticMesh owns for as long as it exists: holding it weakly is how a cache of
/// what was made from a mesh (its GPU upload) learns that the mesh is gone.
sealed class StaticMeshLife : SharedObject
{
}
