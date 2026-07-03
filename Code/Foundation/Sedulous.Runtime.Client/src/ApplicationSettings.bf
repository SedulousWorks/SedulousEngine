using Sedulous.RHI;
using System;

namespace Sedulous.Runtime.Client;

struct ApplicationSettings
{
	public StringView Title = "Sedulous Application";
	public int32 Width = 1280;
	public int32 Height = 720;
	public bool Resizable = true;
	public TextureFormat SwapChainFormat = .BGRA8UnormSrgb;
	public PresentMode PresentMode = .Mailbox;
	public bool EnableShaderCache = false;
	public float FixedTimeStep = 1.0f / 60.0f;
	public float MaxFrameTime = 0.25f;
}
