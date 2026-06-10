using System;
using Sedulous.UI;

namespace Sedulous.Editor.App;

/// SVG icon strings and shared drawable instances for editor UI elements.
/// Call Initialize() once at startup, Shutdown() on exit.
static class EditorIcons
{
	// Shared drawable instances (created once, used by all scene pages)
	public static SVGDrawable TranslateIcon;
	public static SVGDrawable RotateIcon;
	public static SVGDrawable ScaleIcon;
	public static SVGDrawable WorldSpaceIcon;
	public static SVGDrawable LocalSpaceIcon;
	public static SVGDrawable GridIcon;

	// Asset-browser per-extension icons (Phase 1 of thumbnail rollout).
	public static SVGDrawable SceneIcon;
	public static SVGDrawable PrefabIcon;
	public static SVGDrawable MeshIcon;
	public static SVGDrawable SkinnedMeshIcon;
	public static SVGDrawable MaterialIcon;
	public static SVGDrawable TextureIcon;
	public static SVGDrawable ParticleFxIcon;
	public static SVGDrawable AudioClipIcon;
	public static SVGDrawable SoundCueIcon;
	public static SVGDrawable AnimationIcon;
	public static SVGDrawable AnimGraphIcon;
	public static SVGDrawable SkeletonIcon;
	public static SVGDrawable PropAnimIcon;
	public static SVGDrawable FontIcon;
	public static SVGDrawable FolderIcon;
	public static SVGDrawable UnknownIcon;

	public static void Initialize()
	{
		TranslateIcon = SVGDrawable.FromString(Translate);
		RotateIcon = SVGDrawable.FromString(Rotate);
		ScaleIcon = SVGDrawable.FromString(Scale);
		WorldSpaceIcon = SVGDrawable.FromString(WorldSpace);
		LocalSpaceIcon = SVGDrawable.FromString(LocalSpace);
		GridIcon = SVGDrawable.FromString(Grid);

		SceneIcon = SVGDrawable.FromString(Scene);
		PrefabIcon = SVGDrawable.FromString(Prefab);
		MeshIcon = SVGDrawable.FromString(Mesh);
		SkinnedMeshIcon = SVGDrawable.FromString(SkinnedMesh);
		MaterialIcon = SVGDrawable.FromString(Material);
		TextureIcon = SVGDrawable.FromString(Texture);
		ParticleFxIcon = SVGDrawable.FromString(ParticleFx);
		AudioClipIcon = SVGDrawable.FromString(AudioClip);
		SoundCueIcon = SVGDrawable.FromString(SoundCue);
		AnimationIcon = SVGDrawable.FromString(Animation);
		AnimGraphIcon = SVGDrawable.FromString(AnimGraph);
		SkeletonIcon = SVGDrawable.FromString(Skeleton);
		PropAnimIcon = SVGDrawable.FromString(PropAnim);
		FontIcon = SVGDrawable.FromString(Font);
		FolderIcon = SVGDrawable.FromString(Folder);
		UnknownIcon = SVGDrawable.FromString(Unknown);
	}

	public static void Shutdown()
	{
		TranslateIcon.ReleaseRef(); TranslateIcon = null;
		RotateIcon.ReleaseRef(); RotateIcon = null;
		ScaleIcon.ReleaseRef(); ScaleIcon = null;
		WorldSpaceIcon.ReleaseRef(); WorldSpaceIcon = null;
		LocalSpaceIcon.ReleaseRef(); LocalSpaceIcon = null;
		GridIcon.ReleaseRef(); GridIcon = null;

		SceneIcon.ReleaseRef(); SceneIcon = null;
		PrefabIcon.ReleaseRef(); PrefabIcon = null;
		MeshIcon.ReleaseRef(); MeshIcon = null;
		SkinnedMeshIcon.ReleaseRef(); SkinnedMeshIcon = null;
		MaterialIcon.ReleaseRef(); MaterialIcon = null;
		TextureIcon.ReleaseRef(); TextureIcon = null;
		ParticleFxIcon.ReleaseRef(); ParticleFxIcon = null;
		AudioClipIcon.ReleaseRef(); AudioClipIcon = null;
		SoundCueIcon.ReleaseRef(); SoundCueIcon = null;
		AnimationIcon.ReleaseRef(); AnimationIcon = null;
		AnimGraphIcon.ReleaseRef(); AnimGraphIcon = null;
		SkeletonIcon.ReleaseRef(); SkeletonIcon = null;
		PropAnimIcon.ReleaseRef(); PropAnimIcon = null;
		FontIcon.ReleaseRef(); FontIcon = null;
		FolderIcon.ReleaseRef(); FolderIcon = null;
		UnknownIcon.ReleaseRef(); UnknownIcon = null;
	}

