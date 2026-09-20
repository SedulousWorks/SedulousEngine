using System;
using Sedulous.Editor.Core;
using System.Collections;
using Sedulous.UI;

namespace Sedulous.Editor.App;

/// The hand-authored editor icon set: inline SVG strings materialised once into shared
/// BakedSVGDrawable instances, which the VG/SVG stack renders crisp at any size. Inline
/// strings are deliberate: editor chrome versioned with the code, no VFS or pipeline
/// coupling, works on a fresh checkout; external icon files can come with full themes
/// later, the drawables do not care where the string came from.
///
/// Lifetime: the application calls Initialize at startup and Shutdown at teardown. The
/// drawables are null before Initialize.
static class EditorIcons
{
	// ---- viewport toolbar ----
	public static BakedSVGDrawable Translate = null;
	public static BakedSVGDrawable Rotate = null;
	public static BakedSVGDrawable Scale = null;
	public static BakedSVGDrawable WorldSpace = null;
	public static BakedSVGDrawable LocalSpace = null;
	public static BakedSVGDrawable Grid = null;

	// ---- asset types (browser rows and tiles, the picker) ----
	public static BakedSVGDrawable Scene = null;
	public static BakedSVGDrawable Prefab = null;
	public static BakedSVGDrawable Mesh = null;
	public static BakedSVGDrawable SkinnedMesh = null;
	public static BakedSVGDrawable Material = null;
	public static BakedSVGDrawable Texture = null;
	public static BakedSVGDrawable ParticleFx = null;
	public static BakedSVGDrawable Animation = null;
	public static BakedSVGDrawable AnimGraph = null;
	public static BakedSVGDrawable Skeleton = null;
	public static BakedSVGDrawable Folder = null;
	public static BakedSVGDrawable Unknown = null;

	// ---- chrome ----
	/// The tab and panel close X; the theme tints it.
	public static BakedSVGDrawable Close = null;

	// ---- list and row controls (the container list editor) ----
	public static BakedSVGDrawable Add = null;
	public static BakedSVGDrawable Remove = null;
	public static BakedSVGDrawable MoveUp = null;
	public static BakedSVGDrawable MoveDown = null;
	public static BakedSVGDrawable Copy = null;
	public static BakedSVGDrawable Edit = null;

	// ---- terrain brush modes (the sculpt tool panel) ----
	public static BakedSVGDrawable BrushRaise = null;
	public static BakedSVGDrawable BrushLower = null;
	public static BakedSVGDrawable BrushSmooth = null;
	public static BakedSVGDrawable BrushFlatten = null;

	private static bool sInitialized = false;

	public static void Initialize()
	{
		if (sInitialized)
			return;
		sInitialized = true;
		Translate = BakedSVGDrawable.FromString(cTranslate);
		Rotate = BakedSVGDrawable.FromString(cRotate);
		Scale = BakedSVGDrawable.FromString(cScale);
		WorldSpace = BakedSVGDrawable.FromString(cWorldSpace);
		LocalSpace = BakedSVGDrawable.FromString(cLocalSpace);
		Grid = BakedSVGDrawable.FromString(cGrid);
		Scene = BakedSVGDrawable.FromString(cScene);
		Prefab = BakedSVGDrawable.FromString(cPrefab);
		Mesh = BakedSVGDrawable.FromString(cMesh);
		SkinnedMesh = BakedSVGDrawable.FromString(cSkinnedMesh);
		Material = BakedSVGDrawable.FromString(cMaterial);
		Texture = BakedSVGDrawable.FromString(cTexture);
		ParticleFx = BakedSVGDrawable.FromString(cParticleFx);
		Animation = BakedSVGDrawable.FromString(cAnimation);
		AnimGraph = BakedSVGDrawable.FromString(cAnimGraph);
		Skeleton = BakedSVGDrawable.FromString(cSkeleton);
		Folder = BakedSVGDrawable.FromString(cFolder);
		Unknown = BakedSVGDrawable.FromString(cUnknown);
		Close = BakedSVGDrawable.FromString(cClose);
		Add = BakedSVGDrawable.FromString(cAdd);
		Remove = BakedSVGDrawable.FromString(cRemove);
		MoveUp = BakedSVGDrawable.FromString(cMoveUp);
		MoveDown = BakedSVGDrawable.FromString(cMoveDown);
		Copy = BakedSVGDrawable.FromString(cCopy);
		Edit = BakedSVGDrawable.FromString(cEdit);
		BrushRaise = BakedSVGDrawable.FromString(cBrushRaise);
		BrushLower = BakedSVGDrawable.FromString(cBrushLower);
		BrushSmooth = BakedSVGDrawable.FromString(cBrushSmooth);
		BrushFlatten = BakedSVGDrawable.FromString(cBrushFlatten);
	}

