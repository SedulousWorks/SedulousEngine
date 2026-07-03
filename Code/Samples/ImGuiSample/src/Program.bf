namespace ImGuiSample;

using System;
using System.IO;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.Shaders;
using Sedulous.Runtime.Client;
using Sedulous.RuntimeGraphics;
using cimgui_Beef;
using RuntimeSampleFramework;

/// Uniform buffer for projection matrix
[CRepr]
struct ImGuiUniforms
{
	public Matrix Projection;
}

/// ImGui integration sample demonstrating immediate-mode GUI with RHI rendering.
class ImGuiSampleApp : RuntimeSampleApp
{
	// ImGui context
	private ImGuiContext* mImGuiContext;
	private ImGuiIO* mIO;

	// RHI resources
	private IBuffer mVertexBuffer;
	private IBuffer mIndexBuffer;
	private IBuffer mUniformBuffer;
	private ITexture mFontTexture;
	private ITextureView mFontTextureView;
	private ISampler mFontSampler;
	private IShaderModule mVertShader;
	private IShaderModule mFragShader;
	private IBindGroupLayout mBindGroupLayout;
	private IBindGroup mBindGroup;
	private IPipelineLayout mPipelineLayout;
	private IRenderPipeline mPipeline;

	// Sample's own shader system (uses sample-specific shader path)
	private ShaderSystem mSampleShaderSystem;

	// Buffer sizes
	private const int MAX_VERTEX_BUFFER = 512 * 1024;
	private const int MAX_INDEX_BUFFER = 128 * 1024;

	// Cached draw data for rendering
	private int32 mTotalVtxCount;
	private int32 mTotalIdxCount;

	// Font texture ID used to identify our font texture
	private const uint64 FONT_TEXTURE_ID = 1;

	// Demo state
	private float[4] mBackgroundColor = .(0.1f, 0.18f, 0.24f, 1.0f);
	private int32 mSliderValue = 50;
	private bool mCheckboxValue = false;
	private int32 mComboSelected = 0;
	private float mPropertyValue = 1.0f;
	private bool mFirstFrame = true;

	// Cached delta time for input
	private float mDeltaTime = 1.0f / 60.0f;

	public override ApplicationSettings Settings()
	{
		return .() { Title = "ImGui Sample", Width = 1024, Height = 768 };
	}

	protected override void OnInit(Sedulous.Runtime.Client.IApplicationHost host)
	{
		let rw = host.MainWindow;

		// Initialize shader system
		mSampleShaderSystem = new ShaderSystem();
		String shaderPath = scope .();
		Path.InternalCombine(shaderPath, BuiltInAssetDirectory, "samples/ImGuiSample/shaders");
		if (mSampleShaderSystem.Initialize(Device, scope StringView[](shaderPath)) case .Err)
		{
			Console.WriteLine("Failed to initialize shader system");
			return;
		}

		// Create ImGui context
		mImGuiContext = igCreateContext(null);
		mIO = igGetIO_Nil();

		// Configure IO
		mIO.ConfigFlags |= (.)ImGuiConfigFlags.ImGuiConfigFlags_DockingEnable;
		mIO.BackendFlags |= (.)ImGuiBackendFlags.ImGuiBackendFlags_RendererHasTextures;
		mIO.DisplaySize = .() { x = (float)rw.Swap.Width, y = (float)rw.Swap.Height };
		mIO.DeltaTime = 1.0f / 60.0f;

		// Disable ini file saving for sample
		mIO.IniFilename = null;

		// Set atlas format to RGBA32 for our renderer
		mIO.Fonts.TexDesiredFormat = .ImTextureFormat_RGBA32;

		// Add default font
		ImFontAtlas_AddFontDefault(mIO.Fonts, null);

		// Create RHI resources (buffers, shaders, pipeline)
		if (!CreateBuffers())
			return;

		if (!CreateBindings())
			return;

		if (!CreatePipeline(rw.Swap.Format))
			return;

		Console.WriteLine("ImGui Sample initialized.");
		Console.WriteLine("  - Mouse: interact with UI");
		Console.WriteLine("  - ESC: Exit");
	}

