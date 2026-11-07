# GSV Poems — Design System (v1)

Status: **draft v2 (peacock palette), waiting for approval** · Mock-ups: https://claude.ai/artifact/Fs1e9fkQE5zWnWG3beW3jk (private canvas)

## Feel
Peacock (Mor): cool white cards, deep peacock teal, saffron highlights. It is fresh, calm and Gujarati, and it is deliberately **not** the cream and coffee look of the kavigsv.com website. Built for an elderly, non-technical writer: big type, a labelled icon on every control, one main action per screen.

## Themes (colour tokens)
| Token | Mor (default) | Light | Night | Kamal | Neel | Van |
| --- | --- | --- | --- | --- | --- | --- |
| background | #F4F7F6 | #F5F5F7 | #0E1416 | #F7F2F8 | #0F1B3D | #EEF5EF |
| surface / page | #FFFFFF | #FFFFFF | #172124 | #FFFFFF | #172654 | #FFFFFF |
| ink (text) | #10302E | #1C1C1E | #E8F0EF | #2A1630 | #EEF2FF | #15281B |
| muted text | #4F6664 | #5C5C60 | #A7B8B6 | #66506B | #B9C3E6 | #4E6354 |
| primary (actions) | #0E5E5A | #2D6CB5 | #5FD0C5 | #A0285F | #F5B83D | #2F7D4F |
| accent (ornament) | #E8833A | #8E8E93 | #F2A65E | #2F7D5B | #7FB2FF | #C27C0E |

- **Mor extras:**
  - Peacock blue: #2D6CB5, used in the Home hero gradient (#2D6CB5 to #0E5E5A to #0A403E)
  - Saffron for text and small numbers: #B4561A
  - Teal tint for chips: #E3EEEC
  - Button gradient: #13746F to #0B4C49
- **Status colours:**
  - Good / shubh: #2F5A3C
  - Neutral / char: #283A70
  - Bad / ashubh: #9B2C2C
  - Festival: #B9520A
  - Alert background: #FFF0E3, with border #F2A65E
- **Colour is never the only signal:** every status also has a text tag.
- **Contrast:** text must be ≥ 4.5:1 in every theme. Bright saffron (#E8833A) is for ornaments and icons only; text uses #B4561A.

## Type
| Role | Font | Size / line height |
| --- | --- | --- |
| Poem title | Noto Serif Gujarati / Tiro Devanagari Hindi | 28 / 1.25, bold, −0.01em |
| Poem body | Noto Serif Gujarati / Tiro Devanagari Hindi | 22 / 1.85 (adjustable 18–30) |
| Screen title | Noto Serif Gujarati | 28 bold |
| UI label | Hind Vadodara | 17 semibold |
| Secondary | Hind Vadodara | 14–15 |

- The minimum UI text is 13 sp.
- All fonts are bundled for offline use (SIL OFL).
- Every size scales with the system font-size setting.

## Shape, depth, spacing
- **Corner radius:**
  - Cards: 18–22 dp
  - Hero and reader page: 26–30 dp
  - Pills and chips: full rounding
- **Spacing:** 4 dp grid, with 16–18 dp screen gutters and 14–22 dp gaps between sections.
- **Embossed tiles** for categories and settings icons:
  - A subtle top-light gradient
  - A 1 px inner highlight at the top
  - A 2 px inner shadow at the bottom
  - A soft drop shadow
- **Bottom bar:** translucent paper with a 20 px blur, a hairline top edge, and content scrolling underneath.

## Touch and motion
- Touch targets are ≥ 48 dp, and ≥ 56–60 dp for main actions.
- Feedback starts the moment the finger touches down (press scale 0.97).
- Springs have no bounce (damping 1.0, response 0.35 s). A slight bounce (0.8) only after a flick, such as swiping between poems.
- When Reduce Motion is on, animations become 200 ms cross-fades.

## Navigation
- **Bottom bar**, left to right: Settings · Search · **Home** (a raised 66 dp peacock-teal disc with a saffron ring when active) · Write · Collection. Every item has a label.
- **Tablet:** two panes (list + reader) with a floating pill-shaped bottom bar.
- **Help:** every screen has a "?" button at the top right.

## Ornaments
- **Lotus line motif:** the page header, the Home hero watermark and the PIN screen.
- **Saffron corner brackets:** on the reader page.
- **Lined paper:** in the editor.
- **Splash:** the photo sits in a temple-arch frame.

## App icon
- **Option B, recommended:** a saffron lotus over a white quill stroke on a peacock-teal (#0B4C49) Android adaptive icon.
- **Option A:** the full logo, used on the splash screen.

## Icons: 3D clay set (40 icons)
- **Look:** a raised matte "clay" tile (lit from the top, 22% darker at the bottom, with a 2.5 dp bottom edge and a soft coloured drop shadow) sitting in a subtly recessed well. On top is a glossy two-tone symbol with depth, a glass shine across its top half and a carved darker detail.
- **Colours:** each icon has a dominant tile colour and a lighter supporting highlight. All 40 are listed in `ICON_PROMPTS.md`.
- **Built as layered vector graphics** (in Flutter: a CustomPainter or SVG with gradients), so the icons stay sharp at any size, follow the theme and need no internet.
- **Optional renders:** if photoreal PNGs are rendered from `ICON_PROMPTS.md`, put them in `assets/icons/3d/<key>.png` and they replace the vector icons. The vector icons stay as a fallback.
- **Sizes:**
  - Nav bar: 40 dp, with Home at 72 dp and raised
  - Category tiles: 60–62 dp
  - Settings rows: 48 dp
  - Tool buttons: 36–44 dp
  - App icon: 128 dp in the preview
