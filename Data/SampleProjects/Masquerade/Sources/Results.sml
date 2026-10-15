<screen mode="modal" transition="fade" default-focus="again-btn">

  <!-- The round's end (Masquerade.as): who won, every hunter's points, and what next. -->
  <Flex direction="vertical" justify="center" align="center">
    <Panel padding="26" style="background: rounded-rect(#120814E8, radius=16);">
      <Flex direction="vertical" align="center" spacing="8" width="520">
        <Label id="res-title" text="" font-size="40" style="text-color: #F4D080;"/>
        <Label id="res-you" text="" font-size="22" style="text-color: #F4E6C8;"/>
        <Spacer spacer-height="4"/>
        <Label id="res-0" text="" font-size="18" style="text-color: #E0D0B0;"/>
        <Label id="res-1" text="" font-size="18" style="text-color: #E0D0B0;"/>
        <Label id="res-2" text="" font-size="18" style="text-color: #E0D0B0;"/>
        <Label id="res-3" text="" font-size="18" style="text-color: #E0D0B0;"/>
        <Label id="res-best" text="" font-size="15" style="text-color: #B8A080;"/>
        <Spacer spacer-height="8"/>
        <Button id="again-btn" text="Another round" width="320" height="42" font-size="21" style="background: state-list(normal=rounded-rect(#22102A, radius=10, border=#7A5A28, border-width=2), hover=rounded-rect(#30183A, radius=10, border=#E0B860, border-width=3), pressed=rounded-rect(#3E2048, radius=10, border=#F4D080, border-width=4), focused=rounded-rect(#22102A, radius=10, border=#F4D080, border-width=4), disabled=rounded-rect(#140A18, radius=10, border=#3A2A20, border-width=2)); text-color: #F4E6C8;"/>
        <Button id="title-btn" text="Leave to the title" width="320" height="42" font-size="21" style="background: state-list(normal=rounded-rect(#22102A, radius=10, border=#7A5A28, border-width=2), hover=rounded-rect(#30183A, radius=10, border=#E0B860, border-width=3), pressed=rounded-rect(#3E2048, radius=10, border=#F4D080, border-width=4), focused=rounded-rect(#22102A, radius=10, border=#F4D080, border-width=4), disabled=rounded-rect(#140A18, radius=10, border=#3A2A20, border-width=2)); text-color: #F4E6C8;"/>
      </Flex>
    </Panel>
  </Flex>

</screen>
