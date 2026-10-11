<screen mode="modal" transition="fade" default-focus="next-btn">

  <!-- A level's results (Lamplight.as fills them): how long, what was taken, how often seen and
       caught, the ghost medal for never being seen, and the best on this level. -->
  <Flex direction="vertical" justify="center" align="center">
    <Panel padding="26" style="background: rounded-rect(#0C0907E8, radius=16);">
      <Flex direction="vertical" align="stretch" spacing="8" width="420">
        <Label id="res-title" text="Away clean" font-size="40" style="text-color: #F0D8A8;"/>
        <Label id="res-time" text="" font-size="22" style="text-color: #E8D8B8;"/>
        <Label id="res-loot" text="" font-size="22" style="text-color: #E8D8B8;"/>
        <Label id="res-seen" text="" font-size="22" style="text-color: #E8D8B8;"/>
        <Label id="res-medal" text="" font-size="26" style="text-color: #FFE07A;"/>
        <Label id="res-best" text="" font-size="16" style="text-color: #B8A080;"/>
        <Spacer spacer-height="8"/>
        <Button id="next-btn" text="On to the next" height="44" font-size="22" style="background: state-list(normal=rounded-rect(#1E1610, radius=10, border=#6A5030, border-width=2), hover=rounded-rect(#2C2016, radius=10, border=#D8B070, border-width=3), pressed=rounded-rect(#3A2A1A, radius=10, border=#F0C070, border-width=4), focused=rounded-rect(#1E1610, radius=10, border=#F0C070, border-width=4), disabled=rounded-rect(#100C08, radius=10, border=#3A2C1E, border-width=2)); text-color: #F0E0C0;"/>
        <Button id="again-btn" text="This level again" height="44" font-size="22" style="background: state-list(normal=rounded-rect(#1E1610, radius=10, border=#6A5030, border-width=2), hover=rounded-rect(#2C2016, radius=10, border=#D8B070, border-width=3), pressed=rounded-rect(#3A2A1A, radius=10, border=#F0C070, border-width=4), focused=rounded-rect(#1E1610, radius=10, border=#F0C070, border-width=4), disabled=rounded-rect(#100C08, radius=10, border=#3A2C1E, border-width=2)); text-color: #F0E0C0;"/>
        <Button id="title-btn" text="To the title" height="44" font-size="22" style="background: state-list(normal=rounded-rect(#1E1610, radius=10, border=#6A5030, border-width=2), hover=rounded-rect(#2C2016, radius=10, border=#D8B070, border-width=3), pressed=rounded-rect(#3A2A1A, radius=10, border=#F0C070, border-width=4), focused=rounded-rect(#1E1610, radius=10, border=#F0C070, border-width=4), disabled=rounded-rect(#100C08, radius=10, border=#3A2C1E, border-width=2)); text-color: #F0E0C0;"/>
      </Flex>
    </Panel>
  </Flex>

</screen>