	public static void Shutdown()
	{
		let all = scope List<BakedSVGDrawable>();
		Bakeable(all);
		for (let icon in all)
			icon.ReleaseRef();
		Translate = null;
		Rotate = null;
		Scale = null;
		WorldSpace = null;
		LocalSpace = null;
		Grid = null;
		Scene = null;
		Prefab = null;
		Mesh = null;
		SkinnedMesh = null;
		Material = null;
		Texture = null;
		ParticleFx = null;
		Animation = null;
		AnimGraph = null;
		Skeleton = null;
		Folder = null;
		Unknown = null;
		Close = null;
		Add = null;
		Remove = null;
		MoveUp = null;
		MoveDown = null;
		Copy = null;
		Edit = null;
		BrushRaise = null;
		BrushLower = null;
		BrushSmooth = null;
		BrushFlatten = null;
		sInitialized = false;
	}

	/// Every icon, for the bake pass (UIHost.BakeSvgDrawables at startup and DPI change).
	public static void Bakeable(List<BakedSVGDrawable> outIcons)
	{
		BakedSVGDrawable[?] all = .(
			Translate, Rotate, Scale, WorldSpace, LocalSpace, Grid, Scene, Prefab, Mesh, SkinnedMesh, Material, Texture, ParticleFx, Animation, AnimGraph, Skeleton, Folder, Unknown, Close, Add, Remove, MoveUp, MoveDown, Copy, Edit, BrushRaise, BrushLower, BrushSmooth, BrushFlatten);
		for (let icon in all)
		{
			if (icon != null)
				outIcons.Add(icon);
		}
	}

	/// The icon for a content-database instance type name ("StaticMeshAsset"). Never null
	/// after Initialize: unmatched types get the generic document glyph.
	public static SVGDrawable ForAssetType(StringView typeName)
	{
		switch (AssetTypeNames.Short(typeName))
		{
		case "SceneDocument": return Scene;
		case "ModelManifestAsset": return Prefab;
		case "StaticMeshAsset": return Mesh;
		case "SkinnedMeshAsset": return SkinnedMesh;
		case "MaterialAsset": return Material;
		case "TextureAsset", "ImageAsset": return Texture;
		case "ParticleEffectAsset": return ParticleFx;
		case "AnimationClipAsset": return Animation;
		case "AnimationGraphAsset": return AnimGraph;
		case "SkeletonAsset": return Skeleton;
		default: return Unknown;
		}
	}

	// ---- glyphs: 24x24 viewBox, a single light-grey fill, tintable ----

	/// Translate gizmo: four arrows pointing outward from centre.
	private const String cTranslate = """
		<svg viewBox="0 0 24 24">
		  <path d="M12 2l3 3h-2v4h-2V5H9l3-3z" fill="#E0E0E0"/>
		  <path d="M12 22l-3-3h2v-4h2v4h2l-3 3z" fill="#E0E0E0"/>
		  <path d="M2 12l3-3v2h4v2H5v2l-3-3z" fill="#E0E0E0"/>
		  <path d="M22 12l-3 3v-2h-4v-2h4V9l3 3z" fill="#E0E0E0"/>
		</svg>
		""";

	/// Rotate gizmo: circular arrow.
	private const String cRotate = """
		<svg viewBox="0 0 24 24">
		  <path d="M12 4c4.42 0 8 3.58 8 8h-2.5c0-3.04-2.46-5.5-5.5-5.5S6.5 8.96 6.5 12s2.46 5.5 5.5 5.5c1.52 0 2.9-.62 3.89-1.61l1.77 1.77A7.96 7.96 0 0112 20c-4.42 0-8-3.58-8-8s3.58-8 8-8z" fill="#E0E0E0"/>
		  <path d="M20 12l3-3v6l-3-3z" fill="#E0E0E0"/>
		</svg>
		""";

	/// Scale gizmo: diagonal arrow with corner squares.
	private const String cScale = """
		<svg viewBox="0 0 24 24">
		  <rect x="3" y="3" width="5" height="5" fill="#E0E0E0"/>
		  <path d="M8 8l10 10" stroke="#E0E0E0" stroke-width="2" stroke-linecap="round"/>
		  <rect x="16" y="16" width="5" height="5" fill="#E0E0E0"/>
		  <path d="M14 20h6v-6" fill="none" stroke="#E0E0E0" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
		</svg>
		""";

