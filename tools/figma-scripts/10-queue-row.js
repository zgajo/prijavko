(async () => {
  // prijavko — QueueRow. 4 state variants: queued / sending / sent / failed.
  // UX spec §Custom Components #2. Composes GuestStatusGlyph.

  let page = figma.root.children.find((p) => p.name === "Components");
  await figma.setCurrentPageAsync(page);

  // Find the GuestStatusGlyph component set and pick the "small" size main component.
  const glyphSet = page.findOne(
    (n) => n.type === "COMPONENT_SET" && n.name === "GuestStatusGlyph"
  );
  if (!glyphSet) throw new Error("GuestStatusGlyph not found");

  // Cache the 4 small-size glyph main components we need.
  const glyphByState = {};
  for (const child of glyphSet.children) {
    const parts = Object.fromEntries(
      child.name.split(",").map((s) => s.trim().split("=").map((x) => x.trim()))
    );
    if (parts.size === "small") glyphByState[parts.state] = child;
  }

  for (const node of page.findAll((n) => n.name === "QueueRow")) node.remove();

  const allVars = await figma.variables.getLocalVariablesAsync();
  const v = Object.fromEntries(allVars.map((x) => [x.name, x]));

  await figma.loadFontAsync({ family: "Manrope", style: "SemiBold" });
  await figma.loadFontAsync({ family: "Manrope", style: "Bold" });
  await figma.loadFontAsync({ family: "Manrope", style: "Medium" });

  const styles = await figma.getLocalTextStylesAsync();
  const titleLarge = styles.find((s) => s.name === "title/Large");
  const bodySmall = styles.find((s) => s.name === "body/Small");
  const labelLarge = styles.find((s) => s.name === "label/Large");

  const boundFill = (variable) =>
    figma.variables.setBoundVariableForPaint(
      { type: "SOLID", color: { r: 0.5, g: 0.5, b: 0.5 } },
      "color",
      variable
    );

  const stateConfigs = [
    { state: "queued",  title: "HR2184…", meta: "Dodirom za uređivanje", titleVar: v["onSurface"],     trailing: "edit",   errorBorder: false },
    { state: "sending", title: "HR2184…", meta: "Šaljem na eVisitor…",   titleVar: v["onSurface"],     trailing: "edit",   errorBorder: false },
    { state: "sent",    title: "HR2184…", meta: "Prijavljeno",           titleVar: v["onSurface"],     trailing: "edit",   errorBorder: false },
    { state: "failed",  title: "HR2184…", meta: "Neuspjeh — uredi i pošalji", titleVar: v["error"], trailing: "uredi",  errorBorder: true  },
  ];

  const rows = [];
  for (const cfg of stateConfigs) {
    const row = figma.createComponent();
    row.name = `state=${cfg.state}`;
    row.layoutMode = "HORIZONTAL";
    row.primaryAxisSizingMode = "FIXED";
    row.counterAxisSizingMode = "AUTO";
    row.primaryAxisAlignItems = "CENTER";
    row.counterAxisAlignItems = "CENTER";
    row.resize(360, 64);
    row.itemSpacing = 12;
    for (const pad of ["paddingLeft", "paddingRight", "paddingTop", "paddingBottom"]) {
      row.setBoundVariable(pad, v["space-12"]);
    }
    for (const corner of ["topLeftRadius", "topRightRadius", "bottomLeftRadius", "bottomRightRadius"]) {
      row.setBoundVariable(corner, v["radius-button"]);
    }
    row.fills = [boundFill(v["surfaceContainer"])];
    if (cfg.errorBorder) {
      row.strokes = [boundFill(v["error"])];
      row.strokeWeight = 1;
      row.strokeAlign = "INSIDE";
    }

    // Leading: GuestStatusGlyph small instance.
    const glyphMain = glyphByState[cfg.state];
    if (glyphMain) {
      const inst = glyphMain.createInstance();
      row.appendChild(inst);
    }

    // Center column: title + meta.
    const center = figma.createFrame();
    center.layoutMode = "VERTICAL";
    center.primaryAxisSizingMode = "AUTO";
    center.counterAxisSizingMode = "AUTO";
    center.itemSpacing = 2;
    center.fills = [];
    row.appendChild(center);
    center.layoutSizingHorizontal = "FILL";

    const title = figma.createText();
    await title.setTextStyleIdAsync(titleLarge.id);
    title.characters = cfg.title;
    title.fills = [boundFill(cfg.titleVar)];
    center.appendChild(title);
    title.layoutSizingHorizontal = "FILL";

    const meta = figma.createText();
    await meta.setTextStyleIdAsync(bodySmall.id);
    meta.characters = cfg.meta;
    meta.fills = [boundFill(v["onSurfaceVariant"])];
    center.appendChild(meta);
    meta.layoutSizingHorizontal = "FILL";

    // Trailing action.
    const trailing = figma.createFrame();
    trailing.name = "trailing";
    trailing.layoutMode = "HORIZONTAL";
    trailing.primaryAxisSizingMode = "AUTO";
    trailing.counterAxisSizingMode = "AUTO";
    trailing.primaryAxisAlignItems = "CENTER";
    trailing.counterAxisAlignItems = "CENTER";
    trailing.paddingLeft = trailing.paddingRight = 8;
    trailing.paddingTop = trailing.paddingBottom = 8;
    trailing.minHeight = 48;
    trailing.minWidth = 48;
    trailing.fills = [];
    const trailingText = figma.createText();
    if (cfg.trailing === "edit") {
      trailingText.fontName = { family: "Manrope", style: "Bold" };
      trailingText.characters = "✎";
      trailingText.fontSize = 18;
      trailingText.fills = [boundFill(v["onSurfaceVariant"])];
    } else {
      await trailingText.setTextStyleIdAsync(labelLarge.id);
      trailingText.characters = "Uredi";
      trailingText.fills = [boundFill(v["primary"])];
    }
    trailing.appendChild(trailingText);
    row.appendChild(trailing);

    rows.push(row);
  }

  const set = figma.combineAsVariants(rows, page);
  set.name = "QueueRow";

  // Stack variants vertically with gap, resize set to fit.
  const pad = 16;
  const gap = 16;
  let cy = pad;
  for (const r of rows) {
    r.x = pad;
    r.y = cy;
    cy += r.height + gap;
  }
  set.resizeWithoutConstraints(rows[0].width + 2 * pad, cy - gap + pad);

  // Position below CredentialBanner (y=520, h ~ 270 → start at y=820).
  set.x = 0;
  set.y = 820;

  return {
    ok: true,
    setId: set.id,
    variantCount: rows.length,
    variants: rows.map((r) => r.name),
  };
})()
