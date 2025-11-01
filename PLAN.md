**Titlu**
- CityAir Compare – Plan de Implementare (bazat pe `SPECS.md` și `AGENTS.md`)

**Scop**
- Operționalizează specificațiile produsului în iterații livrabile, cu testare completă (unit/integration/e2e/visual/a11y/perf) și buclă AI Reviewer.

**Principii**
- Fidelitate la specificații (stack, metodologii, UI/UX, KPI) din `SPECS.md`.
- Test-first unde e fezabil, cu matrice de test conform `AGENTS.md` §4–§5.
- Observabilitate și reproductibilitate: rezultate auditate, surse/date/versiuni documentate.

**Arhitectură (rezumat din `SPECS.md`)**
- Frontend: Next.js 15 (App Router, RSC), React 19.2, TanStack Query.
- Vizualizări: ECharts (linii dense, calendar heatmap, diurnal radar/rose).
- Hartă: MapLibre GL (stații, filtre, clustering, bbox).
- API: Route Handlers `/api/cities`, `/api/series`, `/api/diurnal`, `/api/coverage`.
- DB: PostgreSQL + TimescaleDB (hypertables), PostGIS (bbox), Redis (cache).
- ETL: Vercel Cron, integrare OpenAQ/WAQI/EEA; validare zod, normalizare, winsorization p1–p99, QA flags.
- Observabilitate: OpenTelemetry, Sentry; logs cron.

**Structură Repo (propusă)**
- `app/` (Next.js App Router; pagini RSC și layout-uri)
- `app/api/` (Route Handlers pentru `/cities`, `/series`, `/diurnal`, `/coverage`)
- `features/compare/` (UI principală Compare + subcomponente)
- `components/` (KPIBar, SyncLineChart, CalendarHeatmap, DiurnalProfile, StationsMap, MethodologyDrawer)
- `lib/` (utils: timezones, AQI/CAQI, winsorization, coverage, i18n, zod-schemas)
- `data/` (fixtures, snapshots test, MSW handlers)
- `db/` (migrations SQL: TimescaleDB/PostGIS; seeds controlate)
- `tests/` (unit/integration; `e2e/` Playwright; `visual/` baseline screenshots)
- `scripts/` (CI helpers: quality-gate report aggregation)

**Iterații & Livrabile**
- M0 – Bootstrap & Calitate de bază
  - Setup Next.js 15 + React 19.2 + TS + ESLint + Prettier + Vitest + Playwright + MSW + axe + Lighthouse CI.
  - Scripturi `package.json` identice cu `AGENTS.md` §11; Husky hooks.
  - CI/CD pipeline schematizat în `AGENTS.md` §7 (joburi goale care rulează static checks + build + unit smoke).
  - Acceptanță: rulează `npm run lint`, `npm run typecheck`, `npm run build`, `npm run test:unit` (smoke).

- M1 – Contract API & Schelet DB
  - Definire contracte `/api/cities`, `/api/series`, `/api/diurnal`, `/api/coverage` (zod schemas, tipuri TS, MSW).
  - DDL TimescaleDB/PostGIS: `measurement` (hypertable), indici, materialized views `agg_hour/day/month/season` (schelet), FK/enum-uri.
  - Redis: chei cache și TTL per endpoint; convenții `series:{city}:{pollutant}:{bucket}:{index}:{stationType}:{local}`.
  - Acceptanță: contract tests cu MSW; migrations trec teste de schemă (`AGENTS.md` §8).

- M2 – ETL Minimal (OpenAQ) & Data Fixtures
  - Job cron: ingest orar din OpenAQ (subset: București + 1–2 capitale), validare zod, normalizare unități, winsorization p1–p99, `qa_flag`.
  - Inserție în `measurement`; calcul materializate orare; idempotency (no duplicate on rerun).
  - Fixtures: snapshoturi JSON reduse pentru golden-cases (§4 „Fixtures & date controlate”).
  - Acceptanță: unit tests parseri + integration până în DB (staging); rapoarte coverage minime (
    85% pe utilitare critice, 70% global), `AGENTS.md` §4.

- M3 – UI Compare (schelet) + KPIBar
  - Pagina `Compare`: selectoare oraș/poluanți/interval/index și fairness toggles (stare în URL; TanStack Query ca orchestrator).
  - KPIBar: medie, mediană, p95, %WHO, worst hour, best month (mock data via MSW la început).
  - MethodologyDrawer: surse, linkuri, versiuni metodologie.
  - Acceptanță: unit + integration pentru calcul KPI, i18n RO/EN (coverage 100% chei), a11y basic (axe no violations pe pagină).