	/// World space: globe.
	private const String cWorldSpace = """
		<svg viewBox="0 0 24 24">
		  <circle cx="12" cy="12" r="9" fill="none" stroke="#E0E0E0" stroke-width="1.5"/>
		  <ellipse cx="12" cy="12" rx="4" ry="9" fill="none" stroke="#E0E0E0" stroke-width="1"/>
		  <line x1="3" y1="12" x2="21" y2="12" stroke="#E0E0E0" stroke-width="1"/>
		  <line x1="12" y1="3" x2="12" y2="21" stroke="#E0E0E0" stroke-width="1"/>
		</svg>
		""";

	/// Local space: cube.
	private const String cLocalSpace = """
		<svg viewBox="0 0 24 24">
		  <path d="M12 2L4 7v10l8 5 8-5V7l-8-5z" fill="none" stroke="#E0E0E0" stroke-width="1.5" stroke-linejoin="round"/>
		  <path d="M12 22V12M4 7l8 5 8-5" fill="none" stroke="#E0E0E0" stroke-width="1" stroke-linejoin="round"/>
		</svg>
		""";

	/// Debug grid: 4x4 grid pattern.
	private const String cGrid = """
		<svg viewBox="0 0 24 24">
		  <rect x="3" y="3" width="18" height="18" fill="none" stroke="#E0E0E0" stroke-width="1.4"/>
		  <line x1="9"  y1="3" x2="9"  y2="21" stroke="#E0E0E0" stroke-width="1"/>
		  <line x1="15" y1="3" x2="15" y2="21" stroke="#E0E0E0" stroke-width="1"/>
		  <line x1="3" y1="9"  x2="21" y2="9"  stroke="#E0E0E0" stroke-width="1"/>
		  <line x1="3" y1="15" x2="21" y2="15" stroke="#E0E0E0" stroke-width="1"/>
		</svg>
		""";

	/// Scene: linked nodes (a scene graph).
	private const String cScene = """
		<svg viewBox="0 0 24 24">
		  <circle cx="12" cy="5" r="2.2" fill="none" stroke="#E0E0E0" stroke-width="1.4"/>
		  <circle cx="5" cy="18" r="2.2" fill="none" stroke="#E0E0E0" stroke-width="1.4"/>
		  <circle cx="19" cy="18" r="2.2" fill="none" stroke="#E0E0E0" stroke-width="1.4"/>
		  <path d="M11 7l-5 9M13 7l5 9M7 18h10" fill="none" stroke="#E0E0E0" stroke-width="1.2"/>
		</svg>
		""";

	/// Prefab/model manifest: cube outline with an inset cube (template).
	private const String cPrefab = """
		<svg viewBox="0 0 24 24">
		  <path d="M12 2L4 6v12l8 4 8-4V6l-8-4z" fill="none" stroke="#E0E0E0" stroke-width="1.4" stroke-linejoin="round"/>
		  <path d="M12 22V11M4 6l8 5 8-5" fill="none" stroke="#E0E0E0" stroke-width="1"/>
		  <rect x="9" y="13" width="6" height="6" fill="none" stroke="#E0E0E0" stroke-width="1" stroke-linejoin="round"/>
		</svg>
		""";

	/// Mesh: wireframe pyramid.
	private const String cMesh = """
		<svg viewBox="0 0 24 24">
		  <path d="M12 3L3 20h18L12 3z" fill="none" stroke="#E0E0E0" stroke-width="1.4" stroke-linejoin="round"/>
		  <path d="M12 3v17M3 20l9-6 9 6" fill="none" stroke="#E0E0E0" stroke-width="1"/>
		</svg>
		""";

	/// Skinned mesh: pyramid + bone overlay.
	private const String cSkinnedMesh = """
		<svg viewBox="0 0 24 24">
		  <path d="M12 3L3 20h18L12 3z" fill="none" stroke="#E0E0E0" stroke-width="1.2" stroke-linejoin="round"/>
		  <path d="M12 3v17M3 20l9-6 9 6" fill="none" stroke="#E0E0E0" stroke-width="0.8"/>
		  <circle cx="12" cy="9" r="1.6" fill="#E0E0E0"/>
		  <circle cx="12" cy="17" r="1.6" fill="#E0E0E0"/>
		  <line x1="12" y1="10.5" x2="12" y2="15.5" stroke="#E0E0E0" stroke-width="1.4"/>
		</svg>
		""";

	/// Material: shaded sphere with highlight.
	private const String cMaterial = """
		<svg viewBox="0 0 24 24">
		  <circle cx="12" cy="12" r="9" fill="none" stroke="#E0E0E0" stroke-width="1.4"/>
		  <path d="M3 12a9 9 0 0118 0" fill="none" stroke="#E0E0E0" stroke-width="0.9"/>
		  <circle cx="9" cy="9" r="1.6" fill="#E0E0E0"/>
		</svg>
		""";

