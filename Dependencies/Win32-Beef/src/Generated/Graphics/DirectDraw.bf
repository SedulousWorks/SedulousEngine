using Win32.Foundation;
using Win32.Graphics.Gdi;
using Win32.System.Com;
using System;

namespace Win32.Graphics.DirectDraw;

#region Constants
public static
{
	public const uint32 DIRECTDRAW_VERSION = 1792;
	public const uint32 _FACDD = 2166;
	public const Guid CLSID_DirectDraw = .(0xd7b70ee0, 0x4340, 0x11cf, 0xb0, 0x63, 0x00, 0x20, 0xaf, 0xc2, 0xcd, 0x35);
	public const Guid CLSID_DirectDraw7 = .(0x3c305196, 0x50db, 0x11d3, 0x9c, 0xfe, 0x00, 0xc0, 0x4f, 0xd9, 0x30, 0xc5);
	public const Guid CLSID_DirectDrawClipper = .(0x593817a0, 0x7db3, 0x11cf, 0xa2, 0xde, 0x00, 0xaa, 0x00, 0xb9, 0x33, 0x56);
	public const int32 DDENUM_ATTACHEDSECONDARYDEVICES = 1;
	public const int32 DDENUM_DETACHEDSECONDARYDEVICES = 2;
	public const int32 DDENUM_NONDISPLAYDEVICES = 4;
	public const String REGSTR_KEY_DDHW_DESCRIPTION = "Description";
	public const String REGSTR_KEY_DDHW_DRIVERNAME = "DriverName";
	public const String REGSTR_PATH_DDHW = "Hardware\\DirectDrawDrivers";
	public const int32 DDCREATE_HARDWAREONLY = 1;
	public const int32 DDCREATE_EMULATIONONLY = 2;
	public const uint32 MAX_DDDEVICEID_STRING = 512;
	public const int32 DDGDI_GETHOSTIDENTIFIER = 1;
	public const int32 DDSD_CAPS = 1;
	public const int32 DDSD_HEIGHT = 2;
	public const int32 DDSD_WIDTH = 4;
	public const int32 DDSD_PITCH = 8;
	public const int32 DDSD_BACKBUFFERCOUNT = 32;
	public const int32 DDSD_ZBUFFERBITDEPTH = 64;
	public const int32 DDSD_ALPHABITDEPTH = 128;
	public const int32 DDSD_LPSURFACE = 2048;
	public const int32 DDSD_PIXELFORMAT = 4096;
	public const int32 DDSD_CKDESTOVERLAY = 8192;
	public const int32 DDSD_CKDESTBLT = 16384;
	public const int32 DDSD_CKSRCOVERLAY = 32768;
	public const int32 DDSD_CKSRCBLT = 65536;
	public const int32 DDSD_MIPMAPCOUNT = 131072;
	public const int32 DDSD_REFRESHRATE = 262144;
	public const int32 DDSD_LINEARSIZE = 524288;
	public const int32 DDSD_TEXTURESTAGE = 1048576;
	public const int32 DDSD_FVF = 2097152;
	public const int32 DDSD_SRCVBHANDLE = 4194304;
	public const int32 DDSD_DEPTH = 8388608;
	public const int32 DDSD_ALL = 16775662;
	public const int32 DDOSD_GUID = 1;
	public const int32 DDOSD_COMPRESSION_RATIO = 2;
	public const int32 DDOSD_SCAPS = 4;
	public const int32 DDOSD_OSCAPS = 8;
	public const int32 DDOSD_ALL = 15;
	public const int32 DDOSDCAPS_OPTCOMPRESSED = 1;
	public const int32 DDOSDCAPS_OPTREORDERED = 2;
	public const int32 DDOSDCAPS_MONOLITHICMIPMAP = 4;
	public const int32 DDOSDCAPS_VALIDSCAPS = 805324800;
	public const int32 DDOSDCAPS_VALIDOSCAPS = 7;
	public const int32 DDCOLOR_BRIGHTNESS = 1;
	public const int32 DDCOLOR_CONTRAST = 2;
	public const int32 DDCOLOR_HUE = 4;
	public const int32 DDCOLOR_SATURATION = 8;
	public const int32 DDCOLOR_SHARPNESS = 16;
	public const int32 DDCOLOR_GAMMA = 32;
	public const int32 DDCOLOR_COLORENABLE = 64;
	public const int32 DDSCAPS_RESERVED1 = 1;
	public const int32 DDSCAPS_ALPHA = 2;
	public const int32 DDSCAPS_BACKBUFFER = 4;
	public const int32 DDSCAPS_COMPLEX = 8;
	public const int32 DDSCAPS_FLIP = 16;
	public const int32 DDSCAPS_FRONTBUFFER = 32;
	public const int32 DDSCAPS_OFFSCREENPLAIN = 64;
	public const int32 DDSCAPS_OVERLAY = 128;
	public const int32 DDSCAPS_PALETTE = 256;
	public const int32 DDSCAPS_PRIMARYSURFACE = 512;
	public const int32 DDSCAPS_RESERVED3 = 1024;
	public const int32 DDSCAPS_PRIMARYSURFACELEFT = 0;
	public const int32 DDSCAPS_SYSTEMMEMORY = 2048;
	public const int32 DDSCAPS_TEXTURE = 4096;
	public const int32 DDSCAPS_3DDEVICE = 8192;
	public const int32 DDSCAPS_VIDEOMEMORY = 16384;
	public const int32 DDSCAPS_VISIBLE = 32768;
	public const int32 DDSCAPS_WRITEONLY = 65536;
	public const int32 DDSCAPS_ZBUFFER = 131072;
	public const int32 DDSCAPS_OWNDC = 262144;
	public const int32 DDSCAPS_LIVEVIDEO = 524288;
	public const int32 DDSCAPS_HWCODEC = 1048576;
	public const int32 DDSCAPS_MODEX = 2097152;
	public const int32 DDSCAPS_MIPMAP = 4194304;
	public const int32 DDSCAPS_RESERVED2 = 8388608;
	public const int32 DDSCAPS_ALLOCONLOAD = 67108864;
	public const int32 DDSCAPS_VIDEOPORT = 134217728;
	public const int32 DDSCAPS_LOCALVIDMEM = 268435456;
	public const int32 DDSCAPS_NONLOCALVIDMEM = 536870912;
	public const int32 DDSCAPS_STANDARDVGAMODE = 1073741824;
	public const int32 DDSCAPS_OPTIMIZED = -2147483648;
	public const int32 DDSCAPS2_RESERVED4 = 2;
	public const int32 DDSCAPS2_HARDWAREDEINTERLACE = 0;
	public const int32 DDSCAPS2_HINTDYNAMIC = 4;
	public const int32 DDSCAPS2_HINTSTATIC = 8;
	public const int32 DDSCAPS2_TEXTUREMANAGE = 16;
	public const int32 DDSCAPS2_RESERVED1 = 32;
	public const int32 DDSCAPS2_RESERVED2 = 64;
	public const int32 DDSCAPS2_OPAQUE = 128;
	public const int32 DDSCAPS2_HINTANTIALIASING = 256;
	public const int32 DDSCAPS2_CUBEMAP = 512;
	public const int32 DDSCAPS2_CUBEMAP_POSITIVEX = 1024;
	public const int32 DDSCAPS2_CUBEMAP_NEGATIVEX = 2048;
	public const int32 DDSCAPS2_CUBEMAP_POSITIVEY = 4096;
	public const int32 DDSCAPS2_CUBEMAP_NEGATIVEY = 8192;
	public const int32 DDSCAPS2_CUBEMAP_POSITIVEZ = 16384;
	public const int32 DDSCAPS2_CUBEMAP_NEGATIVEZ = 32768;
	public const int32 DDSCAPS2_MIPMAPSUBLEVEL = 65536;
	public const int32 DDSCAPS2_D3DTEXTUREMANAGE = 131072;
	public const int32 DDSCAPS2_DONOTPERSIST = 262144;
	public const int32 DDSCAPS2_STEREOSURFACELEFT = 524288;
	public const int32 DDSCAPS2_VOLUME = 2097152;
	public const int32 DDSCAPS2_NOTUSERLOCKABLE = 4194304;
	public const int32 DDSCAPS2_POINTS = 8388608;
	public const int32 DDSCAPS2_RTPATCHES = 16777216;
	public const int32 DDSCAPS2_NPATCHES = 33554432;
	public const int32 DDSCAPS2_RESERVED3 = 67108864;
	public const int32 DDSCAPS2_DISCARDBACKBUFFER = 268435456;
	public const int32 DDSCAPS2_ENABLEALPHACHANNEL = 536870912;
	public const int32 DDSCAPS2_EXTENDEDFORMATPRIMARY = 1073741824;
	public const int32 DDSCAPS2_ADDITIONALPRIMARY = -2147483648;
	public const int32 DDSCAPS3_MULTISAMPLE_MASK = 31;
	public const int32 DDSCAPS3_MULTISAMPLE_QUALITY_MASK = 224;
	public const uint32 DDSCAPS3_MULTISAMPLE_QUALITY_SHIFT = 5;
	public const int32 DDSCAPS3_RESERVED1 = 256;
	public const int32 DDSCAPS3_RESERVED2 = 512;
	public const int32 DDSCAPS3_LIGHTWEIGHTMIPMAP = 1024;
	public const int32 DDSCAPS3_AUTOGENMIPMAP = 2048;
	public const int32 DDSCAPS3_DMAP = 4096;
	public const int32 DDSCAPS3_CREATESHAREDRESOURCE = 8192;
	public const int32 DDSCAPS3_READONLYRESOURCE = 16384;
	public const int32 DDSCAPS3_OPENSHAREDRESOURCE = 32768;
	public const int32 DDCAPS_3D = 1;
	public const int32 DDCAPS_ALIGNBOUNDARYDEST = 2;
	public const int32 DDCAPS_ALIGNSIZEDEST = 4;
	public const int32 DDCAPS_ALIGNBOUNDARYSRC = 8;
	public const int32 DDCAPS_ALIGNSIZESRC = 16;
	public const int32 DDCAPS_ALIGNSTRIDE = 32;
	public const int32 DDCAPS_BLT = 64;
	public const int32 DDCAPS_BLTQUEUE = 128;
	public const int32 DDCAPS_BLTFOURCC = 256;
	public const int32 DDCAPS_BLTSTRETCH = 512;
	public const int32 DDCAPS_GDI = 1024;
	public const int32 DDCAPS_OVERLAY = 2048;
	public const int32 DDCAPS_OVERLAYCANTCLIP = 4096;
	public const int32 DDCAPS_OVERLAYFOURCC = 8192;
	public const int32 DDCAPS_OVERLAYSTRETCH = 16384;
	public const int32 DDCAPS_PALETTE = 32768;
	public const int32 DDCAPS_PALETTEVSYNC = 65536;
	public const int32 DDCAPS_READSCANLINE = 131072;
	public const int32 DDCAPS_RESERVED1 = 262144;
	public const int32 DDCAPS_VBI = 524288;
	public const int32 DDCAPS_ZBLTS = 1048576;
	public const int32 DDCAPS_ZOVERLAYS = 2097152;
	public const int32 DDCAPS_COLORKEY = 4194304;
	public const int32 DDCAPS_ALPHA = 8388608;
	public const int32 DDCAPS_COLORKEYHWASSIST = 16777216;
	public const int32 DDCAPS_NOHARDWARE = 33554432;
	public const int32 DDCAPS_BLTCOLORFILL = 67108864;
	public const int32 DDCAPS_BANKSWITCHED = 134217728;
	public const int32 DDCAPS_BLTDEPTHFILL = 268435456;
	public const int32 DDCAPS_CANCLIP = 536870912;
	public const int32 DDCAPS_CANCLIPSTRETCHED = 1073741824;
	public const int32 DDCAPS_CANBLTSYSMEM = -2147483648;
	public const int32 DDCAPS2_CERTIFIED = 1;
	public const int32 DDCAPS2_NO2DDURING3DSCENE = 2;
	public const int32 DDCAPS2_VIDEOPORT = 4;
	public const int32 DDCAPS2_AUTOFLIPOVERLAY = 8;
	public const int32 DDCAPS2_CANBOBINTERLEAVED = 16;
	public const int32 DDCAPS2_CANBOBNONINTERLEAVED = 32;
	public const int32 DDCAPS2_COLORCONTROLOVERLAY = 64;
	public const int32 DDCAPS2_COLORCONTROLPRIMARY = 128;
	public const int32 DDCAPS2_CANDROPZ16BIT = 256;
	public const int32 DDCAPS2_NONLOCALVIDMEM = 512;
	public const int32 DDCAPS2_NONLOCALVIDMEMCAPS = 1024;
	public const int32 DDCAPS2_NOPAGELOCKREQUIRED = 2048;
	public const int32 DDCAPS2_WIDESURFACES = 4096;
	public const int32 DDCAPS2_CANFLIPODDEVEN = 8192;
	public const int32 DDCAPS2_CANBOBHARDWARE = 16384;
	public const int32 DDCAPS2_COPYFOURCC = 32768;
	public const int32 DDCAPS2_PRIMARYGAMMA = 131072;
	public const int32 DDCAPS2_CANRENDERWINDOWED = 524288;
	public const int32 DDCAPS2_CANCALIBRATEGAMMA = 1048576;
	public const int32 DDCAPS2_FLIPINTERVAL = 2097152;
	public const int32 DDCAPS2_FLIPNOVSYNC = 4194304;
	public const int32 DDCAPS2_CANMANAGETEXTURE = 8388608;
	public const int32 DDCAPS2_TEXMANINNONLOCALVIDMEM = 16777216;
	public const int32 DDCAPS2_STEREO = 33554432;
	public const int32 DDCAPS2_SYSTONONLOCAL_AS_SYSTOLOCAL = 67108864;
	public const int32 DDCAPS2_RESERVED1 = 134217728;
	public const int32 DDCAPS2_CANMANAGERESOURCE = 268435456;
	public const int32 DDCAPS2_DYNAMICTEXTURES = 536870912;
	public const int32 DDCAPS2_CANAUTOGENMIPMAP = 1073741824;
	public const int32 DDCAPS2_CANSHARERESOURCE = -2147483648;
	public const int32 DDFXALPHACAPS_BLTALPHAEDGEBLEND = 1;
	public const int32 DDFXALPHACAPS_BLTALPHAPIXELS = 2;
	public const int32 DDFXALPHACAPS_BLTALPHAPIXELSNEG = 4;
	public const int32 DDFXALPHACAPS_BLTALPHASURFACES = 8;
	public const int32 DDFXALPHACAPS_BLTALPHASURFACESNEG = 16;
	public const int32 DDFXALPHACAPS_OVERLAYALPHAEDGEBLEND = 32;
	public const int32 DDFXALPHACAPS_OVERLAYALPHAPIXELS = 64;
	public const int32 DDFXALPHACAPS_OVERLAYALPHAPIXELSNEG = 128;
	public const int32 DDFXALPHACAPS_OVERLAYALPHASURFACES = 256;
	public const int32 DDFXALPHACAPS_OVERLAYALPHASURFACESNEG = 512;
	public const int32 DDFXCAPS_BLTARITHSTRETCHY = 32;
	public const int32 DDFXCAPS_BLTARITHSTRETCHYN = 16;
	public const int32 DDFXCAPS_BLTMIRRORLEFTRIGHT = 64;
	public const int32 DDFXCAPS_BLTMIRRORUPDOWN = 128;
	public const int32 DDFXCAPS_BLTROTATION = 256;
	public const int32 DDFXCAPS_BLTROTATION90 = 512;
	public const int32 DDFXCAPS_BLTSHRINKX = 1024;
	public const int32 DDFXCAPS_BLTSHRINKXN = 2048;
	public const int32 DDFXCAPS_BLTSHRINKY = 4096;
	public const int32 DDFXCAPS_BLTSHRINKYN = 8192;
	public const int32 DDFXCAPS_BLTSTRETCHX = 16384;
	public const int32 DDFXCAPS_BLTSTRETCHXN = 32768;
	public const int32 DDFXCAPS_BLTSTRETCHY = 65536;
	public const int32 DDFXCAPS_BLTSTRETCHYN = 131072;
	public const int32 DDFXCAPS_OVERLAYARITHSTRETCHY = 262144;
	public const int32 DDFXCAPS_OVERLAYARITHSTRETCHYN = 8;
	public const int32 DDFXCAPS_OVERLAYSHRINKX = 524288;
	public const int32 DDFXCAPS_OVERLAYSHRINKXN = 1048576;
	public const int32 DDFXCAPS_OVERLAYSHRINKY = 2097152;
	public const int32 DDFXCAPS_OVERLAYSHRINKYN = 4194304;
	public const int32 DDFXCAPS_OVERLAYSTRETCHX = 8388608;
	public const int32 DDFXCAPS_OVERLAYSTRETCHXN = 16777216;
	public const int32 DDFXCAPS_OVERLAYSTRETCHY = 33554432;
	public const int32 DDFXCAPS_OVERLAYSTRETCHYN = 67108864;
	public const int32 DDFXCAPS_OVERLAYMIRRORLEFTRIGHT = 134217728;
	public const int32 DDFXCAPS_OVERLAYMIRRORUPDOWN = 268435456;
	public const int32 DDFXCAPS_OVERLAYDEINTERLACE = 536870912;
	public const int32 DDFXCAPS_BLTALPHA = 1;
	public const int32 DDFXCAPS_BLTFILTER = 32;
	public const int32 DDFXCAPS_OVERLAYALPHA = 4;
	public const int32 DDFXCAPS_OVERLAYFILTER = 262144;
	public const int32 DDSVCAPS_RESERVED1 = 1;
	public const int32 DDSVCAPS_RESERVED2 = 2;
	public const int32 DDSVCAPS_RESERVED3 = 4;
	public const int32 DDSVCAPS_RESERVED4 = 8;
	public const int32 DDSVCAPS_STEREOSEQUENTIAL = 16;
	public const int32 DDPCAPS_4BIT = 1;
	public const int32 DDPCAPS_8BITENTRIES = 2;
	public const int32 DDPCAPS_8BIT = 4;
	public const int32 DDPCAPS_INITIALIZE = 0;
	public const int32 DDPCAPS_PRIMARYSURFACE = 16;
	public const int32 DDPCAPS_PRIMARYSURFACELEFT = 32;
	public const int32 DDPCAPS_ALLOW256 = 64;
	public const int32 DDPCAPS_VSYNC = 128;
	public const int32 DDPCAPS_1BIT = 256;
	public const int32 DDPCAPS_2BIT = 512;
	public const int32 DDPCAPS_ALPHA = 1024;
	public const int32 DDSPD_IUNKNOWNPOINTER = 1;
	public const int32 DDSPD_VOLATILE = 2;
	public const int32 DDBD_1 = 16384;
	public const int32 DDBD_2 = 8192;
	public const int32 DDBD_4 = 4096;
	public const int32 DDBD_8 = 2048;
	public const int32 DDBD_16 = 1024;
	public const int32 DDBD_24 = 512;
	public const int32 DDBD_32 = 256;
	public const int32 DDCKEY_COLORSPACE = 1;
	public const int32 DDCKEY_DESTBLT = 2;
	public const int32 DDCKEY_DESTOVERLAY = 4;
	public const int32 DDCKEY_SRCBLT = 8;
	public const int32 DDCKEY_SRCOVERLAY = 16;
	public const int32 DDCKEYCAPS_DESTBLT = 1;
	public const int32 DDCKEYCAPS_DESTBLTCLRSPACE = 2;
	public const int32 DDCKEYCAPS_DESTBLTCLRSPACEYUV = 4;
	public const int32 DDCKEYCAPS_DESTBLTYUV = 8;
	public const int32 DDCKEYCAPS_DESTOVERLAY = 16;
	public const int32 DDCKEYCAPS_DESTOVERLAYCLRSPACE = 32;
	public const int32 DDCKEYCAPS_DESTOVERLAYCLRSPACEYUV = 64;
	public const int32 DDCKEYCAPS_DESTOVERLAYONEACTIVE = 128;
	public const int32 DDCKEYCAPS_DESTOVERLAYYUV = 256;
	public const int32 DDCKEYCAPS_SRCBLT = 512;
	public const int32 DDCKEYCAPS_SRCBLTCLRSPACE = 1024;
	public const int32 DDCKEYCAPS_SRCBLTCLRSPACEYUV = 2048;
	public const int32 DDCKEYCAPS_SRCBLTYUV = 4096;
	public const int32 DDCKEYCAPS_SRCOVERLAY = 8192;
	public const int32 DDCKEYCAPS_SRCOVERLAYCLRSPACE = 16384;
	public const int32 DDCKEYCAPS_SRCOVERLAYCLRSPACEYUV = 32768;
	public const int32 DDCKEYCAPS_SRCOVERLAYONEACTIVE = 65536;
	public const int32 DDCKEYCAPS_SRCOVERLAYYUV = 131072;
	public const int32 DDCKEYCAPS_NOCOSTOVERLAY = 262144;
	public const int32 DDPF_ALPHAPIXELS = 1;
	public const int32 DDPF_ALPHA = 2;
	public const int32 DDPF_FOURCC = 4;
	public const int32 DDPF_PALETTEINDEXED4 = 8;
	public const int32 DDPF_PALETTEINDEXEDTO8 = 16;
	public const int32 DDPF_PALETTEINDEXED8 = 32;
	public const int32 DDPF_RGB = 64;
	public const int32 DDPF_COMPRESSED = 128;
	public const int32 DDPF_RGBTOYUV = 256;
	public const int32 DDPF_YUV = 512;
	public const int32 DDPF_ZBUFFER = 1024;
	public const int32 DDPF_PALETTEINDEXED1 = 2048;
	public const int32 DDPF_PALETTEINDEXED2 = 4096;
	public const int32 DDPF_ZPIXELS = 8192;
	public const int32 DDPF_STENCILBUFFER = 16384;
	public const int32 DDPF_ALPHAPREMULT = 32768;
	public const int32 DDPF_LUMINANCE = 131072;
	public const int32 DDPF_BUMPLUMINANCE = 262144;
	public const int32 DDPF_BUMPDUDV = 524288;
	public const int32 DDENUMSURFACES_ALL = 1;
	public const int32 DDENUMSURFACES_MATCH = 2;
	public const int32 DDENUMSURFACES_NOMATCH = 4;
	public const int32 DDENUMSURFACES_CANBECREATED = 8;
	public const int32 DDENUMSURFACES_DOESEXIST = 16;
	public const int32 DDSDM_STANDARDVGAMODE = 1;
	public const int32 DDEDM_REFRESHRATES = 1;
	public const int32 DDEDM_STANDARDVGAMODES = 2;
	public const int32 DDSCL_FULLSCREEN = 1;
	public const int32 DDSCL_ALLOWREBOOT = 2;
	public const int32 DDSCL_NOWINDOWCHANGES = 4;
	public const int32 DDSCL_NORMAL = 8;
	public const int32 DDSCL_EXCLUSIVE = 16;
	public const int32 DDSCL_ALLOWMODEX = 64;
	public const int32 DDSCL_SETFOCUSWINDOW = 128;
	public const int32 DDSCL_SETDEVICEWINDOW = 256;
	public const int32 DDSCL_CREATEDEVICEWINDOW = 512;
	public const int32 DDSCL_MULTITHREADED = 1024;
	public const int32 DDSCL_FPUSETUP = 2048;
	public const int32 DDSCL_FPUPRESERVE = 4096;
	public const int32 DDBLT_ALPHADEST = 1;
	public const int32 DDBLT_ALPHADESTCONSTOVERRIDE = 2;
	public const int32 DDBLT_ALPHADESTNEG = 4;
	public const int32 DDBLT_ALPHADESTSURFACEOVERRIDE = 8;
	public const int32 DDBLT_ALPHAEDGEBLEND = 16;
	public const int32 DDBLT_ALPHASRC = 32;
	public const int32 DDBLT_ALPHASRCCONSTOVERRIDE = 64;
	public const int32 DDBLT_ALPHASRCNEG = 128;
	public const int32 DDBLT_ALPHASRCSURFACEOVERRIDE = 256;
	public const int32 DDBLT_ASYNC = 512;
	public const int32 DDBLT_COLORFILL = 1024;
	public const int32 DDBLT_DDFX = 2048;
	public const int32 DDBLT_DDROPS = 4096;
	public const int32 DDBLT_KEYDEST = 8192;
	public const int32 DDBLT_KEYDESTOVERRIDE = 16384;
	public const int32 DDBLT_KEYSRC = 32768;
	public const int32 DDBLT_KEYSRCOVERRIDE = 65536;
	public const int32 DDBLT_ROP = 131072;
	public const int32 DDBLT_ROTATIONANGLE = 262144;
	public const int32 DDBLT_ZBUFFER = 524288;
	public const int32 DDBLT_ZBUFFERDESTCONSTOVERRIDE = 1048576;
	public const int32 DDBLT_ZBUFFERDESTOVERRIDE = 2097152;
	public const int32 DDBLT_ZBUFFERSRCCONSTOVERRIDE = 4194304;
	public const int32 DDBLT_ZBUFFERSRCOVERRIDE = 8388608;
	public const int32 DDBLT_WAIT = 16777216;
	public const int32 DDBLT_DEPTHFILL = 33554432;
	public const int32 DDBLT_DONOTWAIT = 134217728;
	public const int32 DDBLT_PRESENTATION = 268435456;
	public const int32 DDBLT_LAST_PRESENTATION = 536870912;
	public const int32 DDBLT_EXTENDED_FLAGS = 1073741824;
	public const int32 DDBLT_EXTENDED_LINEAR_CONTENT = 4;
	public const uint32 DDBLTFAST_NOCOLORKEY = 0;
	public const uint32 DDBLTFAST_SRCCOLORKEY = 1;
	public const uint32 DDBLTFAST_DESTCOLORKEY = 2;
	public const uint32 DDBLTFAST_WAIT = 16;
	public const uint32 DDBLTFAST_DONOTWAIT = 32;
	public const int32 DDFLIP_WAIT = 1;
	public const int32 DDFLIP_EVEN = 2;
	public const int32 DDFLIP_ODD = 4;
	public const int32 DDFLIP_NOVSYNC = 8;
	public const int32 DDFLIP_INTERVAL2 = 33554432;
	public const int32 DDFLIP_INTERVAL3 = 50331648;
	public const int32 DDFLIP_INTERVAL4 = 67108864;
	public const int32 DDFLIP_STEREO = 16;
	public const int32 DDFLIP_DONOTWAIT = 32;
	public const int32 DDOVER_ALPHADEST = 1;
	public const int32 DDOVER_ALPHADESTCONSTOVERRIDE = 2;
	public const int32 DDOVER_ALPHADESTNEG = 4;
	public const int32 DDOVER_ALPHADESTSURFACEOVERRIDE = 8;
	public const int32 DDOVER_ALPHAEDGEBLEND = 16;
	public const int32 DDOVER_ALPHASRC = 32;
	public const int32 DDOVER_ALPHASRCCONSTOVERRIDE = 64;
	public const int32 DDOVER_ALPHASRCNEG = 128;
	public const int32 DDOVER_ALPHASRCSURFACEOVERRIDE = 256;
	public const int32 DDOVER_HIDE = 512;
	public const int32 DDOVER_KEYDEST = 1024;
	public const int32 DDOVER_KEYDESTOVERRIDE = 2048;
	public const int32 DDOVER_KEYSRC = 4096;
	public const int32 DDOVER_KEYSRCOVERRIDE = 8192;
	public const int32 DDOVER_SHOW = 16384;
	public const int32 DDOVER_ADDDIRTYRECT = 32768;
	public const int32 DDOVER_REFRESHDIRTYRECTS = 65536;
	public const int32 DDOVER_REFRESHALL = 131072;
	public const int32 DDOVER_DDFX = 524288;
	public const int32 DDOVER_AUTOFLIP = 1048576;
	public const int32 DDOVER_BOB = 2097152;
	public const int32 DDOVER_OVERRIDEBOBWEAVE = 4194304;
	public const int32 DDOVER_INTERLEAVED = 8388608;
	public const int32 DDOVER_BOBHARDWARE = 16777216;
	public const int32 DDOVER_ARGBSCALEFACTORS = 33554432;
	public const int32 DDOVER_DEGRADEARGBSCALING = 67108864;
	public const int32 DDSETSURFACEDESC_RECREATEDC = 0;
	public const int32 DDSETSURFACEDESC_PRESERVEDC = 1;
	public const int32 DDLOCK_SURFACEMEMORYPTR = 0;
	public const int32 DDLOCK_WAIT = 1;
	public const int32 DDLOCK_EVENT = 2;
	public const int32 DDLOCK_READONLY = 16;
	public const int32 DDLOCK_WRITEONLY = 32;
	public const int32 DDLOCK_NOSYSLOCK = 2048;
	public const int32 DDLOCK_NOOVERWRITE = 4096;
	public const int32 DDLOCK_DISCARDCONTENTS = 8192;
	public const int32 DDLOCK_OKTOSWAP = 8192;
	public const int32 DDLOCK_DONOTWAIT = 16384;
	public const int32 DDLOCK_HASVOLUMETEXTUREBOXRECT = 32768;
	public const int32 DDLOCK_NODIRTYUPDATE = 65536;
	public const int32 DDBLTFX_ARITHSTRETCHY = 1;
	public const int32 DDBLTFX_MIRRORLEFTRIGHT = 2;
	public const int32 DDBLTFX_MIRRORUPDOWN = 4;
	public const int32 DDBLTFX_NOTEARING = 8;
	public const int32 DDBLTFX_ROTATE180 = 16;
	public const int32 DDBLTFX_ROTATE270 = 32;
	public const int32 DDBLTFX_ROTATE90 = 64;
	public const int32 DDBLTFX_ZBUFFERRANGE = 128;
	public const int32 DDBLTFX_ZBUFFERBASEDEST = 256;
	public const int32 DDOVERFX_ARITHSTRETCHY = 1;
	public const int32 DDOVERFX_MIRRORLEFTRIGHT = 2;
	public const int32 DDOVERFX_MIRRORUPDOWN = 4;
	public const int32 DDOVERFX_DEINTERLACE = 8;
	public const int32 DDWAITVB_BLOCKBEGIN = 1;
	public const int32 DDWAITVB_BLOCKBEGINEVENT = 2;
	public const int32 DDWAITVB_BLOCKEND = 4;
	public const int32 DDGFS_CANFLIP = 1;
	public const int32 DDGFS_ISFLIPDONE = 2;
	public const int32 DDGBS_CANBLT = 1;
	public const int32 DDGBS_ISBLTDONE = 2;
	public const int32 DDENUMOVERLAYZ_BACKTOFRONT = 0;
	public const int32 DDENUMOVERLAYZ_FRONTTOBACK = 1;
	public const int32 DDOVERZ_SENDTOFRONT = 0;
	public const int32 DDOVERZ_SENDTOBACK = 1;
	public const int32 DDOVERZ_MOVEFORWARD = 2;
	public const int32 DDOVERZ_MOVEBACKWARD = 3;
	public const int32 DDOVERZ_INSERTINFRONTOF = 4;
	public const int32 DDOVERZ_INSERTINBACKOF = 5;
	public const int32 DDSGR_CALIBRATE = 1;
	public const int32 DDSMT_ISTESTREQUIRED = 1;
	public const int32 DDEM_MODEPASSED = 1;
	public const int32 DDEM_MODEFAILED = 2;
	public const uint32 DDENUMRET_CANCEL = 0;
	public const uint32 DDENUMRET_OK = 1;
	public const int32 DDERR_NOTINITIALIZED = -2147221008;
	public const int32 OBJECT_ISROOT = -2147483648;
	public const uint32 DDUNSUPPORTEDMODE = 4294967295;
	public const Guid GUID_MiscellaneousCallbacks = .(0xefd60cc0, 0x49e7, 0x11d0, 0x88, 0x9d, 0x00, 0xaa, 0x00, 0xbb, 0xb7, 0x6a);
	public const Guid GUID_VideoPortCallbacks = .(0xefd60cc1, 0x49e7, 0x11d0, 0x88, 0x9d, 0x00, 0xaa, 0x00, 0xbb, 0xb7, 0x6a);
	public const Guid GUID_ColorControlCallbacks = .(0xefd60cc2, 0x49e7, 0x11d0, 0x88, 0x9d, 0x00, 0xaa, 0x00, 0xbb, 0xb7, 0x6a);
	public const Guid GUID_VideoPortCaps = .(0xefd60cc3, 0x49e7, 0x11d0, 0x88, 0x9d, 0x00, 0xaa, 0x00, 0xbb, 0xb7, 0x6a);
	public const Guid GUID_D3DCallbacks2 = .(0x0ba584e1, 0x70b6, 0x11d0, 0x88, 0x9d, 0x00, 0xaa, 0x00, 0xbb, 0xb7, 0x6a);
	public const Guid GUID_D3DCallbacks3 = .(0xddf41230, 0xec0a, 0x11d0, 0xa9, 0xb6, 0x00, 0xaa, 0x00, 0xc0, 0x99, 0x3e);
	public const Guid GUID_NonLocalVidMemCaps = .(0x86c4fa80, 0x8d84, 0x11d0, 0x94, 0xe8, 0x00, 0xc0, 0x4f, 0xc3, 0x41, 0x37);
	public const Guid GUID_KernelCallbacks = .(0x80863800, 0x6b06, 0x11d0, 0x9b, 0x06, 0x00, 0xa0, 0xc9, 0x03, 0xa3, 0xb8);
	public const Guid GUID_KernelCaps = .(0xffaa7540, 0x7aa8, 0x11d0, 0x9b, 0x06, 0x00, 0xa0, 0xc9, 0x03, 0xa3, 0xb8);
	public const Guid GUID_D3DExtendedCaps = .(0x7de41f80, 0x9d93, 0x11d0, 0x89, 0xab, 0x00, 0xa0, 0xc9, 0x05, 0x41, 0x29);
	public const Guid GUID_ZPixelFormats = .(0x93869880, 0x36cf, 0x11d1, 0x9b, 0x1b, 0x00, 0xaa, 0x00, 0xbb, 0xb8, 0xae);
	public const Guid GUID_DDMoreSurfaceCaps = .(0x3b8a0466, 0xf269, 0x11d1, 0x88, 0x0b, 0x00, 0xc0, 0x4f, 0xd9, 0x30, 0xc5);
	public const Guid GUID_DDStereoMode = .(0xf828169c, 0xa8e8, 0x11d2, 0xa1, 0xf2, 0x00, 0xa0, 0xc9, 0x83, 0xea, 0xf6);
	public const Guid GUID_OptSurfaceKmodeInfo = .(0xe05c8472, 0x51d4, 0x11d1, 0x8c, 0xce, 0x00, 0xa0, 0xc9, 0x06, 0x29, 0xa8);
	public const Guid GUID_OptSurfaceUmodeInfo = .(0x9d792804, 0x5fa8, 0x11d1, 0x8c, 0xd0, 0x00, 0xa0, 0xc9, 0x06, 0x29, 0xa8);
	public const Guid GUID_UserModeDriverInfo = .(0xf0b0e8e2, 0x5f97, 0x11d1, 0x8c, 0xd0, 0x00, 0xa0, 0xc9, 0x06, 0x29, 0xa8);
	public const Guid GUID_UserModeDriverPassword = .(0x97f861b6, 0x60a1, 0x11d1, 0x8c, 0xd0, 0x00, 0xa0, 0xc9, 0x06, 0x29, 0xa8);
	public const Guid GUID_D3DParseUnknownCommandCallback = .(0x2e04ffa0, 0x98e4, 0x11d1, 0x8c, 0xe1, 0x00, 0xa0, 0xc9, 0x06, 0x29, 0xa8);
	public const Guid GUID_MotionCompCallbacks = .(0xb1122b40, 0x5da5, 0x11d1, 0x8f, 0xcf, 0x00, 0xc0, 0x4f, 0xc2, 0x9b, 0x4e);
	public const Guid GUID_Miscellaneous2Callbacks = .(0x406b2f00, 0x3e5a, 0x11d1, 0xb6, 0x40, 0x00, 0xaa, 0x00, 0xa1, 0xf9, 0x6a);
	public const int32 DDPF_NOVEL_TEXTURE_FORMAT = 1048576;
	public const int32 DDPF_D3DFORMAT = 2097152;
	public const int32 D3DFORMAT_OP_TEXTURE = 1;
	public const int32 D3DFORMAT_OP_VOLUMETEXTURE = 2;
	public const int32 D3DFORMAT_OP_CUBETEXTURE = 4;
	public const int32 D3DFORMAT_OP_OFFSCREEN_RENDERTARGET = 8;
	public const int32 D3DFORMAT_OP_SAME_FORMAT_RENDERTARGET = 16;
	public const int32 D3DFORMAT_OP_ZSTENCIL = 64;
	public const int32 D3DFORMAT_OP_ZSTENCIL_WITH_ARBITRARY_COLOR_DEPTH = 128;
	public const int32 D3DFORMAT_OP_SAME_FORMAT_UP_TO_ALPHA_RENDERTARGET = 256;
	public const int32 D3DFORMAT_OP_DISPLAYMODE = 1024;
	public const int32 D3DFORMAT_OP_3DACCELERATION = 2048;
	public const int32 D3DFORMAT_OP_PIXELSIZE = 4096;
	public const int32 D3DFORMAT_OP_CONVERT_TO_ARGB = 8192;
	public const int32 D3DFORMAT_OP_OFFSCREENPLAIN = 16384;
	public const int32 D3DFORMAT_OP_SRGBREAD = 32768;
	public const int32 D3DFORMAT_OP_BUMPMAP = 65536;
	public const int32 D3DFORMAT_OP_DMAP = 131072;
	public const int32 D3DFORMAT_OP_NOFILTER = 262144;
	public const int32 D3DFORMAT_MEMBEROFGROUP_ARGB = 524288;
	public const int32 D3DFORMAT_OP_SRGBWRITE = 1048576;
	public const int32 D3DFORMAT_OP_NOALPHABLEND = 2097152;
	public const int32 D3DFORMAT_OP_AUTOGENMIPMAP = 4194304;
	public const int32 D3DFORMAT_OP_VERTEXTEXTURE = 8388608;
	public const int32 D3DFORMAT_OP_NOTEXCOORDWRAPNORMIP = 16777216;
	public const uint32 DELETED_OK = 0;
	public const uint32 DELETED_LASTONE = 1;
	public const uint32 DELETED_NOTFOUND = 2;
	public const uint32 DCICOMMAND = 3075;
	public const int32 DD_VERSION = 512;
	public const int32 DD_RUNTIME_VERSION = 2306;
	public const uint32 DD_HAL_VERSION = 256;
	public const uint32 DDCREATEDRIVEROBJECT = 10;
	public const uint32 DDGET32BITDRIVERNAME = 11;
	public const uint32 DDNEWCALLBACKFNS = 12;
	public const uint32 DDVERSIONINFO = 13;
	public const String DDHAL_DRIVER_DLLNAME = "DDRAW16.DLL";
	public const String DDHAL_APP_DLLNAME = "DDRAW.DLL";
	public const uint32 CCHDEVICENAME = 32;
	public const uint32 MAX_DRIVER_NAME = 32;
	public const uint32 MAX_PALETTE_SIZE = 256;
	public const uint32 MAX_AUTOFLIP_BUFFERS = 10;
	public const int32 DDSCAPS_EXECUTEBUFFER = 8388608;
	public const int32 DDSCAPS2_VERTEXBUFFER = 32;
	public const int32 DDSCAPS2_COMMANDBUFFER = 64;
	public const int32 DDSCAPS2_INDEXBUFFER = 67108864;
	public const int32 DDSCAPS3_VIDEO = 512;
	public const uint32 D3DFMT_INTERNAL_D32 = 71;
	public const uint32 D3DFMT_INTERNAL_S1D15 = 72;
	public const uint32 D3DFMT_INTERNAL_D15S1 = 73;
	public const uint32 D3DFMT_INTERNAL_S8D24 = 74;
	public const uint32 D3DFMT_INTERNAL_D24S8 = 75;
	public const uint32 D3DFMT_INTERNAL_X8D24 = 76;
	public const uint32 D3DFMT_INTERNAL_D24X8 = 77;
	public const int32 DDHAL_PLEASEALLOC_BLOCKSIZE = 2;
	public const int32 DDHAL_PLEASEALLOC_LINEARSIZE = 3;
	public const int32 VIDMEM_ISLINEAR = 1;
	public const int32 VIDMEM_ISRECTANGULAR = 2;
	public const int32 VIDMEM_ISHEAP = 4;
	public const int32 VIDMEM_ISNONLOCAL = 8;
	public const int32 VIDMEM_ISWC = 16;
	public const int32 VIDMEM_HEAPDISABLED = 32;
	public const int32 HEAPALIASINFO_MAPPEDREAL = 1;
	public const int32 HEAPALIASINFO_MAPPEDDUMMY = 2;
	public const int32 DDHAL_CB32_DESTROYDRIVER = 1;
	public const int32 DDHAL_CB32_CREATESURFACE = 2;
	public const int32 DDHAL_CB32_SETCOLORKEY = 4;
	public const int32 DDHAL_CB32_SETMODE = 8;
	public const int32 DDHAL_CB32_WAITFORVERTICALBLANK = 16;
	public const int32 DDHAL_CB32_CANCREATESURFACE = 32;
	public const int32 DDHAL_CB32_CREATEPALETTE = 64;
	public const int32 DDHAL_CB32_GETSCANLINE = 128;
	public const int32 DDHAL_CB32_SETEXCLUSIVEMODE = 256;
	public const int32 DDHAL_CB32_FLIPTOGDISURFACE = 512;
	public const int32 DDHAL_PALCB32_DESTROYPALETTE = 1;
	public const int32 DDHAL_PALCB32_SETENTRIES = 2;
	public const int32 DDHAL_SURFCB32_DESTROYSURFACE = 1;
	public const int32 DDHAL_SURFCB32_FLIP = 2;
	public const int32 DDHAL_SURFCB32_SETCLIPLIST = 4;
	public const int32 DDHAL_SURFCB32_LOCK = 8;
	public const int32 DDHAL_SURFCB32_UNLOCK = 16;
	public const int32 DDHAL_SURFCB32_BLT = 32;
	public const int32 DDHAL_SURFCB32_SETCOLORKEY = 64;
	public const int32 DDHAL_SURFCB32_ADDATTACHEDSURFACE = 128;
	public const int32 DDHAL_SURFCB32_GETBLTSTATUS = 256;
	public const int32 DDHAL_SURFCB32_GETFLIPSTATUS = 512;
	public const int32 DDHAL_SURFCB32_UPDATEOVERLAY = 1024;
	public const int32 DDHAL_SURFCB32_SETOVERLAYPOSITION = 2048;
	public const int32 DDHAL_SURFCB32_RESERVED4 = 4096;
	public const int32 DDHAL_SURFCB32_SETPALETTE = 8192;
	public const int32 DDHAL_MISCCB32_GETAVAILDRIVERMEMORY = 1;
	public const int32 DDHAL_MISCCB32_UPDATENONLOCALHEAP = 2;
	public const int32 DDHAL_MISCCB32_GETHEAPALIGNMENT = 4;
	public const int32 DDHAL_MISCCB32_GETSYSMEMBLTSTATUS = 8;
	public const int32 DDHAL_MISC2CB32_CREATESURFACEEX = 2;
	public const int32 DDHAL_MISC2CB32_GETDRIVERSTATE = 4;
	public const int32 DDHAL_MISC2CB32_DESTROYDDLOCAL = 8;
	public const int32 DDHAL_EXEBUFCB32_CANCREATEEXEBUF = 1;
	public const int32 DDHAL_EXEBUFCB32_CREATEEXEBUF = 2;
	public const int32 DDHAL_EXEBUFCB32_DESTROYEXEBUF = 4;
	public const int32 DDHAL_EXEBUFCB32_LOCKEXEBUF = 8;
	public const int32 DDHAL_EXEBUFCB32_UNLOCKEXEBUF = 16;
	public const int32 DDHAL_VPORT32_CANCREATEVIDEOPORT = 1;
	public const int32 DDHAL_VPORT32_CREATEVIDEOPORT = 2;
	public const int32 DDHAL_VPORT32_FLIP = 4;
	public const int32 DDHAL_VPORT32_GETBANDWIDTH = 8;
	public const int32 DDHAL_VPORT32_GETINPUTFORMATS = 16;
	public const int32 DDHAL_VPORT32_GETOUTPUTFORMATS = 32;
	public const int32 DDHAL_VPORT32_GETFIELD = 128;
	public const int32 DDHAL_VPORT32_GETLINE = 256;
	public const int32 DDHAL_VPORT32_GETCONNECT = 512;
	public const int32 DDHAL_VPORT32_DESTROY = 1024;
	public const int32 DDHAL_VPORT32_GETFLIPSTATUS = 2048;
	public const int32 DDHAL_VPORT32_UPDATE = 4096;
	public const int32 DDHAL_VPORT32_WAITFORSYNC = 8192;
	public const int32 DDHAL_VPORT32_GETSIGNALSTATUS = 16384;
	public const int32 DDHAL_VPORT32_COLORCONTROL = 32768;
	public const int32 DDHAL_COLOR_COLORCONTROL = 1;
	public const int32 DDHAL_KERNEL_SYNCSURFACEDATA = 1;
	public const int32 DDHAL_KERNEL_SYNCVIDEOPORTDATA = 2;
	public const uint32 DDHAL_MOCOMP32_GETGUIDS = 1;
	public const uint32 DDHAL_MOCOMP32_GETFORMATS = 2;
	public const uint32 DDHAL_MOCOMP32_CREATE = 4;
	public const uint32 DDHAL_MOCOMP32_GETCOMPBUFFINFO = 8;
	public const uint32 DDHAL_MOCOMP32_GETINTERNALINFO = 16;
	public const uint32 DDHAL_MOCOMP32_BEGINFRAME = 32;
	public const uint32 DDHAL_MOCOMP32_ENDFRAME = 64;
	public const uint32 DDHAL_MOCOMP32_RENDER = 128;
	public const uint32 DDHAL_MOCOMP32_QUERYSTATUS = 256;
	public const uint32 DDHAL_MOCOMP32_DESTROY = 512;
	public const int32 DDHAL_DRIVER_NOTHANDLED = 0;
	public const int32 DDHAL_DRIVER_HANDLED = 1;
	public const int32 DDHAL_DRIVER_NOCKEYHW = 2;
	public const int32 DDRAWIPAL_256 = 1;
	public const int32 DDRAWIPAL_16 = 2;
	public const int32 DDRAWIPAL_GDI = 4;
	public const int32 DDRAWIPAL_STORED_8 = 8;
	public const int32 DDRAWIPAL_STORED_16 = 16;
	public const int32 DDRAWIPAL_STORED_24 = 32;
	public const int32 DDRAWIPAL_EXCLUSIVE = 64;
	public const int32 DDRAWIPAL_INHEL = 128;
	public const int32 DDRAWIPAL_DIRTY = 256;
	public const int32 DDRAWIPAL_ALLOW256 = 512;
	public const int32 DDRAWIPAL_4 = 1024;
	public const int32 DDRAWIPAL_2 = 2048;
	public const int32 DDRAWIPAL_STORED_8INDEX = 4096;
	public const int32 DDRAWIPAL_ALPHA = 8192;
	public const int32 DDRAWICLIP_WATCHWINDOW = 1;
	public const int32 DDRAWICLIP_ISINITIALIZED = 2;
	public const int32 DDRAWICLIP_INMASTERSPRITELIST = 4;
	public const int32 DDAL_IMPLICIT = 1;
	public const int32 ACCESSRECT_VRAMSTYLE = 1;
	public const int32 ACCESSRECT_NOTHOLDINGWIN16LOCK = 2;
	public const int32 ACCESSRECT_BROKEN = 4;
	public const uint32 PFINDEX_UNINITIALIZED = 0;
	public const int32 DDRAWISURFGBL_MEMFREE = 1;
	public const int32 DDRAWISURFGBL_SYSMEMREQUESTED = 2;
	public const int32 DDRAWISURFGBL_ISGDISURFACE = 4;
	public const int32 DDRAWISURFGBL_SOFTWAREAUTOFLIP = 8;
	public const int32 DDRAWISURFGBL_LOCKNOTHOLDINGWIN16LOCK = 16;
	public const int32 DDRAWISURFGBL_LOCKVRAMSTYLE = 32;
	public const int32 DDRAWISURFGBL_LOCKBROKEN = 64;
	public const int32 DDRAWISURFGBL_IMPLICITHANDLE = 128;
	public const int32 DDRAWISURFGBL_ISCLIENTMEM = 256;
	public const int32 DDRAWISURFGBL_HARDWAREOPSOURCE = 512;
	public const int32 DDRAWISURFGBL_HARDWAREOPDEST = 1024;
	public const int32 DDRAWISURFGBL_VPORTINTERLEAVED = 2048;
	public const int32 DDRAWISURFGBL_VPORTDATA = 4096;
	public const int32 DDRAWISURFGBL_LATEALLOCATELINEAR = 8192;
	public const int32 DDRAWISURFGBL_SYSMEMEXECUTEBUFFER = 16384;
	public const int32 DDRAWISURFGBL_FASTLOCKHELD = 32768;
	public const int32 DDRAWISURFGBL_READONLYLOCKHELD = 65536;
	public const int32 DDRAWISURFGBL_DX8SURFACE = 524288;
	public const int32 DDRAWISURFGBL_DDHELDONTFREE = 1048576;
	public const int32 DDRAWISURFGBL_NOTIFYWHENUNLOCKED = 2097152;
	public const int32 DDRAWISURFGBL_RESERVED0 = -2147483648;
	public const int32 DDRAWISURF_ATTACHED = 1;
	public const int32 DDRAWISURF_IMPLICITCREATE = 2;
	public const int32 DDRAWISURF_ISFREE = 4;
	public const int32 DDRAWISURF_ATTACHED_FROM = 8;
	public const int32 DDRAWISURF_IMPLICITROOT = 16;
	public const int32 DDRAWISURF_PARTOFPRIMARYCHAIN = 32;
	public const int32 DDRAWISURF_DATAISALIASED = 64;
	public const int32 DDRAWISURF_HASDC = 128;
	public const int32 DDRAWISURF_HASCKEYDESTOVERLAY = 256;
	public const int32 DDRAWISURF_HASCKEYDESTBLT = 512;
	public const int32 DDRAWISURF_HASCKEYSRCOVERLAY = 1024;
	public const int32 DDRAWISURF_HASCKEYSRCBLT = 2048;
	public const int32 DDRAWISURF_LOCKEXCLUDEDCURSOR = 4096;
	public const int32 DDRAWISURF_HASPIXELFORMAT = 8192;
	public const int32 DDRAWISURF_HASOVERLAYDATA = 16384;
	public const int32 DDRAWISURF_SETGAMMA = 32768;
	public const int32 DDRAWISURF_SW_CKEYDESTOVERLAY = 65536;
	public const int32 DDRAWISURF_SW_CKEYDESTBLT = 131072;
	public const int32 DDRAWISURF_SW_CKEYSRCOVERLAY = 262144;
	public const int32 DDRAWISURF_SW_CKEYSRCBLT = 524288;
	public const int32 DDRAWISURF_HW_CKEYDESTOVERLAY = 1048576;
	public const int32 DDRAWISURF_HW_CKEYDESTBLT = 2097152;
	public const int32 DDRAWISURF_HW_CKEYSRCOVERLAY = 4194304;
	public const int32 DDRAWISURF_HW_CKEYSRCBLT = 8388608;
	public const int32 DDRAWISURF_INMASTERSPRITELIST = 16777216;
	public const int32 DDRAWISURF_HELCB = 33554432;
	public const int32 DDRAWISURF_FRONTBUFFER = 67108864;
	public const int32 DDRAWISURF_BACKBUFFER = 134217728;
	public const int32 DDRAWISURF_INVALID = 268435456;
	public const int32 DDRAWISURF_DCIBUSY = 536870912;
	public const int32 DDRAWISURF_GETDCNULL = 1073741824;
	public const int32 DDRAWISURF_STEREOSURFACELEFT = 536870912;
	public const int32 DDRAWISURF_DRIVERMANAGED = 1073741824;
	public const int32 DDRAWISURF_DCILOCK = -2147483648;
	public const int32 ROP_HAS_SOURCE = 1;
	public const int32 ROP_HAS_PATTERN = 2;
	public const uint32 DDMODEINFO_PALETTIZED = 1;
	public const uint32 DDMODEINFO_MODEX = 2;
	public const uint32 DDMODEINFO_UNSUPPORTED = 4;
	public const uint32 DDMODEINFO_STANDARDVGA = 8;
	public const uint32 DDMODEINFO_MAXREFRESH = 16;
	public const uint32 DDMODEINFO_STEREO = 32;
	public const int32 DDRAWILCL_HASEXCLUSIVEMODE = 1;
	public const int32 DDRAWILCL_ISFULLSCREEN = 2;
	public const int32 DDRAWILCL_SETCOOPCALLED = 4;
	public const int32 DDRAWILCL_ACTIVEYES = 8;
	public const int32 DDRAWILCL_ACTIVENO = 16;
	public const int32 DDRAWILCL_HOOKEDHWND = 32;
	public const int32 DDRAWILCL_ALLOWMODEX = 64;
	public const int32 DDRAWILCL_V1SCLBEHAVIOUR = 128;
	public const int32 DDRAWILCL_MODEHASBEENCHANGED = 256;
	public const int32 DDRAWILCL_CREATEDWINDOW = 512;
	public const int32 DDRAWILCL_DIRTYDC = 1024;
	public const int32 DDRAWILCL_DISABLEINACTIVATE = 2048;
	public const int32 DDRAWILCL_CURSORCLIPPED = 4096;
	public const int32 DDRAWILCL_EXPLICITMONITOR = 8192;
	public const int32 DDRAWILCL_MULTITHREADED = 16384;
	public const int32 DDRAWILCL_FPUSETUP = 32768;
	public const int32 DDRAWILCL_POWEREDDOWN = 65536;
	public const int32 DDRAWILCL_DIRECTDRAW7 = 131072;
	public const int32 DDRAWILCL_ATTEMPTEDD3DCONTEXT = 262144;
	public const int32 DDRAWILCL_FPUPRESERVE = 524288;
	public const int32 DDRAWILCL_DX8DRIVER = 1048576;
	public const int32 DDRAWILCL_DIRECTDRAW8 = 2097152;
	public const int32 DDRAWI_xxxxxxxxx1 = 1;
	public const int32 DDRAWI_xxxxxxxxx2 = 2;
	public const int32 DDRAWI_VIRTUALDESKTOP = 8;
	public const int32 DDRAWI_MODEX = 16;
	public const int32 DDRAWI_DISPLAYDRV = 32;
	public const int32 DDRAWI_FULLSCREEN = 64;
	public const int32 DDRAWI_MODECHANGED = 128;
	public const int32 DDRAWI_NOHARDWARE = 256;
	public const int32 DDRAWI_PALETTEINIT = 512;
	public const int32 DDRAWI_NOEMULATION = 1024;
	public const int32 DDRAWI_HASCKEYDESTOVERLAY = 2048;
	public const int32 DDRAWI_HASCKEYSRCOVERLAY = 4096;
	public const int32 DDRAWI_HASGDIPALETTE = 8192;
	public const int32 DDRAWI_EMULATIONINITIALIZED = 16384;
	public const int32 DDRAWI_HASGDIPALETTE_EXCLUSIVE = 32768;
	public const int32 DDRAWI_MODEXILLEGAL = 65536;
	public const int32 DDRAWI_FLIPPEDTOGDI = 131072;
	public const int32 DDRAWI_NEEDSWIN16FORVRAMLOCK = 262144;
	public const int32 DDRAWI_PDEVICEVRAMBITCLEARED = 524288;
	public const int32 DDRAWI_STANDARDVGA = 1048576;
	public const int32 DDRAWI_EXTENDEDALIGNMENT = 2097152;
	public const int32 DDRAWI_CHANGINGMODE = 4194304;
	public const int32 DDRAWI_GDIDRV = 8388608;
	public const int32 DDRAWI_ATTACHEDTODESKTOP = 16777216;
	public const int32 DDRAWI_UMODELOADED = 33554432;
	public const int32 DDRAWI_DDRAWDATANOTFETCHED = 67108864;
	public const int32 DDRAWI_SECONDARYDRIVERLOADED = 134217728;
	public const int32 DDRAWI_TESTINGMODES = 268435456;
	public const int32 DDRAWI_DRIVERINFO2 = 536870912;
	public const int32 DDRAWI_BADPDEV = 1073741824;
	public const uint32 DDRAWIVPORT_ON = 1;
	public const uint32 DDRAWIVPORT_SOFTWARE_AUTOFLIP = 2;
	public const uint32 DDRAWIVPORT_COLORKEYANDINTERP = 4;
	public const uint32 DDRAWIVPORT_NOKERNELHANDLES = 8;
	public const uint32 DDRAWIVPORT_SOFTWARE_BOB = 16;
	public const uint32 DDRAWIVPORT_VBION = 32;
	public const uint32 DDRAWIVPORT_VIDEOON = 64;
	public const int32 DDHALINFO_ISPRIMARYDISPLAY = 1;
	public const int32 DDHALINFO_MODEXILLEGAL = 2;
	public const int32 DDHALINFO_GETDRIVERINFOSET = 4;
	public const int32 DDHALINFO_GETDRIVERINFO2 = 8;
	public const int32 DDWAITVB_I_TESTVB = -2147483642;
	public const uint32 DDRAWI_VPORTSTART = 1;
	public const uint32 DDRAWI_VPORTSTOP = 2;
	public const uint32 DDRAWI_VPORTUPDATE = 3;
	public const uint32 DDRAWI_VPORTGETCOLOR = 1;
	public const uint32 DDRAWI_VPORTSETCOLOR = 2;
	public const uint32 DDRAWI_GETCOLOR = 1;
	public const uint32 DDRAWI_SETCOLOR = 2;
	public const uint32 DDMCQUERY_READ = 1;
	public const Guid GUID_D3DCaps = .(0x7bf06991, 0x8794, 0x11d0, 0x91, 0x39, 0x08, 0x00, 0x36, 0xd2, 0xef, 0x02);
	public const Guid GUID_D3DCallbacks = .(0x7bf06990, 0x8794, 0x11d0, 0x91, 0x39, 0x08, 0x00, 0x36, 0xd2, 0xef, 0x02);
	public const Guid GUID_DDMoreCaps = .(0x880baf30, 0xb030, 0x11d0, 0x8e, 0xa7, 0x00, 0x60, 0x97, 0x97, 0xea, 0x5b);
	public const Guid GUID_NTCallbacks = .(0x6fe9ecde, 0xdf89, 0x11d1, 0x9d, 0xb0, 0x00, 0x60, 0x08, 0x27, 0x71, 0xba);
	public const Guid GUID_GetHeapAlignment = .(0x42e02f16, 0x7b41, 0x11d2, 0x8b, 0xff, 0x00, 0xa0, 0xc9, 0x83, 0xea, 0xf6);
	public const Guid GUID_UpdateNonLocalHeap = .(0x42e02f17, 0x7b41, 0x11d2, 0x8b, 0xff, 0x00, 0xa0, 0xc9, 0x83, 0xea, 0xf6);
	public const Guid GUID_NTPrivateDriverCaps = .(0xfad16a23, 0x7b66, 0x11d2, 0x83, 0xd7, 0x00, 0xc0, 0x4f, 0x7c, 0xe5, 0x8c);
	public const Guid GUID_VPE2Callbacks = .(0x52882147, 0x2d47, 0x469a, 0xa0, 0xd1, 0x03, 0x45, 0x58, 0x90, 0xf6, 0xc8);
	public const int32 DDSCAPS_COMMANDBUFFER = 1024;
	public const int32 DDHAL_PLEASEALLOC_USERMEM = 4;
	public const int32 DDHAL_CB32_MAPMEMORY = -2147483648;
	public const int32 DDHAL_MISC2CB32_ALPHABLT = 1;
	public const int32 DDHAL_CREATESURFACEEX_SWAPHANDLES = 1;
	public const int32 DDHAL_NTCB32_FREEDRIVERMEMORY = 1;
	public const int32 DDHAL_NTCB32_SETEXCLUSIVEMODE = 2;
	public const int32 DDHAL_NTCB32_FLIPTOGDISURFACE = 4;
	public const int32 DDHAL_VPORT32_GETAUTOFLIPSURF = 64;
	public const int32 DDHAL_D3DBUFCB32_CANCREATED3DBUF = 1;
	public const int32 DDHAL_D3DBUFCB32_CREATED3DBUF = 2;
	public const int32 DDHAL_D3DBUFCB32_DESTROYD3DBUF = 4;
	public const int32 DDHAL_D3DBUFCB32_LOCKD3DBUF = 8;
	public const int32 DDHAL_D3DBUFCB32_UNLOCKD3DBUF = 16;
	public const int32 DDHAL_PRIVATECAP_ATOMICSURFACECREATION = 1;
	public const int32 DDHAL_PRIVATECAP_NOTIFYPRIMARYCREATION = 2;
	public const int32 DDHAL_PRIVATECAP_RESERVED1 = 4;
	public const int32 DDBLT_AFLAGS = -2147483648;
	public const int32 DDABLT_SRCOVERDEST = 1;
	public const int32 DDKERNELCAPS_SKIPFIELDS = 1;
	public const int32 DDKERNELCAPS_AUTOFLIP = 2;
	public const int32 DDKERNELCAPS_SETSTATE = 4;
	public const int32 DDKERNELCAPS_LOCK = 8;
	public const int32 DDKERNELCAPS_FLIPVIDEOPORT = 16;
	public const int32 DDKERNELCAPS_FLIPOVERLAY = 32;
	public const int32 DDKERNELCAPS_CAPTURE_SYSMEM = 64;
	public const int32 DDKERNELCAPS_CAPTURE_NONLOCALVIDMEM = 128;
	public const int32 DDKERNELCAPS_FIELDPOLARITY = 256;
	public const int32 DDKERNELCAPS_CAPTURE_INVERTED = 512;
	public const int32 DDIRQ_DISPLAY_VSYNC = 1;
	public const int32 DDIRQ_RESERVED1 = 2;
	public const int32 DDIRQ_VPORT0_VSYNC = 4;
	public const int32 DDIRQ_VPORT0_LINE = 8;
	public const int32 DDIRQ_VPORT1_VSYNC = 16;
	public const int32 DDIRQ_VPORT1_LINE = 32;
	public const int32 DDIRQ_VPORT2_VSYNC = 64;
	public const int32 DDIRQ_VPORT2_LINE = 128;
	public const int32 DDIRQ_VPORT3_VSYNC = 256;
	public const int32 DDIRQ_VPORT3_LINE = 512;
	public const int32 DDIRQ_VPORT4_VSYNC = 1024;
	public const int32 DDIRQ_VPORT4_LINE = 2048;
	public const int32 DDIRQ_VPORT5_VSYNC = 4096;
	public const int32 DDIRQ_VPORT5_LINE = 8192;
	public const int32 DDIRQ_VPORT6_VSYNC = 16384;
	public const int32 DDIRQ_VPORT6_LINE = 32768;
	public const int32 DDIRQ_VPORT7_VSYNC = 65536;
	public const int32 DDIRQ_VPORT7_LINE = 131072;
	public const int32 DDIRQ_VPORT8_VSYNC = 262144;
	public const int32 DDIRQ_VPORT8_LINE = 524288;
	public const int32 DDIRQ_VPORT9_VSYNC = 65536;
	public const int32 DDIRQ_VPORT9_LINE = 131072;
	public const int32 SURFACEALIGN_DISCARDABLE = 1;
	public const int32 VMEMHEAP_LINEAR = 1;
	public const int32 VMEMHEAP_RECTANGULAR = 2;
	public const int32 VMEMHEAP_ALIGNMENT = 4;
	public const Guid DDVPTYPE_E_HREFH_VREFH = .(0x54f39980, 0xda60, 0x11cf, 0x9b, 0x06, 0x00, 0xa0, 0xc9, 0x03, 0xa3, 0xb8);
	public const Guid DDVPTYPE_E_HREFH_VREFL = .(0x92783220, 0xda60, 0x11cf, 0x9b, 0x06, 0x00, 0xa0, 0xc9, 0x03, 0xa3, 0xb8);
	public const Guid DDVPTYPE_E_HREFL_VREFH = .(0xa07a02e0, 0xda60, 0x11cf, 0x9b, 0x06, 0x00, 0xa0, 0xc9, 0x03, 0xa3, 0xb8);
	public const Guid DDVPTYPE_E_HREFL_VREFL = .(0xe09c77e0, 0xda60, 0x11cf, 0x9b, 0x06, 0x00, 0xa0, 0xc9, 0x03, 0xa3, 0xb8);
	public const Guid DDVPTYPE_CCIR656 = .(0xfca326a0, 0xda60, 0x11cf, 0x9b, 0x06, 0x00, 0xa0, 0xc9, 0x03, 0xa3, 0xb8);
	public const Guid DDVPTYPE_BROOKTREE = .(0x1352a560, 0xda61, 0x11cf, 0x9b, 0x06, 0x00, 0xa0, 0xc9, 0x03, 0xa3, 0xb8);
	public const Guid DDVPTYPE_PHILIPS = .(0x332cf160, 0xda61, 0x11cf, 0x9b, 0x06, 0x00, 0xa0, 0xc9, 0x03, 0xa3, 0xb8);
	public const int32 DDVPD_WIDTH = 1;
	public const int32 DDVPD_HEIGHT = 2;
	public const int32 DDVPD_ID = 4;
	public const int32 DDVPD_CAPS = 8;
	public const int32 DDVPD_FX = 16;
	public const int32 DDVPD_AUTOFLIP = 32;
	public const int32 DDVPD_ALIGN = 64;
	public const int32 DDVPD_PREFERREDAUTOFLIP = 128;
	public const int32 DDVPD_FILTERQUALITY = 256;
	public const int32 DDVPCONNECT_DOUBLECLOCK = 1;
	public const int32 DDVPCONNECT_VACT = 2;
	public const int32 DDVPCONNECT_INVERTPOLARITY = 4;
	public const int32 DDVPCONNECT_DISCARDSVREFDATA = 8;
	public const int32 DDVPCONNECT_HALFLINE = 16;
	public const int32 DDVPCONNECT_INTERLACED = 32;
	public const int32 DDVPCONNECT_SHAREEVEN = 64;
	public const int32 DDVPCONNECT_SHAREODD = 128;
	public const int32 DDVPCAPS_AUTOFLIP = 1;
	public const int32 DDVPCAPS_INTERLACED = 2;
	public const int32 DDVPCAPS_NONINTERLACED = 4;
	public const int32 DDVPCAPS_READBACKFIELD = 8;
	public const int32 DDVPCAPS_READBACKLINE = 16;
	public const int32 DDVPCAPS_SHAREABLE = 32;
	public const int32 DDVPCAPS_SKIPEVENFIELDS = 64;
	public const int32 DDVPCAPS_SKIPODDFIELDS = 128;
	public const int32 DDVPCAPS_SYNCMASTER = 256;
	public const int32 DDVPCAPS_VBISURFACE = 512;
	public const int32 DDVPCAPS_COLORCONTROL = 1024;
	public const int32 DDVPCAPS_OVERSAMPLEDVBI = 2048;
	public const int32 DDVPCAPS_SYSTEMMEMORY = 4096;
	public const int32 DDVPCAPS_VBIANDVIDEOINDEPENDENT = 8192;
	public const int32 DDVPCAPS_HARDWAREDEINTERLACE = 16384;
	public const int32 DDVPFX_CROPTOPDATA = 1;
	public const int32 DDVPFX_CROPX = 2;
	public const int32 DDVPFX_CROPY = 4;
	public const int32 DDVPFX_INTERLEAVE = 8;
	public const int32 DDVPFX_MIRRORLEFTRIGHT = 16;
	public const int32 DDVPFX_MIRRORUPDOWN = 32;
	public const int32 DDVPFX_PRESHRINKX = 64;
	public const int32 DDVPFX_PRESHRINKY = 128;
	public const int32 DDVPFX_PRESHRINKXB = 256;
	public const int32 DDVPFX_PRESHRINKYB = 512;
	public const int32 DDVPFX_PRESHRINKXS = 1024;
	public const int32 DDVPFX_PRESHRINKYS = 2048;
	public const int32 DDVPFX_PRESTRETCHX = 4096;
	public const int32 DDVPFX_PRESTRETCHY = 8192;
	public const int32 DDVPFX_PRESTRETCHXN = 16384;
	public const int32 DDVPFX_PRESTRETCHYN = 32768;
	public const int32 DDVPFX_VBICONVERT = 65536;
	public const int32 DDVPFX_VBINOSCALE = 131072;
	public const int32 DDVPFX_IGNOREVBIXCROP = 262144;
	public const int32 DDVPFX_VBINOINTERLEAVE = 524288;
	public const int32 DDVP_AUTOFLIP = 1;
	public const int32 DDVP_CONVERT = 2;
	public const int32 DDVP_CROP = 4;
	public const int32 DDVP_INTERLEAVE = 8;
	public const int32 DDVP_MIRRORLEFTRIGHT = 16;
	public const int32 DDVP_MIRRORUPDOWN = 32;
	public const int32 DDVP_PRESCALE = 64;
	public const int32 DDVP_SKIPEVENFIELDS = 128;
	public const int32 DDVP_SKIPODDFIELDS = 256;
	public const int32 DDVP_SYNCMASTER = 512;
	public const int32 DDVP_VBICONVERT = 1024;
	public const int32 DDVP_VBINOSCALE = 2048;
	public const int32 DDVP_OVERRIDEBOBWEAVE = 4096;
	public const int32 DDVP_IGNOREVBIXCROP = 8192;
	public const int32 DDVP_VBINOINTERLEAVE = 16384;
	public const int32 DDVP_HARDWAREDEINTERLACE = 32768;
	public const int32 DDVPFORMAT_VIDEO = 1;
	public const int32 DDVPFORMAT_VBI = 2;
	public const int32 DDVPTARGET_VIDEO = 1;
	public const int32 DDVPTARGET_VBI = 2;
	public const int32 DDVPWAIT_BEGIN = 1;
	public const int32 DDVPWAIT_END = 2;
	public const int32 DDVPWAIT_LINE = 3;
	public const int32 DDVPFLIP_VIDEO = 1;
	public const int32 DDVPFLIP_VBI = 2;
	public const int32 DDVPSQ_NOSIGNAL = 1;
	public const int32 DDVPSQ_SIGNALOK = 2;
	public const int32 DDVPB_VIDEOPORT = 1;
	public const int32 DDVPB_OVERLAY = 2;
	public const int32 DDVPB_TYPE = 4;
	public const int32 DDVPBCAPS_SOURCE = 1;
	public const int32 DDVPBCAPS_DESTINATION = 2;
	public const int32 DDVPCREATE_VBIONLY = 1;
	public const int32 DDVPCREATE_VIDEOONLY = 2;
	public const int32 DDVPSTATUS_VBIONLY = 1;
	public const int32 DDVPSTATUS_VIDEOONLY = 2;
	public const Guid GUID_DxApi = .(0x8a79bef0, 0xb915, 0x11d0, 0x91, 0x44, 0x08, 0x00, 0x36, 0xd2, 0xef, 0x02);
	public const uint32 MDL_MAPPED_TO_SYSTEM_VA = 1;
	public const uint32 MDL_PAGES_LOCKED = 2;
	public const uint32 MDL_SOURCE_IS_NONPAGED_POOL = 4;
	public const uint32 MDL_ALLOCATED_FIXED_SIZE = 8;
	public const uint32 MDL_PARTIAL = 16;
	public const uint32 MDL_PARTIAL_HAS_BEEN_MAPPED = 32;
	public const uint32 MDL_IO_PAGE_READ = 64;
	public const uint32 MDL_WRITE_OPERATION = 128;
	public const uint32 MDL_PARENT_MAPPED_SYSTEM_VA = 256;
	public const uint32 MDL_LOCK_HELD = 512;
	public const uint32 MDL_SCATTER_GATHER_VA = 1024;
	public const uint32 MDL_IO_SPACE = 2048;
	public const uint32 MDL_NETWORK_HEADER = 4096;
	public const uint32 MDL_MAPPING_CAN_FAIL = 8192;
	public const uint32 MDL_ALLOCATED_MUST_SUCCEED = 16384;
	public const uint32 MDL_64_BIT_VA = 32768;
	public const uint32 DX_OK = 0;
	public const uint32 DXERR_UNSUPPORTED = 2147500033;
	public const uint32 DXERR_GENERIC = 2147500037;
	public const uint32 DXERR_OUTOFCAPS = 2289434984;
	public const int32 DDIRQ_BUSMASTER = 2;
	public const uint32 IRQINFO_HANDLED = 1;
	public const uint32 IRQINFO_NOTHANDLED = 2;
	public const uint32 DDSKIP_SKIPNEXT = 1;
	public const uint32 DDSKIP_ENABLENEXT = 2;
	public const uint32 DDTRANSFER_SYSTEMMEMORY = 1;
	public const uint32 DDTRANSFER_NONLOCALVIDMEM = 2;
	public const uint32 DDTRANSFER_INVERT = 4;
	public const uint32 DDTRANSFER_CANCEL = 128;
	public const uint32 DDTRANSFER_HALFLINES = 256;
	public const uint32 DXAPI_HALVERSION = 1;
}
#endregion
#region Function Pointers
public function BOOL LPDDENUMCALLBACKA(Guid* param0, PSTR param1, PSTR param2, void* param3);

