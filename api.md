# KRÉTA Mobile API dokumentáció

## Általános információk

**Alap URL:** `{iskola_url}/ellenorzo/v3/`
Az `iskola_url` az aktív intézmény URL-je

**API kulcs (minden kérésnél header-ben):** `apiKey: 21ff6c25-d1da-4a68-a811-c881a6057463`

**Authentikáció:** automatikusan kezeli a `TokenRefreshAuthenticator`

**Dátumformátum:** `KeszitesDatuma`, `Datum`, stb.

---

## Bejelentkezési folyamat (OAuth 2.0)

### IdP (Identity Provider) végpontok

| Végpont | URL |
|---|---|
| Engedélyezés (authorize) | `{idpBaseUrl}connect/authorize` |
| Token csere / frissítés | `{idpBaseUrl}connect/token` |
| Munkamenet befejezése | `{idpBaseUrl}connect/endsession` |

> Az `idpBaseUrl` az `IdpConfiguration` `host` + `path` mezőiből áll össze (pl. `https://idp.e-kreta.hu/`).

### Hitelesítési állapotok

| Állapot | Leírás |
|---|---|
| `LoggedOut` | Nincs bejelentkezett felhasználó |
| `LoggingIn` | Bejelentkezés folyamatban (böngésző/WebView nyitva) |
| `LoggedIn` | Sikeres bejelentkezés, aktív munkamenet |
| `TokenExpired` | Az access token lejárt, frissítés szükséges |
| `ExtendingToken` | Token frissítés folyamatban (`getFreshToken()`) |
| `AuthenticationFailed` | Sikertelen bejelentkezés (ok: `AuthenticationException.Reason`) |

### Hibaokok (`AuthenticationException.Reason`)

| Ok | Leírás |
|---|---|
| `BAD_CREDENTIALS` | Hibás felhasználónév/jelszó (4xx client error) |
| `NO_RIGHT_TO_USE_APP` | Nincs jogosultsága az alkalmazás használatához (403 Forbidden) |
| `NOT_SUPPORTED_PROFILE` | Nem támogatott felhasználói szerepkör |
| `CLIENT_TIME_IS_OUT_SYNC_ERROR` | Az eszköz rendszerórája szinkronban van a token lejáratával |
| `CANCEL_SESSION` | Felhasználó vagy a rendszer megszakította a munkamenetet |

### Token struktúra (`AuthenticationToken`)

| Mező | Típus | Leírás |
|---|---|---|
| `id` | String | Profil azonosítója (elsődleges kulcs) |
| `tokenType` | String | Token típusa (pl. `Bearer`) |
| `accessToken` | JWToken | Access token (JWT), tartalmazza: `kreta:user_name`, `kreta:institute_code` |
| `refreshToken` | String | Refresh token a token frissítéshez |
| `idToken` | JWToken? | ID token (OIDC, opcionális) |
| `retryCount` | Int | Sikertelen frissítési kísérletek száma |
| `extra` | String? | Extra mező |

### Token frissítés (`getToken` / `getFreshToken`)

- Ha az access token érvényes és `forceRefresh = false`: a tárolt tokent adja vissza.
- Ha lejárt vagy `forceRefresh = true`: `getFreshToken()` hívja az AppAuth token refresh mechanizmust (`POST {idpBaseUrl}connect/token` a refresh tokennel).
- Sikerrel az új tokeneket elmenti a `AuthenticationTokenDao`-ba.
- Ha a frissítés is sikertelen: `TokenExpired` állapotba kerül, újra kell bejelentkezni.

---

## Push értesítési API (Notification API v3)

**Alap URL:** `https://kretaglobalmobileapi2.ekreta.hu/api/v3/`

**API kulcs (DELETE, PUT):** `apiKey: 7856d350-1fda-45f5-822d-e1a2f3f1acf0`

**POST regisztrációhoz:** Bearer token szükséges (`@Authentication` annotáció, automatikus hozzáadás)

Az értesítési rendszer Firebase Cloud Messaging (FCM) alapú. A regisztrációt a `NotificationRepositoryImpl` kezeli a `NotificationApiV3` Retrofit interfészen keresztül.

---

### `POST Registration` – Feliratkozás push értesítésekre

Regisztrálja az eszközt az adott profilhoz push értesítések fogadására.

**Query paraméterek:**

| Paraméter | Típus | Alapértelmezett | Leírás |
|---|---|---|---|
| `Handle` | String | – | Firebase FCM token |
| `NotificationRole` | Int | profil alapján | Szerepkör (`NotificationMessageRole`) |
| `NotificationEnvironment` | String | profil alapján | Környezet (`Tanulo_Native` / `Gondviselo_Native`) |
| `Platform` | String | `fcmv1` | Platform azonosító |
| `NotificationType` | Int | `1` (ALL) | Értesítési típusok bitmaskja (`NotificationMessageType`) |
| `NotificationSource` | String | `Kreta` | Forrás (`Kreta` / `EUgyintezes`) |

