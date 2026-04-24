namespace Sedulous.Tools.ModelViewer;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Geometry;
using Sedulous.Geometry.Resources;
using Sedulous.Geometry.Tooling;
using Sedulous.Geometry.Tooling.Resources;
using Sedulous.Materials;
using Sedulous.Materials.Resources;
using Sedulous.Textures.Resources;
using Sedulous.Animation;
using Sedulous.Animation.Resources;
using Sedulous.Resources;
using Sedulous.UI.Viewport;
using Sedulous.UI;

/// Per-tab state for a loaded model.
class ModelTab
{
	public String Name ~ delete _;
	public Scene Scene;
	public EntityHandle ModelEntity = .Invalid;
	public EntityHandle CameraEntity = .Invalid;

	// Model resources (refs released on close)
	public StaticMeshResource MeshResource;
	public SkinnedMeshResource SkinnedMeshRes;
	public SkeletonResource SkeletonRes;
	public List<AnimationClipResource> AnimClipResources = new .() ~ delete _;
	public List<String> AnimClipNames = new .() ~ DeleteContainerAndItems!(_);
	public ImportDeduplicationContext DedupContext = new .() ~ delete _;

	// Model info
	public BoundingBox Bounds;
	public int32 MeshCount;
	public int32 VertexCount;
	public int32 TriangleCount;
	public int32 MaterialCount;
	public int32 BoneCount;
	public int32 AnimationCount;
	public bool IsSkinned;

	// Visualization state
	public bool ShowGrid = true;
	public bool ShowBoundingBox = false;
	public bool ShowSkeleton = false;
	public float ModelScale = 1.0f;
	public float Exposure = 1.0f;
	public float AmbientIntensity = 0.15f;

	// Animation state
	public int32 CurrentAnimIndex = -1;
	public bool AnimPlaying = false;
	public bool AnimLoop = true;

	// Per-tab UI (ContentPanel owns toolbar + viewport + anim toolbar)
	public Sedulous.UI.LinearLayout ContentPanel;  // vertical: top toolbar + viewport + anim toolbar
	public Sedulous.UI.Viewport.ViewportView Viewport;
	public ComboBox AnimComboBox;
	public Button PlayPauseBtn;
	public Label ScaleValueLabel;

	// Camera controller
	public ViewportCameraController CameraController;

	public void ReleaseRefs()
	{
		MeshResource?.ReleaseRef();
		SkinnedMeshRes?.ReleaseRef();
		SkeletonRes?.ReleaseRef();
		for (let clip in AnimClipResources)
			clip?.ReleaseRef();
		DedupContext.ReleaseAllRefs();
	}
}
