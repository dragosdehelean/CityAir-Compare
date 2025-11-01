# Agents.md – CityAir Compare

> Acest document operationalizează **SPECS.md** într‑un mod „agent‑centric”, menținând *întocmai spiritul specificațiilor*. Accentul principal: **testare unitară + integrare + e2e pentru fiecare feature** și o **buclă de auto‑verificare AI** la fiecare rundă de răspuns la o instrucțiune.

---

## 1) Scop, non‑scop, principii

**Scop:** coordonare între agenți (roluri) pentru a livra aplicația descrisă în SPECS.md: comparație a calității aerului București vs. alte capitale (ex. Beijing) pe ore/zile/săptămâni/luni/anotimpuri, cu metodologie transparentă și date verificabile.

**Non‑scop:** schimbarea definițiilor, metodologiilor, datelor sau componentelor din SPECS.md; adăugarea de funcționalități în afara roadmap‑ului aprobat.

**Principii:**

* *Fidelity to specs* – nu se alterează metodologiile, sursele de date, UI/UX, stack‑ul sau KPI‑urile de performanță.
* *Test‑first where feasible* – pentru fiecare feature se definește matricea de teste înainte/în paralel cu implementarea.
* *Observability & reproducibility* – fiecare rezultat e auditabil (surse, filtre, versiuni).

---

## 2) Rolurile agenților (responsabilități RACI)

> Toți agenții folosesc TypeScript, Next.js 15 (App Router, RSC), React 19.2, TanStack Query, ECharts, MapLibre, API Next.js (Route Handlers), TimescaleDB + PostGIS, Redis, Vercel Cron – exact ca în SPECS.

### 2.1. Orchestrator Agent (OA)

* Planifică iterațiile; păstrează backlogul de features conform SPECS/roadmap.
* Acceptă livrări doar dacă **toate** testele trec și criteriile de calitate sunt bifate.

### 2.2. Frontend Agent (FE)

* Implementă ecranul **Compare**, componentele **KPIBar**, **SyncLineChart**, **CalendarHeatmap**, **DiurnalProfile**, **StationsMap**, **MethodologyDrawer**.
* Respectă accesibilitatea (WCAG AA), i18n (RO/EN), starea prin TanStack Query + URL ca „source of truth”.

### 2.3. Visualization Agent (Viz)

* Configurează ECharts pentru serii dense, heatmap calendar, ridgeline/rose; gestionează performanța și fallback‑urile (canvas/SVG).
* Definește *visual regression baselines* pentru grafice.

### 2.4. Mapping Agent (Map)

* Integrează MapLibre GL, încărcarea stațiilor, filtre pe tip, bounding boxes și marker clustering.

### 2.5. API & Backend Agent (BE)

* Expune `/api/cities`, `/api/series`, `/api/diurnal`, `/api/coverage` după contract.
* Implementează agregările orare/zi/lună/sezon pe TimescaleDB; cache în Redis.

### 2.6. Data Integration Agent (Data)

* ETL orar din OpenAQ/WAQI/EEA; validare (zod), normalizare unități, deduplicare, QA flags, *winsorization* (p1–p99), rate‑limit handling.

### 2.7. QA & Testing Agent (QA)

* Definește și menține **matricea de testare** și **coverage gates**; operează testele unitare/integrate/e2e, vizuale, a11y, i18n, perf.

### 2.8. Security & Compliance Agent (Sec)

* Rate‑limiting, CORS, gestionare chei, headere securitate, validare input, dependency audit.

### 2.9. Observability Agent (Obs)

* OpenTelemetry, Sentry, logs cron; *quality reports* după fiecare ruladă.

### 2.10. Release & DevOps Agent (Rel)

* CI/CD GitHub Actions: build, type‑check, lint, unit, integration, e2e, visual, a11y, Lighthouse CI, deploy cu gates.

### 2.11. AI Reviewer Agent (AI‑R)

* Rulează **bucla de auto‑verificare** (vezi §6) la fiecare răspuns la o instrucțiune; emite verdict **PASS/FAIL** + difuri/artefacte.

