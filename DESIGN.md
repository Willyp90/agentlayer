# Design Brief

## Direction

**Monochrome Technical** — Production-ready developer tool with terminal-inspired precision. Landing page extends brutalist aesthetic with intentional section layering and accent highlight strategy for developer-centric showcase.

## Tone

Brutalist and technical — sharp edges, minimal surfaces, zero gradients. Information-dense, code-forward, designed for developers and AI engineers.

## Differentiation

Thin 1px borders throughout create a technical grid aesthetic. Landing page uses alternating `bg-background` / `bg-card` sections with borders for rhythm and hierarchy, differentiating from typical marketing websites.

## Color Palette

| Token      | Light OKLCH | Dark OKLCH | Role |
| ---------- | ----------- | --------- | ---- |
| background | 0.98 0 0 | 0.12 0 0 | Page background, base sections |
| card | 1.0 0 0 | 0.16 0 0 | Elevated cards, alternating sections |
| foreground | 0.18 0 0 | 0.92 0 0 | Body text, primary readability |
| muted | 0.92 0 0 | 0.2 0 0 | Secondary text, disabled states, code backgrounds |
| accent | 0.62 0.18 245 | 0.68 0.2 245 | CTAs, highlights, active states, code accents (purple) |
| border | 0.88 0 0 | 0.24 0 0 | 1px dividers, card/section borders |

## Typography

- Display: JetBrains Mono — hero headline (text-4xl bold tracking-tight), section titles (text-2xl font-semibold), labels (text-xs uppercase tracking-widest)
- Body: Figtree — paragraphs (text-sm leading-relaxed), descriptions, UI labels
- Scale: hero headline `text-4xl font-mono font-bold`, subheadline `text-lg font-body`, h2 `text-2xl font-mono font-semibold`, h3 `text-base font-mono font-semibold`, body `text-sm font-body`

## Elevation & Depth

No shadows or gradients. Structure via 1px borders and background color contrast. Card backgrounds (0.16) elevate against page (0.12). Section borders (`border-t border-b`) create visual rhythm.

## Structural Zones

| Zone | Background | Border | Notes |
| ---- | ----------- | ------ | ----- |
| Header/Nav | background | border-b | Logo, nav links (if nav present) |
| Hero Section | background | — | Headline, subheadline, CTA, ICP badge |
| Problem/Solution | card | border-y | Two-column alternate section |
| How It Works | background | — | Four numbered steps grid |
| Benefits | card | border-y | Five-card grid layout |
| Primitives Showcase | background | — | Four code example cards |
| Developer Experience | card | border-y | Three callout cards |
| Footer | muted/20 | border-t | Copyright, ICP attribution |

## Accent Usage Strategy

**When to use accent purple (0.68 0.2 245):**
- Primary CTA buttons ("Get Started", "Deploy", "Explore")
- Active/hover states on interactive elements
- Code syntax highlighting (keywords, values in JSON examples)
- Sparingly in headings or number callouts (e.g., step numbers in "How It Works")

**When NOT to use accent:**
- Body text (use foreground 0.92 0 0)
- Section backgrounds (use background or card only)
- Borders (except focus states on inputs — use accent border on focus)

## Component Patterns

- Buttons: `btn-primary` (accent fill, white text) or `btn-secondary` (border only, hover accent)
- Code blocks: `code-block` (muted/30 background, border-border, monospace text)
- Cards: thin border, card background, no shadow
- Badges: uppercase mono, accent text on muted background
- Dividers: 1px border-border, full width

## Motion

Entrance: `animate-fade-in` (0.4s) or `animate-slide-up` (0.4s) for sections on page load. Hover: color shift only, `transition-smooth` (0.2s). No decorative animations.

## Landing Page Grid & Spacing

- Hero: 96px top padding, 64px bottom (create visual dominance)
- Sections: 64px padding top/bottom (rhythm)
- Card grids: 24px gap on desktop, 16px mobile
- Form groups: 12px gap
- Max width: 1280px (7xl)

## Constraints

- No gradients, shadows, or blur effects
- All borders 1px only
- Border-radius 2px max (most at 0)
- No more than 2 font families (JetBrains Mono + Figtree)
- Accent purple reserved for CTAs and highlights only
- No opacity-based layering; use color contrast instead
- Section alternation via background color, not overlays

## Signature Detail

Thin 1px borders on every interactive element, card, and section divider create a technical grid aesthetic. Landing page section layering (alternating background/card) maintains this while providing visual rhythm for public showcase.
