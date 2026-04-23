(async () => {
  // prijavko — CredentialBanner. 2 variants: warning (default) / info.
  // UX spec §Custom Components #4. Warning amber bg, never red.

  let page = figma.root.children.find((p) => p.name === "Components");
  await figma.setCurrentPageAsync(page);

  for (const node of page.findAll(
    (n) => n.name === "CredentialBanner" || n.name.startsWith("variant=warning") || n.name.startsWith("variant=info")
  )) {
    node.remove();
  }

  const allVars = await figma.variables.getLocalVariablesAsync();
  const v = Object.fromEntries(allVars.map((x) => [x.name, x]));

  await figma.loadFontAsync({ family: "Manrope", style: "SemiBold" });
  await figma.loadFontAsync({ family: "Manrope", style: "Bold" });

  const styles = await figma.getLocalTextStylesAsync();
  const bodyMedium = styles.find((s) => s.name === "body/Medium");
  const labelLarge = styles.find((s) => s.name === "label/Large");

  const boundFill = (variable) =>
    figma.variables.setBoundVariableForPaint(
      { type: "SOLID", color: { r: 0.5, g: 0.5, b: 0.5 } },
      "color",
      variable
    );

  // variant -> bg, fg, iconChar
  const variants = [
    { name: "warning", bgVar: v["warningContainer"],  fgVar: v["onWarningContainer"],  glyph: "⚠", actionLabel: "Ponovi prijavu" },
    { name: "info",    bgVar: v["primaryContainer"],  fgVar: v["onPrimaryContainer"],  glyph: "ℹ", actionLabel: "Pogledaj" },
  ];

  const components = [];
  for (const vnt of variants) {
    const banner = figma.createComponent();
    banner.name = `variant=${vnt.name}`;
    banner.layoutMode = "HORIZONTAL";
    banner.primaryAxisSizingMode = "FIXED";
    banner.counterAxisSizingMode = "AUTO";
    banner.primaryAxisAlignItems = "CENTER";
    banner.counterAxisAlignItems = "CENTER";
    banner.resize(360, 100);
    banner.itemSpacing = 12;
    for (const pad of ["paddingLeft", "paddingRight"]) banner.setBoundVariable(pad, v["space-16"]);
    for (const pad of ["paddingTop", "paddingBottom"]) banner.setBoundVariable(pad, v["space-12"]);
    for (const corner of ["topLeftRadius", "topRightRadius", "bottomLeftRadius", "bottomRightRadius"]) {
      banner.setBoundVariable(corner, v["radius-button"]);
    }
    banner.fills = [boundFill(vnt.bgVar)];

    // Leading icon.
    const icon = figma.createText();
    icon.fontName = { family: "Manrope", style: "Bold" };
    icon.characters = vnt.glyph;
    icon.fontSize = 20;
    icon.fills = [boundFill(vnt.fgVar)];
    banner.appendChild(icon);

    // Message text — fills remaining space.
    const msg = figma.createText();
    await msg.setTextStyleIdAsync(bodyMedium.id);
    msg.characters =
      vnt.name === "warning"
        ? "Sesija na eVisitoru je istekla."
        : "Poslano 3 od 4. Dodirni Pošalji sve.";
    msg.fills = [boundFill(vnt.fgVar)];
    banner.appendChild(msg);
    msg.layoutSizingHorizontal = "FILL";

    // Trailing action — simple text button area, min 48dp tap target.
    const action = figma.createFrame();
    action.name = "action";
    action.layoutMode = "HORIZONTAL";
    action.primaryAxisSizingMode = "AUTO";
    action.counterAxisSizingMode = "AUTO";
    action.primaryAxisAlignItems = "CENTER";
    action.counterAxisAlignItems = "CENTER";
    action.paddingLeft = action.paddingRight = 12;
    action.paddingTop = action.paddingBottom = 8;
    action.minHeight = 48;
    action.fills = [];
    const actionText = figma.createText();
    await actionText.setTextStyleIdAsync(labelLarge.id);
    actionText.characters = vnt.actionLabel;
    actionText.fills = [boundFill(vnt.fgVar)];
    action.appendChild(actionText);
    banner.appendChild(action);

    components.push(banner);
  }

  const set = figma.combineAsVariants(components, page);
  set.name = "CredentialBanner";
  // Position variants vertically with 16dp gap.
  const pad = 16;
  const gap = 16;
  let cy = pad;
  for (const c of components) {
    c.x = pad;
    c.y = cy;
    cy += c.height + gap;
  }
  set.resizeWithoutConstraints(components[0].width + 2 * pad, cy - gap + pad);

  // Position below glyph set (glyph set y=280, h=208 → start at y=520).
  set.x = 0;
  set.y = 520;

  return { ok: true, setId: set.id, name: set.name, variants: components.map((c) => c.name) };
})()
