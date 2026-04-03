using Win32.Graphics.Gdi;
using Win32.Foundation;
using System;

namespace Win32.Graphics.OpenGL;

#region Constants
public static
{
	public const uint32 GL_VERSION_1_1 = 1;
	public const uint32 GL_ACCUM = 256;
	public const uint32 GL_LOAD = 257;
	public const uint32 GL_RETURN = 258;
	public const uint32 GL_MULT = 259;
	public const uint32 GL_ADD = 260;
	public const uint32 GL_NEVER = 512;
	public const uint32 GL_LESS = 513;
	public const uint32 GL_EQUAL = 514;
	public const uint32 GL_LEQUAL = 515;
	public const uint32 GL_GREATER = 516;
	public const uint32 GL_NOTEQUAL = 517;
	public const uint32 GL_GEQUAL = 518;
	public const uint32 GL_ALWAYS = 519;
	public const uint32 GL_CURRENT_BIT = 1;
	public const uint32 GL_POINT_BIT = 2;
	public const uint32 GL_LINE_BIT = 4;
	public const uint32 GL_POLYGON_BIT = 8;
	public const uint32 GL_POLYGON_STIPPLE_BIT = 16;
	public const uint32 GL_PIXEL_MODE_BIT = 32;
	public const uint32 GL_LIGHTING_BIT = 64;
	public const uint32 GL_FOG_BIT = 128;
	public const uint32 GL_DEPTH_BUFFER_BIT = 256;
	public const uint32 GL_ACCUM_BUFFER_BIT = 512;
	public const uint32 GL_STENCIL_BUFFER_BIT = 1024;
	public const uint32 GL_VIEWPORT_BIT = 2048;
	public const uint32 GL_TRANSFORM_BIT = 4096;
	public const uint32 GL_ENABLE_BIT = 8192;
	public const uint32 GL_COLOR_BUFFER_BIT = 16384;
	public const uint32 GL_HINT_BIT = 32768;
	public const uint32 GL_EVAL_BIT = 65536;
	public const uint32 GL_LIST_BIT = 131072;
	public const uint32 GL_TEXTURE_BIT = 262144;
	public const uint32 GL_SCISSOR_BIT = 524288;
	public const uint32 GL_ALL_ATTRIB_BITS = 1048575;
	public const uint32 GL_POINTS = 0;
	public const uint32 GL_LINES = 1;
	public const uint32 GL_LINE_LOOP = 2;
	public const uint32 GL_LINE_STRIP = 3;
	public const uint32 GL_TRIANGLES = 4;
	public const uint32 GL_TRIANGLE_STRIP = 5;
	public const uint32 GL_TRIANGLE_FAN = 6;
	public const uint32 GL_QUADS = 7;
	public const uint32 GL_QUAD_STRIP = 8;
	public const uint32 GL_POLYGON = 9;
	public const uint32 GL_ZERO = 0;
	public const uint32 GL_ONE = 1;
	public const uint32 GL_SRC_COLOR = 768;
	public const uint32 GL_ONE_MINUS_SRC_COLOR = 769;
	public const uint32 GL_SRC_ALPHA = 770;
	public const uint32 GL_ONE_MINUS_SRC_ALPHA = 771;
	public const uint32 GL_DST_ALPHA = 772;
	public const uint32 GL_ONE_MINUS_DST_ALPHA = 773;
	public const uint32 GL_DST_COLOR = 774;
	public const uint32 GL_ONE_MINUS_DST_COLOR = 775;
	public const uint32 GL_SRC_ALPHA_SATURATE = 776;
	public const uint32 GL_TRUE = 1;
	public const uint32 GL_FALSE = 0;
	public const uint32 GL_CLIP_PLANE0 = 12288;
	public const uint32 GL_CLIP_PLANE1 = 12289;
	public const uint32 GL_CLIP_PLANE2 = 12290;
	public const uint32 GL_CLIP_PLANE3 = 12291;
	public const uint32 GL_CLIP_PLANE4 = 12292;
	public const uint32 GL_CLIP_PLANE5 = 12293;
	public const uint32 GL_BYTE = 5120;
	public const uint32 GL_UNSIGNED_BYTE = 5121;
	public const uint32 GL_SHORT = 5122;
	public const uint32 GL_UNSIGNED_SHORT = 5123;
	public const uint32 GL_INT = 5124;
	public const uint32 GL_UNSIGNED_INT = 5125;
	public const uint32 GL_FLOAT = 5126;
	public const uint32 GL_2_BYTES = 5127;
	public const uint32 GL_3_BYTES = 5128;
	public const uint32 GL_4_BYTES = 5129;
	public const uint32 GL_DOUBLE = 5130;
	public const uint32 GL_NONE = 0;
	public const uint32 GL_FRONT_LEFT = 1024;
	public const uint32 GL_FRONT_RIGHT = 1025;
	public const uint32 GL_BACK_LEFT = 1026;
	public const uint32 GL_BACK_RIGHT = 1027;
	public const uint32 GL_FRONT = 1028;
	public const uint32 GL_BACK = 1029;
	public const uint32 GL_LEFT = 1030;
	public const uint32 GL_RIGHT = 1031;
	public const uint32 GL_FRONT_AND_BACK = 1032;
	public const uint32 GL_AUX0 = 1033;
	public const uint32 GL_AUX1 = 1034;
	public const uint32 GL_AUX2 = 1035;
	public const uint32 GL_AUX3 = 1036;
	public const uint32 GL_NO_ERROR = 0;
	public const uint32 GL_INVALID_ENUM = 1280;
	public const uint32 GL_INVALID_VALUE = 1281;
	public const uint32 GL_INVALID_OPERATION = 1282;
	public const uint32 GL_STACK_OVERFLOW = 1283;
	public const uint32 GL_STACK_UNDERFLOW = 1284;
	public const uint32 GL_OUT_OF_MEMORY = 1285;
	public const uint32 GL_2D = 1536;
	public const uint32 GL_3D = 1537;
	public const uint32 GL_3D_COLOR = 1538;
	public const uint32 GL_3D_COLOR_TEXTURE = 1539;
	public const uint32 GL_4D_COLOR_TEXTURE = 1540;
	public const uint32 GL_PASS_THROUGH_TOKEN = 1792;
	public const uint32 GL_POINT_TOKEN = 1793;
	public const uint32 GL_LINE_TOKEN = 1794;
	public const uint32 GL_POLYGON_TOKEN = 1795;
	public const uint32 GL_BITMAP_TOKEN = 1796;
	public const uint32 GL_DRAW_PIXEL_TOKEN = 1797;
	public const uint32 GL_COPY_PIXEL_TOKEN = 1798;
	public const uint32 GL_LINE_RESET_TOKEN = 1799;
	public const uint32 GL_EXP = 2048;
	public const uint32 GL_EXP2 = 2049;
	public const uint32 GL_CW = 2304;
	public const uint32 GL_CCW = 2305;
	public const uint32 GL_COEFF = 2560;
	public const uint32 GL_ORDER = 2561;
	public const uint32 GL_DOMAIN = 2562;
	public const uint32 GL_CURRENT_COLOR = 2816;
	public const uint32 GL_CURRENT_INDEX = 2817;
	public const uint32 GL_CURRENT_NORMAL = 2818;
	public const uint32 GL_CURRENT_TEXTURE_COORDS = 2819;
	public const uint32 GL_CURRENT_RASTER_COLOR = 2820;
	public const uint32 GL_CURRENT_RASTER_INDEX = 2821;
	public const uint32 GL_CURRENT_RASTER_TEXTURE_COORDS = 2822;
	public const uint32 GL_CURRENT_RASTER_POSITION = 2823;
	public const uint32 GL_CURRENT_RASTER_POSITION_VALID = 2824;
	public const uint32 GL_CURRENT_RASTER_DISTANCE = 2825;
	public const uint32 GL_POINT_SMOOTH = 2832;
	public const uint32 GL_POINT_SIZE = 2833;
	public const uint32 GL_POINT_SIZE_RANGE = 2834;
	public const uint32 GL_POINT_SIZE_GRANULARITY = 2835;
	public const uint32 GL_LINE_SMOOTH = 2848;
	public const uint32 GL_LINE_WIDTH = 2849;
	public const uint32 GL_LINE_WIDTH_RANGE = 2850;
	public const uint32 GL_LINE_WIDTH_GRANULARITY = 2851;
	public const uint32 GL_LINE_STIPPLE = 2852;
	public const uint32 GL_LINE_STIPPLE_PATTERN = 2853;
	public const uint32 GL_LINE_STIPPLE_REPEAT = 2854;
	public const uint32 GL_LIST_MODE = 2864;
	public const uint32 GL_MAX_LIST_NESTING = 2865;
	public const uint32 GL_LIST_BASE = 2866;
	public const uint32 GL_LIST_INDEX = 2867;
	public const uint32 GL_POLYGON_MODE = 2880;
	public const uint32 GL_POLYGON_SMOOTH = 2881;
	public const uint32 GL_POLYGON_STIPPLE = 2882;
	public const uint32 GL_EDGE_FLAG = 2883;
	public const uint32 GL_CULL_FACE = 2884;
	public const uint32 GL_CULL_FACE_MODE = 2885;
	public const uint32 GL_FRONT_FACE = 2886;
	public const uint32 GL_LIGHTING = 2896;
	public const uint32 GL_LIGHT_MODEL_LOCAL_VIEWER = 2897;
	public const uint32 GL_LIGHT_MODEL_TWO_SIDE = 2898;
	public const uint32 GL_LIGHT_MODEL_AMBIENT = 2899;
	public const uint32 GL_SHADE_MODEL = 2900;
	public const uint32 GL_COLOR_MATERIAL_FACE = 2901;
	public const uint32 GL_COLOR_MATERIAL_PARAMETER = 2902;
	public const uint32 GL_COLOR_MATERIAL = 2903;
	public const uint32 GL_FOG = 2912;
	public const uint32 GL_FOG_INDEX = 2913;
	public const uint32 GL_FOG_DENSITY = 2914;
	public const uint32 GL_FOG_START = 2915;
	public const uint32 GL_FOG_END = 2916;
	public const uint32 GL_FOG_MODE = 2917;
	public const uint32 GL_FOG_COLOR = 2918;
	public const uint32 GL_DEPTH_RANGE = 2928;
	public const uint32 GL_DEPTH_TEST = 2929;
	public const uint32 GL_DEPTH_WRITEMASK = 2930;
	public const uint32 GL_DEPTH_CLEAR_VALUE = 2931;
	public const uint32 GL_DEPTH_FUNC = 2932;
	public const uint32 GL_ACCUM_CLEAR_VALUE = 2944;
	public const uint32 GL_STENCIL_TEST = 2960;
	public const uint32 GL_STENCIL_CLEAR_VALUE = 2961;
	public const uint32 GL_STENCIL_FUNC = 2962;
	public const uint32 GL_STENCIL_VALUE_MASK = 2963;
	public const uint32 GL_STENCIL_FAIL = 2964;
	public const uint32 GL_STENCIL_PASS_DEPTH_FAIL = 2965;
	public const uint32 GL_STENCIL_PASS_DEPTH_PASS = 2966;
	public const uint32 GL_STENCIL_REF = 2967;
	public const uint32 GL_STENCIL_WRITEMASK = 2968;
	public const uint32 GL_MATRIX_MODE = 2976;
	public const uint32 GL_NORMALIZE = 2977;
	public const uint32 GL_VIEWPORT = 2978;
	public const uint32 GL_MODELVIEW_STACK_DEPTH = 2979;
	public const uint32 GL_PROJECTION_STACK_DEPTH = 2980;
	public const uint32 GL_TEXTURE_STACK_DEPTH = 2981;
	public const uint32 GL_MODELVIEW_MATRIX = 2982;
	public const uint32 GL_PROJECTION_MATRIX = 2983;
	public const uint32 GL_TEXTURE_MATRIX = 2984;
	public const uint32 GL_ATTRIB_STACK_DEPTH = 2992;
	public const uint32 GL_CLIENT_ATTRIB_STACK_DEPTH = 2993;
	public const uint32 GL_ALPHA_TEST = 3008;
	public const uint32 GL_ALPHA_TEST_FUNC = 3009;
	public const uint32 GL_ALPHA_TEST_REF = 3010;
	public const uint32 GL_DITHER = 3024;
	public const uint32 GL_BLEND_DST = 3040;
	public const uint32 GL_BLEND_SRC = 3041;
	public const uint32 GL_BLEND = 3042;
	public const uint32 GL_LOGIC_OP_MODE = 3056;
	public const uint32 GL_INDEX_LOGIC_OP = 3057;
	public const uint32 GL_COLOR_LOGIC_OP = 3058;
	public const uint32 GL_AUX_BUFFERS = 3072;
	public const uint32 GL_DRAW_BUFFER = 3073;
	public const uint32 GL_READ_BUFFER = 3074;
	public const uint32 GL_SCISSOR_BOX = 3088;
	public const uint32 GL_SCISSOR_TEST = 3089;
	public const uint32 GL_INDEX_CLEAR_VALUE = 3104;
	public const uint32 GL_INDEX_WRITEMASK = 3105;
	public const uint32 GL_COLOR_CLEAR_VALUE = 3106;
	public const uint32 GL_COLOR_WRITEMASK = 3107;
	public const uint32 GL_INDEX_MODE = 3120;
	public const uint32 GL_RGBA_MODE = 3121;
	public const uint32 GL_DOUBLEBUFFER = 3122;
	public const uint32 GL_STEREO = 3123;
	public const uint32 GL_RENDER_MODE = 3136;
	public const uint32 GL_PERSPECTIVE_CORRECTION_HINT = 3152;
	public const uint32 GL_POINT_SMOOTH_HINT = 3153;
	public const uint32 GL_LINE_SMOOTH_HINT = 3154;
	public const uint32 GL_POLYGON_SMOOTH_HINT = 3155;
	public const uint32 GL_FOG_HINT = 3156;
	public const uint32 GL_TEXTURE_GEN_S = 3168;
	public const uint32 GL_TEXTURE_GEN_T = 3169;
	public const uint32 GL_TEXTURE_GEN_R = 3170;
	public const uint32 GL_TEXTURE_GEN_Q = 3171;
	public const uint32 GL_PIXEL_MAP_I_TO_I = 3184;
	public const uint32 GL_PIXEL_MAP_S_TO_S = 3185;
	public const uint32 GL_PIXEL_MAP_I_TO_R = 3186;
	public const uint32 GL_PIXEL_MAP_I_TO_G = 3187;
	public const uint32 GL_PIXEL_MAP_I_TO_B = 3188;
	public const uint32 GL_PIXEL_MAP_I_TO_A = 3189;
	public const uint32 GL_PIXEL_MAP_R_TO_R = 3190;
	public const uint32 GL_PIXEL_MAP_G_TO_G = 3191;
	public const uint32 GL_PIXEL_MAP_B_TO_B = 3192;
	public const uint32 GL_PIXEL_MAP_A_TO_A = 3193;
	public const uint32 GL_PIXEL_MAP_I_TO_I_SIZE = 3248;
	public const uint32 GL_PIXEL_MAP_S_TO_S_SIZE = 3249;
	public const uint32 GL_PIXEL_MAP_I_TO_R_SIZE = 3250;
	public const uint32 GL_PIXEL_MAP_I_TO_G_SIZE = 3251;
	public const uint32 GL_PIXEL_MAP_I_TO_B_SIZE = 3252;
	public const uint32 GL_PIXEL_MAP_I_TO_A_SIZE = 3253;
	public const uint32 GL_PIXEL_MAP_R_TO_R_SIZE = 3254;
	public const uint32 GL_PIXEL_MAP_G_TO_G_SIZE = 3255;
	public const uint32 GL_PIXEL_MAP_B_TO_B_SIZE = 3256;
	public const uint32 GL_PIXEL_MAP_A_TO_A_SIZE = 3257;
	public const uint32 GL_UNPACK_SWAP_BYTES = 3312;
	public const uint32 GL_UNPACK_LSB_FIRST = 3313;
	public const uint32 GL_UNPACK_ROW_LENGTH = 3314;
	public const uint32 GL_UNPACK_SKIP_ROWS = 3315;
	public const uint32 GL_UNPACK_SKIP_PIXELS = 3316;
	public const uint32 GL_UNPACK_ALIGNMENT = 3317;
	public const uint32 GL_PACK_SWAP_BYTES = 3328;
	public const uint32 GL_PACK_LSB_FIRST = 3329;
	public const uint32 GL_PACK_ROW_LENGTH = 3330;
	public const uint32 GL_PACK_SKIP_ROWS = 3331;
	public const uint32 GL_PACK_SKIP_PIXELS = 3332;
	public const uint32 GL_PACK_ALIGNMENT = 3333;
	public const uint32 GL_MAP_COLOR = 3344;
	public const uint32 GL_MAP_STENCIL = 3345;
	public const uint32 GL_INDEX_SHIFT = 3346;
	public const uint32 GL_INDEX_OFFSET = 3347;
	public const uint32 GL_RED_SCALE = 3348;
	public const uint32 GL_RED_BIAS = 3349;
	public const uint32 GL_ZOOM_X = 3350;
	public const uint32 GL_ZOOM_Y = 3351;
	public const uint32 GL_GREEN_SCALE = 3352;
	public const uint32 GL_GREEN_BIAS = 3353;
	public const uint32 GL_BLUE_SCALE = 3354;
	public const uint32 GL_BLUE_BIAS = 3355;
	public const uint32 GL_ALPHA_SCALE = 3356;
	public const uint32 GL_ALPHA_BIAS = 3357;
	public const uint32 GL_DEPTH_SCALE = 3358;
	public const uint32 GL_DEPTH_BIAS = 3359;
	public const uint32 GL_MAX_EVAL_ORDER = 3376;
	public const uint32 GL_MAX_LIGHTS = 3377;
	public const uint32 GL_MAX_CLIP_PLANES = 3378;
	public const uint32 GL_MAX_TEXTURE_SIZE = 3379;
	public const uint32 GL_MAX_PIXEL_MAP_TABLE = 3380;
	public const uint32 GL_MAX_ATTRIB_STACK_DEPTH = 3381;
	public const uint32 GL_MAX_MODELVIEW_STACK_DEPTH = 3382;
	public const uint32 GL_MAX_NAME_STACK_DEPTH = 3383;
	public const uint32 GL_MAX_PROJECTION_STACK_DEPTH = 3384;
	public const uint32 GL_MAX_TEXTURE_STACK_DEPTH = 3385;
	public const uint32 GL_MAX_VIEWPORT_DIMS = 3386;
	public const uint32 GL_MAX_CLIENT_ATTRIB_STACK_DEPTH = 3387;
	public const uint32 GL_SUBPIXEL_BITS = 3408;
	public const uint32 GL_INDEX_BITS = 3409;
	public const uint32 GL_RED_BITS = 3410;
	public const uint32 GL_GREEN_BITS = 3411;
	public const uint32 GL_BLUE_BITS = 3412;
	public const uint32 GL_ALPHA_BITS = 3413;
	public const uint32 GL_DEPTH_BITS = 3414;
	public const uint32 GL_STENCIL_BITS = 3415;
	public const uint32 GL_ACCUM_RED_BITS = 3416;
	public const uint32 GL_ACCUM_GREEN_BITS = 3417;
	public const uint32 GL_ACCUM_BLUE_BITS = 3418;
	public const uint32 GL_ACCUM_ALPHA_BITS = 3419;
	public const uint32 GL_NAME_STACK_DEPTH = 3440;
	public const uint32 GL_AUTO_NORMAL = 3456;
	public const uint32 GL_MAP1_COLOR_4 = 3472;
	public const uint32 GL_MAP1_INDEX = 3473;
	public const uint32 GL_MAP1_NORMAL = 3474;
	public const uint32 GL_MAP1_TEXTURE_COORD_1 = 3475;
	public const uint32 GL_MAP1_TEXTURE_COORD_2 = 3476;
	public const uint32 GL_MAP1_TEXTURE_COORD_3 = 3477;
	public const uint32 GL_MAP1_TEXTURE_COORD_4 = 3478;
	public const uint32 GL_MAP1_VERTEX_3 = 3479;
	public const uint32 GL_MAP1_VERTEX_4 = 3480;
	public const uint32 GL_MAP2_COLOR_4 = 3504;
	public const uint32 GL_MAP2_INDEX = 3505;
	public const uint32 GL_MAP2_NORMAL = 3506;
	public const uint32 GL_MAP2_TEXTURE_COORD_1 = 3507;
	public const uint32 GL_MAP2_TEXTURE_COORD_2 = 3508;
	public const uint32 GL_MAP2_TEXTURE_COORD_3 = 3509;
	public const uint32 GL_MAP2_TEXTURE_COORD_4 = 3510;
	public const uint32 GL_MAP2_VERTEX_3 = 3511;
	public const uint32 GL_MAP2_VERTEX_4 = 3512;
	public const uint32 GL_MAP1_GRID_DOMAIN = 3536;
	public const uint32 GL_MAP1_GRID_SEGMENTS = 3537;
	public const uint32 GL_MAP2_GRID_DOMAIN = 3538;
	public const uint32 GL_MAP2_GRID_SEGMENTS = 3539;
	public const uint32 GL_TEXTURE_1D = 3552;
	public const uint32 GL_TEXTURE_2D = 3553;
	public const uint32 GL_FEEDBACK_BUFFER_POINTER = 3568;
	public const uint32 GL_FEEDBACK_BUFFER_SIZE = 3569;
	public const uint32 GL_FEEDBACK_BUFFER_TYPE = 3570;
	public const uint32 GL_SELECTION_BUFFER_POINTER = 3571;
	public const uint32 GL_SELECTION_BUFFER_SIZE = 3572;
	public const uint32 GL_TEXTURE_WIDTH = 4096;
	public const uint32 GL_TEXTURE_HEIGHT = 4097;
	public const uint32 GL_TEXTURE_INTERNAL_FORMAT = 4099;
	public const uint32 GL_TEXTURE_BORDER_COLOR = 4100;
	public const uint32 GL_TEXTURE_BORDER = 4101;
	public const uint32 GL_DONT_CARE = 4352;
	public const uint32 GL_FASTEST = 4353;
	public const uint32 GL_NICEST = 4354;
	public const uint32 GL_LIGHT0 = 16384;
	public const uint32 GL_LIGHT1 = 16385;
	public const uint32 GL_LIGHT2 = 16386;
	public const uint32 GL_LIGHT3 = 16387;
	public const uint32 GL_LIGHT4 = 16388;
	public const uint32 GL_LIGHT5 = 16389;
	public const uint32 GL_LIGHT6 = 16390;
	public const uint32 GL_LIGHT7 = 16391;
	public const uint32 GL_AMBIENT = 4608;
	public const uint32 GL_DIFFUSE = 4609;
	public const uint32 GL_SPECULAR = 4610;
	public const uint32 GL_POSITION = 4611;
	public const uint32 GL_SPOT_DIRECTION = 4612;
	public const uint32 GL_SPOT_EXPONENT = 4613;
	public const uint32 GL_SPOT_CUTOFF = 4614;
	public const uint32 GL_CONSTANT_ATTENUATION = 4615;
	public const uint32 GL_LINEAR_ATTENUATION = 4616;
	public const uint32 GL_QUADRATIC_ATTENUATION = 4617;
	public const uint32 GL_COMPILE = 4864;
	public const uint32 GL_COMPILE_AND_EXECUTE = 4865;
	public const uint32 GL_CLEAR = 5376;
	public const uint32 GL_AND = 5377;
	public const uint32 GL_AND_REVERSE = 5378;
	public const uint32 GL_COPY = 5379;
	public const uint32 GL_AND_INVERTED = 5380;
	public const uint32 GL_NOOP = 5381;
	public const uint32 GL_XOR = 5382;
	public const uint32 GL_OR = 5383;
	public const uint32 GL_NOR = 5384;
	public const uint32 GL_EQUIV = 5385;
	public const uint32 GL_INVERT = 5386;
	public const uint32 GL_OR_REVERSE = 5387;
	public const uint32 GL_COPY_INVERTED = 5388;
	public const uint32 GL_OR_INVERTED = 5389;
	public const uint32 GL_NAND = 5390;
	public const uint32 GL_SET = 5391;
	public const uint32 GL_EMISSION = 5632;
	public const uint32 GL_SHININESS = 5633;
	public const uint32 GL_AMBIENT_AND_DIFFUSE = 5634;
	public const uint32 GL_COLOR_INDEXES = 5635;
	public const uint32 GL_MODELVIEW = 5888;
	public const uint32 GL_PROJECTION = 5889;
	public const uint32 GL_TEXTURE = 5890;
	public const uint32 GL_COLOR = 6144;
	public const uint32 GL_DEPTH = 6145;
	public const uint32 GL_STENCIL = 6146;
	public const uint32 GL_COLOR_INDEX = 6400;
	public const uint32 GL_STENCIL_INDEX = 6401;
	public const uint32 GL_DEPTH_COMPONENT = 6402;
	public const uint32 GL_RED = 6403;
	public const uint32 GL_GREEN = 6404;
	public const uint32 GL_BLUE = 6405;
	public const uint32 GL_ALPHA = 6406;
	public const uint32 GL_RGB = 6407;
	public const uint32 GL_RGBA = 6408;
	public const uint32 GL_LUMINANCE = 6409;
	public const uint32 GL_LUMINANCE_ALPHA = 6410;
	public const uint32 GL_BITMAP = 6656;
	public const uint32 GL_POINT = 6912;
	public const uint32 GL_LINE = 6913;
	public const uint32 GL_FILL = 6914;
	public const uint32 GL_RENDER = 7168;
	public const uint32 GL_FEEDBACK = 7169;
	public const uint32 GL_SELECT = 7170;
	public const uint32 GL_FLAT = 7424;
	public const uint32 GL_SMOOTH = 7425;
	public const uint32 GL_KEEP = 7680;
	public const uint32 GL_REPLACE = 7681;
	public const uint32 GL_INCR = 7682;
	public const uint32 GL_DECR = 7683;
	public const uint32 GL_VENDOR = 7936;
	public const uint32 GL_RENDERER = 7937;
	public const uint32 GL_VERSION = 7938;
	public const uint32 GL_EXTENSIONS = 7939;
	public const uint32 GL_S = 8192;
	public const uint32 GL_T = 8193;
	public const uint32 GL_R = 8194;
	public const uint32 GL_Q = 8195;
	public const uint32 GL_MODULATE = 8448;
	public const uint32 GL_DECAL = 8449;
	public const uint32 GL_TEXTURE_ENV_MODE = 8704;
	public const uint32 GL_TEXTURE_ENV_COLOR = 8705;
	public const uint32 GL_TEXTURE_ENV = 8960;
	public const uint32 GL_EYE_LINEAR = 9216;
	public const uint32 GL_OBJECT_LINEAR = 9217;
	public const uint32 GL_SPHERE_MAP = 9218;
	public const uint32 GL_TEXTURE_GEN_MODE = 9472;
	public const uint32 GL_OBJECT_PLANE = 9473;
	public const uint32 GL_EYE_PLANE = 9474;
	public const uint32 GL_NEAREST = 9728;
	public const uint32 GL_LINEAR = 9729;
	public const uint32 GL_NEAREST_MIPMAP_NEAREST = 9984;
	public const uint32 GL_LINEAR_MIPMAP_NEAREST = 9985;
	public const uint32 GL_NEAREST_MIPMAP_LINEAR = 9986;
	public const uint32 GL_LINEAR_MIPMAP_LINEAR = 9987;
	public const uint32 GL_TEXTURE_MAG_FILTER = 10240;
	public const uint32 GL_TEXTURE_MIN_FILTER = 10241;
	public const uint32 GL_TEXTURE_WRAP_S = 10242;
	public const uint32 GL_TEXTURE_WRAP_T = 10243;
	public const uint32 GL_CLAMP = 10496;
	public const uint32 GL_REPEAT = 10497;
	public const uint32 GL_CLIENT_PIXEL_STORE_BIT = 1;
	public const uint32 GL_CLIENT_VERTEX_ARRAY_BIT = 2;
	public const uint32 GL_CLIENT_ALL_ATTRIB_BITS = 4294967295;
	public const uint32 GL_POLYGON_OFFSET_FACTOR = 32824;
	public const uint32 GL_POLYGON_OFFSET_UNITS = 10752;
	public const uint32 GL_POLYGON_OFFSET_POINT = 10753;
	public const uint32 GL_POLYGON_OFFSET_LINE = 10754;
	public const uint32 GL_POLYGON_OFFSET_FILL = 32823;
	public const uint32 GL_ALPHA4 = 32827;
	public const uint32 GL_ALPHA8 = 32828;
	public const uint32 GL_ALPHA12 = 32829;
	public const uint32 GL_ALPHA16 = 32830;
	public const uint32 GL_LUMINANCE4 = 32831;
	public const uint32 GL_LUMINANCE8 = 32832;
	public const uint32 GL_LUMINANCE12 = 32833;
	public const uint32 GL_LUMINANCE16 = 32834;
	public const uint32 GL_LUMINANCE4_ALPHA4 = 32835;
	public const uint32 GL_LUMINANCE6_ALPHA2 = 32836;
	public const uint32 GL_LUMINANCE8_ALPHA8 = 32837;
	public const uint32 GL_LUMINANCE12_ALPHA4 = 32838;
	public const uint32 GL_LUMINANCE12_ALPHA12 = 32839;
	public const uint32 GL_LUMINANCE16_ALPHA16 = 32840;
	public const uint32 GL_INTENSITY = 32841;
	public const uint32 GL_INTENSITY4 = 32842;
	public const uint32 GL_INTENSITY8 = 32843;
	public const uint32 GL_INTENSITY12 = 32844;
	public const uint32 GL_INTENSITY16 = 32845;
	public const uint32 GL_R3_G3_B2 = 10768;
	public const uint32 GL_RGB4 = 32847;
	public const uint32 GL_RGB5 = 32848;
	public const uint32 GL_RGB8 = 32849;
	public const uint32 GL_RGB10 = 32850;
	public const uint32 GL_RGB12 = 32851;
	public const uint32 GL_RGB16 = 32852;
	public const uint32 GL_RGBA2 = 32853;
	public const uint32 GL_RGBA4 = 32854;
	public const uint32 GL_RGB5_A1 = 32855;
	public const uint32 GL_RGBA8 = 32856;
	public const uint32 GL_RGB10_A2 = 32857;
	public const uint32 GL_RGBA12 = 32858;
	public const uint32 GL_RGBA16 = 32859;
	public const uint32 GL_TEXTURE_RED_SIZE = 32860;
	public const uint32 GL_TEXTURE_GREEN_SIZE = 32861;
	public const uint32 GL_TEXTURE_BLUE_SIZE = 32862;
	public const uint32 GL_TEXTURE_ALPHA_SIZE = 32863;
	public const uint32 GL_TEXTURE_LUMINANCE_SIZE = 32864;
	public const uint32 GL_TEXTURE_INTENSITY_SIZE = 32865;
	public const uint32 GL_PROXY_TEXTURE_1D = 32867;
	public const uint32 GL_PROXY_TEXTURE_2D = 32868;
	public const uint32 GL_TEXTURE_PRIORITY = 32870;
	public const uint32 GL_TEXTURE_RESIDENT = 32871;
	public const uint32 GL_TEXTURE_BINDING_1D = 32872;
	public const uint32 GL_TEXTURE_BINDING_2D = 32873;
	public const uint32 GL_VERTEX_ARRAY = 32884;
	public const uint32 GL_NORMAL_ARRAY = 32885;
	public const uint32 GL_COLOR_ARRAY = 32886;
	public const uint32 GL_INDEX_ARRAY = 32887;
	public const uint32 GL_TEXTURE_COORD_ARRAY = 32888;
	public const uint32 GL_EDGE_FLAG_ARRAY = 32889;
	public const uint32 GL_VERTEX_ARRAY_SIZE = 32890;
	public const uint32 GL_VERTEX_ARRAY_TYPE = 32891;
	public const uint32 GL_VERTEX_ARRAY_STRIDE = 32892;
	public const uint32 GL_NORMAL_ARRAY_TYPE = 32894;
	public const uint32 GL_NORMAL_ARRAY_STRIDE = 32895;
	public const uint32 GL_COLOR_ARRAY_SIZE = 32897;
	public const uint32 GL_COLOR_ARRAY_TYPE = 32898;
	public const uint32 GL_COLOR_ARRAY_STRIDE = 32899;
	public const uint32 GL_INDEX_ARRAY_TYPE = 32901;
	public const uint32 GL_INDEX_ARRAY_STRIDE = 32902;
	public const uint32 GL_TEXTURE_COORD_ARRAY_SIZE = 32904;
	public const uint32 GL_TEXTURE_COORD_ARRAY_TYPE = 32905;
	public const uint32 GL_TEXTURE_COORD_ARRAY_STRIDE = 32906;
	public const uint32 GL_EDGE_FLAG_ARRAY_STRIDE = 32908;
	public const uint32 GL_VERTEX_ARRAY_POINTER = 32910;
	public const uint32 GL_NORMAL_ARRAY_POINTER = 32911;
	public const uint32 GL_COLOR_ARRAY_POINTER = 32912;
	public const uint32 GL_INDEX_ARRAY_POINTER = 32913;
	public const uint32 GL_TEXTURE_COORD_ARRAY_POINTER = 32914;
	public const uint32 GL_EDGE_FLAG_ARRAY_POINTER = 32915;
	public const uint32 GL_V2F = 10784;
	public const uint32 GL_V3F = 10785;
	public const uint32 GL_C4UB_V2F = 10786;
	public const uint32 GL_C4UB_V3F = 10787;
	public const uint32 GL_C3F_V3F = 10788;
	public const uint32 GL_N3F_V3F = 10789;
	public const uint32 GL_C4F_N3F_V3F = 10790;
	public const uint32 GL_T2F_V3F = 10791;
	public const uint32 GL_T4F_V4F = 10792;
	public const uint32 GL_T2F_C4UB_V3F = 10793;
	public const uint32 GL_T2F_C3F_V3F = 10794;
	public const uint32 GL_T2F_N3F_V3F = 10795;
	public const uint32 GL_T2F_C4F_N3F_V3F = 10796;
	public const uint32 GL_T4F_C4F_N3F_V4F = 10797;
	public const uint32 GL_EXT_vertex_array = 1;
	public const uint32 GL_EXT_bgra = 1;
	public const uint32 GL_EXT_paletted_texture = 1;
	public const uint32 GL_WIN_swap_hint = 1;
	public const uint32 GL_WIN_draw_range_elements = 1;
	public const uint32 GL_VERTEX_ARRAY_EXT = 32884;
	public const uint32 GL_NORMAL_ARRAY_EXT = 32885;
	public const uint32 GL_COLOR_ARRAY_EXT = 32886;
	public const uint32 GL_INDEX_ARRAY_EXT = 32887;
	public const uint32 GL_TEXTURE_COORD_ARRAY_EXT = 32888;
	public const uint32 GL_EDGE_FLAG_ARRAY_EXT = 32889;
	public const uint32 GL_VERTEX_ARRAY_SIZE_EXT = 32890;
	public const uint32 GL_VERTEX_ARRAY_TYPE_EXT = 32891;
	public const uint32 GL_VERTEX_ARRAY_STRIDE_EXT = 32892;
	public const uint32 GL_VERTEX_ARRAY_COUNT_EXT = 32893;
	public const uint32 GL_NORMAL_ARRAY_TYPE_EXT = 32894;
	public const uint32 GL_NORMAL_ARRAY_STRIDE_EXT = 32895;
	public const uint32 GL_NORMAL_ARRAY_COUNT_EXT = 32896;
	public const uint32 GL_COLOR_ARRAY_SIZE_EXT = 32897;
	public const uint32 GL_COLOR_ARRAY_TYPE_EXT = 32898;
	public const uint32 GL_COLOR_ARRAY_STRIDE_EXT = 32899;
	public const uint32 GL_COLOR_ARRAY_COUNT_EXT = 32900;
	public const uint32 GL_INDEX_ARRAY_TYPE_EXT = 32901;
	public const uint32 GL_INDEX_ARRAY_STRIDE_EXT = 32902;
	public const uint32 GL_INDEX_ARRAY_COUNT_EXT = 32903;
	public const uint32 GL_TEXTURE_COORD_ARRAY_SIZE_EXT = 32904;
	public const uint32 GL_TEXTURE_COORD_ARRAY_TYPE_EXT = 32905;
	public const uint32 GL_TEXTURE_COORD_ARRAY_STRIDE_EXT = 32906;
	public const uint32 GL_TEXTURE_COORD_ARRAY_COUNT_EXT = 32907;
	public const uint32 GL_EDGE_FLAG_ARRAY_STRIDE_EXT = 32908;
	public const uint32 GL_EDGE_FLAG_ARRAY_COUNT_EXT = 32909;
	public const uint32 GL_VERTEX_ARRAY_POINTER_EXT = 32910;
	public const uint32 GL_NORMAL_ARRAY_POINTER_EXT = 32911;
	public const uint32 GL_COLOR_ARRAY_POINTER_EXT = 32912;
	public const uint32 GL_INDEX_ARRAY_POINTER_EXT = 32913;
	public const uint32 GL_TEXTURE_COORD_ARRAY_POINTER_EXT = 32914;
	public const uint32 GL_EDGE_FLAG_ARRAY_POINTER_EXT = 32915;
	public const uint32 GL_DOUBLE_EXT = 5130;
	public const uint32 GL_BGR_EXT = 32992;
	public const uint32 GL_BGRA_EXT = 32993;
	public const uint32 GL_COLOR_TABLE_FORMAT_EXT = 32984;
	public const uint32 GL_COLOR_TABLE_WIDTH_EXT = 32985;
	public const uint32 GL_COLOR_TABLE_RED_SIZE_EXT = 32986;
	public const uint32 GL_COLOR_TABLE_GREEN_SIZE_EXT = 32987;
	public const uint32 GL_COLOR_TABLE_BLUE_SIZE_EXT = 32988;
	public const uint32 GL_COLOR_TABLE_ALPHA_SIZE_EXT = 32989;
	public const uint32 GL_COLOR_TABLE_LUMINANCE_SIZE_EXT = 32990;
	public const uint32 GL_COLOR_TABLE_INTENSITY_SIZE_EXT = 32991;
	public const uint32 GL_COLOR_INDEX1_EXT = 32994;
	public const uint32 GL_COLOR_INDEX2_EXT = 32995;
	public const uint32 GL_COLOR_INDEX4_EXT = 32996;
	public const uint32 GL_COLOR_INDEX8_EXT = 32997;
	public const uint32 GL_COLOR_INDEX12_EXT = 32998;
	public const uint32 GL_COLOR_INDEX16_EXT = 32999;
	public const uint32 GL_MAX_ELEMENTS_VERTICES_WIN = 33000;
	public const uint32 GL_MAX_ELEMENTS_INDICES_WIN = 33001;
	public const uint32 GL_PHONG_WIN = 33002;
	public const uint32 GL_PHONG_HINT_WIN = 33003;
	public const uint32 GL_FOG_SPECULAR_TEXTURE_WIN = 33004;
	public const uint32 GL_LOGIC_OP = 3057;
	public const uint32 GL_TEXTURE_COMPONENTS = 4099;
	public const uint32 GLU_VERSION_1_1 = 1;
	public const uint32 GLU_VERSION_1_2 = 1;
	public const uint32 GLU_INVALID_ENUM = 100900;
	public const uint32 GLU_INVALID_VALUE = 100901;
	public const uint32 GLU_OUT_OF_MEMORY = 100902;
	public const uint32 GLU_INCOMPATIBLE_GL_VERSION = 100903;
	public const uint32 GLU_VERSION = 100800;
	public const uint32 GLU_EXTENSIONS = 100801;
	public const uint32 GLU_TRUE = 1;
	public const uint32 GLU_FALSE = 0;
	public const uint32 GLU_SMOOTH = 100000;
	public const uint32 GLU_FLAT = 100001;
	public const uint32 GLU_NONE = 100002;
	public const uint32 GLU_POINT = 100010;
	public const uint32 GLU_LINE = 100011;
	public const uint32 GLU_FILL = 100012;
	public const uint32 GLU_SILHOUETTE = 100013;
	public const uint32 GLU_OUTSIDE = 100020;
	public const uint32 GLU_INSIDE = 100021;
	public const uint32 GLU_TESS_WINDING_RULE = 100140;
	public const uint32 GLU_TESS_BOUNDARY_ONLY = 100141;
	public const uint32 GLU_TESS_TOLERANCE = 100142;
	public const uint32 GLU_TESS_WINDING_ODD = 100130;
	public const uint32 GLU_TESS_WINDING_NONZERO = 100131;
	public const uint32 GLU_TESS_WINDING_POSITIVE = 100132;
	public const uint32 GLU_TESS_WINDING_NEGATIVE = 100133;
	public const uint32 GLU_TESS_WINDING_ABS_GEQ_TWO = 100134;
	public const uint32 GLU_TESS_BEGIN = 100100;
	public const uint32 GLU_TESS_VERTEX = 100101;
	public const uint32 GLU_TESS_END = 100102;
	public const uint32 GLU_TESS_ERROR = 100103;
	public const uint32 GLU_TESS_EDGE_FLAG = 100104;
	public const uint32 GLU_TESS_COMBINE = 100105;
	public const uint32 GLU_TESS_BEGIN_DATA = 100106;
	public const uint32 GLU_TESS_VERTEX_DATA = 100107;
	public const uint32 GLU_TESS_END_DATA = 100108;
	public const uint32 GLU_TESS_ERROR_DATA = 100109;
	public const uint32 GLU_TESS_EDGE_FLAG_DATA = 100110;
	public const uint32 GLU_TESS_COMBINE_DATA = 100111;
	public const uint32 GLU_TESS_ERROR1 = 100151;
	public const uint32 GLU_TESS_ERROR2 = 100152;
	public const uint32 GLU_TESS_ERROR3 = 100153;
	public const uint32 GLU_TESS_ERROR4 = 100154;
	public const uint32 GLU_TESS_ERROR5 = 100155;
	public const uint32 GLU_TESS_ERROR6 = 100156;
	public const uint32 GLU_TESS_ERROR7 = 100157;
	public const uint32 GLU_TESS_ERROR8 = 100158;
	public const uint32 GLU_TESS_MISSING_BEGIN_POLYGON = 100151;
	public const uint32 GLU_TESS_MISSING_BEGIN_CONTOUR = 100152;
	public const uint32 GLU_TESS_MISSING_END_POLYGON = 100153;
	public const uint32 GLU_TESS_MISSING_END_CONTOUR = 100154;
	public const uint32 GLU_TESS_COORD_TOO_LARGE = 100155;
	public const uint32 GLU_TESS_NEED_COMBINE_CALLBACK = 100156;
	public const uint32 GLU_AUTO_LOAD_MATRIX = 100200;
	public const uint32 GLU_CULLING = 100201;
	public const uint32 GLU_SAMPLING_TOLERANCE = 100203;
	public const uint32 GLU_DISPLAY_MODE = 100204;
	public const uint32 GLU_PARAMETRIC_TOLERANCE = 100202;
	public const uint32 GLU_SAMPLING_METHOD = 100205;
	public const uint32 GLU_U_STEP = 100206;
	public const uint32 GLU_V_STEP = 100207;
	public const uint32 GLU_PATH_LENGTH = 100215;
	public const uint32 GLU_PARAMETRIC_ERROR = 100216;
	public const uint32 GLU_DOMAIN_DISTANCE = 100217;
	public const uint32 GLU_MAP1_TRIM_2 = 100210;
	public const uint32 GLU_MAP1_TRIM_3 = 100211;
	public const uint32 GLU_OUTLINE_POLYGON = 100240;
	public const uint32 GLU_OUTLINE_PATCH = 100241;
	public const uint32 GLU_NURBS_ERROR1 = 100251;
	public const uint32 GLU_NURBS_ERROR2 = 100252;
	public const uint32 GLU_NURBS_ERROR3 = 100253;
	public const uint32 GLU_NURBS_ERROR4 = 100254;
	public const uint32 GLU_NURBS_ERROR5 = 100255;
	public const uint32 GLU_NURBS_ERROR6 = 100256;
	public const uint32 GLU_NURBS_ERROR7 = 100257;
	public const uint32 GLU_NURBS_ERROR8 = 100258;
	public const uint32 GLU_NURBS_ERROR9 = 100259;
	public const uint32 GLU_NURBS_ERROR10 = 100260;
	public const uint32 GLU_NURBS_ERROR11 = 100261;
	public const uint32 GLU_NURBS_ERROR12 = 100262;
	public const uint32 GLU_NURBS_ERROR13 = 100263;
	public const uint32 GLU_NURBS_ERROR14 = 100264;
	public const uint32 GLU_NURBS_ERROR15 = 100265;
	public const uint32 GLU_NURBS_ERROR16 = 100266;
	public const uint32 GLU_NURBS_ERROR17 = 100267;
	public const uint32 GLU_NURBS_ERROR18 = 100268;
	public const uint32 GLU_NURBS_ERROR19 = 100269;
	public const uint32 GLU_NURBS_ERROR20 = 100270;
	public const uint32 GLU_NURBS_ERROR21 = 100271;
	public const uint32 GLU_NURBS_ERROR22 = 100272;
	public const uint32 GLU_NURBS_ERROR23 = 100273;
	public const uint32 GLU_NURBS_ERROR24 = 100274;
	public const uint32 GLU_NURBS_ERROR25 = 100275;
	public const uint32 GLU_NURBS_ERROR26 = 100276;
	public const uint32 GLU_NURBS_ERROR27 = 100277;
	public const uint32 GLU_NURBS_ERROR28 = 100278;
	public const uint32 GLU_NURBS_ERROR29 = 100279;
	public const uint32 GLU_NURBS_ERROR30 = 100280;
	public const uint32 GLU_NURBS_ERROR31 = 100281;
	public const uint32 GLU_NURBS_ERROR32 = 100282;
	public const uint32 GLU_NURBS_ERROR33 = 100283;
	public const uint32 GLU_NURBS_ERROR34 = 100284;
	public const uint32 GLU_NURBS_ERROR35 = 100285;
	public const uint32 GLU_NURBS_ERROR36 = 100286;
	public const uint32 GLU_NURBS_ERROR37 = 100287;
	public const uint32 GLU_CW = 100120;
	public const uint32 GLU_CCW = 100121;
	public const uint32 GLU_INTERIOR = 100122;
	public const uint32 GLU_EXTERIOR = 100123;
	public const uint32 GLU_UNKNOWN = 100124;
	public const uint32 GLU_BEGIN = 100100;
	public const uint32 GLU_VERTEX = 100101;
	public const uint32 GLU_END = 100102;
	public const uint32 GLU_ERROR = 100103;
	public const uint32 GLU_EDGE_FLAG = 100104;
}
#endregion

