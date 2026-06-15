#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(scriptDir, '..');
const args = process.argv.slice(2);
const assemble = args.includes('--assemble');
const checkDevice = args.includes('--device') || args.includes('--install');
const install = args.includes('--install');
const printEnv = args.includes('--print-env');
const showHelp = args.includes('--help') || args.includes('-h');
const separatorIndex = args.indexOf('--');
const hvigorArgs = separatorIndex >= 0
  ? args.slice(separatorIndex + 1)
  : ['assembleHap', '--no-daemon', '--stacktrace'];

const defaultDevEcoSdkRoot = '/Applications/DevEco-Studio.app/Contents/sdk';
const defaultDevEcoJavaHome = '/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home';
const components = ['toolchains', 'ets', 'js', 'native', 'previewer'];
const hmsCoreComponents = ['toolchains', 'ets', 'native'];
let hasFailure = false;
let hasBlockingFailure = false;

function printUsage() {
  console.log('Usage: node scripts/check-deveco-env.mjs [options] [-- hvigor args]');
  console.log('');
  console.log('Options:');
  console.log('  --assemble    Run Hvigor after environment checks');
  console.log('  --device      Check DevEco hdc device visibility');
  console.log('  --install     Install the signed HAP after build/device checks');
  console.log('  --print-env   Print suggested DEVECO_SDK_HOME/JAVA_HOME exports');
  console.log('  --help        Show this help');
  console.log('');
  console.log('Examples:');
  console.log('  node scripts/check-deveco-env.mjs --assemble --device');
  console.log('  node scripts/check-deveco-env.mjs --assemble -- assembleHap --no-daemon --stacktrace --debug');
}

if (showHelp) {
  printUsage();
  process.exit(0);
}

function mark(level, label, detail = '') {
  const prefix = level === 'pass' ? '[pass]' : level === 'warn' ? '[warn]' : '[fail]';
  console.log(`${prefix} ${label}${detail ? ` - ${detail}` : ''}`);
  if (level === 'fail') {
    hasFailure = true;
  }
}

function fail(label, detail = '', blocking = true) {
  mark('fail', label, detail);
  if (blocking) {
    hasBlockingFailure = true;
  }
}

function exists(filePath) {
  return fs.existsSync(filePath);
}

function readText(filePath) {
  return fs.readFileSync(filePath, 'utf8');
}

function readJson(filePath) {
  return JSON.parse(readText(filePath));
}

function extractStringField(text, field) {
  const match = new RegExp(`"${field}"\\s*:\\s*"([^"]+)"`).exec(text);
  return match ? match[1] : '';
}

function extractArrayBlock(text, field) {
  const fieldIndex = text.indexOf(`"${field}"`);
  if (fieldIndex < 0) {
    return '';
  }

  const startIndex = text.indexOf('[', fieldIndex);
  if (startIndex < 0) {
    return '';
  }

  let depth = 0;
  for (let index = startIndex; index < text.length; index += 1) {
    const char = text[index];
    if (char === '[') {
      depth += 1;
    } else if (char === ']') {
      depth -= 1;
      if (depth === 0) {
        return text.slice(startIndex, index + 1);
      }
    }
  }

  return '';
}

function extractApiNumber(sdkVersion) {
  const match = /\((\d+)\)/.exec(sdkVersion);
  return match ? match[1] : sdkVersion;
}

function normalize(filePath) {
  return path.resolve(filePath).replace(/\/$/, '');
}

function sdkDefaultDir(sdkRoot) {
  return path.join(sdkRoot, 'default');
}

function hasExpectedSdkRootLayout(sdkRoot) {
  return exists(path.join(sdkDefaultDir(sdkRoot), 'sdk-pkg.json'));
}

function hasDefaultOnlyLayout(sdkHome) {
  return exists(path.join(sdkHome, 'sdk-pkg.json')) &&
    (exists(path.join(sdkHome, 'openharmony')) || exists(path.join(sdkHome, 'hms')));
}

function javaBinary(javaHome) {
  return path.join(javaHome, 'bin', 'java');
}

function devEcoJavaHomeFromSdkRoot(sdkRoot) {
  return path.join(path.dirname(sdkRoot), 'jbr', 'Contents', 'Home');
}

function detectSdkRoot() {
  const envHome = process.env.DEVECO_SDK_HOME ? normalize(process.env.DEVECO_SDK_HOME) : '';
  const candidates = [];

  if (envHome) {
    candidates.push(envHome);
    if (hasDefaultOnlyLayout(envHome)) {
      candidates.push(path.dirname(envHome));
    }
  }

  candidates.push(defaultDevEcoSdkRoot);

  for (const candidate of candidates) {
    if (candidate && hasExpectedSdkRootLayout(candidate)) {
      return {
        envHome,
        sdkRoot: normalize(candidate),
      };
    }
  }

  return {
    envHome,
    sdkRoot: envHome || defaultDevEcoSdkRoot,
  };
}

