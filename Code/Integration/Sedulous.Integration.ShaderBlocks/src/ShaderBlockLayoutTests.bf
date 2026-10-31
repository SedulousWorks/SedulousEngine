using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Materials;
using Sedulous.Render;
using Sedulous.Shaders;
using Sedulous.VFS;

namespace Sedulous.Integration.ShaderBlocks;

/// One member as the Beef mirror lays it out, under the shader's name for it.
struct FieldRow : this(StringView Name, int Offset);

/// Every engine shader block against its Beef mirror, member by member. The engine's shaders are
/// cooked to SPIR-V as the engine cook does (CookEngineShaders), and each block's members are read
/// from what DXC compiled: its OpMemberName and OpMemberDecorate Offset, the offsets Vulkan uses
/// and the WGSL translation starts from. A field added, moved or renamed on one side only fails
/// here, which a size check alone does not catch (two fields swapped, a value moved into padding of
/// the same size). It needs no GPU.
class ShaderBlockLayoutTests
{
	private static FieldRow[?] sGpuLight = .(
		.("positionWS", offsetof(GpuLight, PositionWS)),
		.("range", offsetof(GpuLight, Range)),
		.("color", offsetof(GpuLight, Color)),
		.("intensity", offsetof(GpuLight, Intensity)),
		.("directionWS", offsetof(GpuLight, DirectionWS)),
		.("type", offsetof(GpuLight, Type)),
		.("innerCos", offsetof(GpuLight, InnerCos)),
		.("outerCos", offsetof(GpuLight, OuterCos)),
		.("shadowIndex", offsetof(GpuLight, ShadowIndex)),
		.("shadowStrength", offsetof(GpuLight, ShadowStrength)));

	private static FieldRow[?] sGpuLocalShadow = .(
		.("viewProj", offsetof(GpuLocalShadow, ViewProjection)),
		.("atlasScaleBias", offsetof(GpuLocalShadow, AtlasScaleBias)),
		.("depthBias", offsetof(GpuLocalShadow, DepthBias)),
		.("atlasSelect", offsetof(GpuLocalShadow, AtlasSelect)),
		.("normalBiasPerDistance", offsetof(GpuLocalShadow, NormalBiasPerDistance)),
		.("_localPad", offsetof(GpuLocalShadow, Pad2)));

	private static FieldRow[?] sGpuProbe = .(
		.("center", offsetof(GpuProbe, Center)),
		.("intensity", offsetof(GpuProbe, Intensity)),
		.("boxMin", offsetof(GpuProbe, BoxMin)),
		.("blendDistance", offsetof(GpuProbe, BlendDistance)),
		.("boxMax", offsetof(GpuProbe, BoxMax)),
		.("slice", offsetof(GpuProbe, Slice)),
		.("mipCount", offsetof(GpuProbe, MipCount)),
		.("priority", offsetof(GpuProbe, Priority)),
		.("parallax", offsetof(GpuProbe, Parallax)),
		.("_probeRecordPad", offsetof(GpuProbe, Pad)));

	private static FieldRow[?] sDecalUniforms = .(
		.("World", offsetof(DecalUniforms, World)),
		.("InvWorld", offsetof(DecalUniforms, InvWorld)),
		.("InvViewProj", offsetof(DecalUniforms, InvViewProj)),
		.("Color", offsetof(DecalUniforms, Color)),
		.("InvTargetSize", offsetof(DecalUniforms, InvTargetSize)),
		.("FadeStartCos", offsetof(DecalUniforms, FadeStartCos)),
		.("FadeEndCos", offsetof(DecalUniforms, FadeEndCos)),
		.("YFlip", offsetof(DecalUniforms, YFlip)),
		.("_decalPad0", offsetof(DecalUniforms, Pad0)),
		.("_decalPad1", offsetof(DecalUniforms, Pad1)),
		.("_decalPad2", offsetof(DecalUniforms, Pad2)));

	/// The forward view (view.hlsli), as every forward stage declares it.
	private static FieldRow[?] sView = .(
		.("ViewProj", offsetof(MeshViewData, ViewProj)),
		.("View", offsetof(MeshViewData, View)),
		.("CascadeViewProj", offsetof(MeshViewData, CascadeViewProj)),
		.("CameraPos", offsetof(MeshViewData, CameraPos)),
		.("LightCount", offsetof(MeshViewData, LightCount)),
		.("LightOffset", offsetof(MeshViewData, LightOffset)),
		.("ClusterVpX", offsetof(MeshViewData, ClusterViewportX)),
		.("ClusterVpY", offsetof(MeshViewData, ClusterViewportY)),
		.("IBLMaxLod", offsetof(MeshViewData, IblMaxLod)),
		.("ClusterGridX", offsetof(MeshViewData, ClusterGridX)),
		.("ClusterGridY", offsetof(MeshViewData, ClusterGridY)),
		.("ClusterSliceCount", offsetof(MeshViewData, ClusterSliceCount)),
		.("ClusterTileSize", offsetof(MeshViewData, ClusterTileSize)),
		.("ClusterNear", offsetof(MeshViewData, ClusterNear)),
		.("ClusterFar", offsetof(MeshViewData, ClusterFar)),
		.("ClusterLogScale", offsetof(MeshViewData, ClusterLogScale)),
		.("ClusterLogBias", offsetof(MeshViewData, ClusterLogBias)),
		.("Ambient", offsetof(MeshViewData, Ambient)),
		.("ShadowCascadeCount", offsetof(MeshViewData, ShadowCascadeCount)),
		.("CascadeSplitFar", offsetof(MeshViewData, CascadeSplitFar)),
		.("CascadeTexelSize", offsetof(MeshViewData, CascadeTexelSize)),
		.("ShadowNormalBias", offsetof(MeshViewData, ShadowNormalBias)),
		.("ShadowDepthBias", offsetof(MeshViewData, ShadowDepthBias)),
		.("CascadeLayerBase", offsetof(MeshViewData, CascadeLayerBase)),
		.("LocalShadowBase", offsetof(MeshViewData, LocalShadowBase)),
		.("PrevViewProj", offsetof(MeshViewData, PrevViewProj)),
		.("Jitter", offsetof(MeshViewData, Jitter)),
		.("ProbeBase", offsetof(MeshViewData, ProbeBase)),
		.("ProbeCount", offsetof(MeshViewData, ProbeCount)),
		.("_probePad0", offsetof(MeshViewData, ProbePad0)),
		.("_probePad1", offsetof(MeshViewData, ProbePad1)),
		.("ShadowParams", offsetof(MeshViewData, ShadowParams)),
		.("DebugParams", offsetof(MeshViewData, DebugParams)),
		.("IblDiffuse", offsetof(MeshViewData, IblDiffuse)),
		.("IblSpecular", offsetof(MeshViewData, IblSpecular)),
		.("SceneTime", offsetof(MeshViewData, SceneTime)),
		.("PrevSceneTime", offsetof(MeshViewData, PrevSceneTime)));

