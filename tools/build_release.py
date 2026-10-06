"""Build patch-only releases without bundling the upstream shaderpack."""
from pathlib import Path
import hashlib, json, zipfile

REPO = Path(__file__).resolve().parents[1]
OUT = REPO / 'dist'
VERSION = 'v0.1.0'

def language(path):
    rows = [row for row in path.read_text(encoding='utf-8').splitlines()
            if row and not row.startswith('#')]
    keys = [row.split('=', 1)[0] for row in rows]
    assert len(keys) == len(set(keys)), 'Duplicate language keys'
    options = [k for k in keys if k.startswith('option.') and not k.endswith('.comment')]
    assert all(k + '.comment' in keys for k in options)
    return {'entries': len(keys), 'options_with_tooltips': len(options)}

def build():
    OUT.mkdir(exist_ok=True)
    archives = []
    counts = {}
    for mode, name in [
        ('standard', f'BSL_10.1.8_zhCN_Overlay_{VERSION}.zip'),
        ('optimized', f'BSL_10.1.8_zhCN_1070Ti_ModPatch_{VERSION}.zip')
    ]:
        patch = REPO / 'patches' / mode
        counts[mode] = language(patch / 'shaders/lang/zh_CN.lang')
        archive = OUT / name
        with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as z:
            for p in sorted(patch.rglob('*')):
                if p.is_file():
                    z.write(p, p.relative_to(patch).as_posix())
            z.write(REPO / 'README.md', '使用说明.md')
            z.write(REPO / 'docs/VALIDATION.md', '验证说明.md')
            if mode == 'optimized':
                z.write(REPO / 'tools/Apply-Optimized.ps1', 'tools/Apply-Optimized.ps1')
                cmd = (REPO / 'tools/应用优化魔改.cmd').read_text(encoding='utf-8')
                cmd = cmd.replace('%~dp0Apply-Optimized.ps1', '%~dp0tools\\Apply-Optimized.ps1')
                z.writestr('应用优化魔改.cmd', cmd.replace('\r\n', '\n').replace('\n', '\r\n').encode('utf-8'))
        with zipfile.ZipFile(archive) as z:
            assert z.testzip() is None
            names = set(z.namelist())
            assert 'shaders/lang/zh_CN.lang' in names
            assert not any(n.endswith(('.glsl', '.fsh', '.vsh', '.csh', '.png', '.properties')) for n in names)
            if mode == 'standard': assert 'changes.json' not in names
            else: assert {'changes.json', 'tools/Apply-Optimized.ps1', '应用优化魔改.cmd'} <= names
        archives.append(archive)
    sums = ''.join(hashlib.sha256(p.read_bytes()).hexdigest() + '  ' + p.name + '\n' for p in archives)
    (OUT / 'SHA256SUMS.txt').write_text(sums, encoding='utf-8')
    report = {'base_version': 'BSL 10.1.8', 'patch_version': VERSION, 'language': counts,
              'checks': ['No duplicate language keys', 'All options have Chinese tooltips',
                         'ZIP CRC passed', 'No upstream source files or textures in release ZIPs',
                         'Windows PowerShell 5.1 installer generated matching repaired files',
                         'Installer refused existing output and modified upstream files'],
              'runtime_reload_confirmed': False, 'controlled_fps_comparison': False}
    (REPO / 'docs/validation.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(sums)

if __name__ == '__main__': build()