function checkProjectProfile() {
  const profilePath = path.join(projectRoot, 'build-profile.json5');
  if (!exists(profilePath)) {
    fail('build-profile.json5', 'missing');
    return { compileSdkVersion: '', compileApi: '', runtimeOS: '', signingConfig: '', signingConfigCount: 0 };
  }

  const text = readText(profilePath);
  const compileSdkVersion = extractStringField(text, 'compileSdkVersion');
  const targetSdkVersion = extractStringField(text, 'targetSdkVersion');
  const compatibleSdkVersion = extractStringField(text, 'compatibleSdkVersion');
  const runtimeOS = extractStringField(text, 'runtimeOS');
  const signingConfig = extractStringField(text, 'signingConfig');
  const signingConfigsBlock = extractArrayBlock(text, 'signingConfigs');
  const signingConfigCount = (signingConfigsBlock.match(/"material"\s*:/g) || []).length;
  const compileApi = extractApiNumber(compileSdkVersion);

  if (compileSdkVersion) {
    mark('pass', 'compileSdkVersion', compileSdkVersion);
  } else {
    fail('compileSdkVersion', 'missing in build-profile.json5');
  }

  if (targetSdkVersion) {
    mark('pass', 'targetSdkVersion', targetSdkVersion);
  } else {
    mark('warn', 'targetSdkVersion', 'missing in build-profile.json5');
  }

  if (compatibleSdkVersion) {
    mark('pass', 'compatibleSdkVersion', compatibleSdkVersion);
  }

  if (runtimeOS === 'HarmonyOS') {
    mark('pass', 'runtimeOS', runtimeOS);
  } else {
    fail('runtimeOS', `expected HarmonyOS, found "${runtimeOS || 'missing'}"`);
  }

  if (signingConfigCount > 0) {
    mark('pass', 'signingConfigs', `${signingConfigCount} configured`);
  } else if (signingConfig) {
    mark('warn', 'signingConfigs', `product references "${signingConfig}", but app.signingConfigs is empty`);
  } else {
    mark('warn', 'signingConfigs', 'empty; HAP will be unsigned');
  }

  return { compileSdkVersion, compileApi, runtimeOS, signingConfig, signingConfigCount };
}

function checkHvigorConfig() {
  const configPath = path.join(projectRoot, 'hvigor', 'hvigor-config.json5');
  if (!exists(configPath)) {
    fail('hvigor-config.json5', `missing ${configPath}`);
    return;
  }

  let config;
  try {
    config = readJson(configPath);
  } catch (error) {
    fail('hvigor-config.json5', 'invalid JSON5-compatible syntax');
    return;
  }

  if (config.modelVersion === '6.0.0') {
    mark('pass', 'hvigor modelVersion', config.modelVersion);
  } else {
    fail('hvigor modelVersion', `expected 6.0.0, found "${config.modelVersion || 'missing'}"`, false);
  }

  if (config.dependencies && !Array.isArray(config.dependencies) && typeof config.dependencies === 'object') {
    mark('pass', 'hvigor dependencies', 'object');
  } else {
    fail('hvigor dependencies', 'expected an object, for example "dependencies": {}');
  }
}

function checkSdkHome(sdkRoot, envHome) {
  if (!envHome) {
    mark('warn', 'DEVECO_SDK_HOME', `not set; suggested value is ${sdkRoot}`);
    return;
  }

  if (normalize(envHome) === normalize(sdkRoot)) {
    mark('pass', 'DEVECO_SDK_HOME', sdkRoot);
    return;
  }

  if (hasDefaultOnlyLayout(envHome) && normalize(path.dirname(envHome)) === normalize(sdkRoot)) {
    mark(
      'warn',
      'DEVECO_SDK_HOME',
      `points to sdk/default; Hvigor subprocesses will use the parent SDK root: ${sdkRoot}`,
    );
    return;
  }

  mark('warn', 'DEVECO_SDK_HOME', `unexpected value "${envHome}"; suggested value is ${sdkRoot}`);
}

function checkComponentPackage(packagePath, expectedApi, componentLabel) {
  if (!exists(packagePath)) {
    fail(componentLabel, `missing ${path.basename(packagePath)}`);
    return;
  }

  const pkg = readJson(packagePath);
  if (String(pkg.apiVersion) !== String(expectedApi)) {
    fail(componentLabel, `apiVersion ${pkg.apiVersion} does not match compile API ${expectedApi}`);
    return;
  }

  mark('pass', componentLabel, `api ${pkg.apiVersion}`);
}

