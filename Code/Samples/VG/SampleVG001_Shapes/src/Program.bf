namespace SampleVG001_Shapes;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Core.Mathematics;
using Sedulous.VG;
using Sedulous.VG.SVG;
using SampleFramework;

class VGShapesSample : SampleApp
{
	// VG shader: 2D orthographic projection with per-vertex color and coverage-based AA
	const String cShaderSource = """
		cbuffer Uniforms : register(b0, space0)
		{
		    row_major float4x4 Projection;
		};

		struct VSInput
		{
		    float2 Position : TEXCOORD0;
		    float2 TexCoord : TEXCOORD1;
		    float4 Color    : TEXCOORD2;
		    float  Coverage : TEXCOORD3;
		};

		struct PSInput
		{
		    float4 Position : SV_POSITION;
		    float2 TexCoord : TEXCOORD0;
		    float4 Color    : TEXCOORD1;
		    float  Coverage : TEXCOORD2;
		};

		PSInput VSMain(VSInput input)
		{
		    PSInput output;
		    output.Position = mul(float4(input.Position, 0.0, 1.0), Projection);
		    output.TexCoord = input.TexCoord;
		    output.Color = input.Color;
		    output.Coverage = input.Coverage;
		    return output;
		}

		float4 PSMain(PSInput input) : SV_TARGET
		{
		    float4 col = input.Color;
		    col.a *= input.Coverage;
		    return col;
		}
		""";

	private ShaderCompiler mShaderCompiler;
	private IShaderModule mVertexShader;
	private IShaderModule mPixelShader;
	private IBuffer mVertexBuffer;
	private IBuffer mIndexBuffer;
	private IBuffer mUniformBuffer;
	private IBindGroupLayout mBindGroupLayout;
	private IBindGroup mBindGroup;
	private IPipelineLayout mPipelineLayout;
	private IRenderPipeline mPipeline;
	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;

	private VGContext mVGContext ~ delete _;

	// Current buffer capacities
	private int mVertexCapacity;
	private int mIndexCapacity;

	public this() : base(.Vulkan, true)
	{
	}

	protected override StringView Title => "SampleVG001 — Vector Graphics Shapes";