public function BOOL LPDDENUMCALLBACKW(Guid* param0, PWSTR param1, PWSTR param2, void* param3);

public function BOOL LPDDENUMCALLBACKEXA(Guid* param0, PSTR param1, PSTR param2, void* param3, HMONITOR param4);

public function BOOL LPDDENUMCALLBACKEXW(Guid* param0, PWSTR param1, PWSTR param2, void* param3, HMONITOR param4);

public function HRESULT LPDIRECTDRAWENUMERATEEXA(LPDDENUMCALLBACKEXA lpCallback, void* lpContext, uint32 dwFlags);

public function HRESULT LPDIRECTDRAWENUMERATEEXW(LPDDENUMCALLBACKEXW lpCallback, void* lpContext, uint32 dwFlags);

public function HRESULT LPDDENUMMODESCALLBACK(DDSURFACEDESC* param0, void* param1);

public function HRESULT LPDDENUMMODESCALLBACK2(DDSURFACEDESC2* param0, void* param1);

public function HRESULT LPDDENUMSURFACESCALLBACK(IDirectDrawSurface* param0, DDSURFACEDESC* param1, void* param2);

public function HRESULT LPDDENUMSURFACESCALLBACK2(IDirectDrawSurface4* param0, DDSURFACEDESC2* param1, void* param2);