	/// The per draw block: one Beef struct and one declaration (object_block.hlsli) that the
	/// forward, shadow depth and pick vertex stages all include, every field by its name in each.
	private static FieldRow[?] sObject = .(
		.("World", offsetof(MeshObjectData, World)),
		.("PrevWorld", offsetof(MeshObjectData, PrevWorld)),
		.("Tint", offsetof(MeshObjectData, Tint)),
		.("BoneBase", offsetof(MeshObjectData, BoneBase)),
		.("PrevBoneBase", offsetof(MeshObjectData, PrevBoneBase)),
		.("PickIndex", offsetof(MeshObjectData, PickIndex)),
		.("PickGeneration", offsetof(MeshObjectData, PickGeneration)),
		.("Fade", offsetof(MeshObjectData, Fade)),
		.("_objectPad0", offsetof(MeshObjectData, ObjectPad0)),
		.("_objectPad1", offsetof(MeshObjectData, ObjectPad1)),
		.("_objectPad2", offsetof(MeshObjectData, ObjectPad2)));

	private static FieldRow[?] sInstance = .(
		.("World", offsetof(MeshInstanceData, World)),
		.("PrevWorld", offsetof(MeshInstanceData, PrevWorld)),
		.("Tint", offsetof(MeshInstanceData, Tint)));

	private static FieldRow[?] sShadowView = .(
		.("LightViewProj", offsetof(MeshShadowViewData, LightViewProj)),
		.("ShadowCamera", offsetof(MeshShadowViewData, Camera)),
		.("ShadowFadeFromCamera", offsetof(MeshShadowViewData, FadeFromCamera)),
		.("SceneTime", offsetof(MeshShadowViewData, SceneTime)),
		.("_shadowPad0", offsetof(MeshShadowViewData, Pad0)),
		.("_shadowPad1", offsetof(MeshShadowViewData, Pad1)),
		.("_shadowPad2", offsetof(MeshShadowViewData, Pad2)));

	private static FieldRow[?] sPickView = .(
		.("ViewProj", offsetof(MeshPickViewData, ViewProj)),
		.("SceneTime", offsetof(MeshPickViewData, SceneTime)),
		.("_pickPad0", offsetof(MeshPickViewData, Pad0)),
		.("_pickPad1", offsetof(MeshPickViewData, Pad1)),
		.("_pickPad2", offsetof(MeshPickViewData, Pad2)),
		.("PickCamera", offsetof(MeshPickViewData, Camera)),
		.("_pickPad3", offsetof(MeshPickViewData, Pad3)));

	/// An instanced draw's set: its fade window, count and set pick id (instance_fade.hlsli).
	private static FieldRow[?] sInstanceSet = .(
		.("FadeStart", offsetof(MeshInstanceSetData, FadeStart)),
		.("FadeEnd", offsetof(MeshInstanceSetData, FadeEnd)),
		.("InstanceCount", offsetof(MeshInstanceSetData, InstanceCount)),
		.("_setPad0", offsetof(MeshInstanceSetData, Pad0)),
		.("SetPickIndex", offsetof(MeshInstanceSetData, PickIndex)),
		.("SetPickGeneration", offsetof(MeshInstanceSetData, PickGeneration)),
		.("_setPad1", offsetof(MeshInstanceSetData, Pad1)),
		.("_setPad2", offsetof(MeshInstanceSetData, Pad2)));

	private static FieldRow[?] sSky = .(
		.("InvViewProj", offsetof(SkyUniform, InvViewProj)),
		.("PrevViewProj", offsetof(SkyUniform, PrevViewProj)),
		.("CameraPos", offsetof(SkyUniform, CameraPos)),
		.("BackgroundIntensity", offsetof(SkyUniform, BackgroundIntensity)),
		.("SunDirection", offsetof(SkyUniform, SunDirection)),
		.("SunAngularSizeDegrees", offsetof(SkyUniform, SunAngularSizeDegrees)),
		.("SunColor", offsetof(SkyUniform, SunColor)),
		.("SunIntensity", offsetof(SkyUniform, SunIntensity)),
		.("Jitter", offsetof(SkyUniform, Jitter)),
		.("SkyFlags", offsetof(SkyUniform, SkyFlags)));

	private static FieldRow[?] sIblPush = .(
		.("FaceIndex", offsetof(IblPush, FaceIndex)),
		.("Mode", offsetof(IblPush, Mode)),
		.("Roughness", offsetof(IblPush, Roughness)),
		.("SkyIntensity", offsetof(IblPush, SkyIntensity)),
		.("SunDirection", offsetof(IblPush, SunDirection)),
		.("SunAngularSize", offsetof(IblPush, SunAngularSize)),
		.("Horizon", offsetof(IblPush, Horizon)),
		.("SunIntensity", offsetof(IblPush, SunIntensity)),
		.("Zenith", offsetof(IblPush, Zenith)),
		.("SkyRotation", offsetof(IblPush, SkyRotation)),
		.("Ground", offsetof(IblPush, Ground)),
		.("Turbidity", offsetof(IblPush, Turbidity)));