	private bool CreateBuffers()
	{
		// Create vertex buffer
		BufferDesc vertexDesc = .()
		{
			Size = MAX_VERTEX_BUFFER,
			Usage = .Vertex,
			Memory = .CpuToGpu
		};

		if (Device.CreateBuffer(vertexDesc) not case .Ok(let vb))
		{
			Console.WriteLine("Failed to create vertex buffer");
			return false;
		}
		mVertexBuffer = vb;

		// Create index buffer
		BufferDesc indexDesc = .()
		{
			Size = MAX_INDEX_BUFFER,
			Usage = .Index,
			Memory = .CpuToGpu
		};

		if (Device.CreateBuffer(indexDesc) not case .Ok(let ib))
		{
			Console.WriteLine("Failed to create index buffer");
			return false;
		}
		mIndexBuffer = ib;

		// Create uniform buffer
		BufferDesc uniformDesc = .()
		{
			Size = (uint64)sizeof(ImGuiUniforms),
			Usage = .Uniform,
			Memory = .CpuToGpu
		};

		if (Device.CreateBuffer(uniformDesc) not case .Ok(let ub))
		{
			Console.WriteLine("Failed to create uniform buffer");
			return false;
		}
		mUniformBuffer = ub;

		Console.WriteLine("Buffers created");
		return true;
	}

	private bool CreateBindings()
	{
		// Load shaders
		let shaderResult = mSampleShaderSystem.GetShaderPair("imgui");
		if (shaderResult case .Err)
		{
			Console.WriteLine("Failed to load shaders");
			return false;
		}

		mVertShader = shaderResult.Value.vert.Module;
		mFragShader = shaderResult.Value.frag.Module;
		Console.WriteLine("Shaders compiled");

		// Create bind group layout
		BindGroupLayoutEntry[3] layoutEntries = .(
			BindGroupLayoutEntry.UniformBuffer(0, .Vertex),
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment)
		);
		BindGroupLayoutDesc bindGroupLayoutDesc = .(layoutEntries);
		if (Device.CreateBindGroupLayout(bindGroupLayoutDesc) not case .Ok(let layout))
		{
			Console.WriteLine("Failed to create bind group layout");
			return false;
		}
		mBindGroupLayout = layout;

		// Create pipeline layout
		IBindGroupLayout[1] layouts = .(mBindGroupLayout);
		PipelineLayoutDesc pipelineLayoutDesc = .(layouts);
		if (Device.CreatePipelineLayout(pipelineLayoutDesc) not case .Ok(let pipelineLayout))
		{
			Console.WriteLine("Failed to create pipeline layout");
			return false;
		}
		mPipelineLayout = pipelineLayout;

