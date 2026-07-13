# Politieke tool Render wrapper

Publieke wrapper zonder dossierdata. Render gebruikt deze repository alleen om de private repository
`jonathanvanderelst1997/politieke-tool-jonathan` read-only te klonen via een deploy key.

## Vereiste Render environment variables

- `GH_DEPLOY_KEY_B64`
- `POLITIEK_ONLINE_AUTH_USER`
- `POLITIEK_ONLINE_AUTH_PASSWORD` — minimaal 16 tekens aanbevolen, alleen in Render bewaren
- `POLITIEK_META_APP_ID`
- `POLITIEK_META_APP_SECRET`
- `POLITIEK_META_CONFIG_ID`

## Sessiebeveiliging

`start.sh` houdt loginwachtwoord en sessieondertekening gescheiden:

- bij iedere processtart wordt een nieuwe willekeurige 384-bit bootnonce gemaakt;
- als Render een persistent `POLITIEK_SESSION_SECRET` bevat, dient dat alleen als HMAC-basissleutel;
- de effectieve sessiesleutel wordt uit de basissleutel en bootnonce afgeleid en roteert dus bij elke herstart;
- zonder persistente basissleutel wordt de willekeurige bootnonce rechtstreeks als effectieve sleutel gebruikt;
- `POLITIEK_SESSION_VERSION` staat standaard op `2026-07-13-v3`;
- iedere herstart of versiewijziging maakt bestaande sessies ongeldig;
- geen enkele sleutel wordt gelogd, gecommit of op schijf opgeslagen.

Een persistent Render-geheim blijft nuttig als extra sleutelcomponent, maar is niet vereist voor rotatie. Het mag nooit gelijk worden behandeld als het loginwachtwoord.

## Deploycontrole

De build logt alleen de SHA van de gekloonde private commit als `PRIVATE_APP_COMMIT` en bewaart die in `.render-private-commit`. De private gateway vergelijkt die marker bij opstart met de werkelijke Git HEAD en publiceert de geverifieerde waarde als healthheader `X-Politiek-Commit`. Bij ontbrekende of afwijkende provenance weigert de gateway te starten.

De productiecontrole staat in de private repository:

```bash
POLITIEK_EXPECTED_COMMIT=<private-main-sha> npm run test:live-security
```

De live workflow slaagt pas na drie opeenvolgende responses met exact die commit. Zonder CI-inloggeheimen controleert ze de ongeauthenticeerde grens; met `POLITIEK_LIVE_TEST_USER` en `POLITIEK_LIVE_TEST_PASSWORD` controleert ze ook login, CSRF en logout.

Render volgt deze wrapperrepository en niet rechtstreeks private `main`. Tot de automatische cross-repository-trigger uit private issue #15 is ingericht, vormt deze expliciete wrapperupdate de auditeerbare deploytrigger.

## Laatste gevraagde private deploy

- Private commit: `78230d5c7869b48ab62211c7794e1271165629b0`
- Doel: de centrale AI Hub, alle zeventien runtime-dossiers, de actuele Stad/OCMW Antwerpen Mail 2-template en fail-closed exacte deploymentprovenance samen uitrollen.