	/// probe_prefilter_ps.ps.hlsl's struct Push; its float2 Pad is the mirror's pad0 and pad1.
	private static FieldRow[?] sPrefilterPush = .(
		.("FaceIndex", offsetof(ProbePrefilterPush, FaceIndex)),
		.("Roughness", offsetof(ProbePrefilterPush, Roughness)),
		.("Pad", offsetof(ProbePrefilterPush, Pad0)));

	private static FieldRow[?] sClusterBuildParams = .(
		.("GridX", offsetof(ClusterBuildParams, GridX)),
		.("GridY", offsetof(ClusterBuildParams, GridY)),
		.("SliceCount", offsetof(ClusterBuildParams, SliceCount)),
		.("TileSize", offsetof(ClusterBuildParams, TileSize)),
		.("Near", offsetof(ClusterBuildParams, NearZ)),
		.("Far", offsetof(ClusterBuildParams, FarZ)),
		.("LogScale", offsetof(ClusterBuildParams, LogScale)),
		.("LogBias", offsetof(ClusterBuildParams, LogBias)),
		.("LightCount", offsetof(ClusterBuildParams, LightCount)),
		.("LightOffset", offsetof(ClusterBuildParams, LightOffset)),
		.("Orthographic", offsetof(ClusterBuildParams, Orthographic)),
		.("_pad", offsetof(ClusterBuildParams, Pad0)),
		.("ViewMatrix", offsetof(ClusterBuildParams, ViewMatrix)),
		.("InvProjection", offsetof(ClusterBuildParams, InverseProjection)));

	private static FieldRow[?] sGtaoPush = .(
		.("InvProj", offsetof(GtaoPush, InvProj)),
		.("TexelSize", offsetof(GtaoPush, TexelSize)),
		.("Radius", offsetof(GtaoPush, Radius)),
		.("Intensity", offsetof(GtaoPush, Intensity)),
		.("ProjScaleY", offsetof(GtaoPush, ProjScaleY)),
		.("FrameMod", offsetof(GtaoPush, FrameMod)),
		.("DebugMode", offsetof(GtaoPush, DebugMode)),
		.("Orthographic", offsetof(GtaoPush, Orthographic)));

	private static FieldRow[?] sSsaoPush = .(
		.("InvProj", offsetof(SsaoPush, InvProj)),
		.("TexelSize", offsetof(SsaoPush, TexelSize)),
		.("Jitter", offsetof(SsaoPush, Jitter)),
		.("ProjXX", offsetof(SsaoPush, ProjXX)),
		.("ProjYY", offsetof(SsaoPush, ProjYY)),
		.("Radius", offsetof(SsaoPush, Radius)),
		.("Intensity", offsetof(SsaoPush, Intensity)),
		.("Bias", offsetof(SsaoPush, Bias)),
		.("SampleCount", offsetof(SsaoPush, SampleCount)),
		.("DebugMode", offsetof(SsaoPush, DebugMode)),
		.("Orthographic", offsetof(SsaoPush, Orthographic)),
		.("_pad", offsetof(SsaoPush, Pad)));

	private static FieldRow[?] sAoBlurPush = .(
		.("Dir", offsetof(AoBlurPush, Direction)),
		.("TexelSize", offsetof(AoBlurPush, TexelSize)),
		.("DepthSigma", offsetof(AoBlurPush, DepthSigma)),
		.("_pad0", offsetof(AoBlurPush, Pad0)),
		.("_pad1", offsetof(AoBlurPush, Pad1)),
		.("_pad2", offsetof(AoBlurPush, Pad2)));

	private static FieldRow[?] sAoApplyPush = .(
		.("Strength", offsetof(AoApplyPush, Strength)),
		.("FlipAoY", offsetof(AoApplyPush, FlipAoY)),
		.("_pad1", offsetof(AoApplyPush, Pad1)),
		.("_pad2", offsetof(AoApplyPush, Pad2)));

	private static FieldRow[?] sBloomPush = .(
		.("SrcTexel", offsetof(BloomPush, SrcTexel)),
		.("Threshold", offsetof(BloomPush, Threshold)),
		.("Knee", offsetof(BloomPush, Knee)),
		.("FirstPass", offsetof(BloomPush, FirstPass)),
		.("_pad0", offsetof(BloomPush, Pad0)),
		.("_pad1", offsetof(BloomPush, Pad1)),
		.("_pad2", offsetof(BloomPush, Pad2)));

	private static FieldRow[?] sTaaPush = .(
		.("TexelSize", offsetof(TaaPush, TexelSize)),
		.("BlendFactor", offsetof(TaaPush, BlendFactor)),
		.("HistoryValid", offsetof(TaaPush, HistoryValid)),
		.("VarianceGamma", offsetof(TaaPush, VarianceGamma)),
		.("MotionScale", offsetof(TaaPush, MotionScale)),
		.("NearPlane", offsetof(TaaPush, NearPlane)),
		.("FarPlane", offsetof(TaaPush, FarPlane)),
		.("Orthographic", offsetof(TaaPush, Orthographic)),
		.("_pad0", offsetof(TaaPush, Pad0)),
		.("_pad1", offsetof(TaaPush, Pad1)),
		.("_pad2", offsetof(TaaPush, Pad2)));

	private static FieldRow[?] sSsgiPush = .(
		.("InvProj", offsetof(SsgiPush, InvProj)),
		.("VpMin", offsetof(SsgiPush, VpMin)),
		.("VpSize", offsetof(SsgiPush, VpSize)),
		.("Jitter", offsetof(SsgiPush, Jitter)),
		.("ProjXX", offsetof(SsgiPush, ProjXX)),
		.("ProjYY", offsetof(SsgiPush, ProjYY)),
		.("Thickness", offsetof(SsgiPush, Thickness)),
		.("Radius", offsetof(SsgiPush, Radius)),
		.("MaxSteps", offsetof(SsgiPush, MaxSteps)),
		.("RayCount", offsetof(SsgiPush, RayCount)),
		.("YSign", offsetof(SsgiPush, YSign)),
		.("FrameIndex", offsetof(SsgiPush, FrameIndex)),
		.("MaxRadiance", offsetof(SsgiPush, MaxRadiance)),
		.("_pad0", offsetof(SsgiPush, Pad0)));