function checkSdkComponents(sdkRoot, compileApi) {
  const defaultDir = sdkDefaultDir(sdkRoot);
  const sdkPkgPath = path.join(defaultDir, 'sdk-pkg.json');
  if (!exists(sdkPkgPath)) {
    fail('DevEco SDK root', `missing ${sdkPkgPath}`);
    return;
  }

  const sdkPkg = readJson(sdkPkgPath);
  const displayName = sdkPkg?.data?.displayName || 'unknown SDK';
  const apiVersion = sdkPkg?.data?.apiVersion || 'unknown';
  if (String(apiVersion) === String(compileApi)) {
    mark('pass', 'SDK package', `${displayName}, api ${apiVersion}`);
  } else {
    fail('SDK package', `api ${apiVersion} does not match compile API ${compileApi}`);
  }

  for (const component of components) {
    checkComponentPackage(
      path.join(defaultDir, 'openharmony', component, 'oh-uni-package.json'),
      compileApi,
      `OpenHarmony ${component}`,
    );
  }

  for (const component of hmsCoreComponents) {
    checkComponentPackage(
      path.join(defaultDir, 'hms', component, 'uni-package.json'),
      compileApi,
      `HarmonyOS ${component}`,
    );
  }
}

function detectJava(sdkRoot) {
  const devEcoJavaHome = devEcoJavaHomeFromSdkRoot(sdkRoot);
  if (exists(javaBinary(devEcoJavaHome))) {
    return {
      command: javaBinary(devEcoJavaHome),
      javaHome: normalize(devEcoJavaHome),
      source: 'DevEco JBR'
    };
  }

  if (exists(javaBinary(defaultDevEcoJavaHome))) {
    return {
      command: javaBinary(defaultDevEcoJavaHome),
      javaHome: normalize(defaultDevEcoJavaHome),
      source: 'DevEco JBR'
    };
  }

  if (process.env.JAVA_HOME) {
    const javaFromHome = javaBinary(process.env.JAVA_HOME);
    if (exists(javaFromHome)) {
      return {
        command: javaFromHome,
        javaHome: normalize(process.env.JAVA_HOME),
        source: 'JAVA_HOME'
      };
    }
  }

  return {
    command: 'java',
    javaHome: '',
    source: 'PATH'
  };
}

function checkJava(sdkRoot) {
  const javaInfo = detectJava(sdkRoot);
  const result = spawnSync(javaInfo.command, ['-version'], { encoding: 'utf8' });
  const versionOutput = `${result.stderr || ''}${result.stdout || ''}`.trim().split('\n')[0] || '';

  if (result.status === 0) {
    mark('pass', 'Java Runtime', `${versionOutput} (${javaInfo.source})`);
    return javaInfo;
  }

  fail('Java Runtime', 'missing; PackageHap will fail until Java is available');
  return {
    command: '',
    javaHome: '',
    source: ''
  };
}

function checkHvigor(sdkRoot) {
  const hvigorw = path.join(path.dirname(sdkRoot), 'tools', 'hvigor', 'bin', 'hvigorw');
  if (!exists(hvigorw)) {
    fail('hvigorw', `missing ${hvigorw}`);
    return '';
  }

  mark('pass', 'hvigorw', hvigorw);
  return hvigorw;
}

function detectHdc(sdkRoot) {
  const hdcPath = path.join(sdkDefaultDir(sdkRoot), 'openharmony', 'toolchains', 'hdc');
  if (exists(hdcPath)) {
    mark('pass', 'hdc', hdcPath);
    return hdcPath;
  }

  mark('warn', 'hdc', `missing ${hdcPath}`);
  return '';
}

function checkDevices(hdcPath) {
  if (!hdcPath) {
    return [];
  }

  const result = spawnSync(hdcPath, ['list', 'targets'], { encoding: 'utf8' });
  if (result.status !== 0) {
    mark('warn', 'devices', `${result.stderr || result.stdout || 'hdc list targets failed'}`.trim());
    return [];
  }

  const devices = result.stdout.split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line && !line.includes('[Empty]'));

  if (devices.length > 0) {
    mark('pass', 'devices', devices.join(', '));
  } else {
    mark('warn', 'devices', 'no hdc target connected');
  }

  return devices;
}

