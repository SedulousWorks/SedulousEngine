namespace NuklearSample;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.Shaders;
using Sedulous.Runtime.Client;
using Sedulous.Runtime;
using Nuklear_Beef;

/// Vertex structure matching Nuklear's expected format
[CRepr]
struct NkVertex
{
	public float[2] Position;
	public float[2] TexCoord;
	public uint8[4] Color;
}

/// Uniform buffer for projection matrix
[CRepr]
struct NkUniforms
{
	public Matrix Projection;
}

/// Nuklear integration sample demonstrating immediate-mode GUI with RHI rendering.
class NuklearSampleApp : Application
{
	// Nuklear context and font
	private nk_context mNkContext;
	private nk_font_atlas mFontAtlas;
	private nk_font* mDefaultFont;
	private nk_buffer mCommandBuffer;
	private nk_buffer mVertexBuffer;
	private nk_buffer mIndexBuffer;
	private nk_draw_null_texture mNullTexture;

	// Vertex layout for nk_convert
	private nk_draw_vertex_layout_element[4] mVertexLayout;

	// RHI resources
	private IBuffer mRhiVertexBuffer;
	private IBuffer mRhiIndexBuffer;
	private IBuffer mUniformBuffer;
	private ITexture mFontTexture;
	private ITextureView mFontTextureView;
	private ISampler mFontSampler;
	private ShaderSystem mShaderSystem;
	private IShaderModule mVertShader;
	private IShaderModule mFragShader;
	private IBindGroupLayout mBindGroupLayout;
	private IBindGroup mBindGroup;
	private IPipelineLayout mPipelineLayout;
	private IRenderPipeline mPipeline;

	// Buffer sizes
	private const int MAX_VERTEX_BUFFER = 512 * 1024;
	private const int MAX_INDEX_BUFFER = 128 * 1024;

	// Demo state
	private nk_colorf mBackgroundColor = .() { r = 0.1f, g = 0.18f, b = 0.24f, a = 1.0f };
	private int32 mSliderValue = 50;
	private bool mCheckboxValue = false;
	private int32 mComboSelected = 0;
	private float mPropertyValue = 1.0f;

	public this() : base()
	{
	}

	protected override void OnInitialize(Context context)
	{
		// Initialize shader system
		mShaderSystem = new ShaderSystem();
		String shaderPath = scope .();
		GetAssetPath("samples/NuklearSample/shaders", shaderPath);
		if (mShaderSystem.Initialize(Device, scope StringView[](shaderPath)) case .Err)
		{
			Console.WriteLine("Failed to initialize shader system");
			return;
		}

		// Initialize Nuklear font atlas
		nk_font_atlas_init_default(&mFontAtlas);
		nk_font_atlas_begin(&mFontAtlas);

		// Add default font
		mDefaultFont = nk_font_atlas_add_default(&mFontAtlas, 14, null);

		// Bake font atlas to image
		int32 atlasWidth = 0, atlasHeight = 0;
		void* atlasImage = nk_font_atlas_bake(&mFontAtlas, &atlasWidth, &atlasHeight, .NK_FONT_ATLAS_RGBA32);

		if (atlasImage == null || atlasWidth == 0 || atlasHeight == 0)
		{
			Console.WriteLine("Failed to bake font atlas");
			return;
		}

		// Create font texture
		if (!CreateFontTexture(atlasImage, (uint32)atlasWidth, (uint32)atlasHeight))
			return;

		// Complete font atlas initialization
		nk_handle texHandle = .();
		texHandle.id = 1; // Use a simple ID for the texture
		nk_font_atlas_end(&mFontAtlas, texHandle, &mNullTexture);

		// Initialize Nuklear context with default font
		if (!nk_init_default(&mNkContext, &mDefaultFont.handle))
		{
			Console.WriteLine("Failed to initialize Nuklear context");
			return;
		}

		// Initialize command and vertex/index buffers
		nk_buffer_init_default(&mCommandBuffer);
		nk_buffer_init_default(&mVertexBuffer);
		nk_buffer_init_default(&mIndexBuffer);

		// Setup vertex layout for nk_convert
		mVertexLayout[0] = .() { attribute = .NK_VERTEX_POSITION, format = .NK_FORMAT_FLOAT, offset = 0 };
		mVertexLayout[1] = .() { attribute = .NK_VERTEX_TEXCOORD, format = .NK_FORMAT_FLOAT, offset = 8 };
		mVertexLayout[2] = .() { attribute = .NK_VERTEX_COLOR, format = .NK_FORMAT_R8G8B8A8, offset = 16 };
		mVertexLayout[3] = .() { attribute = .NK_VERTEX_ATTRIBUTE_COUNT, format = .NK_FORMAT_COUNT, offset = 0 };

		// Create RHI resources
		if (!CreateBuffers())
			return;

		if (!CreateBindings())
			return;

		if (!CreatePipeline())
			return;

		Console.WriteLine("Nuklear Sample initialized.");
		Console.WriteLine("  - Mouse: interact with UI");
		Console.WriteLine("  - ESC: Exit");
	}

