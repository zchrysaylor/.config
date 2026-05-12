import path from 'node:path';
import type { ExtensionAPI, ExtensionContext } from '@earendil-works/pi-coding-agent';

const RESET = '\x1b[0m';
const BOLD = '\x1b[1m';
const MEDIUM_GREY: Rgb = [150, 150, 150];

// const DEEP_BLUE: Rgb = [22, 83, 189];
// const BLUE: Rgb = [48, 129, 247];
// const SKY: Rgb = [93, 171, 255];
// const ICE: Rgb = [151, 205, 255];
// const PALETTE: Rgb[] = [DEEP_BLUE, BLUE, SKY, ICE, SKY, BLUE];

// const DEEP_MARSH: Rgb = [18, 71, 75];
// const TEAL: Rgb = [46, 130, 130];
// const FROST_TEAL: Rgb = [110, 184, 178];
// const ICE_TEAL: Rgb = [183, 227, 219];
// const PALETTE: Rgb[] = [DEEP_MARSH, TEAL, FROST_TEAL, ICE_TEAL, FROST_TEAL, TEAL];

const DEEP_MARSH: Rgb = [38, 110, 112];
const TEAL: Rgb = [78, 162, 159];
const FROST_TEAL: Rgb = [140, 208, 200];
const ICE_TEAL: Rgb = [205, 240, 232];
const PALETTE: Rgb[] = [DEEP_MARSH, TEAL, FROST_TEAL, ICE_TEAL, FROST_TEAL, TEAL];

const TITLE_LINES = [
  '               ██╗              ██╗ ',
  '  ███████████╗ ██║     ██████   ██║ ',
  '    ██╔══██╔═╝ ██║    ██╔═══██╗ ██║ ',
  '    ██║  ██║   █████╗ ██║   ██║ ██║ ',
  '    ██║  ██║   ██╔══╝ ██║   ██║ ██║ ',
  '  ███████████╗ ██║     ██████╔╝ ██║ ',
  '  ╚══════════╝ ██║     ╚═════╝  ██║ ',
  '               ╚═╝              ╚═╝ ',
];

type Rgb = [number, number, number];

type HeaderComponent = {
  render(width: number): string[];
  invalidate(): void;
};

function mix(a: number, b: number, t: number) {
  return Math.round(a + (b - a) * t);
}

function sampleGradient(position: number) {
  const wrapped = ((position % 1) + 1) % 1;
  const scaled = wrapped * PALETTE.length;
  const index = Math.floor(scaled);
  const nextIndex = (index + 1) % PALETTE.length;
  const t = scaled - index;
  const a = PALETTE[index]!;
  const b = PALETTE[nextIndex]!;

  return [mix(a[0], b[0], t), mix(a[1], b[1], t), mix(a[2], b[2], t)] as Rgb;
}

function fg([r, g, b]: Rgb, text: string) {
  return `\x1b[38;2;${r};${g};${b}m${text}${RESET}`;
}

function gradientText(text: string, phase: number) {
  const chars = [...text];
  const span = Math.max(chars.length - 1, 1);

  return chars
    .map((char, index) => {
      if (char === ' ') return char;
      return fg(sampleGradient(index / span + phase), char);
    })
    .join('');
}

function charWidth(char: string) {
  // Good enough for this banner: Korean/CJK glyphs are double-width in terminals.
  return /[\u1100-\u11FF\u3130-\u318F\uAC00-\uD7AF\u2E80-\u9FFF]/u.test(char) ? 2 : 1;
}

function displayWidth(text: string) {
  return [...text].reduce((width, char) => width + charWidth(char), 0);
}

function center(text: string, width: number, offset = 0) {
  const length = displayWidth(text);
  if (length >= width) return text;
  return `${' '.repeat(Math.max(0, Math.floor((width - length) / 2) + offset))}${text}`;
}

function projectName() {
  return path.basename(process.cwd()) || 'session';
}

function renderHeader(width: number, phase: number, subtitleText: string) {
  const lines = TITLE_LINES.map((line, row) => gradientText(center(line, width), phase + row * 0.045));
  const phrase = center('도련님, 귀환하시니 터미널이 다시 빛나옵니다.', width, 1);
  const subtitle = center(subtitleText, width);

  return ['', ...lines, fg(MEDIUM_GREY, phrase), '', `${BOLD}${gradientText(subtitle, phase + 0.18)}${RESET}`, ''];
}

export default function (pi: ExtensionAPI) {
  let requestRender: (() => void) | undefined;
  let currentModelId = 'no model selected';

  function installHeader(ctx: ExtensionContext) {
    ctx.ui.setHeader((tui): HeaderComponent => {
      requestRender = () => tui.requestRender();

      return {
        render(width: number) {
          return renderHeader(width, 0, `${currentModelId} · ${projectName()}`);
        },
        invalidate() {
          tui.requestRender();
        },
      };
    });
  }

  pi.on('session_start', (_event, ctx) => {
    currentModelId = ctx.model?.id ?? 'no model selected';
    if (!ctx.hasUI) return;
    installHeader(ctx);
  });

  pi.on('model_select', (event) => {
    currentModelId = event.model.id;
    requestRender?.();
  });

  pi.on('session_shutdown', (_event, ctx) => {
    if (ctx.hasUI) ctx.ui.setHeader(undefined);
  });

  pi.registerCommand('hangul-title', {
    description: 'Enable the blue 파이 custom header',
    handler: async (_args, ctx) => {
      installHeader(ctx);
      ctx.ui.notify('Hangul title enabled', 'info');
    },
  });

  pi.registerCommand('hangul-title-builtin', {
    description: "Restore pi's built-in header for this session",
    handler: async (_args, ctx) => {
      ctx.ui.setHeader(undefined);
      ctx.ui.notify('Built-in header restored', 'info');
    },
  });
}