#region TypeDefs
typealias HGLRC = int;

#endregion


#region Enums

[AllowDuplicates]
public enum PFD_PIXEL_TYPE : int8
{
	PFD_TYPE_RGBA = 0,
	PFD_TYPE_COLORINDEX = 1,
}


[AllowDuplicates]
public enum PFD_LAYER_TYPE : int8
{
	PFD_UNDERLAY_PLANE = -1,
	PFD_MAIN_PLANE = 0,
	PFD_OVERLAY_PLANE = 1,
}


[AllowDuplicates]
public enum PFD_FLAGS : uint32
{
	PFD_DOUBLEBUFFER = 1,
	PFD_STEREO = 2,
	PFD_DRAW_TO_WINDOW = 4,
	PFD_DRAW_TO_BITMAP = 8,
	PFD_SUPPORT_GDI = 16,
	PFD_SUPPORT_OPENGL = 32,
	PFD_GENERIC_FORMAT = 64,
	PFD_NEED_PALETTE = 128,
	PFD_NEED_SYSTEM_PALETTE = 256,
	PFD_SWAP_EXCHANGE = 512,
	PFD_SWAP_COPY = 1024,
	PFD_SWAP_LAYER_BUFFERS = 2048,
	PFD_GENERIC_ACCELERATED = 4096,
	PFD_SUPPORT_DIRECTDRAW = 8192,
	PFD_DIRECT3D_ACCELERATED = 16384,
	PFD_SUPPORT_COMPOSITION = 32768,
	PFD_DEPTH_DONTCARE = 536870912,
	PFD_DOUBLEBUFFER_DONTCARE = 1073741824,
	PFD_STEREO_DONTCARE = 2147483648,
}

