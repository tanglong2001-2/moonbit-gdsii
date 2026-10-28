"""Build and directly run native public-API consumers; no Node host is used."""
from pathlib import Path
from fractions import Fraction
import argparse
import hashlib
import json
import os
import platform
import shutil
import struct
import subprocess
import sys

root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--expect-platform', choices=('linux', 'win32'), default='linux')
parser.add_argument('--output', type=Path, default=root / '_build/ci/native')
args = parser.parse_args()
assert sys.platform == args.expect_platform, (sys.platform, args.expect_platform)
output = args.output.resolve()
output.mkdir(parents=True, exist_ok=False)  # Preserve evidence from previous attempts.
(output / 'bin').mkdir()
empty_path = output / 'empty-runtime-path'
empty_path.mkdir()
moon_home = Path(os.environ['MOON_HOME'])
moon = moon_home / 'bin' / ('moon.exe' if sys.platform == 'win32' else 'moon')
moonc = moon_home / 'bin' / ('moonc.exe' if sys.platform == 'win32' else 'moonc')
cases = []


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run(name, command, *, environment=None, cwd=root, timeout=300):
    result = subprocess.run([str(p) for p in command], cwd=cwd, env=environment,
                            capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=timeout)
    record = {'name': name, 'command': [str(p) for p in command], 'exitCode': result.returncode,
              'stdout': result.stdout, 'stderr': result.stderr}
    (output / (name + '.json')).write_text(json.dumps(record, indent=2), encoding='utf-8')
    (output / (name + '.log')).write_text(result.stdout + result.stderr, encoding='utf-8')
    assert result.returncode == 0, (name, result.returncode)
    cases.append(name)
    return result


def executable_format(path):
    data = path.read_bytes()[:4096]
    if args.expect_platform == 'linux':
        if len(data) >= 20 and data[:4] == b'\x7fELF' and data[4:6] == b'\x02\x01':
            kind, machine = struct.unpack_from('<HH', data, 16)
            if kind in (2, 3) and machine == 62:  # Executable/PIE, x86-64; not a C object.
                assert path.stat().st_mode & 0o111
                return 'ELF64-x86-64'
    elif len(data) >= 64 and data[:2] == b'MZ':
        offset = struct.unpack_from('<I', data, 60)[0]
        if offset + 26 <= len(data) and data[offset:offset + 4] == b'PE\0\0':
            if struct.unpack_from('<H', data, offset + 4)[0] == 0x8664 and struct.unpack_from('<H', data, offset + 24)[0] == 0x20b:
                return 'PE32+-x86-64'
    return None


run('moon-version', [moon, 'version', '--all'])
packages = ('cmd/author', 'tests/record_rewrite', 'tests/native_core')
run('native-build', [moon, 'build', *packages, '--target', 'native', '--verbose'])
runtime_env = os.environ.copy()
runtime_env['PATH'] = str(empty_path)
runtime_env.pop('NODE_OPTIONS', None)
runtime_env.pop('NODE_PATH', None)
assert shutil.which('node', path=runtime_env['PATH']) is None
binaries = {}
responses = {}
for package in packages:
    directory = root / '_build/native/debug/build' / package
    candidates = [(path, executable_format(path)) for path in directory.iterdir() if path.is_file()]
    candidates = [(path, kind) for path, kind in candidates if kind is not None]
    assert len(candidates) == 1, (package, [(str(p), k) for p, k in candidates])
    binary, kind = candidates[0]
    name = package.rsplit('/', 1)[1]
    exported = output / 'bin' / binary.name
    shutil.copy2(binary, exported)
    assert sha256(exported) == sha256(binary)
    generated_c = directory / (name + '.c')
    binaries[package] = {'sourcePath': binary.relative_to(root).as_posix(), 'format': kind,
                         'size': binary.stat().st_size, 'sha256': sha256(binary),
                         'evidenceBinary': str(exported), 'generatedCSha256': sha256(generated_c)}
    result = run('run-' + name, [exported], environment=runtime_env, cwd=empty_path, timeout=30)
    assert result.stderr == '', name
    responses[package] = json.loads(result.stdout)