- M4 – SyncLineChart (ECharts) + Sincronizare Zoom/Brush
  - Implementare grafic linii multi-serie cu downsampling/throttling; timezone local.
  - Sincronizare zoom/brush între orașe; tooltips corecte; fallback SVG.
  - Baseline vizual: 24h/7z/30z/12l (toleranță Δpixel per chart).
  - Acceptanță: unit (scale/tz/absent data), e2e smoke (zoom/brush), vizual regression PASS.

- M5 – CalendarHeatmap + DiurnalProfile
  - Heatmap zi/oră cu legendă percentile; highlight zile „peste WHO”; click filtrează.
  - Diurnal radar/rose: agregare oră locală; comutare lună/sezon.
  - Acceptanță: unit pentru mapare zi/oră și agregări; e2e pentru interacțiuni; vizual baseline pe anotimpuri diferite.

- M6 – StationsMap (MapLibre) + Filtre stații
  - Încărcare stații folosite de serii; filtre type (background/traffic/industrial), clustering, bbox corect; lazy load + cleanup.
  - Acceptanță: integration pentru filtre, e2e „Background only” reflectă stațiile și sursele seriei; a11y (keyboard + aria descrieri).

- M7 – Integrare API completă + Cache Redis
  - Legare UI la `/api/*` live; TanStack Query keys stabile; `staleTime`/`gcTime`; `select` reduce payload.
  - Redis cache pentru agregări frecvente; invalidare după ETL.
  - Acceptanță: contract tests stable; e2e „critical journeys” – selectare orașe/poluant/perioadă, comutare AQI/CAQI/WHO.

- M8 – Alerte Coverage & Exporturi
  - `/api/coverage` + banner UI pentru <70% acoperire; export CSV/PNG + „method snapshot”.
  - Acceptanță: unit calcul coverage; e2e banner on/off; fișiere descărcabile cu metadate complete.

- M9 – Observabilitate, Securitate, Perf
  - OTel + Sentry DSN; headere securitate, CORS strict, rate-limit; dep audit zero high/critical.
  - Perf budgets: LCP <2.5s, TTI <3s, bundle <200 KB inițial; lazy load grafice/hartă; Lighthouse CI pe preview.
  - Acceptanță: a11y/i18n PASS; perf PASS; security gates PASS.

- M10 – Roadmap v0 → v1 (din `SPECS.md`)
  - v0: flow complet pentru PM2.5 pe 2–3 orașe; fairness toggles; exporturi; baseline vizual stabil.
  - v1: multi-poluant, filtre stații avansate, profil oraș, ingest istoric EEA.

**Matrice Teste (conform `AGENTS.md` §5)**
- Compare & KPIBar: unit KPI, TZ; integrare TanStack+URL; e2e selecții + toggles; a11y AA; perf bugete.
- SyncLineChart: unit scale/TZ/downsampling/absențe; e2e zoom/brush/tooltips; vizual baseline 24h/7z/30z/12l.
- CalendarHeatmap: unit mapare locală/legendă; vizual anotimpuri; e2e highlight WHO + click filter.
- DiurnalProfile: unit agregare locală; e2e comutare lună/sezon.
- StationsMap: integration stații/filtre/clustering/bbox; e2e toggle background; a11y.
- API `/api/series`: unit conversii AQI/CAQI, winsorization, local-time alignment, zod validate; integration query combinat; contract stable.
- API `/api/diurnal`: unit agregări 0–23 locale; integration multi-oraș, multi-month.
- API `/api/coverage`: unit % acoperire + warning; e2e banner.
- Exporturi: e2e CSV/PNG + snapshot metodă.
- ETL: unit parseri/normalizare/validare; integration end-to-end până în Timescale; observabilitate logs/metrice.
- Sezonalitate: unit `seasonOf(date, hemisphere)` teste parametrizate.
- Securitate/i18n/a11y: axe „no violations”, 100% traduceri, CORS strict, fără uploads neautorizate.