	/// Returns the icon associated with a resource extension (or the folder
	/// / unknown fallback). The returned `SVGDrawable` is owned by EditorIcons
	/// - callers should not delete it. Pass `isFolder = true` for directory
	/// entries; their extension is ignored.
	public static SVGDrawable GetForExtension(StringView @extension, bool isFolder = false)
	{
		if (isFolder) return FolderIcon;

		// Lowercase compare via case-insensitive Equals would be ideal, but
		// since asset-browser extensions are produced canonically lowercase,
		// direct equality is sufficient.
		if (@extension == ".scene")       return SceneIcon;
		if (@extension == ".prefab")      return PrefabIcon;
		if (@extension == ".mesh")        return MeshIcon;
		if (@extension == ".skinnedmesh") return SkinnedMeshIcon;
		if (@extension == ".material")    return MaterialIcon;
		if (@extension == ".texture")     return TextureIcon;
		if (@extension == ".particlefx")  return ParticleFxIcon;
		if (@extension == ".audioclip")   return AudioClipIcon;
		if (@extension == ".soundcue")    return SoundCueIcon;
		if (@extension == ".animation")   return AnimationIcon;
		if (@extension == ".animgraph")   return AnimGraphIcon;
		if (@extension == ".skeleton")    return SkeletonIcon;
		if (@extension == ".propanim")    return PropAnimIcon;
		if (@extension == ".font")        return FontIcon;

		return UnknownIcon;
	}

	/// Translate gizmo - four arrows pointing outward from center.
	public static readonly String Translate = """
		<svg viewBox="0 0 24 24">
		  <path d="M12 2l3 3h-2v4h-2V5H9l3-3z" fill="#E0E0E0"/>
		  <path d="M12 22l-3-3h2v-4h2v4h2l-3 3z" fill="#E0E0E0"/>
		  <path d="M2 12l3-3v2h4v2H5v2l-3-3z" fill="#E0E0E0"/>
		  <path d="M22 12l-3 3v-2h-4v-2h4V9l3 3z" fill="#E0E0E0"/>
		</svg>
		""";

	/// Rotate gizmo - circular arrow.
	public static readonly String Rotate = """
		<svg viewBox="0 0 24 24">
		  <path d="M12 4c4.42 0 8 3.58 8 8h-2.5c0-3.04-2.46-5.5-5.5-5.5S6.5 8.96 6.5 12s2.46 5.5 5.5 5.5c1.52 0 2.9-.62 3.89-1.61l1.77 1.77A7.96 7.96 0 0112 20c-4.42 0-8-3.58-8-8s3.58-8 8-8z" fill="#E0E0E0"/>
		  <path d="M20 12l3-3v6l-3-3z" fill="#E0E0E0"/>
		</svg>
		""";

	/// Scale gizmo - diagonal arrow with corner square.
	public static readonly String Scale = """
		<svg viewBox="0 0 24 24">
		  <rect x="3" y="3" width="5" height="5" fill="#E0E0E0"/>
		  <path d="M8 8l10 10" stroke="#E0E0E0" stroke-width="2" stroke-linecap="round"/>
		  <rect x="16" y="16" width="5" height="5" fill="#E0E0E0"/>
		  <path d="M14 20h6v-6" fill="none" stroke="#E0E0E0" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
		</svg>
		""";

	/// World space - globe/grid icon.
	public static readonly String WorldSpace = """
		<svg viewBox="0 0 24 24">
		  <circle cx="12" cy="12" r="9" fill="none" stroke="#E0E0E0" stroke-width="1.5"/>
		  <ellipse cx="12" cy="12" rx="4" ry="9" fill="none" stroke="#E0E0E0" stroke-width="1"/>
		  <line x1="3" y1="12" x2="21" y2="12" stroke="#E0E0E0" stroke-width="1"/>
		  <line x1="12" y1="3" x2="12" y2="21" stroke="#E0E0E0" stroke-width="1"/>
		</svg>
		""";

	/// Local space - cube icon.
	public static readonly String LocalSpace = """
		<svg viewBox="0 0 24 24">
		  <path d="M12 2L4 7v10l8 5 8-5V7l-8-5z" fill="none" stroke="#E0E0E0" stroke-width="1.5" stroke-linejoin="round"/>
		  <path d="M12 22V12M4 7l8 5 8-5" fill="none" stroke="#E0E0E0" stroke-width="1" stroke-linejoin="round"/>
		</svg>
		""";

