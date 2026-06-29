---
name: Hufpflege Design System
colors:
  surface: '#fcf9f4'
  surface-dim: '#dcdad5'
  surface-bright: '#fcf9f4'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f3ee'
  surface-container: '#f0ede9'
  surface-container-high: '#ebe8e3'
  surface-container-highest: '#e5e2dd'
  on-surface: '#1c1c19'
  on-surface-variant: '#414942'
  inverse-surface: '#31302d'
  inverse-on-surface: '#f3f0eb'
  outline: '#717971'
  outline-variant: '#c1c9bf'
  surface-tint: '#386847'
  primary: '#154628'
  on-primary: '#ffffff'
  primary-container: '#2e5e3e'
  on-primary-container: '#a1d5ad'
  inverse-primary: '#9fd3aa'
  secondary: '#845400'
  on-secondary: '#ffffff'
  secondary-container: '#ffb959'
  on-secondary-container: '#744900'
  tertiary: '#04425c'
  on-tertiary: '#ffffff'
  tertiary-container: '#275a75'
  on-tertiary-container: '#a0d0ef'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#baefc5'
  primary-fixed-dim: '#9fd3aa'
  on-primary-fixed: '#00210e'
  on-primary-fixed-variant: '#1f5031'
  secondary-fixed: '#ffddb6'
  secondary-fixed-dim: '#ffb959'
  on-secondary-fixed: '#2a1800'
  on-secondary-fixed-variant: '#643f00'
  tertiary-fixed: '#c5e7ff'
  tertiary-fixed-dim: '#9dcdec'
  on-tertiary-fixed: '#001e2d'
  on-tertiary-fixed-variant: '#154c66'
  background: '#fcf9f4'
  on-background: '#1c1c19'
  surface-variant: '#e5e2dd'
typography:
  display-lg:
    fontFamily: Nunito Sans
    fontSize: 57px
    fontWeight: '700'
    lineHeight: 64px
    letterSpacing: -0.25px
  headline-lg:
    fontFamily: Nunito Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Nunito Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
  title-lg:
    fontFamily: Nunito Sans
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Nunito Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0.5px
  body-md:
    fontFamily: Nunito Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0.25px
  label-lg:
    fontFamily: Nunito Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.1px
  label-md:
    fontFamily: Nunito Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  container-padding: 16px
  card-gap: 12px
---

## Brand & Style
The design system centers on the intersection of professional craftsmanship and natural equine care. It adopts a **Modern Material 3** aesthetic—refined, functional, and organized—while infusing warmth through organic color choices and soft geometry. 

The personality is that of a "Trusted Expert": reliable enough for medical documentation, yet approachable enough for field work in a stable. The interface avoids cold, clinical whites in favor of earthy tones that reduce glare during outdoor use. The visual language emphasizes clarity and durability, mirroring the tactile nature of farriery and hoof orthopedics.

## Colors
This palette is grounded in the environment of the horse. 

- **Primary (Deep Forest Green):** Represents growth, health, and the professional stability of the specialist. Used for key actions and branding elements.
- **Secondary (Warm Amber):** Inspired by leather and horn, used for accents that require attention without the alarm of red.
- **Background (Off-White):** A soft, "paper-like" surface that reduces eye strain in bright outdoor light.
- **Status Colors:** Logic-driven colors for quick scanning:
    - **Regulär:** Soft Green for healthy maintenance.
    - **Akut:** Warm Orange for urgent treatment needs.
    - **Geplant:** Calm Blue for upcoming appointments.

## Typography
**Nunito Sans** is chosen for its rounded terminals, which provide a friendly, organic feel that complements the "warm professional" brand. 

Hierarchy is established through weight rather than extreme size shifts to maintain a compact, tool-like density. For technical data—such as hoof measurements or date logs—ensure `body-md` is used to maintain legibility in list-heavy views. All headers use Bold or SemiBold weights to ensure high contrast against the off-white background.

## Layout & Spacing
The layout follows a **fluid grid** model optimized for one-handed mobile use, typical for a specialist who may be holding a lead rope or tool. 

- **Margins:** A standard 16px lateral margin is used for all screens.
- **Rhythm:** An 8px linear scale governs all vertical relationships. 
- **Touch Targets:** Minimum touch targets are 48x48px to accommodate users who may be wearing work gloves or have compromised dexterity while working in the field.
- **Grouping:** Use 12px gaps between cards to create a distinct but tight visual relationship between records.

## Elevation & Depth
This design system utilizes **Tonal Layers** combined with **Ambient Shadows** to create a focused hierarchy.

- **Level 0 (Background):** Off-White (#F7F4EF), flat.
- **Level 1 (Secondary Cards/Lists):** Pure White (#FFFFFF) with a very thin 1px stroke in a light neutral tone. No shadow.
- **Level 2 (Main Interactive Cards):** Pure White (#FFFFFF) with a subtle, diffused shadow (Blur: 8px, Y-Offset: 2px, Opacity: 8% Black). This is the primary "Work Surface" for horse profiles and appointment details.
- **Level 3 (Floating Action Buttons/Dialogs):** Primary color surfaces with a more pronounced shadow to indicate immediate priority.

Avoid heavy black shadows; instead, use a slight tint of the Primary color in the shadow color for a more naturalistic look.

## Shapes
The shape language is "Soft-Modern." 

- **Cards:** Use a consistent 12dp (0.75rem) corner radius. This is large enough to feel friendly but structured enough to feel professional.
- **Input Fields:** Follow the 12dp radius to match cards, creating a unified form language.
- **Badges/Chips:** Use a fully rounded "Pill" shape (32dp+) to distinguish status indicators from clickable buttons or cards.
- **Buttons:** Large buttons use a 12dp radius; smaller utility buttons use a pill shape.

## Components
### Buttons
- **Primary:** Solid Deep Forest Green with White text. High emphasis.
- **Secondary:** Outlined with Primary color or solid Warm Amber for "Caution/Important" actions.
- **FAB (Floating Action Button):** For "Neuer Eintrag" (New Entry) or "Termin hinzufügen," using the Primary color.

### Chips & Badges (Status)
Pill-shaped with light background tints and dark text for maximum readability:
- **Regulär:** Light Green background, Dark Green text.
- **Akut:** Light Amber background, Dark Amber text.
- **Geplant:** Light Blue background, Dark Blue text.

### Cards (Pferdeprofil / Termin)
Pure White surface, 12dp radius, Elevation 2. Contents should include a small horse silhouette or photo thumbnail (rounded) and the status badge in the top-right corner.

### Input Fields
Filled style with a bottom-only border or fully enclosed with 12dp radius. Use Warm Amber for the cursor and active underline to provide a "glow" of activity.

### Icons
Use a custom iconography set that is "Line-Art" style with rounded ends.
- **Pferd (Horse):** A clean silhouette.
- **Hufbeschlag (Horseshoe):** Used for treatment logs.
- **Kalender (Calendar):** For scheduling.
- **Kamera (Camera):** Crucial for documenting hoof progress with photos.