public function HRESULT LPDDENUMSURFACESCALLBACK7(IDirectDrawSurface7* param0, DDSURFACEDESC2* param1, void* param2);

public function uint32 LPCLIPPERCALLBACK(IDirectDrawClipper* lpDDClipper, HWND hWnd, uint32 code, void* lpContext);

public function HRESULT LPDDENUMVIDEOCALLBACK(DDVIDEOPORTCAPS* param0, void* param1);

public function uint32 LPDD32BITDRIVERINIT(uint32 dwContext);

public function BOOL LPDDHEL_INIT(DDRAWI_DIRECTDRAW_GBL* param0, BOOL param1);

public function uint32 LPDDHAL_SETCOLORKEY(DDHAL_DRVSETCOLORKEYDATA* param0);

public function uint32 LPDDHAL_CANCREATESURFACE(DDHAL_CANCREATESURFACEDATA* param0);

public function uint32 LPDDHAL_WAITFORVERTICALBLANK(DDHAL_WAITFORVERTICALBLANKDATA* param0);

public function uint32 LPDDHAL_CREATESURFACE(DDHAL_CREATESURFACEDATA* param0);

public function uint32 LPDDHAL_DESTROYDRIVER(DDHAL_DESTROYDRIVERDATA* param0);

public function uint32 LPDDHAL_SETMODE(DDHAL_SETMODEDATA* param0);

public function uint32 LPDDHAL_CREATEPALETTE(DDHAL_CREATEPALETTEDATA* param0);

public function uint32 LPDDHAL_GETSCANLINE(DDHAL_GETSCANLINEDATA* param0);

public function uint32 LPDDHAL_SETEXCLUSIVEMODE(DDHAL_SETEXCLUSIVEMODEDATA* param0);

public function uint32 LPDDHAL_FLIPTOGDISURFACE(DDHAL_FLIPTOGDISURFACEDATA* param0);

public function uint32 LPDDHAL_GETDRIVERINFO(DDHAL_GETDRIVERINFODATA* param0);

public function uint32 LPDDHALPALCB_DESTROYPALETTE(DDHAL_DESTROYPALETTEDATA* param0);

public function uint32 LPDDHALPALCB_SETENTRIES(DDHAL_SETENTRIESDATA* param0);

public function uint32 LPDDHALSURFCB_LOCK(DDHAL_LOCKDATA* param0);

public function uint32 LPDDHALSURFCB_UNLOCK(DDHAL_UNLOCKDATA* param0);

public function uint32 LPDDHALSURFCB_BLT(DDHAL_BLTDATA* param0);

public function uint32 LPDDHALSURFCB_UPDATEOVERLAY(DDHAL_UPDATEOVERLAYDATA* param0);

public function uint32 LPDDHALSURFCB_SETOVERLAYPOSITION(DDHAL_SETOVERLAYPOSITIONDATA* param0);

public function uint32 LPDDHALSURFCB_SETPALETTE(DDHAL_SETPALETTEDATA* param0);

public function uint32 LPDDHALSURFCB_FLIP(DDHAL_FLIPDATA* param0);

public function uint32 LPDDHALSURFCB_DESTROYSURFACE(DDHAL_DESTROYSURFACEDATA* param0);

public function uint32 LPDDHALSURFCB_SETCLIPLIST(DDHAL_SETCLIPLISTDATA* param0);

public function uint32 LPDDHALSURFCB_ADDATTACHEDSURFACE(DDHAL_ADDATTACHEDSURFACEDATA* param0);

public function uint32 LPDDHALSURFCB_SETCOLORKEY(DDHAL_SETCOLORKEYDATA* param0);

public function uint32 LPDDHALSURFCB_GETBLTSTATUS(DDHAL_GETBLTSTATUSDATA* param0);

public function uint32 LPDDHALSURFCB_GETFLIPSTATUS(DDHAL_GETFLIPSTATUSDATA* param0);

public function uint32 LPDDHAL_GETAVAILDRIVERMEMORY(DDHAL_GETAVAILDRIVERMEMORYDATA* param0);

public function uint32 LPDDHAL_UPDATENONLOCALHEAP(DDHAL_UPDATENONLOCALHEAPDATA* param0);

public function uint32 LPDDHAL_GETHEAPALIGNMENT(DDHAL_GETHEAPALIGNMENTDATA* param0);

public function uint32 LPDDHAL_CREATESURFACEEX(DDHAL_CREATESURFACEEXDATA* param0);

public function uint32 LPDDHAL_GETDRIVERSTATE(DDHAL_GETDRIVERSTATEDATA* param0);

public function uint32 LPDDHAL_DESTROYDDLOCAL(DDHAL_DESTROYDDLOCALDATA* param0);

public function uint32 LPDDHALEXEBUFCB_CANCREATEEXEBUF(DDHAL_CANCREATESURFACEDATA* param0);

public function uint32 LPDDHALEXEBUFCB_CREATEEXEBUF(DDHAL_CREATESURFACEDATA* param0);

public function uint32 LPDDHALEXEBUFCB_DESTROYEXEBUF(DDHAL_DESTROYSURFACEDATA* param0);

public function uint32 LPDDHALEXEBUFCB_LOCKEXEBUF(DDHAL_LOCKDATA* param0);

public function uint32 LPDDHALEXEBUFCB_UNLOCKEXEBUF(DDHAL_UNLOCKDATA* param0);

public function uint32 LPDDHALVPORTCB_CANCREATEVIDEOPORT(DDHAL_CANCREATEVPORTDATA* param0);

public function uint32 LPDDHALVPORTCB_CREATEVIDEOPORT(DDHAL_CREATEVPORTDATA* param0);

public function uint32 LPDDHALVPORTCB_FLIP(DDHAL_FLIPVPORTDATA* param0);

public function uint32 LPDDHALVPORTCB_GETBANDWIDTH(DDHAL_GETVPORTBANDWIDTHDATA* param0);

public function uint32 LPDDHALVPORTCB_GETINPUTFORMATS(DDHAL_GETVPORTINPUTFORMATDATA* param0);

public function uint32 LPDDHALVPORTCB_GETOUTPUTFORMATS(DDHAL_GETVPORTOUTPUTFORMATDATA* param0);

public function uint32 LPDDHALVPORTCB_GETFIELD(DDHAL_GETVPORTFIELDDATA* param0);

public function uint32 LPDDHALVPORTCB_GETLINE(DDHAL_GETVPORTLINEDATA* param0);

public function uint32 LPDDHALVPORTCB_GETVPORTCONNECT(DDHAL_GETVPORTCONNECTDATA* param0);

public function uint32 LPDDHALVPORTCB_DESTROYVPORT(DDHAL_DESTROYVPORTDATA* param0);

public function uint32 LPDDHALVPORTCB_GETFLIPSTATUS(DDHAL_GETVPORTFLIPSTATUSDATA* param0);

public function uint32 LPDDHALVPORTCB_UPDATE(DDHAL_UPDATEVPORTDATA* param0);

public function uint32 LPDDHALVPORTCB_WAITFORSYNC(DDHAL_WAITFORVPORTSYNCDATA* param0);

public function uint32 LPDDHALVPORTCB_GETSIGNALSTATUS(DDHAL_GETVPORTSIGNALDATA* param0);

public function uint32 LPDDHALVPORTCB_COLORCONTROL(DDHAL_VPORTCOLORDATA* param0);

public function uint32 LPDDHALCOLORCB_COLORCONTROL(DDHAL_COLORCONTROLDATA* param0);

public function uint32 LPDDHALKERNELCB_SYNCSURFACE(DDHAL_SYNCSURFACEDATA* param0);

public function uint32 LPDDHALKERNELCB_SYNCVIDEOPORT(DDHAL_SYNCVIDEOPORTDATA* param0);

public function HRESULT LPDDGAMMACALIBRATORPROC(DDGAMMARAMP* param0, uint8* param1);

public function uint32 LPDDHALMOCOMPCB_GETGUIDS(DDHAL_GETMOCOMPGUIDSDATA* param0);

public function uint32 LPDDHALMOCOMPCB_GETFORMATS(DDHAL_GETMOCOMPFORMATSDATA* param0);

public function uint32 LPDDHALMOCOMPCB_CREATE(DDHAL_CREATEMOCOMPDATA* param0);

public function uint32 LPDDHALMOCOMPCB_GETCOMPBUFFINFO(DDHAL_GETMOCOMPCOMPBUFFDATA* param0);

public function uint32 LPDDHALMOCOMPCB_GETINTERNALINFO(DDHAL_GETINTERNALMOCOMPDATA* param0);

public function uint32 LPDDHALMOCOMPCB_BEGINFRAME(DDHAL_BEGINMOCOMPFRAMEDATA* param0);

public function uint32 LPDDHALMOCOMPCB_ENDFRAME(DDHAL_ENDMOCOMPFRAMEDATA* param0);

public function uint32 LPDDHALMOCOMPCB_RENDER(DDHAL_RENDERMOCOMPDATA* param0);

public function uint32 LPDDHALMOCOMPCB_QUERYSTATUS(DDHAL_QUERYMOCOMPSTATUSDATA* param0);

public function uint32 LPDDHALMOCOMPCB_DESTROY(DDHAL_DESTROYMOCOMPDATA* param0);

public function BOOL LPDDHAL_SETINFO(DDHALINFO* lpDDHalInfo, BOOL reset);

public function uint LPDDHAL_VIDMEMALLOC(DDRAWI_DIRECTDRAW_GBL* lpDD, int32 heap, uint32 dwWidth, uint32 dwHeight);

public function void LPDDHAL_VIDMEMFREE(DDRAWI_DIRECTDRAW_GBL* lpDD, int32 heap, uint fpMem);

public function uint32 PDD_SETCOLORKEY(DD_DRVSETCOLORKEYDATA* param0);

public function uint32 PDD_CANCREATESURFACE(DD_CANCREATESURFACEDATA* param0);

public function uint32 PDD_WAITFORVERTICALBLANK(DD_WAITFORVERTICALBLANKDATA* param0);

public function uint32 PDD_CREATESURFACE(DD_CREATESURFACEDATA* param0);

public function uint32 PDD_DESTROYDRIVER(_DD_DESTROYDRIVERDATA* param0);

public function uint32 PDD_SETMODE(_DD_SETMODEDATA* param0);

public function uint32 PDD_CREATEPALETTE(DD_CREATEPALETTEDATA* param0);

public function uint32 PDD_GETSCANLINE(DD_GETSCANLINEDATA* param0);

public function uint32 PDD_MAPMEMORY(DD_MAPMEMORYDATA* param0);

public function uint32 PDD_GETDRIVERINFO(DD_GETDRIVERINFODATA* param0);

public function uint32 PDD_GETAVAILDRIVERMEMORY(DD_GETAVAILDRIVERMEMORYDATA* param0);

public function uint32 PDD_ALPHABLT(DD_BLTDATA* param0);

public function uint32 PDD_CREATESURFACEEX(DD_CREATESURFACEEXDATA* param0);

public function uint32 PDD_GETDRIVERSTATE(DD_GETDRIVERSTATEDATA* param0);

public function uint32 PDD_DESTROYDDLOCAL(DD_DESTROYDDLOCALDATA* param0);

public function uint32 PDD_FREEDRIVERMEMORY(DD_FREEDRIVERMEMORYDATA* param0);

public function uint32 PDD_SETEXCLUSIVEMODE(DD_SETEXCLUSIVEMODEDATA* param0);

public function uint32 PDD_FLIPTOGDISURFACE(DD_FLIPTOGDISURFACEDATA* param0);

public function uint32 PDD_PALCB_DESTROYPALETTE(DD_DESTROYPALETTEDATA* param0);

public function uint32 PDD_PALCB_SETENTRIES(DD_SETENTRIESDATA* param0);

public function uint32 PDD_SURFCB_LOCK(DD_LOCKDATA* param0);

public function uint32 PDD_SURFCB_UNLOCK(DD_UNLOCKDATA* param0);

public function uint32 PDD_SURFCB_BLT(DD_BLTDATA* param0);

public function uint32 PDD_SURFCB_UPDATEOVERLAY(DD_UPDATEOVERLAYDATA* param0);

public function uint32 PDD_SURFCB_SETOVERLAYPOSITION(DD_SETOVERLAYPOSITIONDATA* param0);

public function uint32 PDD_SURFCB_SETPALETTE(DD_SETPALETTEDATA* param0);

public function uint32 PDD_SURFCB_FLIP(DD_FLIPDATA* param0);

public function uint32 PDD_SURFCB_DESTROYSURFACE(DD_DESTROYSURFACEDATA* param0);

public function uint32 PDD_SURFCB_SETCLIPLIST(DD_SETCLIPLISTDATA* param0);

public function uint32 PDD_SURFCB_ADDATTACHEDSURFACE(DD_ADDATTACHEDSURFACEDATA* param0);

public function uint32 PDD_SURFCB_SETCOLORKEY(DD_SETCOLORKEYDATA* param0);

public function uint32 PDD_SURFCB_GETBLTSTATUS(DD_GETBLTSTATUSDATA* param0);

public function uint32 PDD_SURFCB_GETFLIPSTATUS(DD_GETFLIPSTATUSDATA* param0);

public function uint32 PDD_VPORTCB_CANCREATEVIDEOPORT(DD_CANCREATEVPORTDATA* param0);

public function uint32 PDD_VPORTCB_CREATEVIDEOPORT(DD_CREATEVPORTDATA* param0);

public function uint32 PDD_VPORTCB_FLIP(DD_FLIPVPORTDATA* param0);

public function uint32 PDD_VPORTCB_GETBANDWIDTH(DD_GETVPORTBANDWIDTHDATA* param0);

public function uint32 PDD_VPORTCB_GETINPUTFORMATS(DD_GETVPORTINPUTFORMATDATA* param0);

public function uint32 PDD_VPORTCB_GETOUTPUTFORMATS(DD_GETVPORTOUTPUTFORMATDATA* param0);

public function uint32 PDD_VPORTCB_GETAUTOFLIPSURF(_DD_GETVPORTAUTOFLIPSURFACEDATA* param0);

public function uint32 PDD_VPORTCB_GETFIELD(DD_GETVPORTFIELDDATA* param0);

public function uint32 PDD_VPORTCB_GETLINE(DD_GETVPORTLINEDATA* param0);

public function uint32 PDD_VPORTCB_GETVPORTCONNECT(DD_GETVPORTCONNECTDATA* param0);

public function uint32 PDD_VPORTCB_DESTROYVPORT(DD_DESTROYVPORTDATA* param0);

public function uint32 PDD_VPORTCB_GETFLIPSTATUS(DD_GETVPORTFLIPSTATUSDATA* param0);

public function uint32 PDD_VPORTCB_UPDATE(DD_UPDATEVPORTDATA* param0);

public function uint32 PDD_VPORTCB_WAITFORSYNC(DD_WAITFORVPORTSYNCDATA* param0);

public function uint32 PDD_VPORTCB_GETSIGNALSTATUS(DD_GETVPORTSIGNALDATA* param0);

public function uint32 PDD_VPORTCB_COLORCONTROL(DD_VPORTCOLORDATA* param0);

public function uint32 PDD_COLORCB_COLORCONTROL(DD_COLORCONTROLDATA* param0);

public function uint32 PDD_KERNELCB_SYNCSURFACE(DD_SYNCSURFACEDATA* param0);

public function uint32 PDD_KERNELCB_SYNCVIDEOPORT(DD_SYNCVIDEOPORTDATA* param0);

public function uint32 PDD_MOCOMPCB_GETGUIDS(DD_GETMOCOMPGUIDSDATA* param0);

public function uint32 PDD_MOCOMPCB_GETFORMATS(DD_GETMOCOMPFORMATSDATA* param0);

public function uint32 PDD_MOCOMPCB_CREATE(DD_CREATEMOCOMPDATA* param0);

public function uint32 PDD_MOCOMPCB_GETCOMPBUFFINFO(DD_GETMOCOMPCOMPBUFFDATA* param0);

public function uint32 PDD_MOCOMPCB_GETINTERNALINFO(DD_GETINTERNALMOCOMPDATA* param0);

public function uint32 PDD_MOCOMPCB_BEGINFRAME(DD_BEGINMOCOMPFRAMEDATA* param0);

public function uint32 PDD_MOCOMPCB_ENDFRAME(DD_ENDMOCOMPFRAMEDATA* param0);

public function uint32 PDD_MOCOMPCB_RENDER(DD_RENDERMOCOMPDATA* param0);

public function uint32 PDD_MOCOMPCB_QUERYSTATUS(DD_QUERYMOCOMPSTATUSDATA* param0);

public function uint32 PDD_MOCOMPCB_DESTROY(DD_DESTROYMOCOMPDATA* param0);

public function void PDX_IRQCALLBACK(DX_IRQDATA* pIrqData);

public function uint32 PDX_GETIRQINFO(void* param0, void* param1, DDGETIRQINFO* param2);

public function uint32 PDX_ENABLEIRQ(void* param0, DDENABLEIRQINFO* param1, void* param2);

public function uint32 PDX_SKIPNEXTFIELD(void* param0, DDSKIPNEXTFIELDINFO* param1, void* param2);

public function uint32 PDX_BOBNEXTFIELD(void* param0, DDBOBNEXTFIELDINFO* param1, void* param2);

public function uint32 PDX_SETSTATE(void* param0, DDSETSTATEININFO* param1, DDSETSTATEOUTINFO* param2);

public function uint32 PDX_LOCK(void* param0, DDLOCKININFO* param1, DDLOCKOUTINFO* param2);

public function uint32 PDX_FLIPOVERLAY(void* param0, DDFLIPOVERLAYINFO* param1, void* param2);

public function uint32 PDX_FLIPVIDEOPORT(void* param0, DDFLIPVIDEOPORTINFO* param1, void* param2);

public function uint32 PDX_GETPOLARITY(void* param0, DDGETPOLARITYININFO* param1, DDGETPOLARITYOUTINFO* param2);

public function uint32 PDX_GETCURRENTAUTOFLIP(void* param0, DDGETCURRENTAUTOFLIPININFO* param1, DDGETCURRENTAUTOFLIPOUTINFO* param2);

public function uint32 PDX_GETPREVIOUSAUTOFLIP(void* param0, DDGETPREVIOUSAUTOFLIPININFO* param1, DDGETPREVIOUSAUTOFLIPOUTINFO* param2);

public function uint32 PDX_TRANSFER(void* param0, DDTRANSFERININFO* param1, DDTRANSFEROUTINFO* param2);

public function uint32 PDX_GETTRANSFERSTATUS(void* param0, void* param1, DDGETTRANSFERSTATUSOUTINFO* param2);

#endregion

#region Structs
[CRepr]
public struct _DDFXROP
{
}

[CRepr]
public struct DDARGB
{
	public uint8 blue;
	public uint8 green;
	public uint8 red;
	public uint8 alpha;
}

[CRepr]
public struct DDRGBA
{
	public uint8 red;
	public uint8 green;
	public uint8 blue;
	public uint8 alpha;
}

[CRepr]
public struct DDCOLORKEY
{
	public uint32 dwColorSpaceLowValue;
	public uint32 dwColorSpaceHighValue;
}

[CRepr]
public struct DDBLTFX
{
	[CRepr, Union]
	public struct _Anonymous4_e__Union
	{
		public uint32 dwAlphaSrcConst;
		public IDirectDrawSurface* lpDDSAlphaSrc;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 dwZSrcConst;
		public IDirectDrawSurface* lpDDSZBufferSrc;
	}
	[CRepr, Union]
	public struct _Anonymous5_e__Union
	{
		public uint32 dwFillColor;
		public uint32 dwFillDepth;
		public uint32 dwFillPixel;
		public IDirectDrawSurface* lpDDSPattern;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint32 dwZDestConst;
		public IDirectDrawSurface* lpDDSZBufferDest;
	}
	[CRepr, Union]
	public struct _Anonymous3_e__Union
	{
		public uint32 dwAlphaDestConst;
		public IDirectDrawSurface* lpDDSAlphaDest;
	}
	public uint32 dwSize;
	public uint32 dwDDFX;
	public uint32 dwROP;
	public uint32 dwDDROP;
	public uint32 dwRotationAngle;
	public uint32 dwZBufferOpCode;
	public uint32 dwZBufferLow;
	public uint32 dwZBufferHigh;
	public uint32 dwZBufferBaseDest;
	public uint32 dwZDestConstBitDepth;
	public using _Anonymous1_e__Union Anonymous1;
	public uint32 dwZSrcConstBitDepth;
	public using _Anonymous2_e__Union Anonymous2;
	public uint32 dwAlphaEdgeBlendBitDepth;
	public uint32 dwAlphaEdgeBlend;
	public uint32 dwReserved;
	public uint32 dwAlphaDestConstBitDepth;
	public using _Anonymous3_e__Union Anonymous3;
	public uint32 dwAlphaSrcConstBitDepth;
	public using _Anonymous4_e__Union Anonymous4;
	public using _Anonymous5_e__Union Anonymous5;
	public DDCOLORKEY ddckDestColorkey;
	public DDCOLORKEY ddckSrcColorkey;
}

[CRepr]
public struct DDSCAPS
{
	public uint32 dwCaps;
}

[CRepr]
public struct DDOSCAPS
{
	public uint32 dwCaps;
}

[CRepr]
public struct DDSCAPSEX
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 dwCaps4;
		public uint32 dwVolumeDepth;
	}
	public uint32 dwCaps2;
	public uint32 dwCaps3;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct DDSCAPS2
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 dwCaps4;
		public uint32 dwVolumeDepth;
	}
	public uint32 dwCaps;
	public uint32 dwCaps2;
	public uint32 dwCaps3;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct DDCAPS_DX1
{
	public uint32 dwSize;
	public uint32 dwCaps;
	public uint32 dwCaps2;
	public uint32 dwCKeyCaps;
	public uint32 dwFXCaps;
	public uint32 dwFXAlphaCaps;
	public uint32 dwPalCaps;
	public uint32 dwSVCaps;
	public uint32 dwAlphaBltConstBitDepths;
	public uint32 dwAlphaBltPixelBitDepths;
	public uint32 dwAlphaBltSurfaceBitDepths;
	public uint32 dwAlphaOverlayConstBitDepths;
	public uint32 dwAlphaOverlayPixelBitDepths;
	public uint32 dwAlphaOverlaySurfaceBitDepths;
	public uint32 dwZBufferBitDepths;
	public uint32 dwVidMemTotal;
	public uint32 dwVidMemFree;
	public uint32 dwMaxVisibleOverlays;
	public uint32 dwCurrVisibleOverlays;
	public uint32 dwNumFourCCCodes;
	public uint32 dwAlignBoundarySrc;
	public uint32 dwAlignSizeSrc;
	public uint32 dwAlignBoundaryDest;
	public uint32 dwAlignSizeDest;
	public uint32 dwAlignStrideAlign;
	public uint32[8] dwRops;
	public DDSCAPS ddsCaps;
	public uint32 dwMinOverlayStretch;
	public uint32 dwMaxOverlayStretch;
	public uint32 dwMinLiveVideoStretch;
	public uint32 dwMaxLiveVideoStretch;
	public uint32 dwMinHwCodecStretch;
	public uint32 dwMaxHwCodecStretch;
	public uint32 dwReserved1;
	public uint32 dwReserved2;
	public uint32 dwReserved3;
}

[CRepr]
public struct DDCAPS_DX3
{
	public uint32 dwSize;
	public uint32 dwCaps;
	public uint32 dwCaps2;
	public uint32 dwCKeyCaps;
	public uint32 dwFXCaps;
	public uint32 dwFXAlphaCaps;
	public uint32 dwPalCaps;
	public uint32 dwSVCaps;
	public uint32 dwAlphaBltConstBitDepths;
	public uint32 dwAlphaBltPixelBitDepths;
	public uint32 dwAlphaBltSurfaceBitDepths;
	public uint32 dwAlphaOverlayConstBitDepths;
	public uint32 dwAlphaOverlayPixelBitDepths;
	public uint32 dwAlphaOverlaySurfaceBitDepths;
	public uint32 dwZBufferBitDepths;
	public uint32 dwVidMemTotal;
	public uint32 dwVidMemFree;
	public uint32 dwMaxVisibleOverlays;
	public uint32 dwCurrVisibleOverlays;
	public uint32 dwNumFourCCCodes;
	public uint32 dwAlignBoundarySrc;
	public uint32 dwAlignSizeSrc;
	public uint32 dwAlignBoundaryDest;
	public uint32 dwAlignSizeDest;
	public uint32 dwAlignStrideAlign;
	public uint32[8] dwRops;
	public DDSCAPS ddsCaps;
	public uint32 dwMinOverlayStretch;
	public uint32 dwMaxOverlayStretch;
	public uint32 dwMinLiveVideoStretch;
	public uint32 dwMaxLiveVideoStretch;
	public uint32 dwMinHwCodecStretch;
	public uint32 dwMaxHwCodecStretch;
	public uint32 dwReserved1;
	public uint32 dwReserved2;
	public uint32 dwReserved3;
	public uint32 dwSVBCaps;
	public uint32 dwSVBCKeyCaps;
	public uint32 dwSVBFXCaps;
	public uint32[8] dwSVBRops;
	public uint32 dwVSBCaps;
	public uint32 dwVSBCKeyCaps;
	public uint32 dwVSBFXCaps;
	public uint32[8] dwVSBRops;
	public uint32 dwSSBCaps;
	public uint32 dwSSBCKeyCaps;
	public uint32 dwSSBFXCaps;
	public uint32[8] dwSSBRops;
	public uint32 dwReserved4;
	public uint32 dwReserved5;
	public uint32 dwReserved6;
}

[CRepr]
public struct DDCAPS_DX5
{
	public uint32 dwSize;
	public uint32 dwCaps;
	public uint32 dwCaps2;
	public uint32 dwCKeyCaps;
	public uint32 dwFXCaps;
	public uint32 dwFXAlphaCaps;
	public uint32 dwPalCaps;
	public uint32 dwSVCaps;
	public uint32 dwAlphaBltConstBitDepths;
	public uint32 dwAlphaBltPixelBitDepths;
	public uint32 dwAlphaBltSurfaceBitDepths;
	public uint32 dwAlphaOverlayConstBitDepths;
	public uint32 dwAlphaOverlayPixelBitDepths;
	public uint32 dwAlphaOverlaySurfaceBitDepths;
	public uint32 dwZBufferBitDepths;
	public uint32 dwVidMemTotal;
	public uint32 dwVidMemFree;
	public uint32 dwMaxVisibleOverlays;
	public uint32 dwCurrVisibleOverlays;
	public uint32 dwNumFourCCCodes;
	public uint32 dwAlignBoundarySrc;
	public uint32 dwAlignSizeSrc;
	public uint32 dwAlignBoundaryDest;
	public uint32 dwAlignSizeDest;
	public uint32 dwAlignStrideAlign;
	public uint32[8] dwRops;
	public DDSCAPS ddsCaps;
	public uint32 dwMinOverlayStretch;
	public uint32 dwMaxOverlayStretch;
	public uint32 dwMinLiveVideoStretch;
	public uint32 dwMaxLiveVideoStretch;
	public uint32 dwMinHwCodecStretch;
	public uint32 dwMaxHwCodecStretch;
	public uint32 dwReserved1;
	public uint32 dwReserved2;
	public uint32 dwReserved3;
	public uint32 dwSVBCaps;
	public uint32 dwSVBCKeyCaps;
	public uint32 dwSVBFXCaps;
	public uint32[8] dwSVBRops;
	public uint32 dwVSBCaps;
	public uint32 dwVSBCKeyCaps;
	public uint32 dwVSBFXCaps;
	public uint32[8] dwVSBRops;
	public uint32 dwSSBCaps;
	public uint32 dwSSBCKeyCaps;
	public uint32 dwSSBFXCaps;
	public uint32[8] dwSSBRops;
	public uint32 dwMaxVideoPorts;
	public uint32 dwCurrVideoPorts;
	public uint32 dwSVBCaps2;
	public uint32 dwNLVBCaps;
	public uint32 dwNLVBCaps2;
	public uint32 dwNLVBCKeyCaps;
	public uint32 dwNLVBFXCaps;
	public uint32[8] dwNLVBRops;
}

[CRepr]
public struct DDCAPS_DX6
{
	public uint32 dwSize;
	public uint32 dwCaps;
	public uint32 dwCaps2;
	public uint32 dwCKeyCaps;
	public uint32 dwFXCaps;
	public uint32 dwFXAlphaCaps;
	public uint32 dwPalCaps;
	public uint32 dwSVCaps;
	public uint32 dwAlphaBltConstBitDepths;
	public uint32 dwAlphaBltPixelBitDepths;
	public uint32 dwAlphaBltSurfaceBitDepths;
	public uint32 dwAlphaOverlayConstBitDepths;
	public uint32 dwAlphaOverlayPixelBitDepths;
	public uint32 dwAlphaOverlaySurfaceBitDepths;
	public uint32 dwZBufferBitDepths;
	public uint32 dwVidMemTotal;
	public uint32 dwVidMemFree;
	public uint32 dwMaxVisibleOverlays;
	public uint32 dwCurrVisibleOverlays;
	public uint32 dwNumFourCCCodes;
	public uint32 dwAlignBoundarySrc;
	public uint32 dwAlignSizeSrc;
	public uint32 dwAlignBoundaryDest;
	public uint32 dwAlignSizeDest;
	public uint32 dwAlignStrideAlign;
	public uint32[8] dwRops;
	public DDSCAPS ddsOldCaps;
	public uint32 dwMinOverlayStretch;
	public uint32 dwMaxOverlayStretch;
	public uint32 dwMinLiveVideoStretch;
	public uint32 dwMaxLiveVideoStretch;
	public uint32 dwMinHwCodecStretch;
	public uint32 dwMaxHwCodecStretch;
	public uint32 dwReserved1;
	public uint32 dwReserved2;
	public uint32 dwReserved3;
	public uint32 dwSVBCaps;
	public uint32 dwSVBCKeyCaps;
	public uint32 dwSVBFXCaps;
	public uint32[8] dwSVBRops;
	public uint32 dwVSBCaps;
	public uint32 dwVSBCKeyCaps;
	public uint32 dwVSBFXCaps;
	public uint32[8] dwVSBRops;
	public uint32 dwSSBCaps;
	public uint32 dwSSBCKeyCaps;
	public uint32 dwSSBFXCaps;
	public uint32[8] dwSSBRops;
	public uint32 dwMaxVideoPorts;
	public uint32 dwCurrVideoPorts;
	public uint32 dwSVBCaps2;
	public uint32 dwNLVBCaps;
	public uint32 dwNLVBCaps2;
	public uint32 dwNLVBCKeyCaps;
	public uint32 dwNLVBFXCaps;
	public uint32[8] dwNLVBRops;
	public DDSCAPS2 ddsCaps;
}

[CRepr]
public struct DDCAPS_DX7
{
	public uint32 dwSize;
	public uint32 dwCaps;
	public uint32 dwCaps2;
	public uint32 dwCKeyCaps;
	public uint32 dwFXCaps;
	public uint32 dwFXAlphaCaps;
	public uint32 dwPalCaps;
	public uint32 dwSVCaps;
	public uint32 dwAlphaBltConstBitDepths;
	public uint32 dwAlphaBltPixelBitDepths;
	public uint32 dwAlphaBltSurfaceBitDepths;
	public uint32 dwAlphaOverlayConstBitDepths;
	public uint32 dwAlphaOverlayPixelBitDepths;
	public uint32 dwAlphaOverlaySurfaceBitDepths;
	public uint32 dwZBufferBitDepths;
	public uint32 dwVidMemTotal;
	public uint32 dwVidMemFree;
	public uint32 dwMaxVisibleOverlays;
	public uint32 dwCurrVisibleOverlays;
	public uint32 dwNumFourCCCodes;
	public uint32 dwAlignBoundarySrc;
	public uint32 dwAlignSizeSrc;
	public uint32 dwAlignBoundaryDest;
	public uint32 dwAlignSizeDest;
	public uint32 dwAlignStrideAlign;
	public uint32[8] dwRops;
	public DDSCAPS ddsOldCaps;
	public uint32 dwMinOverlayStretch;
	public uint32 dwMaxOverlayStretch;
	public uint32 dwMinLiveVideoStretch;
	public uint32 dwMaxLiveVideoStretch;
	public uint32 dwMinHwCodecStretch;
	public uint32 dwMaxHwCodecStretch;
	public uint32 dwReserved1;
	public uint32 dwReserved2;
	public uint32 dwReserved3;
	public uint32 dwSVBCaps;
	public uint32 dwSVBCKeyCaps;
	public uint32 dwSVBFXCaps;
	public uint32[8] dwSVBRops;
	public uint32 dwVSBCaps;
	public uint32 dwVSBCKeyCaps;
	public uint32 dwVSBFXCaps;
	public uint32[8] dwVSBRops;
	public uint32 dwSSBCaps;
	public uint32 dwSSBCKeyCaps;
	public uint32 dwSSBFXCaps;
	public uint32[8] dwSSBRops;
	public uint32 dwMaxVideoPorts;
	public uint32 dwCurrVideoPorts;
	public uint32 dwSVBCaps2;
	public uint32 dwNLVBCaps;
	public uint32 dwNLVBCaps2;
	public uint32 dwNLVBCKeyCaps;
	public uint32 dwNLVBFXCaps;
	public uint32[8] dwNLVBRops;
	public DDSCAPS2 ddsCaps;
}

