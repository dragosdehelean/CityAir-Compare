# Specificații produs – “CityAir Compare” (București vs. alte capitale foarte poluate, ex. Beijing)

## 1) Obiectiv & public

* **Obiectiv:** o aplicație web care permite **compararea relevantă** a poluării aerului între orașe (ex. București vs. Beijing) pe **ore, zile, săptămâni, luni, anotimpuri**, cu metodologie transparentă și date verificabile.
* **Public țintă:** locuitori ai orașelor, jurnaliști, ONG-uri, cercetători, decidenți locali.
* **Definiții-cheie (explicate succint):**

  * **PM2.5/PM10** – particule în suspensie cu diametrul ≤2.5µm/≤10µm; asociate cu riscuri cardiopulmonare. Praguri de referință **WHO 2021**: PM2.5 anual ≤5 µg/m³; PM10 anual ≤15 µg/m³; 8h O₃ ≤60 µg/m³; NO₂ anual ≤10 µg/m³. ([World Health Organization][1])
  * **AQI (Air Quality Index)** – scală agregată pe poluanți (PM2.5, PM10, O₃, NO₂, SO₂, CO); există **formule naționale** (ex. **AQI SUA** actualizat 2024 pentru PM2.5) și **CAQI** european (versiune orară/zilnică, “roadside”/“background”). ([Environmental Protection Agency][2])

## 2) Surse de date (primare & oficiale)

* **OpenAQ API** – agregator global de măsurători oficiale; endpointuri REST + arhivă istorică. (cheie gratuită; rate limits). ([OpenAQ Docs][3])
* **WAQI (aqicn.org) API** – rețea globală în timp real (token necesar). ([aqicn.org][4])
* **EEA – Air Quality Download Service** (UE) – descărcare programatică date oficiale (inclusiv România). ([European Environment Agency][5])
* **România (RNMCA/ANPM – calitateaer.ro)** – rețeaua națională; București are stații trafic/fond urban. (Integrare prin EEA sau paginile oficiale.) ([calitateaer.ro][6])
* **Meteo pentru context** (temperatură, vânt) – **Open-Meteo** (fără cheie), **CAMS** (reanalize/previziuni aerosoli) pentru analize sezoniere. ([open-meteo.com][7])

> Notă: alegem **doar stații de tip “background urban/suburban”** la comparații implicite (evităm traficul industrial/artere rutiere) pentru fair-play; marcăm altfel în UI.

## 3) Metodologie de comparare (transparență & repetabilitate)

* **Unități & indecși:**

  * Afișare **concentrații brute** (µg/m³) + convertire la **AQI SUA** și **CAQI** (utilizatorul poate comuta). ([Environmental Protection Agency][2])
  * **Mod “WHO compliance”**: raportare la ghidurile WHO 2021 (ex. % ore/ zile peste prag). ([PMC][8])
* **Agregări temporale (locale):** orar → zilnic (mediană), săptămânal (medie ponderată), lunar/sezonier (mediană lunară), cu **timezone local** al orașului.
* **Sezonalitate & diurn:**

  * **Seasons** după emisfera orașului; **diurnal** pe oră locală (boxplot/ridgeline).
* **Calitate date:** excludere valori negative/nule; **winsorization** pe percentila 1–99; marcăm **“data coverage”** (% ore lipsă).
* **Selecția stațiilor:** default “background”; opțional filtre “traffic/industrial”; **mix egal** pe oraș (pondere egală stații valide).
* **Documentare in-app:** drawer “Metodologie & surse” cu linkuri către **OpenAQ**, **WAQI**, **WHO**, **EPA**, **EEA**. ([OpenAQ Docs][3])

## 4) Experiență utilizator (UX)

* **Ecran principal – “Compare”**

  * Selector orașe (București preset + listă capitale), poluant (PM2.5 default), perioadă (ultimele 24h/7z/30z/12l/ultime 5 sezoane), index (AQI/CAQI/WHO).
  * **Grafic sincronizat** (multi-serie) cu zoom + brush; **calendar heatmap** (zi/oră); **diurnal profile** (radar/rose).
  * **“Fairness toggles”**: *Background only*, *Same local time*, *Normalize by WHO*.
  * **Indicatori rapizi**: medie, mediană, p95, % depășiri WHO, “worst hour”, “best month”.
