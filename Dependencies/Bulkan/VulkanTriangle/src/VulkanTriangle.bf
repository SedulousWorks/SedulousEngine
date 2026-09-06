using Bulkan;
using System;
using System.Collections;
using SDL2;
namespace VulkanTriangle;

class VulkanTriangle
{
	private void InitVulkan()
	{
		this.CreateInstance();

		this.SetupDebugMessenger();

		this.CreateSurface();

		this.PickPhysicalDevice();

		this.CreateLogicalDevice();

		this.CreateSwapChain();

		this.CreateImageViews();

		this.CreateRenderPass();

		this.CreateGraphicsPipeline();

		this.CreateFramebuffers();

		this.CreateCommandPool();

		this.CreateCommandBuffers();

		this.CreateSemaphores();
	}

	private void CleanupVulkan()
	{
		Helpers.CheckErrors(VulkanNative.vkDeviceWaitIdle(this.device));

		delete commandBuffers;

		VulkanNative.vkDestroySemaphore(this.device, this.renderFinishedSemaphore, null);
		VulkanNative.vkDestroySemaphore(this.device, this.imageAvailableSemaphore, null);

		VulkanNative.vkDestroyCommandPool(this.device, this.commandPool, null);

		for (var framebuffer in this.swapChainFramebuffers)
		{
			VulkanNative.vkDestroyFramebuffer(this.device, framebuffer, null);
		}
		delete this.swapChainFramebuffers;

		VulkanNative.vkDestroyPipeline(this.device, this.graphicsPipeline, null);

		VulkanNative.vkDestroyPipelineLayout(this.device, this.pipelineLayout, null);

		VulkanNative.vkDestroyRenderPass(this.device, this.renderPass, null);

		for (var imageView in this.swapChainImageViews)
		{
			VulkanNative.vkDestroyImageView(this.device, imageView, null);
		}
		delete this.swapChainImageViews;
		delete swapChainImages;

		VulkanNative.vkDestroySwapchainKHR(this.device, this.swapChain, null);

		VulkanNative.vkDestroyDevice(this.device, null);

		this.DestroyDebugMessenger();

		VulkanNative.vkDestroySurfaceKHR(this.instance, this.surface, null);

		VulkanNative.vkDestroyInstance(this.instance, null);
	}

	public void Run()
	{
		this.InitWindow();

		this.InitVulkan();

		this.MainLoop(scope => this.DrawFrame);

		this.CleanupVulkan();

		this.DestroyWindow();
	}
}
