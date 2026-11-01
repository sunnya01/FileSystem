"""Extract the existing SAP search-help call chain as an abapGit ZIP."""

from collections import Counter, deque
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET
from zipfile import ZipFile, ZIP_DEFLATED


ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path('/Users/sunchaowei/Git/ProjHistory/SAP项目经历/华友项目/开发程序/HuaYou/NEW')
ARCHIVES = [
    SOURCE / 'ZEHR_20260608_155344.zip',
    SOURCE / 'ZHR002_20260106_195330.zip',
    SOURCE / 'ZHR001_20260106_191218.zip',
    SOURCE / 'ZCA_20260605_041739.zip',
]
DEST = ROOT / 'ZEHR_SEARCH_HELP'
OUT = ROOT / 'output'
ZIP_PATH = OUT / 'ZEHR_SEARCH_HELP_20261020.zip'
MANIFEST_PATH = OUT / 'ZEHR_SEARCH_HELP_20261020.manifest.json'
NS = 'http://www.sap.com/abapxml'
ET.register_namespace('asx', NS)

FUNCTIONS = {
    'ZFM_EHR_COMM_SEARCH_HELP',
    'ZFM_EHR_GET_SHLP_FR_DOMAIN',
    'ZFM_EHR_GET_SHLP_FR_TABLE',
    'ZFM_EHR_GET_SHLP_FR_SHLP',
    'ZFM_EHR_GET_SHLP_FR_SUBTY',
    'ZFM_EHR_IF_COM',
    'ZFM_EHR_GET_FUNC_INFO',
    'ZFM_EHR_JSON_TO_ABAP',
    'ZFM_EHR_ABAP_TO_JSON',
}
INCLUDES = {
    'LZEHR_FG_COMMF01',
    'LZEHR_FG_COMMF02',
    'LZEHR_FG_COMMTOP',
    'SAPLZEHR_FG_COMM',
}


def encode_xml(root):
    ET.indent(root, space=' ')
    return ET.tostring(root, encoding='utf-8', xml_declaration=True) + b'\n'


def active_abap(data):
    """Remove comments while preserving quoted ABAP strings."""
    result = []
    for line in data.decode('utf-8-sig').splitlines():
        if line.startswith('*'):
            continue
        quoted = False
        i = 0
        while i < len(line):
            c = line[i]
            if c == "'":
                if quoted and i + 1 < len(line) and line[i + 1] == "'":
                    i += 2
                    continue
                quoted = not quoted
            elif c == '"' and not quoted:
                line = line[:i]
                break
            i += 1
        result.append(line)
    return '\n'.join(result).upper()


