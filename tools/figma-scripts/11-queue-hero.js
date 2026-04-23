(async () => {
  // prijavko — QueueHero. UX spec §Custom Components #3.
  // 4 state variants: empty_recent, empty_fresh, non_empty, auth_dead.

  let page = figma.root.children.find((p) => p.name === "Components");
  await figma.setCurrentPageAsync(page);

  for (const n of page.findAll((nd) => nd.name === "QueueHero")) n.remove();

  const allVars = await figma.variables.getLocalVariablesAsync();
  const v = Object.fromEntries(allVars.map((x) => [x.name, x]));

  await figma.loadFontAsync({ family: "Manrope", style: "ExtraBold" });
  await figma.loadFontAsync({ family: "Manrope", style: "Bold" });
  await figma.loadFontAsync({ family: "Manrope", style: "Medium" });
  await figma.loadFontAsync({ family: "Manrope", style: "Regular" });

  const styles = await figma.getLocalTextStylesAsync();
  const displayMedium = styles.find((s) => s.name === "display/Medium");
  const labelMedium = styles.find((s) => s.name === "label/Medium");
  const bodySmall = styles.find((s) => s.name === "body/Small");

  const boundFill = (variable) =>
    figma.variables.setBoundVariableForPaint(
      { type: "SOLID", color: { r: 0.5, g: 0.5, b: 0.5 } },
      "color",
      variable
    );

  // [variantName, count, caption, meta, bgVar, fgVar, metaVar]
  const states = [
    ["state=empty_recent",  "0", "U REDU",  "Zadnja prijava: prije 12 min",   v["primaryContainer"], v["onPrimaryContainer"], v["onPrimaryContainer"]],
    ["state=empty_fresh",   "0", "U REDU",  "Skeniraj za prvog gosta",        v["primaryContainer"], v["onPrimaryContainer"], v["onPrimaryContainer"]],
    ["state=non_empty",     "3", "U REDU",  "Dodirni Pošalji sve",            v["primaryContainer"], v["onPrimaryContainer"], v["onPrimaryContainer"]],
    ["state=auth_dead",     "3", "U REDU",  "Slanje blokirano",               v["warningContainer"], v["onWarningContainer"], v["onWarningContainer"]],
  ];

  const variants = [];
  for (const [name, count, caption, meta, bgVar, fgVar, metaVar] of states) {
    const hero = figma.createComponent();
    hero.name = name;
    hero.layoutMode = "HORIZONTAL";
    hero.primaryAxisSizingMode = "FIXED";
    hero.counterAxisSizingMode = "AUTO";
    hero.primaryAxisAlignItems = "CENTER";
    hero.counterAxisAlignItems = "CENTER";
    hero.resize(360, 120);
    hero.itemSpacing = 16;
    for (const pad of ["paddingLeft", "paddingRight"]) hero.setBoundVariable(pad, v["space-24"]);
    for (const pad of ["paddingTop", "paddingBottom"]) hero.setBoundVariable(pad, v["space-16"]);
    // 14dp radius per spec — no token for it, so literal.
    hero.cornerRadius = 14;
    hero.fills = [boundFill(bgVar)];

    // Left: label + count stacked.
    const left = figma.createFrame();
    left.layoutMode = "VERTICAL";
    left.primaryAxisSizingMode = "AUTO";
    left.counterAxisSizingMode = "AUTO";
    left.itemSpacing = 4;
    left.fills = [];
    hero.appendChild(left);

    const lab = figma.createText();
    await lab.setTextStyleIdAsync(labelMedium.id);
    lab.characters = caption;
    lab.fills = [boundFill(fgVar)];
    lab.opacity = 0.8;
    left.appendChild(lab);

    const cnt = figma.createText();
    await cnt.setTextStyleIdAsync(displayMedium.id);
    cnt.fontName = { family: "Manrope", style: "ExtraBold" };
    cnt.characters = count;
    cnt.fills = [boundFill(fgVar)];
    left.appendChild(cnt);

    // Right: meta (2 lines allowed).
    const rightText = figma.createText();
    await rightText.setTextStyleIdAsync(bodySmall.id);
    rightText.characters = meta;
    rightText.fills = [boundFill(metaVar)];
    rightText.opacity = 0.85;
    rightText.textAlignHorizontal = "RIGHT";
    hero.appendChild(rightText);
    rightText.layoutSizingHorizontal = "FILL";

    variants.push(hero);
  }

  const set = figma.combineAsVariants(variants, page);
  set.name = "QueueHero";

  // Stack variants vertically inside the set.
  const pad = 16, gap = 16;
  let cy = pad;
  for (const c of variants) {
    c.x = pad;
    c.y = cy;
    cy += c.height + gap;
  }
  set.resizeWithoutConstraints(variants[0].width + 2 * pad, cy - gap + pad);

  set.x = 0;
  set.y = 1200;

  return { ok: true, setId: set.id, variants: variants.map((c) => c.name) };
})()