* **Harta stațiilor** (MapLibre GL): lagărează stațiile folosite; filtre pe tip stație. ([maplibre.org][9])
* **City cards**: scurt profil (altitudine, climă, surse dominante – user-facing, fără afirmații speculative).
* **Export reproducibil**: CSV/PNG + “method snapshot” (interval, surse, filtre).
* **Accesibilitate & i18n**: RO/EN; contrast AA; descrieri pentru screen readers.

## 5) Stack tehnic (Next.js + React) – alegere justificată

* **Frontend:** **Next.js 15.x (App Router, RSC, Turbopack)** + **React 19.2** (features recente de performanță). ([nextjs.org][10])
* **Date client:** **TanStack Query** (cache, revalidare, retry, suspense-ready). ([tanstack.com][11])
* **Grafică:** **Apache ECharts** pentru heatmap, ridgeline, linii dense (canvas/SVG switch). ([echarts.apache.org][12])
* **Hartă:** **MapLibre GL JS** (open-source, tiles libere/ieftine). ([maplibre.org][9])
* **Backend & ETL:**

  * **API Next.js (Route Handlers)** + **cronuri Vercel** pentru ingest orară (OpenAQ/WAQI/EEA). ([Vercel][13])
  * **DB:** PostgreSQL + **TimescaleDB** (hypertables) + **PostGIS** (bbox orașe); cache **Redis** pentru serii agregate. ([tigerdata.com][14])
* **Observabilitate:** OpenTelemetry, Sentry; logs cron (Vercel). ([Vercel][15])
* **Deploy:** Frontend/edge pe Vercel; DB gestionat (Neon/Timescale Cloud); chei API în Vercel Env.

### Schelet minimal de directoare

```
/app
  /(compare)/page.tsx           // main compare view (RSC + client charts)
  /api/series/route.ts          // REST: time series (bucket, city, pollutant, index)
/lib
  /data-sources/openaq.ts       // fetchers + zod validation
  /data-sources/waqi.ts
  /indexing/aqi-us.ts           // AQI US conversion utils
  /indexing/caqi.ts             // CAQI conversion utils
/components
  CityMultiSelect.tsx
  TimeScaleSwitch.tsx
  Charts/
    LineMultiCity.tsx
    CalendarHeatmap.tsx
    DiurnalRose.tsx
  Map/StationsMap.tsx
```

## 6) Model de date (TimescaleDB)

* `city(id, name, country, tz, lat, lon, bbox, hemisphere)`
* `station(id, city_id, provider, type enum{background,traffic,industrial}, lat, lon, active)`
* `measurement(id, station_id, ts, pollutant enum{pm25,pm10,o3,no2,so2,co}, value, unit, qa_flag)`
* **Materializate**: `agg_hour(city_id, pollutant, ts_local, p50, p95, n)`, `agg_day`, `agg_month`, `agg_season`.
* **Indici**: hypertable pe `measurement(ts)`, dimensionare pe `station_id`; particionare secundară pe `pollutant`.

## 7) API (contract public)

* `GET /api/cities?q=Bucharest`
* `GET /api/series?cities=Bucharest,Beijing&pollutant=pm25&from=2025-01-01&to=2025-10-31&bucket=hour&index=aqi_us&stationType=background&local=1`
* `GET /api/diurnal?cities=..&month=1-12`
* `GET /api/coverage?cities=..` (raport calitate date)
* **Răspuns**: `{ meta:{source:["OpenAQ","WAQI","EEA"], index:"AQI_US", ...}, series:[{city, tz, points:[{t,v},..]}] }`

## 8) ETL & actualizare

* **Frecvență:** orar (cron), + job zilnic pentru agregări lunare/sezoniere. **Vercel Cron** + route functions. ([Vercel][13])
* **Ordine:** fetch → validare (zod) → conversie unități → scriere bulk → refresh materializate → invalidare cache.
* **Surse primare:** OpenAQ (prioritar), WAQI (fallback/completare), EEA (UE – istoric & QC). ([OpenAQ Docs][3])

## 9) Ecranări & corectitudine

* **Comparabilitate implicită:** (a) doar **background**; (b) **aceleași ferestre** de timp local; (c) afișează **% acoperire**.
* **Afișare erori:** banner dacă <70% acoperire/zi; icon per oraș pentru date estimate.
* **Disclaimere licențe:** menționăm sursa și licența (OpenAQ—open data; WAQI—token; EEA—politici Eionet). ([OpenAQ Docs][3])

## 10) UI componente (React)

