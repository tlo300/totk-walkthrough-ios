import sharp from 'sharp';
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = join(__dirname, '..');
const SVG_SOURCE = join(REPO_ROOT, 'assets', 'icon_source.svg');
const APPICONSET = join(REPO_ROOT, 'app', 'Sources', 'Assets.xcassets', 'AppIcon.appiconset');

const SIZES = [
  ['Icon-20@2x.png', 40],
  ['Icon-20@3x.png', 60],
  ['Icon-29@2x.png', 58],
  ['Icon-29@3x.png', 87],
  ['Icon-40@2x.png', 80],
  ['Icon-40@3x.png', 120],
  ['Icon-60@2x.png', 120],
  ['Icon-60@3x.png', 180],
  ['Icon-1024.png', 1024],
];

const svgBuffer = readFileSync(SVG_SOURCE);

for (const [filename, size] of SIZES) {
  const outPath = join(APPICONSET, filename);
  await sharp(svgBuffer).resize(size, size).png().toFile(outPath);
  console.log(`  wrote ${filename} (${size}x${size})`);
}

console.log('Done —', APPICONSET);