[CRepr]
public struct DDPIXELFORMAT
{
	[CRepr, Union]
	public struct _Anonymous5_e__Union
	{
		public uint32 dwRGBAlphaBitMask;
		public uint32 dwYUVAlphaBitMask;
		public uint32 dwLuminanceAlphaBitMask;
		public uint32 dwRGBZBitMask;
		public uint32 dwYUVZBitMask;
	}
	[CRepr, Union]
	public struct _Anonymous3_e__Union
	{
		[CRepr]
		public struct _MultiSampleCaps_e__Struct
		{
			public uint16 wFlipMSTypes;
			public uint16 wBltMSTypes;
		}
		public uint32 dwGBitMask;
		public uint32 dwUBitMask;
		public uint32 dwZBitMask;
		public uint32 dwBumpDvBitMask;
		public _MultiSampleCaps_e__Struct MultiSampleCaps;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint32 dwRGBBitCount;
		public uint32 dwYUVBitCount;
		public uint32 dwZBufferBitDepth;
		public uint32 dwAlphaBitDepth;
		public uint32 dwLuminanceBitCount;
		public uint32 dwBumpBitCount;
		public uint32 dwPrivateFormatBitCount;
	}
	[CRepr, Union]
	public struct _Anonymous4_e__Union
	{
		public uint32 dwBBitMask;
		public uint32 dwVBitMask;
		public uint32 dwStencilBitMask;
		public uint32 dwBumpLuminanceBitMask;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 dwRBitMask;
		public uint32 dwYBitMask;
		public uint32 dwStencilBitDepth;
		public uint32 dwLuminanceBitMask;
		public uint32 dwBumpDuBitMask;
		public uint32 dwOperations;
	}
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwFourCC;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public using _Anonymous3_e__Union Anonymous3;
	public using _Anonymous4_e__Union Anonymous4;
	public using _Anonymous5_e__Union Anonymous5;
}

[CRepr]
public struct DDOVERLAYFX
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 dwAlphaSrcConst;
		public IDirectDrawSurface* lpDDSAlphaSrc;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint32 dwAlphaDestConst;
		public IDirectDrawSurface* lpDDSAlphaDest;
	}
	public uint32 dwSize;
	public uint32 dwAlphaEdgeBlendBitDepth;
	public uint32 dwAlphaEdgeBlend;
	public uint32 dwReserved;
	public uint32 dwAlphaDestConstBitDepth;
	public using _Anonymous1_e__Union Anonymous1;
	public uint32 dwAlphaSrcConstBitDepth;
	public using _Anonymous2_e__Union Anonymous2;
	public DDCOLORKEY dckDestColorkey;
	public DDCOLORKEY dckSrcColorkey;
	public uint32 dwDDFX;
	public uint32 dwFlags;
}

[CRepr]
public struct DDBLTBATCH
{
	public RECT* lprDest;
	public IDirectDrawSurface* lpDDSSrc;
	public RECT* lprSrc;
	public uint32 dwFlags;
	public DDBLTFX* lpDDBltFx;
}

[CRepr]
public struct DDGAMMARAMP
{
	public uint16[256] red;
	public uint16[256] green;
	public uint16[256] blue;
}

[CRepr]
public struct DDDEVICEIDENTIFIER
{
	public CHAR[512] szDriver;
	public CHAR[512] szDescription;
	public LARGE_INTEGER liDriverVersion;
	public uint32 dwVendorId;
	public uint32 dwDeviceId;
	public uint32 dwSubSysId;
	public uint32 dwRevision;
	public Guid guidDeviceIdentifier;
}

[CRepr]
public struct DDDEVICEIDENTIFIER2
{
	public CHAR[512] szDriver;
	public CHAR[512] szDescription;
	public LARGE_INTEGER liDriverVersion;
	public uint32 dwVendorId;
	public uint32 dwDeviceId;
	public uint32 dwSubSysId;
	public uint32 dwRevision;
	public Guid guidDeviceIdentifier;
	public uint32 dwWHQLLevel;
}

[CRepr]
public struct DDSURFACEDESC
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 dwMipMapCount;
		public uint32 dwZBufferBitDepth;
		public uint32 dwRefreshRate;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public int32 lPitch;
		public uint32 dwLinearSize;
	}
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwHeight;
	public uint32 dwWidth;
	public using _Anonymous1_e__Union Anonymous1;
	public uint32 dwBackBufferCount;
	public using _Anonymous2_e__Union Anonymous2;
	public uint32 dwAlphaBitDepth;
	public uint32 dwReserved;
	public void* lpSurface;
	public DDCOLORKEY ddckCKDestOverlay;
	public DDCOLORKEY ddckCKDestBlt;
	public DDCOLORKEY ddckCKSrcOverlay;
	public DDCOLORKEY ddckCKSrcBlt;
	public DDPIXELFORMAT ddpfPixelFormat;
	public DDSCAPS ddsCaps;
}

[CRepr]
public struct DDSURFACEDESC2
{
	[CRepr, Union]
	public struct _Anonymous4_e__Union
	{
		public DDCOLORKEY ddckCKDestOverlay;
		public uint32 dwEmptyFaceColor;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public uint32 dwBackBufferCount;
		public uint32 dwDepth;
	}
	[CRepr, Union]
	public struct _Anonymous3_e__Union
	{
		public uint32 dwMipMapCount;
		public uint32 dwRefreshRate;
		public uint32 dwSrcVBHandle;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public int32 lPitch;
		public uint32 dwLinearSize;
	}
	[CRepr, Union]
	public struct _Anonymous5_e__Union
	{
		public DDPIXELFORMAT ddpfPixelFormat;
		public uint32 dwFVF;
	}
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwHeight;
	public uint32 dwWidth;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public using _Anonymous3_e__Union Anonymous3;
	public uint32 dwAlphaBitDepth;
	public uint32 dwReserved;
	public void* lpSurface;
	public using _Anonymous4_e__Union Anonymous4;
	public DDCOLORKEY ddckCKDestBlt;
	public DDCOLORKEY ddckCKSrcOverlay;
	public DDCOLORKEY ddckCKSrcBlt;
	public using _Anonymous5_e__Union Anonymous5;
	public DDSCAPS2 ddsCaps;
	public uint32 dwTextureStage;
}

[CRepr]
public struct DDOPTSURFACEDESC
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public DDSCAPS2 ddSCaps;
	public DDOSCAPS ddOSCaps;
	public Guid guid;
	public uint32 dwCompressionRatio;
}

[CRepr]
public struct DDCOLORCONTROL
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public int32 lBrightness;
	public int32 lContrast;
	public int32 lHue;
	public int32 lSaturation;
	public int32 lSharpness;
	public int32 lGamma;
	public int32 lColorEnable;
	public uint32 dwReserved1;
}

[CRepr]
public struct DDVIDEOPORTCONNECT
{
	public uint32 dwSize;
	public uint32 dwPortWidth;
	public Guid guidTypeID;
	public uint32 dwFlags;
	public uint dwReserved1;
}

[CRepr]
public struct DDVIDEOPORTCAPS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwMaxWidth;
	public uint32 dwMaxVBIWidth;
	public uint32 dwMaxHeight;
	public uint32 dwVideoPortID;
	public uint32 dwCaps;
	public uint32 dwFX;
	public uint32 dwNumAutoFlipSurfaces;
	public uint32 dwAlignVideoPortBoundary;
	public uint32 dwAlignVideoPortPrescaleWidth;
	public uint32 dwAlignVideoPortCropBoundary;
	public uint32 dwAlignVideoPortCropWidth;
	public uint32 dwPreshrinkXStep;
	public uint32 dwPreshrinkYStep;
	public uint32 dwNumVBIAutoFlipSurfaces;
	public uint32 dwNumPreferredAutoflip;
	public uint16 wNumFilterTapsX;
	public uint16 wNumFilterTapsY;
}

[CRepr]
public struct DDVIDEOPORTDESC
{
	public uint32 dwSize;
	public uint32 dwFieldWidth;
	public uint32 dwVBIWidth;
	public uint32 dwFieldHeight;
	public uint32 dwMicrosecondsPerField;
	public uint32 dwMaxPixelsPerSecond;
	public uint32 dwVideoPortID;
	public uint32 dwReserved1;
	public DDVIDEOPORTCONNECT VideoPortType;
	public uint dwReserved2;
	public uint dwReserved3;
}

[CRepr]
public struct DDVIDEOPORTINFO
{
	public uint32 dwSize;
	public uint32 dwOriginX;
	public uint32 dwOriginY;
	public uint32 dwVPFlags;
	public RECT rCrop;
	public uint32 dwPrescaleWidth;
	public uint32 dwPrescaleHeight;
	public DDPIXELFORMAT* lpddpfInputFormat;
	public DDPIXELFORMAT* lpddpfVBIInputFormat;
	public DDPIXELFORMAT* lpddpfVBIOutputFormat;
	public uint32 dwVBIHeight;
	public uint dwReserved1;
	public uint dwReserved2;
}

[CRepr]
public struct DDVIDEOPORTBANDWIDTH
{
	public uint32 dwSize;
	public uint32 dwCaps;
	public uint32 dwOverlay;
	public uint32 dwColorkey;
	public uint32 dwYInterpolate;
	public uint32 dwYInterpAndColorkey;
	public uint dwReserved1;
	public uint dwReserved2;
}

[CRepr]
public struct DDVIDEOPORTSTATUS
{
	public uint32 dwSize;
	public BOOL bInUse;
	public uint32 dwFlags;
	public uint32 dwReserved1;
	public DDVIDEOPORTCONNECT VideoPortType;
	public uint dwReserved2;
	public uint dwReserved3;
}

[CRepr]
public struct DDVIDEOPORTNOTIFY
{
	public LARGE_INTEGER ApproximateTimeStamp;
	public int32 lField;
	public uint32 dwSurfaceIndex;
	public int32 lDone;
}

[CRepr]
public struct DDKERNELCAPS
{
	public uint32 dwSize;
	public uint32 dwCaps;
	public uint32 dwIRQCaps;
}

[CRepr]
public struct SURFACEALIGNMENT
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Linear_e__Struct
		{
			public uint32 dwStartAlignment;
			public uint32 dwPitchAlignment;
			public uint32 dwFlags;
			public uint32 dwReserved2;
		}
		[CRepr]
		public struct _Rectangular_e__Struct
		{
			public uint32 dwXAlignment;
			public uint32 dwYAlignment;
			public uint32 dwFlags;
			public uint32 dwReserved2;
		}
		public _Linear_e__Struct Linear;
		public _Rectangular_e__Struct Rectangular;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct HEAPALIGNMENT
{
	public uint32 dwSize;
	public DDSCAPS ddsCaps;
	public uint32 dwReserved;
	public SURFACEALIGNMENT ExecuteBuffer;
	public SURFACEALIGNMENT Overlay;
	public SURFACEALIGNMENT Texture;
	public SURFACEALIGNMENT ZBuffer;
	public SURFACEALIGNMENT AlphaBuffer;
	public SURFACEALIGNMENT Offscreen;
	public SURFACEALIGNMENT FlipTarget;
}

[CRepr]
public struct DD_GETHEAPALIGNMENTDATA
{
	public uint dwInstance;
	public uint32 dwHeap;
	public HRESULT ddRVal;
	public void* GetHeapAlignment;
	public HEAPALIGNMENT Alignment;
}

[CRepr]
public struct VMEML
{
	public VMEML* next;
	public uint ptr;
	public uint32 size;
	public BOOL bDiscardable;
}

[CRepr]
public struct VMEMR
{
	public VMEMR* next;
	public VMEMR* prev;
	public VMEMR* pUp;
	public VMEMR* pDown;
	public VMEMR* pLeft;
	public VMEMR* pRight;
	public uint ptr;
	public uint32 size;
	public uint32 x;
	public uint32 y;
	public uint32 cx;
	public uint32 cy;
	public uint32 flags;
	public uint pBits;
	public BOOL bDiscardable;
}

[CRepr]
public struct VMEMHEAP
{
	public uint32 dwFlags;
	public uint32 stride;
	public void* freeList;
	public void* allocList;
	public uint32 dwTotalSize;
	public uint fpGARTLin;
	public uint fpGARTDev;
	public uint32 dwCommitedSize;
	public uint32 dwCoalesceCount;
	public HEAPALIGNMENT Alignment;
	public DDSCAPSEX ddsCapsEx;
	public DDSCAPSEX ddsCapsExAlt;
	public LARGE_INTEGER liPhysAGPBase;
	public HANDLE hdevAGP;
	public void* pvPhysRsrv;
	public uint8* pAgpCommitMask;
	public uint32 dwAgpCommitMaskSize;
}

[CRepr]
public struct PROCESS_LIST
{
	public PROCESS_LIST* lpLink;
	public uint32 dwProcessId;
	public uint32 dwRefCnt;
	public uint32 dwAlphaDepth;
	public uint32 dwZDepth;
}

[CRepr]
public struct DDMONITORINFO
{
	public uint16 Manufacturer;
	public uint16 Product;
	public uint32 SerialNumber;
	public Guid DeviceIdentifier;
	public int32 Mode640x480;
	public int32 Mode800x600;
	public int32 Mode1024x768;
	public int32 Mode1280x1024;
	public int32 Mode1600x1200;
	public int32 ModeReserved1;
	public int32 ModeReserved2;
	public int32 ModeReserved3;
}

[CRepr]
public struct DD32BITDRIVERDATA
{
	public CHAR[260] szName;
	public CHAR[64] szEntryPoint;
	public uint32 dwContext;
}

[CRepr]
public struct DDVERSIONDATA
{
	public uint32 dwHALVersion;
	public uint dwReserved1;
	public uint dwReserved2;
}

[CRepr]
public struct VIDMEM
{
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint fpEnd;
		public uint32 dwWidth;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public VMEMHEAP* lpHeap;
		public uint32 dwHeight;
	}
	public uint32 dwFlags;
	public uint fpStart;
	public using _Anonymous1_e__Union Anonymous1;
	public DDSCAPS ddsCaps;
	public DDSCAPS ddsCapsAlt;
	public using _Anonymous2_e__Union Anonymous2;
}

[CRepr]
public struct VIDMEMINFO
{
	public uint fpPrimary;
	public uint32 dwFlags;
	public uint32 dwDisplayWidth;
	public uint32 dwDisplayHeight;
	public int32 lDisplayPitch;
	public DDPIXELFORMAT ddpfDisplay;
	public uint32 dwOffscreenAlign;
	public uint32 dwOverlayAlign;
	public uint32 dwTextureAlign;
	public uint32 dwZBufferAlign;
	public uint32 dwAlphaAlign;
	public uint32 dwNumHeaps;
	public VIDMEM* pvmList;
}

[CRepr]
public struct HEAPALIAS
{
	public uint fpVidMem;
	public void* lpAlias;
	public uint32 dwAliasSize;
}

[CRepr]
public struct HEAPALIASINFO
{
	public uint32 dwRefCnt;
	public uint32 dwFlags;
	public uint32 dwNumHeaps;
	public HEAPALIAS* lpAliases;
}

[CRepr]
public struct IUNKNOWN_LIST
{
	public IUNKNOWN_LIST* lpLink;
	public Guid* lpGuid;
	public IUnknown* lpIUnknown;
}

[CRepr]
public struct DDHAL_DDCALLBACKS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public LPDDHAL_DESTROYDRIVER DestroyDriver;
	public LPDDHAL_CREATESURFACE CreateSurface;
	public LPDDHAL_SETCOLORKEY SetColorKey;
	public LPDDHAL_SETMODE SetMode;
	public LPDDHAL_WAITFORVERTICALBLANK WaitForVerticalBlank;
	public LPDDHAL_CANCREATESURFACE CanCreateSurface;
	public LPDDHAL_CREATEPALETTE CreatePalette;
	public LPDDHAL_GETSCANLINE GetScanLine;
	public LPDDHAL_SETEXCLUSIVEMODE SetExclusiveMode;
	public LPDDHAL_FLIPTOGDISURFACE FlipToGDISurface;
}

[CRepr]
public struct DDHAL_DDPALETTECALLBACKS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public LPDDHALPALCB_DESTROYPALETTE DestroyPalette;
	public LPDDHALPALCB_SETENTRIES SetEntries;
}

[CRepr]
public struct DDHAL_DDSURFACECALLBACKS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public LPDDHALSURFCB_DESTROYSURFACE DestroySurface;
	public LPDDHALSURFCB_FLIP Flip;
	public LPDDHALSURFCB_SETCLIPLIST SetClipList;
	public LPDDHALSURFCB_LOCK Lock;
	public LPDDHALSURFCB_UNLOCK Unlock;
	public LPDDHALSURFCB_BLT Blt;
	public LPDDHALSURFCB_SETCOLORKEY SetColorKey;
	public LPDDHALSURFCB_ADDATTACHEDSURFACE AddAttachedSurface;
	public LPDDHALSURFCB_GETBLTSTATUS GetBltStatus;
	public LPDDHALSURFCB_GETFLIPSTATUS GetFlipStatus;
	public LPDDHALSURFCB_UPDATEOVERLAY UpdateOverlay;
	public LPDDHALSURFCB_SETOVERLAYPOSITION SetOverlayPosition;
	public void* reserved4;
	public LPDDHALSURFCB_SETPALETTE SetPalette;
}

[CRepr]
public struct DDHAL_DDMISCELLANEOUSCALLBACKS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public LPDDHAL_GETAVAILDRIVERMEMORY GetAvailDriverMemory;
	public LPDDHAL_UPDATENONLOCALHEAP UpdateNonLocalHeap;
	public LPDDHAL_GETHEAPALIGNMENT GetHeapAlignment;
	public LPDDHALSURFCB_GETBLTSTATUS GetSysmemBltStatus;
}

[CRepr]
public struct DDHAL_DDMISCELLANEOUS2CALLBACKS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public void* Reserved;
	public LPDDHAL_CREATESURFACEEX CreateSurfaceEx;
	public LPDDHAL_GETDRIVERSTATE GetDriverState;
	public LPDDHAL_DESTROYDDLOCAL DestroyDDLocal;
}

[CRepr]
public struct DDHAL_DDEXEBUFCALLBACKS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public LPDDHALEXEBUFCB_CANCREATEEXEBUF CanCreateExecuteBuffer;
	public LPDDHALEXEBUFCB_CREATEEXEBUF CreateExecuteBuffer;
	public LPDDHALEXEBUFCB_DESTROYEXEBUF DestroyExecuteBuffer;
	public LPDDHALEXEBUFCB_LOCKEXEBUF LockExecuteBuffer;
	public LPDDHALEXEBUFCB_UNLOCKEXEBUF UnlockExecuteBuffer;
}

[CRepr]
public struct DDHAL_DDVIDEOPORTCALLBACKS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public LPDDHALVPORTCB_CANCREATEVIDEOPORT CanCreateVideoPort;
	public LPDDHALVPORTCB_CREATEVIDEOPORT CreateVideoPort;
	public LPDDHALVPORTCB_FLIP FlipVideoPort;
	public LPDDHALVPORTCB_GETBANDWIDTH GetVideoPortBandwidth;
	public LPDDHALVPORTCB_GETINPUTFORMATS GetVideoPortInputFormats;
	public LPDDHALVPORTCB_GETOUTPUTFORMATS GetVideoPortOutputFormats;
	public void* lpReserved1;
	public LPDDHALVPORTCB_GETFIELD GetVideoPortField;
	public LPDDHALVPORTCB_GETLINE GetVideoPortLine;
	public LPDDHALVPORTCB_GETVPORTCONNECT GetVideoPortConnectInfo;
	public LPDDHALVPORTCB_DESTROYVPORT DestroyVideoPort;
	public LPDDHALVPORTCB_GETFLIPSTATUS GetVideoPortFlipStatus;
	public LPDDHALVPORTCB_UPDATE UpdateVideoPort;
	public LPDDHALVPORTCB_WAITFORSYNC WaitForVideoPortSync;
	public LPDDHALVPORTCB_GETSIGNALSTATUS GetVideoSignalStatus;
	public LPDDHALVPORTCB_COLORCONTROL ColorControl;
}

[CRepr]
public struct DDHAL_DDCOLORCONTROLCALLBACKS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public LPDDHALCOLORCB_COLORCONTROL ColorControl;
}

[CRepr]
public struct DDHAL_DDKERNELCALLBACKS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public LPDDHALKERNELCB_SYNCSURFACE SyncSurfaceData;
	public LPDDHALKERNELCB_SYNCVIDEOPORT SyncVideoPortData;
}

[CRepr]
public struct DDHAL_DDMOTIONCOMPCALLBACKS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public LPDDHALMOCOMPCB_GETGUIDS GetMoCompGuids;
	public LPDDHALMOCOMPCB_GETFORMATS GetMoCompFormats;
	public LPDDHALMOCOMPCB_CREATE CreateMoComp;
	public LPDDHALMOCOMPCB_GETCOMPBUFFINFO GetMoCompBuffInfo;
	public LPDDHALMOCOMPCB_GETINTERNALINFO GetInternalMoCompInfo;
	public LPDDHALMOCOMPCB_BEGINFRAME BeginMoCompFrame;
	public LPDDHALMOCOMPCB_ENDFRAME EndMoCompFrame;
	public LPDDHALMOCOMPCB_RENDER RenderMoComp;
	public LPDDHALMOCOMPCB_QUERYSTATUS QueryMoCompStatus;
	public LPDDHALMOCOMPCB_DESTROY DestroyMoComp;
}

[CRepr]
public struct DDNONLOCALVIDMEMCAPS
{
	public uint32 dwSize;
	public uint32 dwNLVBCaps;
	public uint32 dwNLVBCaps2;
	public uint32 dwNLVBCKeyCaps;
	public uint32 dwNLVBFXCaps;
	public uint32[8] dwNLVBRops;
}

[CRepr]
public struct DDMORESURFACECAPS
{
	[CRepr]
	public struct ExtendedHeapRestrictions
	{
		public DDSCAPSEX ddsCapsEx;
		public DDSCAPSEX ddsCapsExAlt;
	}
	public uint32 dwSize;
	public DDSCAPSEX ddsCapsMore;
	public ExtendedHeapRestrictions* ddsExtendedHeapRestrictions mut => &ddsExtendedHeapRestrictions_impl;
	private ExtendedHeapRestrictions[ANYSIZE_ARRAY] ddsExtendedHeapRestrictions_impl;
}

[CRepr]
public struct DDSTEREOMODE
{
	public uint32 dwSize;
	public uint32 dwHeight;
	public uint32 dwWidth;
	public uint32 dwBpp;
	public uint32 dwRefreshRate;
	public BOOL bSupported;
}

[CRepr]
public struct DDRAWI_DDRAWPALETTE_INT
{
	public void* lpVtbl;
	public DDRAWI_DDRAWPALETTE_LCL* lpLcl;
	public DDRAWI_DDRAWPALETTE_INT* lpLink;
	public uint32 dwIntRefCnt;
}

[CRepr]
public struct DDRAWI_DDRAWPALETTE_GBL
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint dwReserved1;
		public HPALETTE hHELGDIPalette;
	}
	public uint32 dwRefCnt;
	public uint32 dwFlags;
	public DDRAWI_DIRECTDRAW_LCL* lpDD_lcl;
	public uint32 dwProcessId;
	public PALETTEENTRY* lpColorTable;
	public using _Anonymous_e__Union Anonymous;
	public uint32 dwDriverReserved;
	public uint32 dwContentsStamp;
	public uint32 dwSaveStamp;
	public uint32 dwHandle;
}

[CRepr]
public struct DDRAWI_DDRAWPALETTE_LCL
{
	public uint32 lpPalMore;
	public DDRAWI_DDRAWPALETTE_GBL* lpGbl;
	public uint dwUnused0;
	public uint32 dwLocalRefCnt;
	public IUnknown* pUnkOuter;
	public DDRAWI_DIRECTDRAW_LCL* lpDD_lcl;
	public uint dwReserved1;
	public uint dwDDRAWReserved1;
	public uint dwDDRAWReserved2;
	public uint dwDDRAWReserved3;
}

[CRepr]
public struct DDRAWI_DDRAWCLIPPER_INT
{
	public void* lpVtbl;
	public DDRAWI_DDRAWCLIPPER_LCL* lpLcl;
	public DDRAWI_DDRAWCLIPPER_INT* lpLink;
	public uint32 dwIntRefCnt;
}

[CRepr]
public struct DDRAWI_DDRAWCLIPPER_GBL
{
	public uint32 dwRefCnt;
	public uint32 dwFlags;
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public uint32 dwProcessId;
	public uint dwReserved1;
	public uint hWnd;
	public RGNDATA* lpStaticClipList;
}

[CRepr]
public struct DDRAWI_DDRAWCLIPPER_LCL
{
	public uint32 lpClipMore;
	public DDRAWI_DDRAWCLIPPER_GBL* lpGbl;
	public DDRAWI_DIRECTDRAW_LCL* lpDD_lcl;
	public uint32 dwLocalRefCnt;
	public IUnknown* pUnkOuter;
	public DDRAWI_DIRECTDRAW_INT* lpDD_int;
	public uint dwReserved1;
	public IUnknown* pAddrefedThisOwner;
}

[CRepr]
public struct ATTACHLIST
{
	public uint32 dwFlags;
	public ATTACHLIST* lpLink;
	public DDRAWI_DDRAWSURFACE_LCL* lpAttached;
	public DDRAWI_DDRAWSURFACE_INT* lpIAttached;
}

[CRepr]
public struct DBLNODE
{
	public DBLNODE* next;
	public DBLNODE* prev;
	public DDRAWI_DDRAWSURFACE_LCL* object;
	public DDRAWI_DDRAWSURFACE_INT* object_int;
}

[CRepr]
public struct ACCESSRECTLIST
{
	public ACCESSRECTLIST* lpLink;
	public RECT rDest;
	public DDRAWI_DIRECTDRAW_LCL* lpOwner;
	public void* lpSurfaceData;
	public uint32 dwFlags;
	public HEAPALIASINFO* lpHeapAliasInfo;
}

[CRepr]
public struct DDRAWI_DDRAWSURFACE_INT
{
	public void* lpVtbl;
	public DDRAWI_DDRAWSURFACE_LCL* lpLcl;
	public DDRAWI_DDRAWSURFACE_INT* lpLink;
	public uint32 dwIntRefCnt;
}

[CRepr]
public struct DDRAWI_DDRAWSURFACE_GBL
{
	[CRepr, Union]
	public struct _Anonymous3_e__Union
	{
		public DDRAWI_DIRECTDRAW_GBL* lpDD;
		public void* lpDDHandle;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public ACCESSRECTLIST* lpRectList;
		public uint32 dwBlockSizeY;
		public int32 lSlicePitch;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public VMEMHEAP* lpVidMemHeap;
		public uint32 dwBlockSizeX;
	}
	[CRepr, Union]
	public struct _Anonymous4_e__Union
	{
		public int32 lPitch;
		public uint32 dwLinearSize;
	}
	public uint32 dwRefCnt;
	public uint32 dwGlobalFlags;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public using _Anonymous3_e__Union Anonymous3;
	public uint fpVidMem;
	public using _Anonymous4_e__Union Anonymous4;
	public uint16 wHeight;
	public uint16 wWidth;
	public uint32 dwUsageCount;
	public uint dwReserved1;
	public DDPIXELFORMAT ddpfSurface;
}

[CRepr]
public struct DDRAWI_DDRAWSURFACE_GBL_MORE
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 dwPhysicalPageTable;
		public uint fpPhysicalVidMem;
	}
	public uint32 dwSize;
	public using _Anonymous_e__Union Anonymous;
	public uint32* pPageTable;
	public uint32 cPages;
	public uint dwSavedDCContext;
	public uint fpAliasedVidMem;
	public uint dwDriverReserved;
	public uint dwHELReserved;
	public uint32 cPageUnlocks;
	public uint hKernelSurface;
	public uint32 dwKernelRefCnt;
	public DDCOLORCONTROL* lpColorInfo;
	public uint fpNTAlias;
	public uint32 dwContentsStamp;
	public void* lpvUnswappedDriverReserved;
	public void* lpDDRAWReserved2;
	public uint32 dwDDRAWReserved1;
	public uint32 dwDDRAWReserved2;
	public uint fpAliasOfVidMem;
}

[CRepr]
public struct DDRAWI_DDRAWSURFACE_MORE
{
	public uint32 dwSize;
	public IUNKNOWN_LIST* lpIUnknowns;
	public DDRAWI_DIRECTDRAW_LCL* lpDD_lcl;
	public uint32 dwPageLockCount;
	public uint32 dwBytesAllocated;
	public DDRAWI_DIRECTDRAW_INT* lpDD_int;
	public uint32 dwMipMapCount;
	public DDRAWI_DDRAWCLIPPER_INT* lpDDIClipper;
	public HEAPALIASINFO* lpHeapAliasInfo;
	public uint32 dwOverlayFlags;
	public void* rgjunc;
	public DDRAWI_DDVIDEOPORT_LCL* lpVideoPort;
	public DDOVERLAYFX* lpddOverlayFX;
	public DDSCAPSEX ddsCapsEx;
	public uint32 dwTextureStage;
	public void* lpDDRAWReserved;
	public void* lpDDRAWReserved2;
	public void* lpDDrawReserved3;
	public uint32 dwDDrawReserved4;
	public void* lpDDrawReserved5;
	public uint32* lpGammaRamp;
	public uint32* lpOriginalGammaRamp;
	public void* lpDDrawReserved6;
	public uint32 dwSurfaceHandle;
	public uint32[2] qwDDrawReserved8;
	public void* lpDDrawReserved9;
	public uint32 cSurfaces;
	public DDSURFACEDESC2* pCreatedDDSurfaceDesc2;
	public DDRAWI_DDRAWSURFACE_LCL** slist;
	public uint32 dwFVF;
	public void* lpVB;
}

[CRepr]
public struct DDRAWI_DDRAWSURFACE_LCL
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public DDRAWI_DDRAWCLIPPER_LCL* lpDDClipper;
		public DDRAWI_DDRAWCLIPPER_INT* lp16DDClipper;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public DDRAWI_DDRAWPALETTE_INT* lpDDPalette;
		public DDRAWI_DDRAWPALETTE_INT* lp16DDPalette;
	}
	public DDRAWI_DDRAWSURFACE_MORE* lpSurfMore;
	public DDRAWI_DDRAWSURFACE_GBL* lpGbl;
	public uint hDDSurface;
	public ATTACHLIST* lpAttachList;
	public ATTACHLIST* lpAttachListFrom;
	public uint32 dwLocalRefCnt;
	public uint32 dwProcessId;
	public uint32 dwFlags;
	public DDSCAPS ddsCaps;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public uint32 dwModeCreatedIn;
	public uint32 dwBackBufferCount;
	public DDCOLORKEY ddckCKDestBlt;
	public DDCOLORKEY ddckCKSrcBlt;
	public uint hDC;
	public uint dwReserved1;
	public DDCOLORKEY ddckCKSrcOverlay;
	public DDCOLORKEY ddckCKDestOverlay;
	public DDRAWI_DDRAWSURFACE_INT* lpSurfaceOverlaying;
	public DBLNODE dbnOverlayNode;
	public RECT rcOverlaySrc;
	public RECT rcOverlayDest;
	public uint32 dwClrXparent;
	public uint32 dwAlpha;
	public int32 lOverlayX;
	public int32 lOverlayY;
}

[CRepr]
public struct DDHALMODEINFO
{
	public uint32 dwWidth;
	public uint32 dwHeight;
	public int32 lPitch;
	public uint32 dwBPP;
	public uint16 wFlags;
	public uint16 wRefreshRate;
	public uint32 dwRBitMask;
	public uint32 dwGBitMask;
	public uint32 dwBBitMask;
	public uint32 dwAlphaBitMask;
}

[CRepr]
public struct DDRAWI_DIRECTDRAW_INT
{
	public void* lpVtbl;
	public DDRAWI_DIRECTDRAW_LCL* lpLcl;
	public DDRAWI_DIRECTDRAW_INT* lpLink;
	public uint32 dwIntRefCnt;
}

[CRepr]
public struct DDHAL_CALLBACKS
{
	public DDHAL_DDCALLBACKS cbDDCallbacks;
	public DDHAL_DDSURFACECALLBACKS cbDDSurfaceCallbacks;
	public DDHAL_DDPALETTECALLBACKS cbDDPaletteCallbacks;
	public DDHAL_DDCALLBACKS HALDD;
	public DDHAL_DDSURFACECALLBACKS HALDDSurface;
	public DDHAL_DDPALETTECALLBACKS HALDDPalette;
	public DDHAL_DDCALLBACKS HELDD;
	public DDHAL_DDSURFACECALLBACKS HELDDSurface;
	public DDHAL_DDPALETTECALLBACKS HELDDPalette;
	public DDHAL_DDEXEBUFCALLBACKS cbDDExeBufCallbacks;
	public DDHAL_DDEXEBUFCALLBACKS HALDDExeBuf;
	public DDHAL_DDEXEBUFCALLBACKS HELDDExeBuf;
	public DDHAL_DDVIDEOPORTCALLBACKS cbDDVideoPortCallbacks;
	public DDHAL_DDVIDEOPORTCALLBACKS HALDDVideoPort;
	public DDHAL_DDCOLORCONTROLCALLBACKS cbDDColorControlCallbacks;
	public DDHAL_DDCOLORCONTROLCALLBACKS HALDDColorControl;
	public DDHAL_DDMISCELLANEOUSCALLBACKS cbDDMiscellaneousCallbacks;
	public DDHAL_DDMISCELLANEOUSCALLBACKS HALDDMiscellaneous;
	public DDHAL_DDKERNELCALLBACKS cbDDKernelCallbacks;
	public DDHAL_DDKERNELCALLBACKS HALDDKernel;
	public DDHAL_DDMOTIONCOMPCALLBACKS cbDDMotionCompCallbacks;
	public DDHAL_DDMOTIONCOMPCALLBACKS HALDDMotionComp;
}

[CRepr]
public struct DDCORECAPS
{
	public uint32 dwSize;
	public uint32 dwCaps;
	public uint32 dwCaps2;
	public uint32 dwCKeyCaps;
	public uint32 dwFXCaps;
	public uint32 dwFXAlphaCaps;
	public uint32 dwPalCaps;
	public uint32 dwSVCaps;
	public uint32 dwAlphaBltConstBitDepths;
	public uint32 dwAlphaBltPixelBitDepths;
	public uint32 dwAlphaBltSurfaceBitDepths;
	public uint32 dwAlphaOverlayConstBitDepths;
	public uint32 dwAlphaOverlayPixelBitDepths;
	public uint32 dwAlphaOverlaySurfaceBitDepths;
	public uint32 dwZBufferBitDepths;
	public uint32 dwVidMemTotal;
	public uint32 dwVidMemFree;
	public uint32 dwMaxVisibleOverlays;
	public uint32 dwCurrVisibleOverlays;
	public uint32 dwNumFourCCCodes;
	public uint32 dwAlignBoundarySrc;
	public uint32 dwAlignSizeSrc;
	public uint32 dwAlignBoundaryDest;
	public uint32 dwAlignSizeDest;
	public uint32 dwAlignStrideAlign;
	public uint32[8] dwRops;
	public DDSCAPS ddsCaps;
	public uint32 dwMinOverlayStretch;
	public uint32 dwMaxOverlayStretch;
	public uint32 dwMinLiveVideoStretch;
	public uint32 dwMaxLiveVideoStretch;
	public uint32 dwMinHwCodecStretch;
	public uint32 dwMaxHwCodecStretch;
	public uint32 dwReserved1;
	public uint32 dwReserved2;
	public uint32 dwReserved3;
	public uint32 dwSVBCaps;
	public uint32 dwSVBCKeyCaps;
	public uint32 dwSVBFXCaps;
	public uint32[8] dwSVBRops;
	public uint32 dwVSBCaps;
	public uint32 dwVSBCKeyCaps;
	public uint32 dwVSBFXCaps;
	public uint32[8] dwVSBRops;
	public uint32 dwSSBCaps;
	public uint32 dwSSBCKeyCaps;
	public uint32 dwSSBFXCaps;
	public uint32[8] dwSSBRops;
	public uint32 dwMaxVideoPorts;
	public uint32 dwCurrVideoPorts;
	public uint32 dwSVBCaps2;
}

