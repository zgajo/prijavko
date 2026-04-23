(async () => {
  // Fix: position GuestStatusGlyph variants in a 5×3 grid inside the set.
  let page = figma.root.children.find((p) => p.name === "Components");
  await figma.setCurrentPageAsync(page);

  const set = page.findOne((n) => n.type === "COMPONENT_SET" && n.name === "GuestStatusGlyph");
  if (!set) return { ok: false, error: "GuestStatusGlyph set not found" };

  const stateOrder = ["queued", "sending", "sent", "failed", "in_flight_unresolved"];
  const sizeOrder = ["small", "large", "hero"];
  const sizePx = { small: 24, large: 56, hero: 64 };
  const pad = 16;
  const gap = 16;

  // Parse variant name back to {size, state}.
  const parse = (name) => {
    const m = Object.fromEntries(
      name.split(",").map((s) => s.trim().split("=").map((x) => x.trim()))
    );
    return m;
  };

  // Compute row Ys.
  const rowY = {};
  let cursorY = pad;
  for (const s of sizeOrder) {
    rowY[s] = cursorY;
    cursorY += sizePx[s] + gap;
  }
  const totalH = cursorY - gap + pad;

  // Compute column widths per row (each row has its own col width = its sizePx).
  const totalW = pad + 5 * 64 + 4 * gap + pad; // widest row dominates (hero=64)

  // Position each child.
  for (const child of set.children) {
    const { size, state } = parse(child.name);
    const col = stateOrder.indexOf(state);
    const rowWidth = sizePx[size];
    // Center each cell in a fixed 64-wide column so rows align visually.
    const colX = pad + col * (64 + gap) + (64 - rowWidth) / 2;
    child.x = colX;
    child.y = rowY[size];
  }

  // Resize the set frame to fit all variants.
  set.resizeWithoutConstraints(totalW, totalH);

  return { ok: true, setId: set.id, w: set.width, h: set.height, variants: set.children.length };
})()
