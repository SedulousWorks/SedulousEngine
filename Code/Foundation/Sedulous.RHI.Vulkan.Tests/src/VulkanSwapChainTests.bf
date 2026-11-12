using System;
using Sedulous.Core;
using Sedulous.RHI;
using Bulkan;
using Sedulous.RHI.Vulkan;

namespace Sedulous.RHI.Vulkan.Tests;

/// The swapchain's surface format and its alternate view, from what a surface offers. A
/// desktop's surface offers BGRA formats, an Android phone's RGBA only; asked for BGRA sRGB, a
/// phone must still get an sRGB format, and its UNORM view to match. Pure; no device.
class VulkanSwapChainTests
{
	private static VkSurfaceFormatKHR Offered(VkFormat format)
	{
		VkSurfaceFormatKHR offered = .();
		offered.format = format;
		offered.colorSpace = .VK_COLOR_SPACE_SRGB_NONLINEAR_KHR;
		return offered;
	}

	[Test]
	public static void TheFormatAskedForIsTakenWhenTheSurfaceOffersIt()
	{
		var offered = VkSurfaceFormatKHR[2](Offered(.VK_FORMAT_B8G8R8A8_UNORM), Offered(.VK_FORMAT_B8G8R8A8_SRGB));
		Test.Assert(VulkanSwapChain.ChooseSurfaceFormat(.(&offered[0], offered.Count), .VK_FORMAT_B8G8R8A8_SRGB).format == .VK_FORMAT_B8G8R8A8_SRGB);
	}

	/// A surface like an Android phone's: RGBA formats, UNORM first.
	[Test]
	public static void ASurfaceWithRgbaFormatsOnlyGivesAnSrgbOneForABgraSrgbRequest()
	{
		var offered = VkSurfaceFormatKHR[3](Offered(.VK_FORMAT_R8G8B8A8_UNORM), Offered(.VK_FORMAT_R8G8B8A8_SRGB),
			Offered(.VK_FORMAT_R5G6B5_UNORM_PACK16));
		let chosen = VulkanSwapChain.ChooseSurfaceFormat(.(&offered[0], offered.Count), .VK_FORMAT_B8G8R8A8_SRGB);
		Test.Assert(chosen.format == .VK_FORMAT_R8G8B8A8_SRGB);
		Test.Assert(chosen.colorSpace == .VK_COLOR_SPACE_SRGB_NONLINEAR_KHR);
	}

	[Test]
	public static void WithNoSrgbFormatOfferedAnEightBitUnormOneElseTheFirst()
	{
		var unorm = VkSurfaceFormatKHR[2](Offered(.VK_FORMAT_R5G6B5_UNORM_PACK16), Offered(.VK_FORMAT_R8G8B8A8_UNORM));
		Test.Assert(VulkanSwapChain.ChooseSurfaceFormat(.(&unorm[0], unorm.Count), .VK_FORMAT_B8G8R8A8_SRGB).format == .VK_FORMAT_R8G8B8A8_UNORM);
		var other = VkSurfaceFormatKHR[1](Offered(.VK_FORMAT_A2B10G10R10_UNORM_PACK32));
		Test.Assert(VulkanSwapChain.ChooseSurfaceFormat(.(&other[0], other.Count), .VK_FORMAT_B8G8R8A8_SRGB).format
			== .VK_FORMAT_A2B10G10R10_UNORM_PACK32);
	}

	[Test]
	public static void TheAlternateViewFollowsTheFormatNegotiated()
	{
		// Asked as the requested format's twin: the twin of what the surface gave.
		Test.Assert(VulkanSwapChain.AlternateViewFor(.BGRA8UnormSrgb, .BGRA8Unorm, .BGRA8UnormSrgb) == .BGRA8Unorm);
		Test.Assert(VulkanSwapChain.AlternateViewFor(.BGRA8UnormSrgb, .BGRA8Unorm, .RGBA8UnormSrgb) == .RGBA8Unorm);
		// Asked for the negotiated format's own twin: honoured as asked.
		Test.Assert(VulkanSwapChain.AlternateViewFor(.BGRA8UnormSrgb, .RGBA8Unorm, .RGBA8UnormSrgb) == .RGBA8Unorm);
		// None asked, or a negotiated format with no twin: none.
		Test.Assert(VulkanSwapChain.AlternateViewFor(.BGRA8UnormSrgb, .Undefined, .BGRA8UnormSrgb) == .Undefined);
		Test.Assert(VulkanSwapChain.AlternateViewFor(.BGRA8UnormSrgb, .BGRA8Unorm, .RGB10A2Unorm) == .Undefined);
	}
}