**Válasz:**

```json
{
  "registrationId": "<uuid>"
}
```

---

### `DELETE Registration` – Leiratkozás push értesítésekről

Törli az eszköz regisztrációját.

**Query paraméterek:**

| Paraméter | Típus | Leírás |
|---|---|---|
| `RegistrationId` | String | A regisztrációkor kapott `registrationId` |
| `NotificationRole` | Int | Szerepkör értéke |
| `NotificationEnvironment` | String | Környezet értéke |
| `NotificationType` | Int | Értesítési típus bitmask |
| `NotificationSource` | String | Forrás |

**Válasz:** üres body (`ResponseBody`)

---

### `PUT Registration` – Regisztráció frissítése (token csere)

Frissíti a meglévő regisztrációt (pl. ha az FCM token megváltozott).

**Query paraméterek:**

| Paraméter | Típus | Leírás |
|---|---|---|
| `RegistrationId` | String | Meglévő regisztráció azonosítója |
| `Handle` | String | Új FCM token |
| `NotificationRole` | Int | Szerepkör értéke |
| `NotificationEnvironment` | String | Környezet értéke |
| `NotificationType` | Int | Értesítési típus bitmask |
| `NotificationSource` | String | Forrás |

**Válasz:** üres body (`ResponseBody`)

---

### Enum értékek

#### `NotificationEnvironment` (query string értéke)

| Enum | Érték |
|---|---|
| `STUDENT` | `Tanulo_Native` |
| `GUARDIAN` | `Gondviselo_Native` |

#### `NotificationMessageRole` (egész szám)

| Enum | Érték |
|---|---|
| `STUDENT` | `1` |
| `GUARDIAN` | `2` |
| `BOTH` | `3` |

#### `NotificationMessageType` (bitmask – 2 hatványa)

| Enum | Bit érték | Leírás |
|---|---|---|
| `ALL` | `1` | Összes értesítési típus |
| `EVALUATION` | `2` | Értékelés (jegy) |
| `OMISSION` | `4` | Hiányzás |
| `NOTE` | `8` | Feljegyzés |
| `MESSAGE` | `16` | Üzenet |
| `TASK` | `32` | Feladat |
| `EXAM` | `64` | Dolgozat |
| `LESSONS` | `128` | Órarendi változás |
| `ACCESS_CONTROL_SYSTEM` | `256` | Beléptetőrendszer |

#### `NotificationSource` (query string értéke)

| Enum | Érték |
|---|---|
| `KRETA` | `Kreta` |
| `EUGYINTEZES` | `EUgyintezes` |

---

### Firebase (FCM) push üzenet payload

| FCM data kulcs | Típus | Leírás |
|---|---|---|
| `InstituteCode` | String | Intézménykód |
| `UserId` | Int (String) | Felhasználó azonosítója |
| `NotificationType` | Int (String) | Értesítési típus bitmask |
| `NotificationRole` | Int (String) | Szerepkör értéke |
| `NotificationSource` | String | Forrás (`Kreta` / `EUgyintezes`) |
| `ItemId` | Int (String) | Érintett elem azonosítója |
| `Message` | String | Értesítés szöveges tartalma |
| `MessageId` | String | Üzenet egyedi azonosítója |
| `Title` | String | Értesítés címe |
| `Data` | String (JSON) | Extra adat (pl. feladatnál `TaskData`) |

**`TaskData` struktúra** (a `Data` mező JSON-ja, feladat típusú értesítésnél):

| JSON mező | Típus | Leírás |
|---|---|---|
| `FeladatTipusId` | Int | Feladat típusa (`TaskTypeId`) |
| `FeladatDatum` | String? | Feladat határideje |

**`TaskTypeId` értékek:**

| Enum | Leírás |
|---|---|
| `NOT_DEFINED_TASK` | Ismeretlen/nem definiált |
| `HOMEWORK_TASK` | Házi feladat |
| `CLASSWORK_TASK` | Osztálymunka |
| `ELEARNING_TASK` | E-learning feladat |
| `LANGUAGE_LEARNING_TASK` | Nyelvtanulási feladat |

---

**`SubscriptionForPushNotification` (helyi DB rekord):**

| Mező | Típus | Leírás |
|---|---|---|
| `uid` | String | Regisztráció azonosítója (a szerver adja) |
| `profileId` | String | Profil azonosítója |
| `notificationRole` | `NotificationMessageRole` | Szerepkör |
| `token` | String | FCM token |
| `notificationMessageType` | Int | Aktív értesítési típus bitmask |

---

## GET végpontok

### `GET sajat/TanuloAdatlap`
Visszaadja a bejelentkezett tanuló személyes adatait.

