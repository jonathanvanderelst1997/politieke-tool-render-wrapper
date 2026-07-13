# Politieke tool Render wrapper

Publieke wrapper zonder dossierdata. Render gebruikt deze repository alleen om de private repository
`jonathanvanderelst1997/politieke-tool-jonathan` read-only te klonen via een deploy key.

## Vereiste Render environment variables

- `GH_DEPLOY_KEY_B64`
- `POLITIEK_ONLINE_AUTH_USER`
- `POLITIEK_ONLINE_AUTH_PASSWORD` — minimaal 16 tekens, alleen in Render bewaren
- `POLITIEK_META_APP_ID`
- `POLITIEK_META_APP_SECRET`
- `POLITIEK_META_CONFIG_ID`

## Sessiebeveiliging

`start.sh` houdt loginwachtwoord en sessieondertekening gescheiden:

- wanneer `POLITIEK_SESSION_SECRET` in Render is ingesteld, wordt dat afzonderlijke geheim gebruikt;
- wanneer het ontbreekt, genereert de wrapper bij elke processtart een willekeurig 384-bit sessiegeheim;
- `POLITIEK_SESSION_VERSION` staat standaard op `2026-07-13-v2`;
- een herstart of versiewijziging maakt bestaande sessies ongeldig;
- het gegenereerde geheim wordt niet gelogd en niet naar GitHub geschreven.

Voor langdurig stabiele sessies kan een afzonderlijk willekeurig `POLITIEK_SESSION_SECRET` in Render worden ingesteld. Het mag nooit gelijk zijn aan het loginwachtwoord.

## Deploycontrole

De build logt alleen de SHA van de gekloonde private commit als `PRIVATE_APP_COMMIT`. Er worden geen private dossiergegevens, deploykeys, wachtwoorden, sessiegeheimen, cookies of tokens gelogd.

De productiecontrole staat in de private repository:

```bash
npm run test:live-security
```

Zonder CI-inloggeheimen controleert die test alleen de ongeauthenticeerde grens. Met de GitHub Actions-secrets `POLITIEK_LIVE_TEST_USER` en `POLITIEK_LIVE_TEST_PASSWORD` controleert ze ook login, CSRF en logout.
