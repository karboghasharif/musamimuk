# Product Marketing Context

**Document version:** v1  
**Last updated:** 2026-10-26  
**Product:** Musamimuk (Arabic: مساميمك)  
**Sites / apps:** [musamimuk.com](https://musamimuk.com/) · Google Play `com.musamimuk.app` · iOS `com.musamimuk.ios.app`  
**Sister repos:** Flutter app · Laravel API (`Musamimuk 3`) · React admin / marketing site (`editor 2`)

> V1 auto-drafted from landing page, Play listing, in-app About/AI copy, and product docs. Marked gaps need founder confirmation.

## Product Overview
**One-liner:** Free AI photo editor and design maker for mobile — create social graphics, remove backgrounds, generate QR codes, and join design contests from your phone.

**What it does:** Musamimuk is a mobile design studio. Users design on a canvas (text, shapes, stickers, logos, stock assets), remove image backgrounds with AI, generate QR codes, browse/redesign public templates, save designs public or private, enter contests, and use AI Studio (ChatGPT-powered images, editable designs, chat, and vision). Coins power AI features; Musamimuk Pro unlocks premium access via subscription.

**Product category:** AI photo editor / mobile graphic design app / design maker (same shelf as Canva Mobile, Picsart, PhotoRoom, Adobe Express)

**Product type:** Consumer mobile app (freemium) with backend API, admin portal, and ChatGPT Apps/MCP integration

**Business model:**
- Free to download and use core editor + templates + contests
- **Musamimuk Coins** (IAP consumable packs) for AI tools (e.g. image gen, editor AI commands); welcome grant on register/upgrade
- **Musamimuk Pro** subscription (RevenueCat): Lifetime / Yearly / Monthly — entitlement `musamimuk_pro` for premium assets and plan perks
- Background removal currently free in default coin costs (confirm if this stays)
- In-app ads placements exist on the backend

## Target Audience
**Target companies:** Primarily B2C individuals; also solo operators and very small businesses (shops, freelancers) who need phone-first design — not enterprise design teams

**Decision-makers:** The end user themselves (download + subscribe/buy coins). No formal buying committee.

**Primary use case:** Create polished social posts, product photos, Islamic/cultural graphics, and promo visuals on Android/iOS without desktop software or a hired designer.

**Jobs to be done:**
- “Make a good-looking post for Instagram / Facebook / Snapchat from my phone, fast.”
- “Cut the background out of this product or portrait photo cleanly.”
- “Design something that looks right in Arabic (fonts, RTL, Ramadan/Islamic themes).”
- “Generate a QR code that matches my brand and drop it into a design.”

**Use cases:**
- Social media creators — posts, stories, covers
- Small businesses — promotions, product graphics, QR for menus/WiFi/links
- Freelancers — quick client mockups, saved versions in My Designs
- Students — posters, CVs/resumes, project graphics
- Community / faith-based creators — Islamic templates, contest entries (e.g. Ramadan)
- Everyday users — one-tap background removal and photo touch-ups

## Personas
*B2C-weighted. Light stakeholder map for clarity.*

| Persona | Cares about | Challenge | Value we promise |
|---------|-------------|-----------|------------------|
| Social creator | Speed, templates, on-brand look | Phone tools feel weak vs Canva desktop | Standout posts with AI edits + templates from the phone |
| Small shop owner | Cheap, Arabic-friendly, QR + product shots | Can’t afford a designer; English-first apps frustrate | Promo graphics + BG removal + QR without hiring anyone |
| Contest / community creator | Recognition, themes, rewards | Nowhere to show work among peers | Enter contests, submit designs, win rewards |
| AI-curious hobbyist | Prompt → usable design | Generators dump flat images, not editable layers | ChatGPT images + editable layered designs + vision advice |

## Problems & Pain Points
**Core problem:** People need professional-looking graphics on their phone, but most “simple” editors are either too shallow, too English/Western-centric, or push them into heavy desktop tools.

**Why alternatives fall short:**
- Desktop-first design tools (Canva web, Photoshop) — awkward or incomplete on mobile
- Pure photo editors — weak templates, contests, and design-system features
- Western template libraries — weak Arabic typography and Islamic/cultural content
- One-shot AI image apps — output isn’t editable as layers in a real design canvas

**What it costs them:** Time fiddling with tools that don’t fit; money on freelancers for simple posts; missed posting cadence; awkward Arabic text rendering

**Emotional tension:** “I know what I want it to look like, but I don’t feel like a designer — and I don’t want to look amateur in my feed or shop.”

## Competitive Landscape
**Direct:** Canva Mobile, Picsart, Adobe Express, PhotoRoom — fall short when users need Arabic-first fonts/templates, contest community, or a lighter free path with coins instead of hard paywalls (positioning claim — validate with users)

**Secondary:** CapCut / InShot (video-first), pure BG-removal apps (remove.bg mobile clones), QR-only apps — solve one job, not the full design loop

**Indirect:** Hire a designer, design on desktop then transfer, post raw phone photos, ChatGPT image alone without an editor — slow, expensive, or non-editable

## Differentiation
**Key differentiators:**
- Arabic + English custom font library (admin-curated), RTL-aware experience, Islamic/social template categories
- Full mobile canvas editor + AI Studio (images, editable layered designs, chat, vision) + BG removal + QR in one app
- Design contests with prizes (community loop, not just a tool)
- Musamimuk Coins wallet (server-truth IAP) + Musamimuk Pro — flexible monetization vs all-or-nothing Pro
- ChatGPT Apps / MCP: same Musamimuk account can create/search/edit designs from ChatGPT, then continue in the Flutter editor

**How we do it differently:** Build for phone-first creators who need cultural fit (especially Arabic/Islamic markets) and a path from AI prompt → editable design → save/share/contest — not just filters or flat AI images.

**Why that's better:** Faster path from idea to postable asset in the user’s language and context; keeps creativity in-app instead of bouncing between three tools.

**Why customers choose us:** (gap — need store reviews / interview quotes) Likely: free start, Arabic fonts/templates, contests, AI that lands in a real editor.

## Objections
| Objection | Response |
|-----------|----------|
| “Isn’t this just another Canva?” | Canva is great; Musamimuk is phone-first with Arabic fonts, Islamic templates, contests, and AI that produces editable designs — built for creators who live on mobile. |
| “Will AI / coins get expensive?” | Core editing and many features stay free. Coins are pay-as-you-go for AI; Pro unlocks premium assets. Welcome coins on signup so you can try before you buy. |
| “Is it only Android / only English?” | Android on Play today; iOS shipping. Full EN + AR localization. |
| “Can I trust my designs / account?” | Designs save to My Designs (public or private). Auth via email, Google, Apple, Facebook; guests can try then upgrade. |

**Anti-persona:** Enterprise brand teams needing SSO, DAM, approval workflows, and multi-seat admin; print shops needing CMYK/press workflows; users who only want desktop vector/illustration (Illustrator-class).

## Switching Dynamics
**Push:** Frustration with English-only templates, bad Arabic text, paying for tools they barely use, or bouncing between BG remover + QR app + editor

**Pull:** One app that edits, removes backgrounds, makes QR codes, offers Arabic fonts/templates, AI Studio, and contests

**Habit:** Muscle memory in Canva/Picsart; existing template libraries; “good enough” Instagram stories

**Anxiety:** Will my old designs transfer? Will coins drain fast? Is the editor powerful enough vs what I already know?

## Customer Language
**How they describe the problem:**
- (gap — capture from reviews/support) Likely directions: “I need Arabic fonts that look right,” “remove background for product photo,” “make Instagram post on phone,” “design for Ramadan”

**How they describe us:**
- From our own copy (not yet customer-verbatim): “all-in-one design studio,” “AI photo editor and design maker,” “create standout designs,” “مساميمك”

**Words to use:**
- Design maker, AI photo editor, remove backgrounds, templates, My Designs, design contests, Musamimuk Coins, Musamimuk Pro, AI Studio, editable designs, Arabic fonts, QR codes, on your phone

**Words to avoid:**
- “Photoshop killer,” “enterprise platform,” “seamless” / “revolutionary” / empty AI hype
- Calling ChatGPT MCP “OpenAI’s product” — it’s Musamimuk inside ChatGPT with the user’s account

**Glossary:**
| Term | Meaning |
|------|---------|
| Musamimuk / مساميمك | Product brand (note: some internal docs spell “Musammimuk”) |
| My Designs | User’s saved design library (public or private) |
| Online Designs / templates | Public catalog users can browse and redesign |
| AI Studio | In-app ChatGPT surfaces: images, designs, chat, vision |
| Musamimuk Coins | Server-side wallet currency for AI / paid features |
| Musamimuk Pro | Subscription entitlement (`musamimuk_pro`) via RevenueCat |
| Guest | Try-before-account; cannot buy/spend coins until upgrade |
| Contest | Timed design competition with prizes / currency |
| Online Assets | Multi-source stock picker (Unsplash, Pexels, Pixabay, icons, etc.) |
| ChatGPT MCP / Apps | ChatGPT as another client of the Musamimuk API (OAuth) |

## Brand Voice
*Inferred from landing, Play listing, and in-app About — confirm with founder.*

| Attribute | Means | Doesn't mean | Example line |
|-----------|-------|--------------|--------------|
| Clear & capable | Feature-led, concrete verbs (remove, design, generate, join) | Feature dumps or jargon walls | “Remove backgrounds, design social media graphics, generate QR codes, and join design contests — all from your phone.” |
| Encouraging, not elitist | Beginners welcome; creativity for everyone | Condescending “anyone can design!!!” hype | “Whether you are a beginner or a pro, our editor is built to turn your ideas into polished visuals.” |
| Community-aware | Contests, listening, cultural templates | Fake “join millions” claims without proof | “We listen to our community and keep improving so you can focus on what matters: your creativity.” |
| Bilingual-respectful | EN and AR treated as first-class | Token Arabic or broken RTL as an afterthought | AI prompt hint: “Modern Arabic logo for a coffee shop…” |

**Tone by context:**
- Support: Calm, specific next steps; own the issue if it’s ours
- Launch: Energy via what’s new + who it’s for (Arabic creators, contests, AI Studio) — one concrete proof
- Errors: What happened + what to do (e.g. insufficient coins → open coin store)
- Sales / store listing: Benefit + capability, free download CTA, no superlative stacks
- Social: Show real designs, contest winners, before/after BG removal; light personality OK

**Terms we own:** Musamimuk, مساميمك, Musamimuk Coins, Musamimuk Pro, AI Studio, My Designs, Online Designs

**Never use (and why):**
- “All-in-one platform” as empty category speak — we say what the all-in-one actually includes
- “Seamless AI” — coins, loading, and limits are real; be honest
- Competing on “Photoshop replacement” — wrong shelf and wrong promise

## Proof Points
**Metrics:** (gap — installs, ratings, contest entries, retention, coin conversion)

**Customers:** (gap — notable shops, creators, or logos)

**Testimonials:** (gap — pull from Play reviews once curated)

**Value themes:**
| Theme | Proof |
|-------|-------|
| Phone-first design studio | Landing + Play listing feature list; canvas presets for social sizes |
| AI that stays editable | AI Studio → layered designs; editor AI commands via backend |
| Cultural / Arabic fit | Custom Arabic+English fonts; Islamic template category; AR localization |
| Community | Contests module + Ramadan-style competition copy in-app |
| Fair try | Free download, guest mode, welcome coins, Pro + coin packs |

## Goals
**Business goal:** Grow mobile installs and convert free users into coin buyers and/or Musamimuk Pro subscribers while deepening Arabic/social-creator retention via templates, contests, and AI Studio.

**Conversion action:** Primary — Google Play install (and App Store when live). Secondary — create free account (guest upgrade). Tertiary — first coin purchase or Pro subscribe.

**Current metrics:** (gap)

## Paid Ads
*Not configured — skip until running paid. When ads start, fill target CPA/ROAS, budgets, and agent permissions here.*

## Learnings
*Decisions and tested lessons. Newest first. Keep it to about 20 active entries.*
| Date | Learning | Evidence | Applies to | Status |
|------|----------|----------|------------|--------|
| | | | | |

## Changelog
*Newest first. One line per revision: what changed and why.*
- v1 (2026-10-26) — Initial context auto-drafted from musamimuk.com landing, Play listing, in-app About/AI/wallet copy, and sister-repo product docs.
