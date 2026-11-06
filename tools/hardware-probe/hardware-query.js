// Windows Script Host JScript, not Node.js. All WMI field lists come from the BAT.
var fs = new ActiveXObject('Scripting.FileSystemObject');
var env = new ActiveXObject('WScript.Shell').Environment('PROCESS');
var output = env('OUTPUT_DIR'), raw = [], report = [], warnings = [];
var GiB = 1073741824, unknown = 'tuntematon';

function write(name, text, ascii) {
    var file = fs.CreateTextFile(fs.BuildPath(output, name), true, !ascii);
    file.Write(text + '\r\n'); file.Close();
}
function value(v) { return v === null || typeof v === 'undefined' || String(v) === '' ? unknown : String(v); }
function numeric(v) { return value(v) === unknown || !isFinite(Number(v)) ? null : Number(v); }
function fixed(v) { return v === null ? unknown : v.toFixed(2); }
function clean(v) { return value(v).replace(/[\r\n]/g, ' '); }
function query(cls, fieldVariable, section) {
    var fields = String(env(fieldVariable));
    if (!/^[A-Za-z0-9_,]+$/.test(fields)) throw new Error('Virheellinen kenttalista: ' + fieldVariable);
    var names = fields.split(','), rows = [];
    for (var e = new Enumerator(wmi.ExecQuery('SELECT ' + fields + ' FROM ' + cls)); !e.atEnd(); e.moveNext()) {
        var row = {}, object = e.item();
        raw.push('[' + section + '.' + rows.length + ']');
        for (var n = 0; n < names.length; n++) {
            row[names[n]] = object.Properties_.Item(names[n]).Value;
            raw.push(names[n] + '=' + clean(row[names[n]]));
        }
        rows.push(row);
    }
    return rows;
}
function registry(method, key, name) {
    try {
        var input = reg.Methods_.Item(method).InParameters.SpawnInstance_();
        input.hDefKey = 0x80000002; input.sSubKeyName = key; input.sValueName = name;
        var result = reg.ExecMethod_(method, input);
        return Number(result.ReturnValue) === 0 ? (method === 'GetStringValue' ? result.sValue : numeric(result.uValue)) : null;
    } catch (err) { return null; }
}
function pciDevices() {
    var devices = {}, keys = String(env('PCI_FIELDS')).split(',');
    for (var e = new Enumerator(wmi.ExecQuery('SELECT * FROM Win32_PnPEntity WHERE PNPClass="Display"')); !e.atEnd(); e.moveNext()) {
        var device = e.item(), values = {};
        try {
            var input = device.Methods_.Item('GetDeviceProperties').InParameters.SpawnInstance_();
            var list = new ActiveXObject('Scripting.Dictionary');
            for (var k = 0; k < keys.length; k++) list.Add(k, keys[k]);
            input.devicePropertyKeys = list.Items();
            var result = device.ExecMethod_('GetDeviceProperties', input);
            if (Number(result.ReturnValue) !== 0) throw new Error('GetDeviceProperties ' + result.ReturnValue);
            var props = new VBArray(result.deviceProperties).toArray();
            for (var p = 0; p < props.length; p++) values[String(props[p].KeyName).replace('DEVPKEY_PciDevice_', '')] = numeric(props[p].Data);
        } catch (err) { warnings.push('PCIe-tietoja ei saatu: ' + clean(device.Name)); }
        devices[String(device.DeviceID)] = values;
    }
    return devices;
}
function within(amount, low, high) { return amount !== null && amount >= low && (high === '*' || amount < high); }
function vendorOf(id) { return /VEN_10DE/i.test(id) ? 'NVIDIA' : /VEN_1002/i.test(id) ? 'AMD' : /VEN_8086/i.test(id) ? 'Intel' : unknown; }
// profiles.json: the first profile whose limits match. An unknown memory amount never matches a limit.
function profileFor(ram, gpus) {
    var file = fs.OpenTextFile(env('CATALOG_FILE'), 1, false, 0);
    var text = file.ReadAll().replace(/^(\uFEFF|\xEF\xBB\xBF)/, ''); file.Close();
    // WSH JScript has no JSON object. The catalog is a file of this installation; only a JSON object literal is read.
    if (!/^\s*\{[\s\S]*\}\s*$/.test(text)) throw new Error('profiles.json ei ole JSON-olio.');
    var catalog = eval('(' + text + ')');
    for (var n = 0; n < catalog.profiles.length; n++) {
        var p = catalog.profiles[n], l = p.limits;
        if (!within(ram, l.ramGiB, '*')) continue;
        if (l.gpu === null) return {profile:p, gpu:null};
        for (var j = 0; j < gpus.length; j++) {
            var g = gpus[j];
            if (g.working && (l.gpu === 'any' || l.gpu === g.vendor) && within(g.vram, l.vramGiB, '*')) return {profile:p, gpu:g};
        }
    }
    return null;
}
// results\selection.cmd (set lines) and results\downloads.txt (kind URL) for tools\setup\MALLIN-ASENNUS.cmd
function writeSelection(chosen) {
    var safe = function (v) { v = String(v); if (/["%!^&<>|\r\n]/.test(v)) throw new Error('profiles.json: kielletty merkki arvossa ' + v); return v; };
    var sets = [], list = [];
    if (chosen) {
        var p = chosen.profile, backend = /-bin-win-(cpu|vulkan|cuda)-/.exec(p.runtime[0]);
        if (!backend) throw new Error('profiles.json ' + p.id + ': ensimmainen runtime ei ole llama.cpp cpu/vulkan/cuda -zip.');
        sets.push('set "PROFILE=' + safe(p.id) + '"', 'set "LABEL=' + safe(p.label) + '"', 'set "BACKEND=' + backend[1] + '"',
            'set "WORKFLOW=' + safe(p.workflow) + '"', 'set "GPU_NAME=' + (chosen.gpu ? safe(chosen.gpu.name) : '') + '"');
        for (var i = 0; i < p.runtime.length; i++) list.push('runtime ' + safe(p.runtime[i]));
        for (i = 0; i < p.models.length; i++) list.push('model ' + safe(p.models[i]));
    } else sets.push('set "PROFILE="');
    write('selection.cmd', sets.join('\r\n'), true);
    write('downloads.txt', list.join('\r\n'), true);
}

try {
    var locator = new ActiveXObject('WbemScripting.SWbemLocator');
    var wmi = locator.ConnectServer('.', 'root\\cimv2');
    var reg = locator.ConnectServer('.', 'root\\default').Get('StdRegProv');
    var cpu = query('Win32_Processor', 'CPU_FIELDS', 'cpu');
    var system = query('Win32_ComputerSystem', 'SYSTEM_FIELDS', 'system')[0] || {};
    var os = query('Win32_OperatingSystem', 'OS_FIELDS', 'os')[0] || {};
    var memory = query('Win32_PhysicalMemory', 'RAM_FIELDS', 'memory');
    var video = query('Win32_VideoController', 'GPU_FIELDS', 'gpu');
    var pci = {};
    try { pci = pciDevices(); } catch (err) { warnings.push('PCIe-kysely ei onnistunut.'); }
    var usable = numeric(os.TotalVisibleMemorySize), free = numeric(os.FreePhysicalMemory);
    usable = usable === null ? null : usable / 1048576;
    free = free === null ? null : free / 1048576;
    var installed = 0, allModulesKnown = memory.length > 0;
    var types = {20:'DDR',21:'DDR2',24:'DDR3',26:'DDR4',27:'LPDDR',28:'LPDDR2',29:'LPDDR3',30:'LPDDR4',34:'DDR5',35:'LPDDR5'};
    report.push('Kone: ' + value(system.Manufacturer) + ' ' + value(system.Model));
    report.push('Windows: ' + value(os.Caption) + ', ' + value(os.OSArchitecture));
    for (var i = 0; i < cpu.length; i++) report.push('CPU: ' + value(cpu[i].Name) + ', ' + value(cpu[i].NumberOfCores) + ' ydinta / ' + value(cpu[i].NumberOfLogicalProcessors) + ' saietta');
    var moduleLines = [];
    for (i = 0; i < memory.length; i++) {
        var m = memory[i], capacity = numeric(m.Capacity), speed = numeric(m.ConfiguredClockSpeed) || numeric(m.Speed);
        if (capacity === null) allModulesKnown = false; else installed += capacity / GiB;
        moduleLines.push('  Muisti ' + (i + 1) + ': ' + (types[m.SMBIOSMemoryType] || unknown) + ', ' + fixed(capacity === null ? null : capacity / GiB) + ' GiB; nopeusarvo ' + (speed || unknown) + ' (WMI)');
    }
    report.push('RAM: ' + fixed(allModulesKnown ? installed : null) + ' GiB asennettu; ' + fixed(usable) + ' GiB Windowsin kaytossa; ' + fixed(free) + ' GiB vapaana');
    report = report.concat(moduleLines);
    report.push('RAM-kello MHz: ei varmennettu. WMI-nopeusarvo voi kuvata DDR-siirtonopeutta.');
    var gpus = [], rates = {1:2.5,2:5,3:8,4:16,5:32,6:64};
    for (i = 0; i < video.length; i++) {
        var g = video[i], id = String(g.PNPDeviceID), p = pci[id] || {};
        var driver = registry('GetStringValue', 'SYSTEM\\CurrentControlSet\\Enum\\' + id, 'Driver');
        // The 64-bit registry value is adapter-specific. WMI AdapterRAM is not
        // a reliable VRAM size (32-bit overflow, and misleading iGPU values).
        var bytes = driver ? registry('GetQWORDValue', 'SYSTEM\\CurrentControlSet\\Control\\Class\\' + driver, 'HardwareInformation.qwMemorySize') : null;
        var vram = bytes !== null && bytes > 0 ? bytes / GiB : null;
        gpus.push({name:value(g.Name), vendor:vendorOf(id), vram:vram, working:numeric(g.ConfigManagerErrorCode) === 0});
        report.push('GPU: ' + value(g.Name) + '; VRAM ' + fixed(vram) + ' GiB; ajuri ' + value(g.DriverVersion));
        report.push('  Vayla: ' + (p.CurrentLinkSpeed ? 'PCIe ' + p.CurrentLinkSpeed + '.0 x' + value(p.CurrentLinkWidth) + ', ' + value(rates[p.CurrentLinkSpeed]) + ' GT/s/kaista; maksimi x' + value(p.MaxLinkWidth) + ', ' + value(rates[p.MaxLinkSpeed]) + ' GT/s/kaista' : (id.indexOf('PCI\\') === 0 ? 'PCI; linkkinopeus ei ilmoitettu' : unknown)));
        raw.push('[gpu_extra.' + i + ']', 'VRAM_GiB=' + fixed(vram), 'VRAM_source=' + (vram === null ? 'unknown' : 'HardwareInformation.qwMemorySize'));
        for (var key in p) if (p.hasOwnProperty(key)) raw.push(key + '=' + value(p[key]));
    }
    var chosen = profileFor(usable, gpus);
    if (usable === null) { chosen = null; report.push('Suositus: ei voida arvioida, RAM-tieto puuttuu.'); }
    else if (!cpu.length || numeric(cpu[0].Architecture) !== 9) {
        chosen = null;
        report.push('Suositus: Windows x64 -sovelluspaketin sopivuutta ei voitu vahvistaa.');
    }
    else if (!chosen) report.push('Suositus: mikaan profiles.json-profiili ei sovi tahan koneeseen.');
    else {
        report.push('Suositus: ' + chosen.profile.label + (chosen.gpu ? ' / ' + chosen.gpu.name : '') + ' (profiili ' + chosen.profile.id + ', tyonkulku ' + chosen.profile.workflow + ').');
        report.push('Testattu: ' + chosen.profile.tested);
    }
    if (env('CONNECTED_RC') !== '0' || env('DISCONNECTED_RC') !== '0') warnings.push('PnPUtil-laitelista on osittain vahvistamatta.');
    if (warnings.length) report.push('Huomio: ' + warnings.join(' '));
    raw.push('[result]', 'RAM_usable_GiB=' + fixed(usable), 'Profile=' + (chosen ? chosen.profile.id : unknown), 'GPU=' + (chosen && chosen.gpu ? chosen.gpu.name : unknown));
    writeSelection(chosen);
    write('hardware.ini', 'STATUS=collected\r\n' + raw.join('\r\n'));
    write('report.txt', report.join('\r\n'));
} catch (err) {
    var message = 'Tunnistus epaonnistui: ' + err.message;
    write('hardware.ini', 'STATUS=failed\r\nERROR=' + clean(err.message));
    write('report.txt', message);
    WScript.Echo(message);
    WScript.Quit(1);
}