---

## 3) Proces de colaborare

* **Branching:** `feat/*`, `fix/*`, `chore/*`; PR mici (<400 LOC diff la cod, <20 fișiere modificate unde e posibil).
* **Commit format:** Conventional Commits.
* **Codeowners:** FE (UI), Viz (grafice), Map (hartă), BE (API), Data (ETL), QA (test), Sec, Obs, Rel, OA (final approval).
* **Definition of Ready (DoR):** descriere, criterii de acceptanță măsurabile, matrice de teste, date de fixture.
* **Definition of Done (DoD):** implementare + **toate testele verzi**, rapoarte perf/a11y, docs actualizate, telemetry adăugată.

---

## 4) Strategia de testare (toate nivelurile)

**Tehnologii:**

* **Unit:** Vitest + Testing Library (React Testing Library, DOM Testing Library).
* **Integrare API:** Vitest + Supertest/MSW (mock de rețea), contract tests pentru `/api/*`.
* **E2E:** Playwright (headless + trace/video), *network mocking* cu MSW unde e necesar; *real API smoke* pe mediu de staging.
* **Vizual regresie:** Playwright *screenshot diff* cu toleranță per chart; baseline per densitate de date.
* **A11y:** axe‑core (jest‑axe/ct) + pași e2e cu axe‑playwright.
* **i18n:** snap‑tests pentru RO/EN, verificare key‑coverage 100%.
* **Perf:** Lighthouse CI (LCP, TTI, TBT), bundle limit cu `size-limit`.
* **Static quality:** ESLint (Next.js plugin), Type‑check (tsc), Prettier, Depcheck, npm‑audit/OWASP Dependency Check.

**Coverage gates minime:** 85% unit/integration pe cod critic (utilitare AQI/CAQI, conversii, selectors), 70% global, 95% branch pe funcții de indexare/conversie.

**Fixtures & date controlate:**

* Snapshoturi JSON OpenAQ/WAQI/EEA minimizate; *golden cases* pentru: (1) oraș emisfera sudică (sezoane opuse), (2) linie temporală cu ore lipsă (coverage <70%), (3) extreme p0/p100 (winsorization), (4) amestec tip stație background/traffic.

---

## 5) Matricea de test pe feature (exhaustivă)

> Pentru fiecare feature, există **Unit**, **Integration**, **E2E**, **Visual** (unde se aplică), **A11y**, **Perf**. QA menține un checklist ce trebuie bifat înainte de PR merge.

### 5.1. Compare View & KPIBar

* **Unit:** calcul KPI (medie, mediană, p95, %WHO) pe serii mock; sincronizare time‑zone local.
* **Integrare:** interacțiune TanStack Query + URL params; *refetch* și *caching* corect.
* **E2E:** selectare orașe/poluanți/perioade, comutare AQI/CAQI/WHO, *fairness toggles*; verificare că datele și graficele se actualizează.
* **A11y:** focus order, aria‑labels, contrast.
* **Perf:** timpi sub budget (LCP <2.5s, TTI <3s).

### 5.2. SyncLineChart (ECharts)

* **Unit:** scale/time‑zone; downsampling; absent data handling.
* **Visual:** baseline screenshots pentru 24h/7z/30z/12l; toleranță Δpixel.
* **E2E:** zoom/brush sincronizat între orașe; tooltips cu valori corecte.

### 5.3. CalendarHeatmap

* **Unit:** mapare zi/oră locală; percentila/legendă corectă.
* **Visual:** baseline pentru anotimpuri diferite.
* **E2E:** higlight zile „peste WHO”; filtrare corectă la click.

### 5.4. DiurnalProfile (radar/rose)

* **Unit:** agregare oră locală; comparare București vs. Beijing.
* **E2E:** comutare lună/sezon; verificare „shape” coerent.

### 5.5. StationsMap (MapLibre)

* **Integration:** încărcare stații, filtre `type` (background/traffic/industrial), clustering; bounding box corect.
* **E2E:** toggle „Background only” reflectă stațiile vizibile și sursele seriei.
* **A11y:** tastatură + descrieri.