	protected override Result<void> OnInit()
	{
		// Init shader compiler
		mShaderCompiler = new ShaderCompiler();
		if (mShaderCompiler.Init() case .Err)
		{
			Console.WriteLine("ERROR: ShaderCompiler.Init failed");
			return .Err;
		}

		let format = (mBackendType == .Vulkan) ? ShaderOutputFormat.SPIRV : ShaderOutputFormat.DXIL;

		// Compile shaders
		let vsBytecode = scope List<uint8>();
		let psBytecode = scope List<uint8>();
		let errors = scope String();

		if (mShaderCompiler.CompileVertex(cShaderSource, "VSMain", format, vsBytecode, errors) case .Err)
		{
			Console.WriteLine("VS compile failed: {}", errors);
			return .Err;
		}
		errors.Clear();
		if (mShaderCompiler.CompilePixel(cShaderSource, "PSMain", format, psBytecode, errors) case .Err)
		{
			Console.WriteLine("PS compile failed: {}", errors);
			return .Err;
		}

		// Create shader modules
		let vsResult = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(vsBytecode.Ptr, vsBytecode.Count), Label = "VG_VS" });
		if (vsResult case .Err) { Console.WriteLine("ERROR: CreateShaderModule (VS) failed"); return .Err; }
		mVertexShader = vsResult.Value;

		let psResult = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(psBytecode.Ptr, psBytecode.Count), Label = "VG_PS" });
		if (psResult case .Err) { Console.WriteLine("ERROR: CreateShaderModule (PS) failed"); return .Err; }
		mPixelShader = psResult.Value;

		// Create uniform buffer (4x4 matrix = 64 bytes)
		let ubResult = mDevice.CreateBuffer(BufferDesc()
		{
			Size = 64,
			Usage = .Uniform | .CopyDst,
			Memory = .CpuToGpu,
			Label = "VG_Uniforms"
		});
		if (ubResult case .Err) { Console.WriteLine("ERROR: CreateBuffer (UB) failed"); return .Err; }
		mUniformBuffer = ubResult.Value;

		// Create bind group layout
		let bglEntries = scope BindGroupLayoutEntry[1];
		bglEntries[0] = BindGroupLayoutEntry()
		{
			Binding = 0,
			Visibility = .Vertex,
			Type = .UniformBuffer
		};
		let bglResult = mDevice.CreateBindGroupLayout(BindGroupLayoutDesc()
		{
			Entries = Span<BindGroupLayoutEntry>(bglEntries),
			Label = "VG_BGL"
		});
		if (bglResult case .Err) { Console.WriteLine("ERROR: CreateBindGroupLayout failed"); return .Err; }
		mBindGroupLayout = bglResult.Value;

		// Create bind group (entries are positional, matching layout order)
		let bgEntries = scope BindGroupEntry[1];
		bgEntries[0] = BindGroupEntry()
		{
			Buffer = mUniformBuffer,
			BufferOffset = 0,
			BufferSize = 64
		};
		let bgResult = mDevice.CreateBindGroup(BindGroupDesc()
		{
			Layout = mBindGroupLayout,
			Entries = Span<BindGroupEntry>(bgEntries),
			Label = "VG_BG"
		});
		if (bgResult case .Err) { Console.WriteLine("ERROR: CreateBindGroup failed"); return .Err; }
		mBindGroup = bgResult.Value;

		// Create pipeline layout
		let bglSpan = scope IBindGroupLayout[1];
		bglSpan[0] = mBindGroupLayout;
		let plResult = mDevice.CreatePipelineLayout(PipelineLayoutDesc()
		{
			BindGroupLayouts = Span<IBindGroupLayout>(bglSpan),
			Label = "VG_PL"
		});
		if (plResult case .Err) { Console.WriteLine("ERROR: CreatePipelineLayout failed"); return .Err; }
		mPipelineLayout = plResult.Value;

		// Create render pipeline with VGVertex layout
		let vertexAttribs = scope VertexAttribute[4];
		vertexAttribs[0] = VertexAttribute() { ShaderLocation = 0, Format = .Float32x2, Offset = 0 };   // Position
		vertexAttribs[1] = VertexAttribute() { ShaderLocation = 1, Format = .Float32x2, Offset = 8 };   // TexCoord
		vertexAttribs[2] = VertexAttribute() { ShaderLocation = 2, Format = .Unorm8x4,  Offset = 16 };  // Color (packed RGBA)
		vertexAttribs[3] = VertexAttribute() { ShaderLocation = 3, Format = .Float32,    Offset = 20 };  // Coverage

		let vertexLayouts = scope VertexBufferLayout[1];
		vertexLayouts[0] = VertexBufferLayout()
		{
			Stride = (uint32)VGVertex.SizeInBytes,
			StepMode = .Vertex,
			Attributes = Span<VertexAttribute>(vertexAttribs)
		};

		let colorTargets = scope ColorTargetState[1];
		colorTargets[0] = ColorTargetState()
		{
			Format = mSwapChain.Format,
			WriteMask = .All,
			Blend = BlendState()
			{
				Color = BlendComponent()
				{
					SrcFactor = .SrcAlpha,
					DstFactor = .OneMinusSrcAlpha,
					Operation = .Add
				},
				Alpha = BlendComponent()
				{
					SrcFactor = .One,
					DstFactor = .OneMinusSrcAlpha,
					Operation = .Add
				}
			}
		};

		let rpDesc = RenderPipelineDesc()
		{
			Layout = mPipelineLayout,
			Vertex = .() { Shader = .(mVertexShader, "VSMain"), Buffers = vertexLayouts },
			Fragment = .() { Shader = .(mPixelShader, "PSMain"), Targets = colorTargets },
			Primitive = PrimitiveState() { Topology = .TriangleList },
			Label = "VG_Pipeline"
		};

		let pipResult = mDevice.CreateRenderPipeline(rpDesc);
		if (pipResult case .Err) { Console.WriteLine("ERROR: CreateRenderPipeline failed"); return .Err; }
		mPipeline = pipResult.Value;

		// Create command pool and fence
		let poolResult = mDevice.CreateCommandPool(.Graphics);
		if (poolResult case .Err) { Console.WriteLine("ERROR: CreateCommandPool failed"); return .Err; }
		mCommandPool = poolResult.Value;

		let fenceResult = mDevice.CreateFence(0);
		if (fenceResult case .Err) { Console.WriteLine("ERROR: CreateFence failed"); return .Err; }
		mFrameFence = fenceResult.Value;
		mFrameFenceValue = 0;

		// Create VG context
		mVGContext = new VGContext();

		return .Ok;
	}

	protected override void OnRender()
	{
		if (mFrameFenceValue > 0)
			mFrameFence.Wait(mFrameFenceValue);

		if (mSwapChain.AcquireNextImage() case .Err) return;

		// Build VG scene
		mVGContext.Clear();
		BuildScene();

		let batch = mVGContext.GetBatch();
		if (batch.IsEmpty)
			return;

		// Update projection matrix (2D orthographic)
		UpdateProjection();

		// Ensure GPU buffers are large enough
		EnsureBuffers(batch.VertexCount, batch.IndexCount);

		// Upload vertex/index data
		UploadBatchData(batch);

		// Render
		mCommandPool.Reset();
		let encoderResult = mCommandPool.CreateEncoder();
		if (encoderResult case .Err) return;
		var encoder = encoderResult.Value;

		// Barrier: Present → RenderTarget
		let texBarriers = scope TextureBarrier[1];
		texBarriers[0] = TextureBarrier()
		{
			Texture = mSwapChain.CurrentTexture,
			OldState = .Present,
			NewState = .RenderTarget
		};
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		// Begin render pass
		let colorAttachments = scope ColorAttachment[1];
		colorAttachments[0] = ColorAttachment()
		{
			View = mSwapChain.CurrentTextureView,
			LoadOp = .Clear,
			StoreOp = .Store,
			ClearValue = ClearColor(0.12f, 0.12f, 0.14f, 1.0f)
		};

		let rp = encoder.BeginRenderPass(RenderPassDesc()
		{
			ColorAttachments = .(colorAttachments)
		});

		rp.SetPipeline(mPipeline);
		rp.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0.0f, 1.0f);
		rp.SetScissor(0, 0, mWidth, mHeight);
		rp.SetBindGroup(0, mBindGroup);
		rp.SetVertexBuffer(0, mVertexBuffer, 0);
		rp.SetIndexBuffer(mIndexBuffer, .UInt32, 0);

		// Draw all VG commands
		for (int i = 0; i < batch.CommandCount; i++)
		{
			let cmd = batch.GetCommand(i);
			if (cmd.IndexCount > 0)
				rp.DrawIndexed((uint32)cmd.IndexCount, 1, (uint32)cmd.StartIndex, 0, 0);
		}

		rp.End();

		// Barrier: RenderTarget → Present
		texBarriers[0].OldState = .RenderTarget;
		texBarriers[0].NewState = .Present;
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		var cmdBuf = encoder.Finish();
		mFrameFenceValue++;
		mGraphicsQueue.Submit(Span<ICommandBuffer>(&cmdBuf, 1), mFrameFence, mFrameFenceValue);
		mSwapChain.Present(mGraphicsQueue);
		mCommandPool.DestroyEncoder(ref encoder);
	}

	private void BuildScene()
	{
		let w = (float)mWidth;
		let h = (float)mHeight;

		// --- Row 1: Basic filled shapes ---

		// Solid rectangle
		mVGContext.FillRect(.(20, 20, 120, 80), Color.CornflowerBlue);

		// Rounded rectangle with uniform radius
		mVGContext.FillRoundedRect(.(160, 20, 120, 80), 12, Color.Coral);

		// Rounded rectangle with per-corner radii
		mVGContext.FillRoundedRect(.(300, 20, 120, 80), .(0, 20, 0, 20), Color.MediumSeaGreen);

		// Filled circle
		mVGContext.FillCircle(.(500, 60), 40, Color.Gold);

		// Filled ellipse
		mVGContext.FillEllipse(.(620, 60), 50, 35, Color.MediumPurple);

		// --- Row 2: Stroked shapes ---

		// Stroked rectangle
		mVGContext.StrokeRect(.(20, 130, 120, 80), Color.White, 2.0f);

		// Stroked rounded rect
		mVGContext.StrokeRoundedRect(.(160, 130, 120, 80), 12, Color.LightCoral, 2.0f);

		// Stroked circle
		mVGContext.StrokeCircle(.(360, 170), 40, Color.LightSkyBlue, 2.5f);

		// --- Row 3: Polygons and stars ---

		// Pentagon
		mVGContext.FillRegularPolygon(.(80, 290), 40, 5, Color.Tomato);

		// Hexagon
		mVGContext.FillRegularPolygon(.(200, 290), 40, 6, Color.DodgerBlue);

		// Octagon
		mVGContext.FillRegularPolygon(.(320, 290), 40, 8, Color.MediumOrchid);

		// 5-point star
		mVGContext.FillStar(.(460, 290), 45, 20, 5, Color.Gold);

		// 6-point star
		mVGContext.FillStar(.(600, 290), 45, 25, 6, Color.OrangeRed);

		// --- Row 4: Path drawing with curves ---

		// Custom cubic Bezier path
		{
			let pb = scope PathBuilder();
			pb.MoveTo(20, 380);
			pb.CubicTo(60, 340, 100, 420, 140, 380);
			pb.CubicTo(180, 340, 220, 420, 260, 380);
			let path = pb.ToPath();
			defer delete path;

			mVGContext.StrokePath(path, Color.LimeGreen, .(3.0f, .Round, .Round));
		}

		// Quadratic Bezier wave
		{
			let pb = scope PathBuilder();
			pb.MoveTo(280, 400);
			pb.QuadTo(320, 350, 360, 400);
			pb.QuadTo(400, 450, 440, 400);
			pb.QuadTo(480, 350, 520, 400);
			let path = pb.ToPath();
			defer delete path;

			mVGContext.StrokePath(path, Color.HotPink, .(2.5f, .Butt, .Miter));
		}

		// --- Row 5: Gradient fills ---

		// Linear gradient rectangle
		{
			let fill = scope VGLinearGradientFill(.(20, 440), .(240, 440));
			fill.AddStop(0, Color.Red);
			fill.AddStop(0.5f, Color.Yellow);
			fill.AddStop(1, Color.Blue);

			let pb = scope PathBuilder();
			pb.MoveTo(20, 440);
			pb.LineTo(240, 440);
			pb.LineTo(240, 520);
			pb.LineTo(20, 520);
			pb.Close();
			let path = pb.ToPath();
			defer delete path;

			mVGContext.FillPath(path, fill);
		}

		// Radial gradient circle
		{
			let fill = scope VGRadialGradientFill(.(340, 480), 50);
			fill.AddStop(0, Color.White);
			fill.AddStop(0.6f, Color.CornflowerBlue);
			fill.AddStop(1, Color(0, 0, 80));

			let pb = scope PathBuilder();
			ShapeBuilder.BuildCircle(.(340, 480), 50, pb);
			let path = pb.ToPath();
			defer delete path;

			mVGContext.FillPath(path, fill);
		}

		// --- Row 6: SVG path icon ---
		{
			let pb = scope PathBuilder();
			// Heart icon
			if (SVGPathParser.Parse(
				"M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z",
				pb) case .Ok)
			{
				let path = pb.ToPath();
				defer delete path;

				// Scale and position the heart
				mVGContext.PushState();
				mVGContext.Translate(460, 440);
				mVGContext.Scale(5, 5);
				mVGContext.Translate(-12, -12);
				mVGContext.FillPath(path, Color.Crimson);
				mVGContext.PopState();
			}
		}

		// --- Row 6 continued: Transform demo ---
		{
			mVGContext.PushState();
			mVGContext.Translate(680, 480);

			// Rotating squares
			for (int i = 0; i < 6; i++)
			{
				let angle = (float)i * Math.PI_f / 6.0f + mTotalTime * 0.5f;
				let alpha = (uint8)(255 - i * 35);

				mVGContext.PushState();
				mVGContext.Rotate(angle);
				mVGContext.FillRoundedRect(.(-30, -30, 60, 60), 6, Color(100, 180, 255, alpha));
				mVGContext.PopState();
			}

			mVGContext.PopState();
		}

		// --- Labels (column headers as stroked rectangles with fills) ---
		// Top-left: title area
		mVGContext.StrokeRect(.(0, 0, w, h), Color(60, 60, 60), 1.0f);
	}

	private void UpdateProjection()
	{
		// Orthographic projection: (0,0) top-left, (width,height) bottom-right
		let w = (float)mWidth;
		let h = (float)mHeight;

		// Column-major 4x4 ortho matrix
		float[16] proj = .(
			2.0f / w,  0,         0, 0,
			0,        -2.0f / h,  0, 0,
			0,         0,         1, 0,
			-1.0f,     1.0f,      0, 1
		);

		let mapped = mUniformBuffer.Map();
		if (mapped != null)
		{
			Internal.MemCpy(mapped, &proj, 64);
			mUniformBuffer.Unmap();
		}
	}

	private void EnsureBuffers(int vertexCount, int indexCount)
	{
		if (mVertexBuffer == null || vertexCount > mVertexCapacity)
		{
			if (mVertexBuffer != null)
				mDevice.DestroyBuffer(ref mVertexBuffer);

			mVertexCapacity = Math.Max(vertexCount, 4096);
			let size = (uint64)(mVertexCapacity * VGVertex.SizeInBytes);
			let result = mDevice.CreateBuffer(BufferDesc()
			{
				Size = size,
				Usage = .Vertex | .CopyDst,
				Memory = .CpuToGpu,
				Label = "VG_VB"
			});
			if (result case .Ok(let buf))
				mVertexBuffer = buf;
		}

		if (mIndexBuffer == null || indexCount > mIndexCapacity)
		{
			if (mIndexBuffer != null)
				mDevice.DestroyBuffer(ref mIndexBuffer);

			mIndexCapacity = Math.Max(indexCount, 8192);
			let size = (uint64)(mIndexCapacity * 4);
			let result = mDevice.CreateBuffer(BufferDesc()
			{
				Size = size,
				Usage = .Index | .CopyDst,
				Memory = .CpuToGpu,
				Label = "VG_IB"
			});
			if (result case .Ok(let buf))
				mIndexBuffer = buf;
		}
	}

	private void UploadBatchData(VGBatch batch)
	{
		let vertexData = batch.GetVertexData();
		let indexData = batch.GetIndexData();

		if (vertexData.Length > 0)
		{
			let mapped = mVertexBuffer.Map();
			if (mapped != null)
			{
				Internal.MemCpy(mapped, vertexData.Ptr, vertexData.Length * VGVertex.SizeInBytes);
				mVertexBuffer.Unmap();
			}
		}

		if (indexData.Length > 0)
		{
			let mapped = mIndexBuffer.Map();
			if (mapped != null)
			{
				Internal.MemCpy(mapped, indexData.Ptr, indexData.Length * 4);
				mIndexBuffer.Unmap();
			}
		}
	}

	protected override void OnShutdown()
	{
		if (mFrameFence != null)
			mDevice?.DestroyFence(ref mFrameFence);
		if (mCommandPool != null)
			mDevice?.DestroyCommandPool(ref mCommandPool);
		if (mPipeline != null)
			mDevice?.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null)
			mDevice?.DestroyPipelineLayout(ref mPipelineLayout);
		if (mBindGroup != null)
			mDevice?.DestroyBindGroup(ref mBindGroup);
		if (mBindGroupLayout != null)
			mDevice?.DestroyBindGroupLayout(ref mBindGroupLayout);
		if (mIndexBuffer != null)
			mDevice?.DestroyBuffer(ref mIndexBuffer);
		if (mVertexBuffer != null)
			mDevice?.DestroyBuffer(ref mVertexBuffer);
		if (mUniformBuffer != null)
			mDevice?.DestroyBuffer(ref mUniformBuffer);
		if (mPixelShader != null)
			mDevice?.DestroyShaderModule(ref mPixelShader);
		if (mVertexShader != null)
			mDevice?.DestroyShaderModule(ref mVertexShader);
		if (mShaderCompiler != null)
		{
			mShaderCompiler.Destroy();
			delete mShaderCompiler;
		}
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope VGShapesSample();
		return app.Run();
	}
}