[CRepr]
public struct DDRAWI_DIRECTDRAW_GBL
{
	public uint32 dwRefCnt;
	public uint32 dwFlags;
	public uint fpPrimaryOrig;
	public DDCORECAPS ddCaps;
	public uint32 dwInternal1;
	public uint32[9] dwUnused1;
	public DDHAL_CALLBACKS* lpDDCBtmp;
	public DDRAWI_DDRAWSURFACE_INT* dsList;
	public DDRAWI_DDRAWPALETTE_INT* palList;
	public DDRAWI_DDRAWCLIPPER_INT* clipperList;
	public DDRAWI_DIRECTDRAW_GBL* lp16DD;
	public uint32 dwMaxOverlays;
	public uint32 dwCurrOverlays;
	public uint32 dwMonitorFrequency;
	public DDCORECAPS ddHELCaps;
	public uint32[50] dwUnused2;
	public DDCOLORKEY ddckCKDestOverlay;
	public DDCOLORKEY ddckCKSrcOverlay;
	public VIDMEMINFO vmiData;
	public void* lpDriverHandle;
	public DDRAWI_DIRECTDRAW_LCL* lpExclusiveOwner;
	public uint32 dwModeIndex;
	public uint32 dwModeIndexOrig;
	public uint32 dwNumFourCC;
	public uint32* lpdwFourCC;
	public uint32 dwNumModes;
	public DDHALMODEINFO* lpModeInfo;
	public PROCESS_LIST plProcessList;
	public uint32 dwSurfaceLockCount;
	public uint32 dwAliasedLockCnt;
	public uint dwReserved3;
	public uint hDD;
	public CHAR[12] cObsolete;
	public uint32 dwReserved1;
	public uint32 dwReserved2;
	public DBLNODE dbnOverlayRoot;
	public uint16* lpwPDeviceFlags;
	public uint32 dwPDevice;
	public uint32 dwWin16LockCnt;
	public uint32 dwUnused3;
	public uint32 hInstance;
	public uint32 dwEvent16;
	public uint32 dwSaveNumModes;
	public uint lpD3DGlobalDriverData;
	public uint lpD3DHALCallbacks;
	public DDCORECAPS ddBothCaps;
	public DDVIDEOPORTCAPS* lpDDVideoPortCaps;
	public DDRAWI_DDVIDEOPORT_INT* dvpList;
	public uint lpD3DHALCallbacks2;
	public RECT rectDevice;
	public uint32 cMonitors;
	public void* gpbmiSrc;
	public void* gpbmiDest;
	public HEAPALIASINFO* phaiHeapAliases;
	public uint hKernelHandle;
	public uint pfnNotifyProc;
	public DDKERNELCAPS* lpDDKernelCaps;
	public DDNONLOCALVIDMEMCAPS* lpddNLVCaps;
	public DDNONLOCALVIDMEMCAPS* lpddNLVHELCaps;
	public DDNONLOCALVIDMEMCAPS* lpddNLVBothCaps;
	public uint lpD3DExtendedCaps;
	public uint32 dwDOSBoxEvent;
	public RECT rectDesktop;
	public CHAR[32] cDriverName;
	public uint lpD3DHALCallbacks3;
	public uint32 dwNumZPixelFormats;
	public DDPIXELFORMAT* lpZPixelFormats;
	public DDRAWI_DDMOTIONCOMP_INT* mcList;
	public uint32 hDDVxd;
	public DDSCAPSEX ddsCapsMore;
}

[CRepr]
public struct DDRAWI_DIRECTDRAW_LCL
{
	public uint32 lpDDMore;
	public DDRAWI_DIRECTDRAW_GBL* lpGbl;
	public uint32 dwUnused0;
	public uint32 dwLocalFlags;
	public uint32 dwLocalRefCnt;
	public uint32 dwProcessId;
	public IUnknown* pUnkOuter;
	public uint32 dwObsolete1;
	public uint hWnd;
	public uint hDC;
	public uint32 dwErrorMode;
	public DDRAWI_DDRAWSURFACE_INT* lpPrimary;
	public DDRAWI_DDRAWSURFACE_INT* lpCB;
	public uint32 dwPreferredMode;
	public HINSTANCE hD3DInstance;
	public IUnknown* pD3DIUnknown;
	public DDHAL_CALLBACKS* lpDDCB;
	public uint hDDVxd;
	public uint32 dwAppHackFlags;
	public uint hFocusWnd;
	public uint32 dwHotTracking;
	public uint32 dwIMEState;
	public uint hWndPopup;
	public uint hDD;
	public uint hGammaCalibrator;
	public LPDDGAMMACALIBRATORPROC lpGammaCalibrator;
}

[CRepr]
public struct DDRAWI_DDVIDEOPORT_INT
{
	public void* lpVtbl;
	public DDRAWI_DDVIDEOPORT_LCL* lpLcl;
	public DDRAWI_DDVIDEOPORT_INT* lpLink;
	public uint32 dwIntRefCnt;
	public uint32 dwFlags;
}

[CRepr]
public struct DDRAWI_DDVIDEOPORT_LCL
{
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public DDVIDEOPORTDESC ddvpDesc;
	public DDVIDEOPORTINFO ddvpInfo;
	public DDRAWI_DDRAWSURFACE_INT* lpSurface;
	public DDRAWI_DDRAWSURFACE_INT* lpVBISurface;
	public DDRAWI_DDRAWSURFACE_INT** lpFlipInts;
	public uint32 dwNumAutoflip;
	public uint32 dwProcessID;
	public uint32 dwStateFlags;
	public uint32 dwFlags;
	public uint32 dwRefCnt;
	public uint fpLastFlip;
	public uint dwReserved1;
	public uint dwReserved2;
	public HANDLE hDDVideoPort;
	public uint32 dwNumVBIAutoflip;
	public DDVIDEOPORTDESC* lpVBIDesc;
	public DDVIDEOPORTDESC* lpVideoDesc;
	public DDVIDEOPORTINFO* lpVBIInfo;
	public DDVIDEOPORTINFO* lpVideoInfo;
	public uint32 dwVBIProcessID;
	public DDRAWI_DDVIDEOPORT_INT* lpVPNotify;
}

[CRepr]
public struct DDRAWI_DDMOTIONCOMP_INT
{
	public void* lpVtbl;
	public DDRAWI_DDMOTIONCOMP_LCL* lpLcl;
	public DDRAWI_DDMOTIONCOMP_INT* lpLink;
	public uint32 dwIntRefCnt;
}

[CRepr]
public struct DDRAWI_DDMOTIONCOMP_LCL
{
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public Guid guid;
	public uint32 dwUncompWidth;
	public uint32 dwUncompHeight;
	public DDPIXELFORMAT ddUncompPixelFormat;
	public uint32 dwInternalFlags;
	public uint32 dwRefCnt;
	public uint32 dwProcessId;
	public HANDLE hMoComp;
	public uint32 dwDriverReserved1;
	public uint32 dwDriverReserved2;
	public uint32 dwDriverReserved3;
	public void* lpDriverReserved1;
	public void* lpDriverReserved2;
	public void* lpDriverReserved3;
}

[CRepr]
public struct DDHALINFO
{
	public uint32 dwSize;
	public DDHAL_DDCALLBACKS* lpDDCallbacks;
	public DDHAL_DDSURFACECALLBACKS* lpDDSurfaceCallbacks;
	public DDHAL_DDPALETTECALLBACKS* lpDDPaletteCallbacks;
	public VIDMEMINFO vmiData;
	public DDCORECAPS ddCaps;
	public uint32 dwMonitorFrequency;
	public LPDDHAL_GETDRIVERINFO GetDriverInfo;
	public uint32 dwModeIndex;
	public uint32* lpdwFourCC;
	public uint32 dwNumModes;
	public DDHALMODEINFO* lpModeInfo;
	public uint32 dwFlags;
	public void* lpPDevice;
	public uint32 hInstance;
	public uint lpD3DGlobalDriverData;
	public uint lpD3DHALCallbacks;
	public DDHAL_DDEXEBUFCALLBACKS* lpDDExeBufCallbacks;
}

[CRepr]
public struct DDHALDDRAWFNS
{
	public uint32 dwSize;
	public LPDDHAL_SETINFO lpSetInfo;
	public LPDDHAL_VIDMEMALLOC lpVidMemAlloc;
	public LPDDHAL_VIDMEMFREE lpVidMemFree;
}

[CRepr]
public struct DDHAL_BLTDATA
{
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public DDRAWI_DDRAWSURFACE_LCL* lpDDDestSurface;
	public RECTL rDest;
	public DDRAWI_DDRAWSURFACE_LCL* lpDDSrcSurface;
	public RECTL rSrc;
	public uint32 dwFlags;
	public uint32 dwROPFlags;
	public DDBLTFX bltFX;
	public HRESULT ddRVal;
	public LPDDHALSURFCB_BLT Blt;
	public BOOL IsClipped;
	public RECTL rOrigDest;
	public RECTL rOrigSrc;
	public uint32 dwRectCnt;
	public RECT* prDestRects;
}

[CRepr]
public struct DDHAL_LOCKDATA
{
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public DDRAWI_DDRAWSURFACE_LCL* lpDDSurface;
	public uint32 bHasRect;
	public RECTL rArea;
	public void* lpSurfData;
	public HRESULT ddRVal;
	public LPDDHALSURFCB_LOCK Lock;
	public uint32 dwFlags;
}

[CRepr]
public struct DDHAL_UNLOCKDATA
{
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public DDRAWI_DDRAWSURFACE_LCL* lpDDSurface;
	public HRESULT ddRVal;
	public LPDDHALSURFCB_UNLOCK Unlock;
}

[CRepr]
public struct DDHAL_UPDATEOVERLAYDATA
{
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public DDRAWI_DDRAWSURFACE_LCL* lpDDDestSurface;
	public RECTL rDest;
	public DDRAWI_DDRAWSURFACE_LCL* lpDDSrcSurface;
	public RECTL rSrc;
	public uint32 dwFlags;
	public DDOVERLAYFX overlayFX;
	public HRESULT ddRVal;
	public LPDDHALSURFCB_UPDATEOVERLAY UpdateOverlay;
}

[CRepr]
public struct DDHAL_SETOVERLAYPOSITIONDATA
{
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public DDRAWI_DDRAWSURFACE_LCL* lpDDSrcSurface;
	public DDRAWI_DDRAWSURFACE_LCL* lpDDDestSurface;
	public int32 lXPos;
	public int32 lYPos;
	public HRESULT ddRVal;
	public LPDDHALSURFCB_SETOVERLAYPOSITION SetOverlayPosition;
}

[CRepr]
public struct DDHAL_SETPALETTEDATA
{
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public DDRAWI_DDRAWSURFACE_LCL* lpDDSurface;
	public DDRAWI_DDRAWPALETTE_GBL* lpDDPalette;
	public HRESULT ddRVal;
	public LPDDHALSURFCB_SETPALETTE SetPalette;
	public BOOL Attach;
}

[CRepr]
public struct DDHAL_FLIPDATA
{
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public DDRAWI_DDRAWSURFACE_LCL* lpSurfCurr;
	public DDRAWI_DDRAWSURFACE_LCL* lpSurfTarg;
	public uint32 dwFlags;
	public HRESULT ddRVal;
	public LPDDHALSURFCB_FLIP Flip;
	public DDRAWI_DDRAWSURFACE_LCL* lpSurfCurrLeft;
	public DDRAWI_DDRAWSURFACE_LCL* lpSurfTargLeft;
}

[CRepr]
public struct DDHAL_DESTROYSURFACEDATA
{
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public DDRAWI_DDRAWSURFACE_LCL* lpDDSurface;
	public HRESULT ddRVal;
	public LPDDHALSURFCB_DESTROYSURFACE DestroySurface;
}

[CRepr]
public struct DDHAL_SETCLIPLISTDATA
{
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public DDRAWI_DDRAWSURFACE_LCL* lpDDSurface;
	public HRESULT ddRVal;
	public LPDDHALSURFCB_SETCLIPLIST SetClipList;
}

[CRepr]
public struct DDHAL_ADDATTACHEDSURFACEDATA
{
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public DDRAWI_DDRAWSURFACE_LCL* lpDDSurface;
	public DDRAWI_DDRAWSURFACE_LCL* lpSurfAttached;
	public HRESULT ddRVal;
	public LPDDHALSURFCB_ADDATTACHEDSURFACE AddAttachedSurface;
}

[CRepr]
public struct DDHAL_SETCOLORKEYDATA
{
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public DDRAWI_DDRAWSURFACE_LCL* lpDDSurface;
	public uint32 dwFlags;
	public DDCOLORKEY ckNew;
	public HRESULT ddRVal;
	public LPDDHALSURFCB_SETCOLORKEY SetColorKey;
}

[CRepr]
public struct DDHAL_GETBLTSTATUSDATA
{
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public DDRAWI_DDRAWSURFACE_LCL* lpDDSurface;
	public uint32 dwFlags;
	public HRESULT ddRVal;
	public LPDDHALSURFCB_GETBLTSTATUS GetBltStatus;
}

[CRepr]
public struct DDHAL_GETFLIPSTATUSDATA
{
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public DDRAWI_DDRAWSURFACE_LCL* lpDDSurface;
	public uint32 dwFlags;
	public HRESULT ddRVal;
	public LPDDHALSURFCB_GETFLIPSTATUS GetFlipStatus;
}

[CRepr]
public struct DDHAL_DESTROYPALETTEDATA
{
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public DDRAWI_DDRAWPALETTE_GBL* lpDDPalette;
	public HRESULT ddRVal;
	public LPDDHALPALCB_DESTROYPALETTE DestroyPalette;
}

[CRepr]
public struct DDHAL_SETENTRIESDATA
{
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public DDRAWI_DDRAWPALETTE_GBL* lpDDPalette;
	public uint32 dwBase;
	public uint32 dwNumEntries;
	public PALETTEENTRY* lpEntries;
	public HRESULT ddRVal;
	public LPDDHALPALCB_SETENTRIES SetEntries;
}

[CRepr]
public struct DDHAL_CREATESURFACEDATA
{
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public DDSURFACEDESC* lpDDSurfaceDesc;
	public DDRAWI_DDRAWSURFACE_LCL** lplpSList;
	public uint32 dwSCnt;
	public HRESULT ddRVal;
	public LPDDHAL_CREATESURFACE CreateSurface;
}

[CRepr]
public struct DDHAL_CANCREATESURFACEDATA
{
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public DDSURFACEDESC* lpDDSurfaceDesc;
	public uint32 bIsDifferentPixelFormat;
	public HRESULT ddRVal;
	public LPDDHAL_CANCREATESURFACE CanCreateSurface;
}

[CRepr]
public struct DDHAL_CREATEPALETTEDATA
{
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public DDRAWI_DDRAWPALETTE_GBL* lpDDPalette;
	public PALETTEENTRY* lpColorTable;
	public HRESULT ddRVal;
	public LPDDHAL_CREATEPALETTE CreatePalette;
	public BOOL is_excl;
}

[CRepr]
public struct DDHAL_WAITFORVERTICALBLANKDATA
{
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public uint32 dwFlags;
	public uint32 bIsInVB;
	public uint hEvent;
	public HRESULT ddRVal;
	public LPDDHAL_WAITFORVERTICALBLANK WaitForVerticalBlank;
}

[CRepr]
public struct DDHAL_DESTROYDRIVERDATA
{
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public HRESULT ddRVal;
	public LPDDHAL_DESTROYDRIVER DestroyDriver;
}

[CRepr]
public struct DDHAL_SETMODEDATA
{
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public uint32 dwModeIndex;
	public HRESULT ddRVal;
	public LPDDHAL_SETMODE SetMode;
	public BOOL inexcl;
	public BOOL useRefreshRate;
}

[CRepr]
public struct DDHAL_DRVSETCOLORKEYDATA
{
	public DDRAWI_DDRAWSURFACE_LCL* lpDDSurface;
	public uint32 dwFlags;
	public DDCOLORKEY ckNew;
	public HRESULT ddRVal;
	public LPDDHAL_SETCOLORKEY SetColorKey;
}

[CRepr]
public struct DDHAL_GETSCANLINEDATA
{
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public uint32 dwScanLine;
	public HRESULT ddRVal;
	public LPDDHAL_GETSCANLINE GetScanLine;
}

[CRepr]
public struct DDHAL_SETEXCLUSIVEMODEDATA
{
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public uint32 dwEnterExcl;
	public uint32 dwReserved;
	public HRESULT ddRVal;
	public LPDDHAL_SETEXCLUSIVEMODE SetExclusiveMode;
}

[CRepr]
public struct DDHAL_FLIPTOGDISURFACEDATA
{
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public uint32 dwToGDI;
	public uint32 dwReserved;
	public HRESULT ddRVal;
	public LPDDHAL_FLIPTOGDISURFACE FlipToGDISurface;
}

[CRepr]
public struct DDHAL_CANCREATEVPORTDATA
{
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public DDVIDEOPORTDESC* lpDDVideoPortDesc;
	public HRESULT ddRVal;
	public LPDDHALVPORTCB_CANCREATEVIDEOPORT CanCreateVideoPort;
}

[CRepr]
public struct DDHAL_CREATEVPORTDATA
{
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public DDVIDEOPORTDESC* lpDDVideoPortDesc;
	public DDRAWI_DDVIDEOPORT_LCL* lpVideoPort;
	public HRESULT ddRVal;
	public LPDDHALVPORTCB_CREATEVIDEOPORT CreateVideoPort;
}

[CRepr]
public struct DDHAL_FLIPVPORTDATA
{
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public DDRAWI_DDVIDEOPORT_LCL* lpVideoPort;
	public DDRAWI_DDRAWSURFACE_LCL* lpSurfCurr;
	public DDRAWI_DDRAWSURFACE_LCL* lpSurfTarg;
	public HRESULT ddRVal;
	public LPDDHALVPORTCB_FLIP FlipVideoPort;
}

[CRepr]
public struct DDHAL_GETVPORTBANDWIDTHDATA
{
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public DDRAWI_DDVIDEOPORT_LCL* lpVideoPort;
	public DDPIXELFORMAT* lpddpfFormat;
	public uint32 dwWidth;
	public uint32 dwHeight;
	public uint32 dwFlags;
	public DDVIDEOPORTBANDWIDTH* lpBandwidth;
	public HRESULT ddRVal;
	public LPDDHALVPORTCB_GETBANDWIDTH GetVideoPortBandwidth;
}

[CRepr]
public struct DDHAL_GETVPORTINPUTFORMATDATA
{
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public DDRAWI_DDVIDEOPORT_LCL* lpVideoPort;
	public uint32 dwFlags;
	public DDPIXELFORMAT* lpddpfFormat;
	public uint32 dwNumFormats;
	public HRESULT ddRVal;
	public LPDDHALVPORTCB_GETINPUTFORMATS GetVideoPortInputFormats;
}

[CRepr]
public struct DDHAL_GETVPORTOUTPUTFORMATDATA
{
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public DDRAWI_DDVIDEOPORT_LCL* lpVideoPort;
	public uint32 dwFlags;
	public DDPIXELFORMAT* lpddpfInputFormat;
	public DDPIXELFORMAT* lpddpfOutputFormats;
	public uint32 dwNumFormats;
	public HRESULT ddRVal;
	public LPDDHALVPORTCB_GETOUTPUTFORMATS GetVideoPortOutputFormats;
}

[CRepr]
public struct DDHAL_GETVPORTFIELDDATA
{
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public DDRAWI_DDVIDEOPORT_LCL* lpVideoPort;
	public BOOL bField;
	public HRESULT ddRVal;
	public LPDDHALVPORTCB_GETFIELD GetVideoPortField;
}

[CRepr]
public struct DDHAL_GETVPORTLINEDATA
{
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public DDRAWI_DDVIDEOPORT_LCL* lpVideoPort;
	public uint32 dwLine;
	public HRESULT ddRVal;
	public LPDDHALVPORTCB_GETLINE GetVideoPortLine;
}

[CRepr]
public struct DDHAL_GETVPORTCONNECTDATA
{
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public uint32 dwPortId;
	public DDVIDEOPORTCONNECT* lpConnect;
	public uint32 dwNumEntries;
	public HRESULT ddRVal;
	public LPDDHALVPORTCB_GETVPORTCONNECT GetVideoPortConnectInfo;
}

[CRepr]
public struct DDHAL_DESTROYVPORTDATA
{
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public DDRAWI_DDVIDEOPORT_LCL* lpVideoPort;
	public HRESULT ddRVal;
	public LPDDHALVPORTCB_DESTROYVPORT DestroyVideoPort;
}

[CRepr]
public struct DDHAL_GETVPORTFLIPSTATUSDATA
{
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public uint fpSurface;
	public HRESULT ddRVal;
	public LPDDHALVPORTCB_GETFLIPSTATUS GetVideoPortFlipStatus;
}

[CRepr]
public struct DDHAL_UPDATEVPORTDATA
{
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public DDRAWI_DDVIDEOPORT_LCL* lpVideoPort;
	public DDRAWI_DDRAWSURFACE_INT** lplpDDSurface;
	public DDRAWI_DDRAWSURFACE_INT** lplpDDVBISurface;
	public DDVIDEOPORTINFO* lpVideoInfo;
	public uint32 dwFlags;
	public uint32 dwNumAutoflip;
	public uint32 dwNumVBIAutoflip;
	public HRESULT ddRVal;
	public LPDDHALVPORTCB_UPDATE UpdateVideoPort;
}

[CRepr]
public struct DDHAL_WAITFORVPORTSYNCDATA
{
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public DDRAWI_DDVIDEOPORT_LCL* lpVideoPort;
	public uint32 dwFlags;
	public uint32 dwLine;
	public uint32 dwTimeOut;
	public HRESULT ddRVal;
	public LPDDHALVPORTCB_WAITFORSYNC WaitForVideoPortSync;
}

[CRepr]
public struct DDHAL_GETVPORTSIGNALDATA
{
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public DDRAWI_DDVIDEOPORT_LCL* lpVideoPort;
	public uint32 dwStatus;
	public HRESULT ddRVal;
	public LPDDHALVPORTCB_GETSIGNALSTATUS GetVideoSignalStatus;
}

[CRepr]
public struct DDHAL_VPORTCOLORDATA
{
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public DDRAWI_DDVIDEOPORT_LCL* lpVideoPort;
	public uint32 dwFlags;
	public DDCOLORCONTROL* lpColorData;
	public HRESULT ddRVal;
	public LPDDHALVPORTCB_COLORCONTROL ColorControl;
}

[CRepr]
public struct DDHAL_COLORCONTROLDATA
{
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public DDRAWI_DDRAWSURFACE_LCL* lpDDSurface;
	public DDCOLORCONTROL* lpColorData;
	public uint32 dwFlags;
	public HRESULT ddRVal;
	public LPDDHALCOLORCB_COLORCONTROL ColorControl;
}

[CRepr]
public struct DDHAL_GETDRIVERINFODATA
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public Guid guidInfo;
	public uint32 dwExpectedSize;
	public void* lpvData;
	public uint32 dwActualSize;
	public HRESULT ddRVal;
	public uint dwContext;
}

[CRepr]
public struct DDHAL_GETAVAILDRIVERMEMORYDATA
{
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public DDSCAPS DDSCaps;
	public uint32 dwTotal;
	public uint32 dwFree;
	public HRESULT ddRVal;
	public LPDDHAL_GETAVAILDRIVERMEMORY GetAvailDriverMemory;
	public DDSCAPSEX ddsCapsEx;
}

[CRepr]
public struct DDHAL_UPDATENONLOCALHEAPDATA
{
	public DDRAWI_DIRECTDRAW_GBL* lpDD;
	public uint32 dwHeap;
	public uint fpGARTLin;
	public uint fpGARTDev;
	public uint ulPolicyMaxBytes;
	public HRESULT ddRVal;
	public LPDDHAL_UPDATENONLOCALHEAP UpdateNonLocalHeap;
}

[CRepr]
public struct DDHAL_GETHEAPALIGNMENTDATA
{
	public uint dwInstance;
	public uint32 dwHeap;
	public HRESULT ddRVal;
	public LPDDHAL_GETHEAPALIGNMENT GetHeapAlignment;
	public HEAPALIGNMENT Alignment;
}

[CRepr]
public struct DDHAL_CREATESURFACEEXDATA
{
	public uint32 dwFlags;
	public DDRAWI_DIRECTDRAW_LCL* lpDDLcl;
	public DDRAWI_DDRAWSURFACE_LCL* lpDDSLcl;
	public HRESULT ddRVal;
}

[CRepr]
public struct DDHAL_GETDRIVERSTATEDATA
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint dwhContext;
	}
	public uint32 dwFlags;
	public using _Anonymous_e__Union Anonymous;
	public uint32* lpdwStates;
	public uint32 dwLength;
	public HRESULT ddRVal;
}

[CRepr]
public struct DDHAL_DESTROYDDLOCALDATA
{
	public uint32 dwFlags;
	public DDRAWI_DIRECTDRAW_LCL* pDDLcl;
	public HRESULT ddRVal;
}

[CRepr]
public struct DDHAL_SYNCSURFACEDATA
{
	public uint32 dwSize;
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public DDRAWI_DDRAWSURFACE_LCL* lpDDSurface;
	public uint32 dwSurfaceOffset;
	public uint fpLockPtr;
	public int32 lPitch;
	public uint32 dwOverlayOffset;
	public uint32 dwOverlaySrcWidth;
	public uint32 dwOverlaySrcHeight;
	public uint32 dwOverlayDestWidth;
	public uint32 dwOverlayDestHeight;
	public uint dwDriverReserved1;
	public uint dwDriverReserved2;
	public uint dwDriverReserved3;
	public HRESULT ddRVal;
}

[CRepr]
public struct DDHAL_SYNCVIDEOPORTDATA
{
	public uint32 dwSize;
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public DDRAWI_DDVIDEOPORT_LCL* lpVideoPort;
	public uint32 dwOriginOffset;
	public uint32 dwHeight;
	public uint32 dwVBIHeight;
	public uint dwDriverReserved1;
	public uint dwDriverReserved2;
	public uint dwDriverReserved3;
	public HRESULT ddRVal;
}

[CRepr]
public struct DDHAL_GETMOCOMPGUIDSDATA
{
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public uint32 dwNumGuids;
	public Guid* lpGuids;
	public HRESULT ddRVal;
	public LPDDHALMOCOMPCB_GETGUIDS GetMoCompGuids;
}

[CRepr]
public struct DDHAL_GETMOCOMPFORMATSDATA
{
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public Guid* lpGuid;
	public uint32 dwNumFormats;
	public DDPIXELFORMAT* lpFormats;
	public HRESULT ddRVal;
	public LPDDHALMOCOMPCB_GETFORMATS GetMoCompFormats;
}

[CRepr]
public struct DDHAL_CREATEMOCOMPDATA
{
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public DDRAWI_DDMOTIONCOMP_LCL* lpMoComp;
	public Guid* lpGuid;
	public uint32 dwUncompWidth;
	public uint32 dwUncompHeight;
	public DDPIXELFORMAT ddUncompPixelFormat;
	public void* lpData;
	public uint32 dwDataSize;
	public HRESULT ddRVal;
	public LPDDHALMOCOMPCB_CREATE CreateMoComp;
}

[CRepr]
public struct DDMCCOMPBUFFERINFO
{
	public uint32 dwSize;
	public uint32 dwNumCompBuffers;
	public uint32 dwWidthToCreate;
	public uint32 dwHeightToCreate;
	public uint32 dwBytesToAllocate;
	public DDSCAPS2 ddCompCaps;
	public DDPIXELFORMAT ddPixelFormat;
}

[CRepr]
public struct DDHAL_GETMOCOMPCOMPBUFFDATA
{
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public Guid* lpGuid;
	public uint32 dwWidth;
	public uint32 dwHeight;
	public DDPIXELFORMAT ddPixelFormat;
	public uint32 dwNumTypesCompBuffs;
	public DDMCCOMPBUFFERINFO* lpCompBuffInfo;
	public HRESULT ddRVal;
	public LPDDHALMOCOMPCB_GETCOMPBUFFINFO GetMoCompBuffInfo;
}

[CRepr]
public struct DDHAL_GETINTERNALMOCOMPDATA
{
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public Guid* lpGuid;
	public uint32 dwWidth;
	public uint32 dwHeight;
	public DDPIXELFORMAT ddPixelFormat;
	public uint32 dwScratchMemAlloc;
	public HRESULT ddRVal;
	public LPDDHALMOCOMPCB_GETINTERNALINFO GetInternalMoCompInfo;
}

[CRepr]
public struct DDHAL_BEGINMOCOMPFRAMEDATA
{
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public DDRAWI_DDMOTIONCOMP_LCL* lpMoComp;
	public DDRAWI_DDRAWSURFACE_LCL* lpDestSurface;
	public uint32 dwInputDataSize;
	public void* lpInputData;
	public uint32 dwOutputDataSize;
	public void* lpOutputData;
	public HRESULT ddRVal;
	public LPDDHALMOCOMPCB_BEGINFRAME BeginMoCompFrame;
}

[CRepr]
public struct DDHAL_ENDMOCOMPFRAMEDATA
{
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public DDRAWI_DDMOTIONCOMP_LCL* lpMoComp;
	public void* lpInputData;
	public uint32 dwInputDataSize;
	public HRESULT ddRVal;
	public LPDDHALMOCOMPCB_ENDFRAME EndMoCompFrame;
}

[CRepr]
public struct DDMCBUFFERINFO
{
	public uint32 dwSize;
	public DDRAWI_DDRAWSURFACE_LCL* lpCompSurface;
	public uint32 dwDataOffset;
	public uint32 dwDataSize;
	public void* lpPrivate;
}

[CRepr]
public struct DDHAL_RENDERMOCOMPDATA
{
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public DDRAWI_DDMOTIONCOMP_LCL* lpMoComp;
	public uint32 dwNumBuffers;
	public DDMCBUFFERINFO* lpBufferInfo;
	public uint32 dwFunction;
	public void* lpInputData;
	public uint32 dwInputDataSize;
	public void* lpOutputData;
	public uint32 dwOutputDataSize;
	public HRESULT ddRVal;
	public LPDDHALMOCOMPCB_RENDER RenderMoComp;
}

[CRepr]
public struct DDHAL_QUERYMOCOMPSTATUSDATA
{
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public DDRAWI_DDMOTIONCOMP_LCL* lpMoComp;
	public DDRAWI_DDRAWSURFACE_LCL* lpSurface;
	public uint32 dwFlags;
	public HRESULT ddRVal;
	public LPDDHALMOCOMPCB_QUERYSTATUS QueryMoCompStatus;
}

[CRepr]
public struct DDHAL_DESTROYMOCOMPDATA
{
	public DDRAWI_DIRECTDRAW_LCL* lpDD;
	public DDRAWI_DDMOTIONCOMP_LCL* lpMoComp;
	public HRESULT ddRVal;
	public LPDDHALMOCOMPCB_DESTROY DestroyMoComp;
}

[CRepr]
public struct _DD_DESTROYDRIVERDATA
{
}

[CRepr]
public struct _DD_SETMODEDATA
{
}

[CRepr]
public struct _DD_GETVPORTAUTOFLIPSURFACEDATA
{
}

[CRepr]
public struct VIDEOMEMORY
{
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint fpEnd;
		public uint32 dwWidth;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public VMEMHEAP* lpHeap;
		public uint32 dwHeight;
	}
	public uint32 dwFlags;
	public uint fpStart;
	public using _Anonymous1_e__Union Anonymous1;
	public DDSCAPS ddsCaps;
	public DDSCAPS ddsCapsAlt;
	public using _Anonymous2_e__Union Anonymous2;
}

[CRepr]
public struct VIDEOMEMORYINFO
{
	public uint fpPrimary;
	public uint32 dwFlags;
	public uint32 dwDisplayWidth;
	public uint32 dwDisplayHeight;
	public int32 lDisplayPitch;
	public DDPIXELFORMAT ddpfDisplay;
	public uint32 dwOffscreenAlign;
	public uint32 dwOverlayAlign;
	public uint32 dwTextureAlign;
	public uint32 dwZBufferAlign;
	public uint32 dwAlphaAlign;
	public void* pvPrimary;
}

[CRepr]
public struct DD_CALLBACKS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public PDD_DESTROYDRIVER DestroyDriver;
	public PDD_CREATESURFACE CreateSurface;
	public PDD_SETCOLORKEY SetColorKey;
	public PDD_SETMODE SetMode;
	public PDD_WAITFORVERTICALBLANK WaitForVerticalBlank;
	public PDD_CANCREATESURFACE CanCreateSurface;
	public PDD_CREATEPALETTE CreatePalette;
	public PDD_GETSCANLINE GetScanLine;
	public PDD_MAPMEMORY MapMemory;
}

[CRepr]
public struct DD_MISCELLANEOUSCALLBACKS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public PDD_GETAVAILDRIVERMEMORY GetAvailDriverMemory;
}

[CRepr]
public struct DD_MISCELLANEOUS2CALLBACKS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public PDD_ALPHABLT AlphaBlt;
	public PDD_CREATESURFACEEX CreateSurfaceEx;
	public PDD_GETDRIVERSTATE GetDriverState;
	public PDD_DESTROYDDLOCAL DestroyDDLocal;
}

[CRepr]
public struct DD_NTCALLBACKS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public PDD_FREEDRIVERMEMORY FreeDriverMemory;
	public PDD_SETEXCLUSIVEMODE SetExclusiveMode;
	public PDD_FLIPTOGDISURFACE FlipToGDISurface;
}

[CRepr]
public struct DD_PALETTECALLBACKS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public PDD_PALCB_DESTROYPALETTE DestroyPalette;
	public PDD_PALCB_SETENTRIES SetEntries;
}

[CRepr]
public struct DD_SURFACECALLBACKS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public PDD_SURFCB_DESTROYSURFACE DestroySurface;
	public PDD_SURFCB_FLIP Flip;
	public PDD_SURFCB_SETCLIPLIST SetClipList;
	public PDD_SURFCB_LOCK Lock;
	public PDD_SURFCB_UNLOCK Unlock;
	public PDD_SURFCB_BLT Blt;
	public PDD_SURFCB_SETCOLORKEY SetColorKey;
	public PDD_SURFCB_ADDATTACHEDSURFACE AddAttachedSurface;
	public PDD_SURFCB_GETBLTSTATUS GetBltStatus;
	public PDD_SURFCB_GETFLIPSTATUS GetFlipStatus;
	public PDD_SURFCB_UPDATEOVERLAY UpdateOverlay;
	public PDD_SURFCB_SETOVERLAYPOSITION SetOverlayPosition;
	public void* reserved4;
	public PDD_SURFCB_SETPALETTE SetPalette;
}

[CRepr]
public struct DD_VIDEOPORTCALLBACKS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public PDD_VPORTCB_CANCREATEVIDEOPORT CanCreateVideoPort;
	public PDD_VPORTCB_CREATEVIDEOPORT CreateVideoPort;
	public PDD_VPORTCB_FLIP FlipVideoPort;
	public PDD_VPORTCB_GETBANDWIDTH GetVideoPortBandwidth;
	public PDD_VPORTCB_GETINPUTFORMATS GetVideoPortInputFormats;
	public PDD_VPORTCB_GETOUTPUTFORMATS GetVideoPortOutputFormats;
	public void* lpReserved1;
	public PDD_VPORTCB_GETFIELD GetVideoPortField;
	public PDD_VPORTCB_GETLINE GetVideoPortLine;
	public PDD_VPORTCB_GETVPORTCONNECT GetVideoPortConnectInfo;
	public PDD_VPORTCB_DESTROYVPORT DestroyVideoPort;
	public PDD_VPORTCB_GETFLIPSTATUS GetVideoPortFlipStatus;
	public PDD_VPORTCB_UPDATE UpdateVideoPort;
	public PDD_VPORTCB_WAITFORSYNC WaitForVideoPortSync;
	public PDD_VPORTCB_GETSIGNALSTATUS GetVideoSignalStatus;
	public PDD_VPORTCB_COLORCONTROL ColorControl;
}

[CRepr]
public struct DD_COLORCONTROLCALLBACKS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public PDD_COLORCB_COLORCONTROL ColorControl;
}

[CRepr]
public struct DD_KERNELCALLBACKS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public PDD_KERNELCB_SYNCSURFACE SyncSurfaceData;
	public PDD_KERNELCB_SYNCVIDEOPORT SyncVideoPortData;
}

[CRepr]
public struct DD_MOTIONCOMPCALLBACKS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public PDD_MOCOMPCB_GETGUIDS GetMoCompGuids;
	public PDD_MOCOMPCB_GETFORMATS GetMoCompFormats;
	public PDD_MOCOMPCB_CREATE CreateMoComp;
	public PDD_MOCOMPCB_GETCOMPBUFFINFO GetMoCompBuffInfo;
	public PDD_MOCOMPCB_GETINTERNALINFO GetInternalMoCompInfo;
	public PDD_MOCOMPCB_BEGINFRAME BeginMoCompFrame;
	public PDD_MOCOMPCB_ENDFRAME EndMoCompFrame;
	public PDD_MOCOMPCB_RENDER RenderMoComp;
	public PDD_MOCOMPCB_QUERYSTATUS QueryMoCompStatus;
	public PDD_MOCOMPCB_DESTROY DestroyMoComp;
}