#endregion

#region Function Pointers
public function void PFNGLARRAYELEMENTEXTPROC(int32 i);

public function void PFNGLDRAWARRAYSEXTPROC(uint32 mode, int32 first, int32 count);

public function void PFNGLVERTEXPOINTEREXTPROC(int32 size, uint32 type, int32 stride, int32 count, void* pointer);

public function void PFNGLNORMALPOINTEREXTPROC(uint32 type, int32 stride, int32 count, void* pointer);

public function void PFNGLCOLORPOINTEREXTPROC(int32 size, uint32 type, int32 stride, int32 count, void* pointer);

public function void PFNGLINDEXPOINTEREXTPROC(uint32 type, int32 stride, int32 count, void* pointer);

public function void PFNGLTEXCOORDPOINTEREXTPROC(int32 size, uint32 type, int32 stride, int32 count, void* pointer);

public function void PFNGLEDGEFLAGPOINTEREXTPROC(int32 stride, int32 count, uint8* pointer);

public function void PFNGLGETPOINTERVEXTPROC(uint32 pname, void** @params);

public function void PFNGLARRAYELEMENTARRAYEXTPROC(uint32 mode, int32 count, void* pi);

public function void PFNGLDRAWRANGEELEMENTSWINPROC(uint32 mode, uint32 start, uint32 end, int32 count, uint32 type, void* indices);

