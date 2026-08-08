// Minimal one-off Leonardo image generator for REVERSIA's remaining asset
// batch (Canva quota was hit mid-batch; this covers the rest).
// Usage: node generate_leonardo.js
'use strict';

const fs = require('fs');
const path = require('path');

const API_KEY = process.env.LEONARDO_API_KEY;
if (!API_KEY) {
  console.error('LEONARDO_API_KEY is not set in this shell.');
  process.exit(1);
}

const MODEL_ID = 'de7d3faf-762f-48e0-b3b7-9d0ac3a3fcf3'; // Phoenix 1.0
const OUTPUT_DIR = path.resolve(__dirname, '../../assets/images');

const NEGATIVE_PROMPT =
  'text, watermark, logo wordmark, signature, stamp, seal, border frame, ' +
  'low quality, blurry, multiple characters, people, hands, cropped';

const ASSETS = [
  {
    file: 'app_icon.png',
    prompt:
      'A single elegant mobile app icon illustration for a Japanese abstract strategy board game called REVERSIA, whose core mechanic is a piece flipping and switching allegiance. Two circular coin-like game pieces mid-flip, one deep indigo-blue side and one vermilion-red side, arranged in a yin-yang-like circular composition with a thin gold ring border, on a deep dark background. Dignified, minimalist, modern Japanese (wamodern) design language, calm and confident mood. Bold flat shapes, clean silhouette readable at small size, subtle gold accent line details, semi-realistic mobile app icon illustration, centered, square composition',
  },
  {
    file: 'splash_background.png',
    prompt:
      'A dignified title screen background illustration for a Japanese abstract strategy board game called REVERSIA. A dark warm-brown wood grain board game surface fading into deep near-black at the edges, with a single soft golden spotlight glow in the upper area, faint drifting ink-wash mist. Calm, elegant, minimalist, modern Japanese (wamodern) atmosphere. No text, no logo, no characters, no people, no board grid lines, semi-realistic mobile game splash screen background illustration, vertical portrait composition',
  },
  {
    file: 'piece_front.png',
    prompt:
      'A single top-down illustration of one round game piece (go-stone shaped disc) for a Japanese abstract strategy board game, showing its "front" face: deep indigo-blue lacquered surface with a subtle upward arrow engraving, thin gold rim edge, soft directional highlight, dignified minimalist wamodern design. Centered on a plain dark background, no text, no logo, no watermark, no other objects, no characters, semi-realistic game asset illustration',
  },
  {
    file: 'piece_back.png',
    prompt:
      'A single top-down illustration of one round game piece (go-stone shaped disc) for a Japanese abstract strategy board game, showing its "back" face: deep vermilion-red lacquered surface with a subtle triangular engraving, thin gold rim edge, soft directional highlight, dignified minimalist wamodern design. Centered on a plain dark background, no text, no logo, no watermark, no other objects, no characters, semi-realistic game asset illustration',
  },
  {
    file: 'piece_king.png',
    prompt:
      'A single top-down illustration of one round king game piece (go-stone shaped disc) for a Japanese abstract strategy board game, brilliant polished gold lacquered surface with an engraved shield emblem, faint warm glow, dignified regal minimalist wamodern design. Centered on a plain dark background, no text, no logo, no watermark, no other objects, no characters, semi-realistic game asset illustration',
  },
  {
    file: 'victory_decoration.png',
    prompt:
      'A purely abstract celebratory radial burst illustration for a victory screen in a Japanese abstract strategy board game. Radiating thin gold light rays and delicate ink-wash flourish lines bursting outward from an empty center point, on a transparent-feeling deep dark background, dignified triumphant elegant wamodern mood. Absolutely no words, no letters, no typography of any kind, no title, no caption, no logo, no watermark, no characters, no people, no symbols that resemble writing, purely abstract light-ray graphic only, semi-realistic game asset illustration, centered radial composition with an empty blank center',
  },
];

async function generateOne(asset) {
  const outPath = path.join(OUTPUT_DIR, asset.file);
  if (fs.existsSync(outPath)) {
    console.log(`SKIP (exists): ${asset.file}`);
    return;
  }

  console.log(`Requesting: ${asset.file}`);
  const createRes = await fetch('https://cloud.leonardo.ai/api/rest/v1/generations', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      prompt: asset.prompt,
      negative_prompt: NEGATIVE_PROMPT,
      modelId: MODEL_ID,
      width: 512,
      height: 512,
      num_images: 1,
      alchemy: false,
      photoReal: false,
    }),
  });

  if (!createRes.ok) {
    const body = await createRes.text();
    throw new Error(`Create failed for ${asset.file}: ${createRes.status} ${body}`);
  }
  const createJson = await createRes.json();
  const generationId = createJson.sdGenerationJob && createJson.sdGenerationJob.generationId;
  if (!generationId) {
    throw new Error(`No generationId for ${asset.file}: ${JSON.stringify(createJson)}`);
  }

  // Poll for completion.
  let imageUrl = null;
  for (let attempt = 0; attempt < 30; attempt++) {
    await new Promise((r) => setTimeout(r, 3000));
    const pollRes = await fetch(
      `https://cloud.leonardo.ai/api/rest/v1/generations/${generationId}`,
      { headers: { Authorization: `Bearer ${API_KEY}` } }
    );
    if (!pollRes.ok) continue;
    const pollJson = await pollRes.json();
    const gen = pollJson.generations_by_pk;
    if (gen && gen.status === 'COMPLETE') {
      const images = gen.generated_images || [];
      if (images.length > 0) imageUrl = images[0].url;
      break;
    }
    if (gen && gen.status === 'FAILED') {
      throw new Error(`Generation FAILED for ${asset.file}`);
    }
  }

  if (!imageUrl) {
    throw new Error(`Timed out waiting for ${asset.file}`);
  }

  const imgRes = await fetch(imageUrl);
  const buf = Buffer.from(await imgRes.arrayBuffer());
  fs.writeFileSync(outPath, buf);
  console.log(`OK: ${asset.file} (${buf.length} bytes)`);
}

async function main() {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  for (const asset of ASSETS) {
    await generateOne(asset);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
