(async () => {
  // Add top chrome to CaptureConfirmation: close × (top-left) + success counter
  // chip "✓ 3 u redu" (top-right). Matches HTML mockup.
  // Uses layoutPositioning = "ABSOLUTE" so they overlay the auto-layout content.

  for (const f of ["Regular", "Medium", "SemiBold", "Bold"]) {
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

  const pageC = figma.root.children.find((p) => p.name === "Components");
  await figma.setCurrentPageAsync(pageC);

  const cap = pageC.findOne(
    (n) => n.type === "COMPONENT" && n.name === "CaptureConfirmation"
  );
  if (!cap) return { ok: false, error: "CaptureConfirmation not found" };

  // Idempotent: remove prior chrome if present.
  for (const ch of [...cap.children]) {
    if (ch.name === "scan-close" || ch.name === "scan-counter") ch.remove();
  }

  const W = cap.width;

  // ── Close button (top-left) ──────────────────────────────────────────────
  const close = figma.createFrame();
  close.name = "scan-close";
  close.resize(40, 40);
  close.cornerRadius = 20;
  close.layoutMode = "HORIZONTAL";
  close.primaryAxisSizingMode = "FIXED";
  close.counterAxisSizingMode = "FIXED";
  close.primaryAxisAlignItems = "CENTER";
  close.counterAxisAlignItems = "CENTER";
  close.fills = [{ type: "SOLID", color: { r: 0, g: 0, b: 0 }, opacity: 0.5 }];
  const closeTxt = figma.createText();
  closeTxt.fontName = { family: "Manrope", style: "Bold" };
  closeTxt.characters = "×";
  closeTxt.fontSize = 22;
  closeTxt.fills = [{ type: "SOLID", color: { r: 1, g: 1, b: 1 } }];
  close.appendChild(closeTxt);
  cap.appendChild(close);
  close.layoutPositioning = "ABSOLUTE";
  close.x = 16;
  close.y = 16;

  // ── Counter chip (top-right, success-tinted) ─────────────────────────────
  const chip = figma.createFrame();
  chip.name = "scan-counter";
  chip.layoutMode = "HORIZONTAL";
  chip.primaryAxisSizingMode = "AUTO";
  chip.counterAxisSizingMode = "AUTO";
  chip.primaryAxisAlignItems = "CENTER";
  chip.counterAxisAlignItems = "CENTER";
  chip.paddingLeft = 12;
  chip.paddingRight = 12;
  chip.paddingTop = 6;
  chip.paddingBottom = 6;
  chip.itemSpacing = 6;
  chip.cornerRadius = 999;
  chip.fills = [boundFill(v["success"])];

  const chipIcon = figma.createText();
  chipIcon.fontName = { family: "Manrope", style: "Bold" };
  chipIcon.characters = "✓";
  chipIcon.fontSize = 14;
  chipIcon.fills = [boundFill(v["onSuccess"])];
  chip.appendChild(chipIcon);

  const chipText = figma.createText();
  await chipText.setTextStyleIdAsync(S["label/Large"].id);
  chipText.characters = "3 u redu";
  chipText.fills = [boundFill(v["onSuccess"])];
  chip.appendChild(chipText);

  cap.appendChild(chip);
  chip.layoutPositioning = "ABSOLUTE";
  chip.x = W - chip.width - 16;
  chip.y = 16;

  return {
    ok: true,
    closeId: close.id,
    chipId: chip.id,
    capWidth: W,
    chipX: chip.x,
  };
})()
