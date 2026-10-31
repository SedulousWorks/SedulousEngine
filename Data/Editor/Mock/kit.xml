<!--
  The kit (Documentation/Specs/editor-gui-catalog.md, section 2): every piece the editor's pages
  share, designed once, shown in its states. A state the pointer or the focus makes (hover, press,
  focus) is live on the real widgets; where a piece is drawn here before its widget exists (the
  component header, the slots, the problems list), its states are drawn side by side.
-->
<Panel class="page kit-page">
    <ScrollView id="kit-scroll" class="kit-scroll">
        <Panel class="kit">

            <!-- ========== Actions ========== -->
            <Label class="kit-title" text="Actions"/>
            <Label class="kit-note" text="Neutral by default; one primary per surface; a destructive verb says what it destroys. A disabled action says why in its tooltip."/>
            <Panel class="kit-row">
                <Panel class="kit-cell"><Button class="primary" text="Create"/><Label class="kit-caption" text="primary"/></Panel>
                <Panel class="kit-cell"><Button text="Cancel"/><Label class="kit-caption" text="neutral"/></Panel>
                <Panel class="kit-cell"><Button class="ghost" text="Show in Console"/><Label class="kit-caption" text="ghost"/></Panel>
                <Panel class="kit-cell"><Button class="danger" text="Delete 3 Assets"/><Label class="kit-caption" text="destructive"/></Panel>
                <Panel class="kit-cell"><Button class="primary" text="Export" enabled="false" tooltip="Choose a target platform first"/><Label class="kit-caption" text="disabled, with a reason"/></Panel>
                <Panel class="kit-cell"><Button class="with-icon" icon="Editor/Icons/plus.svg" text="Add Component"/><Label class="kit-caption" text="icon and verb"/></Panel>
                <Panel class="kit-cell">
                    <Panel class="kit-inline">
                        <Button class="icon-button" icon="Editor/Icons/filter.svg" tooltip="Filter by type"/>
                        <Button class="icon-button checked" icon="Editor/Icons/tiles.svg" tooltip="Tiles"/>
                        <Button class="icon-button" icon="Editor/Icons/trash.svg" enabled="false" tooltip="Nothing selected"/>
                    </Panel>
                    <Label class="kit-caption" text="icon: rest, on, disabled"/>
                </Panel>
            </Panel>
            <Panel class="kit-row">
                <Panel class="kit-cell">
                    <Panel class="segmented">
                        <Button class="segment" name="kit-seg" toggle="true" checked="true" text="Local"/>
                        <Button class="segment" name="kit-seg" toggle="true" text="World"/>
                        <Button class="segment" name="kit-seg" toggle="true" text="Parent"/>
                    </Panel>
                    <Label class="kit-caption" text="segmented choice (one of a few, all shown)"/>
                </Panel>
                <Panel class="kit-cell">
                    <Panel class="kit-inline">
                        <CheckBox text="Cast Shadows" checked="true"/>
                        <CheckBox text="Static"/>
                        <CheckBox text="Visible" indeterminate="true" tooltip="Some of the selection"/>
                        <CheckBox text="Locked" enabled="false"/>
                    </Panel>
                    <Label class="kit-caption" text="check: on, off, mixed, disabled"/>
                </Panel>
                <Panel class="kit-cell">
                    <Panel class="kit-inline">
                        <ToggleSwitch checked="true"/>
                        <ToggleSwitch/>
                    </Panel>
                    <Label class="kit-caption" text="switch: takes effect at once"/>
                </Panel>
                <Panel class="kit-cell">
                    <Panel class="kit-inline">
                        <RadioButton name="kit-radio" text="Perspective" checked="true"/>
                        <RadioButton name="kit-radio" text="Orthographic"/>
                    </Panel>
                    <Label class="kit-caption" text="radio"/>
                </Panel>
            </Panel>

            <!-- ========== Fields ========== -->
            <Label class="kit-title" text="Fields"/>
            <Label class="kit-note" text="A field sinks into its surface. Invalid says why under it, live; read-only has no frame, so it never looks editable."/>
            <Panel class="kit-row">
                <Panel class="kit-cell kit-field"><TextField placeholder="Name the scene"/><Label class="kit-caption" text="empty"/></Panel>
                <Panel class="kit-cell kit-field"><TextField text="Level 1"/><Label class="kit-caption" text="filled"/></Panel>
                <Panel class="kit-cell kit-field">
                    <TextField class="invalid" text="Level/1"/>
                    <Panel class="field-message danger"><Image class="message-icon" src="Editor/Icons/error.svg"/><Label text="A name cannot hold /"/></Panel>
                </Panel>
                <Panel class="kit-cell kit-field"><TextField class="read-only" readOnly="true" text="7f3a1c0e-4b2d"/><Label class="kit-caption" text="read-only"/></Panel>
                <Panel class="kit-cell kit-field"><TextField text="Disabled" enabled="false"/><Label class="kit-caption" text="disabled"/></Panel>
            </Panel>
            <Panel class="kit-row">
                <Panel class="kit-cell kit-field">
                    <Panel class="with-unit"><NumberField value="12" min="0" max="1000" step="0.1"/><Label class="unit" text="kg"/></Panel>
                    <Label class="kit-caption" text="number with its unit"/>
                </Panel>
                <Panel class="kit-cell kit-field">
                    <Panel class="with-unit"><NumberField value="45"/><Label class="unit" text="deg"/></Panel>
                    <Label class="kit-caption" text="angles always in degrees"/>
                </Panel>
                <Panel class="kit-cell kit-field">
                    <Panel class="slider-field"><Slider value="0.6" min="0" max="1"/><NumberField value="0.6" min="0" max="1" step="0.01"/></Panel>
                    <Label class="kit-caption" text="slider with its value"/>
                </Panel>
                <Panel class="kit-cell kit-field"><ComboBox items="Dynamic|Kinematic|Static" selected="0"/><Label class="kit-caption" text="choice by name"/></Panel>
                <Panel class="kit-cell kit-field">
                    <Panel class="search">
                        <Image class="search-icon" src="Editor/Icons/search.svg"/>
                        <TextField class="search-field" text="crate"/>
                        <Button class="search-clear" icon="Editor/Icons/close.svg" tooltip="Clear (Esc)"/>
                    </Panel>
                    <Label class="kit-caption" text="search: clear once typed"/>
                </Panel>
            </Panel>

            <!-- ========== Chips and badges ========== -->
            <Label class="kit-title" text="Chips and badges"/>
            <Label class="kit-note" text="A chip is a filter you press. A badge is a fact about a row, one look in every list and picker."/>
            <Panel class="kit-row">
                <Panel class="kit-cell">
                    <Panel class="kit-inline">
                        <Button class="chip checked" text="Info 128"/>
                        <Button class="chip warning checked" text="Warnings 3"/>
                        <Button class="chip error" text="Errors 1"/>
                    </Panel>
                    <Label class="kit-caption" text="chips: on, on, off"/>
                </Panel>
                <Panel class="kit-cell">
                    <Panel class="kit-inline">
                        <Label class="badge success" text="Cooked"/>
                        <Label class="badge warning" text="Stale"/>
                        <Label class="badge danger" text="Failed"/>
                        <Label class="badge accent" text="Override"/>
                        <Label class="badge" text="Always Export"/>
                        <Image class="badge-icon star" src="Editor/Icons/star.svg" tooltip="Favourite"/>
                        <Panel class="dirty-dot" tooltip="Unsaved changes"/>
                    </Panel>
                    <Label class="kit-caption" text="badges, favourite, unsaved"/>
                </Panel>
            </Panel>

            <!-- ========== Lists and trees ========== -->
            <Label class="kit-title" text="Lists and trees"/>
            <Label class="kit-note" text="Type icons are tinted by category where the eye scans a list, so the kind of a row reads before its name. Prefab instances name themselves in the accent; a hidden entity dims."/>
            <Panel class="kit-row">
                <Panel class="kit-cell kit-list">
                    <Panel class="kit-rows">
                        <Panel class="tree-row"><Image class="row-arrow" src="Editor/Icons/chevron-down.svg"/><Image class="row-icon" src="Editor/Icons/layers.svg"/><Label class="row-name strong" text="Level 1"/></Panel>
                        <Panel class="tree-row depth-1"><Image class="row-icon cat-rendering" src="Editor/Icons/sun.svg"/><Label class="row-name" text="Sun"/></Panel>
                        <Panel class="tree-row depth-1 kit-hover"><Image class="row-arrow" src="Editor/Icons/chevron-down.svg"/><Image class="row-icon cat-physics" src="Editor/Icons/character.svg"/><Label class="row-name prefab" text="Player"/><Label class="row-count" text="3"/></Panel>
                        <Panel class="tree-row depth-2"><Image class="row-icon cat-rendering" src="Editor/Icons/camera.svg"/><Label class="row-name" text="Camera"/></Panel>
                        <Panel class="tree-row depth-2 kit-selected"><Image class="row-icon cat-rendering" src="Editor/Icons/cube.svg"/><Label class="row-name" text="Model"/></Panel>
                        <Panel class="tree-row depth-2"><Image class="row-icon cat-audio" src="Editor/Icons/speaker.svg"/><Label class="row-name" text="Footsteps"/></Panel>
                        <Panel class="drop-line depth-2"/>
                        <Panel class="tree-row depth-1 hidden-entity"><Image class="row-icon cat-physics" src="Editor/Icons/physics.svg"/><Label class="row-name" text="Trigger"/><Spacer/><Image class="row-trail" src="Editor/Icons/eye-off.svg"/></Panel>
                        <Panel class="tree-row depth-1 renaming"><Image class="row-icon cat-rendering" src="Editor/Icons/cube.svg"/><TextField class="rename-field" text="Crate 4"/></Panel>
                        <Panel class="tree-row depth-1"><Image class="row-icon cat-effects" src="Editor/Icons/particles.svg"/><Label class="row-name" text="Sparks"/></Panel>
                    </Panel>
                    <Label class="kit-caption" text="tree: hover, selected, drop line, hidden, renaming, prefab"/>
                </Panel>
                <Panel class="kit-cell kit-list">
                    <Panel class="kit-rows">
                        <Panel class="asset-row"><Image class="row-icon cat-rendering" src="Editor/Icons/cube.svg"/><Label class="row-name" text="Crate"/><Label class="row-kind" text="Model"/><Label class="badge success" text="Cooked"/></Panel>
                        <Panel class="asset-row kit-selected"><Image class="row-icon cat-rendering" src="Editor/Icons/material.svg"/><Label class="row-name" text="Wood"/><Label class="row-kind" text="Material"/><Panel class="dirty-dot"/></Panel>
                        <Panel class="asset-row"><Image class="row-icon cat-rendering" src="Editor/Icons/texture.svg"/><Label class="row-name" text="Brick_Albedo"/><Label class="row-kind" text="Texture"/><Label class="badge warning" text="Stale"/></Panel>
                        <Panel class="asset-row"><Image class="row-icon cat-audio" src="Editor/Icons/speaker.svg"/><Label class="row-name" text="Footstep"/><Label class="row-kind" text="Sound"/><Image class="badge-icon star" src="Editor/Icons/star.svg"/></Panel>
                        <Panel class="asset-row"><Image class="row-icon cat-scripting" src="Editor/Icons/script.svg"/><Label class="row-name" text="Player"/><Label class="row-kind" text="Script"/><Label class="badge danger" text="Failed"/></Panel>
                        <Panel class="asset-row"><Image class="row-icon cat-gui" src="Editor/Icons/gui-panel.svg"/><Label class="row-name" text="Menu"/><Label class="row-kind" text="GUI"/></Panel>
                        <Panel class="asset-row"><Image class="row-icon cat-animation" src="Editor/Icons/animation.svg"/><Label class="row-name" text="Run"/><Label class="row-kind" text="Animation"/></Panel>
                        <Panel class="asset-row"><Image class="row-icon" src="Editor/Icons/font.svg"/><Label class="row-name" text="Inter"/><Label class="row-kind" text="Font"/></Panel>
                    </Panel>
                    <Label class="kit-caption" text="asset rows: icon, name, kind, badge"/>
                </Panel>
                <Panel class="kit-cell">
                    <Panel class="kit-tiles">
                        <Panel class="tile"><Panel class="tile-thumb"><Image class="tile-glyph cat-rendering" src="Editor/Icons/cube.svg"/></Panel><Label class="tile-name" text="Crate"/></Panel>
                        <Panel class="tile kit-hover"><Panel class="tile-thumb"><Image class="tile-glyph cat-rendering" src="Editor/Icons/material.svg"/><Panel class="tile-badges"><Panel class="dirty-dot"/></Panel></Panel><Label class="tile-name" text="Wood"/></Panel>
                        <Panel class="tile kit-selected"><Panel class="tile-thumb"><Image class="tile-glyph cat-audio" src="Editor/Icons/speaker.svg"/><Panel class="tile-badges"><Image class="badge-icon star" src="Editor/Icons/star.svg"/></Panel></Panel><Label class="tile-name" text="Footstep"/></Panel>
                        <Panel class="tile"><Panel class="tile-thumb"><Image class="tile-glyph cat-scripting" src="Editor/Icons/script.svg"/><Panel class="tile-badges"><Image class="badge-icon danger" src="Editor/Icons/error.svg"/></Panel></Panel><Label class="tile-name" text="Player_Controller_Long_Name"/></Panel>
                    </Panel>
                    <Label class="kit-caption" text="tiles: rest, hover, selected, failed; long names ellipsize"/>
                </Panel>
            </Panel>
            <Panel class="kit-row">
                <Panel class="kit-cell">
                    <Panel class="drag-ghost"><Image class="row-icon cat-rendering" src="Editor/Icons/cube.svg"/><Label text="Crate"/><Label class="drag-count" text="+2"/></Panel>
                    <Label class="kit-caption" text="drag ghost: what moves, not a grey box"/>
                </Panel>
                <Panel class="kit-cell">
                    <Panel class="drag-ghost refused"><Image class="row-icon" src="Editor/Icons/script.svg"/><Label text="Player"/><Label class="drag-reason" text="A script cannot go on a group"/></Panel>
                    <Label class="kit-caption" text="refused, with the reason"/>
                </Panel>
            </Panel>

            <!-- ========== Type icons ========== -->
            <Label class="kit-title" text="Type icons"/>
            <Label class="kit-note" text="One per asset and component type, named by the type (MeshComponent.svg), found by asking the type: its own, its base's, then a generic one. Tinted by the category the type declares; Scene and Utility stay neutral."/>
            <Label class="kit-subtitle" text="Assets"/>
            <Panel class="type-groups">
                <Panel class="type-group"><Label class="type-group-name" text="Scene"/>
                    <Panel class="type-cell" tooltip="SceneDocument"><Image class="row-icon" src="Editor/Icons/Types/SceneDocument.svg"/><Label class="type-name" text="Scene"/></Panel>
                    <Panel class="type-cell" tooltip="PrefabDocument"><Image class="row-icon" src="Editor/Icons/Types/PrefabDocument.svg"/><Label class="type-name" text="Prefab"/></Panel>
                </Panel>
                <Panel class="type-group"><Label class="type-group-name" text="Rendering"/>
                    <Panel class="type-cell" tooltip="ModelManifestAsset"><Image class="row-icon cat-rendering" src="Editor/Icons/Types/ModelManifestAsset.svg"/><Label class="type-name" text="Model Manifest"/></Panel>
                    <Panel class="type-cell" tooltip="StaticMeshAsset"><Image class="row-icon cat-rendering" src="Editor/Icons/Types/StaticMeshAsset.svg"/><Label class="type-name" text="Static Mesh"/></Panel>
                    <Panel class="type-cell" tooltip="SkinnedMeshAsset"><Image class="row-icon cat-rendering" src="Editor/Icons/Types/SkinnedMeshAsset.svg"/><Label class="type-name" text="Skinned Mesh"/></Panel>
                    <Panel class="type-cell" tooltip="MaterialAsset"><Image class="row-icon cat-rendering" src="Editor/Icons/Types/MaterialAsset.svg"/><Label class="type-name" text="Material"/></Panel>
                    <Panel class="type-cell" tooltip="ShaderAsset"><Image class="row-icon cat-rendering" src="Editor/Icons/Types/ShaderAsset.svg"/><Label class="type-name" text="Shader"/></Panel>
                    <Panel class="type-cell" tooltip="TextureAsset"><Image class="row-icon cat-rendering" src="Editor/Icons/Types/TextureAsset.svg"/><Label class="type-name" text="Texture"/></Panel>
                    <Panel class="type-cell" tooltip="RenderTextureAsset"><Image class="row-icon cat-rendering" src="Editor/Icons/Types/RenderTextureAsset.svg"/><Label class="type-name" text="Render Texture"/></Panel>
                    <Panel class="type-cell" tooltip="ImageAsset"><Image class="row-icon cat-rendering" src="Editor/Icons/Types/ImageAsset.svg"/><Label class="type-name" text="Image"/></Panel>
                    <Panel class="type-cell" tooltip="VectorImageAsset"><Image class="row-icon cat-rendering" src="Editor/Icons/Types/VectorImageAsset.svg"/><Label class="type-name" text="Vector Image"/></Panel>
                    <Panel class="type-cell" tooltip="EnvironmentProfileAsset"><Image class="row-icon cat-rendering" src="Editor/Icons/Types/EnvironmentProfileAsset.svg"/><Label class="type-name" text="Environment Profile"/></Panel>
                    <Panel class="type-cell" tooltip="PostProcessProfileAsset"><Image class="row-icon cat-rendering" src="Editor/Icons/Types/PostProcessProfileAsset.svg"/><Label class="type-name" text="Post Process Profile"/></Panel>
                </Panel>
                <Panel class="type-group"><Label class="type-group-name" text="Effects"/>
                    <Panel class="type-cell" tooltip="ParticleEffectAsset"><Image class="row-icon cat-effects" src="Editor/Icons/Types/ParticleEffectAsset.svg"/><Label class="type-name" text="Particle Effect"/></Panel>
                </Panel>
                <Panel class="type-group"><Label class="type-group-name" text="Animation"/>
                    <Panel class="type-cell" tooltip="SkeletonAsset"><Image class="row-icon cat-animation" src="Editor/Icons/Types/SkeletonAsset.svg"/><Label class="type-name" text="Skeleton"/></Panel>
                    <Panel class="type-cell" tooltip="AnimationClipAsset"><Image class="row-icon cat-animation" src="Editor/Icons/Types/AnimationClipAsset.svg"/><Label class="type-name" text="Animation Clip"/></Panel>
                    <Panel class="type-cell" tooltip="AnimationGraphAsset"><Image class="row-icon cat-animation" src="Editor/Icons/Types/AnimationGraphAsset.svg"/><Label class="type-name" text="Animation Graph"/></Panel>
                    <Panel class="type-cell" tooltip="PropertyAnimationClipAsset"><Image class="row-icon cat-animation" src="Editor/Icons/Types/PropertyAnimationClipAsset.svg"/><Label class="type-name" text="Property Animation Clip"/></Panel>
                </Panel>
                <Panel class="type-group"><Label class="type-group-name" text="Audio"/>
                    <Panel class="type-cell" tooltip="AudioClipAsset"><Image class="row-icon cat-audio" src="Editor/Icons/Types/AudioClipAsset.svg"/><Label class="type-name" text="Audio Clip"/></Panel>
                    <Panel class="type-cell" tooltip="AudioBusLayoutAsset"><Image class="row-icon cat-audio" src="Editor/Icons/Types/AudioBusLayoutAsset.svg"/><Label class="type-name" text="Audio Bus Layout"/></Panel>
                    <Panel class="type-cell" tooltip="SoundCueAsset"><Image class="row-icon cat-audio" src="Editor/Icons/Types/SoundCueAsset.svg"/><Label class="type-name" text="Sound Cue"/></Panel>
                </Panel>
                <Panel class="type-group"><Label class="type-group-name" text="Scripting"/>
                    <Panel class="type-cell" tooltip="ScriptClassAsset"><Image class="row-icon cat-scripting" src="Editor/Icons/Types/ScriptClassAsset.svg"/><Label class="type-name" text="Script Class"/></Panel>
                </Panel>
                <Panel class="type-group"><Label class="type-group-name" text="GUI"/>
                    <Panel class="type-cell" tooltip="FontAsset"><Image class="row-icon cat-gui" src="Editor/Icons/Types/FontAsset.svg"/><Label class="type-name" text="Font"/></Panel>
                    <Panel class="type-cell" tooltip="GuiDocumentAsset"><Image class="row-icon cat-gui" src="Editor/Icons/Types/GuiDocumentAsset.svg"/><Label class="type-name" text="Gui Document"/></Panel>
                    <Panel class="type-cell" tooltip="GuiStyleSheetAsset"><Image class="row-icon cat-gui" src="Editor/Icons/Types/GuiStyleSheetAsset.svg"/><Label class="type-name" text="Gui Style Sheet"/></Panel>
                    <Panel class="type-cell" tooltip="UIDocumentAsset"><Image class="row-icon cat-gui" src="Editor/Icons/Types/UIDocumentAsset.svg"/><Label class="type-name" text="UI Document"/></Panel>
                    <Panel class="type-cell" tooltip="UIThemeAsset"><Image class="row-icon cat-gui" src="Editor/Icons/Types/UIThemeAsset.svg"/><Label class="type-name" text="UI Theme"/></Panel>
                </Panel>
                <Panel class="type-group"><Label class="type-group-name" text="Input"/>
                    <Panel class="type-cell" tooltip="InputMapAsset"><Image class="row-icon cat-input" src="Editor/Icons/Types/InputMapAsset.svg"/><Label class="type-name" text="Input Map"/></Panel>
                </Panel>
                <Panel class="type-group"><Label class="type-group-name" text="Physics"/>
                    <Panel class="type-cell" tooltip="CollisionShapeAsset"><Image class="row-icon cat-physics" src="Editor/Icons/Types/CollisionShapeAsset.svg"/><Label class="type-name" text="Collision Shape"/></Panel>
                    <Panel class="type-cell" tooltip="PhysicalMaterialAsset"><Image class="row-icon cat-physics" src="Editor/Icons/Types/PhysicalMaterialAsset.svg"/><Label class="type-name" text="Physical Material"/></Panel>
                </Panel>
                <Panel class="type-group"><Label class="type-group-name" text="Navigation"/>
                    <Panel class="type-cell" tooltip="NavigationZoneAsset"><Image class="row-icon cat-navigation" src="Editor/Icons/Types/NavigationZoneAsset.svg"/><Label class="type-name" text="Navigation Zone"/></Panel>
                </Panel>
                <Panel class="type-group"><Label class="type-group-name" text="Terrain"/>
                    <Panel class="type-cell" tooltip="HeightfieldAsset"><Image class="row-icon cat-terrain" src="Editor/Icons/Types/HeightfieldAsset.svg"/><Label class="type-name" text="Heightfield"/></Panel>
                    <Panel class="type-cell" tooltip="TerrainAsset"><Image class="row-icon cat-terrain" src="Editor/Icons/Types/TerrainAsset.svg"/><Label class="type-name" text="Terrain"/></Panel>
                    <Panel class="type-cell" tooltip="SplatmapAsset"><Image class="row-icon cat-terrain" src="Editor/Icons/Types/SplatmapAsset.svg"/><Label class="type-name" text="Splatmap"/></Panel>
                    <Panel class="type-cell" tooltip="VegetationMaskAsset"><Image class="row-icon cat-terrain" src="Editor/Icons/Types/VegetationMaskAsset.svg"/><Label class="type-name" text="Vegetation Mask"/></Panel>
                </Panel>
            </Panel>
            <Label class="kit-subtitle" text="Components"/>
            <Panel class="type-groups">
                <Panel class="type-group"><Label class="type-group-name" text="Rendering"/>
                    <Panel class="type-cell" tooltip="MeshComponent"><Image class="row-icon cat-rendering" src="Editor/Icons/Types/MeshComponent.svg"/><Label class="type-name" text="Mesh"/></Panel>
                    <Panel class="type-cell" tooltip="InstancedMeshComponent"><Image class="row-icon cat-rendering" src="Editor/Icons/Types/InstancedMeshComponent.svg"/><Label class="type-name" text="Instanced Mesh"/></Panel>
                    <Panel class="type-cell" tooltip="InstanceMemberComponent"><Image class="row-icon cat-rendering" src="Editor/Icons/Types/InstanceMemberComponent.svg"/><Label class="type-name" text="Instance Member"/></Panel>
                    <Panel class="type-cell" tooltip="CameraComponent"><Image class="row-icon cat-rendering" src="Editor/Icons/Types/CameraComponent.svg"/><Label class="type-name" text="Camera"/></Panel>
                    <Panel class="type-cell" tooltip="LightComponent"><Image class="row-icon cat-rendering" src="Editor/Icons/Types/LightComponent.svg"/><Label class="type-name" text="Light"/></Panel>
                    <Panel class="type-cell" tooltip="SpriteComponent"><Image class="row-icon cat-rendering" src="Editor/Icons/Types/SpriteComponent.svg"/><Label class="type-name" text="Sprite"/></Panel>
                    <Panel class="type-cell" tooltip="DecalComponent"><Image class="row-icon cat-rendering" src="Editor/Icons/Types/DecalComponent.svg"/><Label class="type-name" text="Decal"/></Panel>
                    <Panel class="type-cell" tooltip="EnvironmentSettings"><Image class="row-icon cat-rendering" src="Editor/Icons/Types/EnvironmentSettings.svg"/><Label class="type-name" text="Environment Settings"/></Panel>
                    <Panel class="type-cell" tooltip="ReflectionProbeComponent"><Image class="row-icon cat-rendering" src="Editor/Icons/Types/ReflectionProbeComponent.svg"/><Label class="type-name" text="Reflection Probe"/></Panel>
                    <Panel class="type-cell" tooltip="PostProcessSettings"><Image class="row-icon cat-rendering" src="Editor/Icons/Types/PostProcessSettings.svg"/><Label class="type-name" text="Post Process Settings"/></Panel>
                </Panel>
                <Panel class="type-group"><Label class="type-group-name" text="Physics"/>
                    <Panel class="type-cell" tooltip="RigidBodyComponent"><Image class="row-icon cat-physics" src="Editor/Icons/Types/RigidBodyComponent.svg"/><Label class="type-name" text="Rigid Body"/></Panel>
                    <Panel class="type-cell" tooltip="ColliderComponent"><Image class="row-icon cat-physics" src="Editor/Icons/Types/ColliderComponent.svg"/><Label class="type-name" text="Collider"/></Panel>
                    <Panel class="type-cell" tooltip="CharacterComponent"><Image class="row-icon cat-physics" src="Editor/Icons/Types/CharacterComponent.svg"/><Label class="type-name" text="Character"/></Panel>
                    <Panel class="type-cell" tooltip="JointComponent"><Image class="row-icon cat-physics" src="Editor/Icons/Types/JointComponent.svg"/><Label class="type-name" text="Joint"/></Panel>
                </Panel>
                <Panel class="type-group"><Label class="type-group-name" text="Audio"/>
                    <Panel class="type-cell" tooltip="AudioSourceComponent"><Image class="row-icon cat-audio" src="Editor/Icons/Types/AudioSourceComponent.svg"/><Label class="type-name" text="Audio Source"/></Panel>
                    <Panel class="type-cell" tooltip="AudioListenerComponent"><Image class="row-icon cat-audio" src="Editor/Icons/Types/AudioListenerComponent.svg"/><Label class="type-name" text="Audio Listener"/></Panel>
                    <Panel class="type-cell" tooltip="AudioReverbZoneComponent"><Image class="row-icon cat-audio" src="Editor/Icons/Types/AudioReverbZoneComponent.svg"/><Label class="type-name" text="Audio Reverb Zone"/></Panel>
                </Panel>
                <Panel class="type-group"><Label class="type-group-name" text="Scripting"/>
                    <Panel class="type-cell" tooltip="ScriptComponent"><Image class="row-icon cat-scripting" src="Editor/Icons/Types/ScriptComponent.svg"/><Label class="type-name" text="Script"/></Panel>
                    <Panel class="type-cell" tooltip="SceneScriptSettings"><Image class="row-icon cat-scripting" src="Editor/Icons/Types/SceneScriptSettings.svg"/><Label class="type-name" text="Scene Script Settings"/></Panel>
                </Panel>
                <Panel class="type-group"><Label class="type-group-name" text="Animation"/>
                    <Panel class="type-cell" tooltip="SkeletalAnimationComponent"><Image class="row-icon cat-animation" src="Editor/Icons/Types/SkeletalAnimationComponent.svg"/><Label class="type-name" text="Skeletal Animation"/></Panel>
                    <Panel class="type-cell" tooltip="AnimationGraphComponent"><Image class="row-icon cat-animation" src="Editor/Icons/Types/AnimationGraphComponent.svg"/><Label class="type-name" text="Animation Graph"/></Panel>
                    <Panel class="type-cell" tooltip="TwoBoneIkComponent"><Image class="row-icon cat-animation" src="Editor/Icons/Types/TwoBoneIkComponent.svg"/><Label class="type-name" text="Two Bone Ik"/></Panel>
                    <Panel class="type-cell" tooltip="AimIkComponent"><Image class="row-icon cat-animation" src="Editor/Icons/Types/AimIkComponent.svg"/><Label class="type-name" text="Aim Ik"/></Panel>
                    <Panel class="type-cell" tooltip="FootIkComponent"><Image class="row-icon cat-animation" src="Editor/Icons/Types/FootIkComponent.svg"/><Label class="type-name" text="Foot Ik"/></Panel>
                    <Panel class="type-cell" tooltip="InstancedSkinningComponent"><Image class="row-icon cat-animation" src="Editor/Icons/Types/InstancedSkinningComponent.svg"/><Label class="type-name" text="Instanced Skinning"/></Panel>
                    <Panel class="type-cell" tooltip="PropertyAnimatorComponent"><Image class="row-icon cat-animation" src="Editor/Icons/Types/PropertyAnimatorComponent.svg"/><Label class="type-name" text="Property Animator"/></Panel>
                </Panel>
                <Panel class="type-group"><Label class="type-group-name" text="GUI"/>
                    <Panel class="type-cell" tooltip="GuiCanvasComponent"><Image class="row-icon cat-gui" src="Editor/Icons/Types/GuiCanvasComponent.svg"/><Label class="type-name" text="Gui Canvas"/></Panel>
                    <Panel class="type-cell" tooltip="GuiBillboardComponent"><Image class="row-icon cat-gui" src="Editor/Icons/Types/GuiBillboardComponent.svg"/><Label class="type-name" text="Gui Billboard"/></Panel>
                    <Panel class="type-cell" tooltip="GuiWorldPanelComponent"><Image class="row-icon cat-gui" src="Editor/Icons/Types/GuiWorldPanelComponent.svg"/><Label class="type-name" text="Gui World Panel"/></Panel>
                    <Panel class="type-cell" tooltip="UICanvasComponent"><Image class="row-icon cat-gui" src="Editor/Icons/Types/UICanvasComponent.svg"/><Label class="type-name" text="UI Canvas"/></Panel>
                    <Panel class="type-cell" tooltip="UIBillboardComponent"><Image class="row-icon cat-gui" src="Editor/Icons/Types/UIBillboardComponent.svg"/><Label class="type-name" text="UI Billboard"/></Panel>
                    <Panel class="type-cell" tooltip="UIWorldPanelComponent"><Image class="row-icon cat-gui" src="Editor/Icons/Types/UIWorldPanelComponent.svg"/><Label class="type-name" text="UI World Panel"/></Panel>
                </Panel>
                <Panel class="type-group"><Label class="type-group-name" text="Effects"/>
                    <Panel class="type-cell" tooltip="ParticleEffectComponent"><Image class="row-icon cat-effects" src="Editor/Icons/Types/ParticleEffectComponent.svg"/><Label class="type-name" text="Particle Effect"/></Panel>
                </Panel>
                <Panel class="type-group"><Label class="type-group-name" text="Navigation"/>
                    <Panel class="type-cell" tooltip="NavMeshZoneComponent"><Image class="row-icon cat-navigation" src="Editor/Icons/Types/NavMeshZoneComponent.svg"/><Label class="type-name" text="Nav Mesh Zone"/></Panel>
                    <Panel class="type-cell" tooltip="NavAgentComponent"><Image class="row-icon cat-navigation" src="Editor/Icons/Types/NavAgentComponent.svg"/><Label class="type-name" text="Nav Agent"/></Panel>
                </Panel>
                <Panel class="type-group"><Label class="type-group-name" text="Terrain"/>
                    <Panel class="type-cell" tooltip="TerrainComponent"><Image class="row-icon cat-terrain" src="Editor/Icons/Types/TerrainComponent.svg"/><Label class="type-name" text="Terrain"/></Panel>
                    <Panel class="type-cell" tooltip="TerrainVegetationComponent"><Image class="row-icon cat-terrain" src="Editor/Icons/Types/TerrainVegetationComponent.svg"/><Label class="type-name" text="Terrain Vegetation"/></Panel>
                </Panel>
                <Panel class="type-group"><Label class="type-group-name" text="Utility"/>
                    <Panel class="type-cell" tooltip="SplineComponent"><Image class="row-icon" src="Editor/Icons/Types/SplineComponent.svg"/><Label class="type-name" text="Spline"/></Panel>
                    <Panel class="type-cell" tooltip="PathFollowComponent"><Image class="row-icon" src="Editor/Icons/Types/PathFollowComponent.svg"/><Label class="type-name" text="Path Follow"/></Panel>
                </Panel>
                <Panel class="type-group"><Label class="type-group-name" text="Networking"/>
                    <Panel class="type-cell" tooltip="NetworkComponent"><Image class="row-icon cat-networking" src="Editor/Icons/Types/NetworkComponent.svg"/><Label class="type-name" text="Network"/></Panel>
                    <Panel class="type-cell" tooltip="NetworkedTransform"><Image class="row-icon cat-networking" src="Editor/Icons/Types/NetworkedTransform.svg"/><Label class="type-name" text="Networked Transform"/></Panel>
                </Panel>
            </Panel>

            <!-- ========== The inspector's pieces ========== -->
            <Label class="kit-title" text="The inspector's pieces"/>
            <Label class="kit-note" text="A component's header: its arrow, tinted icon, name, enable check and menu (copy, paste, reset, remove). A row changed from its default says so with a bar and a revert; a prefab override with the accent."/>
            <Panel class="kit-row">
                <Panel class="kit-cell kit-inspector">
                    <Panel class="kit-grid">
                        <Panel class="component-header">
                            <Image class="row-arrow" src="Editor/Icons/chevron-down.svg"/>
                            <Image class="row-icon cat-rendering" src="Editor/Icons/cube.svg"/>
                            <Label class="component-name" text="Mesh Renderer"/>
                            <CheckBox class="component-enabled" checked="true" tooltip="Enabled"/>
                            <Button class="icon-button" icon="Editor/Icons/more.svg" tooltip="Copy, paste, reset, remove"/>
                        </Panel>
                        <Panel class="prop-row"><Label class="prop-name" text="Mesh"/>
                            <Panel class="slot"><Panel class="slot-thumb"><Image class="slot-glyph cat-rendering" src="Editor/Icons/cube.svg"/></Panel><Label class="slot-name" text="Crate"/>
                                <Button class="slot-button" icon="Editor/Icons/target.svg" tooltip="Pick (or drop an asset here)"/><Button class="slot-button" icon="Editor/Icons/open.svg" tooltip="Open"/></Panel>
                        </Panel>
                        <Panel class="prop-row"><Label class="prop-name" text="Material"/>
                            <Panel class="slot empty"><Label class="slot-name" text="None"/><Button class="slot-button" icon="Editor/Icons/target.svg" tooltip="Pick"/></Panel>
                        </Panel>
                        <Panel class="prop-row changed"><Panel class="change-bar"/><Label class="prop-name" text="Cast Shadows"/>
                            <CheckBox checked="false"/><Spacer/><Button class="revert" icon="Editor/Icons/revert.svg" tooltip="Revert to default (on)"/>
                        </Panel>
                        <Panel class="prop-row overridden"><Panel class="change-bar"/><Label class="prop-name" text="Scale"/>
                            <Panel class="with-unit"><NumberField value="1.5" step="0.1"/></Panel><Button class="revert" icon="Editor/Icons/revert.svg" tooltip="Revert to the prefab's value (1)"/>
                        </Panel>
                        <Panel class="prop-row"><Label class="prop-name" text="Layer"/><TextField placeholder="Mixed" class="mixed"/></Panel>
                        <Panel class="prop-row read-only-row"><Label class="prop-name" text="Bounds"/><Label class="read-only-value mono" text="2.0 x 1.0 x 2.0 m"/><Image class="lock" src="Editor/Icons/lock.svg" tooltip="Computed from the mesh"/></Panel>
                        <Panel class="prop-row invalid-row"><Label class="prop-name" text="LOD Bias"/>
                            <Panel class="prop-stack"><NumberField class="invalid" value="-2" min="-10" max="10"/><Panel class="field-message danger"><Label text="At least 0"/></Panel></Panel>
                        </Panel>
                        <Panel class="component-header collapsed disabled-component">
                            <Image class="row-arrow" src="Editor/Icons/chevron-right.svg"/>
                            <Image class="row-icon cat-physics" src="Editor/Icons/physics.svg"/>
                            <Label class="component-name" text="Rigid Body"/>
                            <CheckBox class="component-enabled" tooltip="Enabled"/>
                            <Button class="icon-button" icon="Editor/Icons/more.svg"/>
                        </Panel>
                        <Panel class="component-header collapsed">
                            <Image class="row-arrow" src="Editor/Icons/chevron-right.svg"/>
                            <Image class="row-icon cat-scripting" src="Editor/Icons/script.svg"/>
                            <Label class="component-name" text="Player Controller"/>
                            <Label class="badge accent" text="Added"/>
                            <CheckBox class="component-enabled" checked="true"/>
                            <Button class="icon-button" icon="Editor/Icons/more.svg"/>
                        </Panel>
                        <Button class="add-component with-icon" icon="Editor/Icons/plus.svg" text="Add Component"/>
                    </Panel>
                    <Label class="kit-caption" text="headers: open, off and closed, added in this prefab instance; rows: slot, empty slot, changed, overridden, mixed, read-only, invalid"/>
                </Panel>
                <Panel class="kit-cell kit-inspector">
                    <Panel class="kit-grid">
                        <Panel class="prop-row"><Label class="prop-name" text="Target"/>
                            <Panel class="slot"><Image class="slot-glyph cat-physics" src="Editor/Icons/character.svg"/><Label class="slot-name" text="Player"/><Label class="slot-path" text="Level 1 / Player"/>
                                <Button class="slot-button" icon="Editor/Icons/target.svg" tooltip="Pick in the hierarchy or the viewport"/><Button class="slot-button" icon="Editor/Icons/close.svg" tooltip="Clear"/></Panel>
                        </Panel>
                        <Panel class="prop-row list-head"><Image class="row-arrow" src="Editor/Icons/chevron-down.svg"/><Label class="prop-name" text="Waypoints"/><Label class="list-count" text="3"/><Spacer/>
                            <Button class="slot-button" icon="Editor/Icons/plus.svg" tooltip="Add (Ctrl+Enter)"/></Panel>
                        <Panel class="list-item"><Image class="grip" src="Editor/Icons/grip.svg" tooltip="Drag to reorder"/><Label class="list-index" text="1"/><NumberField value="0"/><NumberField value="0"/><NumberField value="4"/><Button class="slot-button" icon="Editor/Icons/minus.svg" tooltip="Remove"/></Panel>
                        <Panel class="list-item kit-hover"><Image class="grip" src="Editor/Icons/grip.svg"/><Label class="list-index" text="2"/><NumberField value="6"/><NumberField value="0"/><NumberField value="4"/><Button class="slot-button" icon="Editor/Icons/minus.svg" tooltip="Remove"/></Panel>
                        <Panel class="list-item"><Image class="grip" src="Editor/Icons/grip.svg"/><Label class="list-index" text="3"/><NumberField value="6"/><NumberField value="0"/><NumberField value="-2"/><Button class="slot-button" icon="Editor/Icons/minus.svg" tooltip="Remove"/></Panel>
                        <Panel class="prop-row"><Label class="prop-name" text="Bone"/><ComboBox items="spine_01|spine_02|head|hand_l|hand_r" selected="2"/></Panel>
                        <Panel class="prop-row"><Label class="prop-name" text="Jump Key"/><Button class="key-capture" text="Space" tooltip="Press to rebind"/></Panel>
                        <Panel class="prop-row notice-row"><Image class="message-icon" src="Editor/Icons/warning.svg"/><Label class="notice-text" text="This camera renders to a texture no material uses."/></Panel>
                    </Panel>
                    <Label class="kit-caption" text="entity slot, list editor, bone choice, key capture, a notice row"/>
                </Panel>
            </Panel>

            <!-- ========== Page bars ========== -->
            <Label class="kit-title" text="Page bars"/>
            <Label class="kit-note" text="One page toolbar: save, undo and redo first, the page's own after. One transport for every preview, the simulate controls and the Game tab, its state named beside it."/>
            <Panel class="kit-row">
                <Panel class="kit-cell kit-wide">
                    <ToolBar class="page-toolbar">
                        <ToolButton icon="Editor/Icons/save.svg" tooltip="Save (Ctrl+S)"/>
                        <ToolButton icon="Editor/Icons/undo.svg" tooltip="Undo (Ctrl+Z)"/>
                        <ToolButton icon="Editor/Icons/redo.svg" tooltip="Redo (Ctrl+Shift+Z)" enabled="false"/>
                        <Separator/>
                        <ToolButton icon="Editor/Icons/restart.svg" tooltip="Restart"/>
                        <ToolButton icon="Editor/Icons/play.svg" toggle="true" checked="true" tooltip="Play (F5)"/>
                        <ToolButton icon="Editor/Icons/pause.svg" tooltip="Pause (F6)"/>
                        <ToolButton icon="Editor/Icons/stop.svg" tooltip="Stop (Shift+F5)"/>
                        <Label class="transport-state playing" text="Playing"/>
                        <Spacer/>
                        <Label class="badge warning" text="Waiting for cook"/>
                        <Label class="transport-state paused" text="Paused"/>
                        <Label class="transport-state faulted" text="Script error"/>
                    </ToolBar>
                    <Label class="kit-caption" text="page toolbar and transport, with each state's label"/>
                </Panel>
            </Panel>

            <!-- ========== Problems ========== -->
            <Label class="kit-title" text="Problems"/>
            <Label class="kit-note" text="One place a page lists its errors and warnings, each a link to its source; not a status line, not the first error only."/>
            <Panel class="kit-row">
                <Panel class="kit-cell kit-wide">
                    <Panel class="problems">
                        <Panel class="problems-head"><Label class="problems-title" text="Problems"/><Label class="badge danger" text="1"/><Label class="badge warning" text="2"/></Panel>
                        <Panel class="problem-row"><Image class="message-icon danger" src="Editor/Icons/error.svg"/><Label class="problem-text" text="'speed' is not a member of Player"/><Label class="problem-source" text="Player.as:42"/></Panel>
                        <Panel class="problem-row kit-hover"><Image class="message-icon warning" src="Editor/Icons/warning.svg"/><Label class="problem-text" text="Brick_Albedo has no mipmaps"/><Label class="problem-source" text="Textures/Brick_Albedo"/></Panel>
                        <Panel class="problem-row"><Image class="message-icon warning" src="Editor/Icons/warning.svg"/><Label class="problem-text" text="Two lights share the shadow atlas past its size"/><Label class="problem-source" text="Level 1 / Lamp"/></Panel>
                    </Panel>
                </Panel>
            </Panel>

            <!-- ========== Empty, busy and error ========== -->
            <Label class="kit-title" text="Empty, busy and failed"/>
            <Label class="kit-note" text="Every list, tree, viewport, picker and page: never a blank area. Each says what is so and offers the next step."/>
            <Panel class="kit-row">
                <Panel class="kit-cell state-box">
                    <Image class="state-icon" src="Editor/Icons/folder-open.svg"/>
                    <Label class="state-title" text="No assets here yet"/>
                    <Label class="state-text" text="Drop files here or import them."/>
                    <Button class="with-icon" icon="Editor/Icons/plus.svg" text="Import..."/>
                </Panel>
                <Panel class="kit-cell state-box">
                    <Image class="state-icon" src="Editor/Icons/search.svg"/>
                    <Label class="state-title" text="Nothing matches crate4"/>
                    <Button class="ghost" text="Clear the search"/>
                </Panel>
                <Panel class="kit-cell state-box">
                    <ProgressBar class="state-progress" indeterminate="true"/>
                    <Label class="state-title" text="Cooking 12 of 40"/>
                    <Label class="state-text" text="Brick_Albedo"/>
                    <Button text="Cancel"/>
                </Panel>
                <Panel class="kit-cell state-box failed">
                    <Image class="state-icon" src="Editor/Icons/error.svg"/>
                    <Label class="state-title" text="The preview failed to load"/>
                    <Label class="state-text" text="Crate.glb has no mesh named Crate_LOD0."/>
                    <Panel class="kit-inline"><Button text="Retry"/><Button class="ghost" text="Show in Console"/></Panel>
                </Panel>
            </Panel>

            <!-- ========== Feedback ========== -->
            <Label class="kit-title" text="Feedback"/>
            <Label class="kit-note" text="Toasts stack at the bottom right of the dock, above the status bar, capped and grouped; an error stays until dismissed. A job is one pattern: progress, cancel, result."/>
            <Panel class="kit-row">
                <Panel class="kit-cell">
                    <Panel class="kit-toasts">
                        <Panel class="kit-toast success"><Image class="message-icon" src="Editor/Icons/check.svg"/><Panel class="toast-text"><Label class="toast-title" text="Exported Sky Hopper"/><Label class="toast-message" text="Linux, 48 MB, in 12 s"/></Panel><Button class="ghost toast-action" text="Open Folder"/><Button class="slot-button" icon="Editor/Icons/close.svg"/></Panel>
                        <Panel class="kit-toast warning"><Image class="message-icon" src="Editor/Icons/warning.svg"/><Panel class="toast-text"><Label class="toast-title" text="3 textures have no mipmaps"/><Label class="toast-message" text="They were generated for this cook."/></Panel><Label class="toast-count" text="x3"/><Button class="slot-button" icon="Editor/Icons/close.svg"/></Panel>
                        <Panel class="kit-toast error"><Image class="message-icon" src="Editor/Icons/error.svg"/><Panel class="toast-text"><Label class="toast-title" text="Player.as failed to compile"/><Label class="toast-message" text="'speed' is not a member of Player"/></Panel><Button class="ghost toast-action" text="Show in Console"/><Button class="slot-button" icon="Editor/Icons/close.svg"/></Panel>
                    </Panel>
                    <Label class="kit-caption" text="toasts: success with an action, warning grouped, error"/>
                </Panel>
                <Panel class="kit-cell">
                    <Panel class="kit-tooltip"><Label class="tooltip-title" text="Frame Selection"/><Label class="key" text="F"/></Panel>
                    <Panel class="kit-tooltip"><Label class="tooltip-title" text="Export"/><Label class="tooltip-reason" text="Choose a target platform first"/></Panel>
                    <Label class="kit-caption" text="tooltips: the action and its key; a disabled one's reason"/>
                    <Panel class="job">
                        <Label class="job-name" text="Cooking"/>
                        <ProgressBar class="job-progress" value="0.3"/>
                        <Label class="job-count" text="12 of 40"/>
                        <Button class="slot-button" icon="Editor/Icons/close.svg" tooltip="Cancel the cook"/>
                    </Panel>
                    <Label class="kit-caption" text="a job in the status bar"/>
                </Panel>
            </Panel>

            <!-- ========== Dialogs ========== -->
            <Label class="kit-title" text="Dialogs"/>
            <Label class="kit-note" text="A title, the body, and a footer with one primary verb (Enter) beside Cancel (Escape). Validation is live beside its field, and a disabled primary says why. A confirmation names its verb and lists what it touches."/>
            <Panel class="kit-row">
                <Panel class="kit-cell">
                    <Panel class="dialog">
                        <Panel class="dialog-head"><Label class="dialog-title" text="New Scene"/><Button class="slot-button" icon="Editor/Icons/close.svg" tooltip="Close (Esc)"/></Panel>
                        <Panel class="dialog-body form">
                            <Label class="form-label" text="Name"/>
                            <Panel class="form-field"><TextField class="invalid" text="Level 1"/><Panel class="field-message danger"><Label text="Level 1 already exists in Levels"/></Panel></Panel>
                            <Label class="form-label" text="Group"/>
                            <Panel class="form-field"><Panel class="slot"><Image class="slot-glyph" src="Editor/Icons/folder.svg"/><Label class="slot-name" text="Levels"/><Button class="slot-button" icon="Editor/Icons/target.svg"/></Panel></Panel>
                            <Label class="form-label" text="Start from"/>
                            <Panel class="form-field">
                                <Panel class="segmented"><Button class="segment" name="kit-start" toggle="true" checked="true" text="Empty"/><Button class="segment" name="kit-start" toggle="true" text="Sky and Sun"/><Button class="segment" name="kit-start" toggle="true" text="Template"/></Panel>
                                <Label class="form-help" text="Sky and Sun adds a sky, a sun and an ambient probe."/>
                            </Panel>
                        </Panel>
                        <Panel class="dialog-buttons"><Spacer/><Button text="Cancel"/><Button class="primary" text="Create" enabled="false" tooltip="Choose another name"/></Panel>
                    </Panel>
                    <Label class="kit-caption" text="a form: label column, help, live validation"/>
                </Panel>
                <Panel class="kit-cell">
                    <Panel class="dialog">
                        <Panel class="dialog-head"><Label class="dialog-title" text="Delete 3 assets?"/></Panel>
                        <Panel class="dialog-body">
                            <Label class="dialog-text" text="These go to the project's trash. 2 scenes still use Wood."/>
                            <Panel class="confirm-list">
                                <Panel class="asset-row"><Image class="row-icon cat-rendering" src="Editor/Icons/material.svg"/><Label class="row-name" text="Wood"/><Spacer/><Label class="badge warning" text="Used by 2"/></Panel>
                                <Panel class="asset-row"><Image class="row-icon cat-rendering" src="Editor/Icons/texture.svg"/><Label class="row-name" text="Wood_Albedo"/></Panel>
                                <Panel class="asset-row"><Image class="row-icon cat-rendering" src="Editor/Icons/texture.svg"/><Label class="row-name" text="Wood_Normal"/></Panel>
                            </Panel>
                        </Panel>
                        <Panel class="dialog-buttons"><Spacer/><Button text="Cancel"/><Button class="danger-primary" text="Delete"/></Panel>
                    </Panel>
                    <Label class="kit-caption" text="confirm: a verb, what it touches"/>
                </Panel>
                <Panel class="kit-cell">
                    <Panel class="dialog picker">
                        <Panel class="picker-search">
                            <Panel class="search"><Image class="search-icon" src="Editor/Icons/search.svg"/><TextField class="search-field" text="wo"/></Panel>
                        </Panel>
                        <Label class="picker-group" text="Recent"/>
                        <Panel class="asset-row kit-selected"><Image class="row-icon cat-rendering" src="Editor/Icons/material.svg"/><Label class="row-name" text="Wood"/><Spacer/><Image class="row-trail" src="Editor/Icons/check.svg" tooltip="The current value"/></Panel>
                        <Label class="picker-group" text="Materials"/>
                        <Panel class="asset-row"><Image class="row-icon cat-rendering" src="Editor/Icons/material.svg"/><Label class="row-name" text="Wood_Dark"/><Spacer/><Image class="badge-icon star" src="Editor/Icons/star.svg"/></Panel>
                        <Panel class="asset-row kit-hover"><Image class="row-icon cat-rendering" src="Editor/Icons/material.svg"/><Label class="row-name" text="Wool"/></Panel>
                        <Panel class="picker-foot"><Label class="picker-hint" text="Enter picks, Esc keeps Wood"/><Spacer/><Button class="ghost" text="None"/></Panel>
                    </Panel>
                    <Label class="kit-caption" text="picker: search, recent first, the current value marked"/>
                </Panel>
                <Panel class="kit-cell">
                    <Panel class="dialog picker">
                        <Panel class="picker-search">
                            <Panel class="search"><Image class="search-icon" src="Editor/Icons/search.svg"/><TextField class="search-field" text="glass"/></Panel>
                        </Panel>
                        <Panel class="state-box picker-empty">
                            <Label class="state-title" text="No material named glass"/>
                            <Button class="with-icon" icon="Editor/Icons/plus.svg" text="Create Material glass"/>
                        </Panel>
                    </Panel>
                    <Label class="kit-caption" text="picker, empty: offers to create"/>
                </Panel>
            </Panel>

        </Panel>
    </ScrollView>
</Panel>