function findHapOutputs() {
  const outputsDir = path.join(projectRoot, 'entry', 'build', 'default', 'outputs');
  if (!exists(outputsDir)) {
    return [];
  }

  const found = [];
  const stack = [outputsDir];
  while (stack.length > 0) {
    const current = stack.pop();
    if (!current) {
      continue;
    }

    const entries = fs.readdirSync(current, { withFileTypes: true });
    for (const entry of entries) {
      const entryPath = path.join(current, entry.name);
      if (entry.isDirectory()) {
        stack.push(entryPath);
      } else if (entry.name.endsWith('.hap')) {
        found.push(entryPath);
      }
    }
  }

  return found.sort();
}

function reportHapOutputs(projectProfile) {
  const haps = findHapOutputs();
  if (haps.length === 0) {
    mark('warn', 'HAP output', 'not found under entry/build/default/outputs');
    return '';
  }

  let installableHap = '';
  for (const hap of haps) {
    const relativePath = path.relative(projectRoot, hap);
    const sizeKb = Math.ceil(fs.statSync(hap).size / 1024);
    if (hap.includes('-unsigned')) {
      mark('warn', 'HAP output', `${relativePath} (${sizeKb} KB, unsigned)`);
    } else {
      mark('pass', 'HAP output', `${relativePath} (${sizeKb} KB)`);
      installableHap = hap;
    }
  }

  if (!installableHap && projectProfile.signingConfigCount === 0) {
    mark('warn', 'install readiness', 'unsigned HAP cannot be installed on a normal device; configure signing in DevEco Studio');
    console.log('       DevEco Studio: File > Project Structure > Signing Configs > Automatically generate signature');
  }

  return installableHap;
}

function printSuggestedEnvironment(sdkRoot, javaInfo) {
  console.log('');
  console.log('Suggested shell setup:');
  console.log(`export DEVECO_SDK_HOME=${sdkRoot}`);
  if (javaInfo.javaHome) {
    console.log(`export JAVA_HOME=${javaInfo.javaHome}`);
    console.log('export PATH=$JAVA_HOME/bin:$PATH');
  } else {
    console.log('export JAVA_HOME=$(/usr/libexec/java_home)');
  }
}

function runHvigor(hvigorw, sdkRoot, javaInfo) {
  console.log('');
  console.log(`Running: ${hvigorw} ${hvigorArgs.join(' ')}`);
  const env = {
    ...process.env,
    DEVECO_SDK_HOME: sdkRoot,
  };
  if (javaInfo.javaHome) {
    env.JAVA_HOME = javaInfo.javaHome;
    env.PATH = `${path.join(javaInfo.javaHome, 'bin')}:${process.env.PATH || ''}`;
  }

  const result = spawnSync(hvigorw, hvigorArgs, {
    cwd: projectRoot,
    env,
    stdio: 'inherit',
  });

  return result.status ?? 1;
}

function runInstall(hdcPath, devices, hapPath) {
  if (!hdcPath || devices.length === 0 || !hapPath) {
    console.log('');
    console.error('Cannot install until hdc has a device and a signed HAP is available.');
    process.exitCode = 1;
    return;
  }

  console.log('');
  console.log(`Running: ${hdcPath} install -r ${hapPath}`);
  const result = spawnSync(hdcPath, ['install', '-r', hapPath], {
    cwd: projectRoot,
    stdio: 'inherit',
  });
  process.exitCode = result.status ?? 1;
}

console.log('DevEco/Hvigor environment check');
console.log(`Project: ${projectRoot}`);
console.log('');

const projectProfile = checkProjectProfile();
checkHvigorConfig();
const { envHome, sdkRoot } = detectSdkRoot();
checkSdkHome(sdkRoot, envHome);
checkSdkComponents(sdkRoot, projectProfile.compileApi);
const javaInfo = checkJava(sdkRoot);
const javaReady = Boolean(javaInfo.command);
const hvigorw = checkHvigor(sdkRoot);
const hdcPath = checkDevice || install ? detectHdc(sdkRoot) : '';
const devices = checkDevice || install ? checkDevices(hdcPath) : [];

if (printEnv || hasFailure) {
  printSuggestedEnvironment(sdkRoot, javaInfo);
}

if (assemble) {
  if (hasBlockingFailure || !javaReady || !hvigorw) {
    console.log('');
    console.error('Cannot run Hvigor until the failed checks above are fixed.');
    process.exit(1);
  }
  const hvigorStatus = runHvigor(hvigorw, sdkRoot, javaInfo);
  process.exitCode = hvigorStatus;
  if (hvigorStatus === 0) {
    console.log('');
    console.log('Build artifacts:');
    const hapPath = reportHapOutputs(projectProfile);
    if (install) {
      runInstall(hdcPath, devices, hapPath);
    }
  }
} else if (install) {
  const hapPath = reportHapOutputs(projectProfile);
  runInstall(hdcPath, devices, hapPath);
} else if (hasFailure || !javaReady) {
  process.exitCode = 1;
}
