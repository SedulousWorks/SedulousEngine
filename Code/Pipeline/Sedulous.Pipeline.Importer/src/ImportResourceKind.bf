using System;

namespace Sedulous.Pipeline.Importer;

/// What kind of asset an import plan entry would create, which is how the review dialog groups
/// them.
enum ImportResourceKind : uint8
{
	Texture,
	Material,
	Mesh,
	Skeleton,
	AnimationClip,
	Collision,
	/// A single asset importer's one product, being a texture, an image, audio, a font, and so
	/// on: the whole file is the resource.
	Asset,
}

extension ImportResourceKind
{
	/// The heading the review dialog puts this group under.
	public StringView Label
	{
		get
		{
			switch (this)
			{
			case .Texture: return "Textures";
			case .Material: return "Materials";
			case .Mesh: return "Meshes";
			case .Skeleton: return "Skeleton";
			case .AnimationClip: return "Animation Clips";
			case .Collision: return "Collision";
			case .Asset: return "Asset";
			}
		}
	}
}
