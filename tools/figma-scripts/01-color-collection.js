(async () => {
  // prijavko — `color` collection, single mode (Dark — UX spec's default design target).
  // Starter plan: 1 mode/collection. Light palette added later (in Flutter or on plan upgrade).
  // Idempotent: reuses collection if it exists, updates existing vars by name.

  const hexToRgb = (hex) => {
    const n = hex.replace("#", "");
    return {
      r: parseInt(n.slice(0, 2), 16) / 255,
      g: parseInt(n.slice(2, 4), 16) / 255,
      b: parseInt(n.slice(4, 6), 16) / 255,
    };
  };

  const COLOR_SCOPES = ["FRAME_FILL", "SHAPE_FILL", "TEXT_FILL", "STROKE_COLOR"];

  // Dark-mode values from UX spec §Color System.
  const tokens = [
    ["primary",              "#7FCDCF"],
    ["onPrimary",            "#003738"],
    ["primaryContainer",     "#004F52"],
    ["onPrimaryContainer",   "#B4ECEE"],
    ["surface",              "#0E1515"],
    ["surfaceContainer",     "#1A2323"],
    ["onSurface",            "#E1E3E2"],
    ["onSurfaceVariant",     "#BFC9C8"],
    ["outline",              "#899392"],
    ["success",              "#81C784"],
    ["warning",              "#FFB74D"],
    ["error",                "#F2B8B5"],
    ["closureAccent",        "#D4B858"],
  ];

  const existing = await figma.variables.getLocalVariableCollectionsAsync();
  let collection = existing.find((c) => c.name === "color");
  const wasCreated = !collection;
  if (!collection) {
    collection = figma.variables.createVariableCollection("color");
  }
  const modeId = collection.modes[0].modeId;
  if (collection.modes[0].name !== "Dark") {
    collection.renameMode(modeId, "Dark");
  }

  const existingVars = await figma.variables.getLocalVariablesAsync();
  const byName = new Map(
    existingVars
      .filter((v) => v.variableCollectionId === collection.id)
      .map((v) => [v.name, v])
  );

  const results = [];
  for (const [name, hex] of tokens) {
    let v = byName.get(name);
    const reused = !!v;
    if (!v) v = figma.variables.createVariable(name, collection, "COLOR");
    v.scopes = COLOR_SCOPES;
    v.setValueForMode(modeId, hexToRgb(hex));
    results.push({ name, id: v.id, reused });
  }

  return {
    ok: true,
    collectionCreated: wasCreated,
    collectionId: collection.id,
    mode: collection.modes[0].name,
    variableCount: results.length,
    variables: results.map((r) => r.name),
  };
})()
