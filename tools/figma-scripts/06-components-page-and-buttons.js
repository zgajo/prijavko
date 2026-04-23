(async () => {
  // prijavko — create Components page, then Button main components (Filled/Outlined/Text).
  // Tokens: primary, onPrimary, outline, radius-button, button-min-height, label/Large.

  // ── Ensure Components page exists and is active ──────────────────────────
  let page = figma.root.children.find((p) => p.name === "Components");
  if (!page) {
    page = figma.createPage();
    page.name = "Components";
  }
  await figma.setCurrentPageAsync(page);

  // Clear any prior button set so this script is idempotent.
  for (const node of page.findAll((n) => n.name.startsWith("Button/"))) {
    node.remove();
  }

  // ── Fetch variables ──────────────────────────────────────────────────────
  const allVars = await figma.variables.getLocalVariablesAsync();
  const v = Object.fromEntries(allVars.map((x) => [x.name, x]));

  // ── Load fonts ───────────────────────────────────────────────────────────
  await figma.loadFontAsync({ family: "Manrope", style: "SemiBold" });

  // ── Fetch text style ─────────────────────────────────────────────────────
  const textStyles = await figma.getLocalTextStylesAsync();
  const labelLarge = textStyles.find((s) => s.name === "label/Large");

  // Helper: solid paint bound to a color variable.
  const boundFill = (variable) =>
    figma.variables.setBoundVariableForPaint(
      { type: "SOLID", color: { r: 0.5, g: 0.5, b: 0.5 } },
      "color",
      variable
    );

  // Helper: bind radius + min-height variables on a frame.
  const bindFrameDims = (frame) => {
    frame.setBoundVariable("topLeftRadius", v["radius-button"]);
    frame.setBoundVariable("topRightRadius", v["radius-button"]);
    frame.setBoundVariable("bottomLeftRadius", v["radius-button"]);
    frame.setBoundVariable("bottomRightRadius", v["radius-button"]);
    frame.setBoundVariable("minHeight", v["button-min-height"]);
  };

  // Helper: create button with auto-layout, text centered.
  const makeButton = async ({ name, label, fillVar, textColorVar, strokeVar }) => {
    const btn = figma.createComponent();
    btn.name = name;
    btn.layoutMode = "HORIZONTAL";
    btn.primaryAxisSizingMode = "AUTO";
    btn.counterAxisSizingMode = "AUTO";
    btn.primaryAxisAlignItems = "CENTER";
    btn.counterAxisAlignItems = "CENTER";
    btn.paddingLeft = btn.paddingRight = 24;
    btn.paddingTop = btn.paddingBottom = 16;
    btn.itemSpacing = 8;

    if (fillVar) btn.fills = [boundFill(fillVar)];
    else btn.fills = [];

    if (strokeVar) {
      btn.strokes = [boundFill(strokeVar)];
      btn.strokeWeight = 1;
      btn.strokeAlign = "INSIDE";
    }

    bindFrameDims(btn);

    const text = figma.createText();
    await text.setTextStyleIdAsync(labelLarge.id);
    text.characters = label;
    text.fills = [boundFill(textColorVar)];
    btn.appendChild(text);

    return btn;
  };

  const filled = await makeButton({
    name: "Button/Filled",
    label: "Pošalji sve",
    fillVar: v["primary"],
    textColorVar: v["onPrimary"],
    strokeVar: null,
  });
  const outlined = await makeButton({
    name: "Button/Outlined",
    label: "Ručni unos",
    fillVar: null,
    textColorVar: v["primary"],
    strokeVar: v["outline"],
  });
  const textBtn = await makeButton({
    name: "Button/Text",
    label: "Uredi",
    fillVar: null,
    textColorVar: v["primary"],
    strokeVar: null,
  });

  // Position horizontally with 32dp gaps at y=0.
  let x = 0;
  for (const c of [filled, outlined, textBtn]) {
    c.x = x;
    c.y = 0;
    x += c.width + 32;
  }

  return {
    ok: true,
    page: page.name,
    components: [
      { name: filled.name, id: filled.id, w: filled.width, h: filled.height },
      { name: outlined.name, id: outlined.id, w: outlined.width, h: outlined.height },
      { name: textBtn.name, id: textBtn.id, w: textBtn.width, h: textBtn.height },
    ],
  };
})()