* **CompareHeader** (selectors), **KPIBar**, **SyncLineChart** (ECharts), **CalendarHeatmap**, **DiurnalProfile**, **StationsMap** (MapLibre), **MethodologyDrawer** (citări inline).
* **State:** TanStack Query + URL params ca “source of truth” (deep-linking).

## 11) Performanță & calitate

* **LCP < 2.5s**, **TTI < 3s** pe conexiune 3G; payload < 200KB inițial; streaming RSC.
* **Testare:** unit (utils AQI/CAQI), integrare (API routes), vizual (Playwright).
* **Observabilitate:** tracing request-id până la fetch sursă; alerte cron eșuate.

## 12) Securitate & confidențialitate

* Numai date publice; **rate-limiting** pe API; chei surse în env; CORS restrictiv; audit third-party.

## 13) Roadmap (MVP → +90 zile)

* **MVP (4–6 săpt.):** Compare (PM2.5), București vs. 1–2 orașe preset, 3 vizualizări (linie, calendar, diurnal), export CSV/PNG, metodologie.
* **v1:** multi-poluant, filtre stații, profil oraș, EEA ingest istoric.
* **v1.1:** corelare cu meteo (vânt, inversiuni), “bad days explainer”, embed card.

---

### De ce aceste alegeri?

* **Next.js 15.x + React 19.2** oferă RSC, streaming și Turbopack pentru livrare rapidă; React 19.2 este actualul release stabil. ([nextjs.org][10])
* **ECharts** gestionează volume mari (canvas/SVG) și heatmap-uri; **MapLibre** evită licențe restrictive; **TanStack Query** simplifică cache/revalidare. ([echarts.apache.org][12])
* **OpenAQ/WAQI/EEA** acoperă global + UE + România (oficial), iar **WHO/EPA/CAQI** oferă referințe comparabile și verificabile. ([OpenAQ Docs][3])

Dacă vrei, pot genera direct **skeleton-ul Next.js** (App Router) cu ECharts + MapLibre + TanStack Query și două endpointuri `/api/cities` & `/api/series`, ori pot livra **schema SQL TimescaleDB** (DDL) cu `hypertable` și `materialized views`. Ce preferi să vezi prima dată?

[1]: https://www.who.int/publications/i/item/9789240034228?utm_source=chatgpt.com "WHO global air quality guidelines: particulate matter (‎PM2. ..."
[2]: https://www.epa.gov/system/files/documents/2024-02/pm-naaqs-air-quality-index-fact-sheet.pdf?utm_source=chatgpt.com "Final Updates to the Air Quality Index (AQI) for Particulate ..."
[3]: https://docs.openaq.org/?utm_source=chatgpt.com "OpenAQ Docs: OpenAQ API Docs"
[4]: https://aqicn.org/api/?utm_source=chatgpt.com "Air Quality Programmatic APIs"
[5]: https://www.eea.europa.eu/en/datahub/datahubitem-view/778ef9f5-6293-4846-badd-56a29c70880d?utm_source=chatgpt.com "Air Quality download service - European Environment Agency"
[6]: https://www.calitateaer.ro/?utm_source=chatgpt.com "Calitate Aer | Acasă"
[7]: https://open-meteo.com/en/docs/historical-weather-api?utm_source=chatgpt.com "️ Historical Weather API"
[8]: https://pmc.ncbi.nlm.nih.gov/articles/PMC8920460/?utm_source=chatgpt.com "World Health Organization air quality guidelines 2021"
[9]: https://www.maplibre.org/maplibre-gl-js/docs/?utm_source=chatgpt.com "MapLibre GL JS"
[10]: https://nextjs.org/blog?utm_source=chatgpt.com "Next.js by Vercel - The React Framework"
[11]: https://tanstack.com/query?utm_source=chatgpt.com "TanStack Query"
[12]: https://echarts.apache.org/?utm_source=chatgpt.com "Apache ECharts"
[13]: https://vercel.com/docs/cron-jobs?utm_source=chatgpt.com "Cron Jobs"
[14]: https://www.tigerdata.com/learn/best-practices-time-series-data-modeling-single-or-multiple-partitioned-tables-aka-hypertables?utm_source=chatgpt.com "Best Practices for Time-Series Data Modeling: Single or ..."
[15]: https://vercel.com/docs/cron-jobs/manage-cron-jobs?utm_source=chatgpt.com "Managing Cron Jobs"