	private static FieldRow[?] sSsgiDownPush = .(
		.("SrcTexelSize", offsetof(SsgiDownPush, SrcTexelSize)),
		.("_pad0", offsetof(SsgiDownPush, Pad0)));

	private static FieldRow[?] sSsgiBlurPush = .(
		.("TexelSize", offsetof(SsgiBlurPush, TexelSize)),
		.("DepthSigma", offsetof(SsgiBlurPush, DepthSigma)),
		.("Step", offsetof(SsgiBlurPush, Step)),
		.("InvProj", offsetof(SsgiBlurPush, InvProj)),
		.("VpMin", offsetof(SsgiBlurPush, VpMin)),
		.("VpSize", offsetof(SsgiBlurPush, VpSize)),
		.("YSign", offsetof(SsgiBlurPush, YSign)),
		.("_pad1", offsetof(SsgiBlurPush, Pad1)));

	/// The shader packs ViewToWorld0 to the next 16-byte row; the mirror's pad0 and pad1 fill the gap
	/// and are no members of the shader's block.
	private static FieldRow[?] sSsgiResolvePush = .(
		.("VpMin", offsetof(SsgiResolvePush, VpMin)),
		.("VpSize", offsetof(SsgiResolvePush, VpSize)),
		.("TexelSize", offsetof(SsgiResolvePush, TexelSize)),
		.("BlendFactor", offsetof(SsgiResolvePush, BlendFactor)),
		.("HistoryValid", offsetof(SsgiResolvePush, HistoryValid)),
		.("VarianceGamma", offsetof(SsgiResolvePush, VarianceGamma)),
		.("MotionScale", offsetof(SsgiResolvePush, MotionScale)),
		.("TemporalOn", offsetof(SsgiResolvePush, TemporalOn)),
		.("Debug", offsetof(SsgiResolvePush, Debug)),
		.("OutputAccum", offsetof(SsgiResolvePush, OutputAccum)),
		.("Intensity", offsetof(SsgiResolvePush, Intensity)),
		.("ViewToWorld0", offsetof(SsgiResolvePush, ViewToWorld) + 0),
		.("ViewToWorld1", offsetof(SsgiResolvePush, ViewToWorld) + 16),
		.("ViewToWorld2", offsetof(SsgiResolvePush, ViewToWorld) + 32),
		.("SkyAmbient", offsetof(SsgiResolvePush, SkyAmbient)),
		.("ShSkyDimmer", offsetof(SsgiResolvePush, ShSkyDimmer)));

	private static FieldRow[?] sSsrPush = .(
		.("InvProj", offsetof(SsrPush, InvProj)),
		.("VpMin", offsetof(SsrPush, VpMin)),
		.("VpSize", offsetof(SsrPush, VpSize)),
		.("Jitter", offsetof(SsrPush, Jitter)),
		.("ProjXX", offsetof(SsrPush, ProjXX)),
		.("ProjYY", offsetof(SsrPush, ProjYY)),
		.("Thickness", offsetof(SsrPush, Thickness)),
		.("Intensity", offsetof(SsrPush, Intensity)),
		.("EdgeFade", offsetof(SsrPush, EdgeFade)),
		.("RoughnessCutoff", offsetof(SsrPush, RoughCutoff)),
		.("MaxSteps", offsetof(SsrPush, MaxSteps)),
		.("YSign", offsetof(SsrPush, YSign)),
		.("Debug", offsetof(SsrPush, Debug)),
		.("Glossy", offsetof(SsrPush, Glossy)));

	private static FieldRow[?] sSsrResolvePush = .(
		.("VpMin", offsetof(SsrResolvePush, VpMin)),
		.("VpSize", offsetof(SsrResolvePush, VpSize)),
		.("TexelSize", offsetof(SsrResolvePush, TexelSize)),
		.("BlendFactor", offsetof(SsrResolvePush, BlendFactor)),
		.("HistoryValid", offsetof(SsrResolvePush, HistoryValid)),
		.("VarianceGamma", offsetof(SsrResolvePush, VarianceGamma)),
		.("MotionScale", offsetof(SsrResolvePush, MotionScale)),
		.("TemporalOn", offsetof(SsrResolvePush, TemporalOn)),
		.("Debug", offsetof(SsrResolvePush, Debug)),
		.("GhostReject", offsetof(SsrResolvePush, GhostReject)));

	private static FieldRow[?] sTonemapPush = .(
		.("Exposure", offsetof(TonemapPush, Exposure)),
		.("BloomIntensity", offsetof(TonemapPush, BloomIntensity)),
		.("UvScale", offsetof(TonemapPush, UvScale)),
		.("UvOffset", offsetof(TonemapPush, UvOffset)),
		.("AoStrength", offsetof(TonemapPush, AoStrength)),
		.("DebugShowAo", offsetof(TonemapPush, DebugShowAo)),
		.("Operator", offsetof(TonemapPush, Operator)),
		.("FlipSceneY", offsetof(TonemapPush, FlipSceneY)),
		.("AutoExposure", offsetof(TonemapPush, AutoExposure)),
		.("AutoKey", offsetof(TonemapPush, AutoKey)),
		.("AutoMin", offsetof(TonemapPush, AutoMin)),
		.("AutoMax", offsetof(TonemapPush, AutoMax)),
		.("GradeIntensity", offsetof(TonemapPush, GradeIntensity)),
		.("LutSize", offsetof(TonemapPush, LutSize)),
		.("EncodeOutput", offsetof(TonemapPush, EncodeOutput)),
		.("Rotation", offsetof(TonemapPush, Rotation)),
		.("_tonemapPad0", offsetof(TonemapPush, Pad0)),
		.("_tonemapPad1", offsetof(TonemapPush, Pad1)));