### 5.6. API `/api/series`

* **Unit:** conversii AQI_US/CAQI, *winsorization*, local‑time alignment; validare parametri (zod).
* **Integration:** query combinat `cities/pollutant/from/to/bucket/index/stationType/local` produce structură meta + puncte corecte.
* **Contract test:** tipuri/forme JSON stabile; *backward‑compat* semnalată în changelog.

### 5.7. API `/api/diurnal`

* **Unit:** agregări per oră (0–23) locale; emisfere.
* **Integration:** filtrare `month` multiplă; orașe multiple.

### 5.8. API `/api/coverage`

* **Unit:** calcul % acoperire; prag <70% ridică „warning”.
* **E2E:** banner apare/dispare corect.

### 5.9. Export CSV/PNG + „method snapshot”

* **E2E:** export generat; conține interval, surse, filtre; fișiere descărcabile.

### 5.10. ETL (cron ingest OpenAQ/WAQI/EEA)

* **Unit:** parseri, validare zod, normalizare unități, mapping stații.
* **Integration:** *end‑to‑end* până în Timescale (staging DB); idempotency (rerun nu dublează).
* **Observability:** logs & metri
  e; alerte la eșec.

### 5.11. Sezonalitate & diurn (emisfere)

* **Unit:** funcția `seasonOf(date, hemisphere)` acoperă toate lunile; teste parametrizate.

### 5.12. Securitate & confidențialitate

* **Static:** ESLint security rules, npm‑audit zero criticals.
* **E2E:** CORS strict; imposibil uploads neautorizate; secret leakage checks.

### 5.13. Accesibilitate & i18n

* **A11y:** axe „no violations” pe pagini critice.
* **i18n:** 100% traduceri; fallbackuri inexistente.

---

## 6) Bucla de auto‑verificare AI (executată la **fiecare** răspuns la o instrucțiune)

> Rol: AI‑R orchestrează o ruladă completă de teste + check‑uri de calitate și produce un „Quality Gate Report”. Dacă **orice** pas eșuează → răspunsul este marcat **FAIL**, se propune remediere și se re‑execută secvența până la **N=2** reîncercări (configurabil în CI), fără a altera spiritul SPECS.

**Secvența (pseudocod):**

1. **Context freeze:** preia commit range/branch curent și schimbările propuse în răspuns.
2. **Static checks:** `tsc --noEmit`, `eslint .`, `prettier --check .`, `depcheck`, `npm audit --audit-level=high`.
3. **Build:** `next build` (edge + server/route handlers). Orice warning critic oprește.
4. **Unit & integration:** `vitest run --coverage` + rapoarte (thresholds minime §4).
5. **API contract tests:** rulează suitea `/api/*` contract + MSW.
6. **E2E Playwright:** cu trace/video; subset „smoke” + full „critical user journeys”.
7. **Visual regression:** Playwright screenshot diff pentru grafice/hartă (baseline actualizat doar prin PR aprobat de QA).
8. **A11y & i18n:** axe‑playwright, key‑coverage i18n.
9. **Performance:** Lighthouse CI pe staging (mobil/3G) → LCP, TTI, TBT, CLS sub bugete.
10. **Security gates:** headere, CORS, no secrets; dependency‑vulns = 0 „high/critical”.
11. **Observability sanity:** evenimente OTel prezente; Sentry DSN configurat; erori runtime 0 în logs.
12. **Report:** generează `quality-gate-report.md` cu verdict **PASS/FAIL**, listează testele, acoperirea, difuri vizuale, scoruri perf și a11y, plus „action items”.

**Criterii de calitate verificate automat (stack‑specific + best practices):**