		Console.WriteLine("Bindings created");
		return true;
	}

	private bool CreatePipeline(TextureFormat swapFormat)
	{
		// ImDrawVert: float2 pos (0), float2 uv (8), uint32 col (16) = 20 bytes
		VertexAttribute[3] vertexAttributes = .(
			.(VertexFormat.Float2, 0, 0),            // Position at location 0
			.(VertexFormat.Float2, 8, 1),            // TexCoord at location 1
			.(VertexFormat.UByte4Normalized, 16, 2)  // Color at location 2
		);
		VertexBufferLayout[1] vertexBuffers = .(
			.((uint64)sizeof(ImDrawVert), vertexAttributes)
		);

		// Color target with alpha blending
		ColorTargetState[1] colorTargets = .(
			.()
			{
				Format = swapFormat,
				Blend = .()
				{
					Color = .()
					{
						SrcFactor = .SrcAlpha,
						DstFactor = .OneMinusSrcAlpha,
						Operation = .Add
					},
					Alpha = .()
					{
						SrcFactor = .One,
						DstFactor = .OneMinusSrcAlpha,
						Operation = .Add
					}
				},
				WriteMask = .All
			}
		);

		// Pipeline descriptor
		RenderPipelineDesc pipelineDesc = .()
		{
			Layout = mPipelineLayout,
			Vertex = .()
			{
				Shader = .(mVertShader, "main"),
				Buffers = vertexBuffers
			},
			Fragment = .()
			{
				Shader = .(mFragShader, "main"),
				Targets = colorTargets
			},
			Primitive = .()
			{
				Topology = .TriangleList,
				FrontFace = .CCW,
				CullMode = .None
			},
			DepthStencil = null,
			Multisample = .()
			{
				Count = 1,
				Mask = uint32.MaxValue,
				AlphaToCoverageEnabled = false
			}
		};

		if (Device.CreateRenderPipeline(pipelineDesc) not case .Ok(let pipeline))
		{
			Console.WriteLine("Failed to create pipeline");
			return false;
		}
		mPipeline = pipeline;

		Console.WriteLine("Pipeline created");
		return true;
	}

	/// Create or update GPU font texture from ImTextureData
	private bool HandleTextureUpdate(ImTextureData* tex)
	{
		if (tex.Status == .ImTextureStatus_WantCreate)
		{
			void* pixels = ImTextureData_GetPixels(tex);
			if (pixels == null)
				return false;

			// Delete previous texture resources if any
			if (mFontSampler != null) { delete mFontSampler; mFontSampler = null; }
			if (mFontTextureView != null) Device.DestroyTextureView(ref mFontTextureView);
			if (mFontTexture != null) Device.DestroyTexture(ref mFontTexture);
			if (mBindGroup != null) Device.DestroyBindGroup(ref mBindGroup);

			uint32 w = (uint32)tex.Width;
			uint32 h = (uint32)tex.Height;

			// Create texture
			TextureDesc texDesc = TextureDesc.Texture2D(w, h, .RGBA8Unorm, .Sampled | .CopyDst);
			if (Device.CreateTexture(texDesc) not case .Ok(let gpuTex))
			{
				Console.WriteLine("Failed to create font texture");
				return false;
			}
			mFontTexture = gpuTex;

			// Upload texture data
			TextureDataLayout dataLayout = .()
			{
				Offset = 0,
				BytesPerRow = w * 4,
				RowsPerImage = h
			};
			Extent3D writeSize = .(w, h, 1);
			Span<uint8> data = .((uint8*)pixels, (int)(w * h * 4));
			TransferHelper.WriteTextureSync(Device.GetQueue(.Graphics), Device, mFontTexture, data, dataLayout, writeSize);

			// Create texture view
			TextureViewDesc viewDesc = .();
			if (Device.CreateTextureView(mFontTexture, viewDesc) not case .Ok(let view))
			{
				Console.WriteLine("Failed to create font texture view");
				return false;
			}
			mFontTextureView = view;

			// Create sampler
			SamplerDesc samplerDesc = .()
			{
				AddressU = .ClampToEdge,
				AddressV = .ClampToEdge,
				AddressW = .ClampToEdge,
				MagFilter = .Linear,
				MinFilter = .Linear,
				MipmapFilter = .Linear,
				MinLod = 0.0f,
				MaxLod = 1.0f
			};
			if (Device.CreateSampler(samplerDesc) not case .Ok(let sampler))
			{
				Console.WriteLine("Failed to create font sampler");
				return false;
			}
			mFontSampler = sampler;

			// Create bind group
			BindGroupEntry[3] bindGroupEntries = .(
				BindGroupEntry.Buffer(mUniformBuffer, 0, 0),
				BindGroupEntry.Texture(mFontTextureView),
				BindGroupEntry.Sampler(mFontSampler)
			);
			BindGroupDesc bindGroupDesc = .(mBindGroupLayout, bindGroupEntries);
			if (Device.CreateBindGroup(bindGroupDesc) not case .Ok(let group))
			{
				Console.WriteLine("Failed to create bind group");
				return false;
			}
			mBindGroup = group;

			// Mark texture as created
			ImTextureData_SetTexID(tex, FONT_TEXTURE_ID);
			ImTextureData_SetStatus(tex, .ImTextureStatus_OK);

			Console.WriteLine(scope $"Font texture created: {w}x{h}");
		}
		else if (tex.Status == .ImTextureStatus_WantUpdates)
		{
			// For partial updates, re-upload the entire texture (simple approach)
			if (mFontTexture != null && tex.Width > 0 && tex.Height > 0)
			{
				void* pixels = ImTextureData_GetPixels(tex);
				if (pixels != null)
				{
					uint32 w = (uint32)tex.Width;
					uint32 h = (uint32)tex.Height;
					TextureDataLayout dataLayout = .()
					{
						Offset = 0,
						BytesPerRow = w * 4,
						RowsPerImage = h
					};
					Extent3D writeSize = .(w, h, 1);
					Span<uint8> data = .((uint8*)pixels, (int)(w * h * 4));
					TransferHelper.WriteTextureSync(Device.GetQueue(.Graphics), Device, mFontTexture, data, dataLayout, writeSize);
				}
			}
			ImTextureData_SetStatus(tex, .ImTextureStatus_OK);
		}
		else if (tex.Status == .ImTextureStatus_WantDestroy)
		{
			ImTextureData_SetTexID(tex, 0);
			ImTextureData_SetStatus(tex, .ImTextureStatus_Destroyed);
		}

		return true;
	}

	protected override void OnUpdate(Sedulous.Runtime.Client.IApplicationHost host, float deltaTime, float totalTime)
	{
		mDeltaTime = deltaTime;

		let mouse = Shell.InputManager.Mouse;
		let keyboard = Shell.InputManager.Keyboard;

		let rw = host.MainWindow;

		// Update display size
		mIO.DisplaySize = .() { x = (float)rw.Swap.Width, y = (float)rw.Swap.Height };
		mIO.DeltaTime = mDeltaTime > 0 ? mDeltaTime : 1.0f / 60.0f;

		// Mouse
		ImGuiIO_AddMousePosEvent(mIO, mouse.X, mouse.Y);
		ImGuiIO_AddMouseButtonEvent(mIO, 0, mouse.IsButtonDown(.Left));
		ImGuiIO_AddMouseButtonEvent(mIO, 1, mouse.IsButtonDown(.Right));
		ImGuiIO_AddMouseButtonEvent(mIO, 2, mouse.IsButtonDown(.Middle));
		if (mouse.ScrollY != 0)
			ImGuiIO_AddMouseWheelEvent(mIO, 0, mouse.ScrollY);

		// Keyboard - modifier keys
		ImGuiIO_AddKeyEvent(mIO, .ImGuiMod_Ctrl, keyboard.IsKeyDown(.LeftCtrl) || keyboard.IsKeyDown(.RightCtrl));
		ImGuiIO_AddKeyEvent(mIO, .ImGuiMod_Shift, keyboard.IsKeyDown(.LeftShift) || keyboard.IsKeyDown(.RightShift));
		ImGuiIO_AddKeyEvent(mIO, .ImGuiMod_Alt, keyboard.IsKeyDown(.LeftAlt) || keyboard.IsKeyDown(.RightAlt));

		// Navigation keys
		ImGuiIO_AddKeyEvent(mIO, .ImGuiKey_Tab, keyboard.IsKeyDown(.Tab));
		ImGuiIO_AddKeyEvent(mIO, .ImGuiKey_LeftArrow, keyboard.IsKeyDown(.Left));
		ImGuiIO_AddKeyEvent(mIO, .ImGuiKey_RightArrow, keyboard.IsKeyDown(.Right));
		ImGuiIO_AddKeyEvent(mIO, .ImGuiKey_UpArrow, keyboard.IsKeyDown(.Up));
		ImGuiIO_AddKeyEvent(mIO, .ImGuiKey_DownArrow, keyboard.IsKeyDown(.Down));
		ImGuiIO_AddKeyEvent(mIO, .ImGuiKey_Delete, keyboard.IsKeyDown(.Delete));
		ImGuiIO_AddKeyEvent(mIO, .ImGuiKey_Backspace, keyboard.IsKeyDown(.Backspace));
		ImGuiIO_AddKeyEvent(mIO, .ImGuiKey_Enter, keyboard.IsKeyDown(.Return));
		ImGuiIO_AddKeyEvent(mIO, .ImGuiKey_Escape, keyboard.IsKeyDown(.Escape));

		// Letter keys for shortcuts
		ImGuiIO_AddKeyEvent(mIO, .ImGuiKey_A, keyboard.IsKeyDown(.A));
		ImGuiIO_AddKeyEvent(mIO, .ImGuiKey_C, keyboard.IsKeyDown(.C));
		ImGuiIO_AddKeyEvent(mIO, .ImGuiKey_V, keyboard.IsKeyDown(.V));
		ImGuiIO_AddKeyEvent(mIO, .ImGuiKey_X, keyboard.IsKeyDown(.X));
		ImGuiIO_AddKeyEvent(mIO, .ImGuiKey_Y, keyboard.IsKeyDown(.Y));
		ImGuiIO_AddKeyEvent(mIO, .ImGuiKey_Z, keyboard.IsKeyDown(.Z));

		// Start new ImGui frame
		igNewFrame();

		// Build UI
		BuildUI();
	}

	private void BuildUI()
	{
		// Set initial window positions on first frame
		if (mFirstFrame)
		{
			igSetNextWindowPos(.() { x = 50, y = 50 }, (.)ImGuiCond.ImGuiCond_FirstUseEver, .() { x = 0, y = 0 });
			igSetNextWindowSize(.() { x = 300, y = 400 }, (.)ImGuiCond.ImGuiCond_FirstUseEver);
		}

		// Demo window
		if (igBegin("ImGui Demo", null, 0))
		{
			// Background color picker
			igText("Background Color:");
			igColorEdit4("##bg", &mBackgroundColor[0], 0);

			igSpacing();
			igSeparator();
			igSpacing();

			// Slider
			igText("Slider:");
			igSliderInt("##slider", &mSliderValue, 0, 100, "%d", 0);

			igSpacing();

			// Checkbox
			igCheckbox("Enable Feature", &mCheckboxValue);

			igSpacing();

			// Property (drag float)
			igDragFloat("Property", &mPropertyValue, 0.1f, 0.0f, 10.0f, "%.2f", 0);

			igSpacing();

			// Combo box
			igCombo_Str("Options", &mComboSelected, "Option 1\0Option 2\0Option 3\0\0", -1);

			igSpacing();
			igSeparator();
			igSpacing();

			// Buttons
			if (igButton("Button 1", .() { x = 0, y = 0 }))
				Console.WriteLine("Button 1 clicked!");
			igSameLine(0, -1);
			if (igButton("Button 2", .() { x = 0, y = 0 }))
				Console.WriteLine("Button 2 clicked!");

			igSpacing();
			igSeparator();
			igSpacing();

			// Info text
			igText(scope $"Slider: {mSliderValue}");
			igText(scope $"Property: {mPropertyValue:F2}");
		}
		igEnd();

		// Second demo window
		if (mFirstFrame)
		{
			igSetNextWindowPos(.() { x = 400, y = 50 }, (.)ImGuiCond.ImGuiCond_FirstUseEver, .() { x = 0, y = 0 });
			igSetNextWindowSize(.() { x = 250, y = 150 }, (.)ImGuiCond.ImGuiCond_FirstUseEver);
		}

		if (igBegin("About", null, 0))
		{
			igText("ImGui Demo");
			igText("Integrated with Sedulous RHI");
			igText("Running on Beef!");
		}
		igEnd();

		mFirstFrame = false;
	}

	protected override void OnRender(Sedulous.Runtime.Client.IApplicationHost host, ref Sedulous.RuntimeGraphics.FrameContext frame)
	{
		// End ImGui frame and generate draw data
		igRender();

		ImDrawData* drawData = igGetDrawData();
		if (drawData == null || !drawData.Valid)
			return;

		// Handle texture creation/updates
		if (drawData.Textures != null)
		{
			let texList = drawData.Textures;
			for (int32 i = 0; i < texList.Size; i++)
			{
				ImTextureData* tex = texList.Data[i];
				if (tex != null && tex.Status != .ImTextureStatus_OK && tex.Status != .ImTextureStatus_Destroyed)
					HandleTextureUpdate(tex);
			}
		}

		// Update projection matrix
		float width = drawData.DisplaySize.x;
		float height = drawData.DisplaySize.y;
		if (width <= 0 || height <= 0)
			return;

		Matrix projection = Matrix.CreateOrthographicOffCenter(0, width, height, 0, -1.0f, 1.0f);

		ImGuiUniforms uniforms = .() { Projection = projection };
		Span<uint8> uniformData = .((uint8*)&uniforms, sizeof(ImGuiUniforms));
		TransferHelper.WriteMappedBuffer(mUniformBuffer, 0, uniformData);

		// Upload combined vertex/index data from all draw lists
		mTotalVtxCount = drawData.TotalVtxCount;
		mTotalIdxCount = drawData.TotalIdxCount;

		if (mTotalVtxCount == 0 || mTotalIdxCount == 0)
			return;

		// Upload vertex data
		uint64 vtxOffset = 0;
		uint64 idxOffset = 0;
		for (int32 n = 0; n < drawData.CmdListsCount; n++)
		{
			ImDrawList* cmdList = drawData.CmdLists.Data[n];
			int vtxSize = cmdList.VtxBuffer.Size * sizeof(ImDrawVert);
			int idxSize = cmdList.IdxBuffer.Size * sizeof(uint16);

			if (vtxOffset + (uint64)vtxSize <= MAX_VERTEX_BUFFER)
			{
				Span<uint8> vtxSpan = .((uint8*)cmdList.VtxBuffer.Data, vtxSize);
				TransferHelper.WriteMappedBuffer(mVertexBuffer, vtxOffset, vtxSpan);
			}

			if (idxOffset + (uint64)idxSize <= MAX_INDEX_BUFFER)
			{
				Span<uint8> idxSpan = .((uint8*)cmdList.IdxBuffer.Data, idxSize);
				TransferHelper.WriteMappedBuffer(mIndexBuffer, idxOffset, idxSpan);
			}

			vtxOffset += (uint64)vtxSize;
			idxOffset += (uint64)idxSize;
		}

		// Begin render pass
		let rp = frame.BeginBackbufferPass(ClearColor(mBackgroundColor[0], mBackgroundColor[1], mBackgroundColor[2], mBackgroundColor[3]));
		if (rp != null && mTotalVtxCount > 0 && mBindGroup != null)
		{
			rp.SetViewport(0, 0, (float)frame.Width, (float)frame.Height, 0, 1);
			rp.SetScissor(0, 0, frame.Width, frame.Height);
			rp.SetPipeline(mPipeline);
			rp.SetBindGroup(0, mBindGroup);
			rp.SetVertexBuffer(0, mVertexBuffer, 0);
			rp.SetIndexBuffer(mIndexBuffer, .UInt16, 0);

			// Iterate draw lists and commands
			int32 globalVtxOffset = 0;
			int32 globalIdxOffset = 0;

			ImVec2 clipOff = drawData.DisplayPos;

			for (int32 n = 0; n < drawData.CmdListsCount; n++)
			{
				ImDrawList* cmdList = drawData.CmdLists.Data[n];

				for (int32 cmdIdx = 0; cmdIdx < cmdList.CmdBuffer.Size; cmdIdx++)
				{
					ImDrawCmd* cmd = &cmdList.CmdBuffer.Data[cmdIdx];

					if (cmd.ElemCount == 0)
						continue;

					// Apply scissor/clipping rectangle
					let clipX = Math.Max(0, (int32)(cmd.ClipRect.x - clipOff.x));
					let clipY = Math.Max(0, (int32)(cmd.ClipRect.y - clipOff.y));
					let clipW = (int32)(cmd.ClipRect.z - cmd.ClipRect.x);
					let clipH = (int32)(cmd.ClipRect.w - cmd.ClipRect.y);

					if (clipW > 0 && clipH > 0)
					{
						rp.SetScissor(clipX, clipY, (uint32)clipW, (uint32)clipH);
						rp.DrawIndexed(cmd.ElemCount, 1,
							(uint32)(cmd.IdxOffset + (uint32)globalIdxOffset),
							(int32)(cmd.VtxOffset + (uint32)globalVtxOffset), 0);
					}
				}

				globalVtxOffset += cmdList.VtxBuffer.Size;
				globalIdxOffset += cmdList.IdxBuffer.Size;
			}
		}
		frame.EndBackbufferPass();
	}

	protected override void OnCleanup(Sedulous.Runtime.Client.IApplicationHost host)
	{
		// Clean up ImGui
		if (mImGuiContext != null)
			igDestroyContext(mImGuiContext);

		// Clean up RHI resources
		if (Device != null)
		{
			Device.DestroyRenderPipeline(ref mPipeline);
			Device.DestroyPipelineLayout(ref mPipelineLayout);
			Device.DestroyBindGroup(ref mBindGroup);
			Device.DestroyBindGroupLayout(ref mBindGroupLayout);
			//Device.DestroyShaderModule(ref mFragShader);
			//Device.DestroyShaderModule(ref mVertShader);
			Device.DestroySampler(ref mFontSampler);
			Device.DestroyTextureView(ref mFontTextureView);
			Device.DestroyTexture(ref mFontTexture);
			Device.DestroyBuffer(ref mUniformBuffer);
			Device.DestroyBuffer(ref mIndexBuffer);
			Device.DestroyBuffer(ref mVertexBuffer);
		}

		if (mSampleShaderSystem != null) { mSampleShaderSystem.Dispose(); delete mSampleShaderSystem; }
	}
}

class Program
{
	public static int Main(String[] args)
	{
		return RuntimeSampleApp.Run<ImGuiSampleApp>();
	}
}