| Mező (JSON) | Típus | Leírás |
|---|---|---|
| `Uid` | String | Tanuló egyedi azonosítója |
| `Nev` | String | Tanuló neve |
| `SzuletesiNev` | String | Születési neve |
| `SzuletesiHely` | String | Születési hely |
| `SzuletesiEv` | Int | Születési év |
| `SzuletesiHonap` | Int | Születési hónap |
| `SzuletesiNap` | Int | Születési nap |
| `AnyjaNeve` | String | Anyja neve |
| `EmailCim` | String? | E-mail cím |
| `Telefonszam` | String? | Telefonszám |
| `Cimek` | String[] | Lakáscímek listája |
| `IntezmenyNev` | String | Intézmény neve |
| `IntezmenyAzonosito` | String | Intézmény kódja |
| `TanevUid` | Long | Aktív tanév azonosítója |
| `Intezmeny` | Object | Intézmény részletes adatai (ld. InstitutionDto) |
| `Gondviselok` | Object[] | Gondviselők listája (ld. GuardianDto) |
| `Bankszamla` | Object | Bankszámla adatok: `BankszamlaSzam`, `BankszamlaTulajdonosNeve`, `BankszamlaTulajdonosTipusId`, `IsReadOnly` |

---

### `GET sajat/Ertekelesek`
Értékelések (jegyek, szöveges értékelések) lekérése. Opcionális szűrők: `datumTol`, `datumIg`.

| Mező (JSON) | Típus | Leírás |
|---|---|---|
| `Uid` | String | Értékelés azonosítója |
| `SzovegesErtek` | String | Szöveges értékelés (pl. "Jeles(5)") |
| `SzovegesErtekelesRovidNev` | String? | Rövidítés (pl. "Jl") |
| `SzamErtek` | Int? | Numerikus érték (1–5) |
| `SulySzazalekErteke` | String? | Súly százalékban |
| `Jelleg` | String? | Jelleg (pl. "Evközi") |
| `ErtekeloTanarNeve` | String | Értékelő tanár neve |
| `RogzitesDatuma` | String | Rögzítés dátuma |
| `KeszitesDatuma` | String | Létrehozás dátuma |
| `LattamozasDatuma` | String? | Gondviselő általi megtekintés dátuma |
| `Tema` | String? | Téma |
| `Tipus` | Object | Típus: `{Uid, Nev, Leiras}` (pl. "évközi jegy") |
| `ErtekFajta` | Object | Értékfajta: `{Uid, Nev, Leiras}` (pl. "Osztályzat") |
| `Mod` | Object? | Mód: `{Uid, Nev, Leiras}` |
| `Tantargy` | Object | Tantárgy: `{Uid, Nev, Kategoria: {Uid, Nev}}` |
| `OsztalyCsoport` | Object | Osztálycsoport: `{Uid}` |
| `SortIndex` | Int | Sorrend |

---

### `GET sajat/Ertekelesek/Atlagok/OsztalyAtlagok`
Osztályátlagok tantárgyanként. Kötelező: `oktatasiNevelesiFeladatUid`, opcionális: `tantargyUid`.

| Mező (JSON) | Típus | Leírás |
|---|---|---|
| `Uid` | String | Azonosító |
| `TanuloAtlag` | BigDecimal? | A tanuló átlaga |
| `OsztalyCsoportAtlag` | BigDecimal? | Az osztály átlaga |
| `OsztalyCsoportAtlagtolValoElteres` | BigDecimal? | Eltérés az osztályátlagtól |
| `Tantargy` | Object | Tantárgy: `{Uid, Nev, Kategoria: {Uid, Nev}}` |

---

### `GET sajat/Ertekelesek/Atlagok/TantargyiAtlagok`
Tantárgyi átlagok időbeli alakulással. Kötelező: `oktatasiNevelesiFeladatUid`.

| Mező (JSON) | Típus | Leírás |
|---|---|---|
| `Uid` | String | Azonosító |
| `SortIndex` | Int | Sorrend |
| `Atlag` | BigDecimal? | Átlag értéke |
| `SulyozottOsztalyzatOsszege` | Float? | Súlyozott összes érték |
| `SulyozottOsztalyzatSzama` | Float? | Súlyok összege |
| `Tantargy` | Object | Tantárgy: `{Uid, Nev, Kategoria: {Uid, Nev}}` |
| `AtlagAlakulasaIdoFuggvenyeben` | Object[] | Időbeli átlagalakulás: `[{Atlag: Float, Datum: String}]` |

---

### `GET sajat/Mulasztasok`
Mulasztások listája. Opcionális: `datumTol`, `datumIg`.