def main():
    archives = [ZipFile(p) for p in ARCHIVES]
    try:
        objects = {}
        function_groups = {}
        for archive, archive_path in zip(archives, ARCHIVES):
            for name in archive.namelist():
                path = Path(name)
                parts = path.name.split('.')
                if len(parts) < 3 or parts[1] == 'devc' or not name.startswith('src/'):
                    continue
                object_name = parts[0].split()[0].upper()
                key = (object_name, parts[1].upper())
                objects.setdefault(key, (archive, archive_path, []))
                if objects[key][1] == archive_path:
                    objects[key][2].append(name)
                if len(parts) == 4 and parts[1] == 'fugr' and parts[3] == 'abap':
                    function_groups.setdefault(parts[2].upper(), object_name)

        by_name = {}
        for key in objects:
            by_name.setdefault(key[0], []).append(key)

        included = {}
        provenance = {}
        visited = set()
        queued = set()
        queue = deque()
        unresolved = set()

        def add_file(name, data, archive_path, operation='copied unchanged', source_lines=None):
            included[name] = data
            provenance[name] = {
                'source_archive': archive_path.name,
                'source_entry': name,
                'operation': operation,
                'sha256': hashlib.sha256(data).hexdigest(),
            }
            if source_lines:
                provenance[name]['source_lines'] = source_lines

        def enqueue_name(name, required=False):
            name = name.upper().split('-')[0]
            if name in by_name:
                for key in by_name[name]:
                    if key not in queued:
                        queue.append(key)
                        queued.add(key)
            elif name in function_groups:
                enqueue_name(function_groups[name], required=True)
            elif required and re.fullmatch(r'[ZY][A-Z0-9_]+', name):
                unresolved.add(name)

        def inspect(name, data):
            if name.endswith('.xml'):
                r = ET.fromstring(data)
                required_tags = {'ROLLNAME', 'DOMNAME', 'ROWTYPE', 'PRECTAB',
                                 'CHECKTABLE', 'FORTABLE', 'ENTITYTAB', 'TYP',
                                 'DBSTRUCT', 'DBFIELD', 'SHLPNAME'}
                for element in r.iter():
                    value = (element.text or '').strip().upper()
                    if re.fullmatch(r'[ZY][A-Z0-9_]+', value):
                        enqueue_name(value, required=element.tag in required_tags)
            elif name.endswith('.abap'):
                code = active_abap(data)
                for token in set(re.findall(r'\b[ZY][A-Z0-9_]+\b', code)):
                    if token in by_name:
                        enqueue_name(token)
                for token in re.findall(r"CALL\s+FUNCTION\s+'([ZY][A-Z0-9_]+)'", code):
                    if token not in FUNCTIONS:
                        enqueue_name(token, required=True)
                for token in re.findall(r'\b(?:TYPE|LIKE|FROM|JOIN)\s+([ZY][A-Z0-9_]+)\b', code):
                    enqueue_name(token, required=True)

        primary = archives[0]
        group_xml = 'src/zehr_fg_comm.fugr.xml'
        root = ET.fromstring(primary.read(group_xml))
        values = root.find(f'{{{NS}}}abap/{{{NS}}}values')
        for child in list(values.find('FUNCTIONS')):
            if child.findtext('FUNCNAME') not in FUNCTIONS:
                values.find('FUNCTIONS').remove(child)
        for child in list(values.find('INCLUDES')):
            if child.text not in INCLUDES:
                values.find('INCLUDES').remove(child)
        add_file(group_xml, encode_xml(root), ARCHIVES[0], 'retained nine function definitions and four includes')

        for function in sorted(FUNCTIONS):
            name = f'src/zehr_fg_comm.fugr.{function.lower()}.abap'
            add_file(name, primary.read(name), ARCHIVES[0])

        for include in sorted(INCLUDES):
            for ext in ['xml', 'abap']:
                name = f'src/zehr_fg_comm.fugr.{include.lower()}.{ext}'
                data = primary.read(name)
                operation = 'copied unchanged'
                source_lines = None
                if ext == 'abap' and include == 'LZEHR_FG_COMMF01':
                    lines = data.decode('utf-8-sig').splitlines(keepends=True)
                    data = ''.join(lines[:61]).encode('utf-8')
                    operation = 'retained the two search-help FORM routines only'
                    source_lines = [1, 61]
                elif ext == 'abap' and include == 'LZEHR_FG_COMMTOP':
                    data = data.decode('utf-8-sig').splitlines(keepends=True)[0].encode('utf-8')
                    operation = 'retained FUNCTION-POOL declaration; removed unused globals'
                    source_lines = [1, 1]
                elif ext == 'abap' and include == 'SAPLZEHR_FG_COMM':
                    data = ('INCLUDE LZEHR_FG_COMMTOP.\n'
                            'INCLUDE LZEHR_FG_COMMUXX.\n'
                            'INCLUDE LZEHR_FG_COMMF01.\n'
                            'INCLUDE LZEHR_FG_COMMF02.\n').encode('utf-8')
                    operation = 'retained only the includes required by the selected functions'
                elif ext == 'xml' and include == 'SAPLZEHR_FG_COMM':
                    program = ET.fromstring(data)
                    program_values = program.find(f'{{{NS}}}abap/{{{NS}}}values')
                    text_pool = program_values.find('TPOOL')
                    if text_pool is not None:
                        program_values.remove(text_pool)
                    data = encode_xml(program)
                    operation = 'removed unused email text pool'
                add_file(name, data, ARCHIVES[0], operation, source_lines)

        # Do not scan the original, unfiltered function group or its global declarations.
        visited.add(('ZEHR_FG_COMM', 'FUGR'))
        queued.add(('ZEHR_FG_COMM', 'FUGR'))
        for name, data in list(included.items()):
            inspect(name, data)

        for name in ['ZVHR0015', 'ZTHR0015D', 'ZEHR_F4HELP', 'ZEHR_INTERFACE',
                     'ZTEHR0001', 'ZTHR_F4_TAB', 'ZSHR_SHH_HEAD', 'ZMSG_01']:
            enqueue_name(name, required=True)

        while queue:
            key = queue.popleft()
            if key in visited:
                continue
            visited.add(key)
            archive, archive_path, names = objects[key]
            for name in names:
                data = archive.read(name)
                add_file(name, data, archive_path)
                inspect(name, data)

        # Keep the repository-root layout identical to an abapGit export.
        for name in ['.abapgit.xml', 'src/package.devc.xml']:
            add_file(name, primary.read(name), ARCHIVES[0])

        DEST.mkdir(exist_ok=True)
        OUT.mkdir(exist_ok=True)
        expected = set(included)
        existing = {p.relative_to(DEST).as_posix() for p in DEST.rglob('*') if p.is_file()}
        if existing - expected:
            raise RuntimeError(f'Unexpected existing output files: {sorted(existing - expected)}')
        for name, data in included.items():
            target = DEST / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
        with ZipFile(ZIP_PATH, 'w', compression=ZIP_DEFLATED) as output:
            for name in sorted(included):
                output.writestr(name, included[name])

        sources_used = {p['source_archive'] for p in provenance.values()}
        manifest = {
            'scope': 'SAP generic search-help core, existing Java RFC gateway, configuration maintenance and recursive custom dependencies',
            'kept_original_object_names': True,
            'functions_in_zehr_fg_comm': sorted(FUNCTIONS),
            'source_archives': [{'path': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
                                for p in ARCHIVES if p.name in sources_used],
            'file_count': len(included),
            'objects': [{'name': name, 'type': typ} for name, typ in sorted(visited)],
            'source_file_counts': dict(Counter(p['source_archive'] for p in provenance.values())),
            'unresolved_static_custom_names': sorted(unresolved - {k[0] for k in visited}),
            'runtime_requirements': [
                'SAP HR and the SAP standard DDIC objects and function modules used by the source',
                '/UI2/CL_JSON for the existing JSON_TO_ABAP implementation',
                'ZTHR0015 and ZTHR0015T configuration rows, plus ZTEHR0001 IFNUM to IFNAM mapping',
                'Objects and functions named dynamically by the actual search-help configuration',
                'ZEHR_IFLOG number range object and interval 01 when IFLOG is enabled',
            ],
            'known_source_limitations': [
                'The exported ZFM_EHR_ABAP_TO_JSON has no active serialization implementation; it is preserved unchanged.',
                'No configuration table data is supplied by the source exports.',
                'The selected function group retains its original name; review conflicts with an existing ZEHR_FG_COMM before import.',
            ],
            'files': {name: provenance[name] for name in sorted(provenance)},
        }
        MANIFEST_PATH.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        print(json.dumps({
            'zip': str(ZIP_PATH), 'file_count': len(included),
            'object_count': len(visited), 'bytes': ZIP_PATH.stat().st_size,
            'source_file_counts': manifest['source_file_counts'],
            'unresolved_static_custom_names': manifest['unresolved_static_custom_names'],
            'object_types': dict(Counter(typ for _, typ in visited)),
        }, ensure_ascii=False, indent=2))
    finally:
        for archive in archives:
            archive.close()


if __name__ == '__main__':
    main()
