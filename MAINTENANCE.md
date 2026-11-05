# MANUgen-julkaisujen ylläpito

## Ota sivusto käyttöön kerran

1. Avaa tämän repositorion **Settings → Pages**.
2. Valitse **Build and deployment → Source → Deploy from a branch**.
3. Valitse haara **main**, kansio **/docs** ja paina **Save**.
4. Avaa **Actions**. Kun **pages build and deployment** on valmis, avaa **Settings → Pages → Visit site**.
5. Halutessasi lisää osoite https://juhanikol.github.io/manugen/ myös repon etusivun **About → Website** -kenttään.

## Päivitä sivua

Muokkaa GitHubissa tiedostoa `docs/index.html` kynäkuvakkeella ja tallenna muutos valinnalla **Commit changes**. Kun muutos on main-haarassa, GitHub julkaisee docs-kansion automaattisesti. Värit ja asettelu ovat tiedostossa `docs/style.css`. README.md näkyy repositorion etusivulla englanniksi. Pidä sovelluksen koodi, kehityshistoria, yritysten kirjaukset ja paikalliset asetukset kehitysrepositoriossa.

## Lisää suomenkielinen tallenne

Sijoita asennus osioon **Asenna MANUgen** ja käyttöesimerkki osioon **Havainnosta hyväksytyksi kirjaukseksi**. Näin tallenne löytyy sen työvaiheen vierestä, jota se havainnollistaa. Pidä tekstiohje myös sivulla.

1. Tallenna yksi tehtävä kerrallaan keksityllä esimerkkiaineistolla. Käytä sovelluksen suomenkielisiä valikoita.
2. Avaa GitHubissa **docs/assets → Add file → Upload files**. Lisää esimerkiksi `asennus-fi.gif` tai `kirjaus-fi.gif` ja tallenna.
3. Etsi index.html-tiedostosta kommentti `setup-guide` tai `usage-guide`. Korvaa se vastaavalla linkillä. Esimerkki asennuksesta:

```html
<p><a href="assets/asennus-fi.gif">Katso asennus vaiheittain (GIF)</a></p>
```

Käyttöesimerkissä käytä osoitetta `assets/kirjaus-fi.gif` ja tekstiä ”Katso poikkeaman kirjaaminen (GIF)”. Lisää kesto ja tiedostokoko linkin viereen, kun ne ovat tiedossa. Linkki avaa animaation vasta käyttäjän pyynnöstä. Pidemmälle tallenteelle sopii MP4 ja sivulle upotettu video, jossa on toisto- ja taukopainikkeet.

## Julkaise Windows-asennustiedosto

1. Valmistele kohdekoneella testattu `MANUgen-setup.exe`. Tarkista, että mukana ovat juuri tämän paketin käyttöehdot sekä viimeistellyt kolmansien osapuolten ilmoitukset ja lisenssit.
2. Avaa **Releases → Draft a new release**. Luo versiota vastaava tagi (esimerkiksi `v0.1.0`) ja anna julkaisulle otsikko.
3. Kirjoita julkaisukuvaus: mitä paketti sisältää, mitä ladataan asennuksen jälkeen, laitevaatimukset ja tämän version tunnetut rajoitukset.
4. Vedä asennustiedosto liitealueelle nimellä **MANUgen-setup.exe**. Julkaise varsinainen versio ja valitse se uusimmaksi julkaisuksi (**Latest**).
5. Avaa Pages-sivun Asennus-osio. Varmista lataamalla, että painike tarjoaa oikean version. Tarkista myös julkaisun Assets-listasta tiedoston nimi ja koko.

Sivu tarkistaa GitHubin uusimman varsinaisen julkaisun. Jos liite löytyy, sivu näyttää version ja suoran latauspainikkeen. Esijulkaisut löytyvät julkaisuluettelosta. Jos tarkistus estyy tai JavaScript on pois käytöstä, linkki avaa julkaisuluettelon. Pelkkä uuden version julkaisu riittää päivittämään latauksen.