public function void PFNGLADDSWAPHINTRECTWINPROC(int32 x, int32 y, int32 width, int32 height);

public function void PFNGLCOLORTABLEEXTPROC(uint32 target, uint32 internalFormat, int32 width, uint32 format, uint32 type, void* data);

public function void PFNGLCOLORSUBTABLEEXTPROC(uint32 target, int32 start, int32 count, uint32 format, uint32 type, void* data);

public function void PFNGLGETCOLORTABLEEXTPROC(uint32 target, uint32 format, uint32 type, void* data);

public function void PFNGLGETCOLORTABLEPARAMETERIVEXTPROC(uint32 target, uint32 pname, int32* @params);

public function void PFNGLGETCOLORTABLEPARAMETERFVEXTPROC(uint32 target, uint32 pname, float* @params);

public function void GLUquadricErrorProc(uint32 param0);

public function void GLUtessBeginProc(uint32 param0);

public function void GLUtessEdgeFlagProc(uint8 param0);

public function void GLUtessVertexProc(void* param0);

public function void GLUtessEndProc();

public function void GLUtessErrorProc(uint32 param0);

public function void GLUtessCombineProc(double* param0, void** param1, float* param2, void** param3);

public function void GLUtessBeginDataProc(uint32 param0, void* param1);

public function void GLUtessEdgeFlagDataProc(uint8 param0, void* param1);