	private static FieldRow[?] sFxaaPush = .(
		.("TexelSize", offsetof(FxaaPush, TexelSize)),
		.("UvScale", offsetof(FxaaPush, UvScale)),
		.("UvOffset", offsetof(FxaaPush, UvOffset)),
		.("SubpixelQuality", offsetof(FxaaPush, SubpixelQuality)),
		.("EdgeThreshold", offsetof(FxaaPush, EdgeThreshold)),
		.("EdgeThresholdMin", offsetof(FxaaPush, EdgeThresholdMin)),
		.("LinearInput", offsetof(FxaaPush, LinearInput)));

	private static FieldRow[?] sExposurePush = .(
		.("UvScale", offsetof(ExposurePush, UvScale)),
		.("UvOffset", offsetof(ExposurePush, UvOffset)),
		.("DtSpeed", offsetof(ExposurePush, DtSpeed)),
		.("HistoryValid", offsetof(ExposurePush, HistoryValid)),
		.("Pad0", offsetof(ExposurePush, Pad0)),
		.("Pad1", offsetof(ExposurePush, Pad1)));

	/// The shader's float2s are the mirror's scalar pairs (uvScaleX and uvScaleY, ...).
	private static FieldRow[?] sDebugBlitPush = .(
		.("UvScale", offsetof(DebugBlitPush, UvScaleX)),
		.("UvOffset", offsetof(DebugBlitPush, UvOffsetX)),
		.("SourceSize", offsetof(DebugBlitPush, SourceWidth)),
		.("RangeMin", offsetof(DebugBlitPush, RangeMin)),
		.("RangeMax", offsetof(DebugBlitPush, RangeMax)),
		.("NearZ", offsetof(DebugBlitPush, NearZ)),
		.("FarZ", offsetof(DebugBlitPush, FarZ)),
		.("Mode", offsetof(DebugBlitPush, Mode)),
		.("_pad", offsetof(DebugBlitPush, Pad)));

	private static FieldRow[?] sDebugGeomPush = .(
		.("ViewProj", offsetof(DebugGeomPush, ViewProj)));

	private static FieldRow[?] sDebugGridPush = .(
		.("ViewProj", offsetof(GridPush, ViewProj)),
		.("OriginExtent", offsetof(GridPush, OriginExtent)),
		.("AxisUSpacing", offsetof(GridPush, AxisUSpacing)),
		.("AxisVBlend", offsetof(GridPush, AxisVBlend)),
		.("CameraFade", offsetof(GridPush, CameraFade)));

	private static FieldRow[?] sDebugScreenPush = .(
		.("InvSize", offsetof(DebugScreenPush, InvSize)),
		.("_pad", offsetof(DebugScreenPush, Pad)));

	private static FieldRow[?] sSpriteView = .(
		.("ViewProj", offsetof(GpuSpriteView, ViewProj)),
		.("View", offsetof(GpuSpriteView, View)));

	private static FieldRow[?] sParticleView = .(
		.("ViewProj", offsetof(Sedulous.Engine.Particles.GpuParticleView, ViewProj)),
		.("View", offsetof(Sedulous.Engine.Particles.GpuParticleView, View)),
		.("ProjZScale", offsetof(Sedulous.Engine.Particles.GpuParticleView, ProjZScale)),
		.("ProjZOffset", offsetof(Sedulous.Engine.Particles.GpuParticleView, ProjZOffset)),
		.("ProjWScale", offsetof(Sedulous.Engine.Particles.GpuParticleView, ProjWScale)),
		.("_particleViewPad0", offsetof(Sedulous.Engine.Particles.GpuParticleView, Pad0)));

