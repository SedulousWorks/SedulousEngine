# NativeSample's authoring tools

NativeSample's content is built through the editor's MCP tools, by the project's own editor: the
stock editor does not link the sample's package, so it knows neither the Spin component, the Bob
behaviour, the Arena level nor the note asset type. Open the project in the stock editor
(`Sedulous.Tools.Editor --project Data/SampleProjects/NativeSample`), run Project > Build Project,
then start the editor it built with the MCP server on:

```
Data/SampleProjects/NativeSample/Code/build/Debug_Linux64/NativeSampleEditor/NativeSampleEditor \
    --project Data/SampleProjects/NativeSample --data-root Data --mcp-port 7420
```

(the port `mcp.py` uses unless `MCP_PORT` says otherwise), then run the script. None of this is
game content.

- `mcp.py`: a small MCP client (`python3 mcp.py http <tool> '<json args>'`, or `--list`).
- `scenegen.py`: scene XML built from the running editor's `component_schema`, so a component
  record starts from the engine's own defaults; the plugin's Spin component and Bob behaviour, and
  its Arena level's settings block, are in the schema while the plugin is loaded.
- `spinners.py`: the content. The Cube and Plane primitives, a note (Notes/Welcome, the Pipeline
  part's asset type), and the scene Spinners (Scenes/Spinners), made the project's default: a
  floor, a row of five cubes that each spin at their own rate about their own axis (the middle one
  also moving up and down, by the plugin's Bob behaviour), and a carousel whose hub turns four
  arms, each carrying a cube that spins as well, lit by a sun under the default sky. The scene
  turns on the plugin's Arena level in its settings, a 30 second round clock. Every cube is the Cube primitive on the default material, told apart by its tint. A rerun
  writes the scene over itself and makes nothing twice.

## The port

These are Raptor's NativeSample tools, ported: `mcp.py` and `scenegen.py` are the Shader Gallery's
here (short asset type names, this engine's settings layout), and `spinners.py` builds the same
scene, under this engine's default environment.
