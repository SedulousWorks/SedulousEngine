using System;

namespace Sedulous.GUI;

// GUI.Hosting: the host on Sedulous.Graphics (GuiHost): one GUI, a root per window, each window's VG
// context, renderer, pass targets and input; the frame; the picture baker (GpuPictureBaker) serving
// every window; the VG shaders they draw with (VgShaderLibrary); a root drawn into a pass its caller
// owns (GuiPassRenderer, an engine's overlays). foundation.ui's counterpart: UI.Runtime. Round three
// of the GUI's evolution (Specs/gui-lab-evolution-3.md, in Raptor), H1 to H3.
//
// VgShaders.bf: the shader set and its library. AtlasPacker.bf: where the baker's atlas puts a
// picture. PictureBaker.bf: the GPU baker. HostedContent.bf:
// what a node shows that is drawn outside the GUI's batch. GuiHost.bf: the host. Offscreen.bf: a
// root drawn into a picture. PassRenderer.bf: a root drawn into a pass its caller opened.
