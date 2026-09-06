#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

// Minimal JSON tokenizer test to see if jsmn chokes
// Inline jsmn from cgltf to test

typedef enum {
	JSMN_UNDEFINED = 0,
	JSMN_OBJECT = 1,
	JSMN_ARRAY = 2,
	JSMN_STRING = 3,
	JSMN_PRIMITIVE = 4
} jsmntype_t;

typedef struct {
	jsmntype_t type;
	int start;
	int end;
	int size;
} jsmntok_t;

// We'll just test if fopen works for this path
int main(void)
{
    const char* path = "D:\\Dev\\Beef\\BeefGFX\\SedulousEngine\\Assets\\samples\\kenney_nature-kit\\Models\\GLTF format\\ground_grass.glb";

    // Read the file
    FILE* f = fopen(path, "rb");
    if (!f) { printf("fopen FAILED\n"); return 1; }
    fseek(f, 0, SEEK_END);
    long file_size = ftell(f);
    fseek(f, 0, SEEK_SET);
    uint8_t* buf = malloc(file_size);
    size_t nread = fread(buf, 1, file_size, f);
    fclose(f);
    printf("Read %zu bytes (expected %ld)\n", nread, file_size);

    // Extract JSON
    uint32_t json_len;
    memcpy(&json_len, buf+12, 4);
    const char* json = (const char*)(buf + 20);
    printf("JSON length: %u\n", json_len);

    // Check for null bytes in JSON
    int nulls = 0;
    for (uint32_t i = 0; i < json_len; i++) {
        if (json[i] == 0) nulls++;
    }
    printf("Null bytes in JSON: %d\n", nulls);

    // Check JSON ends properly
    printf("Last 10 chars of JSON: '");
    for (uint32_t i = json_len > 10 ? json_len - 10 : 0; i < json_len; i++)
        putchar(json[i]);
    printf("'\n");

    // Check padding after JSON (GLB spec says JSON chunk is padded with spaces to 4-byte boundary)
    printf("JSON len mod 4: %u\n", json_len % 4);
    if (json_len % 4 != 0) {
        printf("JSON chunk not 4-byte aligned!\n");
    }

    // Check what's after the JSON chunk
    uint32_t json_chunk_end = 20 + json_len;
    printf("After JSON chunk at offset %u:\n", json_chunk_end);
    if (json_chunk_end + 8 <= (uint32_t)file_size) {
        uint32_t bin_len, bin_magic;
        memcpy(&bin_len, buf + json_chunk_end, 4);
        memcpy(&bin_magic, buf + json_chunk_end + 4, 4);
        printf("  BIN len: %u, magic: 0x%08X (expect 0x004E4942)\n", bin_len, bin_magic);
    }

    // Now try different cgltf versions behavior:
    // The issue might be that cgltf_parse expects GlbHeaderSize = 12 but checks size < 12
    printf("\nGlbHeaderSize check: file_size(%ld) >= 12? %s\n", file_size, file_size >= 12 ? "yes" : "no");

    // Check if it's a token count issue
    // Rough estimate: cgltf uses file_size/4 + 128 for token count with auto
    printf("Auto token count estimate: %ld\n", file_size / 4 + 128);

    // Try with an explicit large token count
    printf("\n--- Trying cgltf_parse with explicit token count ---\n");

    // We need to include the real cgltf for this
    free(buf);
    return 0;
}
