// Keep the release listing usable when scripting or the GitHub API is unavailable.
async function showInstaller() {
  const status = document.querySelector('#availability');
  try {
    const response = await fetch('https://api.github.com/repos/juhanikol/manugen/releases/latest');
    if (response.status === 404) {
      status.textContent = 'Ensimmäinen varsinainen Windows-julkaisu on vielä valmisteilla.';
      return;
    }
    if (!response.ok) return;
    const release = await response.json();
    const installer = release.assets.find(asset => asset.name === 'MANUgen-setup.exe' && asset.state === 'uploaded');
    if (!installer) {
      status.textContent = 'Uusimpaan julkaisuun ei ole liitetty Windows-asennustiedostoa.';
      return;
    }
    const button = document.querySelector('#release');
    button.href = 'https://github.com/juhanikol/manugen/releases/latest/download/MANUgen-setup.exe';
    button.textContent = 'Lataa Windows-asennustiedosto ↓';
    status.textContent = release.tag_name + ' · MANUgen-setup.exe';
  } catch {
    // Network and rate-limit failures leave the static link in place.
  }
}
showInstaller();