# Independent original GDS expectations, built from record declarations rather
# than the native programs or a MoonBit serializer. Same approved layouts as the
# portable consumer gates, expressed with Python's big-endian integer primitives.
def record(kind, dtype=0, payload=b''):
    return struct.pack('>HBB', len(payload) + 4, kind, dtype) + payload


def i16(*values):
    return struct.pack('>' + 'h' * len(values), *values)


def i32(*values):
    return struct.pack('>' + 'i' * len(values), *values)


date = i16(126, 10, 29, 4, 0, 0, 126, 10, 29, 4, 0, 0)
prefix = b''.join([record(0, 2, i16(600)), record(1, 2, date), record(2, 6, b'REWRITE\0'),
    record(3, 5, bytes.fromhex('41800000000000044110000000000001')), record(5, 2, date),
    record(6, 6, b'top\0'), record(8), record(38, 1, bytes.fromhex('8000')),
    record(47, 3, i32(0x123456)), record(13, 2, i16(7)), record(14, 2, i16(2)),
    record(16, 3, i32(0, 0, 8, 0, 8, 4, 0, 4, 0, 0))])
attribute = record(43, 2, i16(7))
suffix = b''.join([record(43, 2, i16(9)), record(44, 6, b'keep'),
    record(127, 5, bytes.fromhex('0000000000000001')), record(127, 6, b'opaque'), record(17), record(7), record(4)])
rewrite_before = prefix + attribute + record(44, 6, b'old\0') + suffix + bytes(32)
rewrite_after = prefix + attribute + record(44, 6, b'route-A\0') + suffix


def authored(boxes):
    date = i16(126, 10, 28, 0, 0, 0, 126, 10, 28, 0, 0, 0)
    records = [record(0, 2, i16(600)), record(1, 2, date), record(2, 6, b'AUTHORED'),
        record(3, 5, bytes.fromhex('41100000000000004110000000000000')), record(5, 2, date), record(6, 6, b'top\0')]
    for x0, y0, x1, y1 in boxes:
        records.extend([record(8), record(13, 2, i16(7)), record(14, 2, i16(2)),
            record(16, 3, i32(x0, y0, x1, y0, x1, y1, x0, y1, x0, y0)), record(17)])
    return b''.join(records + [record(7), record(4)])


expected_files = {'rewrite-before': rewrite_before, 'rewrite-after': rewrite_after,
                  'author-before': authored([(0, 0, 4, 8), (10, 0, 14, 8)]),
                  'author-after': authored([(0, 0, 4, 8), (10, 0, 12, 8)])}
for name, data in expected_files.items():
    (output / (name + '-expected.gds')).write_bytes(data)


def verify_file(name, values):
    assert isinstance(values, list) and all(type(v) is int and 0 <= v <= 255 for v in values), name
    actual = bytes(values)
    destination = output / (name + '-actual.gds')
    destination.write_bytes(actual)
    assert destination.read_bytes() == expected_files[name], name


rewrite = responses['tests/record_rewrite']
verify_file('rewrite-before', rewrite['pair']['before']['bytes'])
verify_file('rewrite-after', rewrite['pair']['after']['bytes'])
assert rewrite['changed_properties'] == 1
assert rewrite['next_property_offset'] == len(prefix) + len(attribute) + len(record(44, 6, b'route-A\0'))
assert rewrite['rejected'] == {'error': ['InvalidStructure', len(prefix), 'property attribute missing']}
author = responses['cmd/author']
assert author['schema'] == 'gdsii-author-v1'
verify_file('author-before', author['before']['bytes'])
verify_file('author-after', author['after']['bytes'])
before, after = author['before']['preflight'], author['after']['preflight']
assert before['status'] == 'RectanglesClear' and before['issues'] == []
for report in (before, after):
    assert report['checked_rectangles'] == report['selected_shapes'] == 2
    assert report['skipped'] == [] and report['dbu_in_meters'] == 1
    assert report['min_width'] == 3 and report['min_spacing'] == 5
