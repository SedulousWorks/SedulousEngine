// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#pragma pack_matrix(row_major)
// variants: HOLES
#include "depth.hlsli"

// Terrain chunk PS. Terrain is always opaque, so it writes the full forward GBUFFER (like unlit.ps):
// SV_Target0 shaded colour, 1 octahedral view-space normal, 2 screen-space motion vector, 3 material
// (roughness/metallic) for SSR. Colour is height-lit: a low-to-high ramp (grass -> rock) modulated by
// a directional term + ambient, then attenuated by the CSM (SampleCSM). Splat-map blending (D2) later.

#define TERRAIN_CASCADE_COUNT 4
cbuffer TerrainView : register(b0, space0) {
    float4x4 ChunkToWorld;
    float4x4 ViewProj;
    float4x4 View;
    float4x4 PrevViewProj;
    float4x4 CascadeViewProj[TERRAIN_CASCADE_COUNT];
    float4   LightDir;   // xyz = direction TO the light (normalized)
    float4   CameraPos;
    float4   Jitter;     // xy = current jitter, zw = previous
    float4   CascadeSplitFar;
    float4   CascadeTexelSize;
    float4   ShadowMeta;   // x = cascade count, y = layer base, z = normal bias, w = depth bias
    float4   ShadowParams; // x = far-fade width, y = uv.y sign, z = heightBlendContrast, w = height maps bound
    float4   SplatParams; // x = palette count, y = weights bound, z = base tile, w = base bound
    float4   SplatParams2; // x = mask maps bound, yzw spare
};

struct PSIn {
    float4 pos      : SV_Position;
    float3 normal   : TEXCOORD0; // world-space
    float  heightT  : TEXCOORD1;
    float4 curClip  : TEXCOORD2;
    float4 prevClip : TEXCOORD3;
    float3 worldPos : TEXCOORD4;
    float2 localXZ  : TEXCOORD5; // terrain-LOCAL XZ (pre-ChunkToWorld) for albedo tiling
    float2 splatUV  : TEXCOORD6; // 0..1 across the terrain footprint (splatmap lookup)
};

#ifdef HOLES
// Terrain holes (Specs/terrain-holes.md, P2): the R8 hole mask over the samples, sampled
// BILINEARLY; a fragment whose mask is above one half is inside the cut. The geometry already
// drops the quads cut at every corner; this shapes the rim between cut and solid samples into a
// smooth iso-line instead of a staircase of whole triangles, at every LOD.
Texture2D    HoleMask    : register(t1, space2);
SamplerState HoleSampler : register(s0, space2);
float HoleCoverage(float2 splatUV) {
    float2 dims;
    HoleMask.GetDimensions(dims.x, dims.y);
    return HoleMask.Sample(HoleSampler, splatUV + 0.5 / max(dims, float2(1.0, 1.0))).r;
}
#endif

// Top-K splat material (set 3): per texel, up to 4 (palette index,
// weight) pairs; the BASE layer owns the remainder (1 - sum). The index map is INTEGER and
// Load-ONLY - filtering palette indices interpolates layer ids into garbage - so the
// splat bilinear is done MANUALLY over the 2x2 texel neighborhood: evaluate the full blend per
// corner, lerp the results. Albedos (base + palette array slices) sample normally (trilinear).
Texture2D<uint4>        IndexMap     : register(t0, space3); // 4 palette indices per texel
Texture2D               WeightMap    : register(t1, space3); // 4 weights per texel (0..1)
Texture2D               BaseAlbedo   : register(t2, space3);
Texture2DArray          PaletteArray : register(t3, space3); // one slice per palette layer
StructuredBuffer<float> TileScales   : register(t4, space3); // [i] = palette layer i's tiling
// Per-layer PBR maps: tangent-space normal + ORM (R=AO G=rough B=metal),
// blended by the SAME top-K weights as albedo. Absent -> a flat / default 1x1 dummy binds.
Texture2D               BaseNormal   : register(t5, space3);
Texture2DArray          NormalArray  : register(t6, space3);
Texture2D               BaseOrm      : register(t7, space3);
Texture2DArray          OrmArray     : register(t8, space3);
// Per-layer HEIGHT/displacement maps: the top-K weights are re-biased
// toward the tallest layer per texel (Mishkinis), .r channel. Absent -> a 1x1 mid-height dummy binds
// AND ShadowParams.w reads 0, so the reweight is skipped and the blend stays linear (byte-identical).
Texture2D               BaseHeight   : register(t9, space3);
Texture2DArray          HeightArray  : register(t10, space3);
// Per-layer COVERAGE/opacity mask: multiplies into a palette layer's weight
// before the base-weight recompute so a sparse layer reveals the base through its gaps. .r channel.
// Absent -> a 1x1 OPAQUE (1.0) dummy binds AND SplatParams2.x reads 0, so the multiply is skipped.
Texture2DArray          MaskArray    : register(t11, space3);
SamplerState            AlbedoSampler : register(s0, space3); // repeat, trilinear