	private bool CreateFontTexture(void* imageData, uint32 width, uint32 height)
	{
		// Create texture
		TextureDesc texDesc = TextureDesc.Texture2D(
			width,
			height,
			.RGBA8Unorm,
			.Sampled | .CopyDst
		);

		if (Device.CreateTexture(texDesc) not case .Ok(let tex))
		{
			Console.WriteLine("Failed to create font texture");
			return false;
		}
		mFontTexture = tex;

		// Upload texture data
		TextureDataLayout dataLayout = .()
		{
			Offset = 0,
			BytesPerRow = width * 4,
			RowsPerImage = height
		};

		Extent3D writeSize = .(width, height, 1);
		Span<uint8> data = .((uint8*)imageData, (int)(width * height * 4));
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

		Console.WriteLine(scope $"Font texture created: {width}x{height}");
		return true;
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
		mRhiVertexBuffer = vb;

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
		mRhiIndexBuffer = ib;

		// Create uniform buffer
		BufferDesc uniformDesc = .()
		{
			Size = (uint64)sizeof(NkUniforms),
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
		let shaderResult = mShaderSystem.GetShaderPair("nuklear");
		if (shaderResult case .Err)
		{
			Console.WriteLine("Failed to load shaders");
			return false;
		}

		mVertShader = shaderResult.Value.vert.Module;
		mFragShader = shaderResult.Value.frag.Module;
		Console.WriteLine("Shaders compiled");

		// Create bind group layout
		// Use binding 0 for all - the RHI applies shifts based on resource type
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

		// Create bind group - use binding 0 for all resource types
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

	private bool CreatePipeline()
	{
		// Vertex attributes: position (float2), texcoord (float2), color (ubyte4 normalized)
		VertexAttribute[3] vertexAttributes = .(
			.(VertexFormat.Float2, 0, 0),            // Position at location 0
			.(VertexFormat.Float2, 8, 1),            // TexCoord at location 1
			.(VertexFormat.UByte4Normalized, 16, 2)  // Color at location 2
		);
		VertexBufferLayout[1] vertexBuffers = .(
			.((uint64)sizeof(NkVertex), vertexAttributes)
		);

		// Color target with alpha blending
		ColorTargetState[1] colorTargets = .(
			.()
			{
				Format = SwapChain.Format,
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

	protected override void OnInput(FrameContext frame)
	{
		let mouse = mShell.InputManager.Mouse;
		let keyboard = mShell.InputManager.Keyboard;

		// Begin Nuklear input
		nk_input_begin(&mNkContext);

		// Mouse position
		nk_input_motion(&mNkContext, (int32)mouse.X, (int32)mouse.Y);

		// Mouse buttons
		nk_input_button(&mNkContext, .NK_BUTTON_LEFT, (int32)mouse.X, (int32)mouse.Y, mouse.IsButtonDown(.Left));
		nk_input_button(&mNkContext, .NK_BUTTON_MIDDLE, (int32)mouse.X, (int32)mouse.Y, mouse.IsButtonDown(.Middle));
		nk_input_button(&mNkContext, .NK_BUTTON_RIGHT, (int32)mouse.X, (int32)mouse.Y, mouse.IsButtonDown(.Right));

		// Mouse scroll
		if (mouse.ScrollY != 0)
			nk_input_scroll(&mNkContext, .() { x = 0, y = mouse.ScrollY });

		// Keyboard - basic text input support
		// Note: Full keyboard support would require character callback from SDL
		nk_input_key(&mNkContext, .NK_KEY_DEL, keyboard.IsKeyDown(.Delete) );
		nk_input_key(&mNkContext, .NK_KEY_ENTER, keyboard.IsKeyDown(.Return) );
		nk_input_key(&mNkContext, .NK_KEY_TAB, keyboard.IsKeyDown(.Tab) );
		nk_input_key(&mNkContext, .NK_KEY_BACKSPACE, keyboard.IsKeyDown(.Backspace) );
		nk_input_key(&mNkContext, .NK_KEY_LEFT, keyboard.IsKeyDown(.Left) );
		nk_input_key(&mNkContext, .NK_KEY_RIGHT, keyboard.IsKeyDown(.Right) );
		nk_input_key(&mNkContext, .NK_KEY_UP, keyboard.IsKeyDown(.Up) );
		nk_input_key(&mNkContext, .NK_KEY_DOWN, keyboard.IsKeyDown(.Down) );

		// Ctrl shortcuts
		let ctrl = keyboard.IsKeyDown(.LeftCtrl) || keyboard.IsKeyDown(.RightCtrl);
		nk_input_key(&mNkContext, .NK_KEY_COPY, ctrl && keyboard.IsKeyDown(.C) );
		nk_input_key(&mNkContext, .NK_KEY_PASTE, ctrl && keyboard.IsKeyDown(.V) );
		nk_input_key(&mNkContext, .NK_KEY_CUT, ctrl && keyboard.IsKeyDown(.X) );
		nk_input_key(&mNkContext, .NK_KEY_TEXT_UNDO, ctrl && keyboard.IsKeyDown(.Z) );
		nk_input_key(&mNkContext, .NK_KEY_TEXT_REDO, ctrl && keyboard.IsKeyDown(.Y) );
		nk_input_key(&mNkContext, .NK_KEY_TEXT_SELECT_ALL, ctrl && keyboard.IsKeyDown(.A) );

		// End Nuklear input
		nk_input_end(&mNkContext);
	}

	protected override void OnUpdate(FrameContext frame)
	{
		// Build Nuklear UI
		BuildUI();

		// Update background clear color based on UI
		mSettings.ClearColor = Color(mBackgroundColor.r, mBackgroundColor.g, mBackgroundColor.b, 1.0f);
	}

	private void BuildUI()
	{
		// Demo window
		if (nk_begin(&mNkContext, "Nuklear Demo", .() { x = 50, y = 50, w = 300, h = 400 },
			(uint32)(nk_panel_flags.NK_WINDOW_BORDER | .NK_WINDOW_MOVABLE | .NK_WINDOW_SCALABLE | .NK_WINDOW_TITLE | .NK_WINDOW_MINIMIZABLE)))
		{
			// Background color picker
			nk_layout_row_dynamic(&mNkContext, 25, 1);
			nk_label(&mNkContext, "Background Color:", (uint32)nk_text_alignment.NK_TEXT_LEFT);

			nk_layout_row_dynamic(&mNkContext, 120, 1);
			mBackgroundColor = nk_color_picker(&mNkContext, mBackgroundColor, .NK_RGBA);

			// Slider
			nk_layout_row_dynamic(&mNkContext, 25, 1);
			nk_label(&mNkContext, "Slider:", (uint32)nk_text_alignment.NK_TEXT_LEFT);
			nk_layout_row_dynamic(&mNkContext, 25, 1);
			nk_slider_int(&mNkContext, 0, &mSliderValue, 100, 1);

			// Checkbox
			nk_layout_row_dynamic(&mNkContext, 25, 1);
			bool checkVal = mCheckboxValue;
			nk_checkbox_label(&mNkContext, "Enable Feature", &checkVal);
			mCheckboxValue = checkVal;

			// Property
			nk_layout_row_dynamic(&mNkContext, 25, 1);
			nk_property_float(&mNkContext, "Property:", 0.0f, &mPropertyValue, 10.0f, 0.1f, 0.1f);

			// Combo box
			nk_layout_row_dynamic(&mNkContext, 25, 1);
			char8*[3] comboItems = .("Option 1", "Option 2", "Option 3");
			mComboSelected = nk_combo(&mNkContext, &comboItems, 3, mComboSelected, 25, .() { x = 200, y = 200 });

			// Buttons
			nk_layout_row_dynamic(&mNkContext, 30, 2);
			if (nk_button_label(&mNkContext, "Button 1"))
				Console.WriteLine("Button 1 clicked!");
			if (nk_button_label(&mNkContext, "Button 2"))
				Console.WriteLine("Button 2 clicked!");

			// Info text
			nk_layout_row_dynamic(&mNkContext, 50, 1);
			String infoText = scope $"Slider: {mSliderValue}\nProperty: {mPropertyValue:F2}";
			nk_label_wrap(&mNkContext, infoText);
		}
		nk_end(&mNkContext);

		// Second demo window
		if (nk_begin(&mNkContext, "About", .() { x = 400, y = 50, w = 250, h = 150 },
			(uint32)(nk_panel_flags.NK_WINDOW_BORDER | .NK_WINDOW_MOVABLE | .NK_WINDOW_TITLE)))
		{
			nk_layout_row_dynamic(&mNkContext, 25, 1);
			nk_label(&mNkContext, "Nuklear GUI Demo", (uint32)nk_text_alignment.NK_TEXT_CENTERED);
			nk_label(&mNkContext, "Integrated with Sedulous RHI", (uint32)nk_text_alignment.NK_TEXT_CENTERED);
			nk_label(&mNkContext, "Running on Beef!", (uint32)nk_text_alignment.NK_TEXT_CENTERED);
		}
		nk_end(&mNkContext);
	}

	protected override void OnPrepareFrame(FrameContext frame)
	{
		// Update projection matrix
		float width = (float)SwapChain.Width;
		float height = (float)SwapChain.Height;

		Matrix projection = Matrix.CreateOrthographicOffCenter(0, width, height, 0, -1.0f, 1.0f);

		NkUniforms uniforms = .()
		{
			Projection = projection
		};
		Span<uint8> uniformData = .((uint8*)&uniforms, sizeof(NkUniforms));
		TransferHelper.WriteMappedBuffer(mUniformBuffer, 0, uniformData);

		// Convert Nuklear commands to vertex/index data
		ConvertDrawCommands();
	}

	private void ConvertDrawCommands()
	{
		// Clear buffers
		nk_buffer_clear(&mVertexBuffer);
		nk_buffer_clear(&mIndexBuffer);

		// Configure conversion
		nk_convert_config config = .();
		config.vertex_layout = &mVertexLayout;
		config.vertex_size = sizeof(NkVertex);
		config.vertex_alignment = 4;
		config.tex_null = mNullTexture;
		config.circle_segment_count = 22;
		config.curve_segment_count = 22;
		config.arc_segment_count = 22;
		config.global_alpha = 1.0f;
		config.shape_AA = .NK_ANTI_ALIASING_ON;
		config.line_AA = .NK_ANTI_ALIASING_ON;

		// Convert commands
		nk_convert(&mNkContext, &mCommandBuffer, &mVertexBuffer, &mIndexBuffer, &config);

		// Upload vertex data to RHI buffer
		if (mVertexBuffer.size > 0 && mVertexBuffer.size <= MAX_VERTEX_BUFFER)
		{
			void* vertexData = nk_buffer_memory_const(&mVertexBuffer);
			Span<uint8> vertSpan = .((uint8*)vertexData, (int)mVertexBuffer.size);
			TransferHelper.WriteMappedBuffer(mRhiVertexBuffer, 0, vertSpan);
		}

		// Upload index data to RHI buffer
		if (mIndexBuffer.size > 0 && mIndexBuffer.size <= MAX_INDEX_BUFFER)
		{
			void* indexData = nk_buffer_memory_const(&mIndexBuffer);
			Span<uint8> idxSpan = .((uint8*)indexData, (int)mIndexBuffer.size);
			TransferHelper.WriteMappedBuffer(mRhiIndexBuffer, 0, idxSpan);
		}
	}

	protected override void OnRender(IRenderPassEncoder renderPass, FrameContext frame)
	{
		if (mVertexBuffer.size == 0 || mIndexBuffer.size == 0)
			return;

		renderPass.SetPipeline(mPipeline);
		renderPass.SetBindGroup(0, mBindGroup);
		renderPass.SetVertexBuffer(0, mRhiVertexBuffer, 0);
		renderPass.SetIndexBuffer(mRhiIndexBuffer, .UInt16, 0);

		// Iterate draw commands
		uint32 indexOffset = 0;
		nk_draw_command* cmd = nk__draw_begin(&mNkContext, &mCommandBuffer);
		while (cmd != null)
		{
			if (cmd.elem_count > 0)
			{
				// Set scissor rect (clamped to viewport)
				let clipX = Math.Max(0, (int32)cmd.clip_rect.x);
				let clipY = Math.Max(0, (int32)cmd.clip_rect.y);
				let clipW = Math.Min((int32)SwapChain.Width - clipX, (int32)cmd.clip_rect.w);
				let clipH = Math.Min((int32)SwapChain.Height - clipY, (int32)cmd.clip_rect.h);

				if (clipW > 0 && clipH > 0)
				{
					renderPass.SetScissor(clipX, clipY, (uint32)clipW, (uint32)clipH);
					renderPass.DrawIndexed(cmd.elem_count, 1, indexOffset, 0, 0);
				}
			}
			indexOffset += cmd.elem_count;
			cmd = nk__draw_next(cmd, &mCommandBuffer, &mNkContext);
		}

		// Clear Nuklear command buffer for next frame
		nk_clear(&mNkContext);
	}

	protected override void OnShutdown()
	{
		// Clean up Nuklear
		nk_buffer_free(&mCommandBuffer);
		nk_buffer_free(&mVertexBuffer);
		nk_buffer_free(&mIndexBuffer);
		nk_font_atlas_clear(&mFontAtlas);
		nk_free(&mNkContext);

		// Clean up RHI resources
		if (mDevice != null)
		{
			mDevice.DestroyRenderPipeline(ref mPipeline);
			mDevice.DestroyPipelineLayout(ref mPipelineLayout);
			mDevice.DestroyBindGroup(ref mBindGroup);
			mDevice.DestroyBindGroupLayout(ref mBindGroupLayout);
			//mDevice.DestroyShaderModule(ref mFragShader);
			//mDevice.DestroyShaderModule(ref mVertShader);
			mDevice.DestroySampler(ref mFontSampler);
			mDevice.DestroyTextureView(ref mFontTextureView);
			mDevice.DestroyTexture(ref mFontTexture);
			mDevice.DestroyBuffer(ref mUniformBuffer);
			mDevice.DestroyBuffer(ref mRhiIndexBuffer);
			mDevice.DestroyBuffer(ref mRhiVertexBuffer);
		}

		if (mShaderSystem != null) { mShaderSystem.Dispose(); delete mShaderSystem; }
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope NuklearSampleApp();
		return app.Run(.() { Title = "Nuklear Sample", Width = 1024, Height = 768, ClearColor = .(0.1f, 0.18f, 0.24f, 1.0f), EnableDepth = false });
	}
}
