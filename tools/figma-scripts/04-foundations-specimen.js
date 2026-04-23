(async () => {
  // prijavko — foundations specimen: one frame showing color swatches + type scale.
  // Purpose: visual validation of tokens before building screens.

  await figma.loadFontAsync({ family: "Manrope", style: "Regular" });
  await figma.loadFontAsync({ family: "Manrope", style: "Medium" });

  // Remove any prior specimen so this script is idempotent.
  const existingRoot = figma.currentPage.findOne(
    (n) => n.type === "FRAME" && n.name === "Foundations · prijavko"
  );
  if (existingRoot) existingRoot.remove();

  // Fetch token references.
  const collections = await figma.variables.getLocalVariableCollectionsAsync();
  const colorCol = collections.find((c) => c.name === "color");
  const allVars = await figma.variables.getLocalVariablesAsync();
  const colorVars = allVars
    .filter((v) => v.variableCollectionId === colorCol.id)
    .sort((a, b) =>
      colorCol.variableIds.indexOf(a.id) - colorCol.variableIds.indexOf(b.id)
    );

  const textStyles = await figma.getLocalTextStylesAsync();
  const typeOrder = [
    "display/Large",
    "display/Medium",
    "headline/Large",
    "headline/Medium",
    "headline/Small",
    "title/Large",
    "title/Medium",
    "body/Large",
    "body/Medium",
    "body/Small",
    "label/Large",
    "label/Medium",
  ];

  // Surface color (Dark) for the canvas backdrop.
  const surfaceDark = { r: 0x0e / 255, g: 0x15 / 255, b: 0x15 / 255 };
  const onSurfaceDark = { r: 0xe1 / 255, g: 0xe3 / 255, b: 0xe2 / 255 };

  // ── Root frame ───────────────────────────────────────────────────────────
  const root = figma.createFrame();
  root.name = "Foundations · prijavko";
  root.layoutMode = "VERTICAL";
  root.primaryAxisSizingMode = "AUTO";
  root.counterAxisSizingMode = "AUTO";
  root.paddingLeft = root.paddingRight = 48;
  root.paddingTop = root.paddingBottom = 48;
  root.itemSpacing = 48;
  root.fills = [{ type: "SOLID", color: surfaceDark }];
  root.x = 0;
  root.y = 0;

  // Title.
  const title = figma.createText();
  title.fontName = { family: "Manrope", style: "Medium" };
  title.characters = "Foundations · prijavko";
  title.fontSize = 28;
  title.fills = [{ type: "SOLID", color: onSurfaceDark }];
  root.appendChild(title);

  // ── Colors section ───────────────────────────────────────────────────────
  const colorsSection = figma.createFrame();
  colorsSection.name = "Colors (Dark mode)";
  colorsSection.layoutMode = "VERTICAL";
  colorsSection.primaryAxisSizingMode = "AUTO";
  colorsSection.counterAxisSizingMode = "AUTO";
  colorsSection.itemSpacing = 16;
  colorsSection.fills = [];
  root.appendChild(colorsSection);

  const colorsHeader = figma.createText();
  colorsHeader.fontName = { family: "Manrope", style: "Medium" };
  colorsHeader.characters = "Color tokens (13)";
  colorsHeader.fontSize = 18;
  colorsHeader.fills = [{ type: "SOLID", color: onSurfaceDark }];
  colorsSection.appendChild(colorsHeader);

  const swatchGrid = figma.createFrame();
  swatchGrid.layoutMode = "HORIZONTAL";
  swatchGrid.layoutWrap = "WRAP";
  swatchGrid.primaryAxisSizingMode = "FIXED";
  swatchGrid.counterAxisSizingMode = "AUTO";
  swatchGrid.resize(720, 100);
  swatchGrid.itemSpacing = 16;
  swatchGrid.counterAxisSpacing = 16;
  swatchGrid.fills = [];
  colorsSection.appendChild(swatchGrid);

  for (const v of colorVars) {
    const tile = figma.createFrame();
    tile.name = v.name;
    tile.layoutMode = "VERTICAL";
    tile.primaryAxisSizingMode = "AUTO";
    tile.counterAxisSizingMode = "FIXED";
    tile.resize(168, 120);
    tile.itemSpacing = 8;
    tile.fills = [];

    const swatch = figma.createFrame();
    swatch.name = "swatch";
    swatch.resize(168, 72);
    swatch.cornerRadius = 12;
    // Bind the swatch fill to the variable — this is the validation.
    const basePaint = { type: "SOLID", color: { r: 0.5, g: 0.5, b: 0.5 } };
    const bound = figma.variables.setBoundVariableForPaint(basePaint, "color", v);
    swatch.fills = [bound];
    swatch.strokes = [{ type: "SOLID", color: { r: 1, g: 1, b: 1 }, opacity: 0.08 }];
    swatch.strokeWeight = 1;
    tile.appendChild(swatch);

    const label = figma.createText();
    label.fontName = { family: "Manrope", style: "Regular" };
    label.characters = v.name;
    label.fontSize = 12;
    label.fills = [{ type: "SOLID", color: onSurfaceDark }];
    tile.appendChild(label);

    swatchGrid.appendChild(tile);
  }

  // ── Type section ─────────────────────────────────────────────────────────
  const typeSection = figma.createFrame();
  typeSection.name = "Type scale (Manrope)";
  typeSection.layoutMode = "VERTICAL";
  typeSection.primaryAxisSizingMode = "AUTO";
  typeSection.counterAxisSizingMode = "AUTO";
  typeSection.itemSpacing = 20;
  typeSection.fills = [];
  root.appendChild(typeSection);

  const typeHeader = figma.createText();
  typeHeader.fontName = { family: "Manrope", style: "Medium" };
  typeHeader.characters = "Type scale (12)";
  typeHeader.fontSize = 18;
  typeHeader.fills = [{ type: "SOLID", color: onSurfaceDark }];
  typeSection.appendChild(typeHeader);

  // Load every style's font once so we can set characters.
  const styleByName = new Map(textStyles.map((s) => [s.name, s]));
  const neededFonts = new Set();
  for (const name of typeOrder) {
    const s = styleByName.get(name);
    if (s) neededFonts.add(JSON.stringify(s.fontName));
  }
  for (const key of neededFonts) {
    await figma.loadFontAsync(JSON.parse(key));
  }

  for (const name of typeOrder) {
    const s = styleByName.get(name);
    if (!s) continue;
    const row = figma.createFrame();
    row.name = name;
    row.layoutMode = "HORIZONTAL";
    row.primaryAxisSizingMode = "FIXED";
    row.counterAxisSizingMode = "AUTO";
    row.counterAxisAlignItems = "CENTER";
    row.resize(900, 40);
    row.itemSpacing = 24;
    row.fills = [];

    const tag = figma.createText();
    tag.fontName = { family: "Manrope", style: "Regular" };
    tag.characters = name;
    tag.fontSize = 12;
    tag.fills = [{ type: "SOLID", color: onSurfaceDark, opacity: 0.7 }];
    tag.resize(160, tag.height);
    row.appendChild(tag);

    const sample = figma.createText();
    sample.fontName = s.fontName;
    sample.characters = "Prijavko · Čović Šestić Žiga 0123";
    await sample.setTextStyleIdAsync(s.id);
    sample.fills = [{ type: "SOLID", color: onSurfaceDark }];
    row.appendChild(sample);

    typeSection.appendChild(row);
  }

  return {
    ok: true,
    rootId: root.id,
    rootName: root.name,
    colorSwatches: colorVars.length,
    typeRows: typeOrder.length,
  };
})()
