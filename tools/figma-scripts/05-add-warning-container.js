(async () => {
  // JIT: CredentialBanner needs container tones. Add now.
  const hexToRgb = (hex) => {
    const n = hex.replace("#", "");
    return {
      r: parseInt(n.slice(0, 2), 16) / 255,
      g: parseInt(n.slice(2, 4), 16) / 255,
      b: parseInt(n.slice(4, 6), 16) / 255,
    };
  };

  const collections = await figma.variables.getLocalVariableCollectionsAsync();
  const color = collections.find((c) => c.name === "color");
  const modeId = color.modes[0].modeId;

  // Dark-mode container tones derived via M3 tonal conventions.
  const extras = [
    ["warningContainer", "#4D3200"],
    ["onWarningContainer", "#FFDDB3"],
  ];

  const allVars = await figma.variables.getLocalVariablesAsync();
  const byName = new Map(
    allVars.filter((v) => v.variableCollectionId === color.id).map((v) => [v.name, v])
  );

  const results = [];
  for (const [name, hex] of extras) {
    let v = byName.get(name);
    if (!v) v = figma.variables.createVariable(name, color, "COLOR");
    v.scopes = ["FRAME_FILL", "SHAPE_FILL", "TEXT_FILL", "STROKE_COLOR"];
    v.setValueForMode(modeId, hexToRgb(hex));
    results.push(v.name);
  }
  return { ok: true, added: results };
})()
