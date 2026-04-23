(async () => {
  // prijavko — spacing, radii, sizing collections (all single-mode).
  // Idempotent: reuses collections and variables by name.

  const upsertCollection = async (name) => {
    const existing = await figma.variables.getLocalVariableCollectionsAsync();
    const found = existing.find((c) => c.name === name);
    if (found) return { collection: found, created: false };
    const c = figma.variables.createVariableCollection(name);
    return { collection: c, created: true };
  };

  const upsertFloatVar = async (collection, modeId, name, value, scopes) => {
    const all = await figma.variables.getLocalVariablesAsync();
    let v = all.find(
      (x) => x.variableCollectionId === collection.id && x.name === name
    );
    const reused = !!v;
    if (!v) v = figma.variables.createVariable(name, collection, "FLOAT");
    v.scopes = scopes;
    v.setValueForMode(modeId, value);
    return { name, id: v.id, reused };
  };

  const summary = {};

  // ── spacing ──────────────────────────────────────────────────────────────
  {
    const { collection, created } = await upsertCollection("spacing");
    const modeId = collection.modes[0].modeId;
    // GAP scope covers auto-layout gap AND padding in Figma's variable picker.
    const scopes = ["GAP"];
    const grid = [4, 8, 12, 16, 24, 32, 48, 64];
    const results = [];
    for (const n of grid) {
      results.push(await upsertFloatVar(collection, modeId, `space-${n}`, n, scopes));
    }
    summary.spacing = {
      collectionId: collection.id,
      created,
      count: results.length,
      variables: results.map((r) => r.name),
    };
  }

  // ── radii ────────────────────────────────────────────────────────────────
  {
    const { collection, created } = await upsertCollection("radii");
    const modeId = collection.modes[0].modeId;
    const scopes = ["CORNER_RADIUS"];
    // Values from .claude/rules/design-system.md §Design Tokens.
    const radii = [
      ["radius-button", 12],
      ["radius-card", 16],
      ["radius-sheet", 24],
    ];
    const results = [];
    for (const [name, val] of radii) {
      results.push(await upsertFloatVar(collection, modeId, name, val, scopes));
    }
    summary.radii = {
      collectionId: collection.id,
      created,
      count: results.length,
      variables: results.map((r) => r.name),
    };
  }

  // ── sizing ───────────────────────────────────────────────────────────────
  {
    const { collection, created } = await upsertCollection("sizing");
    const modeId = collection.modes[0].modeId;
    const scopes = ["WIDTH_HEIGHT"];
    // UX spec §tokens: button min-height 56dp for one-handed night-shift use.
    const sizes = [
      ["button-min-height", 56],
    ];
    const results = [];
    for (const [name, val] of sizes) {
      results.push(await upsertFloatVar(collection, modeId, name, val, scopes));
    }
    summary.sizing = {
      collectionId: collection.id,
      created,
      count: results.length,
      variables: results.map((r) => r.name),
    };
  }

  return { ok: true, ...summary };
})()