**Scripturi NPM (aliniate cu `AGENTS.md` §11)**
- `npm run lint` – ESLint (Next plugin)
- `npm run typecheck` – tsc --noEmit
- `npm run format:check` – prettier --check .
- `npm run depcheck` – depcheck
- `npm run build` – next build
- `npm run test:unit` – vitest run --coverage
- `npm run test:api` – vitest contract tests + MSW/Supertest
- `npm run test:e2e` – playwright test (trace/video)
- `npm run test:visual` – playwright screenshot diff
- `npm run test:a11y` – axe (jest-axe/ct) + axe-playwright
- `npm run test:perf` – Lighthouse CI pe preview URL

**CI/CD Pipeline (executabil incremental)**
- Etape: setup → static → build → test-unit-int → test-api-contract → test-e2e → visual-regression → a11y-i18n → perf → quality-gate → deploy (gated). Conform `AGENTS.md` §7.
- Artefacte: coverage reports, trace.zip, screenshots, lighthouse.json, `quality-gate-report.md`.

**AI Reviewer – Bucla de Auto-Verificare (conform `AGENTS.md` §6)**
- Rulează la fiecare răspuns/PR: static checks, build, unit/integration, API contract, e2e, vizual, a11y/i18n, perf, security, observabilitate.
- Praguri: coverage 85% (critic), 70% global; perf bugete; audit 0 high/critical.
- Verdict PASS/FAIL; pe FAIL → propune remediere și re-execută (max N=2 încercări).

**Detalii Implementare Cheie**
- DB & DDL
  - Tabel `measurement` (hypertable): `id`, `city_id`, `station_id`, `pollutant`, `datetime_utc`, `value_ugm3`, `qa_flag`, `source`.
  - Indici: `time`, `city_id+pollutant+time`, `station_id+time`.
  - Vederi materializate: `agg_hour`, `agg_day`, `agg_month`, `agg_season` (mediană/medie conform metodologiei din `SPECS.md`).
  - PostGIS: bounding boxes orașe; stații cu geom; query pentru map bounds.

- API Contracts
  - `/api/cities` → listă orașe (bbox, tz, hemisferă, meta stații).
  - `/api/series?cities=&pollutant=&from=&to=&bucket=&index=&stationType=&local=` → meta + puncte; validare zod; Redis cache.
  - `/api/diurnal?cities=&pollutant=&month=` → agregare 0–23 local; multi-oraș, multi-month.
  - `/api/coverage?cities=&from=&to=&pollutant=` → % acoperire + warning când <70%.

- Caching & Performanță
  - Chei Redis consistente; `staleTime`/`gcTime` în TanStack Query; `select` pentru reducere payload.
  - ECharts: progressive rendering, throttling zoom/brush, immutable option; fallback SVG.
  - Lazy-load hărți/grafice; bundle inițial <200 KB.

- Securitate & Compliance
  - Rate-limiting pe route handlers; CORS strict; validare input zod; headere securitate; dep audit automat.
  - Management chei API (WAQI/OpenAQ) prin envs securizate; fără leakage în client.

- A11y & i18n
  - WCAG AA; focus order, aria-labels, contrast; teste axe fără violări.
  - i18n RO/EN 100% – snap-tests pentru chei; fallbackuri interzise.

**Definition of Ready (DoR)**
- Descriere clară, criterii de acceptanță măsurabile, matrice de test, fixtures.

**Definition of Done (DoD)**
- Implementare, toate testele verzi, rapoarte perf/a11y, docs actualizate, telemetry adăugată, Quality Gate = PASS.

**Riscuri & Mitigări**
- Rate limits/variații API: MSW pentru testare; backoff + caching; circuit-breaker.
- Lipsă date/coverage redus: banner + fallbackuri UI; explicare metodologică.
- Performanță grafice: downsampling, progressive, memoization; pre-agg în DB.
- Compatibilitate i18n/a11y: audit continuu în CI; checklist QA la PR.

**Backlog Inițial (prioritizat)**
- Bootstrap M0 (tooling + CI), Contracte API M1, DDL+Migrations, ETL minimal M2, Compare+KPI M3, LineChart M4, Heatmap+Diurnal M5, Map M6, Integrare API + Redis M7, Coverage+Exporturi M8, Obs/Sec/Perf M9.

**Note finale**
- Planul respectă 1:1 `SPECS.md` și mechansimele de calitate din `AGENTS.md`.
- Modificările față de plan se fac prin PR mic (sub 400 LOC), cu actualizare corespunzătoare a testelor și a documentației.