public function void GLUtessVertexDataProc(void* param0, void* param1);

public function void GLUtessEndDataProc(void* param0);

public function void GLUtessErrorDataProc(uint32 param0, void* param1);

public function void GLUtessCombineDataProc(double* param0, void** param1, float* param2, void** param3, void* param4);

public function void GLUnurbsErrorProc(uint32 param0);

#endregion

#region Structs
[CRepr]
public struct PIXELFORMATDESCRIPTOR
{
	public uint16 nSize;
	public uint16 nVersion;
	public PFD_FLAGS dwFlags;
	public PFD_PIXEL_TYPE iPixelType;
	public uint8 cColorBits;
	public uint8 cRedBits;
	public uint8 cRedShift;
	public uint8 cGreenBits;
	public uint8 cGreenShift;
	public uint8 cBlueBits;
	public uint8 cBlueShift;
	public uint8 cAlphaBits;
	public uint8 cAlphaShift;
	public uint8 cAccumBits;
	public uint8 cAccumRedBits;
	public uint8 cAccumGreenBits;
	public uint8 cAccumBlueBits;
	public uint8 cAccumAlphaBits;
	public uint8 cDepthBits;
	public uint8 cStencilBits;
	public uint8 cAuxBuffers;
	public PFD_LAYER_TYPE iLayerType;
	public uint8 bReserved;
	public uint32 dwLayerMask;
	public uint32 dwVisibleMask;
	public uint32 dwDamageMask;
}