| Mező (JSON) | Típus | Leírás |
|---|---|---|
| `Uid` | String | Mulasztás azonosítója |
| `Datum` | String | A mulasztás dátuma |
| `KeszitesDatuma` | String | Rögzítés dátuma |
| `IgazolasAllapota` | String | Igazolás állapota (pl. "Igazolt", "Igazolatlan", "Igazolható") |
| `KesesPercben` | Int? | Késés percben (ha késés, nem hiányzás) |
| `RogzitoTanarNeve` | String | Rögzítő tanár |
| `Tipus` | Object | Mulasztás típusa: `{Uid, Nev, Leiras}` (pl. "Hiányzás", "Késés") |
| `IgazolasTipusa` | Object? | Igazolás típusa: `{Uid, Nev, Leiras}` |
| `Mod` | Object | Mód: `{Uid, Nev, Leiras}` |
| `Tantargy` | Object | Tantárgy: `{Uid, Nev, Kategoria: {Uid, Nev}}` |
| `Ora` | Object | Az óra adatai: `{KezdoDatum, VegDatum, Oraszam?}` |
| `OsztalyCsoport` | Object | Osztálycsoport: `{Uid}` |

---

### `GET sajat/OrarendElemek`
Órarend elemek listája. Opcionális: `datumTol`, `datumIg`.

| Mező (JSON) | Típus | Leírás |
|---|---|---|
| `Uid` | String | Óraelem azonosítója |
| `KezdetIdopont` | String | Kezdési idő |
| `VegIdopont` | String | Befejezési idő |
| `Oraszam` | Int? | Óra sorszáma |
| `OraEvesSorszama` | Int? | Éves sorszám |
| `Nev` | String? | Óra neve |
| `Tema` | String? | Téma |
| `TeremNeve` | String? | Terem neve |
| `TanarNeve` | String? | Tanár neve |
| `HelyettesTanarNeve` | String? | Helyettesítő tanár |
| `Allapot` | Object | Állapot: `{Uid, Nev, Leiras}` (pl. "Elmaradt", "Megtartott") |
| `Tipus` | Object | Óra típusa: `{Uid, Nev, Leiras}` |
| `Tantargy` | Object | Tantárgy: `{Uid, Nev, Kategoria: {Uid, Nev}}` |
| `OsztalyCsoport` | Object | Osztálycsoport: `{Uid, Nev}` |
| `TanuloJelenlet` | Object? | Jelenlét: `{Uid, Nev, Leiras}` |
| `HaziFeladatUid` | String? | Kapcsolódó házi feladat UID-ja |
| `BejelentettSzamonkeresUid` | String? | Kapcsolódó számonkérés UID-ja |
| `IsTanuloHaziFeladatEnabled` | Boolean | Beadható-e házi feladat |
| `IsDigitalisOra` | Boolean | Digitális óra-e |
| `DigitalisEszkozTipus` | String? | Digitális eszköz típusa |
| `DigitalisPlatformTipus` | String? | Platform típusa |
| `Csatolmanyok` | Object[]? | Csatolmányok: `[{Uid, Nev}]` |

---

### `GET sajat/OrarendElem`
Egyetlen órarend elem lekérése. Opcionális: `orarendElemUid`.
Ugyanazokat a mezőket adja vissza mint az `OrarendElemek`.

---

### `GET sajat/Intezmenyek/Hetirendek/Orarendi`
Hetirendek lekérése adott időszakra. Kötelező: `orarendElemKezdoNapDatuma`, `orarendElemVegNapDatuma`.
Visszaad egy `TimeTableWeekDto` listát, amely heti bontásban tartalmazza az órarendeket.

---

### `GET sajat/HaziFeladatok`
Házi feladatok listája. Opcionális: `datumTol`, `datumIg`.

| Mező (JSON) | Típus | Leírás |
|---|---|---|
| `Uid` | String | Feladat azonosítója |
| `RogzitoTanarNeve` | String | Feladatot kiadó tanár |
| `FeladasDatuma` | String | Feladás dátuma |
| `HataridoDatuma` | String | Határidő |
| `RogzitesIdopontja` | String | Rögzítés időpontja |
| `Szoveg` | String? | A feladat leírása |
| `IsTanarRogzitette` | Boolean | Tanár rögzítette-e |
| `IsMegoldva` | Boolean | Megoldottnak jelölve-e |
| `IsTanuloHaziFeladatEnabled` | Boolean | Tanuló be tudja-e adni |
| `IsBeadhato` | Boolean | Beadható-e |
| `IsCsatolasEngedelyezes` | Boolean | Csatolmány feltölthető-e |
| `Tantargy` | Object? | Tantárgy: `{Uid, Nev, Kategoria}` |
| `TantargyNeve` | String? | Tantárgy neve (fallback) |
| `OsztalyCsoport` | Object? | Osztálycsoport: `{Uid}` |
| `Csatolmanyok` | Object[]? | Csatolmányok: `[{Uid, Nev, Tipus}]` |

---