	/// Debug grid - 4x4 grid pattern.
	public static readonly String Grid = """
		<svg viewBox="0 0 24 24">
		  <rect x="3" y="3" width="18" height="18" fill="none" stroke="#E0E0E0" stroke-width="1.4"/>
		  <line x1="9"  y1="3" x2="9"  y2="21" stroke="#E0E0E0" stroke-width="1"/>
		  <line x1="15" y1="3" x2="15" y2="21" stroke="#E0E0E0" stroke-width="1"/>
		  <line x1="3" y1="9"  x2="21" y2="9"  stroke="#E0E0E0" stroke-width="1"/>
		  <line x1="3" y1="15" x2="21" y2="15" stroke="#E0E0E0" stroke-width="1"/>
		</svg>
		""";

	// === Asset-browser resource icons (Phase 1 thumbnail rollout) ===

	/// Scene - linked nodes representing a scene graph.
	public static readonly String Scene = """
		<svg viewBox="0 0 24 24">
		  <circle cx="12" cy="5" r="2.2" fill="none" stroke="#E0E0E0" stroke-width="1.4"/>
		  <circle cx="5" cy="18" r="2.2" fill="none" stroke="#E0E0E0" stroke-width="1.4"/>
		  <circle cx="19" cy="18" r="2.2" fill="none" stroke="#E0E0E0" stroke-width="1.4"/>
		  <path d="M11 7l-5 9M13 7l5 9M7 18h10" fill="none" stroke="#E0E0E0" stroke-width="1.2"/>
		</svg>
		""";

	/// Prefab - cube outline with a small inset cube (template).
	public static readonly String Prefab = """
		<svg viewBox="0 0 24 24">
		  <path d="M12 2L4 6v12l8 4 8-4V6l-8-4z" fill="none" stroke="#E0E0E0" stroke-width="1.4" stroke-linejoin="round"/>
		  <path d="M12 22V11M4 6l8 5 8-5" fill="none" stroke="#E0E0E0" stroke-width="1"/>
		  <rect x="9" y="13" width="6" height="6" fill="none" stroke="#E0E0E0" stroke-width="1" stroke-linejoin="round"/>
		</svg>
		""";

	/// Mesh - wireframe pyramid (low-poly triangle).
	public static readonly String Mesh = """
		<svg viewBox="0 0 24 24">
		  <path d="M12 3L3 20h18L12 3z" fill="none" stroke="#E0E0E0" stroke-width="1.4" stroke-linejoin="round"/>
		  <path d="M12 3v17M3 20l9-6 9 6" fill="none" stroke="#E0E0E0" stroke-width="1"/>
		</svg>
		""";

	/// Skinned mesh - pyramid + bone overlay.
	public static readonly String SkinnedMesh = """
		<svg viewBox="0 0 24 24">
		  <path d="M12 3L3 20h18L12 3z" fill="none" stroke="#E0E0E0" stroke-width="1.2" stroke-linejoin="round"/>
		  <path d="M12 3v17M3 20l9-6 9 6" fill="none" stroke="#E0E0E0" stroke-width="0.8"/>
		  <circle cx="12" cy="9" r="1.6" fill="#E0E0E0"/>
		  <circle cx="12" cy="17" r="1.6" fill="#E0E0E0"/>
		  <line x1="12" y1="10.5" x2="12" y2="15.5" stroke="#E0E0E0" stroke-width="1.4"/>
		</svg>
		""";

	/// Material - shaded sphere with highlight.
	public static readonly String Material = """
		<svg viewBox="0 0 24 24">
		  <circle cx="12" cy="12" r="9" fill="none" stroke="#E0E0E0" stroke-width="1.4"/>
		  <path d="M3 12a9 9 0 0118 0" fill="none" stroke="#E0E0E0" stroke-width="0.9"/>
		  <circle cx="9" cy="9" r="1.6" fill="#E0E0E0"/>
		</svg>
		""";

	/// Texture - image frame with mountain glyph.
	public static readonly String Texture = """
		<svg viewBox="0 0 24 24">
		  <rect x="3" y="4" width="18" height="16" fill="none" stroke="#E0E0E0" stroke-width="1.4" rx="1"/>
		  <circle cx="8" cy="9" r="1.5" fill="#E0E0E0"/>
		  <path d="M3 17l5-5 4 4 3-3 6 6" fill="none" stroke="#E0E0E0" stroke-width="1.2" stroke-linejoin="round"/>
		</svg>
		""";