[CRepr]
public struct DD_NONLOCALVIDMEMCAPS
{
	public uint32 dwSize;
	public uint32 dwNLVBCaps;
	public uint32 dwNLVBCaps2;
	public uint32 dwNLVBCKeyCaps;
	public uint32 dwNLVBFXCaps;
	public uint32[8] dwNLVBRops;
}

[CRepr]
public struct DD_PALETTE_GLOBAL
{
	public uint dwReserved1;
}

[CRepr]
public struct DD_PALETTE_LOCAL
{
	public uint32 dwReserved0;
	public uint dwReserved1;
}

[CRepr]
public struct DD_CLIPPER_GLOBAL
{
	public uint dwReserved1;
}

[CRepr]
public struct DD_CLIPPER_LOCAL
{
	public uint dwReserved1;
}

[CRepr]
public struct DD_ATTACHLIST
{
	public DD_ATTACHLIST* lpLink;
	public DD_SURFACE_LOCAL* lpAttached;
}

[CRepr]
public struct DD_SURFACE_INT
{
	public DD_SURFACE_LOCAL* lpLcl;
}

[CRepr]
public struct DD_SURFACE_GLOBAL
{
	[CRepr, Union]
	public struct _Anonymous3_e__Union
	{
		public int32 lPitch;
		public uint32 dwLinearSize;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public uint32 dwBlockSizeY;
		public int32 lSlicePitch;
	}
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public VIDEOMEMORY* lpVidMemHeap;
		public uint32 dwBlockSizeX;
		public uint32 dwUserMemSize;
	}
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public uint fpVidMem;
	public using _Anonymous3_e__Union Anonymous3;
	public int32 yHint;
	public int32 xHint;
	public uint32 wHeight;
	public uint32 wWidth;
	public uint dwReserved1;
	public DDPIXELFORMAT ddpfSurface;
	public uint fpHeapOffset;
	public HANDLE hCreatorProcess;
}

[CRepr]
public struct DD_SURFACE_MORE
{
	public uint32 dwMipMapCount;
	public DD_VIDEOPORT_LOCAL* lpVideoPort;
	public uint32 dwOverlayFlags;
	public DDSCAPSEX ddsCapsEx;
	public uint32 dwSurfaceHandle;
}

[CRepr]
public struct DD_SURFACE_LOCAL
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public DDCOLORKEY ddckCKDestOverlay;
		public DDCOLORKEY ddckCKDestBlt;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public DDCOLORKEY ddckCKSrcOverlay;
		public DDCOLORKEY ddckCKSrcBlt;
	}
	public DD_SURFACE_GLOBAL* lpGbl;
	public uint32 dwFlags;
	public DDSCAPS ddsCaps;
	public uint dwReserved1;
	public using _Anonymous1_e__Union Anonymous1;
	public using _Anonymous2_e__Union Anonymous2;
	public DD_SURFACE_MORE* lpSurfMore;
	public DD_ATTACHLIST* lpAttachList;
	public DD_ATTACHLIST* lpAttachListFrom;
	public RECT rcOverlaySrc;
}

[CRepr]
public struct DD_MORECAPS
{
	public uint32 dwSize;
	public uint32 dwAlphaCaps;
	public uint32 dwSVBAlphaCaps;
	public uint32 dwVSBAlphaCaps;
	public uint32 dwSSBAlphaCaps;
	public uint32 dwFilterCaps;
	public uint32 dwSVBFilterCaps;
	public uint32 dwVSBFilterCaps;
	public uint32 dwSSBFilterCaps;
}

[CRepr]
public struct DDNTCORECAPS
{
	public uint32 dwSize;
	public uint32 dwCaps;
	public uint32 dwCaps2;
	public uint32 dwCKeyCaps;
	public uint32 dwFXCaps;
	public uint32 dwFXAlphaCaps;
	public uint32 dwPalCaps;
	public uint32 dwSVCaps;
	public uint32 dwAlphaBltConstBitDepths;
	public uint32 dwAlphaBltPixelBitDepths;
	public uint32 dwAlphaBltSurfaceBitDepths;
	public uint32 dwAlphaOverlayConstBitDepths;
	public uint32 dwAlphaOverlayPixelBitDepths;
	public uint32 dwAlphaOverlaySurfaceBitDepths;
	public uint32 dwZBufferBitDepths;
	public uint32 dwVidMemTotal;
	public uint32 dwVidMemFree;
	public uint32 dwMaxVisibleOverlays;
	public uint32 dwCurrVisibleOverlays;
	public uint32 dwNumFourCCCodes;
	public uint32 dwAlignBoundarySrc;
	public uint32 dwAlignSizeSrc;
	public uint32 dwAlignBoundaryDest;
	public uint32 dwAlignSizeDest;
	public uint32 dwAlignStrideAlign;
	public uint32[8] dwRops;
	public DDSCAPS ddsCaps;
	public uint32 dwMinOverlayStretch;
	public uint32 dwMaxOverlayStretch;
	public uint32 dwMinLiveVideoStretch;
	public uint32 dwMaxLiveVideoStretch;
	public uint32 dwMinHwCodecStretch;
	public uint32 dwMaxHwCodecStretch;
	public uint32 dwReserved1;
	public uint32 dwReserved2;
	public uint32 dwReserved3;
	public uint32 dwSVBCaps;
	public uint32 dwSVBCKeyCaps;
	public uint32 dwSVBFXCaps;
	public uint32[8] dwSVBRops;
	public uint32 dwVSBCaps;
	public uint32 dwVSBCKeyCaps;
	public uint32 dwVSBFXCaps;
	public uint32[8] dwVSBRops;
	public uint32 dwSSBCaps;
	public uint32 dwSSBCKeyCaps;
	public uint32 dwSSBFXCaps;
	public uint32[8] dwSSBRops;
	public uint32 dwMaxVideoPorts;
	public uint32 dwCurrVideoPorts;
	public uint32 dwSVBCaps2;
}

[CRepr]
public struct DD_D3DBUFCALLBACKS
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public PDD_CANCREATESURFACE CanCreateD3DBuffer;
	public PDD_CREATESURFACE CreateD3DBuffer;
	public PDD_SURFCB_DESTROYSURFACE DestroyD3DBuffer;
	public PDD_SURFCB_LOCK LockD3DBuffer;
	public PDD_SURFCB_UNLOCK UnlockD3DBuffer;
}

[CRepr]
public struct DD_HALINFO_V4
{
	public uint32 dwSize;
	public VIDEOMEMORYINFO vmiData;
	public DDNTCORECAPS ddCaps;
	public PDD_GETDRIVERINFO GetDriverInfo;
	public uint32 dwFlags;
}

[CRepr]
public struct DD_HALINFO
{
	public uint32 dwSize;
	public VIDEOMEMORYINFO vmiData;
	public DDNTCORECAPS ddCaps;
	public PDD_GETDRIVERINFO GetDriverInfo;
	public uint32 dwFlags;
	public void* lpD3DGlobalDriverData;
	public void* lpD3DHALCallbacks;
	public DD_D3DBUFCALLBACKS* lpD3DBufCallbacks;
}

[CRepr]
public struct DD_DIRECTDRAW_GLOBAL
{
	public void* dhpdev;
	public uint dwReserved1;
	public uint dwReserved2;
	public DDVIDEOPORTCAPS* lpDDVideoPortCaps;
}

[CRepr]
public struct DD_DIRECTDRAW_LOCAL
{
	public DD_DIRECTDRAW_GLOBAL* lpGbl;
}

[CRepr]
public struct DD_VIDEOPORT_LOCAL
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public DDVIDEOPORTDESC ddvpDesc;
	public DDVIDEOPORTINFO ddvpInfo;
	public DD_SURFACE_INT* lpSurface;
	public DD_SURFACE_INT* lpVBISurface;
	public uint32 dwNumAutoflip;
	public uint32 dwNumVBIAutoflip;
	public uint dwReserved1;
	public uint dwReserved2;
	public uint dwReserved3;
}

[CRepr]
public struct DD_MOTIONCOMP_LOCAL
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public Guid guid;
	public uint32 dwUncompWidth;
	public uint32 dwUncompHeight;
	public DDPIXELFORMAT ddUncompPixelFormat;
	public uint32 dwDriverReserved1;
	public uint32 dwDriverReserved2;
	public uint32 dwDriverReserved3;
	public void* lpDriverReserved1;
	public void* lpDriverReserved2;
	public void* lpDriverReserved3;
}

[CRepr]
public struct DD_MORESURFACECAPS
{
	[CRepr]
	public struct NTExtendedHeapRestrictions
	{
		public DDSCAPSEX ddsCapsEx;
		public DDSCAPSEX ddsCapsExAlt;
	}
	public uint32 dwSize;
	public DDSCAPSEX ddsCapsMore;
	public NTExtendedHeapRestrictions* ddsExtendedHeapRestrictions mut => &ddsExtendedHeapRestrictions_impl;
	private NTExtendedHeapRestrictions[ANYSIZE_ARRAY] ddsExtendedHeapRestrictions_impl;
}

[CRepr]
public struct DD_STEREOMODE
{
	public uint32 dwSize;
	public uint32 dwHeight;
	public uint32 dwWidth;
	public uint32 dwBpp;
	public uint32 dwRefreshRate;
	public BOOL bSupported;
}

[CRepr]
public struct DD_UPDATENONLOCALHEAPDATA
{
	public DD_DIRECTDRAW_GLOBAL* lpDD;
	public uint32 dwHeap;
	public uint fpGARTLin;
	public uint fpGARTDev;
	public uint ulPolicyMaxBytes;
	public HRESULT ddRVal;
	public void* UpdateNonLocalHeap;
}

[CRepr]
public struct DD_NTPRIVATEDRIVERCAPS
{
	public uint32 dwSize;
	public uint32 dwPrivateCaps;
}

[CRepr]
public struct DD_BLTDATA
{
	public DD_DIRECTDRAW_GLOBAL* lpDD;
	public DD_SURFACE_LOCAL* lpDDDestSurface;
	public RECTL rDest;
	public DD_SURFACE_LOCAL* lpDDSrcSurface;
	public RECTL rSrc;
	public uint32 dwFlags;
	public uint32 dwROPFlags;
	public DDBLTFX bltFX;
	public HRESULT ddRVal;
	public void* Blt;
	public BOOL IsClipped;
	public RECTL rOrigDest;
	public RECTL rOrigSrc;
	public uint32 dwRectCnt;
	public RECT* prDestRects;
	public uint32 dwAFlags;
	public DDARGB ddargbScaleFactors;
}

[CRepr]
public struct DD_LOCKDATA
{
	public DD_DIRECTDRAW_GLOBAL* lpDD;
	public DD_SURFACE_LOCAL* lpDDSurface;
	public uint32 bHasRect;
	public RECTL rArea;
	public void* lpSurfData;
	public HRESULT ddRVal;
	public void* Lock;
	public uint32 dwFlags;
	public uint fpProcess;
}

[CRepr]
public struct DD_UNLOCKDATA
{
	public DD_DIRECTDRAW_GLOBAL* lpDD;
	public DD_SURFACE_LOCAL* lpDDSurface;
	public HRESULT ddRVal;
	public void* Unlock;
}

[CRepr]
public struct DD_UPDATEOVERLAYDATA
{
	public DD_DIRECTDRAW_GLOBAL* lpDD;
	public DD_SURFACE_LOCAL* lpDDDestSurface;
	public RECTL rDest;
	public DD_SURFACE_LOCAL* lpDDSrcSurface;
	public RECTL rSrc;
	public uint32 dwFlags;
	public DDOVERLAYFX overlayFX;
	public HRESULT ddRVal;
	public void* UpdateOverlay;
}

[CRepr]
public struct DD_SETOVERLAYPOSITIONDATA
{
	public DD_DIRECTDRAW_GLOBAL* lpDD;
	public DD_SURFACE_LOCAL* lpDDSrcSurface;
	public DD_SURFACE_LOCAL* lpDDDestSurface;
	public int32 lXPos;
	public int32 lYPos;
	public HRESULT ddRVal;
	public void* SetOverlayPosition;
}

[CRepr]
public struct DD_SETPALETTEDATA
{
	public DD_DIRECTDRAW_GLOBAL* lpDD;
	public DD_SURFACE_LOCAL* lpDDSurface;
	public DD_PALETTE_GLOBAL* lpDDPalette;
	public HRESULT ddRVal;
	public void* SetPalette;
	public BOOL Attach;
}

[CRepr]
public struct DD_FLIPDATA
{
	public DD_DIRECTDRAW_GLOBAL* lpDD;
	public DD_SURFACE_LOCAL* lpSurfCurr;
	public DD_SURFACE_LOCAL* lpSurfTarg;
	public uint32 dwFlags;
	public HRESULT ddRVal;
	public void* Flip;
	public DD_SURFACE_LOCAL* lpSurfCurrLeft;
	public DD_SURFACE_LOCAL* lpSurfTargLeft;
}

[CRepr]
public struct DD_DESTROYSURFACEDATA
{
	public DD_DIRECTDRAW_GLOBAL* lpDD;
	public DD_SURFACE_LOCAL* lpDDSurface;
	public HRESULT ddRVal;
	public void* DestroySurface;
}

[CRepr]
public struct DD_SETCLIPLISTDATA
{
	public DD_DIRECTDRAW_GLOBAL* lpDD;
	public DD_SURFACE_LOCAL* lpDDSurface;
	public HRESULT ddRVal;
	public void* SetClipList;
}

[CRepr]
public struct DD_ADDATTACHEDSURFACEDATA
{
	public DD_DIRECTDRAW_GLOBAL* lpDD;
	public DD_SURFACE_LOCAL* lpDDSurface;
	public DD_SURFACE_LOCAL* lpSurfAttached;
	public HRESULT ddRVal;
	public void* AddAttachedSurface;
}

[CRepr]
public struct DD_SETCOLORKEYDATA
{
	public DD_DIRECTDRAW_GLOBAL* lpDD;
	public DD_SURFACE_LOCAL* lpDDSurface;
	public uint32 dwFlags;
	public DDCOLORKEY ckNew;
	public HRESULT ddRVal;
	public void* SetColorKey;
}

[CRepr]
public struct DD_GETBLTSTATUSDATA
{
	public DD_DIRECTDRAW_GLOBAL* lpDD;
	public DD_SURFACE_LOCAL* lpDDSurface;
	public uint32 dwFlags;
	public HRESULT ddRVal;
	public void* GetBltStatus;
}

[CRepr]
public struct DD_GETFLIPSTATUSDATA
{
	public DD_DIRECTDRAW_GLOBAL* lpDD;
	public DD_SURFACE_LOCAL* lpDDSurface;
	public uint32 dwFlags;
	public HRESULT ddRVal;
	public void* GetFlipStatus;
}

[CRepr]
public struct DD_DESTROYPALETTEDATA
{
	public DD_DIRECTDRAW_GLOBAL* lpDD;
	public DD_PALETTE_GLOBAL* lpDDPalette;
	public HRESULT ddRVal;
	public void* DestroyPalette;
}

[CRepr]
public struct DD_SETENTRIESDATA
{
	public DD_DIRECTDRAW_GLOBAL* lpDD;
	public DD_PALETTE_GLOBAL* lpDDPalette;
	public uint32 dwBase;
	public uint32 dwNumEntries;
	public PALETTEENTRY* lpEntries;
	public HRESULT ddRVal;
	public void* SetEntries;
}

[CRepr]
public struct DD_CREATESURFACEDATA
{
	public DD_DIRECTDRAW_GLOBAL* lpDD;
	public DDSURFACEDESC* lpDDSurfaceDesc;
	public DD_SURFACE_LOCAL** lplpSList;
	public uint32 dwSCnt;
	public HRESULT ddRVal;
	public void* CreateSurface;
}

[CRepr]
public struct DD_CANCREATESURFACEDATA
{
	public DD_DIRECTDRAW_GLOBAL* lpDD;
	public DDSURFACEDESC* lpDDSurfaceDesc;
	public uint32 bIsDifferentPixelFormat;
	public HRESULT ddRVal;
	public void* CanCreateSurface;
}

[CRepr]
public struct DD_CREATEPALETTEDATA
{
	public DD_DIRECTDRAW_GLOBAL* lpDD;
	public DD_PALETTE_GLOBAL* lpDDPalette;
	public PALETTEENTRY* lpColorTable;
	public HRESULT ddRVal;
	public void* CreatePalette;
	public BOOL is_excl;
}

[CRepr]
public struct DD_WAITFORVERTICALBLANKDATA
{
	public DD_DIRECTDRAW_GLOBAL* lpDD;
	public uint32 dwFlags;
	public uint32 bIsInVB;
	public uint hEvent;
	public HRESULT ddRVal;
	public void* WaitForVerticalBlank;
}

[CRepr]
public struct DD_DRVSETCOLORKEYDATA
{
	public DD_SURFACE_LOCAL* lpDDSurface;
	public uint32 dwFlags;
	public DDCOLORKEY ckNew;
	public HRESULT ddRVal;
	public void* SetColorKey;
}

[CRepr]
public struct DD_GETSCANLINEDATA
{
	public DD_DIRECTDRAW_GLOBAL* lpDD;
	public uint32 dwScanLine;
	public HRESULT ddRVal;
	public void* GetScanLine;
}

[CRepr]
public struct DD_MAPMEMORYDATA
{
	public DD_DIRECTDRAW_GLOBAL* lpDD;
	public BOOL bMap;
	public HANDLE hProcess;
	public uint fpProcess;
	public HRESULT ddRVal;
}

[CRepr]
public struct DD_CANCREATEVPORTDATA
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public DDVIDEOPORTDESC* lpDDVideoPortDesc;
	public HRESULT ddRVal;
	public void* CanCreateVideoPort;
}

[CRepr]
public struct DD_CREATEVPORTDATA
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public DDVIDEOPORTDESC* lpDDVideoPortDesc;
	public DD_VIDEOPORT_LOCAL* lpVideoPort;
	public HRESULT ddRVal;
	public void* CreateVideoPort;
}

[CRepr]
public struct DD_FLIPVPORTDATA
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public DD_VIDEOPORT_LOCAL* lpVideoPort;
	public DD_SURFACE_LOCAL* lpSurfCurr;
	public DD_SURFACE_LOCAL* lpSurfTarg;
	public HRESULT ddRVal;
	public void* FlipVideoPort;
}

[CRepr]
public struct DD_GETVPORTBANDWIDTHDATA
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public DD_VIDEOPORT_LOCAL* lpVideoPort;
	public DDPIXELFORMAT* lpddpfFormat;
	public uint32 dwWidth;
	public uint32 dwHeight;
	public uint32 dwFlags;
	public DDVIDEOPORTBANDWIDTH* lpBandwidth;
	public HRESULT ddRVal;
	public void* GetVideoPortBandwidth;
}

[CRepr]
public struct DD_GETVPORTINPUTFORMATDATA
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public DD_VIDEOPORT_LOCAL* lpVideoPort;
	public uint32 dwFlags;
	public DDPIXELFORMAT* lpddpfFormat;
	public uint32 dwNumFormats;
	public HRESULT ddRVal;
	public void* GetVideoPortInputFormats;
}

[CRepr]
public struct DD_GETVPORTOUTPUTFORMATDATA
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public DD_VIDEOPORT_LOCAL* lpVideoPort;
	public uint32 dwFlags;
	public DDPIXELFORMAT* lpddpfInputFormat;
	public DDPIXELFORMAT* lpddpfOutputFormats;
	public uint32 dwNumFormats;
	public HRESULT ddRVal;
	public void* GetVideoPortInputFormats;
}

[CRepr]
public struct DD_GETVPORTFIELDDATA
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public DD_VIDEOPORT_LOCAL* lpVideoPort;
	public BOOL bField;
	public HRESULT ddRVal;
	public void* GetVideoPortField;
}

[CRepr]
public struct DD_GETVPORTLINEDATA
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public DD_VIDEOPORT_LOCAL* lpVideoPort;
	public uint32 dwLine;
	public HRESULT ddRVal;
	public void* GetVideoPortLine;
}

[CRepr]
public struct DD_GETVPORTCONNECTDATA
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public uint32 dwPortId;
	public DDVIDEOPORTCONNECT* lpConnect;
	public uint32 dwNumEntries;
	public HRESULT ddRVal;
	public void* GetVideoPortConnectInfo;
}

[CRepr]
public struct DD_DESTROYVPORTDATA
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public DD_VIDEOPORT_LOCAL* lpVideoPort;
	public HRESULT ddRVal;
	public void* DestroyVideoPort;
}

[CRepr]
public struct DD_GETVPORTFLIPSTATUSDATA
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public uint fpSurface;
	public HRESULT ddRVal;
	public void* GetVideoPortFlipStatus;
}

[CRepr]
public struct DD_UPDATEVPORTDATA
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public DD_VIDEOPORT_LOCAL* lpVideoPort;
	public DD_SURFACE_INT** lplpDDSurface;
	public DD_SURFACE_INT** lplpDDVBISurface;
	public DDVIDEOPORTINFO* lpVideoInfo;
	public uint32 dwFlags;
	public uint32 dwNumAutoflip;
	public uint32 dwNumVBIAutoflip;
	public HRESULT ddRVal;
	public void* UpdateVideoPort;
}

[CRepr]
public struct DD_WAITFORVPORTSYNCDATA
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public DD_VIDEOPORT_LOCAL* lpVideoPort;
	public uint32 dwFlags;
	public uint32 dwLine;
	public uint32 dwTimeOut;
	public HRESULT ddRVal;
	public void* UpdateVideoPort;
}

[CRepr]
public struct DD_GETVPORTSIGNALDATA
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public DD_VIDEOPORT_LOCAL* lpVideoPort;
	public uint32 dwStatus;
	public HRESULT ddRVal;
	public void* GetVideoSignalStatus;
}

[CRepr]
public struct DD_VPORTCOLORDATA
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public DD_VIDEOPORT_LOCAL* lpVideoPort;
	public uint32 dwFlags;
	public DDCOLORCONTROL* lpColorData;
	public HRESULT ddRVal;
	public void* ColorControl;
}

[CRepr]
public struct DD_COLORCONTROLDATA
{
	public DD_DIRECTDRAW_GLOBAL* lpDD;
	public DD_SURFACE_LOCAL* lpDDSurface;
	public DDCOLORCONTROL* lpColorData;
	public uint32 dwFlags;
	public HRESULT ddRVal;
	public void* ColorControl;
}

[CRepr]
public struct DD_GETDRIVERINFODATA
{
	public void* dhpdev;
	public uint32 dwSize;
	public uint32 dwFlags;
	public Guid guidInfo;
	public uint32 dwExpectedSize;
	public void* lpvData;
	public uint32 dwActualSize;
	public HRESULT ddRVal;
}

[CRepr]
public struct DD_GETAVAILDRIVERMEMORYDATA
{
	public DD_DIRECTDRAW_GLOBAL* lpDD;
	public DDSCAPS DDSCaps;
	public uint32 dwTotal;
	public uint32 dwFree;
	public HRESULT ddRVal;
	public void* GetAvailDriverMemory;
}

[CRepr]
public struct DD_FREEDRIVERMEMORYDATA
{
	public DD_DIRECTDRAW_GLOBAL* lpDD;
	public DD_SURFACE_LOCAL* lpDDSurface;
	public HRESULT ddRVal;
	public void* FreeDriverMemory;
}

[CRepr]
public struct DD_SETEXCLUSIVEMODEDATA
{
	public DD_DIRECTDRAW_GLOBAL* lpDD;
	public uint32 dwEnterExcl;
	public uint32 dwReserved;
	public HRESULT ddRVal;
	public void* SetExclusiveMode;
}

[CRepr]
public struct DD_FLIPTOGDISURFACEDATA
{
	public DD_DIRECTDRAW_GLOBAL* lpDD;
	public uint32 dwToGDI;
	public uint32 dwReserved;
	public HRESULT ddRVal;
	public void* FlipToGDISurface;
}

[CRepr]
public struct DD_SYNCSURFACEDATA
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public DD_SURFACE_LOCAL* lpDDSurface;
	public uint32 dwSurfaceOffset;
	public uint fpLockPtr;
	public int32 lPitch;
	public uint32 dwOverlayOffset;
	public uint32 dwDriverReserved1;
	public uint32 dwDriverReserved2;
	public uint32 dwDriverReserved3;
	public uint32 dwDriverReserved4;
	public HRESULT ddRVal;
}

[CRepr]
public struct DD_SYNCVIDEOPORTDATA
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public DD_VIDEOPORT_LOCAL* lpVideoPort;
	public uint32 dwOriginOffset;
	public uint32 dwHeight;
	public uint32 dwVBIHeight;
	public uint32 dwDriverReserved1;
	public uint32 dwDriverReserved2;
	public uint32 dwDriverReserved3;
	public HRESULT ddRVal;
}

[CRepr]
public struct DD_GETMOCOMPGUIDSDATA
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public uint32 dwNumGuids;
	public Guid* lpGuids;
	public HRESULT ddRVal;
}

[CRepr]
public struct DD_GETMOCOMPFORMATSDATA
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public Guid* lpGuid;
	public uint32 dwNumFormats;
	public DDPIXELFORMAT* lpFormats;
	public HRESULT ddRVal;
}

[CRepr]
public struct DD_CREATEMOCOMPDATA
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public DD_MOTIONCOMP_LOCAL* lpMoComp;
	public Guid* lpGuid;
	public uint32 dwUncompWidth;
	public uint32 dwUncompHeight;
	public DDPIXELFORMAT ddUncompPixelFormat;
	public void* lpData;
	public uint32 dwDataSize;
	public HRESULT ddRVal;
}

[CRepr]
public struct DDCOMPBUFFERINFO
{
	public uint32 dwSize;
	public uint32 dwNumCompBuffers;
	public uint32 dwWidthToCreate;
	public uint32 dwHeightToCreate;
	public uint32 dwBytesToAllocate;
	public DDSCAPS2 ddCompCaps;
	public DDPIXELFORMAT ddPixelFormat;
}

[CRepr]
public struct DD_GETMOCOMPCOMPBUFFDATA
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public Guid* lpGuid;
	public uint32 dwWidth;
	public uint32 dwHeight;
	public DDPIXELFORMAT ddPixelFormat;
	public uint32 dwNumTypesCompBuffs;
	public DDCOMPBUFFERINFO* lpCompBuffInfo;
	public HRESULT ddRVal;
}

[CRepr]
public struct DD_GETINTERNALMOCOMPDATA
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public Guid* lpGuid;
	public uint32 dwWidth;
	public uint32 dwHeight;
	public DDPIXELFORMAT ddPixelFormat;
	public uint32 dwScratchMemAlloc;
	public HRESULT ddRVal;
}

[CRepr]
public struct DD_BEGINMOCOMPFRAMEDATA
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public DD_MOTIONCOMP_LOCAL* lpMoComp;
	public DD_SURFACE_LOCAL* lpDestSurface;
	public uint32 dwInputDataSize;
	public void* lpInputData;
	public uint32 dwOutputDataSize;
	public void* lpOutputData;
	public HRESULT ddRVal;
}

[CRepr]
public struct DD_ENDMOCOMPFRAMEDATA
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public DD_MOTIONCOMP_LOCAL* lpMoComp;
	public void* lpInputData;
	public uint32 dwInputDataSize;
	public HRESULT ddRVal;
}

[CRepr]
public struct DDMOCOMPBUFFERINFO
{
	public uint32 dwSize;
	public DD_SURFACE_LOCAL* lpCompSurface;
	public uint32 dwDataOffset;
	public uint32 dwDataSize;
	public void* lpPrivate;
}

[CRepr]
public struct DD_RENDERMOCOMPDATA
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public DD_MOTIONCOMP_LOCAL* lpMoComp;
	public uint32 dwNumBuffers;
	public DDMOCOMPBUFFERINFO* lpBufferInfo;
	public uint32 dwFunction;
	public void* lpInputData;
	public uint32 dwInputDataSize;
	public void* lpOutputData;
	public uint32 dwOutputDataSize;
	public HRESULT ddRVal;
}

[CRepr]
public struct DD_QUERYMOCOMPSTATUSDATA
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public DD_MOTIONCOMP_LOCAL* lpMoComp;
	public DD_SURFACE_LOCAL* lpSurface;
	public uint32 dwFlags;
	public HRESULT ddRVal;
}

[CRepr]
public struct DD_DESTROYMOCOMPDATA
{
	public DD_DIRECTDRAW_LOCAL* lpDD;
	public DD_MOTIONCOMP_LOCAL* lpMoComp;
	public HRESULT ddRVal;
}

[CRepr]
public struct DD_CREATESURFACEEXDATA
{
	public uint32 dwFlags;
	public DD_DIRECTDRAW_LOCAL* lpDDLcl;
	public DD_SURFACE_LOCAL* lpDDSLcl;
	public HRESULT ddRVal;
}

[CRepr]
public struct DD_GETDRIVERSTATEDATA
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public DD_DIRECTDRAW_GLOBAL* lpDD;
		public uint dwhContext;
	}
	public uint32 dwFlags;
	public using _Anonymous_e__Union Anonymous;
	public uint32* lpdwStates;
	public uint32 dwLength;
	public HRESULT ddRVal;
}

[CRepr]
public struct DD_DESTROYDDLOCALDATA
{
	public uint32 dwFlags;
	public DD_DIRECTDRAW_LOCAL* pDDLcl;
	public HRESULT ddRVal;
}

[CRepr]
public struct MDL
{
	[CRepr]
	public struct _EPROCESS
	{
	}
	public MDL* MdlNext;
	public int16 MdlSize;
	public int16 MdlFlags;
	public _EPROCESS* Process;
	public uint32* lpMappedSystemVa;
	public uint32* lpStartVa;
	public uint32 ByteCount;
	public uint32 ByteOffset;
}

[CRepr]
public struct DDSURFACEDATA
{
	public uint32 ddsCaps;
	public uint32 dwSurfaceOffset;
	public uint fpLockPtr;
	public uint32 dwWidth;
	public uint32 dwHeight;
	public int32 lPitch;
	public uint32 dwOverlayFlags;
	public uint32 dwOverlayOffset;
	public uint32 dwOverlaySrcWidth;
	public uint32 dwOverlaySrcHeight;
	public uint32 dwOverlayDestWidth;
	public uint32 dwOverlayDestHeight;
	public uint32 dwVideoPortId;
	public uint32 dwFormatFlags;
	public uint32 dwFormatFourCC;
	public uint32 dwFormatBitCount;
	public uint32 dwRBitMask;
	public uint32 dwGBitMask;
	public uint32 dwBBitMask;
	public uint32 dwDriverReserved1;
	public uint32 dwDriverReserved2;
	public uint32 dwDriverReserved3;
	public uint32 dwDriverReserved4;
}

[CRepr]
public struct DDVIDEOPORTDATA
{
	public uint32 dwVideoPortId;
	public uint32 dwVPFlags;
	public uint32 dwOriginOffset;
	public uint32 dwHeight;
	public uint32 dwVBIHeight;
	public uint32 dwDriverReserved1;
	public uint32 dwDriverReserved2;
	public uint32 dwDriverReserved3;
}

[CRepr]
public struct DX_IRQDATA
{
	public uint32 dwIrqFlags;
}

[CRepr]
public struct DDGETIRQINFO
{
	public uint32 dwFlags;
}

[CRepr]
public struct DDENABLEIRQINFO
{
	public uint32 dwIRQSources;
	public uint32 dwLine;
	public PDX_IRQCALLBACK IRQCallback;
	public DX_IRQDATA* lpIRQData;
}

[CRepr]
public struct DDSKIPNEXTFIELDINFO
{
	public DDVIDEOPORTDATA* lpVideoPortData;
	public uint32 dwSkipFlags;
}

[CRepr]
public struct DDBOBNEXTFIELDINFO
{
	public DDSURFACEDATA* lpSurface;
}

[CRepr]
public struct DDSETSTATEININFO
{
	public DDSURFACEDATA* lpSurfaceData;
	public DDVIDEOPORTDATA* lpVideoPortData;
}

[CRepr]
public struct DDSETSTATEOUTINFO
{
	public BOOL bSoftwareAutoflip;
	public uint32 dwSurfaceIndex;
	public uint32 dwVBISurfaceIndex;
}

[CRepr]
public struct DDLOCKININFO
{
	public DDSURFACEDATA* lpSurfaceData;
}

[CRepr]
public struct DDLOCKOUTINFO
{
	public uint dwSurfacePtr;
}

[CRepr]
public struct DDFLIPOVERLAYINFO
{
	public DDSURFACEDATA* lpCurrentSurface;
	public DDSURFACEDATA* lpTargetSurface;
	public uint32 dwFlags;
}

[CRepr]
public struct DDFLIPVIDEOPORTINFO
{
	public DDVIDEOPORTDATA* lpVideoPortData;
	public DDSURFACEDATA* lpCurrentSurface;
	public DDSURFACEDATA* lpTargetSurface;
	public uint32 dwFlipVPFlags;
}

[CRepr]
public struct DDGETPOLARITYININFO
{
	public DDVIDEOPORTDATA* lpVideoPortData;
}

[CRepr]
public struct DDGETPOLARITYOUTINFO
{
	public uint32 bPolarity;
}

[CRepr]
public struct DDGETCURRENTAUTOFLIPININFO
{
	public DDVIDEOPORTDATA* lpVideoPortData;
}

[CRepr]
public struct DDGETCURRENTAUTOFLIPOUTINFO
{
	public uint32 dwSurfaceIndex;
	public uint32 dwVBISurfaceIndex;
}

[CRepr]
public struct DDGETPREVIOUSAUTOFLIPININFO
{
	public DDVIDEOPORTDATA* lpVideoPortData;
}

[CRepr]
public struct DDGETPREVIOUSAUTOFLIPOUTINFO
{
	public uint32 dwSurfaceIndex;
	public uint32 dwVBISurfaceIndex;
}

[CRepr]
public struct DDTRANSFERININFO
{
	public DDSURFACEDATA* lpSurfaceData;
	public uint32 dwStartLine;
	public uint32 dwEndLine;
	public uint dwTransferID;
	public uint32 dwTransferFlags;
	public MDL* lpDestMDL;
}

[CRepr]
public struct DDTRANSFEROUTINFO
{
	public uint32 dwBufferPolarity;
}

[CRepr]
public struct DDGETTRANSFERSTATUSOUTINFO
{
	public uint dwTransferID;
}

[CRepr]
public struct DXAPI_INTERFACE
{
	public uint16 Size;
	public uint16 Version;
	public void* Context;
	public void* InterfaceReference;
	public void* InterfaceDereference;
	public PDX_GETIRQINFO DxGetIrqInfo;
	public PDX_ENABLEIRQ DxEnableIrq;
	public PDX_SKIPNEXTFIELD DxSkipNextField;
	public PDX_BOBNEXTFIELD DxBobNextField;
	public PDX_SETSTATE DxSetState;
	public PDX_LOCK DxLock;
	public PDX_FLIPOVERLAY DxFlipOverlay;
	public PDX_FLIPVIDEOPORT DxFlipVideoPort;
	public PDX_GETPOLARITY DxGetPolarity;
	public PDX_GETCURRENTAUTOFLIP DxGetCurrentAutoflip;
	public PDX_GETPREVIOUSAUTOFLIP DxGetPreviousAutoflip;
	public PDX_TRANSFER DxTransfer;
	public PDX_GETTRANSFERSTATUS DxGetTransferStatus;
}

#endregion