### `GET sajat/HaziFeladatok/{id}`
Egyetlen házi feladat részletei. Ugyanazokat a mezőket adja, mint a lista.

---

### `GET sajat/BejelentettSzamonkeresek`
Bejelentett számonkérések. Opcionális: `Uids` (vesszővel elválasztva), vagy `datumTol`+`datumIg`.

| Mező (JSON) | Típus | Leírás |
|---|---|---|
| `Uid` | String | Azonosító |
| `Datum` | String | A számonkérés dátuma |
| `OrarendiOraOraszama` | Int | Melyik órán van |
| `BejelentesDatuma` | String | Bejelentés dátuma |
| `RogzitoTanarNeve` | String | Rögzítő tanár |
| `Temaja` | String? | Témája |
| `Modja` | Object | Mód: `{Uid, Nev, Leiras}` (pl. "Témazáró dolgozat") |
| `Tantargy` | Object? | Tantárgy: `{Uid, Nev, Kategoria}` |
| `TantargyNeve` | String? | Tantárgy neve (fallback) |
| `OsztalyCsoport` | Object | Osztálycsoport: `{Uid}` |

---

### `GET sajat/Feljegyzesek`
Feljegyzések (pl. tanár megjegyzései a tanulóról). Opcionális: `datumTol`, `datumIg`.

| Mező (JSON) | Típus | Leírás |
|---|---|---|
| `Uid` | String | Azonosító |
| `Cim` | String | Cím |
| `Tartalom` | String | Tartalom (sima szöveg) |
| `TartalomFormazott` | String | Formázott tartalom (HTML) |
| `KeszitoTanarNeve` | String | Létrehozó tanár |
| `Datum` | String | Dátum |
| `KeszitesDatuma` | String | Létrehozás időpontja |
| `LattamozasDatuma` | String? | Gondviselői megtekintés időpontja |
| `Tipus` | Object | Típus: `{Uid, Nev, Leiras}` |
| `OsztalyCsoport` | Object? | Osztálycsoport: `{Uid}` |

---

### `GET sajat/FaliujsagElemek`
Faliújság bejegyzések.

| Mező (JSON) | Típus | Leírás |
|---|---|---|
| `Uid` | String | Azonosító |
| `Cim` | String | Cím |
| `Tartalom` | String | Tartalom |
| `RogzitoNeve` | String | Létrehozó neve |
| `ErvenyessegKezdete` | String | Érvényesség kezdete |
| `ErvenyessegVege` | String | Érvényesség vége |

---

### `GET sajat/OsztalyCsoportok`
A tanuló osztálycsoportjainak listája.

| Mező (JSON) | Típus | Leírás |
|---|---|---|
| `Uid` | String | Azonosító |
| `Nev` | String | Osztálycsoport neve |
| `IsAktiv` | Boolean | Aktív-e |
| `Tipus` | String | Típus |
| `OktatasNevelesiFeladatSortIndex` | Int | Rendezési sorrend |
| `OktatasNevelesiFeladat` | Object | Oktatási feladat: `{Uid, Nev, Leiras}` |
| `OktatasNevelesiKategoria` | Object | Kategória: `{Uid, Nev, Leiras}` |
| `OsztalyFonok` | Object? | Osztályfőnök: `{Uid}` |
| `OsztalyFonokHelyettes` | Object? | Osztályfőnök-helyettes: `{Uid}` |

---

### `GET sajat/Fogadoorak`
Fogadóórák listája tanáronként csoportosítva. Opcionális: `datumTol`, `datumIg`.

**Válasz:** `ConsultingHourListDto[]` – tanáronkénti lista

| Mező (JSON) | Típus | Leírás |
|---|---|---|
| `Tanar` | Object | Tanár: `{Uid, Nev}` |
| `Fogadoorak` | Object[] | Fogadóórák listája (ld. lent) |

Minden fogadóóra (`Fogadoorak` elem):

| Mező (JSON) | Típus | Leírás |
|---|---|---|
| `Uid` | String | Fogadóóra azonosítója |
| `KezdoIdopont` | String | Kezdési idő |
| `VegIdopont` | String | Befejezési idő |
| `JelentkezesHatarido` | String | Jelentkezési határidő |
| `IsJelentkezesFeatureEnabled` | Boolean | Elérhető-e a foglalás |
| `Terem` | Object | Terem: `{Uid, Nev}` |
| `Idopontok` | Object[] | Foglalható időpontok (ConsultingHourTimeSlotDto) |

---

### `GET sajat/Fogadoorak/{uid}`
Egyetlen fogadóóra részletes adatai. Ugyanazokat a mezőket adja mint a lista egy eleme.

---

### `GET sajat/GondviseloAdatlap`
Gondviselő adatlapja.

| Mező (JSON) | Típus | Leírás |
|---|---|---|
| (Guardian4TDto mezői) | | Gondviselő személyes és elérhetőségi adatai |