	/// TerrainView as terrain.ps.hlsl declares it; terrain.vs.hlsl declares its first four
	/// members and terrain_depth.vs.hlsl its first two (the same rows, a prefix of this table).
	private static FieldRow[?] sTerrainView = .(
		.("ChunkToWorld", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, ChunkToWorld)),
		.("ViewProj", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, ViewProj)),
		.("View", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, View)),
		.("PrevViewProj", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, PrevViewProj)),
		.("CascadeViewProj", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, CascadeViewProj)),
		.("LightDir", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, LightDir)),
		.("_terrainViewPad0", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, Pad0)),
		.("CameraPos", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, CameraPos)),
		.("_terrainViewPad1", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, Pad1)),
		.("Jitter", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, Jitter)),
		.("CascadeSplitFar", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, CascadeSplitFar)),
		.("CascadeTexelSize", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, CascadeTexelSize)),
		.("CascadeCount", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, CascadeCount)),
		.("CascadeLayerBase", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, CascadeLayerBase)),
		.("ShadowNormalBias", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, ShadowNormalBias)),
		.("ShadowDepthBias", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, ShadowDepthBias)),
		.("ShadowFarFade", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, ShadowFarFade)),
		.("ShadowUvYSign", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, ShadowUvYSign)),
		.("HeightBlendContrast", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, HeightBlendContrast)),
		.("HeightMapsBound", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, HeightMapsBound)),
		.("PaletteCount", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, PaletteCount)),
		.("WeightsBound", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, WeightsBound)),
		.("BaseTileScale", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, BaseTileScale)),
		.("BaseBound", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, BaseBound)),
		.("MaskMapsBound", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, MaskMapsBound)),
		.("_terrainViewPad2", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, Pad2)),
		.("_terrainViewPad3", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, Pad3)),
		.("_terrainViewPad4", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, Pad4)),
		.("ShadowStrength", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, ShadowStrength)),
		.("_terrainViewPad5", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, Pad5)),
		.("_terrainViewPad6", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, Pad6)),
		.("_terrainViewPad7", offsetof(Sedulous.Engine.Terrain.GpuTerrainView, Pad7)));

	private static FieldRow[?] sTerrainPickView = .(
		.("ChunkToWorld", offsetof(Sedulous.Engine.Terrain.GpuTerrainPickView, ChunkToWorld)),
		.("ViewProj", offsetof(Sedulous.Engine.Terrain.GpuTerrainPickView, ViewProj)),
		.("PickIndex", offsetof(Sedulous.Engine.Terrain.GpuTerrainPickView, PickIndex)),
		.("PickGeneration", offsetof(Sedulous.Engine.Terrain.GpuTerrainPickView, PickGeneration)),
		.("_pickViewPad0", offsetof(Sedulous.Engine.Terrain.GpuTerrainPickView, Pad0)),
		.("_pickViewPad1", offsetof(Sedulous.Engine.Terrain.GpuTerrainPickView, Pad1)));

	private static FieldRow[?] sTerrainChunk = .(
		.("OriginXZ", offsetof(Sedulous.Engine.Terrain.GpuTerrainChunk, OriginXZ)),
		.("SizeXZ", offsetof(Sedulous.Engine.Terrain.GpuTerrainChunk, SizeXZ)),
		.("TexelBase", offsetof(Sedulous.Engine.Terrain.GpuTerrainChunk, TexelBase)),
		.("TexelSpan", offsetof(Sedulous.Engine.Terrain.GpuTerrainChunk, TexelSpan)),
		.("HeightRange", offsetof(Sedulous.Engine.Terrain.GpuTerrainChunk, HeightRange)),
		.("GridSize", offsetof(Sedulous.Engine.Terrain.GpuTerrainChunk, GridSize)),
		.("Skirt", offsetof(Sedulous.Engine.Terrain.GpuTerrainChunk, Skirt)));

	private static FieldRow[?] sVGUniforms = .(
		.("Projection", offsetof(Sedulous.VG.Renderer.VGUniforms, Projection)),
		.("DistanceFieldPixelRange", offsetof(Sedulous.VG.Renderer.VGUniforms, DistanceFieldPixelRange)),
		.("DistanceFieldAtlasWidth", offsetof(Sedulous.VG.Renderer.VGUniforms, DistanceFieldAtlasWidth)),
		.("DistanceFieldAtlasHeight", offsetof(Sedulous.VG.Renderer.VGUniforms, DistanceFieldAtlasHeight)),
		.("BlendSpace", offsetof(Sedulous.VG.Renderer.VGUniforms, BlendSpace)));

	private static FieldRow[?] sVGBlur = .(
		.("Step", offsetof(Sedulous.VG.Renderer.VGBlurUniforms, Step)),
		.("Region", offsetof(Sedulous.VG.Renderer.VGBlurUniforms, Region)),
		.("Sigma", offsetof(Sedulous.VG.Renderer.VGBlurUniforms, Sigma)),
		.("Radius", offsetof(Sedulous.VG.Renderer.VGBlurUniforms, Radius)),
		.("Unused", offsetof(Sedulous.VG.Renderer.VGBlurUniforms, Unused)));

	/// The engine's shaders cooked once to SPIR-V, as the engine cook does; null without DXC.
	private static CookedShaderPack CookCorpus(ShaderCompiler compiler)
	{
		let dataRoot = FindDataRoot(.. scope String());
		if (dataRoot.IsEmpty)
			return null;
		let shaderDirectory = PathJoin(dataRoot, "Engine/Shaders", .. scope String());
		let scratch = scope String();
		System.IO.Path.GetTempPath(scratch).IgnoreError();
		scratch.Append("sedulous_shader_blocks");
		CookedShaderFormat[1] formats = .(.SpirV);
		var options = ShaderCookOptions();
		options.ShaderDirectory = shaderDirectory;
		options.ScratchDirectory = scratch;
		options.Formats = formats;
		options.ValidateWgsl = false;
		let pack = new CookedShaderPack();
		let report = scope ShaderCookReport();
		ShaderPackCooker.CookEngineShaders(compiler, options, pack, report);
		for (let error in report.Errors)
			Console.WriteLine(error);
		Test.Assert(report.Success, "the engine's shaders cooked clean");
		return pack;
	}

	private static ShaderCompiler MakeCompiler()
	{
		let compiler = new ShaderCompiler();
		if (compiler.Initialize() case .Err)
		{
			delete compiler;
			return null;
		}
		return compiler;
	}

	[Test]
	public static void EveryEngineBlockMatchesItsBeefMirrorMemberByMember()
	{
		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;
		let pack = CookCorpus(compiler);
		defer delete pack;

		void Check(StringView shader, Sedulous.Shaders.ShaderStage stage, ShaderFlags flags, StringView spirvName, Span<FieldRow> fields)
		{
			let at = scope $"{shader} {stage} {flags} {spirvName}";
			let blob = pack.Find(shader, stage, flags, .SpirV);
			Test.Assert(blob case .Ok, scope $"{at}: not in the pack");
			let module = scope SpirvBlocks(blob.Get());
			let members = module.Find(spirvName);
			Test.Assert(members != null, scope $"{at}: no such block");
			Test.Assert(members.Count == fields.Length, scope $"{at}: {members.Count} members in the shader, {fields.Length} in the mirror");
			for (int i < Math.Min(fields.Length, members.Count))
			{
				let field = fields[i];
				let member = members[i];
				Test.Assert(member.Name == field.Name, scope $"{at}: member {i} is {member.Name} in the shader, {field.Name} in the mirror");
				Test.Assert(member.HasOffset, scope $"{at}: {member.Name} has no offset");
				Test.Assert(member.Offset == (uint32)field.Offset, scope $"{at}: {field.Name} at {member.Offset} in the shader, {field.Offset} in the mirror");
			}
		}

		Check("forward", .Fragment, .None, "type.View", sView);
		Check("forward", .Vertex, .None, "type.Object", sObject);
		Check("forward", .Vertex, .Instanced, "InstanceData", sInstance);
		Check("shadow_depth", .Vertex, .None, "type.Object", sObject);
		Check("shadow_depth", .Vertex, .Instanced, "InstanceData", sInstance);
		Check("shadow_depth", .Vertex, .None, "type.ShadowView", sShadowView);
		Check("pick_ids", .Vertex, .None, "type.Object", sObject);
		Check("pick_ids", .Vertex, .Instanced, "InstanceData", sInstance);
		Check("pick_ids", .Vertex, .None, "type.PickView", sPickView);
		Check("forward", .Vertex, .Instanced, "type.InstanceSet", sInstanceSet);
		Check("shadow_depth", .Vertex, .Instanced, "type.InstanceSet", sInstanceSet);
		Check("pick_ids", .Vertex, .Instanced, "type.InstanceSet", sInstanceSet);
		Check("forward", .Fragment, .None, "GpuLight", sGpuLight);
		Check("cluster_build", .Compute, .None, "GpuLight", sGpuLight);
		Check("forward", .Fragment, .None, "GpuLocalShadow", sGpuLocalShadow);
		Check("forward", .Fragment, .None, "GpuProbe", sGpuProbe);
		Check("decal", .Fragment, .None, "type.DecalUniforms", sDecalUniforms);
		Check("phong", .Vertex, .None, "type.Object", sObject);
		Check("phong", .Fragment, .None, "type.View", sView);
		Check("unlit", .Vertex, .None, "type.Object", sObject);
		Check("unlit", .Fragment, .GBuffer, "type.View", sView);
		Check("sky", .Vertex, .None, "type.Sky", sSky);
		Check("sky", .Fragment, .None, "type.Sky", sSky);
		Check("ibl_procenv", .Fragment, .None, "type.ConstantBuffer.IblPush", sIblPush);
		Check("ibl_downsample", .Fragment, .None, "type.ConstantBuffer.IblPush", sIblPush);
		Check("ibl_prefilter", .Fragment, .None, "type.ConstantBuffer.IblPush", sIblPush);
		Check("probe_prefilter_ps", .Fragment, .None, "type.ConstantBuffer.Push", sPrefilterPush);
		Check("cluster_build", .Compute, .None, "type.ClusterBuildParams", sClusterBuildParams);
		Check("ao_gtao", .Fragment, .None, "type.ConstantBuffer.GtaoPush", sGtaoPush);
		Check("ao_ssao", .Fragment, .None, "type.ConstantBuffer.SsaoPush", sSsaoPush);
		Check("ao_blur", .Fragment, .None, "type.ConstantBuffer.BlurPush", sAoBlurPush);
		Check("ao_apply", .Fragment, .None, "type.ConstantBuffer.ApplyPush", sAoApplyPush);
		Check("bloom_ds", .Fragment, .None, "type.ConstantBuffer.BloomPush", sBloomPush);
		Check("bloom_us", .Fragment, .None, "type.ConstantBuffer.BloomPush", sBloomPush);
		Check("taa", .Fragment, .None, "type.ConstantBuffer.TaaPush", sTaaPush);
		Check("ssgi", .Fragment, .None, "type.ConstantBuffer.SsgiPush", sSsgiPush);
		Check("ssgi_down", .Fragment, .None, "type.ConstantBuffer.SsgiDownPush", sSsgiDownPush);
		Check("ssgi_blur", .Fragment, .None, "type.ConstantBuffer.SsgiBlurPush", sSsgiBlurPush);
		Check("ssgi_resolve", .Fragment, .None, "type.ConstantBuffer.SsgiResolvePush", sSsgiResolvePush);
		Check("ssr", .Fragment, .None, "type.ConstantBuffer.SsrPush", sSsrPush);
		Check("ssr_resolve", .Fragment, .None, "type.ConstantBuffer.SsrResolvePush", sSsrResolvePush);
		Check("tonemap", .Fragment, .None, "type.ConstantBuffer.TonemapPush", sTonemapPush);
		Check("fxaa", .Fragment, .None, "type.ConstantBuffer.FxaaPush", sFxaaPush);
		Check("exposure_measure", .Fragment, .None, "type.ConstantBuffer.ExposurePush", sExposurePush);
		Check("debug_blit", .Fragment, .None, "type.ConstantBuffer.DebugBlitPush", sDebugBlitPush);
		Check("debug_geom", .Vertex, .None, "type.ConstantBuffer.GeomPush", sDebugGeomPush);
		Check("debug_grid", .Vertex, .None, "type.ConstantBuffer.GridPush", sDebugGridPush);
		Check("debug_grid", .Fragment, .None, "type.ConstantBuffer.GridPush", sDebugGridPush);
		Check("debug_screen", .Vertex, .None, "type.ConstantBuffer.ScreenPush", sDebugScreenPush);
		Check("sprite", .Vertex, .None, "type.SpriteView", sSpriteView);
		Check("particle", .Vertex, .None, "type.ParticleView", sParticleView);
		Check("particle", .Fragment, .None, "type.ParticleView", sParticleView);
		Check("particletrail", .Vertex, .None, "type.ParticleView", sParticleView);
		Check("terrain", .Fragment, .None, "type.TerrainView", sTerrainView);
		Check("terrain", .Vertex, .None, "type.TerrainView", .(&sTerrainView[0], 4));
		Check("terrain_depth", .Vertex, .None, "type.TerrainView", .(&sTerrainView[0], 2));
		Check("terrain_pick", .Vertex, .None, "type.TerrainPickView", sTerrainPickView);
		Check("terrain", .Vertex, .None, "type.TerrainChunk", sTerrainChunk);
		Check("terrain_depth", .Vertex, .None, "type.TerrainChunk", sTerrainChunk);
		Check("terrain_pick", .Vertex, .None, "type.TerrainChunk", sTerrainChunk);
		Check("vg", .Vertex, .None, "type.VGUniforms", sVGUniforms);
		Check("vg_blur", .Fragment, .None, "type.VGBlur", sVGBlur);
	}

	/// A built-in material's cbuffer Material has no Beef struct: MaterialBuilder lays its uniforms
	/// out by HLSL packing (CreatePbr, CreatePhong, CreateUnlit). Each shader member must be a
	/// uniform property of the same name at the same offset, and each uniform property a shader
	/// member.
	[Test]
	public static void TheBuiltInMaterialsBuffersMatchTheirMaterialBuilderLayouts()
	{
		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;
		let pack = CookCorpus(compiler);
		defer delete pack;

		void Check(StringView shader, Sedulous.Shaders.ShaderStage stage, ShaderFlags flags, Material material)
		{
			defer delete material;
			let at = scope $"{shader} {stage} {flags}";
			let blob = pack.Find(shader, stage, flags, .SpirV);
			Test.Assert(blob case .Ok, scope $"{at}: not in the pack");
			let module = scope SpirvBlocks(blob.Get());
			let members = module.Find("type.Material");
			Test.Assert(members != null, scope $"{at}: no Material block");
			int uniforms = 0;
			for (let property in material.Properties)
			{
				if (property.IsUniform)
					uniforms++;
			}
			// Padding is padding: a member named `_...` holds a place (PBR's former wind lanes)
			// and is no property.
			int named = 0;
			for (let member in members)
			{
				if (!member.Name.StartsWith("_"))
					named++;
			}
			Test.Assert(named == uniforms, scope $"{at}: {named} members in the shader, {uniforms} uniforms in the material");
			for (let member in members)
			{
				if (member.Name.StartsWith("_"))
					continue;
				Test.Assert(material.FindProperty(member.Name, let property), scope $"{at}: {member.Name} is no property");
				Test.Assert(property.IsUniform, scope $"{at}: {member.Name} is not a uniform");
				Test.Assert(member.HasOffset && (property.Offset == member.Offset), scope $"{at}: {member.Name} at {member.Offset} in the shader, {property.Offset} in the material");
			}
		}

		// The vertex stages declare no material buffer: the wind reads its own block (the next
		// test).
		Check("forward", .Fragment, .None, MaterialPresets.CreatePbr("pbr"));
		Check("phong", .Fragment, .None, MaterialPresets.CreatePhong("phong"));
		Check("unlit", .Fragment, .None, MaterialPresets.CreateUnlit("unlit"));
	}

	/// The effect block in wind.hlsli is the one declaration of the wind's parameters: the cook
	/// records its table in the pack, and the material system fills the buffer by that table's
	/// offsets. Every stage that sways must read the same layout.
	[Test]
	public static void EveryWindVertexStagesWindBlockMatchesTheEffectsTable()
	{
		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;
		let pack = CookCorpus(compiler);
		defer delete pack;

		let wind = pack.Effects.ForFlag(.Wind);
		Test.Assert(wind != null, "the pack holds the Wind effect");
		Test.Assert(wind.Name == "Wind");
		Test.Assert((wind.Gate != null) && (wind.Gate.Name == "Strength"));

		let spirvName = scope String("type.ConstantBuffer.");
		ShaderProperties.EffectStructName(wind.Name, spirvName);
		for (let shader in StringView[?]("forward", "phong", "unlit", "shadow_depth", "pick_ids"))
		{
			let blob = pack.Find(shader, .Vertex, .Wind, .SpirV);
			Test.Assert(blob case .Ok, scope $"{shader}: its WIND vertex variant is not in the pack");
			let module = scope SpirvBlocks(blob.Get());
			let members = module.Find(spirvName);
			Test.Assert(members != null, scope $"{shader}: no {spirvName}");
			Test.Assert(members.Count == wind.Properties.Count, scope $"{shader}: {members.Count} members, {wind.Properties.Count} in the table");
			for (int i < Math.Min(members.Count, wind.Properties.Count))
			{
				let member = members[i];
				let property = wind.Properties[i];
				Test.Assert(member.Name == property.Name, scope $"{shader}: member {i} is {member.Name}, the table's {property.Name}");
				Test.Assert(member.HasOffset && (member.Offset == property.Offset), scope $"{shader}: {member.Name} at {member.Offset}, the table's {property.Offset}");
			}
			// Not the material's buffer: no vertex stage declares one for the wind any more.
			Test.Assert(module.Find("type.Material") == null, scope $"{shader}: a Material block in its vertex stage");
		}

		// What each built-in's vertex stage declares, as the Beef table states it (the effects a
		// material on it may carry where no shader system is at hand): its `// variants` line, as
		// the cook read it.
		for (let builtin in MaterialPresets.BuiltinShadings)
		{
			Test.Assert(pack.DeclaredMask(builtin.ShaderName, .Vertex) == builtin.VertexVariants,
				scope $"{builtin.ShaderName}: the pack declares {pack.DeclaredMask(builtin.ShaderName, .Vertex)}, the table {builtin.VertexVariants}");
		}
	}

	/// The engine renderers' mirrors, each its block's size (the render library's own are checked
	/// in Sedulous.Render.Tests).
	[Test]
	public static void TheEngineRenderersMirrorsAreTheirBlocksSizes()
	{
		Test.Assert(sizeof(Sedulous.Engine.Particles.GpuParticleView) == 144);
		Test.Assert(sizeof(Sedulous.Engine.Terrain.GpuTerrainView) == 672); // eight matrices, ten vectors
		Test.Assert(sizeof(Sedulous.Engine.Terrain.GpuTerrainChunk) == 56); // seven pairs
		Test.Assert(sizeof(Sedulous.Engine.Terrain.GpuTerrainPickView) == 144);
	}

	[Test]
	public static void TheReaderFindsABlocksMembersAndOffsetsInCompiledSpirv()
	{
		let compiler = MakeCompiler();
		if (compiler == null) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		defer delete compiler;
		let source = """
			cbuffer Probe : register(b0) { float4 A; float B; float C; float4 D; };
			float4 main() : SV_Target0 { return A * B + D * C; }
			""";
		var result = compiler.Compile(.((uint8*)source.Ptr, source.Length), .Fragment, "main", .SPIRV, .());
		defer result.Dispose();
		Test.Assert(result.Success, result.Messages);

		let module = scope SpirvBlocks(result.Bytecode);
		let members = module.Find("type.Probe");
		Test.Assert(members != null);
		Test.Assert(members.Count == 4);
		Test.Assert((members[0].Name == "A") && (members[0].Offset == 0));
		Test.Assert((members[1].Name == "B") && (members[1].Offset == 16));
		Test.Assert(members[2].Offset == 20);
		Test.Assert((members[3].Name == "D") && (members[3].Offset == 32), "HLSL packing: a float4 does not straddle a 16-byte row");
		Test.Assert(module.Find("type.Missing") == null);
	}
}