[CRepr]
public struct EMRPIXELFORMAT
{
	public EMR emr;
	public PIXELFORMATDESCRIPTOR pfd;
}

[CRepr]
public struct POINTFLOAT
{
	public float x;
	public float y;
}

[CRepr]
public struct GLYPHMETRICSFLOAT
{
	public float gmfBlackBoxX;
	public float gmfBlackBoxY;
	public POINTFLOAT gmfptGlyphOrigin;
	public float gmfCellIncX;
	public float gmfCellIncY;
}

[CRepr]
public struct LAYERPLANEDESCRIPTOR
{
	public uint16 nSize;
	public uint16 nVersion;
	public uint32 dwFlags;
	public uint8 iPixelType;
	public uint8 cColorBits;
	public uint8 cRedBits;
	public uint8 cRedShift;
	public uint8 cGreenBits;
	public uint8 cGreenShift;
	public uint8 cBlueBits;
	public uint8 cBlueShift;
	public uint8 cAlphaBits;
	public uint8 cAlphaShift;
	public uint8 cAccumBits;
	public uint8 cAccumRedBits;
	public uint8 cAccumGreenBits;
	public uint8 cAccumBlueBits;
	public uint8 cAccumAlphaBits;
	public uint8 cDepthBits;
	public uint8 cStencilBits;
	public uint8 cAuxBuffers;
	public uint8 iLayerPlane;
	public uint8 bReserved;
	public COLORREF crTransparent;
}

[CRepr]
public struct GLUnurbs
{
}

[CRepr]
public struct GLUquadric
{
}

[CRepr]
public struct GLUtesselator
{
}

#endregion