---

### `GET sajat/Csatolmany/{uid}`
Streaming letöltés – bináris fájl (ResponseBody). Az `uid` az adott csatolmány azonosítója (pl. házi feladatból, órarendből).

---

### `GET sajat/Intezmenyek/TanevRendjeElemek`
A tanév rendjének eseményei (szünetek, ünnepek, rendkívüli napok).

| Mező (JSON) | Típus | Leírás |
|---|---|---|
| `Uid` | String | Azonosító |
| `Datum` | String | Dátum |
| `Naptipus` | Object | Nap típusa: `{Uid, Nev, Leiras}` (pl. "Szünet", "Tanítási nap") |
| `ElteroOrarendSzerintiTanitasiNap` | Object? | Eltérő nap típusa: `{Uid, Nev, Leiras}` |
| `OrarendiNapHetirendje` | Object | Hét típusa: `{Uid, Nev, Leiras}` (pl. "A-hét", "B-hét") |
| `OsztalyCsoport` | Object? | Osztálycsoport: `{Uid}` |

---

### `GET felhasznalok/Alkalmazottak/Tanarok/Osztalyfonokok`
Osztályfőnökök listája. Opcionális: `Uids`.

| Mező (JSON) | Típus | Leírás |
|---|---|---|
| (ClassMasterDto mezői) | | Osztályfőnök neve, UID-ja és osztálya |

---

### `GET Lep/Eloadasok`
LEP (Líceumi Előadássorozat) előadások listája.

| Mező (JSON) | Típus | Leírás |
|---|---|---|
| (LepEventDto mezői) | | Előadás neve, időpontja, helyszíne, gondviselői engedély állapota |

---

### `GET sajat/Elerhetoseg`
A tanuló/gondviselő elérhetőségi adatai (e-mail, telefonszám).

| Mező (JSON) | Típus | Leírás |
|---|---|---|
| `Id` | String | Elérhetőség azonosítója |
| `Email` | String? | E-mail cím |
| `IsEmailMegerositve` | Boolean | Az e-mail megerősített-e |
| `Telefonszam` | String? | Telefonszám |

---

### `GET documents/digitalisbizonyitvanyok`
Digitális bizonyítványok listája.

| Mező (JSON) | Típus | Leírás |
|---|---|---|
| `Id` | Long | Bizonyítvány azonosítója |
| `Megnevezes` | String? | Bizonyítvány neve |
| `TanevNev` | String? | Tanév neve |
| `TipusNev` | String? | Típus neve |
| `KiallitasDatum` | String | Kiállítás dátuma (ISO 8601) |

---

### `GET documents/digitalisbizonyitvanyok/{id}/file`
Digitális bizonyítvány dokumentumának streaming letöltése. Az `id` az integer azonosító.
Visszatér: `Single<Response<ResponseBody>>` (bináris fájl).

---

### `GET Nep/Programok`
NEP (Nemzeti Egységes Platform?) programok/rendezvények listája, amelyekre a tanuló meghívást kapott.

| Mező (JSON) | Típus | Leírás |
|---|---|---|
| `Id` | Int | Program azonosítója |
| `Datum` | String | Program létrehozásának dátuma |
| `Kezdete` | String | Program kezdési időpontja |
| `Vege` | String | Program befejezési időpontja |
| `ProgramNev` | String | Program neve |
| `SzervezetNev` | String | Szervező neve |
| `Helyszin` | String | Helyszín |
| `GondviseloElfogadas` | Boolean? | Gondviselő beleegyezett-e (null = nincs döntés) |
| `Megjelent` | Boolean | Megjelent-e a tanuló |

---

### `GET ejogsi/aktiv`
Aktív szerepkörök lekérdezése.

| Mező (JSON) | Típus | Leírás |
|---|---|---|
| `IsDktRedirectRequired` | Boolean | Szükséges-e DKT-átirányítás |

---

### `GET Sajat/Tanszercsomag`
Tanszercsomag információk lekérése.

| Mező (JSON) | Típus | Leírás |
|---|---|---|
| `IsIgenyelt` | Boolean | Igényelt-e tanszercsomagot |
| `Atvetel` | String? | Átvétel dátuma (ISO 8601) |
| `OsztasKezdete` | String | Osztás kezdete |
| `OsztasVege` | String | Osztás vége |
| `RgykList` | Object[] | Rendszeres gyermekvédelmi kedvezmények listája (ld. lent) |

**`RgykList` elemek (`RegularChildProtectionBenefitDto`):**

| Mező (JSON) | Típus | Leírás |
|---|---|---|
| `Id` | Int | Azonosító |
| `Szam` | String | Kedvezmény igazolás száma |
| `ErvKezdete` | String | Érvényesség kezdete |
| `ErvVege` | String | Érvényesség vége |