* Next.js: boundaries RSC/Client corecte; Route Handlers stateless; fără blocking I/O în RSC.
* React: hooks corect folosite; keys stabile; evitarea re‑renderurilor; memoization la serii dense.
* TanStack Query: cache keys stabile; `staleTime`/`gcTime` configurate; `select` reduce payload; `retry` rezonabil.
* ECharts: *throttling* la zoom/brush; *progressive rendering* pentru serii lungi; fallback SVG când canvas indisponibil.
* MapLibre: cleanup instanțe; resize observer; accesibilitate (keyboard focus, aria for controls custom).
* API/DB: zod validation; rate limiting; SQL parametrizat; planuri index corecte; timescaledb hypertables; materializate refreshată după ETL.
* ETL: idempotency, backoff, time‑zone handling; p1–p99 winsorization; `qa_flag` aplicat; %coverage calculat.
* A11y/i18n: WCAG AA; imagini/diagrams cu alt text; RO/EN 100%.
* Perf: bugete respectate; payload inițial <200 KB; lazy load pentru hărți/grafice grele.

---

## 7) CI/CD – pipeline (schemă)

**GitHub Actions (etape):**

1. **setup**: `pnpm i` / `npm ci`; cache.
2. **static**: lint, type‑check, prettier, depcheck, audit.
3. **build**: `next build`.
4. **test-unit-int**: `vitest run --coverage`.
5. **test-api-contract**: suite `/api/*` + MSW.
6. **test-e2e**: Playwright (headless, trace on, artifacts upload).
7. **visual-regression**: Playwright screenshots diff.
8. **a11y-i18n**: axe‑playwright + i18n key coverage.
9. **perf**: Lighthouse CI pe preview URL.
10. **quality‑gate**: agregă rapoarte în `quality-gate-report.md`.
11. **deploy**: doar dacă gate=PASS; Vercel + migrations DB (Rel coordonează ferestrele).

**Husky pre‑push:** type‑check + unit tests rapide; **pre‑commit:** eslint + prettier + unit subset.

---

## 8) Contracte de date & teste de schemă

* Teste de migrare (DDL) pentru TimescaleDB/PostGIS; verificări de integritate (FK, enumuri, indici), `hypertable` corect creat.
* Teste contract pentru `measurement`, `agg_*` (tipuri, unități, câmpuri obligatorii), plus *migration snapshot tests*.

---

## 9) Șabloane utile

**PR Template (obligatoriu):**

* [ ] Descriere scurtă
* [ ] Legat de card/issue
* [ ] Criterii de acceptanță
* [ ] Checklist testare: Unit / Integration / E2E / Visual / A11y / Perf
* [ ] Artefacte: trace.zip, screenshots, lighthouse.json
* [ ] Impact perf/a11y/securitate
* [ ] Notă de migrare (dacă este cazul)

**Issue Template (feature):**

* Context, scop
* Criterii de acceptanță
* Matrice de test (link la secțiunea §5)
* Date de test/fixtures

---

## 10) Guvernanță de calitate & raportare

* QA publică **Test Run Report** per PR și per release.
* Obs publică **SLO** (rate job ETL, timpi răspuns API, erori) + alerte.
* OA aprobă doar cu **Quality Gate = PASS** și rapoarte atașate.

---

## 11) Comenzi standard locale

```bash
# static quality
npm run lint && npm run typecheck && npm run format:check && npm run depcheck && npm audit --audit-level=high
# build
npm run build
# unit + integration
npm run test:unit
# api contract
npm run test:api
# e2e (trace/video)
npm run test:e2e
# visual regression
npm run test:visual
# a11y
npm run test:a11y
# lighthouse ci (pe preview url)
npm run test:perf
```

> Nota: scripturile se definesc în `package.json` și sunt reflectate în pipeline‑ul CI/CD (§7). QA păstrează mappingul comenzi → etapă CI.

---

## 12) Anexe – bune practici validate

* Nu se blochează threadul RSC; mută calcule grele pe server/API.
* Nu serializa seturi mari prin RSC; folosește fetch incremental + caching client.
* Memoize pentru serii dense; `immutable ECharts option` pattern.
* Harta se încarcă *lazy*; unmount curat la navigare.
* *Retry/backoff* la fetch extern; circuit‑breaker la căderi WAQI/OpenAQ.

---

**Acest Agents.md este aliniat 1:1 cu SPECS.md și adaugă exclusiv mecanismele de testare, control al calității și bucla de auto‑verificare AI.**