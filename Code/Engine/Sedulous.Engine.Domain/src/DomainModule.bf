using System;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Engine.Domain;

/// One engine domain's declaration, with every facet it contributes: its scene content (the
/// managers and settings bearing systems a scene gets) and the resource libraries it brings
/// (their types and factory descriptions). Declared once, in the domain's own library, as that
/// library's `<Domain>Domain.Module`; the composition root lists the domains and answers for a
/// facet, and never collects anything itself.
///
/// Beef's reflection is the reflection table, so a domain declares no reflection registrar;
/// and the script facades are the generated closure of the root, so no facade registrar
/// either. A domain with no scene content (input) is a module without a scene facet.
class DomainModule
{
	public readonly String Id;
	private SceneModule mScene;
	private bool mHasScene;
	/// BORROWED: the resource libraries' own static modules.
	private ResourceModule[] mResources ~ delete _;

	/// A domain with scene content. TAKES OWNERSHIP of `resources` (null for none).
	public this(String id, SceneModule.InstallFunction installScene, ResourceModule[] resources = null)
	{
		Id = id;
		mScene = .(id, installScene, null);
		mHasScene = installScene != null;
		mResources = resources;
	}

	public bool HasScene => mHasScene;

	/// The scene facet, for the root's SceneComposition; a pointer into this module, which
	/// lives for the process.
	public SceneModule* Scene => mHasScene ? &mScene : null;

	public Span<ResourceModule> Resources => (mResources != null) ? mResources : .();
}