#region COM Types
[CRepr]struct IDirectDraw : IUnknown
{
	public new const Guid IID = .(0x6c14db80, 0xa733, 0x11ce, 0xa5, 0x21, 0x00, 0x20, 0xaf, 0x0b, 0xe5, 0x60);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Compact;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, IDirectDrawClipper** param1, IUnknown* param2) CreateClipper;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, PALETTEENTRY* param1, IDirectDrawPalette** param2, IUnknown* param3) CreatePalette;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSURFACEDESC* param0, IDirectDrawSurface** param1, IUnknown* param2) CreateSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawSurface* param0, IDirectDrawSurface** param1) DuplicateSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DDSURFACEDESC* param1, void* param2, LPDDENUMMODESCALLBACK param3) EnumDisplayModes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DDSURFACEDESC* param1, void* param2, LPDDENUMSURFACESCALLBACK param3) EnumSurfaces;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) FlipToGDISurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDCAPS_DX7* param0, DDCAPS_DX7* param1) GetCaps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSURFACEDESC* param0) GetDisplayMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* param0, uint32* param1) GetFourCCCodes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawSurface** param0) GetGDISurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* param0) GetMonitorFrequency;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* param0) GetScanLine;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* param0) GetVerticalBlankStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* param0) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RestoreDisplayMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND param0, uint32 param1) SetCooperativeLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, uint32 param1, uint32 param2) SetDisplayMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, HANDLE param1) WaitForVerticalBlank;
	}


	public HRESULT Compact() mut => VT.[Friend]Compact(&this);

	public HRESULT CreateClipper(uint32 param0, IDirectDrawClipper** param1, IUnknown* param2) mut => VT.[Friend]CreateClipper(&this, param0, param1, param2);

	public HRESULT CreatePalette(uint32 param0, PALETTEENTRY* param1, IDirectDrawPalette** param2, IUnknown* param3) mut => VT.[Friend]CreatePalette(&this, param0, param1, param2, param3);

	public HRESULT CreateSurface(DDSURFACEDESC* param0, IDirectDrawSurface** param1, IUnknown* param2) mut => VT.[Friend]CreateSurface(&this, param0, param1, param2);

	public HRESULT DuplicateSurface(IDirectDrawSurface* param0, IDirectDrawSurface** param1) mut => VT.[Friend]DuplicateSurface(&this, param0, param1);

	public HRESULT EnumDisplayModes(uint32 param0, DDSURFACEDESC* param1, void* param2, LPDDENUMMODESCALLBACK param3) mut => VT.[Friend]EnumDisplayModes(&this, param0, param1, param2, param3);

	public HRESULT EnumSurfaces(uint32 param0, DDSURFACEDESC* param1, void* param2, LPDDENUMSURFACESCALLBACK param3) mut => VT.[Friend]EnumSurfaces(&this, param0, param1, param2, param3);

	public HRESULT FlipToGDISurface() mut => VT.[Friend]FlipToGDISurface(&this);

	public HRESULT GetCaps(DDCAPS_DX7* param0, DDCAPS_DX7* param1) mut => VT.[Friend]GetCaps(&this, param0, param1);

	public HRESULT GetDisplayMode(DDSURFACEDESC* param0) mut => VT.[Friend]GetDisplayMode(&this, param0);

	public HRESULT GetFourCCCodes(uint32* param0, uint32* param1) mut => VT.[Friend]GetFourCCCodes(&this, param0, param1);

	public HRESULT GetGDISurface(IDirectDrawSurface** param0) mut => VT.[Friend]GetGDISurface(&this, param0);

	public HRESULT GetMonitorFrequency(uint32* param0) mut => VT.[Friend]GetMonitorFrequency(&this, param0);

	public HRESULT GetScanLine(uint32* param0) mut => VT.[Friend]GetScanLine(&this, param0);

	public HRESULT GetVerticalBlankStatus(int32* param0) mut => VT.[Friend]GetVerticalBlankStatus(&this, param0);

	public HRESULT Initialize(Guid* param0) mut => VT.[Friend]Initialize(&this, param0);

	public HRESULT RestoreDisplayMode() mut => VT.[Friend]RestoreDisplayMode(&this);

	public HRESULT SetCooperativeLevel(HWND param0, uint32 param1) mut => VT.[Friend]SetCooperativeLevel(&this, param0, param1);

	public HRESULT SetDisplayMode(uint32 param0, uint32 param1, uint32 param2) mut => VT.[Friend]SetDisplayMode(&this, param0, param1, param2);

	public HRESULT WaitForVerticalBlank(uint32 param0, HANDLE param1) mut => VT.[Friend]WaitForVerticalBlank(&this, param0, param1);
}

[CRepr]struct IDirectDraw2 : IUnknown
{
	public new const Guid IID = .(0xb3a6f3e0, 0x2b43, 0x11cf, 0xa2, 0xde, 0x00, 0xaa, 0x00, 0xb9, 0x33, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Compact;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, IDirectDrawClipper** param1, IUnknown* param2) CreateClipper;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, PALETTEENTRY* param1, IDirectDrawPalette** param2, IUnknown* param3) CreatePalette;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSURFACEDESC* param0, IDirectDrawSurface** param1, IUnknown* param2) CreateSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawSurface* param0, IDirectDrawSurface** param1) DuplicateSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DDSURFACEDESC* param1, void* param2, LPDDENUMMODESCALLBACK param3) EnumDisplayModes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DDSURFACEDESC* param1, void* param2, LPDDENUMSURFACESCALLBACK param3) EnumSurfaces;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) FlipToGDISurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDCAPS_DX7* param0, DDCAPS_DX7* param1) GetCaps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSURFACEDESC* param0) GetDisplayMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* param0, uint32* param1) GetFourCCCodes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawSurface** param0) GetGDISurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* param0) GetMonitorFrequency;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* param0) GetScanLine;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* param0) GetVerticalBlankStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* param0) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RestoreDisplayMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND param0, uint32 param1) SetCooperativeLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, uint32 param1, uint32 param2, uint32 param3, uint32 param4) SetDisplayMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, HANDLE param1) WaitForVerticalBlank;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSCAPS* param0, uint32* param1, uint32* param2) GetAvailableVidMem;
	}


	public HRESULT Compact() mut => VT.[Friend]Compact(&this);

	public HRESULT CreateClipper(uint32 param0, IDirectDrawClipper** param1, IUnknown* param2) mut => VT.[Friend]CreateClipper(&this, param0, param1, param2);

	public HRESULT CreatePalette(uint32 param0, PALETTEENTRY* param1, IDirectDrawPalette** param2, IUnknown* param3) mut => VT.[Friend]CreatePalette(&this, param0, param1, param2, param3);

	public HRESULT CreateSurface(DDSURFACEDESC* param0, IDirectDrawSurface** param1, IUnknown* param2) mut => VT.[Friend]CreateSurface(&this, param0, param1, param2);

	public HRESULT DuplicateSurface(IDirectDrawSurface* param0, IDirectDrawSurface** param1) mut => VT.[Friend]DuplicateSurface(&this, param0, param1);

	public HRESULT EnumDisplayModes(uint32 param0, DDSURFACEDESC* param1, void* param2, LPDDENUMMODESCALLBACK param3) mut => VT.[Friend]EnumDisplayModes(&this, param0, param1, param2, param3);

	public HRESULT EnumSurfaces(uint32 param0, DDSURFACEDESC* param1, void* param2, LPDDENUMSURFACESCALLBACK param3) mut => VT.[Friend]EnumSurfaces(&this, param0, param1, param2, param3);

	public HRESULT FlipToGDISurface() mut => VT.[Friend]FlipToGDISurface(&this);

	public HRESULT GetCaps(DDCAPS_DX7* param0, DDCAPS_DX7* param1) mut => VT.[Friend]GetCaps(&this, param0, param1);

	public HRESULT GetDisplayMode(DDSURFACEDESC* param0) mut => VT.[Friend]GetDisplayMode(&this, param0);

	public HRESULT GetFourCCCodes(uint32* param0, uint32* param1) mut => VT.[Friend]GetFourCCCodes(&this, param0, param1);

	public HRESULT GetGDISurface(IDirectDrawSurface** param0) mut => VT.[Friend]GetGDISurface(&this, param0);

	public HRESULT GetMonitorFrequency(uint32* param0) mut => VT.[Friend]GetMonitorFrequency(&this, param0);

	public HRESULT GetScanLine(uint32* param0) mut => VT.[Friend]GetScanLine(&this, param0);

	public HRESULT GetVerticalBlankStatus(int32* param0) mut => VT.[Friend]GetVerticalBlankStatus(&this, param0);

	public HRESULT Initialize(Guid* param0) mut => VT.[Friend]Initialize(&this, param0);

	public HRESULT RestoreDisplayMode() mut => VT.[Friend]RestoreDisplayMode(&this);

	public HRESULT SetCooperativeLevel(HWND param0, uint32 param1) mut => VT.[Friend]SetCooperativeLevel(&this, param0, param1);

	public HRESULT SetDisplayMode(uint32 param0, uint32 param1, uint32 param2, uint32 param3, uint32 param4) mut => VT.[Friend]SetDisplayMode(&this, param0, param1, param2, param3, param4);

	public HRESULT WaitForVerticalBlank(uint32 param0, HANDLE param1) mut => VT.[Friend]WaitForVerticalBlank(&this, param0, param1);

	public HRESULT GetAvailableVidMem(DDSCAPS* param0, uint32* param1, uint32* param2) mut => VT.[Friend]GetAvailableVidMem(&this, param0, param1, param2);
}

[CRepr]struct IDirectDraw4 : IUnknown
{
	public new const Guid IID = .(0x9c59509a, 0x39bd, 0x11d1, 0x8c, 0x4a, 0x00, 0xc0, 0x4f, 0xd9, 0x30, 0xc5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Compact;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, IDirectDrawClipper** param1, IUnknown* param2) CreateClipper;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, PALETTEENTRY* param1, IDirectDrawPalette** param2, IUnknown* param3) CreatePalette;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSURFACEDESC2* param0, IDirectDrawSurface4** param1, IUnknown* param2) CreateSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawSurface4* param0, IDirectDrawSurface4** param1) DuplicateSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DDSURFACEDESC2* param1, void* param2, LPDDENUMMODESCALLBACK2 param3) EnumDisplayModes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DDSURFACEDESC2* param1, void* param2, LPDDENUMSURFACESCALLBACK2 param3) EnumSurfaces;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) FlipToGDISurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDCAPS_DX7* param0, DDCAPS_DX7* param1) GetCaps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSURFACEDESC2* param0) GetDisplayMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* param0, uint32* param1) GetFourCCCodes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawSurface4** param0) GetGDISurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* param0) GetMonitorFrequency;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* param0) GetScanLine;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* param0) GetVerticalBlankStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* param0) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RestoreDisplayMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND param0, uint32 param1) SetCooperativeLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, uint32 param1, uint32 param2, uint32 param3, uint32 param4) SetDisplayMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, HANDLE param1) WaitForVerticalBlank;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSCAPS2* param0, uint32* param1, uint32* param2) GetAvailableVidMem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC param0, IDirectDrawSurface4** param1) GetSurfaceFromDC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RestoreAllSurfaces;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) TestCooperativeLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDDEVICEIDENTIFIER* param0, uint32 param1) GetDeviceIdentifier;
	}


	public HRESULT Compact() mut => VT.[Friend]Compact(&this);

	public HRESULT CreateClipper(uint32 param0, IDirectDrawClipper** param1, IUnknown* param2) mut => VT.[Friend]CreateClipper(&this, param0, param1, param2);

	public HRESULT CreatePalette(uint32 param0, PALETTEENTRY* param1, IDirectDrawPalette** param2, IUnknown* param3) mut => VT.[Friend]CreatePalette(&this, param0, param1, param2, param3);

	public HRESULT CreateSurface(DDSURFACEDESC2* param0, IDirectDrawSurface4** param1, IUnknown* param2) mut => VT.[Friend]CreateSurface(&this, param0, param1, param2);

	public HRESULT DuplicateSurface(IDirectDrawSurface4* param0, IDirectDrawSurface4** param1) mut => VT.[Friend]DuplicateSurface(&this, param0, param1);

	public HRESULT EnumDisplayModes(uint32 param0, DDSURFACEDESC2* param1, void* param2, LPDDENUMMODESCALLBACK2 param3) mut => VT.[Friend]EnumDisplayModes(&this, param0, param1, param2, param3);

	public HRESULT EnumSurfaces(uint32 param0, DDSURFACEDESC2* param1, void* param2, LPDDENUMSURFACESCALLBACK2 param3) mut => VT.[Friend]EnumSurfaces(&this, param0, param1, param2, param3);

	public HRESULT FlipToGDISurface() mut => VT.[Friend]FlipToGDISurface(&this);

	public HRESULT GetCaps(DDCAPS_DX7* param0, DDCAPS_DX7* param1) mut => VT.[Friend]GetCaps(&this, param0, param1);

	public HRESULT GetDisplayMode(DDSURFACEDESC2* param0) mut => VT.[Friend]GetDisplayMode(&this, param0);

	public HRESULT GetFourCCCodes(uint32* param0, uint32* param1) mut => VT.[Friend]GetFourCCCodes(&this, param0, param1);

	public HRESULT GetGDISurface(IDirectDrawSurface4** param0) mut => VT.[Friend]GetGDISurface(&this, param0);

	public HRESULT GetMonitorFrequency(uint32* param0) mut => VT.[Friend]GetMonitorFrequency(&this, param0);

	public HRESULT GetScanLine(uint32* param0) mut => VT.[Friend]GetScanLine(&this, param0);

	public HRESULT GetVerticalBlankStatus(int32* param0) mut => VT.[Friend]GetVerticalBlankStatus(&this, param0);

	public HRESULT Initialize(Guid* param0) mut => VT.[Friend]Initialize(&this, param0);

	public HRESULT RestoreDisplayMode() mut => VT.[Friend]RestoreDisplayMode(&this);

	public HRESULT SetCooperativeLevel(HWND param0, uint32 param1) mut => VT.[Friend]SetCooperativeLevel(&this, param0, param1);

	public HRESULT SetDisplayMode(uint32 param0, uint32 param1, uint32 param2, uint32 param3, uint32 param4) mut => VT.[Friend]SetDisplayMode(&this, param0, param1, param2, param3, param4);

	public HRESULT WaitForVerticalBlank(uint32 param0, HANDLE param1) mut => VT.[Friend]WaitForVerticalBlank(&this, param0, param1);

	public HRESULT GetAvailableVidMem(DDSCAPS2* param0, uint32* param1, uint32* param2) mut => VT.[Friend]GetAvailableVidMem(&this, param0, param1, param2);

	public HRESULT GetSurfaceFromDC(HDC param0, IDirectDrawSurface4** param1) mut => VT.[Friend]GetSurfaceFromDC(&this, param0, param1);

	public HRESULT RestoreAllSurfaces() mut => VT.[Friend]RestoreAllSurfaces(&this);

	public HRESULT TestCooperativeLevel() mut => VT.[Friend]TestCooperativeLevel(&this);

	public HRESULT GetDeviceIdentifier(DDDEVICEIDENTIFIER* param0, uint32 param1) mut => VT.[Friend]GetDeviceIdentifier(&this, param0, param1);
}

[CRepr]struct IDirectDraw7 : IUnknown
{
	public new const Guid IID = .(0x15e65ec0, 0x3b9c, 0x11d2, 0xb9, 0x2f, 0x00, 0x60, 0x97, 0x97, 0xea, 0x5b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Compact;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, IDirectDrawClipper** param1, IUnknown* param2) CreateClipper;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, PALETTEENTRY* param1, IDirectDrawPalette** param2, IUnknown* param3) CreatePalette;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSURFACEDESC2* param0, IDirectDrawSurface7** param1, IUnknown* param2) CreateSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawSurface7* param0, IDirectDrawSurface7** param1) DuplicateSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DDSURFACEDESC2* param1, void* param2, LPDDENUMMODESCALLBACK2 param3) EnumDisplayModes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DDSURFACEDESC2* param1, void* param2, LPDDENUMSURFACESCALLBACK7 param3) EnumSurfaces;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) FlipToGDISurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDCAPS_DX7* param0, DDCAPS_DX7* param1) GetCaps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSURFACEDESC2* param0) GetDisplayMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* param0, uint32* param1) GetFourCCCodes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawSurface7** param0) GetGDISurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* param0) GetMonitorFrequency;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* param0) GetScanLine;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* param0) GetVerticalBlankStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* param0) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RestoreDisplayMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND param0, uint32 param1) SetCooperativeLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, uint32 param1, uint32 param2, uint32 param3, uint32 param4) SetDisplayMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, HANDLE param1) WaitForVerticalBlank;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSCAPS2* param0, uint32* param1, uint32* param2) GetAvailableVidMem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC param0, IDirectDrawSurface7** param1) GetSurfaceFromDC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RestoreAllSurfaces;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) TestCooperativeLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDDEVICEIDENTIFIER2* param0, uint32 param1) GetDeviceIdentifier;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SIZE* param0, uint32 param1, uint32 param2) StartModeTest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, uint32* param1) EvaluateMode;
	}


	public HRESULT Compact() mut => VT.[Friend]Compact(&this);

	public HRESULT CreateClipper(uint32 param0, IDirectDrawClipper** param1, IUnknown* param2) mut => VT.[Friend]CreateClipper(&this, param0, param1, param2);

	public HRESULT CreatePalette(uint32 param0, PALETTEENTRY* param1, IDirectDrawPalette** param2, IUnknown* param3) mut => VT.[Friend]CreatePalette(&this, param0, param1, param2, param3);

	public HRESULT CreateSurface(DDSURFACEDESC2* param0, IDirectDrawSurface7** param1, IUnknown* param2) mut => VT.[Friend]CreateSurface(&this, param0, param1, param2);

	public HRESULT DuplicateSurface(IDirectDrawSurface7* param0, IDirectDrawSurface7** param1) mut => VT.[Friend]DuplicateSurface(&this, param0, param1);

	public HRESULT EnumDisplayModes(uint32 param0, DDSURFACEDESC2* param1, void* param2, LPDDENUMMODESCALLBACK2 param3) mut => VT.[Friend]EnumDisplayModes(&this, param0, param1, param2, param3);

	public HRESULT EnumSurfaces(uint32 param0, DDSURFACEDESC2* param1, void* param2, LPDDENUMSURFACESCALLBACK7 param3) mut => VT.[Friend]EnumSurfaces(&this, param0, param1, param2, param3);

	public HRESULT FlipToGDISurface() mut => VT.[Friend]FlipToGDISurface(&this);

	public HRESULT GetCaps(DDCAPS_DX7* param0, DDCAPS_DX7* param1) mut => VT.[Friend]GetCaps(&this, param0, param1);

	public HRESULT GetDisplayMode(DDSURFACEDESC2* param0) mut => VT.[Friend]GetDisplayMode(&this, param0);

	public HRESULT GetFourCCCodes(uint32* param0, uint32* param1) mut => VT.[Friend]GetFourCCCodes(&this, param0, param1);

	public HRESULT GetGDISurface(IDirectDrawSurface7** param0) mut => VT.[Friend]GetGDISurface(&this, param0);

	public HRESULT GetMonitorFrequency(uint32* param0) mut => VT.[Friend]GetMonitorFrequency(&this, param0);

	public HRESULT GetScanLine(uint32* param0) mut => VT.[Friend]GetScanLine(&this, param0);

	public HRESULT GetVerticalBlankStatus(int32* param0) mut => VT.[Friend]GetVerticalBlankStatus(&this, param0);

	public HRESULT Initialize(Guid* param0) mut => VT.[Friend]Initialize(&this, param0);

	public HRESULT RestoreDisplayMode() mut => VT.[Friend]RestoreDisplayMode(&this);

	public HRESULT SetCooperativeLevel(HWND param0, uint32 param1) mut => VT.[Friend]SetCooperativeLevel(&this, param0, param1);

	public HRESULT SetDisplayMode(uint32 param0, uint32 param1, uint32 param2, uint32 param3, uint32 param4) mut => VT.[Friend]SetDisplayMode(&this, param0, param1, param2, param3, param4);

	public HRESULT WaitForVerticalBlank(uint32 param0, HANDLE param1) mut => VT.[Friend]WaitForVerticalBlank(&this, param0, param1);

	public HRESULT GetAvailableVidMem(DDSCAPS2* param0, uint32* param1, uint32* param2) mut => VT.[Friend]GetAvailableVidMem(&this, param0, param1, param2);

	public HRESULT GetSurfaceFromDC(HDC param0, IDirectDrawSurface7** param1) mut => VT.[Friend]GetSurfaceFromDC(&this, param0, param1);

	public HRESULT RestoreAllSurfaces() mut => VT.[Friend]RestoreAllSurfaces(&this);

	public HRESULT TestCooperativeLevel() mut => VT.[Friend]TestCooperativeLevel(&this);

	public HRESULT GetDeviceIdentifier(DDDEVICEIDENTIFIER2* param0, uint32 param1) mut => VT.[Friend]GetDeviceIdentifier(&this, param0, param1);

	public HRESULT StartModeTest(SIZE* param0, uint32 param1, uint32 param2) mut => VT.[Friend]StartModeTest(&this, param0, param1, param2);

	public HRESULT EvaluateMode(uint32 param0, uint32* param1) mut => VT.[Friend]EvaluateMode(&this, param0, param1);
}

[CRepr]struct IDirectDrawPalette : IUnknown
{
	public new const Guid IID = .(0x6c14db84, 0xa733, 0x11ce, 0xa5, 0x21, 0x00, 0x20, 0xaf, 0x0b, 0xe5, 0x60);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* param0) GetCaps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, uint32 param1, uint32 param2, PALETTEENTRY* param3) GetEntries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDraw* param0, uint32 param1, PALETTEENTRY* param2) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, uint32 param1, uint32 param2, PALETTEENTRY* param3) SetEntries;
	}


	public HRESULT GetCaps(uint32* param0) mut => VT.[Friend]GetCaps(&this, param0);

	public HRESULT GetEntries(uint32 param0, uint32 param1, uint32 param2, PALETTEENTRY* param3) mut => VT.[Friend]GetEntries(&this, param0, param1, param2, param3);

	public HRESULT Initialize(IDirectDraw* param0, uint32 param1, PALETTEENTRY* param2) mut => VT.[Friend]Initialize(&this, param0, param1, param2);

	public HRESULT SetEntries(uint32 param0, uint32 param1, uint32 param2, PALETTEENTRY* param3) mut => VT.[Friend]SetEntries(&this, param0, param1, param2, param3);
}

[CRepr]struct IDirectDrawClipper : IUnknown
{
	public new const Guid IID = .(0x6c14db85, 0xa733, 0x11ce, 0xa5, 0x21, 0x00, 0x20, 0xaf, 0x0b, 0xe5, 0x60);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* param0, RGNDATA* param1, uint32* param2) GetClipList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND* param0) GetHWnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDraw* param0, uint32 param1) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* param0) IsClipListChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RGNDATA* param0, uint32 param1) SetClipList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, HWND param1) SetHWnd;
	}


	public HRESULT GetClipList(RECT* param0, RGNDATA* param1, uint32* param2) mut => VT.[Friend]GetClipList(&this, param0, param1, param2);

	public HRESULT GetHWnd(HWND* param0) mut => VT.[Friend]GetHWnd(&this, param0);

	public HRESULT Initialize(IDirectDraw* param0, uint32 param1) mut => VT.[Friend]Initialize(&this, param0, param1);

	public HRESULT IsClipListChanged(BOOL* param0) mut => VT.[Friend]IsClipListChanged(&this, param0);

	public HRESULT SetClipList(RGNDATA* param0, uint32 param1) mut => VT.[Friend]SetClipList(&this, param0, param1);

	public HRESULT SetHWnd(uint32 param0, HWND param1) mut => VT.[Friend]SetHWnd(&this, param0, param1);
}

[CRepr]struct IDirectDrawSurface : IUnknown
{
	public new const Guid IID = .(0x6c14db81, 0xa733, 0x11ce, 0xa5, 0x21, 0x00, 0x20, 0xaf, 0x0b, 0xe5, 0x60);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawSurface* param0) AddAttachedSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* param0) AddOverlayDirtyRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* param0, IDirectDrawSurface* param1, RECT* param2, uint32 param3, DDBLTFX* param4) Blt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDBLTBATCH* param0, uint32 param1, uint32 param2) BltBatch;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, uint32 param1, IDirectDrawSurface* param2, RECT* param3, uint32 param4) BltFast;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, IDirectDrawSurface* param1) DeleteAttachedSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* param0, LPDDENUMSURFACESCALLBACK param1) EnumAttachedSurfaces;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, void* param1, LPDDENUMSURFACESCALLBACK param2) EnumOverlayZOrders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawSurface* param0, uint32 param1) Flip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSCAPS* param0, IDirectDrawSurface** param1) GetAttachedSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) GetBltStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSCAPS* param0) GetCaps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawClipper** param0) GetClipper;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DDCOLORKEY* param1) GetColorKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC* param0) GetDC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) GetFlipStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* param0, int32* param1) GetOverlayPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawPalette** param0) GetPalette;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDPIXELFORMAT* param0) GetPixelFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSURFACEDESC* param0) GetSurfaceDesc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDraw* param0, DDSURFACEDESC* param1) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsLost;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* param0, DDSURFACEDESC* param1, uint32 param2, HANDLE param3) Lock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC param0) ReleaseDC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Restore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawClipper* param0) SetClipper;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DDCOLORKEY* param1) SetColorKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 param0, int32 param1) SetOverlayPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawPalette* param0) SetPalette;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* param0) Unlock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* param0, IDirectDrawSurface* param1, RECT* param2, uint32 param3, DDOVERLAYFX* param4) UpdateOverlay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) UpdateOverlayDisplay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, IDirectDrawSurface* param1) UpdateOverlayZOrder;
	}


	public HRESULT AddAttachedSurface(IDirectDrawSurface* param0) mut => VT.[Friend]AddAttachedSurface(&this, param0);

	public HRESULT AddOverlayDirtyRect(RECT* param0) mut => VT.[Friend]AddOverlayDirtyRect(&this, param0);

	public HRESULT Blt(RECT* param0, IDirectDrawSurface* param1, RECT* param2, uint32 param3, DDBLTFX* param4) mut => VT.[Friend]Blt(&this, param0, param1, param2, param3, param4);

	public HRESULT BltBatch(DDBLTBATCH* param0, uint32 param1, uint32 param2) mut => VT.[Friend]BltBatch(&this, param0, param1, param2);

	public HRESULT BltFast(uint32 param0, uint32 param1, IDirectDrawSurface* param2, RECT* param3, uint32 param4) mut => VT.[Friend]BltFast(&this, param0, param1, param2, param3, param4);

	public HRESULT DeleteAttachedSurface(uint32 param0, IDirectDrawSurface* param1) mut => VT.[Friend]DeleteAttachedSurface(&this, param0, param1);

	public HRESULT EnumAttachedSurfaces(void* param0, LPDDENUMSURFACESCALLBACK param1) mut => VT.[Friend]EnumAttachedSurfaces(&this, param0, param1);

	public HRESULT EnumOverlayZOrders(uint32 param0, void* param1, LPDDENUMSURFACESCALLBACK param2) mut => VT.[Friend]EnumOverlayZOrders(&this, param0, param1, param2);

	public HRESULT Flip(IDirectDrawSurface* param0, uint32 param1) mut => VT.[Friend]Flip(&this, param0, param1);

	public HRESULT GetAttachedSurface(DDSCAPS* param0, IDirectDrawSurface** param1) mut => VT.[Friend]GetAttachedSurface(&this, param0, param1);

	public HRESULT GetBltStatus(uint32 param0) mut => VT.[Friend]GetBltStatus(&this, param0);

	public HRESULT GetCaps(DDSCAPS* param0) mut => VT.[Friend]GetCaps(&this, param0);

	public HRESULT GetClipper(IDirectDrawClipper** param0) mut => VT.[Friend]GetClipper(&this, param0);

	public HRESULT GetColorKey(uint32 param0, DDCOLORKEY* param1) mut => VT.[Friend]GetColorKey(&this, param0, param1);

	public HRESULT GetDC(HDC* param0) mut => VT.[Friend]GetDC(&this, param0);

	public HRESULT GetFlipStatus(uint32 param0) mut => VT.[Friend]GetFlipStatus(&this, param0);

	public HRESULT GetOverlayPosition(int32* param0, int32* param1) mut => VT.[Friend]GetOverlayPosition(&this, param0, param1);

	public HRESULT GetPalette(IDirectDrawPalette** param0) mut => VT.[Friend]GetPalette(&this, param0);

	public HRESULT GetPixelFormat(DDPIXELFORMAT* param0) mut => VT.[Friend]GetPixelFormat(&this, param0);

	public HRESULT GetSurfaceDesc(DDSURFACEDESC* param0) mut => VT.[Friend]GetSurfaceDesc(&this, param0);

	public HRESULT Initialize(IDirectDraw* param0, DDSURFACEDESC* param1) mut => VT.[Friend]Initialize(&this, param0, param1);

	public HRESULT IsLost() mut => VT.[Friend]IsLost(&this);

	public HRESULT Lock(RECT* param0, DDSURFACEDESC* param1, uint32 param2, HANDLE param3) mut => VT.[Friend]Lock(&this, param0, param1, param2, param3);

	public HRESULT ReleaseDC(HDC param0) mut => VT.[Friend]ReleaseDC(&this, param0);

	public HRESULT Restore() mut => VT.[Friend]Restore(&this);

	public HRESULT SetClipper(IDirectDrawClipper* param0) mut => VT.[Friend]SetClipper(&this, param0);

	public HRESULT SetColorKey(uint32 param0, DDCOLORKEY* param1) mut => VT.[Friend]SetColorKey(&this, param0, param1);

	public HRESULT SetOverlayPosition(int32 param0, int32 param1) mut => VT.[Friend]SetOverlayPosition(&this, param0, param1);

	public HRESULT SetPalette(IDirectDrawPalette* param0) mut => VT.[Friend]SetPalette(&this, param0);

	public HRESULT Unlock(void* param0) mut => VT.[Friend]Unlock(&this, param0);

	public HRESULT UpdateOverlay(RECT* param0, IDirectDrawSurface* param1, RECT* param2, uint32 param3, DDOVERLAYFX* param4) mut => VT.[Friend]UpdateOverlay(&this, param0, param1, param2, param3, param4);

	public HRESULT UpdateOverlayDisplay(uint32 param0) mut => VT.[Friend]UpdateOverlayDisplay(&this, param0);

	public HRESULT UpdateOverlayZOrder(uint32 param0, IDirectDrawSurface* param1) mut => VT.[Friend]UpdateOverlayZOrder(&this, param0, param1);
}

[CRepr]struct IDirectDrawSurface2 : IUnknown
{
	public new const Guid IID = .(0x57805885, 0x6eec, 0x11cf, 0x94, 0x41, 0xa8, 0x23, 0x03, 0xc1, 0x0e, 0x27);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawSurface2* param0) AddAttachedSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* param0) AddOverlayDirtyRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* param0, IDirectDrawSurface2* param1, RECT* param2, uint32 param3, DDBLTFX* param4) Blt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDBLTBATCH* param0, uint32 param1, uint32 param2) BltBatch;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, uint32 param1, IDirectDrawSurface2* param2, RECT* param3, uint32 param4) BltFast;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, IDirectDrawSurface2* param1) DeleteAttachedSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* param0, LPDDENUMSURFACESCALLBACK param1) EnumAttachedSurfaces;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, void* param1, LPDDENUMSURFACESCALLBACK param2) EnumOverlayZOrders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawSurface2* param0, uint32 param1) Flip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSCAPS* param0, IDirectDrawSurface2** param1) GetAttachedSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) GetBltStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSCAPS* param0) GetCaps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawClipper** param0) GetClipper;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DDCOLORKEY* param1) GetColorKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC* param0) GetDC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) GetFlipStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* param0, int32* param1) GetOverlayPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawPalette** param0) GetPalette;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDPIXELFORMAT* param0) GetPixelFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSURFACEDESC* param0) GetSurfaceDesc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDraw* param0, DDSURFACEDESC* param1) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsLost;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* param0, DDSURFACEDESC* param1, uint32 param2, HANDLE param3) Lock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC param0) ReleaseDC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Restore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawClipper* param0) SetClipper;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DDCOLORKEY* param1) SetColorKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 param0, int32 param1) SetOverlayPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawPalette* param0) SetPalette;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* param0) Unlock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* param0, IDirectDrawSurface2* param1, RECT* param2, uint32 param3, DDOVERLAYFX* param4) UpdateOverlay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) UpdateOverlayDisplay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, IDirectDrawSurface2* param1) UpdateOverlayZOrder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void** param0) GetDDInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) PageLock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) PageUnlock;
	}


	public HRESULT AddAttachedSurface(IDirectDrawSurface2* param0) mut => VT.[Friend]AddAttachedSurface(&this, param0);

	public HRESULT AddOverlayDirtyRect(RECT* param0) mut => VT.[Friend]AddOverlayDirtyRect(&this, param0);

	public HRESULT Blt(RECT* param0, IDirectDrawSurface2* param1, RECT* param2, uint32 param3, DDBLTFX* param4) mut => VT.[Friend]Blt(&this, param0, param1, param2, param3, param4);

	public HRESULT BltBatch(DDBLTBATCH* param0, uint32 param1, uint32 param2) mut => VT.[Friend]BltBatch(&this, param0, param1, param2);

	public HRESULT BltFast(uint32 param0, uint32 param1, IDirectDrawSurface2* param2, RECT* param3, uint32 param4) mut => VT.[Friend]BltFast(&this, param0, param1, param2, param3, param4);

	public HRESULT DeleteAttachedSurface(uint32 param0, IDirectDrawSurface2* param1) mut => VT.[Friend]DeleteAttachedSurface(&this, param0, param1);

	public HRESULT EnumAttachedSurfaces(void* param0, LPDDENUMSURFACESCALLBACK param1) mut => VT.[Friend]EnumAttachedSurfaces(&this, param0, param1);

	public HRESULT EnumOverlayZOrders(uint32 param0, void* param1, LPDDENUMSURFACESCALLBACK param2) mut => VT.[Friend]EnumOverlayZOrders(&this, param0, param1, param2);

	public HRESULT Flip(IDirectDrawSurface2* param0, uint32 param1) mut => VT.[Friend]Flip(&this, param0, param1);

	public HRESULT GetAttachedSurface(DDSCAPS* param0, IDirectDrawSurface2** param1) mut => VT.[Friend]GetAttachedSurface(&this, param0, param1);

	public HRESULT GetBltStatus(uint32 param0) mut => VT.[Friend]GetBltStatus(&this, param0);

	public HRESULT GetCaps(DDSCAPS* param0) mut => VT.[Friend]GetCaps(&this, param0);

	public HRESULT GetClipper(IDirectDrawClipper** param0) mut => VT.[Friend]GetClipper(&this, param0);

	public HRESULT GetColorKey(uint32 param0, DDCOLORKEY* param1) mut => VT.[Friend]GetColorKey(&this, param0, param1);

	public HRESULT GetDC(HDC* param0) mut => VT.[Friend]GetDC(&this, param0);

	public HRESULT GetFlipStatus(uint32 param0) mut => VT.[Friend]GetFlipStatus(&this, param0);

	public HRESULT GetOverlayPosition(int32* param0, int32* param1) mut => VT.[Friend]GetOverlayPosition(&this, param0, param1);

	public HRESULT GetPalette(IDirectDrawPalette** param0) mut => VT.[Friend]GetPalette(&this, param0);

	public HRESULT GetPixelFormat(DDPIXELFORMAT* param0) mut => VT.[Friend]GetPixelFormat(&this, param0);

	public HRESULT GetSurfaceDesc(DDSURFACEDESC* param0) mut => VT.[Friend]GetSurfaceDesc(&this, param0);

	public HRESULT Initialize(IDirectDraw* param0, DDSURFACEDESC* param1) mut => VT.[Friend]Initialize(&this, param0, param1);

	public HRESULT IsLost() mut => VT.[Friend]IsLost(&this);

	public HRESULT Lock(RECT* param0, DDSURFACEDESC* param1, uint32 param2, HANDLE param3) mut => VT.[Friend]Lock(&this, param0, param1, param2, param3);

	public HRESULT ReleaseDC(HDC param0) mut => VT.[Friend]ReleaseDC(&this, param0);

	public HRESULT Restore() mut => VT.[Friend]Restore(&this);

	public HRESULT SetClipper(IDirectDrawClipper* param0) mut => VT.[Friend]SetClipper(&this, param0);

	public HRESULT SetColorKey(uint32 param0, DDCOLORKEY* param1) mut => VT.[Friend]SetColorKey(&this, param0, param1);

	public HRESULT SetOverlayPosition(int32 param0, int32 param1) mut => VT.[Friend]SetOverlayPosition(&this, param0, param1);

	public HRESULT SetPalette(IDirectDrawPalette* param0) mut => VT.[Friend]SetPalette(&this, param0);

	public HRESULT Unlock(void* param0) mut => VT.[Friend]Unlock(&this, param0);

	public HRESULT UpdateOverlay(RECT* param0, IDirectDrawSurface2* param1, RECT* param2, uint32 param3, DDOVERLAYFX* param4) mut => VT.[Friend]UpdateOverlay(&this, param0, param1, param2, param3, param4);

	public HRESULT UpdateOverlayDisplay(uint32 param0) mut => VT.[Friend]UpdateOverlayDisplay(&this, param0);

	public HRESULT UpdateOverlayZOrder(uint32 param0, IDirectDrawSurface2* param1) mut => VT.[Friend]UpdateOverlayZOrder(&this, param0, param1);

	public HRESULT GetDDInterface(void** param0) mut => VT.[Friend]GetDDInterface(&this, param0);

	public HRESULT PageLock(uint32 param0) mut => VT.[Friend]PageLock(&this, param0);

	public HRESULT PageUnlock(uint32 param0) mut => VT.[Friend]PageUnlock(&this, param0);
}