	/// Particle effect - burst pattern from a central point.
	public static readonly String ParticleFx = """
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

	/// Audio clip - speaker with two arc waves.
	public static readonly String AudioClip = """
		<svg viewBox="0 0 24 24">
		  <path d="M4 9v6h4l5 4V5L8 9H4z" fill="#E0E0E0"/>
		  <path d="M16 8c1.5 1.5 1.5 6.5 0 8" fill="none" stroke="#E0E0E0" stroke-width="1.4" stroke-linecap="round"/>
		  <path d="M19 5c3 3 3 11 0 14" fill="none" stroke="#E0E0E0" stroke-width="1.4" stroke-linecap="round"/>
		</svg>
		""";

	/// Sound cue - speaker with branching arrows (cue/variation).
	public static readonly String SoundCue = """
		<svg viewBox="0 0 24 24">
		  <path d="M3 10v4h3l4 3V7L6 10H3z" fill="#E0E0E0"/>
		  <path d="M13 6l4 3-4 3M13 12l4 3-4 3" fill="none" stroke="#E0E0E0" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>
		  <path d="M12 9h5M12 15h5" fill="none" stroke="#E0E0E0" stroke-width="1.2"/>
		</svg>
		""";

	/// Animation - filmstrip.
	public static readonly String Animation = """
		<svg viewBox="0 0 24 24">
		  <rect x="3" y="5" width="18" height="14" fill="none" stroke="#E0E0E0" stroke-width="1.4" rx="1"/>
		  <line x1="3" y1="9" x2="21" y2="9" stroke="#E0E0E0" stroke-width="1"/>
		  <line x1="3" y1="15" x2="21" y2="15" stroke="#E0E0E0" stroke-width="1"/>
		  <line x1="9" y1="5" x2="9" y2="19" stroke="#E0E0E0" stroke-width="1"/>
		  <line x1="15" y1="5" x2="15" y2="19" stroke="#E0E0E0" stroke-width="1"/>
		</svg>
		""";

	/// Animation graph - connected nodes (state graph).
	public static readonly String AnimGraph = """
		<svg viewBox="0 0 24 24">
		  <circle cx="6" cy="6" r="2.2" fill="none" stroke="#E0E0E0" stroke-width="1.4"/>
		  <circle cx="18" cy="6" r="2.2" fill="none" stroke="#E0E0E0" stroke-width="1.4"/>
		  <circle cx="6" cy="18" r="2.2" fill="none" stroke="#E0E0E0" stroke-width="1.4"/>
		  <circle cx="18" cy="18" r="2.2" fill="none" stroke="#E0E0E0" stroke-width="1.4"/>
		  <path d="M8 6h8M6 8v8M18 8v8M8 18h8M8 8l8 8" fill="none" stroke="#E0E0E0" stroke-width="1.2"/>
		</svg>
		""";

	/// Skeleton - articulated stick figure.
	public static readonly String Skeleton = """
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

	/// Property animation - filmstrip with property dot.
	public static readonly String PropAnim = """
		<svg viewBox="0 0 24 24">
		  <rect x="3" y="6" width="18" height="12" fill="none" stroke="#E0E0E0" stroke-width="1.4" rx="1"/>
		  <line x1="3" y1="12" x2="21" y2="12" stroke="#E0E0E0" stroke-width="0.8"/>
		  <circle cx="7" cy="12" r="1.5" fill="#E0E0E0"/>
		  <circle cx="13" cy="9" r="1.5" fill="#E0E0E0"/>
		  <circle cx="17" cy="15" r="1.5" fill="#E0E0E0"/>
		</svg>
		""";

	/// Font - sample "Aa" glyphs.
	public static readonly String Font = """
		<svg viewBox="0 0 24 24">
		  <text x="2" y="19" font-family="Georgia, serif" font-size="20" font-weight="700" fill="#E0E0E0">Aa</text>
		</svg>
		""";

	/// Folder - classic folder glyph.
	public static readonly String Folder = """
		<svg viewBox="0 0 24 24">
		  <path d="M3 7a1 1 0 011-1h5l2 2h9a1 1 0 011 1v9a1 1 0 01-1 1H4a1 1 0 01-1-1V7z" fill="none" stroke="#E0E0E0" stroke-width="1.4" stroke-linejoin="round"/>
		</svg>
		""";

	/// Unknown - generic document with a folded corner.
	public static readonly String Unknown = """
		<svg viewBox="0 0 24 24">
		  <path d="M6 3h8l5 5v12a1 1 0 01-1 1H6a1 1 0 01-1-1V4a1 1 0 011-1z" fill="none" stroke="#E0E0E0" stroke-width="1.4" stroke-linejoin="round"/>
		  <path d="M14 3v5h5" fill="none" stroke="#E0E0E0" stroke-width="1.2"/>
		</svg>
		""";
}