---

### `GET TargyiEszkoz/IsRegisztracioEngedelyezett`
Visszaad egy `Boolean` értéket: engedélyezett-e a tárgyieszköz-regisztráció.
_(Korábbi változatban: `GET TargyiEszkoz/IsRegisztralt` és `GET TargyiEszkoz/IsEszkozKiosztva` – ezek eltávolításra kerültek.)_

---

### `GET TargyiEszkoz/Regisztracio`
TESZEK regisztrációs adatok lekérése.

| Mező (JSON) | Típus | Leírás |
|---|---|---|
| (TeszekRegistrationDto mezői) | | Regisztrációs állapot és adatok |

---

## POST / PUT / DELETE végpontok

### `DELETE sajat/Bankszamla`
Bankszámlaszám törlése. Nincs request body, nincs visszatérési érték (Completable).

### `POST sajat/Bankszamla`
Bankszámlaszám mentése.

**Request body:**
| Mező | Típus | Leírás |
|---|---|---|
| `BankszamlaSzam` | String | Bankszámlaszám |
| `BankszamlaTulajdonosNeve` | String | Tulajdonos neve |
| `BankszamlaTulajdonosTipusId` | Int | Tulajdonos típusa |

---

### `POST sajat/Elerhetoseg` (form-urlencoded)
Elérhetőség (e-mail, telefonszám) frissítése.

| Mező | Típus | Leírás |
|---|---|---|
| `email` | String | E-mail cím |
| `telefonszam` | String | Telefonszám |

---

### `POST sajat/Fogadoorak/Idopontok/Jelentkezesek/{uid}`
Fogadóórára való jelentkezés. Az `uid` az időpont azonosítója. Nincs body, nincs visszatérési érték.

### `DELETE sajat/Fogadoorak/Idopontok/Jelentkezesek/{uid}`
Foglalás visszavonása. Nincs body, nincs visszatérési érték.

---

### `PUT sajat/GondviseloAdatlap`
Gondviselő adatlapjának frissítése.

**Request body:** `Guardian4TPostDto` – gondviselő adatai.

---

### `POST Bejelentes/Covid`
COVID bejelentés rögzítése. Nincs body, nincs visszatérési érték.

---

### `POST TargyiEszkoz/Regisztracio`
TESZEK eszköz regisztrálása.

**Request body:** `Guardian4TPostDto`

---

### `POST Lep/Eloadasok/GondviseloEngedelyezes`
Gondviselői engedély adása/visszavonása LEP előadáshoz.

**Request body:** `LepEventGuardianPermissionPostDto`

| Mező | Típus | Leírás |
|---|---|---|
| (LepEventGuardianPermissionPostDto mezői) | | Engedélyezési állapot és az előadás azonosítója |

---

### `POST sajat/Email/Megerosites`
E-mail cím megerősítési kérelem küldése. Nincs request body, nincs visszatérési érték (Completable).

---

### `POST profil/aktiv`
Alkalmazáshasználat jelentése (aktív profil bejelentése). Nincs request body, nincs visszatérési érték.

---

### `POST Nep/Programok/GondviseloEngedelyezes`
Gondviselői beleegyezés adása/visszavonása NEP programhoz.

**Request body:** `NepEventGuardianPermissionPostDto`

| Mező | Típus | Leírás |
|---|---|---|
| `Id` | Int | A program azonosítója |
| `Dontes` | Boolean? | Beleegyezés döntése (true = igen, false = nem, null = visszavonás) |

---

## Egyéb API base URL-ek

| Név | URL |
|---|---|
| Notification API | `https://kretaglobalmobileapi2.ekreta.hu/api/v3/` |
| Ügyintézés API | `https://eugyintezes.e-kreta.hu/api/v1/` |
| IDP (bejelentkezés) | `https://idp.e-kreta.hu/` |
| DKT API | `https://kretadktapi.e-kreta.hu/dktapi/` |
| Global API | `https://kretaglobalapi.e-kreta.hu/` |

## SSO URL-ek

| | URL |
|---|---|
| DKT | `https://dkttanulo.e-kreta.hu/sso` |
| TESZEK | `https://teszek.e-kreta.hu` |
| Xeropan | `https://xeropan.com/dkt-redirect` |
| Étkezés | `https://eugyintezes.e-kreta.hu/kreta-mobil/ebedbefizetes/megrendelesek` |
| Kérdőívek | `https://eugyintezes.e-kreta.hu/kreta-mobil/adatbekeresek` |

---

## Végpontok összefoglalója (újabb verzió)

