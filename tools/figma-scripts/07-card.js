(async () => {
  // prijavko — Card primitive. Generic container.
  // Tokens: surfaceContainer, radius-card, space-24, title/Medium, body/Medium, onSurface, onSurfaceVariant.

  let page = figma.root.children.find((p) => p.name === "Components");
  await figma.setCurrentPageAsync(page);

  for (const node of page.findAll((n) => n.name === "Card")) node.remove();

  const allVars = await figma.variables.getLocalVariablesAsync();
  const v = Object.fromEntries(allVars.map((x) => [x.name, x]));

  await figma.loadFontAsync({ family: "Manrope", style: "SemiBold" });
  await figma.loadFontAsync({ family: "Manrope", style: "Regular" });

  const styles = await figma.getLocalTextStylesAsync();
  const titleMedium = styles.find((s) => s.name === "title/Medium");
  const bodyMedium = styles.find((s) => s.name === "body/Medium");

  const boundFill = (variable) =>
    figma.variables.setBoundVariableForPaint(
      { type: "SOLID", color: { r: 0.5, g: 0.5, b: 0.5 } },
      "color",
      variable
    );

  const card = figma.createComponent();
  card.name = "Card";
  card.layoutMode = "VERTICAL";
  card.primaryAxisSizingMode = "AUTO";
  card.counterAxisSizingMode = "FIXED";
  card.resize(320, 100);
  card.itemSpacing = 8;
  card.fills = [boundFill(v["surfaceContainer"])];

  // Bind radius + padding.
  for (const corner of ["topLeftRadius", "topRightRadius", "bottomLeftRadius", "bottomRightRadius"]) {
    card.setBoundVariable(corner, v["radius-card"]);
  }
  for (const pad of ["paddingLeft", "paddingRight", "paddingTop", "paddingBottom"]) {
    card.setBoundVariable(pad, v["space-24"]);
  }

  // Title
  const title = figma.createText();
  await title.setTextStyleIdAsync(titleMedium.id);
  title.characters = "Naslov kartice";
  title.fills = [boundFill(v["onSurface"])];
  card.appendChild(title);
  title.layoutSizingHorizontal = "FILL";

  // Body
  const body = figma.createText();
  await body.setTextStyleIdAsync(bodyMedium.id);
  body.characters = "Sadržaj kartice. Zamijeni sa stvarnim sadržajem.";
  body.fills = [boundFill(v["onSurfaceVariant"])];
  card.appendChild(body);
  body.layoutSizingHorizontal = "FILL";

  // Place below buttons at y=120.
  card.x = 0;
  card.y = 120;

  return { ok: true, id: card.id, name: card.name, w: card.width, h: card.height };
})()
