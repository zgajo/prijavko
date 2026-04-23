(async () => {
  // TextField inner field frame is fixed at 280 — doesn't stretch when instance fills parent.
  // Set layoutSizingHorizontal = "FILL" on the field frame so it grows with its parent.

  const pageC = figma.root.children.find((p) => p.name === "Components");
  await figma.setCurrentPageAsync(pageC);

  const tfSet = pageC.findOne(
    (n) => n.type === "COMPONENT_SET" && n.name === "TextField"
  );
  if (!tfSet) return { ok: false, error: "TextField set not found" };

  let updated = 0;
  for (const variant of tfSet.children) {
    // The TextField COMPONENT itself has counterAxisSizingMode=FIXED at 280.
    // Change to AUTO/FILL semantics so instances can fill parents.
    // Actually: child field frame needs layoutSizingHorizontal = FILL.
    const field = variant.children.find(
      (c) => c.type === "FRAME" && c.layoutMode === "HORIZONTAL"
    );
    if (field) {
      field.layoutSizingHorizontal = "FILL";
      updated++;
    }
    // Also the label text above — make it FILL so long labels don't clip.
    const label = variant.children.find(
      (c) => c.type === "TEXT"
    );
    if (label) label.layoutSizingHorizontal = "FILL";
  }

  return { ok: true, updated };
})()