[CRepr]struct IDirectDrawSurface3 : IUnknown
{
	public new const Guid IID = .(0xda044e00, 0x69b2, 0x11d0, 0xa1, 0xd5, 0x00, 0xaa, 0x00, 0xb8, 0xdf, 0xbb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawSurface3* param0) AddAttachedSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* param0) AddOverlayDirtyRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* param0, IDirectDrawSurface3* param1, RECT* param2, uint32 param3, DDBLTFX* param4) Blt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDBLTBATCH* param0, uint32 param1, uint32 param2) BltBatch;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, uint32 param1, IDirectDrawSurface3* param2, RECT* param3, uint32 param4) BltFast;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, IDirectDrawSurface3* param1) DeleteAttachedSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* param0, LPDDENUMSURFACESCALLBACK param1) EnumAttachedSurfaces;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, void* param1, LPDDENUMSURFACESCALLBACK param2) EnumOverlayZOrders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawSurface3* param0, uint32 param1) Flip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSCAPS* param0, IDirectDrawSurface3** param1) GetAttachedSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) GetBltStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSCAPS* param0) GetCaps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawClipper** param0) GetClipper;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DDCOLORKEY* param1) GetColorKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC* param0) GetDC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) GetFlipStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* param0, int32* param1) GetOverlayPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawPalette** param0) GetPalette;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDPIXELFORMAT* param0) GetPixelFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSURFACEDESC* param0) GetSurfaceDesc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDraw* param0, DDSURFACEDESC* param1) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsLost;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* param0, DDSURFACEDESC* param1, uint32 param2, HANDLE param3) Lock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC param0) ReleaseDC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Restore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawClipper* param0) SetClipper;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DDCOLORKEY* param1) SetColorKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 param0, int32 param1) SetOverlayPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawPalette* param0) SetPalette;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* param0) Unlock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* param0, IDirectDrawSurface3* param1, RECT* param2, uint32 param3, DDOVERLAYFX* param4) UpdateOverlay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) UpdateOverlayDisplay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, IDirectDrawSurface3* param1) UpdateOverlayZOrder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void** param0) GetDDInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) PageLock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) PageUnlock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSURFACEDESC* param0, uint32 param1) SetSurfaceDesc;
	}


	public HRESULT AddAttachedSurface(IDirectDrawSurface3* param0) mut => VT.[Friend]AddAttachedSurface(&this, param0);

	public HRESULT AddOverlayDirtyRect(RECT* param0) mut => VT.[Friend]AddOverlayDirtyRect(&this, param0);

	public HRESULT Blt(RECT* param0, IDirectDrawSurface3* param1, RECT* param2, uint32 param3, DDBLTFX* param4) mut => VT.[Friend]Blt(&this, param0, param1, param2, param3, param4);

	public HRESULT BltBatch(DDBLTBATCH* param0, uint32 param1, uint32 param2) mut => VT.[Friend]BltBatch(&this, param0, param1, param2);

	public HRESULT BltFast(uint32 param0, uint32 param1, IDirectDrawSurface3* param2, RECT* param3, uint32 param4) mut => VT.[Friend]BltFast(&this, param0, param1, param2, param3, param4);

	public HRESULT DeleteAttachedSurface(uint32 param0, IDirectDrawSurface3* param1) mut => VT.[Friend]DeleteAttachedSurface(&this, param0, param1);

	public HRESULT EnumAttachedSurfaces(void* param0, LPDDENUMSURFACESCALLBACK param1) mut => VT.[Friend]EnumAttachedSurfaces(&this, param0, param1);

	public HRESULT EnumOverlayZOrders(uint32 param0, void* param1, LPDDENUMSURFACESCALLBACK param2) mut => VT.[Friend]EnumOverlayZOrders(&this, param0, param1, param2);

	public HRESULT Flip(IDirectDrawSurface3* param0, uint32 param1) mut => VT.[Friend]Flip(&this, param0, param1);

	public HRESULT GetAttachedSurface(DDSCAPS* param0, IDirectDrawSurface3** param1) mut => VT.[Friend]GetAttachedSurface(&this, param0, param1);

	public HRESULT GetBltStatus(uint32 param0) mut => VT.[Friend]GetBltStatus(&this, param0);

	public HRESULT GetCaps(DDSCAPS* param0) mut => VT.[Friend]GetCaps(&this, param0);

	public HRESULT GetClipper(IDirectDrawClipper** param0) mut => VT.[Friend]GetClipper(&this, param0);

	public HRESULT GetColorKey(uint32 param0, DDCOLORKEY* param1) mut => VT.[Friend]GetColorKey(&this, param0, param1);

	public HRESULT GetDC(HDC* param0) mut => VT.[Friend]GetDC(&this, param0);

	public HRESULT GetFlipStatus(uint32 param0) mut => VT.[Friend]GetFlipStatus(&this, param0);

	public HRESULT GetOverlayPosition(int32* param0, int32* param1) mut => VT.[Friend]GetOverlayPosition(&this, param0, param1);

	public HRESULT GetPalette(IDirectDrawPalette** param0) mut => VT.[Friend]GetPalette(&this, param0);

	public HRESULT GetPixelFormat(DDPIXELFORMAT* param0) mut => VT.[Friend]GetPixelFormat(&this, param0);

	public HRESULT GetSurfaceDesc(DDSURFACEDESC* param0) mut => VT.[Friend]GetSurfaceDesc(&this, param0);

	public HRESULT Initialize(IDirectDraw* param0, DDSURFACEDESC* param1) mut => VT.[Friend]Initialize(&this, param0, param1);

	public HRESULT IsLost() mut => VT.[Friend]IsLost(&this);

	public HRESULT Lock(RECT* param0, DDSURFACEDESC* param1, uint32 param2, HANDLE param3) mut => VT.[Friend]Lock(&this, param0, param1, param2, param3);

	public HRESULT ReleaseDC(HDC param0) mut => VT.[Friend]ReleaseDC(&this, param0);

	public HRESULT Restore() mut => VT.[Friend]Restore(&this);

	public HRESULT SetClipper(IDirectDrawClipper* param0) mut => VT.[Friend]SetClipper(&this, param0);

	public HRESULT SetColorKey(uint32 param0, DDCOLORKEY* param1) mut => VT.[Friend]SetColorKey(&this, param0, param1);

	public HRESULT SetOverlayPosition(int32 param0, int32 param1) mut => VT.[Friend]SetOverlayPosition(&this, param0, param1);

	public HRESULT SetPalette(IDirectDrawPalette* param0) mut => VT.[Friend]SetPalette(&this, param0);

	public HRESULT Unlock(void* param0) mut => VT.[Friend]Unlock(&this, param0);

	public HRESULT UpdateOverlay(RECT* param0, IDirectDrawSurface3* param1, RECT* param2, uint32 param3, DDOVERLAYFX* param4) mut => VT.[Friend]UpdateOverlay(&this, param0, param1, param2, param3, param4);

	public HRESULT UpdateOverlayDisplay(uint32 param0) mut => VT.[Friend]UpdateOverlayDisplay(&this, param0);

	public HRESULT UpdateOverlayZOrder(uint32 param0, IDirectDrawSurface3* param1) mut => VT.[Friend]UpdateOverlayZOrder(&this, param0, param1);

	public HRESULT GetDDInterface(void** param0) mut => VT.[Friend]GetDDInterface(&this, param0);

	public HRESULT PageLock(uint32 param0) mut => VT.[Friend]PageLock(&this, param0);

	public HRESULT PageUnlock(uint32 param0) mut => VT.[Friend]PageUnlock(&this, param0);

	public HRESULT SetSurfaceDesc(DDSURFACEDESC* param0, uint32 param1) mut => VT.[Friend]SetSurfaceDesc(&this, param0, param1);
}

[CRepr]struct IDirectDrawSurface4 : IUnknown
{
	public new const Guid IID = .(0x0b2b8630, 0xad35, 0x11d0, 0x8e, 0xa6, 0x00, 0x60, 0x97, 0x97, 0xea, 0x5b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawSurface4* param0) AddAttachedSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* param0) AddOverlayDirtyRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* param0, IDirectDrawSurface4* param1, RECT* param2, uint32 param3, DDBLTFX* param4) Blt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDBLTBATCH* param0, uint32 param1, uint32 param2) BltBatch;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, uint32 param1, IDirectDrawSurface4* param2, RECT* param3, uint32 param4) BltFast;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, IDirectDrawSurface4* param1) DeleteAttachedSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* param0, LPDDENUMSURFACESCALLBACK2 param1) EnumAttachedSurfaces;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, void* param1, LPDDENUMSURFACESCALLBACK2 param2) EnumOverlayZOrders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawSurface4* param0, uint32 param1) Flip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSCAPS2* param0, IDirectDrawSurface4** param1) GetAttachedSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) GetBltStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSCAPS2* param0) GetCaps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawClipper** param0) GetClipper;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DDCOLORKEY* param1) GetColorKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC* param0) GetDC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) GetFlipStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* param0, int32* param1) GetOverlayPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawPalette** param0) GetPalette;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDPIXELFORMAT* param0) GetPixelFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSURFACEDESC2* param0) GetSurfaceDesc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDraw* param0, DDSURFACEDESC2* param1) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsLost;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* param0, DDSURFACEDESC2* param1, uint32 param2, HANDLE param3) Lock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC param0) ReleaseDC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Restore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawClipper* param0) SetClipper;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DDCOLORKEY* param1) SetColorKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 param0, int32 param1) SetOverlayPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawPalette* param0) SetPalette;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* param0) Unlock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* param0, IDirectDrawSurface4* param1, RECT* param2, uint32 param3, DDOVERLAYFX* param4) UpdateOverlay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) UpdateOverlayDisplay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, IDirectDrawSurface4* param1) UpdateOverlayZOrder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void** param0) GetDDInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) PageLock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) PageUnlock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSURFACEDESC2* param0, uint32 param1) SetSurfaceDesc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0, void* param1, uint32 param2, uint32 param3) SetPrivateData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0, void* param1, uint32* param2) GetPrivateData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0) FreePrivateData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* param0) GetUniquenessValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ChangeUniquenessValue;
	}


	public HRESULT AddAttachedSurface(IDirectDrawSurface4* param0) mut => VT.[Friend]AddAttachedSurface(&this, param0);

	public HRESULT AddOverlayDirtyRect(RECT* param0) mut => VT.[Friend]AddOverlayDirtyRect(&this, param0);

	public HRESULT Blt(RECT* param0, IDirectDrawSurface4* param1, RECT* param2, uint32 param3, DDBLTFX* param4) mut => VT.[Friend]Blt(&this, param0, param1, param2, param3, param4);

	public HRESULT BltBatch(DDBLTBATCH* param0, uint32 param1, uint32 param2) mut => VT.[Friend]BltBatch(&this, param0, param1, param2);

	public HRESULT BltFast(uint32 param0, uint32 param1, IDirectDrawSurface4* param2, RECT* param3, uint32 param4) mut => VT.[Friend]BltFast(&this, param0, param1, param2, param3, param4);

	public HRESULT DeleteAttachedSurface(uint32 param0, IDirectDrawSurface4* param1) mut => VT.[Friend]DeleteAttachedSurface(&this, param0, param1);

	public HRESULT EnumAttachedSurfaces(void* param0, LPDDENUMSURFACESCALLBACK2 param1) mut => VT.[Friend]EnumAttachedSurfaces(&this, param0, param1);

	public HRESULT EnumOverlayZOrders(uint32 param0, void* param1, LPDDENUMSURFACESCALLBACK2 param2) mut => VT.[Friend]EnumOverlayZOrders(&this, param0, param1, param2);

	public HRESULT Flip(IDirectDrawSurface4* param0, uint32 param1) mut => VT.[Friend]Flip(&this, param0, param1);

	public HRESULT GetAttachedSurface(DDSCAPS2* param0, IDirectDrawSurface4** param1) mut => VT.[Friend]GetAttachedSurface(&this, param0, param1);

	public HRESULT GetBltStatus(uint32 param0) mut => VT.[Friend]GetBltStatus(&this, param0);

	public HRESULT GetCaps(DDSCAPS2* param0) mut => VT.[Friend]GetCaps(&this, param0);

	public HRESULT GetClipper(IDirectDrawClipper** param0) mut => VT.[Friend]GetClipper(&this, param0);

	public HRESULT GetColorKey(uint32 param0, DDCOLORKEY* param1) mut => VT.[Friend]GetColorKey(&this, param0, param1);

	public HRESULT GetDC(HDC* param0) mut => VT.[Friend]GetDC(&this, param0);

	public HRESULT GetFlipStatus(uint32 param0) mut => VT.[Friend]GetFlipStatus(&this, param0);

	public HRESULT GetOverlayPosition(int32* param0, int32* param1) mut => VT.[Friend]GetOverlayPosition(&this, param0, param1);

	public HRESULT GetPalette(IDirectDrawPalette** param0) mut => VT.[Friend]GetPalette(&this, param0);

	public HRESULT GetPixelFormat(DDPIXELFORMAT* param0) mut => VT.[Friend]GetPixelFormat(&this, param0);

	public HRESULT GetSurfaceDesc(DDSURFACEDESC2* param0) mut => VT.[Friend]GetSurfaceDesc(&this, param0);

	public HRESULT Initialize(IDirectDraw* param0, DDSURFACEDESC2* param1) mut => VT.[Friend]Initialize(&this, param0, param1);

	public HRESULT IsLost() mut => VT.[Friend]IsLost(&this);

	public HRESULT Lock(RECT* param0, DDSURFACEDESC2* param1, uint32 param2, HANDLE param3) mut => VT.[Friend]Lock(&this, param0, param1, param2, param3);

	public HRESULT ReleaseDC(HDC param0) mut => VT.[Friend]ReleaseDC(&this, param0);

	public HRESULT Restore() mut => VT.[Friend]Restore(&this);

	public HRESULT SetClipper(IDirectDrawClipper* param0) mut => VT.[Friend]SetClipper(&this, param0);

	public HRESULT SetColorKey(uint32 param0, DDCOLORKEY* param1) mut => VT.[Friend]SetColorKey(&this, param0, param1);

	public HRESULT SetOverlayPosition(int32 param0, int32 param1) mut => VT.[Friend]SetOverlayPosition(&this, param0, param1);

	public HRESULT SetPalette(IDirectDrawPalette* param0) mut => VT.[Friend]SetPalette(&this, param0);

	public HRESULT Unlock(RECT* param0) mut => VT.[Friend]Unlock(&this, param0);

	public HRESULT UpdateOverlay(RECT* param0, IDirectDrawSurface4* param1, RECT* param2, uint32 param3, DDOVERLAYFX* param4) mut => VT.[Friend]UpdateOverlay(&this, param0, param1, param2, param3, param4);

	public HRESULT UpdateOverlayDisplay(uint32 param0) mut => VT.[Friend]UpdateOverlayDisplay(&this, param0);

	public HRESULT UpdateOverlayZOrder(uint32 param0, IDirectDrawSurface4* param1) mut => VT.[Friend]UpdateOverlayZOrder(&this, param0, param1);

	public HRESULT GetDDInterface(void** param0) mut => VT.[Friend]GetDDInterface(&this, param0);

	public HRESULT PageLock(uint32 param0) mut => VT.[Friend]PageLock(&this, param0);

	public HRESULT PageUnlock(uint32 param0) mut => VT.[Friend]PageUnlock(&this, param0);

	public HRESULT SetSurfaceDesc(DDSURFACEDESC2* param0, uint32 param1) mut => VT.[Friend]SetSurfaceDesc(&this, param0, param1);

	public HRESULT SetPrivateData(in Guid param0, void* param1, uint32 param2, uint32 param3) mut => VT.[Friend]SetPrivateData(&this, param0, param1, param2, param3);

	public HRESULT GetPrivateData(in Guid param0, void* param1, uint32* param2) mut => VT.[Friend]GetPrivateData(&this, param0, param1, param2);

	public HRESULT FreePrivateData(in Guid param0) mut => VT.[Friend]FreePrivateData(&this, param0);

	public HRESULT GetUniquenessValue(uint32* param0) mut => VT.[Friend]GetUniquenessValue(&this, param0);

	public HRESULT ChangeUniquenessValue() mut => VT.[Friend]ChangeUniquenessValue(&this);
}

[CRepr]struct IDirectDrawSurface7 : IUnknown
{
	public new const Guid IID = .(0x06675a80, 0x3b9b, 0x11d2, 0xb9, 0x2f, 0x00, 0x60, 0x97, 0x97, 0xea, 0x5b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawSurface7* param0) AddAttachedSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* param0) AddOverlayDirtyRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* param0, IDirectDrawSurface7* param1, RECT* param2, uint32 param3, DDBLTFX* param4) Blt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDBLTBATCH* param0, uint32 param1, uint32 param2) BltBatch;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, uint32 param1, IDirectDrawSurface7* param2, RECT* param3, uint32 param4) BltFast;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, IDirectDrawSurface7* param1) DeleteAttachedSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* param0, LPDDENUMSURFACESCALLBACK7 param1) EnumAttachedSurfaces;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, void* param1, LPDDENUMSURFACESCALLBACK7 param2) EnumOverlayZOrders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawSurface7* param0, uint32 param1) Flip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSCAPS2* param0, IDirectDrawSurface7** param1) GetAttachedSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) GetBltStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSCAPS2* param0) GetCaps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawClipper** param0) GetClipper;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DDCOLORKEY* param1) GetColorKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC* param0) GetDC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) GetFlipStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* param0, int32* param1) GetOverlayPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawPalette** param0) GetPalette;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDPIXELFORMAT* param0) GetPixelFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSURFACEDESC2* param0) GetSurfaceDesc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDraw* param0, DDSURFACEDESC2* param1) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsLost;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* param0, DDSURFACEDESC2* param1, uint32 param2, HANDLE param3) Lock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC param0) ReleaseDC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Restore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawClipper* param0) SetClipper;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DDCOLORKEY* param1) SetColorKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 param0, int32 param1) SetOverlayPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawPalette* param0) SetPalette;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* param0) Unlock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* param0, IDirectDrawSurface7* param1, RECT* param2, uint32 param3, DDOVERLAYFX* param4) UpdateOverlay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) UpdateOverlayDisplay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, IDirectDrawSurface7* param1) UpdateOverlayZOrder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void** param0) GetDDInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) PageLock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) PageUnlock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDSURFACEDESC2* param0, uint32 param1) SetSurfaceDesc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0, void* param1, uint32 param2, uint32 param3) SetPrivateData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0, void* param1, uint32* param2) GetPrivateData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid param0) FreePrivateData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* param0) GetUniquenessValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ChangeUniquenessValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) SetPriority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* param0) GetPriority;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0) SetLOD;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* param0) GetLOD;
	}


	public HRESULT AddAttachedSurface(IDirectDrawSurface7* param0) mut => VT.[Friend]AddAttachedSurface(&this, param0);

	public HRESULT AddOverlayDirtyRect(RECT* param0) mut => VT.[Friend]AddOverlayDirtyRect(&this, param0);

	public HRESULT Blt(RECT* param0, IDirectDrawSurface7* param1, RECT* param2, uint32 param3, DDBLTFX* param4) mut => VT.[Friend]Blt(&this, param0, param1, param2, param3, param4);

	public HRESULT BltBatch(DDBLTBATCH* param0, uint32 param1, uint32 param2) mut => VT.[Friend]BltBatch(&this, param0, param1, param2);

	public HRESULT BltFast(uint32 param0, uint32 param1, IDirectDrawSurface7* param2, RECT* param3, uint32 param4) mut => VT.[Friend]BltFast(&this, param0, param1, param2, param3, param4);

	public HRESULT DeleteAttachedSurface(uint32 param0, IDirectDrawSurface7* param1) mut => VT.[Friend]DeleteAttachedSurface(&this, param0, param1);

	public HRESULT EnumAttachedSurfaces(void* param0, LPDDENUMSURFACESCALLBACK7 param1) mut => VT.[Friend]EnumAttachedSurfaces(&this, param0, param1);

	public HRESULT EnumOverlayZOrders(uint32 param0, void* param1, LPDDENUMSURFACESCALLBACK7 param2) mut => VT.[Friend]EnumOverlayZOrders(&this, param0, param1, param2);

	public HRESULT Flip(IDirectDrawSurface7* param0, uint32 param1) mut => VT.[Friend]Flip(&this, param0, param1);

	public HRESULT GetAttachedSurface(DDSCAPS2* param0, IDirectDrawSurface7** param1) mut => VT.[Friend]GetAttachedSurface(&this, param0, param1);

	public HRESULT GetBltStatus(uint32 param0) mut => VT.[Friend]GetBltStatus(&this, param0);

	public HRESULT GetCaps(DDSCAPS2* param0) mut => VT.[Friend]GetCaps(&this, param0);

	public HRESULT GetClipper(IDirectDrawClipper** param0) mut => VT.[Friend]GetClipper(&this, param0);

	public HRESULT GetColorKey(uint32 param0, DDCOLORKEY* param1) mut => VT.[Friend]GetColorKey(&this, param0, param1);

	public HRESULT GetDC(HDC* param0) mut => VT.[Friend]GetDC(&this, param0);

	public HRESULT GetFlipStatus(uint32 param0) mut => VT.[Friend]GetFlipStatus(&this, param0);

	public HRESULT GetOverlayPosition(int32* param0, int32* param1) mut => VT.[Friend]GetOverlayPosition(&this, param0, param1);

	public HRESULT GetPalette(IDirectDrawPalette** param0) mut => VT.[Friend]GetPalette(&this, param0);

	public HRESULT GetPixelFormat(DDPIXELFORMAT* param0) mut => VT.[Friend]GetPixelFormat(&this, param0);

	public HRESULT GetSurfaceDesc(DDSURFACEDESC2* param0) mut => VT.[Friend]GetSurfaceDesc(&this, param0);

	public HRESULT Initialize(IDirectDraw* param0, DDSURFACEDESC2* param1) mut => VT.[Friend]Initialize(&this, param0, param1);

	public HRESULT IsLost() mut => VT.[Friend]IsLost(&this);

	public HRESULT Lock(RECT* param0, DDSURFACEDESC2* param1, uint32 param2, HANDLE param3) mut => VT.[Friend]Lock(&this, param0, param1, param2, param3);

	public HRESULT ReleaseDC(HDC param0) mut => VT.[Friend]ReleaseDC(&this, param0);

	public HRESULT Restore() mut => VT.[Friend]Restore(&this);

	public HRESULT SetClipper(IDirectDrawClipper* param0) mut => VT.[Friend]SetClipper(&this, param0);

	public HRESULT SetColorKey(uint32 param0, DDCOLORKEY* param1) mut => VT.[Friend]SetColorKey(&this, param0, param1);

	public HRESULT SetOverlayPosition(int32 param0, int32 param1) mut => VT.[Friend]SetOverlayPosition(&this, param0, param1);

	public HRESULT SetPalette(IDirectDrawPalette* param0) mut => VT.[Friend]SetPalette(&this, param0);

	public HRESULT Unlock(RECT* param0) mut => VT.[Friend]Unlock(&this, param0);

	public HRESULT UpdateOverlay(RECT* param0, IDirectDrawSurface7* param1, RECT* param2, uint32 param3, DDOVERLAYFX* param4) mut => VT.[Friend]UpdateOverlay(&this, param0, param1, param2, param3, param4);

	public HRESULT UpdateOverlayDisplay(uint32 param0) mut => VT.[Friend]UpdateOverlayDisplay(&this, param0);

	public HRESULT UpdateOverlayZOrder(uint32 param0, IDirectDrawSurface7* param1) mut => VT.[Friend]UpdateOverlayZOrder(&this, param0, param1);

	public HRESULT GetDDInterface(void** param0) mut => VT.[Friend]GetDDInterface(&this, param0);

	public HRESULT PageLock(uint32 param0) mut => VT.[Friend]PageLock(&this, param0);

	public HRESULT PageUnlock(uint32 param0) mut => VT.[Friend]PageUnlock(&this, param0);

	public HRESULT SetSurfaceDesc(DDSURFACEDESC2* param0, uint32 param1) mut => VT.[Friend]SetSurfaceDesc(&this, param0, param1);

	public HRESULT SetPrivateData(in Guid param0, void* param1, uint32 param2, uint32 param3) mut => VT.[Friend]SetPrivateData(&this, param0, param1, param2, param3);

	public HRESULT GetPrivateData(in Guid param0, void* param1, uint32* param2) mut => VT.[Friend]GetPrivateData(&this, param0, param1, param2);

	public HRESULT FreePrivateData(in Guid param0) mut => VT.[Friend]FreePrivateData(&this, param0);

	public HRESULT GetUniquenessValue(uint32* param0) mut => VT.[Friend]GetUniquenessValue(&this, param0);

	public HRESULT ChangeUniquenessValue() mut => VT.[Friend]ChangeUniquenessValue(&this);

	public HRESULT SetPriority(uint32 param0) mut => VT.[Friend]SetPriority(&this, param0);

	public HRESULT GetPriority(uint32* param0) mut => VT.[Friend]GetPriority(&this, param0);

	public HRESULT SetLOD(uint32 param0) mut => VT.[Friend]SetLOD(&this, param0);

	public HRESULT GetLOD(uint32* param0) mut => VT.[Friend]GetLOD(&this, param0);
}

[CRepr]struct IDirectDrawColorControl : IUnknown
{
	public new const Guid IID = .(0x4b9f0ee0, 0x0d7e, 0x11d0, 0x9b, 0x06, 0x00, 0xa0, 0xc9, 0x03, 0xa3, 0xb8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDCOLORCONTROL* param0) GetColorControls;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDCOLORCONTROL* param0) SetColorControls;
	}


	public HRESULT GetColorControls(DDCOLORCONTROL* param0) mut => VT.[Friend]GetColorControls(&this, param0);

	public HRESULT SetColorControls(DDCOLORCONTROL* param0) mut => VT.[Friend]SetColorControls(&this, param0);
}

[CRepr]struct IDirectDrawGammaControl : IUnknown
{
	public new const Guid IID = .(0x69c11c3e, 0xb46b, 0x11d1, 0xad, 0x7a, 0x00, 0xc0, 0x4f, 0xc2, 0x9b, 0x4e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DDGAMMARAMP* param1) GetGammaRamp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DDGAMMARAMP* param1) SetGammaRamp;
	}


	public HRESULT GetGammaRamp(uint32 param0, DDGAMMARAMP* param1) mut => VT.[Friend]GetGammaRamp(&this, param0, param1);

	public HRESULT SetGammaRamp(uint32 param0, DDGAMMARAMP* param1) mut => VT.[Friend]SetGammaRamp(&this, param0, param1);
}

[CRepr]struct IDDVideoPortContainer : IUnknown
{
	public new const Guid IID = .(0x6c142760, 0xa733, 0x11ce, 0xa5, 0x21, 0x00, 0x20, 0xaf, 0x0b, 0xe5, 0x60);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DDVIDEOPORTDESC* param1, IDirectDrawVideoPort** param2, IUnknown* param3) CreateVideoPort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DDVIDEOPORTCAPS* param1, void* param2, LPDDENUMVIDEOCALLBACK param3) EnumVideoPorts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, uint32* pcInfo, DDVIDEOPORTCONNECT* param2) GetVideoPortConnectInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, DDVIDEOPORTSTATUS* param1) QueryVideoPortStatus;
	}


	public HRESULT CreateVideoPort(uint32 param0, DDVIDEOPORTDESC* param1, IDirectDrawVideoPort** param2, IUnknown* param3) mut => VT.[Friend]CreateVideoPort(&this, param0, param1, param2, param3);

	public HRESULT EnumVideoPorts(uint32 param0, DDVIDEOPORTCAPS* param1, void* param2, LPDDENUMVIDEOCALLBACK param3) mut => VT.[Friend]EnumVideoPorts(&this, param0, param1, param2, param3);

	public HRESULT GetVideoPortConnectInfo(uint32 param0, uint32* pcInfo, DDVIDEOPORTCONNECT* param2) mut => VT.[Friend]GetVideoPortConnectInfo(&this, param0, pcInfo, param2);

	public HRESULT QueryVideoPortStatus(uint32 param0, DDVIDEOPORTSTATUS* param1) mut => VT.[Friend]QueryVideoPortStatus(&this, param0, param1);
}

[CRepr]struct IDirectDrawVideoPort : IUnknown
{
	public new const Guid IID = .(0xb36d93e0, 0x2b43, 0x11cf, 0xa2, 0xde, 0x00, 0xaa, 0x00, 0xb9, 0x33, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawSurface* param0, uint32 param1) Flip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDPIXELFORMAT* param0, uint32 param1, uint32 param2, uint32 param3, DDVIDEOPORTBANDWIDTH* param4) GetBandwidthInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDCOLORCONTROL* param0) GetColorControls;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* lpNumFormats, DDPIXELFORMAT* param1, uint32 param2) GetInputFormats;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDPIXELFORMAT* param0, uint32* lpNumFormats, DDPIXELFORMAT* param2, uint32 param3) GetOutputFormats;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* param0) GetFieldPolarity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* param0) GetVideoLine;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* param0) GetVideoSignalStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDCOLORCONTROL* param0) SetColorControls;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDirectDrawSurface* param0, uint32 param1) SetTargetSurface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDVIDEOPORTINFO* param0) StartVideo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) StopVideo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDVIDEOPORTINFO* param0) UpdateVideo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 param0, uint32 param1, uint32 param2) WaitForSync;
	}


	public HRESULT Flip(IDirectDrawSurface* param0, uint32 param1) mut => VT.[Friend]Flip(&this, param0, param1);

	public HRESULT GetBandwidthInfo(DDPIXELFORMAT* param0, uint32 param1, uint32 param2, uint32 param3, DDVIDEOPORTBANDWIDTH* param4) mut => VT.[Friend]GetBandwidthInfo(&this, param0, param1, param2, param3, param4);

	public HRESULT GetColorControls(DDCOLORCONTROL* param0) mut => VT.[Friend]GetColorControls(&this, param0);

	public HRESULT GetInputFormats(uint32* lpNumFormats, DDPIXELFORMAT* param1, uint32 param2) mut => VT.[Friend]GetInputFormats(&this, lpNumFormats, param1, param2);

	public HRESULT GetOutputFormats(DDPIXELFORMAT* param0, uint32* lpNumFormats, DDPIXELFORMAT* param2, uint32 param3) mut => VT.[Friend]GetOutputFormats(&this, param0, lpNumFormats, param2, param3);

	public HRESULT GetFieldPolarity(int32* param0) mut => VT.[Friend]GetFieldPolarity(&this, param0);

	public HRESULT GetVideoLine(uint32* param0) mut => VT.[Friend]GetVideoLine(&this, param0);

	public HRESULT GetVideoSignalStatus(uint32* param0) mut => VT.[Friend]GetVideoSignalStatus(&this, param0);

	public HRESULT SetColorControls(DDCOLORCONTROL* param0) mut => VT.[Friend]SetColorControls(&this, param0);

	public HRESULT SetTargetSurface(IDirectDrawSurface* param0, uint32 param1) mut => VT.[Friend]SetTargetSurface(&this, param0, param1);

	public HRESULT StartVideo(DDVIDEOPORTINFO* param0) mut => VT.[Friend]StartVideo(&this, param0);

	public HRESULT StopVideo() mut => VT.[Friend]StopVideo(&this);

	public HRESULT UpdateVideo(DDVIDEOPORTINFO* param0) mut => VT.[Friend]UpdateVideo(&this, param0);

	public HRESULT WaitForSync(uint32 param0, uint32 param1, uint32 param2) mut => VT.[Friend]WaitForSync(&this, param0, param1, param2);
}

[CRepr]struct IDirectDrawVideoPortNotify : IUnknown
{
	public new const Guid IID = .(0xa655fb94, 0x0589, 0x4e57, 0xb3, 0x33, 0x56, 0x7a, 0x89, 0x46, 0x8c, 0x88);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE* param0, DDVIDEOPORTNOTIFY* param1) AcquireNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE param0) ReleaseNotification;
	}


	public HRESULT AcquireNotification(HANDLE* param0, DDVIDEOPORTNOTIFY* param1) mut => VT.[Friend]AcquireNotification(&this, param0, param1);

	public HRESULT ReleaseNotification(HANDLE param0) mut => VT.[Friend]ReleaseNotification(&this, param0);
}

[CRepr]struct IDirectDrawKernel : IUnknown
{
	public new const Guid IID = .(0x8d56c120, 0x6a08, 0x11d0, 0x9b, 0x06, 0x00, 0xa0, 0xc9, 0x03, 0xa3, 0xb8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DDKERNELCAPS* param0) GetCaps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint* param0) GetKernelHandle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ReleaseKernelHandle;
	}


	public HRESULT GetCaps(DDKERNELCAPS* param0) mut => VT.[Friend]GetCaps(&this, param0);

	public HRESULT GetKernelHandle(uint* param0) mut => VT.[Friend]GetKernelHandle(&this, param0);

	public HRESULT ReleaseKernelHandle() mut => VT.[Friend]ReleaseKernelHandle(&this);
}

[CRepr]struct IDirectDrawSurfaceKernel : IUnknown
{
	public new const Guid IID = .(0x60755da0, 0x6a40, 0x11d0, 0x9b, 0x06, 0x00, 0xa0, 0xc9, 0x03, 0xa3, 0xb8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint* param0) GetKernelHandle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ReleaseKernelHandle;
	}


	public HRESULT GetKernelHandle(uint* param0) mut => VT.[Friend]GetKernelHandle(&this, param0);

	public HRESULT ReleaseKernelHandle() mut => VT.[Friend]ReleaseKernelHandle(&this);
}

#endregion

#region Functions
public static
{
	[Import("DDRAW.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DirectDrawEnumerateW(LPDDENUMCALLBACKW lpCallback, void* lpContext);

	[Import("DDRAW.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DirectDrawEnumerateA(LPDDENUMCALLBACKA lpCallback, void* lpContext);
	public static HRESULT DirectDrawEnumerate(LPDDENUMCALLBACKA lpCallback, void* lpContext) => DirectDrawEnumerateA(lpCallback, lpContext);

	[Import("DDRAW.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DirectDrawEnumerateExW(LPDDENUMCALLBACKEXW lpCallback, void* lpContext, uint32 dwFlags);

	[Import("DDRAW.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DirectDrawEnumerateExA(LPDDENUMCALLBACKEXA lpCallback, void* lpContext, uint32 dwFlags);
	public static HRESULT DirectDrawEnumerateEx(LPDDENUMCALLBACKEXA lpCallback, void* lpContext, uint32 dwFlags) => DirectDrawEnumerateExA(lpCallback, lpContext, dwFlags);

	[Import("DDRAW.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DirectDrawCreate(Guid* lpGUID, IDirectDraw** lplpDD, IUnknown* pUnkOuter);

	[Import("DDRAW.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DirectDrawCreateEx(Guid* lpGuid, void** lplpDD, in Guid iid, IUnknown* pUnkOuter);

	[Import("DDRAW.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DirectDrawCreateClipper(uint32 dwFlags, IDirectDrawClipper** lplpDDClipper, IUnknown* pUnkOuter);

}
#endregion
