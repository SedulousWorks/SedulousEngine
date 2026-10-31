<!--
  The render textures picker (ruling 21): the graph's textures of the last frame, the picker's, under
  their passes and searched, where they had been one long menu. A row is a texture, its size and
  format beside it; a depth texture shows as distance. Picking one shows it in the view and the
  shading chip names it. The mock's rows are a frame's of the default renderer.
-->
<Panel class="dialog picker texture-picker">
    <Panel class="picker-search">
        <Panel class="search"><Image class="search-icon" src="Editor/Icons/search.svg"/><TextField class="search-field" placeholder="Search render textures"/></Panel>
    </Panel>
    <TreeView id="texture-tree" class="picker-list texture-tree">
        <TreeItem text="Scene" expanded="true">
            <TreeItem text="scene.color  ·  1920x1080  ·  RGBA16F" icon="Editor/Icons/texture.svg"/>
            <TreeItem text="depth.prepass  ·  1920x1080  ·  depth" icon="Editor/Icons/texture.svg"/>
            <TreeItem text="motion.vectors  ·  1920x1080  ·  RG16F" icon="Editor/Icons/texture.svg"/>
        </TreeItem>
        <TreeItem text="Ambient occlusion" expanded="true">
            <TreeItem text="ao.raw  ·  960x540  ·  R8" icon="Editor/Icons/texture.svg"/>
            <TreeItem text="ao.blur  ·  960x540  ·  R8" icon="Editor/Icons/texture.svg"/>
            <TreeItem text="ao.ao  ·  1920x1080  ·  R8" icon="Editor/Icons/texture.svg"/>
        </TreeItem>
        <TreeItem text="Global illumination (SSGI)" expanded="true">
            <TreeItem text="ssgi.raw  ·  960x540  ·  RGBA16F" icon="Editor/Icons/texture.svg"/>
            <TreeItem text="ssgi.denoise1  ·  960x540  ·  RGBA16F" icon="Editor/Icons/texture.svg"/>
            <TreeItem text="ssgi.history  ·  960x540  ·  RGBA16F" icon="Editor/Icons/texture.svg"/>
            <TreeItem text="ssgi.filtered  ·  960x540  ·  RGBA16F" icon="Editor/Icons/texture.svg"/>
            <TreeItem text="ssgi.composite  ·  1920x1080  ·  RGBA16F" icon="Editor/Icons/texture.svg"/>
        </TreeItem>
        <TreeItem text="Reflections (SSR)">
            <TreeItem text="ssr.refl  ·  960x540  ·  RGBA16F" icon="Editor/Icons/texture.svg"/>
        </TreeItem>
        <TreeItem text="Shadows">
            <TreeItem text="shadow.cascades  ·  2048x2048 x4  ·  depth" icon="Editor/Icons/texture.svg"/>
            <TreeItem text="shadow.atlas  ·  4096x4096  ·  depth" icon="Editor/Icons/texture.svg"/>
        </TreeItem>
        <TreeItem text="Bloom">
            <TreeItem text="bloom.down  ·  960x540  ·  RGBA16F" icon="Editor/Icons/texture.svg"/>
            <TreeItem text="bloom.up  ·  960x540  ·  RGBA16F" icon="Editor/Icons/texture.svg"/>
        </TreeItem>
        <TreeItem text="Exposure and post">
            <TreeItem text="exposure.adapted  ·  1x1  ·  R32F" icon="Editor/Icons/texture.svg"/>
            <TreeItem text="post.ldr  ·  1920x1080  ·  RGBA8" icon="Editor/Icons/texture.svg"/>
        </TreeItem>
    </TreeView>
    <Panel class="picker-foot"><Label class="picker-hint" text="The last frame's, 18 textures in 7 passes"/><Spacer/><Button class="ghost" text="Back to Lit"/></Panel>
</Panel>
