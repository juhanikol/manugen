// Keep the release listing usable when scripting or the GitHub API is unavailable.
const TEXT = {
  fi: {
    none: 'Ensimmäinen varsinainen Windows-julkaisu on vielä valmisteilla.',
    missing: 'Uusimpaan julkaisuun ei ole liitetty Windows-asennustiedostoa.',
    download: 'Lataa Windows-asennustiedosto ↓'
  },
  en: {
    none: 'The first Windows release is still in preparation.',
    missing: 'The latest release has no Windows installer attached.',
    download: 'Download the Windows installer ↓'
  }
};

async function showInstaller() {
  const text = TEXT[document.documentElement.lang] || TEXT.fi;
  const status = document.querySelector('#availability');
  try {
    const response = await fetch('https://api.github.com/repos/juhanikol/manugen/releases/latest');
    if (response.status === 404) {
      status.textContent = text.none;
      return;
    }
    if (!response.ok) return;
    const release = await response.json();
    const installer = release.assets.find(asset => asset.name === 'MANUgen-setup.exe' && asset.state === 'uploaded');
    if (!installer) {
      status.textContent = text.missing;
      return;
    }
    const button = document.querySelector('#release');
    button.href = 'https://github.com/juhanikol/manugen/releases/latest/download/MANUgen-setup.exe';
    button.textContent = text.download;
    status.textContent = release.tag_name + ' · MANUgen-setup.exe';
  } catch {
    // Network and rate-limit failures leave the static link in place.
  }
}
showInstaller();