#region Functions
public static
{
	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ChoosePixelFormat(HDC hdc, PIXELFORMATDESCRIPTOR* ppfd);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DescribePixelFormat(HDC hdc, PFD_PIXEL_TYPE iPixelFormat, uint32 nBytes, PIXELFORMATDESCRIPTOR* ppfd);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetPixelFormat(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetPixelFormat(HDC hdc, int32 format, PIXELFORMATDESCRIPTOR* ppfd);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetEnhMetaFilePixelFormat(HENHMETAFILE hemf, uint32 cbBuffer, PIXELFORMATDESCRIPTOR* ppfd);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL wglCopyContext(HGLRC param0, HGLRC param1, uint32 param2);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HGLRC wglCreateContext(HDC param0);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HGLRC wglCreateLayerContext(HDC param0, int32 param1);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL wglDeleteContext(HGLRC param0);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HGLRC wglGetCurrentContext();

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDC wglGetCurrentDC();

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PROC wglGetProcAddress(PSTR param0);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL wglMakeCurrent(HDC param0, HGLRC param1);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL wglShareLists(HGLRC param0, HGLRC param1);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL wglUseFontBitmapsA(HDC param0, uint32 param1, uint32 param2, uint32 param3);
	public static BOOL wglUseFontBitmaps(HDC param0, uint32 param1, uint32 param2, uint32 param3) => wglUseFontBitmapsA(param0, param1, param2, param3);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL wglUseFontBitmapsW(HDC param0, uint32 param1, uint32 param2, uint32 param3);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SwapBuffers(HDC param0);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL wglUseFontOutlinesA(HDC param0, uint32 param1, uint32 param2, uint32 param3, float param4, float param5, int32 param6, GLYPHMETRICSFLOAT* param7);
	public static BOOL wglUseFontOutlines(HDC param0, uint32 param1, uint32 param2, uint32 param3, float param4, float param5, int32 param6, GLYPHMETRICSFLOAT* param7) => wglUseFontOutlinesA(param0, param1, param2, param3, param4, param5, param6, param7);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL wglUseFontOutlinesW(HDC param0, uint32 param1, uint32 param2, uint32 param3, float param4, float param5, int32 param6, GLYPHMETRICSFLOAT* param7);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL wglDescribeLayerPlane(HDC param0, int32 param1, int32 param2, uint32 param3, LAYERPLANEDESCRIPTOR* param4);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 wglSetLayerPaletteEntries(HDC param0, int32 param1, int32 param2, int32 param3, COLORREF* param4);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 wglGetLayerPaletteEntries(HDC param0, int32 param1, int32 param2, int32 param3, COLORREF* param4);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL wglRealizeLayerPalette(HDC param0, int32 param1, BOOL param2);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL wglSwapLayerBuffers(HDC param0, uint32 param1);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glAccum(uint32 op, float value);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glAlphaFunc(uint32 func, float @ref);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8 glAreTexturesResident(int32 n, uint32* textures, uint8* residences);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glArrayElement(int32 i);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glBegin(uint32 mode);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glBindTexture(uint32 target, uint32 texture);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glBitmap(int32 width, int32 height, float xorig, float yorig, float xmove, float ymove, uint8* bitmap);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glBlendFunc(uint32 sfactor, uint32 dfactor);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glCallList(uint32 list);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glCallLists(int32 n, uint32 type, void* lists);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glClear(uint32 mask);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glClearAccum(float red, float green, float blue, float alpha);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glClearColor(float red, float green, float blue, float alpha);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glClearDepth(double depth);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glClearIndex(float c);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glClearStencil(int32 s);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glClipPlane(uint32 plane, double* equation);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor3b(int8 red, int8 green, int8 blue);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor3bv(int8* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor3d(double red, double green, double blue);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor3dv(double* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor3f(float red, float green, float blue);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor3fv(float* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor3i(int32 red, int32 green, int32 blue);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor3iv(int32* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor3s(int16 red, int16 green, int16 blue);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor3sv(int16* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor3ub(uint8 red, uint8 green, uint8 blue);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor3ubv(uint8* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor3ui(uint32 red, uint32 green, uint32 blue);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor3uiv(uint32* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor3us(uint16 red, uint16 green, uint16 blue);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor3usv(uint16* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor4b(int8 red, int8 green, int8 blue, int8 alpha);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor4bv(int8* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor4d(double red, double green, double blue, double alpha);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor4dv(double* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor4f(float red, float green, float blue, float alpha);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor4fv(float* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor4i(int32 red, int32 green, int32 blue, int32 alpha);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor4iv(int32* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor4s(int16 red, int16 green, int16 blue, int16 alpha);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor4sv(int16* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor4ub(uint8 red, uint8 green, uint8 blue, uint8 alpha);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor4ubv(uint8* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor4ui(uint32 red, uint32 green, uint32 blue, uint32 alpha);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor4uiv(uint32* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor4us(uint16 red, uint16 green, uint16 blue, uint16 alpha);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColor4usv(uint16* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColorMask(uint8 red, uint8 green, uint8 blue, uint8 alpha);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColorMaterial(uint32 face, uint32 mode);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glColorPointer(int32 size, uint32 type, int32 stride, void* pointer);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glCopyPixels(int32 x, int32 y, int32 width, int32 height, uint32 type);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glCopyTexImage1D(uint32 target, int32 level, uint32 internalFormat, int32 x, int32 y, int32 width, int32 border);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glCopyTexImage2D(uint32 target, int32 level, uint32 internalFormat, int32 x, int32 y, int32 width, int32 height, int32 border);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glCopyTexSubImage1D(uint32 target, int32 level, int32 xoffset, int32 x, int32 y, int32 width);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glCopyTexSubImage2D(uint32 target, int32 level, int32 xoffset, int32 yoffset, int32 x, int32 y, int32 width, int32 height);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glCullFace(uint32 mode);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glDeleteLists(uint32 list, int32 range);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glDeleteTextures(int32 n, uint32* textures);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glDepthFunc(uint32 func);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glDepthMask(uint8 flag);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glDepthRange(double zNear, double zFar);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glDisable(uint32 cap);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glDisableClientState(uint32 array);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glDrawArrays(uint32 mode, int32 first, int32 count);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glDrawBuffer(uint32 mode);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glDrawElements(uint32 mode, int32 count, uint32 type, void* indices);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glDrawPixels(int32 width, int32 height, uint32 format, uint32 type, void* pixels);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glEdgeFlag(uint8 flag);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glEdgeFlagPointer(int32 stride, void* pointer);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glEdgeFlagv(uint8* flag);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glEnable(uint32 cap);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glEnableClientState(uint32 array);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glEnd();

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glEndList();

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glEvalCoord1d(double u);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glEvalCoord1dv(double* u);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glEvalCoord1f(float u);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glEvalCoord1fv(float* u);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glEvalCoord2d(double u, double v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glEvalCoord2dv(double* u);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glEvalCoord2f(float u, float v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glEvalCoord2fv(float* u);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glEvalMesh1(uint32 mode, int32 i1, int32 i2);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glEvalMesh2(uint32 mode, int32 i1, int32 i2, int32 j1, int32 j2);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glEvalPoint1(int32 i);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glEvalPoint2(int32 i, int32 j);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glFeedbackBuffer(int32 size, uint32 type, float* buffer);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glFinish();

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glFlush();

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glFogf(uint32 pname, float param1);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glFogfv(uint32 pname, float* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glFogi(uint32 pname, int32 param1);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glFogiv(uint32 pname, int32* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glFrontFace(uint32 mode);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glFrustum(double left, double right, double bottom, double top, double zNear, double zFar);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 glGenLists(int32 range);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGenTextures(int32 n, uint32* textures);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGetBooleanv(uint32 pname, uint8* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGetClipPlane(uint32 plane, double* equation);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGetDoublev(uint32 pname, double* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 glGetError();

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGetFloatv(uint32 pname, float* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGetIntegerv(uint32 pname, int32* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGetLightfv(uint32 light, uint32 pname, float* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGetLightiv(uint32 light, uint32 pname, int32* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGetMapdv(uint32 target, uint32 query, double* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGetMapfv(uint32 target, uint32 query, float* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGetMapiv(uint32 target, uint32 query, int32* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGetMaterialfv(uint32 face, uint32 pname, float* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGetMaterialiv(uint32 face, uint32 pname, int32* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGetPixelMapfv(uint32 map, float* values);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGetPixelMapuiv(uint32 map, uint32* values);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGetPixelMapusv(uint32 map, uint16* values);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGetPointerv(uint32 pname, void** @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGetPolygonStipple(uint8* mask);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* glGetString(uint32 name);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGetTexEnvfv(uint32 target, uint32 pname, float* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGetTexEnviv(uint32 target, uint32 pname, int32* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGetTexGendv(uint32 coord, uint32 pname, double* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGetTexGenfv(uint32 coord, uint32 pname, float* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGetTexGeniv(uint32 coord, uint32 pname, int32* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGetTexImage(uint32 target, int32 level, uint32 format, uint32 type, void* pixels);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGetTexLevelParameterfv(uint32 target, int32 level, uint32 pname, float* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGetTexLevelParameteriv(uint32 target, int32 level, uint32 pname, int32* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGetTexParameterfv(uint32 target, uint32 pname, float* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glGetTexParameteriv(uint32 target, uint32 pname, int32* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glHint(uint32 target, uint32 mode);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glIndexMask(uint32 mask);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glIndexPointer(uint32 type, int32 stride, void* pointer);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glIndexd(double c);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glIndexdv(double* c);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glIndexf(float c);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glIndexfv(float* c);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glIndexi(int32 c);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glIndexiv(int32* c);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glIndexs(int16 c);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glIndexsv(int16* c);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glIndexub(uint8 c);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glIndexubv(uint8* c);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glInitNames();

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glInterleavedArrays(uint32 format, int32 stride, void* pointer);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8 glIsEnabled(uint32 cap);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8 glIsList(uint32 list);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8 glIsTexture(uint32 texture);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glLightModelf(uint32 pname, float param1);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glLightModelfv(uint32 pname, float* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glLightModeli(uint32 pname, int32 param1);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glLightModeliv(uint32 pname, int32* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glLightf(uint32 light, uint32 pname, float param2);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glLightfv(uint32 light, uint32 pname, float* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glLighti(uint32 light, uint32 pname, int32 param2);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glLightiv(uint32 light, uint32 pname, int32* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glLineStipple(int32 factor, uint16 pattern);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glLineWidth(float width);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glListBase(uint32 @base);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glLoadIdentity();

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glLoadMatrixd(double* m);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glLoadMatrixf(float* m);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glLoadName(uint32 name);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glLogicOp(uint32 opcode);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glMap1d(uint32 target, double u1, double u2, int32 stride, int32 order, double* points);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glMap1f(uint32 target, float u1, float u2, int32 stride, int32 order, float* points);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glMap2d(uint32 target, double u1, double u2, int32 ustride, int32 uorder, double v1, double v2, int32 vstride, int32 vorder, double* points);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glMap2f(uint32 target, float u1, float u2, int32 ustride, int32 uorder, float v1, float v2, int32 vstride, int32 vorder, float* points);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glMapGrid1d(int32 un, double u1, double u2);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glMapGrid1f(int32 un, float u1, float u2);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glMapGrid2d(int32 un, double u1, double u2, int32 vn, double v1, double v2);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glMapGrid2f(int32 un, float u1, float u2, int32 vn, float v1, float v2);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glMaterialf(uint32 face, uint32 pname, float param2);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glMaterialfv(uint32 face, uint32 pname, float* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glMateriali(uint32 face, uint32 pname, int32 param2);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glMaterialiv(uint32 face, uint32 pname, int32* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glMatrixMode(uint32 mode);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glMultMatrixd(double* m);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glMultMatrixf(float* m);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glNewList(uint32 list, uint32 mode);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glNormal3b(int8 nx, int8 ny, int8 nz);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glNormal3bv(int8* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glNormal3d(double nx, double ny, double nz);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glNormal3dv(double* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glNormal3f(float nx, float ny, float nz);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glNormal3fv(float* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glNormal3i(int32 nx, int32 ny, int32 nz);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glNormal3iv(int32* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glNormal3s(int16 nx, int16 ny, int16 nz);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glNormal3sv(int16* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glNormalPointer(uint32 type, int32 stride, void* pointer);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glOrtho(double left, double right, double bottom, double top, double zNear, double zFar);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glPassThrough(float token);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glPixelMapfv(uint32 map, int32 mapsize, float* values);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glPixelMapuiv(uint32 map, int32 mapsize, uint32* values);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glPixelMapusv(uint32 map, int32 mapsize, uint16* values);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glPixelStoref(uint32 pname, float param1);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glPixelStorei(uint32 pname, int32 param1);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glPixelTransferf(uint32 pname, float param1);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glPixelTransferi(uint32 pname, int32 param1);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glPixelZoom(float xfactor, float yfactor);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glPointSize(float size);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glPolygonMode(uint32 face, uint32 mode);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glPolygonOffset(float factor, float units);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glPolygonStipple(uint8* mask);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glPopAttrib();

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glPopClientAttrib();

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glPopMatrix();

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glPopName();

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glPrioritizeTextures(int32 n, uint32* textures, float* priorities);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glPushAttrib(uint32 mask);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glPushClientAttrib(uint32 mask);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glPushMatrix();

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glPushName(uint32 name);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRasterPos2d(double x, double y);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRasterPos2dv(double* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRasterPos2f(float x, float y);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRasterPos2fv(float* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRasterPos2i(int32 x, int32 y);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRasterPos2iv(int32* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRasterPos2s(int16 x, int16 y);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRasterPos2sv(int16* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRasterPos3d(double x, double y, double z);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRasterPos3dv(double* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRasterPos3f(float x, float y, float z);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRasterPos3fv(float* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRasterPos3i(int32 x, int32 y, int32 z);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRasterPos3iv(int32* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRasterPos3s(int16 x, int16 y, int16 z);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRasterPos3sv(int16* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRasterPos4d(double x, double y, double z, double w);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRasterPos4dv(double* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRasterPos4f(float x, float y, float z, float w);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRasterPos4fv(float* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRasterPos4i(int32 x, int32 y, int32 z, int32 w);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRasterPos4iv(int32* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRasterPos4s(int16 x, int16 y, int16 z, int16 w);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRasterPos4sv(int16* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glReadBuffer(uint32 mode);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glReadPixels(int32 x, int32 y, int32 width, int32 height, uint32 format, uint32 type, void* pixels);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRectd(double x1, double y1, double x2, double y2);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRectdv(double* v1, double* v2);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRectf(float x1, float y1, float x2, float y2);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRectfv(float* v1, float* v2);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRecti(int32 x1, int32 y1, int32 x2, int32 y2);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRectiv(int32* v1, int32* v2);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRects(int16 x1, int16 y1, int16 x2, int16 y2);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRectsv(int16* v1, int16* v2);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 glRenderMode(uint32 mode);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRotated(double angle, double x, double y, double z);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glRotatef(float angle, float x, float y, float z);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glScaled(double x, double y, double z);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glScalef(float x, float y, float z);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glScissor(int32 x, int32 y, int32 width, int32 height);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glSelectBuffer(int32 size, uint32* buffer);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glShadeModel(uint32 mode);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glStencilFunc(uint32 func, int32 @ref, uint32 mask);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glStencilMask(uint32 mask);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glStencilOp(uint32 fail, uint32 zfail, uint32 zpass);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord1d(double s);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord1dv(double* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord1f(float s);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord1fv(float* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord1i(int32 s);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord1iv(int32* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord1s(int16 s);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord1sv(int16* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord2d(double s, double t);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord2dv(double* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord2f(float s, float t);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord2fv(float* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord2i(int32 s, int32 t);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord2iv(int32* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord2s(int16 s, int16 t);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord2sv(int16* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord3d(double s, double t, double r);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord3dv(double* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord3f(float s, float t, float r);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord3fv(float* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord3i(int32 s, int32 t, int32 r);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord3iv(int32* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord3s(int16 s, int16 t, int16 r);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord3sv(int16* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord4d(double s, double t, double r, double q);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord4dv(double* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord4f(float s, float t, float r, float q);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord4fv(float* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord4i(int32 s, int32 t, int32 r, int32 q);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord4iv(int32* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord4s(int16 s, int16 t, int16 r, int16 q);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoord4sv(int16* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexCoordPointer(int32 size, uint32 type, int32 stride, void* pointer);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexEnvf(uint32 target, uint32 pname, float param2);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexEnvfv(uint32 target, uint32 pname, float* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexEnvi(uint32 target, uint32 pname, int32 param2);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexEnviv(uint32 target, uint32 pname, int32* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexGend(uint32 coord, uint32 pname, double param2);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexGendv(uint32 coord, uint32 pname, double* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexGenf(uint32 coord, uint32 pname, float param2);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexGenfv(uint32 coord, uint32 pname, float* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexGeni(uint32 coord, uint32 pname, int32 param2);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexGeniv(uint32 coord, uint32 pname, int32* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexImage1D(uint32 target, int32 level, int32 internalformat, int32 width, int32 border, uint32 format, uint32 type, void* pixels);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexImage2D(uint32 target, int32 level, int32 internalformat, int32 width, int32 height, int32 border, uint32 format, uint32 type, void* pixels);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexParameterf(uint32 target, uint32 pname, float param2);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexParameterfv(uint32 target, uint32 pname, float* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexParameteri(uint32 target, uint32 pname, int32 param2);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexParameteriv(uint32 target, uint32 pname, int32* @params);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexSubImage1D(uint32 target, int32 level, int32 xoffset, int32 width, uint32 format, uint32 type, void* pixels);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTexSubImage2D(uint32 target, int32 level, int32 xoffset, int32 yoffset, int32 width, int32 height, uint32 format, uint32 type, void* pixels);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTranslated(double x, double y, double z);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glTranslatef(float x, float y, float z);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glVertex2d(double x, double y);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glVertex2dv(double* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glVertex2f(float x, float y);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glVertex2fv(float* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glVertex2i(int32 x, int32 y);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glVertex2iv(int32* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glVertex2s(int16 x, int16 y);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glVertex2sv(int16* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glVertex3d(double x, double y, double z);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glVertex3dv(double* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glVertex3f(float x, float y, float z);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glVertex3fv(float* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glVertex3i(int32 x, int32 y, int32 z);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glVertex3iv(int32* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glVertex3s(int16 x, int16 y, int16 z);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glVertex3sv(int16* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glVertex4d(double x, double y, double z, double w);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glVertex4dv(double* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glVertex4f(float x, float y, float z, float w);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glVertex4fv(float* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glVertex4i(int32 x, int32 y, int32 z, int32 w);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glVertex4iv(int32* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glVertex4s(int16 x, int16 y, int16 z, int16 w);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glVertex4sv(int16* v);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glVertexPointer(int32 size, uint32 type, int32 stride, void* pointer);

	[Import("OPENGL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void glViewport(int32 x, int32 y, int32 width, int32 height);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* gluErrorString(uint32 errCode);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR gluErrorUnicodeStringEXT(uint32 errCode);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* gluGetString(uint32 name);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluOrtho2D(double left, double right, double bottom, double top);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluPerspective(double fovy, double aspect, double zNear, double zFar);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluPickMatrix(double x, double y, double width, double height, int32* viewport);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluLookAt(double eyex, double eyey, double eyez, double centerx, double centery, double centerz, double upx, double upy, double upz);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 gluProject(double objx, double objy, double objz, double* modelMatrix, double* projMatrix, int32* viewport, double* winx, double* winy, double* winz);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 gluUnProject(double winx, double winy, double winz, double* modelMatrix, double* projMatrix, int32* viewport, double* objx, double* objy, double* objz);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 gluScaleImage(uint32 format, int32 widthin, int32 heightin, uint32 typein, void* datain, int32 widthout, int32 heightout, uint32 typeout, void* dataout);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 gluBuild1DMipmaps(uint32 target, int32 components, int32 width, uint32 format, uint32 type, void* data);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 gluBuild2DMipmaps(uint32 target, int32 components, int32 width, int32 height, uint32 format, uint32 type, void* data);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern GLUquadric* gluNewQuadric();

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluDeleteQuadric(GLUquadric* state);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluQuadricNormals(GLUquadric* quadObject, uint32 normals);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluQuadricTexture(GLUquadric* quadObject, uint8 textureCoords);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluQuadricOrientation(GLUquadric* quadObject, uint32 orientation);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluQuadricDrawStyle(GLUquadric* quadObject, uint32 drawStyle);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluCylinder(GLUquadric* qobj, double baseRadius, double topRadius, double height, int32 slices, int32 stacks);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluDisk(GLUquadric* qobj, double innerRadius, double outerRadius, int32 slices, int32 loops);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluPartialDisk(GLUquadric* qobj, double innerRadius, double outerRadius, int32 slices, int32 loops, double startAngle, double sweepAngle);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluSphere(GLUquadric* qobj, double radius, int32 slices, int32 stacks);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluQuadricCallback(GLUquadric* qobj, uint32 which, int fn);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern GLUtesselator* gluNewTess();

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluDeleteTess(GLUtesselator* tess);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluTessBeginPolygon(GLUtesselator* tess, void* polygon_data);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluTessBeginContour(GLUtesselator* tess);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluTessVertex(GLUtesselator* tess, double* coords, void* data);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluTessEndContour(GLUtesselator* tess);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluTessEndPolygon(GLUtesselator* tess);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluTessProperty(GLUtesselator* tess, uint32 which, double value);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluTessNormal(GLUtesselator* tess, double x, double y, double z);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluTessCallback(GLUtesselator* tess, uint32 which, int fn);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluGetTessProperty(GLUtesselator* tess, uint32 which, double* value);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern GLUnurbs* gluNewNurbsRenderer();

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluDeleteNurbsRenderer(GLUnurbs* nobj);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluBeginSurface(GLUnurbs* nobj);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluBeginCurve(GLUnurbs* nobj);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluEndCurve(GLUnurbs* nobj);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluEndSurface(GLUnurbs* nobj);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluBeginTrim(GLUnurbs* nobj);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluEndTrim(GLUnurbs* nobj);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluPwlCurve(GLUnurbs* nobj, int32 count, float* array, int32 stride, uint32 type);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluNurbsCurve(GLUnurbs* nobj, int32 nknots, float* knot, int32 stride, float* ctlarray, int32 order, uint32 type);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluNurbsSurface(GLUnurbs* nobj, int32 sknot_count, float* sknot, int32 tknot_count, float* tknot, int32 s_stride, int32 t_stride, float* ctlarray, int32 sorder, int32 torder, uint32 type);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluLoadSamplingMatrices(GLUnurbs* nobj, float* modelMatrix, float* projMatrix, int32* viewport);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluNurbsProperty(GLUnurbs* nobj, uint32 property, float value);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluGetNurbsProperty(GLUnurbs* nobj, uint32 property, float* value);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluNurbsCallback(GLUnurbs* nobj, uint32 which, int fn);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluBeginPolygon(GLUtesselator* tess);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluNextContour(GLUtesselator* tess, uint32 type);

	[Import("GLU32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void gluEndPolygon(GLUtesselator* tess);

}
#endregion
