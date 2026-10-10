---
name: frontend-craft
description: Design and build web UI at a senior design-engineer standard - pages, apps, dashboards, components, landing pages, HTML/React/Vue/Svelte views, CSS, theming, responsive layout, and diagrams. Use before writing or restyling any user-facing interface, and whenever a result must not look templated or AI-generated.
---

# Frontend Craft

Distilled from the Claude Opus 5.5 design and diagramming guidance, generalized to any stack. Correctness, accessibility, and the project's own design system come first; taste comes after.

## 1. Read the request first
- **Honor what exists.** Before designing, look for a design system: tokens/theme files, Tailwind config, component library, existing styles, the repo's AGENTS.md/CLAUDE.md. If one exists, apply it - everything below only fills gaps. Precedence: the user's words → the project's system → your choices.
- **Calibrate treatment, not whether to design.** Utilitarian (tool, form, admin, docs, demo): polished hierarchy, considered spacing, a real palette, restrained flourishes, no giant hero. Editorial (landing page, game, product someone will share): a distinctive point of view and one deliberate aesthetic risk. When unsure, a well-composed page is never wrong; an over-designed one sometimes is.
- **Ground it in the subject.** Pin one subject, its audience, and the screen's single job. Carry at least one detail only this subject would have - its real units, terms of art, document conventions - as content, not ornament. Real content always, never lorem ipsum.

## 2. Plan before code (3 lines)
- **Color:** 4-6 named hex tokens. **Type:** a display face (used with restraint) + a body face (+ a mono/utility face for data if needed). **Layout:** one or two sentences.
- For editorial work, review the plan against the subject: rewrite any part that reads like the default you'd produce for any similar page. Then build exactly to the plan.

## 3. Fundamentals (every UI)
- **Tokens first.** Define the full light palette as CSS custom properties on `:root`; redefine only the tokens for dark under `@media (prefers-color-scheme: dark)` (guard it as `:root:not([data-theme="light"])` if the app has a manual toggle) and again under `:root[data-theme="dark"]`. Set `color-scheme` to match so form controls and scrollbars follow. Never define a color only inside a media/theme block; give `body` an explicit token background.
- **Choose neutrals deliberately.** Tint greys toward the accent; pick pure white/near-black only when they suit the subject.
- **Typography carries the page.** Real fallback stacks for every web font. Body measure ~65ch; one type scale, used consistently; `text-wrap: balance` on headings; letter-spacing on small uppercase labels; `font-variant-numeric: tabular-nums` wherever digits align.
- **Layout does the spacing.** Flex/grid with `gap`, not per-element margins. ≥16px side gutter at every width, set once on one wrapper (use `padding-block` for vertical so sides aren't zeroed). Works at ~400px: rows wrap or stack. `max-width: 100%` on media and aspect-ratio boxes; nothing with a `min-width` wider than the screen. Only tables, code, and diagrams may overflow - inside their own `overflow-x: auto` container. The page body never scrolls sideways. Mobile: respect safe-area insets (`env(safe-area-inset-*)`) on fixed/sticky bars; size one-screen apps with `height: 100%`/`dvh`, not `100vh`.
- **Repeated things are one object.** Cards, rows, badges share edges, baselines, and padding. Content sets container height; no lone orphan items in a grid row. Text that can outgrow its track wraps or scrolls - clipped text is a bug.
- **Not everything is a card.** Border, fill, radius, shadow each mean "separate object" - spend them by role. Big-number tiles only when those numbers are the point.
- **Show the UI at rest.** Everything meant to be read is visible on load - never parked at `opacity: 0` waiting for a scroll observer. Size a hero to its content. Tools and apps open in a realistic working state (real data, or clearly marked example data), not an empty shell.
- **Structure is information.** Numbering, eyebrows, dividers encode something true (a real sequence), not decoration.
- **UI ≠ document.** Dashboards are scanned: summary before detail, state encoded in form (pill, chip, severity stripe) as well as number; semantic colors (good/warning/critical) are separate from the accent; interactive things look interactive.
- **Copy is design material.** Name things by what users recognize (*notifications*, not *webhook config*). Active voice; a control says exactly what happens ("Publish" → toast "Published"). Errors say what went wrong and how to fix it - no apologies, no vagueness.

## 4. Avoid the AI-generated look
Unless the user asks for it, don't default to: warm cream (#F4F1EA) + serif display + terracotta; near-black + one acid-green/vermilion pop; broadsheet hairlines with dense columns; purple-to-blue gradient hero on white; Inter/Space Grotesk as the "safe" face; emoji as section markers; everything centered; `rounded-lg` on everything; accent rails on rounded cards; scattered gratuitous animation. Spend boldness in one place and keep the rest quiet; one orchestrated motion moment beats many effects.

## 5. Build cleanly
- Semantic HTML; close every element; double-quote attributes; every form control has a stable `id` and a `<label>`.
- Visible keyboard focus; full keyboard operability; respect `prefers-reduced-motion`; color is never the only signal; WCAG AA contrast (compute it, don't eyeball).
- Watch specificity: don't let a type selector and a component selector silently cancel each other's spacing. Prefer the project's styling approach (Tailwind, CSS modules, etc.) over introducing a new one.
- Libraries: only when they carry real weight; pin exact versions; prefer what the project already has. Native platform features first (`<input type="date">`, `<dialog>`, `details/summary`).
- Validate loading, empty, error, success, disabled states; long text; missing data; slow network (Part I §6).
- Generative/decorative graphics: Canvas/WebGL, not giant hand-written SVG paths.

## 6. Diagrams (architecture, flows, state)
- Draw only when a picture shows a mechanism faster than a sentence: where data flows, which components talk, what changes between options. Otherwise write the sentence.
- Depict the mechanism, not its name; comparing options → draw the difference (the edge each adds/removes). Match complexity to the decision. **Label the arrows** (`writes`, `polls every 30s`); legends only for repeated encodings.
- Inline SVG: size by `viewBox` + `max-width: 100%; height: auto`; strokes/text in `currentColor` so both themes work; one literal hue only for the element that carries meaning; arrowheads via `<marker>` or `<polygon>`; 11-13px labels of a few words; align to a grid; wrap in `<figure>` + `<figcaption>`, give the svg `role="img"` and an `aria-label` stating the claim; no `<script>`/`<foreignObject>` inside.

## 7. Verify (look once, then fix once)
Render it and look - a screenshot or the browser at desktop and ~400px width, light and dark. Fix what you see in one pass: clipping, overlap, unreadable text, horizontal scroll, dead controls. For charts, spend the look on the chart. Don't build an endless screenshot loop; the gate and the user's feedback take it from there.