assert after['status'] == 'ViolationsFound' and len(after['issues']) == 1
assert all(after['issues'][0][k] == v for k, v in {'rule': 'Width', 'measured': 2, 'shortfall': 1}.items())
delta = author['comparison']
assert delta['status'] == 'NewIssuesFound' and len(delta['introduced']) == 1
assert delta['removed'] == [] and delta['retained'] == 0

# Fraction is the independent mathematical REAL8 oracle. Python's conversion to
# binary64 provides nearest-even rounding without using the MoonBit implementation.
numeric = responses['tests/native_core']
words = ['4180000000000004', 'c180000000000004', '0000000000000001']
encoded = ['4180000000000000', 'c180000000000000', None]
assert len(numeric['real8']) == len(words)
for index, word in enumerate(words):
    raw = bytes.fromhex(word)
    integer = int.from_bytes(raw, 'big')
    exact = Fraction(integer & ((1 << 56) - 1), 1 << 56) * Fraction(16) ** (((integer >> 56) & 127) - 64)
    if integer >> 63:
        exact = -exact
    actual = numeric['real8'][index]
    assert actual['raw'] == list(raw)
    assert struct.pack('>d', actual['value']) == struct.pack('>d', float(exact)), word
    expected_encoding = ({'bytes': list(bytes.fromhex(encoded[index]))} if encoded[index] is not None else
                         {'error': ['InvalidNumber', 'REAL8 normalized range exceeded']})
    assert actual['reencoded'] == expected_encoding, word
assert numeric['invalid_raw'] == {'error': ['InvalidNumber', 'REAL8 requires eight bytes']}
assert numeric['quantized'] == [{'dbu': 0}, {'dbu': 0}, {'dbu': 1}, {'dbu': -1},
    {'error': ['CoordinateOverflow', 2147483647.5]}, {'error': ['CoordinateOverflow', -2147483648.5]}]

identity = {'platform': sys.platform, 'expectedPlatform': args.expect_platform, 'machine': platform.machine(),
            'moonExecutableSha256': sha256(moon), 'mooncExecutableSha256': sha256(moonc),
            'toolchainLock': json.loads((root / '.ci/toolchain.json').read_text(encoding='utf-8')),
            'binaries': binaries, 'runtimePATH': str(empty_path), 'nodeOnRuntimePATH': False,
            'compilerEvidence': 'native-build.json and generated C hashes; moon-version.json records the actual SDK'}
(output / 'compile-identity.json').write_text(json.dumps(identity, indent=2), encoding='utf-8')
summary = {'status': 'PASS', 'platform': sys.platform, 'directNativeExecutables': 3, 'nodeOnRuntimePATH': False,
           'gdsFilesByteExactReadBack': 4, 'independentReal8Vectors': 3, 'independentDbuCases': 6,
           'malformedRawWordRejected': True, 'orphanPropertyRejectedAt': len(prefix),
           'originalPaddingRetained': 32, 'rewriteCopiesPhysicalPadding': False,
           'propertyOtherPayloadsPreserved': 20, 'originalUnknownRecordsPreserved': 2,
           'authoredNewWidthIssues': 1, 'cases': cases,
           'gdsExpectedSha256': {name: hashlib.sha256(data).hexdigest() for name, data in expected_files.items()},
           'binaries': binaries}
(output / 'summary.json').write_text(json.dumps(summary, indent=2), encoding='utf-8')
if os.environ.get('GITHUB_ACTIONS') == 'true':
    # Make the actual compiled identities readable through the same-repo Checks
    # API, independently of downloading the retained artifact archive.
    notice = {'schema': 'gdsii-native-identity-v1', 'commit': os.environ['GITHUB_SHA'],
              'platform': sys.platform, 'nodeOnRuntimePATH': False,
              'moonExecutableSha256': identity['moonExecutableSha256'],
              'mooncExecutableSha256': identity['mooncExecutableSha256'],
              'binaries': {name: {key: binary[key] for key in ('format', 'size', 'sha256', 'generatedCSha256')}
                           for name, binary in binaries.items()},
              'gdsExpectedSha256': summary['gdsExpectedSha256'], 'status': 'PASS'}
    message = json.dumps(notice, separators=(',', ':')).replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A')
    print('::notice title=Native consumer identity::' + message)
print(json.dumps(summary))
