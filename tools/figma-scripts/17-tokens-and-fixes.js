(async () => {
  // Three things:
  // 1. Fix OBRIŠI text vertical centering in TypedConfirmationDialog input field
  // 2. Add surfaceContainerHigh + outlineVariant color tokens (from HTML mockup)
  // 3. Update QueueRow background to surfaceContainerHigh (UX spec §2 says so)

  const hexToRgb = (hex) => {
    const n = hex.replace("#", "");
    return {
      r: parseInt(n.slice(0, 2), 16) / 255,
      g: parseInt(n.slice(2, 4), 16) / 255,
      b: parseInt(n.slice(4, 6), 16) / 255,
    };
  };

  const results = [];

  // ── 1. OBRIŠI centering ─────────────────────────────────────────────────
  {
    const pageC = figma.root.children.find((p) => p.name === "Components");
    await figma.setCurrentPageAsync(pageC);
    const dialog = pageC.findOne((n) => n.type === "COMPONENT" && n.name === "TypedConfirmationDialog");
    if (dialog) {
      // The input is an auto-layout FRAME whose only TEXT child has characters "OBRIŠI".
      const inputFrame = dialog.children.find(
        (c) => c.type === "FRAME" && c.layoutMode === "HORIZONTAL" &&
               c.children.some((k) => k.type === "TEXT" && k.characters === "OBRIŠI")
      );
      if (inputFrame) {
        inputFrame.counterAxisAlignItems = "CENTER";
        results.push("OBRIŠI vertically centered");
      }
    }
  }

  // ── 2. Add surfaceContainerHigh + outlineVariant tokens ─────────────────
  {
    const collections = await figma.variables.getLocalVariableCollectionsAsync();
    const color = collections.find((c) => c.name === "color");
    const modeId = color.modes[0].modeId;
    const allVars = await figma.variables.getLocalVariablesAsync();
    const byName = new Map(
      allVars.filter((v) => v.variableCollectionId === color.id).map((v) => [v.name, v])
    );
    const extras = [
      ["surfaceContainerHigh", "#242D2D"],
      ["outlineVariant", "#3F4948"],
    ];
    for (const [name, hex] of extras) {
      let v = byName.get(name);
      if (!v) v = figma.variables.createVariable(name, color, "COLOR");
      v.scopes = ["FRAME_FILL", "SHAPE_FILL", "TEXT_FILL", "STROKE_COLOR"];
      v.setValueForMode(modeId, hexToRgb(hex));
    }
    results.push("Tokens added: surfaceContainerHigh, outlineVariant");
  }

  // ── 3. Update QueueRow bg → surfaceContainerHigh ────────────────────────
  {
    const pageC = figma.root.children.find((p) => p.name === "Components");
    await figma.setCurrentPageAsync(pageC);
    const allVars = await figma.variables.getLocalVariablesAsync();
    const v = Object.fromEntries(allVars.map((x) => [x.name, x]));

    const qrSet = pageC.findOne(
      (n) => n.type === "COMPONENT_SET" && n.name === "QueueRow"
    );
    if (qrSet) {
      const boundFill = (variable) =>
        figma.variables.setBoundVariableForPaint(
          { type: "SOLID", color: { r: 0.5, g: 0.5, b: 0.5 } },
          "color",
          variable
        );
      for (const variant of qrSet.children) {
        variant.fills = [boundFill(v["surfaceContainerHigh"])];
      }
      results.push("QueueRow bg → surfaceContainerHigh");
    }
  }

  return { ok: true, results };
})()
