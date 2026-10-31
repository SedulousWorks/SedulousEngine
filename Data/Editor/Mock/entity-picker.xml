<!--
  The entity picker (an entity slot's pick) shown as the scene hierarchy shows the scene: the same
  tree, the scene its top row, each entity by its type's icon in its category's colour, opened and
  closed by its arrow, the current entity lit. The search keeps each match with what holds it.
  Enter picks, Esc keeps the value, None clears it. The mock's scene is the scene page's.
-->
<Panel class="dialog picker entity-picker">
    <Panel class="picker-search">
        <Panel class="search"><Image class="search-icon" src="Editor/Icons/search.svg"/><TextField class="search-field" placeholder="Search the scene"/></Panel>
    </Panel>
    <TreeView id="entity-picker-tree" class="entity-picker-tree tree">
        <TreeItem text="Level 1" icon="Editor/Icons/Types/SceneDocument.svg" expanded="true">
            <TreeItem text="Sun" icon="Editor/Icons/Types/LightComponent.svg" icon-class="cat-rendering"/>
            <TreeItem text="Sky" icon="Editor/Icons/Types/EnvironmentSettings.svg" icon-class="cat-rendering"/>
            <TreeItem text="Player" icon="Editor/Icons/Types/CharacterComponent.svg" icon-class="cat-physics" expanded="true">
                <TreeItem text="Camera" icon="Editor/Icons/Types/CameraComponent.svg" icon-class="cat-rendering"/>
                <TreeItem text="Model" icon="Editor/Icons/Types/MeshComponent.svg" icon-class="cat-rendering"/>
                <TreeItem text="Footsteps" icon="Editor/Icons/Types/AudioSourceComponent.svg" icon-class="cat-audio"/>
            </TreeItem>
            <TreeItem text="Ground" icon="Editor/Icons/Types/ColliderComponent.svg" icon-class="cat-physics"/>
            <TreeItem text="Crates" icon="Editor/Icons/Types/PrefabDocument.svg">
                <TreeItem text="Crate" icon="Editor/Icons/Types/MeshComponent.svg" icon-class="cat-rendering"/>
                <TreeItem text="Crate 2" icon="Editor/Icons/Types/MeshComponent.svg" icon-class="cat-rendering"/>
                <TreeItem text="Crate 3" icon="Editor/Icons/Types/MeshComponent.svg" icon-class="cat-rendering"/>
            </TreeItem>
            <TreeItem text="Barrel" icon="Editor/Icons/Types/RigidBodyComponent.svg" icon-class="cat-physics"/>
            <TreeItem text="Lamp" icon="Editor/Icons/Types/LightComponent.svg" icon-class="cat-rendering"/>
            <TreeItem text="Trigger" icon="Editor/Icons/Types/ScriptComponent.svg" icon-class="cat-scripting"/>
        </TreeItem>
    </TreeView>
    <Panel class="picker-foot"><Label class="picker-hint" text="Enter picks, Esc keeps Camera"/><Spacer/><Button class="ghost" text="None"/></Panel>
</Panel>