struct PSOutput {
    float4 color    : SV_Target0;
    float2 normal   : SV_Target1; // octahedral view-space normal
    float2 velocity : SV_Target2; // screen-space motion vector (UV delta)
    float2 material : SV_Target3; // R = roughness, G = metallic (for SSR)
};

// CSM cascade depth ARRAY (t1, one layer per cascade) + a comparison sampler (s0) for hardware PCF.
// Same set-0 layout role as the forward's ShadowMap/ShadowSampler.
Texture2DArray         ShadowMap     : register(t1, space0);
SamplerComparisonState ShadowSampler : register(s0, space0);
static const float kTerrainShadowTexel = 1.0 / 1024.0; // 1 / shadow resolution

// One cascade with a normal-offset bias (fading at grazing angles) + 3x3 hardware PCF. 1 = lit.
// Adapted verbatim from forward.ps.hlsl SampleCascade, mapped to terrain's cbuffer fields.
float SampleCascade(int cascade, float3 worldPos, float3 N, float NdotL) {
    float texelWorld = CascadeTexelSize[cascade];
    float3 biasedPos = worldPos + N * (ShadowMeta.z * texelWorld * (1.0 - NdotL));
    float4 lc = mul(float4(biasedPos, 1.0), CascadeViewProj[cascade]);
    if (lc.w <= 0.0) { return 1.0; }
    float3 ndc = lc.xyz / lc.w;
    float2 uv  = float2(ndc.x * 0.5 + 0.5, ndc.y * ShadowParams.y * 0.5 + 0.5);
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) { return 1.0; }
    float compareDepth = BiasTowardViewer(ndc.z, ShadowMeta.w);   // toward the light: fewer false occluders
    float layer = ShadowMeta.y + (float)cascade;
    float sum = 0.0;
    [unroll] for (int y = -1; y <= 1; ++y) {
        [unroll] for (int x = -1; x <= 1; ++x) {
            sum += ShadowMap.SampleCmpLevelZero(
                ShadowSampler, float3(uv + float2(x, y) * kTerrainShadowTexel, layer), compareDepth);
        }
    }
    return sum * (1.0 / 9.0);
}

// Cascaded shadow: pick the cascade by view-space depth, sample, blend the seam, fade at the far edge.
float SampleCSM(float3 worldPos, float3 N, float NdotL, float viewDepth) {
    int count = (int)ShadowMeta.x;
    if (count <= 0) { return 1.0; } // no directional caster this frame -> fully lit

    int cascade = count - 1;
    [unroll] for (int i = 0; i < TERRAIN_CASCADE_COUNT; ++i) {
        if (i < count && viewDepth < CascadeSplitFar[i]) { cascade = i; break; }
    }
    float shadow = SampleCascade(cascade, worldPos, N, NdotL);

    float splitFar  = CascadeSplitFar[cascade];
    float splitNear = (cascade == 0) ? 0.0 : CascadeSplitFar[cascade - 1];
    float blendBand = (splitFar - splitNear) * 0.15;
    if (cascade < count - 1 && viewDepth > splitFar - blendBand) {
        float t = saturate((viewDepth - (splitFar - blendBand)) / max(blendBand, 1e-4));
        shadow = lerp(shadow, SampleCascade(cascade + 1, worldPos, N, NdotL), t);
    }

    float shadowFar = CascadeSplitFar[count - 1];
    float fadeBand  = max(ShadowParams.x, 0.5);
    float farFade   = saturate((shadowFar - viewDepth) / fadeBand);
    return lerp(1.0, shadow, farFade);
}

