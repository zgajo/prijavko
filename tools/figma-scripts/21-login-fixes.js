(async () => {
  // 1. TextField field row: primaryAxisAlignItems CENTER → MIN (text left-aligned)
  // 2. Login screen: prepend 🔒 icon to "Podaci se čuvaju šifrirano..." hint

  for (const f of ["Regular", "Medium", "SemiBold"]) {
    await figma.loadFontAsync({ family: "Manrope", style: f });
  }

  const allVars = await figma.variables.getLocalVariablesAsync();
  const v = Object.fromEntries(allVars.map((x) => [x.name, x]));
  const styles = await figma.getLocalTextStylesAsync();
  const S = Object.fromEntries(styles.map((s) => [s.name, s]));
  const boundFill = (variable) =>
    figma.variables.setBoundVariableForPaint(
      { type: "SOLID", color: { r: 0.5, g: 0.5, b: 0.5 } },
      "color",
      variable
    );

  const results = [];

  // ── 1. TextField alignment ───────────────────────────────────────────────
  {
    const pageC = figma.root.children.find((p) => p.name === "Components");
    await figma.setCurrentPageAsync(pageC);
    const tfSet = pageC.findOne(
      (n) => n.type === "COMPONENT_SET" && n.name === "TextField"
    );
    if (tfSet) {
      for (const variant of tfSet.children) {
        for (const child of variant.children) {
          if (child.type === "FRAME" && child.layoutMode === "HORIZONTAL") {
            child.primaryAxisAlignItems = "MIN";
          }
        }
      }
      results.push("TextField field rows left-aligned");
    }
  }

  // ── 2. Login hint: add lock icon ─────────────────────────────────────────
  {
    const pageS = figma.root.children.find((p) => p.name === "Screens");
    await figma.setCurrentPageAsync(pageS);
    const login = pageS.findOne((n) => n.name === "02 Login");
    if (login) {
      const hintNode = login.findOne(
        (n) =>
          n.type === "TEXT" &&
          n.characters ===
            "Podaci se čuvaju šifrirano u Android Keystore-u."
      );
      if (hintNode) {
        const parent = hintNode.parent;
        const hintIdx = parent.children.indexOf(hintNode);

        // Build a row: [🔒 icon][hint text], horizontal auto-layout.
        const row = figma.createFrame();
        row.name = "hint-row";
        row.layoutMode = "HORIZONTAL";
        row.primaryAxisSizingMode = "FIXED";
        row.counterAxisSizingMode = "AUTO";
        row.counterAxisAlignItems = "MIN";
        row.itemSpacing = 8;
        row.resize(parent.width - (parent.paddingLeft || 0) - (parent.paddingRight || 0), 1);
        row.fills = [];

        const icon = figma.createText();
        icon.fontName = { family: "Manrope", style: "Regular" };
        icon.characters = "🔒";
        icon.fontSize = 14;
        icon.fills = [boundFill(v["onSurfaceVariant"])];
        row.appendChild(icon);

        // Move the existing hint text into the row (preserves its style binding).
        row.appendChild(hintNode);
        hintNode.layoutSizingHorizontal = "FILL";

        // Insert the row at the hint's old position.
        parent.insertChild(hintIdx, row);
        row.layoutSizingHorizontal = "FILL";

        results.push("Login hint: 🔒 icon prepended");
      }
    }
  }

  return { ok: true, results };
})()