	/// Texture/image: image frame with mountain glyph.
	private const String cTexture = """
		<svg viewBox="0 0 24 24">
		  <rect x="3" y="4" width="18" height="16" fill="none" stroke="#E0E0E0" stroke-width="1.4" rx="1"/>
		  <circle cx="8" cy="9" r="1.5" fill="#E0E0E0"/>
		  <path d="M3 17l5-5 4 4 3-3 6 6" fill="none" stroke="#E0E0E0" stroke-width="1.2" stroke-linejoin="round"/>
		</svg>
		""";

	/// Particle effect: burst pattern.
	private const String cParticleFx = """
		<svg viewBox="0 0 24 24">
		  <circle cx="12" cy="12" r="2" fill="#E0E0E0"/>
		  <circle cx="4" cy="6" r="1.2" fill="#E0E0E0"/>
		  <circle cx="20" cy="6" r="1.2" fill="#E0E0E0"/>
		  <circle cx="3" cy="14" r="1" fill="#E0E0E0"/>
		  <circle cx="21" cy="15" r="1" fill="#E0E0E0"/>
		  <circle cx="7" cy="20" r="1" fill="#E0E0E0"/>
		  <circle cx="17" cy="20" r="1" fill="#E0E0E0"/>
		  <circle cx="12" cy="3" r="1.2" fill="#E0E0E0"/>
		</svg>
		""";

	/// Animation clip: filmstrip.
	private const String cAnimation = """
		<svg viewBox="0 0 24 24">
		  <rect x="3" y="5" width="18" height="14" fill="none" stroke="#E0E0E0" stroke-width="1.4" rx="1"/>
		  <line x1="3" y1="9" x2="21" y2="9" stroke="#E0E0E0" stroke-width="1"/>
		  <line x1="3" y1="15" x2="21" y2="15" stroke="#E0E0E0" stroke-width="1"/>
		  <line x1="9" y1="5" x2="9" y2="19" stroke="#E0E0E0" stroke-width="1"/>
		  <line x1="15" y1="5" x2="15" y2="19" stroke="#E0E0E0" stroke-width="1"/>
		</svg>
		""";

	/// Animation graph: connected state nodes.
	private const String cAnimGraph = """
		<svg viewBox="0 0 24 24">
		  <circle cx="6" cy="6" r="2.2" fill="none" stroke="#E0E0E0" stroke-width="1.4"/>
		  <circle cx="18" cy="6" r="2.2" fill="none" stroke="#E0E0E0" stroke-width="1.4"/>
		  <circle cx="6" cy="18" r="2.2" fill="none" stroke="#E0E0E0" stroke-width="1.4"/>
		  <circle cx="18" cy="18" r="2.2" fill="none" stroke="#E0E0E0" stroke-width="1.4"/>
		  <path d="M8 6h8M6 8v8M18 8v8M8 18h8M8 8l8 8" fill="none" stroke="#E0E0E0" stroke-width="1.2"/>
		</svg>
		""";

	/// Skeleton: articulated stick figure.
	private const String cSkeleton = """
		<svg viewBox="0 0 24 24">
		  <circle cx="12" cy="5" r="2" fill="none" stroke="#E0E0E0" stroke-width="1.4"/>
		  <line x1="12" y1="7" x2="12" y2="14" stroke="#E0E0E0" stroke-width="1.4"/>
		  <line x1="7" y1="10" x2="17" y2="10" stroke="#E0E0E0" stroke-width="1.4"/>
		  <line x1="12" y1="14" x2="8" y2="20" stroke="#E0E0E0" stroke-width="1.4"/>
		  <line x1="12" y1="14" x2="16" y2="20" stroke="#E0E0E0" stroke-width="1.4"/>
		  <circle cx="12" cy="14" r="1.2" fill="#E0E0E0"/>
		  <circle cx="7" cy="10" r="1" fill="#E0E0E0"/>
		  <circle cx="17" cy="10" r="1" fill="#E0E0E0"/>
		</svg>
		""";

	/// Folder: classic folder glyph.
	private const String cFolder = """
		<svg viewBox="0 0 24 24">
		  <path d="M3 7a1 1 0 011-1h5l2 2h9a1 1 0 011 1v9a1 1 0 01-1 1H4a1 1 0 01-1-1V7z" fill="none" stroke="#E0E0E0" stroke-width="1.4" stroke-linejoin="round"/>
		</svg>
		""";

