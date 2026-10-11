<screen mode="modal" transition="fade" default-focus="level-0">

  <!-- The title (Lamplight.as fills it from the save): a button per level with the best taken on
       it, or what opens it; Quit ends the game. -->
  <Flex direction="vertical" justify="center" align="center" padding="32">
    <Panel padding="28" style="background: rounded-rect(#0C0907E8, radius=16);">
      <Flex direction="vertical" align="center" spacing="5" width="460">
        <Label text="Lamplight" font-size="60" style="text-color: #F0D8A8;"/>
        <Label text="One night, one manor, keep to the dark" font-size="20" style="text-color: #B8A080;"/>
        <Spacer spacer-height="8"/>
        <Button id="level-0" text="The Gardens" width="420" height="38" font-size="21" style="background: state-list(normal=rounded-rect(#1E1610, radius=10, border=#6A5030, border-width=2), hover=rounded-rect(#2C2016, radius=10, border=#D8B070, border-width=3), pressed=rounded-rect(#3A2A1A, radius=10, border=#F0C070, border-width=4), focused=rounded-rect(#1E1610, radius=10, border=#F0C070, border-width=4), disabled=rounded-rect(#100C08, radius=10, border=#3A2C1E, border-width=2)); text-color: #F0E0C0;"/>
        <Label id="level-0-best" text="" font-size="15" style="text-color: #C8B490;"/>
        <Button id="level-1" text="The Stable Yard" width="420" height="38" font-size="21" style="background: state-list(normal=rounded-rect(#1E1610, radius=10, border=#6A5030, border-width=2), hover=rounded-rect(#2C2016, radius=10, border=#D8B070, border-width=3), pressed=rounded-rect(#3A2A1A, radius=10, border=#F0C070, border-width=4), focused=rounded-rect(#1E1610, radius=10, border=#F0C070, border-width=4), disabled=rounded-rect(#100C08, radius=10, border=#3A2C1E, border-width=2)); text-color: #F0E0C0;"/>
        <Label id="level-1-best" text="" font-size="15" style="text-color: #C8B490;"/>
        <Button id="level-2" text="The Ground Floor" width="420" height="38" font-size="21" style="background: state-list(normal=rounded-rect(#1E1610, radius=10, border=#6A5030, border-width=2), hover=rounded-rect(#2C2016, radius=10, border=#D8B070, border-width=3), pressed=rounded-rect(#3A2A1A, radius=10, border=#F0C070, border-width=4), focused=rounded-rect(#1E1610, radius=10, border=#F0C070, border-width=4), disabled=rounded-rect(#100C08, radius=10, border=#3A2C1E, border-width=2)); text-color: #F0E0C0;"/>
        <Label id="level-2-best" text="" font-size="15" style="text-color: #C8B490;"/>
        <Button id="level-3" text="The Cellars" width="420" height="38" font-size="21" style="background: state-list(normal=rounded-rect(#1E1610, radius=10, border=#6A5030, border-width=2), hover=rounded-rect(#2C2016, radius=10, border=#D8B070, border-width=3), pressed=rounded-rect(#3A2A1A, radius=10, border=#F0C070, border-width=4), focused=rounded-rect(#1E1610, radius=10, border=#F0C070, border-width=4), disabled=rounded-rect(#100C08, radius=10, border=#3A2C1E, border-width=2)); text-color: #F0E0C0;"/>
        <Label id="level-3-best" text="" font-size="15" style="text-color: #C8B490;"/>
        <Button id="level-4" text="The Upper Floor" width="420" height="38" font-size="21" style="background: state-list(normal=rounded-rect(#1E1610, radius=10, border=#6A5030, border-width=2), hover=rounded-rect(#2C2016, radius=10, border=#D8B070, border-width=3), pressed=rounded-rect(#3A2A1A, radius=10, border=#F0C070, border-width=4), focused=rounded-rect(#1E1610, radius=10, border=#F0C070, border-width=4), disabled=rounded-rect(#100C08, radius=10, border=#3A2C1E, border-width=2)); text-color: #F0E0C0;"/>
        <Label id="level-4-best" text="" font-size="15" style="text-color: #C8B490;"/>
        <Spacer spacer-height="10"/>
        <Button id="quit-btn" text="Quit" width="200" height="40" font-size="20" style="background: state-list(normal=rounded-rect(#1E1610, radius=10, border=#6A5030, border-width=2), hover=rounded-rect(#2C2016, radius=10, border=#D8B070, border-width=3), pressed=rounded-rect(#3A2A1A, radius=10, border=#F0C070, border-width=4), focused=rounded-rect(#1E1610, radius=10, border=#F0C070, border-width=4), disabled=rounded-rect(#100C08, radius=10, border=#3A2C1E, border-width=2)); text-color: #F0E0C0;"/>
        <Spacer spacer-height="6"/>
        <Label text="WASD or stick to move, C sneak, Shift run, F use, G throw, Q / E turn the view" font-size="15" style="text-color: #8C7A60;"/>
      </Flex>
    </Panel>
  </Flex>

</screen>