// Octahedral encode a unit vector -> [-1,1]^2 (matches forward/unlit OctEncode).
float2 OctEncode(float3 n) {
    n /= (abs(n.x) + abs(n.y) + abs(n.z));
    float2 e = n.xy;
    if (n.z < 0.0) {
        e = (1.0 - abs(float2(e.y, e.x))) *
            float2(e.x >= 0.0 ? 1.0 : -1.0, e.y >= 0.0 ? 1.0 : -1.0);
    }
    return e;
}

PSOutput main(PSIn i) {
#ifdef HOLES
    if (HoleCoverage(i.splatUV) > 0.5) { discard; }
#endif
    float3 n = normalize(i.normal);
    float3 sun = normalize(LightDir.xyz);

    float3 base;
    float3 blendedN = float3(0.0, 0.0, 1.0); // tangent-space normal (flat default)
    float3 blendedOrm = float3(1.0, 1.0, 0.0); // AO, roughness, metallic (default material)
    bool hasBase = SplatParams.w >= 0.5;
    bool hasWeights = SplatParams.y >= 0.5 && SplatParams.x >= 0.5;
    // The procedural height/slope colour ramp (grass -> rock). It is BOTH the no-material
    // fallback AND the implicit BASE when no base albedo is assigned: a fresh terrain starts on
    // the ramp, and adding paint layers must composite OVER that same look (not flip the
    // unpainted remainder to the white dummy - the "why did my terrain turn white" confusion).
    const float3 kRampLow  = float3(0.24, 0.40, 0.16); // grass
    const float3 kRampHigh = float3(0.52, 0.50, 0.46); // rock
    float3 rampCol = lerp(kRampLow, kRampHigh, i.heightT);
    rampCol = lerp(kRampHigh * 0.8, rampCol, saturate(n.y)); // steep faces read as exposed rock
    if (hasWeights || hasBase) {
        // Base maps tile in terrain-LOCAL XZ (glued to the surface under move/rotate). These are in
        // UNIFORM control flow, so plain Sample (implicit derivatives) is valid.
        float2 baseUV = i.localXZ / max(SplatParams.z, 1e-3);
        float3 baseCol =
            hasBase ? BaseAlbedo.Sample(AlbedoSampler, baseUV).rgb : rampCol;
        float3 baseNrm = BaseNormal.Sample(AlbedoSampler, baseUV).rgb * 2.0 - 1.0;
        float3 baseOrm = BaseOrm.Sample(AlbedoSampler, baseUV).rgb;
        // Height-blend controls: ShadowParams.w = height maps bound,
        // .z = contrast (soft-skirt width). Both uniform, so branching on heightBound is uniform
        // control flow (safe for SampleGrad derivatives; no-height terrains pay nothing).
        bool  heightBound = ShadowParams.w >= 0.5;
        float contrast    = max(ShadowParams.z, 1e-3);
        float baseH = heightBound ? BaseHeight.Sample(AlbedoSampler, baseUV).r : 0.0;
        bool  maskBound = SplatParams2.x >= 0.5;
        if (hasWeights) {
            // Manual bilinear over the splat texels: Load index+weight at the 4 corners, blend
            // per corner (skip zero-weight slots - the typical texel uses 1-2), lerp the results.
            // Palette taps use SampleGrad with gradients hoisted OUT of the data-dependent
            // branches: WGSL forbids implicit-derivative sampling in non-uniform control flow
            // (grad of localXZ/tile == grad(localXZ)/tile, so the mip selection is identical).
            float2 dxLocal = ddx(i.localXZ);
            float2 dyLocal = ddy(i.localXZ);
            float2 dims;
            WeightMap.GetDimensions(dims.x, dims.y);
            float2 tex = i.splatUV * dims - 0.5;
            float2 f = frac(tex);
            int2 t00 = int2(floor(tex));
            int2 maxT = int2(dims) - int2(1, 1);
            float3 cornerC[4];
            float3 cornerN[4];
            float3 cornerO[4];
            [unroll] for (int cIdx = 0; cIdx < 4; ++cIdx) {
                int2 offs = int2(cIdx & 1, cIdx >> 1);
                int2 texel = clamp(t00 + offs, int2(0, 0), maxT);
                uint4 idx = IndexMap.Load(int3(texel, 0));
                float4 w = WeightMap.Load(int3(texel, 0));
                // Coverage mask: multiply each palette slot's weight by its
                // mask BEFORE the base-weight recompute, so masked-out coverage falls to base. Uniform
                // branch (SplatParams2.x); the freed weight reveals whatever is beneath. Composes with
                // height-blend below, which then reweights the already-masked weights.
                if (maskBound) {
                    // Sample each slot's coverage mask and cut its weight; the REMOVED coverage is
                    // handed to the other PAINTED layers so a sparse layer reveals the layer you
                    // PAINTED beneath it - not the base canvas. Receptivity is CONTINUOUS
                    // (smoothstep on the mask value), not a hard >= 0.999 test: a byte-quantized
                    // photo mask (opaque pixels at 250..254/255) and bilinear-filtered texels near a
                    // hole must still receive, and a step would draw a hard ring along its
                    // iso-contour. Heavily-cut areas of a layer receive ~nothing, so a mask still
                    // cuts its own layer. The redistributed share also fades out (the /kRecvKnee
                    // saturate) as the receiver pool vanishes, instead of amplifying a vanishing
                    // slot to full coverage; whatever is not redistributed falls to base via the
                    // baseW recompute below (sparse-over-base -> reveal base, unchanged).
                    float freed = 0.0;
                    float recvSum = 0.0;
                    float recv[4];
                    [unroll] for (int mk = 0; mk < 4; ++mk) {
                        recv[mk] = 0.0;
                        if (w[mk] > 0.0) {
                            uint mLayer = idx[mk];
                            float mTile = max(TileScales[mLayer], 1e-3);
                            float3 mUv = float3(i.localXZ / mTile, (float)mLayer);
                            float mval = MaskArray.SampleGrad(AlbedoSampler, mUv,
                                                              dxLocal / mTile, dyLocal / mTile).r;
                            freed += w[mk] * (1.0 - mval);
                            w[mk] *= mval;
                            recv[mk] = w[mk] * smoothstep(0.75, 0.95, mval);
                            recvSum += recv[mk];
                        }
                    }
                    if (freed > 0.0 && recvSum > 1e-5) {
                        const float kRecvKnee = 0.05; // receiver pool below this redistributes less
                        float share = freed * saturate(recvSum / kRecvKnee);
                        [unroll] for (int rk = 0; rk < 4; ++rk) {
                            w[rk] += share * (recv[rk] / recvSum);
                        }
                    }
                }
                float baseW = saturate(1.0 - (w.x + w.y + w.z + w.w));
                float3 c, nTS, orm;
                if (!heightBound) {
                    // LINEAR blend (OFF path) - byte-identical to pre-height-blend: base gets the
                    // remainder weight, each active palette slot gets its raw weight.
                    c = baseCol * baseW;
                    nTS = baseNrm * baseW;
                    orm = baseOrm * baseW;
                    [unroll] for (int k = 0; k < 4; ++k) {
                        float wk = w[k];
                        if (wk > 0.0) {
                            uint layer = idx[k];
                            float tile = max(TileScales[layer], 1e-3);
                            float3 uvk = float3(i.localXZ / tile, (float)layer);
                            float2 gx = dxLocal / tile;
                            float2 gy = dyLocal / tile;
                            c += PaletteArray.SampleGrad(AlbedoSampler, uvk, gx, gy).rgb * wk;
                            nTS += (NormalArray.SampleGrad(AlbedoSampler, uvk, gx, gy).rgb * 2.0 - 1.0) * wk;
                            orm += OrmArray.SampleGrad(AlbedoSampler, uvk, gx, gy).rgb * wk;
                        }
                    }
                } else {
                    // HEIGHT-BLEND (Mishkinis): sample each active slot's maps once, then re-bias the
                    // weights toward the tallest contributor with a soft skirt of width `contrast`,
                    // renormalize (stays convex), and combine albedo/normal/ORM with the new weights.
                    float3 slotC[4], slotN[4]; float3 slotO[4]; float slotH[4];
                    [unroll] for (int k = 0; k < 4; ++k) {
                        slotC[k] = float3(0.0, 0.0, 0.0);
                        slotN[k] = float3(0.0, 0.0, 0.0);
                        slotO[k] = float3(0.0, 0.0, 0.0);
                        slotH[k] = 0.0;
                        if (w[k] > 0.0) {
                            uint layer = idx[k];
                            float tile = max(TileScales[layer], 1e-3);
                            float3 uvk = float3(i.localXZ / tile, (float)layer);
                            float2 gx = dxLocal / tile;
                            float2 gy = dyLocal / tile;
                            slotC[k] = PaletteArray.SampleGrad(AlbedoSampler, uvk, gx, gy).rgb;
                            slotN[k] = NormalArray.SampleGrad(AlbedoSampler, uvk, gx, gy).rgb * 2.0 - 1.0;
                            slotO[k] = OrmArray.SampleGrad(AlbedoSampler, uvk, gx, gy).rgb;
                            slotH[k] = HeightArray.SampleGrad(AlbedoSampler, uvk, gx, gy).r;
                        }
                    }
                    // Scores = weight + height; the base competes only when it has remainder weight.
                    float sBase = (baseW > 0.0) ? (baseW + baseH) : -1e30;
                    float sMax = sBase;
                    float sK[4];
                    [unroll] for (int k = 0; k < 4; ++k) {
                        sK[k] = (w[k] > 0.0) ? (w[k] + slotH[k]) : -1e30;
                        sMax = max(sMax, sK[k]);
                    }
                    float lo = sMax - contrast; // contributors below this are culled (skirt width)
                    float bBase = (baseW > 0.0) ? max(sBase - lo, 0.0) : 0.0;
                    float sum = bBase;
                    float bK[4];
                    [unroll] for (int k = 0; k < 4; ++k) {
                        bK[k] = (w[k] > 0.0) ? max(sK[k] - lo, 0.0) : 0.0;
                        sum += bK[k];
                    }
                    float inv = 1.0 / max(sum, 1e-6); // the max contributor survives, so sum >= contrast
                    float ewBase = bBase * inv;
                    c = baseCol * ewBase;
                    nTS = baseNrm * ewBase;
                    orm = baseOrm * ewBase;
                    [unroll] for (int k = 0; k < 4; ++k) {
                        float ew = bK[k] * inv;
                        c += slotC[k] * ew;
                        nTS += slotN[k] * ew;
                        orm += slotO[k] * ew;
                    }
                }
                cornerC[cIdx] = c;
                cornerN[cIdx] = nTS;
                cornerO[cIdx] = orm;
            }
            base = lerp(lerp(cornerC[0], cornerC[1], f.x), lerp(cornerC[2], cornerC[3], f.x), f.y);
            blendedN = lerp(lerp(cornerN[0], cornerN[1], f.x), lerp(cornerN[2], cornerN[3], f.x), f.y);
            blendedOrm = lerp(lerp(cornerO[0], cornerO[1], f.x), lerp(cornerO[2], cornerO[3], f.x), f.y);
        } else {
            base = baseCol; // no weights authored: pure base everywhere
            blendedN = baseNrm;
            blendedOrm = baseOrm;
        }
    } else {
        base = rampCol; // no material at all -> the ramp (headless tools, layerless terrains)
    }

    // Perturb the shading normal by the blended tangent-space normal. The frame is analytic in the
    // CHUNK frame: the tiling UV is terrain-LOCAL XZ, so the map's U axis is
    // local +X rotated to world by ChunkToWorld (world +X would shear on a rotated terrain).
    float3 axisU = normalize(mul(float4(1.0, 0.0, 0.0, 0.0), ChunkToWorld).xyz);
    float3 T = normalize(axisU - n * dot(axisU, n));
    float3 B = cross(n, T);
    float3 N = normalize(blendedN.x * T + blendedN.y * B + blendedN.z * n);
    float ndlN = saturate(dot(N, sun));
    float ao = blendedOrm.r;

    // CSM: attenuate only the DIRECT (sun) term; ambient is indirect (AO-modulated). The shadow bias
    // uses the stable geometric normal n (perturbed N would add acne from high-frequency detail).
    float viewDepth = -mul(float4(i.worldPos, 1.0), View).z;
    float shadow = SampleCSM(i.worldPos, n, ndlN, viewDepth);

    const float3 ambient = float3(0.28, 0.30, 0.34);
    float3 lit = base * (ambient * ao + ndlN * shadow);

    // GBuffer motion vector: current vs previous NDC (unjittered), NDC.y flipped vs UV.y.
    float2 curNDC  = i.curClip.xy  / i.curClip.w  + Jitter.xy;
    float2 prevNDC = i.prevClip.xy / i.prevClip.w + Jitter.zw;

    PSOutput o;
    o.color    = float4(lit, 1.0);
    o.normal   = OctEncode(normalize(mul(float4(N, 0.0), View).xyz));
    o.velocity = (curNDC - prevNDC) * float2(0.5, -0.5);
    o.material = float2(blendedOrm.g, blendedOrm.b); // roughness, metallic
    return o;
}
