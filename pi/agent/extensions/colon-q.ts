import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';

export default function (pi: ExtensionAPI) {
  pi.on('input', (event, ctx) => {
    if (event.source === 'interactive' && event.text === ':q' && (event.images?.length ?? 0) === 0) {
      if (!ctx.isIdle()) ctx.abort();
      ctx.shutdown();
      return { action: 'handled' };
    }

    return { action: 'continue' };
  });
}