| Metódus | HTTP | Végpont | Visszatérési típus |
|---|---|---|---|
| `deleteBankAccountNumber` | DELETE | `sajat/Bankszamla` | Completable |
| `deleteReservation` | DELETE | `sajat/Fogadoorak/Idopontok/Jelentkezesek/{uid}` | Completable |
| `downloadAttachment` | GET | `sajat/Csatolmany/{uid}` | Observable\<ResponseBody\> (streaming) |
| `downloadDigitalCertificateDocumentation` | GET | `documents/digitalisbizonyitvanyok/{id}/file` | Single\<Response\<ResponseBody\>\> (streaming) |
| `getAnnouncedTests` | GET | `sajat/BejelentettSzamonkeresek` | Observable\<List\<AnnouncedTestDto\>\> |
| `getClassAverage` | GET | `sajat/Ertekelesek/Atlagok/OsztalyAtlagok` | Observable\<List\<ClassAverageDto\>\> |
| `getClassMaster` | GET | `felhasznalok/Alkalmazottak/Tanarok/Osztalyfonokok` | Observable\<List\<ClassMasterDto\>\> |
| `getConsultingHour` | GET | `sajat/Fogadoorak/{uid}` | Observable\<ConsultingHourDto\> |
| `getConsultingHours` | GET | `sajat/Fogadoorak` | Observable\<List\<ConsultingHourListDto\>\> |
| `getContact` | GET | `sajat/Elerhetoseg` | suspend → ContactDto |
| `getDigitalCertifications` | GET | `documents/digitalisbizonyitvanyok` | Observable\<List\<DigitalCertificationDto\>\> |
| `getEvaluations` | GET | `sajat/Ertekelesek` | Observable\<List\<EvaluationDto\>\> |
| `getGroups` | GET | `sajat/OsztalyCsoportok` | suspend → List\<GroupDto\> |
| `getGuardian4T` | GET | `sajat/GondviseloAdatlap` | Observable\<Guardian4TDto\> |
| `getHomework` | GET | `sajat/HaziFeladatok/{id}` | Observable\<HomeworkDto\> |
| `getHomeworks` | GET | `sajat/HaziFeladatok` | Observable\<List\<HomeworkDto\>\> |
| `getLEPEvents` | GET | `Lep/Eloadasok` | Observable\<List\<LepEventDto\>\> |
| `getLesson` | GET | `sajat/OrarendElem` | Observable\<LessonDto\> |
| `getLessons` | GET | `sajat/OrarendElemek` | Observable\<List\<LessonDto\>\> |
| `getNepEvents` | GET | `Nep/Programok` | Observable\<List\<NepEventDto\>\> |
| `getNotes` | GET | `sajat/Feljegyzesek` | Observable\<List\<NoteDto\>\> |
| `getNoticeBoardItems` | GET | `sajat/FaliujsagElemek` | Observable\<List\<NoticeBoardItemDto\>\> |
| `getOmissions` | GET | `sajat/Mulasztasok` | Observable\<List\<OmissionDto\>\> |
| `getRegistrationEnabled` | GET | `TargyiEszkoz/IsRegisztracioEngedelyezett` | Observable\<Boolean\> |
| `getRoles` | GET | `ejogsi/aktiv` | Single\<RolesDto\> |
| `getSchoolYearCalendar` | GET | `sajat/Intezmenyek/TanevRendjeElemek` | Observable\<List\<SchoolYearCalendarEntryDto\>\> |
| `getStudent` | GET | `sajat/TanuloAdatlap` | suspend → StudentDto |
| `getStudyKit` | GET | `Sajat/Tanszercsomag` | Observable\<StudyKitDto\> |
| `getSubjectAverage` | GET | `sajat/Ertekelesek/Atlagok/TantargyiAtlagok` | Observable\<List\<SubjectAverageDto\>\> |
| `getTeszekRegistration` | GET | `TargyiEszkoz/Regisztracio` | Observable\<TeszekRegistrationDto\> |
| `getTimeTableWeeks` | GET | `sajat/Intezmenyek/Hetirendek/Orarendi` | Observable\<List\<TimeTableWeekDto\>\> |
| `postBankAccountNumber` | POST | `sajat/Bankszamla` | Completable |
| `postContact` | POST | `sajat/Elerhetoseg` | Completable |
| `postCovidForm` | POST | `Bejelentes/Covid` | Completable |
| `postEmailVerification` | POST | `sajat/Email/Megerosites` | Completable |
| `postReservation` | POST | `sajat/Fogadoorak/Idopontok/Jelentkezesek/{uid}` | Completable |
| `postTeszekRegistration` | POST | `TargyiEszkoz/Regisztracio` | Completable |
| `reportAppUsage` | POST | `profil/aktiv` | Completable |
| `updateGuardian4T` | PUT | `sajat/GondviseloAdatlap` | Completable |
| `updateLepEventPermission` | POST | `Lep/Eloadasok/GondviseloEngedelyezes` | Completable |
| `updateNepEventPermission` | POST | `Nep/Programok/GondviseloEngedelyezes` | Completable |