	/// Unknown: generic document with a folded corner.
	private const String cUnknown = """
		<svg viewBox="0 0 24 24">
		  <path d="M6 3h8l5 5v12a1 1 0 01-1 1H6a1 1 0 01-1-1V4a1 1 0 011-1z" fill="none" stroke="#E0E0E0" stroke-width="1.4" stroke-linejoin="round"/>
		  <path d="M14 3v5h5" fill="none" stroke="#E0E0E0" stroke-width="1.2"/>
		</svg>
		""";

	/// Close X: the tab/panel close glyph (diamond-cut X polygon).
	private const String cClose = """
		<svg viewBox="0 0 24 24">
		  <path d="M3.5 5.3L5.3 3.5 12 10.2 18.7 3.5 20.5 5.3 13.8 12 20.5 18.7 18.7 20.5 12 13.8 5.3 20.5 3.5 18.7 10.2 12z" fill="#E0E0E0"/>
		</svg>
		""";

	/// Add: plus (add a list row).
	private const String cAdd = """
		<svg viewBox="0 0 24 24">
		  <path d="M11 5h2v6h6v2h-6v6h-2v-6H5v-2h6z" fill="#E0E0E0"/>
		</svg>
		""";

	/// Remove: trash can (delete a list row).
	private const String cRemove = """
		<svg viewBox="0 0 24 24">
		  <path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z" fill="#E0E0E0"/>
		</svg>
		""";

	/// Move up: chevron up (reorder a list row).
	private const String cMoveUp = """
		<svg viewBox="0 0 24 24">
		  <path d="M12 8l-6 6 1.4 1.4L12 10.8l4.6 4.6L18 14z" fill="#E0E0E0"/>
		</svg>
		""";

	/// Move down: chevron down (reorder a list row).
	private const String cMoveDown = """
		<svg viewBox="0 0 24 24">
		  <path d="M12 16l6-6-1.4-1.4L12 13.2 7.4 8.6 6 10z" fill="#E0E0E0"/>
		</svg>
		""";

	/// Copy: two overlapping documents (duplicate a component).
	private const String cCopy = """
		<svg viewBox="0 0 24 24">
		  <path d="M16 1H4a2 2 0 00-2 2v12h2V3h12V1zm3 4H8a2 2 0 00-2 2v14a2 2 0 002 2h11a2 2 0 002-2V7a2 2 0 00-2-2zm0 16H8V7h11v14z" fill="#E0E0E0"/>
		</svg>
		""";

	/// Edit: a pen at 45 degrees with a small nib notch (open-for-editing).
	private const String cEdit = """
		<svg viewBox="0 0 24 24">
		  <path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04a1 1 0 000-1.41l-2.34-2.34a1 1 0 00-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z" fill="#E0E0E0"/>
		</svg>
		""";

	/// Brush Raise: an up arrow rising off a ground baseline.
	private const String cBrushRaise = """
		<svg viewBox="0 0 24 24">
		  <path d="M4 20h16" fill="none" stroke="#E0E0E0" stroke-width="2" stroke-linecap="round"/>
		  <path d="M12 16V5M7.5 9.5L12 5l4.5 4.5" fill="none" stroke="#E0E0E0" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
		</svg>
		""";

	/// Brush Lower: a down arrow pushing toward a ground baseline.
	private const String cBrushLower = """
		<svg viewBox="0 0 24 24">
		  <path d="M4 20h16" fill="none" stroke="#E0E0E0" stroke-width="2" stroke-linecap="round"/>
		  <path d="M12 4v11M7.5 10.5L12 15l4.5-4.5" fill="none" stroke="#E0E0E0" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
		</svg>
		""";

	/// Brush Smooth: a smooth wave (neighbourhood averaging).
	private const String cBrushSmooth = """
		<svg viewBox="0 0 24 24">
		  <path d="M3 14C6 7 9 7 12 13S18 20 21 13" fill="none" stroke="#E0E0E0" stroke-width="2" stroke-linecap="round"/>
		</svg>
		""";

	/// Brush Flatten: a flat bar with two arrows pressing down onto it.
	private const String cBrushFlatten = """
		<svg viewBox="0 0 24 24">
		  <path d="M4 17h16" fill="none" stroke="#E0E0E0" stroke-width="2" stroke-linecap="round"/>
		  <path d="M8 5v6M5.8 8.2L8 11l2.2-2.8" fill="none" stroke="#E0E0E0" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
		  <path d="M16 5v6M13.8 8.2L16 11l2.2-2.8" fill="none" stroke="#E0E0E0" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
		</svg>
		""";
}
