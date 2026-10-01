<screen mode="modal" transition="fade" default-focus="victory-title-btn">

  <Panel style="background: rgba(8, 14, 30, 0.6);">
  <Flex direction="vertical" justify="center" align="center" padding="32">

    <Panel padding="40"
           style="background: rounded-rect(rgb(30, 26, 14), radius=14, border-width=2, border=rgb(255, 226, 120));">
      <Flex direction="vertical" align="center" spacing="8">
        <Label id="victory-title" font-family="Lilita One" text="You Win!" font-size="56" style="text-color: rgb(255, 226, 120);"/>
        <Label id="victory-summary" text="" font-size="18" class="label"/>
        <Spacer spacer-height="24"/>
        <Flex direction="vertical" spacing="8" width="260">
          <Button id="victory-title-btn" text="Back to Title" height="46" class="primary"/>
        </Flex>
      </Flex>
    </Panel>

  </Flex>
  </Panel>

</screen>
