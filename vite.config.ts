import {defineConfig, Plugin} from 'vite';
import fs from 'fs';
import path from 'path';

function flutterRawStaticPlugin(): Plugin {
  return {
    name: 'flutter-raw-static',
    configureServer(server) {
      server.middlewares.use((req, res, next) => {
        if (!req.url) return next();
        let urlPath = req.url.split('?')[0];

        // Normalize flutter_web subpath if requested
        if (urlPath.startsWith('/flutter_web/')) {
          urlPath = urlPath.replace(/^\/flutter_web/, '');
        }

        const isFlutterFile =
          urlPath === '/main.dart.js' ||
          urlPath === '/flutter.js' ||
          urlPath === '/flutter_bootstrap.js' ||
          urlPath === '/flutter_service_worker.js' ||
          urlPath === '/version.json' ||
          urlPath === '/manifest.json' ||
          urlPath.startsWith('/canvaskit/') ||
          urlPath.startsWith('/assets/') ||
          urlPath.startsWith('/icons/');

        if (isFlutterFile) {
          const candidatePaths = [
            path.join(process.cwd(), urlPath),
            path.join(process.cwd(), 'public', urlPath),
            path.join(process.cwd(), 'flutter_web_dist', urlPath),
          ];

          for (const filePath of candidatePaths) {
            if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
              if (urlPath.endsWith('.js') || urlPath.endsWith('.mjs')) {
                res.setHeader('Content-Type', 'text/javascript; charset=utf-8');
              } else if (urlPath.endsWith('.json')) {
                res.setHeader('Content-Type', 'application/json; charset=utf-8');
              } else if (urlPath.endsWith('.wasm')) {
                res.setHeader('Content-Type', 'application/wasm');
              } else if (urlPath.endsWith('.ttf')) {
                res.setHeader('Content-Type', 'font/ttf');
              } else if (urlPath.endsWith('.otf')) {
                res.setHeader('Content-Type', 'font/otf');
              } else if (urlPath.endsWith('.woff')) {
                res.setHeader('Content-Type', 'font/woff');
              } else if (urlPath.endsWith('.woff2')) {
                res.setHeader('Content-Type', 'font/woff2');
              } else if (urlPath.endsWith('.png')) {
                res.setHeader('Content-Type', 'image/png');
              } else if (urlPath.endsWith('.jpg') || urlPath.endsWith('.jpeg')) {
                res.setHeader('Content-Type', 'image/jpeg');
              } else if (urlPath.endsWith('.bin')) {
                res.setHeader('Content-Type', 'application/octet-stream');
              } else if (urlPath.endsWith('.frag')) {
                res.setHeader('Content-Type', 'text/plain');
              }
              res.setHeader('Access-Control-Allow-Origin', '*');
              res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
              res.setHeader('Cross-Origin-Embedder-Policy', 'credentialless');
              res.setHeader('Cache-Control', 'no-cache');
              fs.createReadStream(filePath).pipe(res);
              return;
            }
          }
        }
        next();
      });
    },
  };
}

export default defineConfig(() => {
  return {
    plugins: [flutterRawStaticPlugin()],
    server: {
      port: 3000,
      host: '0.0.0.0',
      hmr: process.env.DISABLE_HMR !== 'true',
      watch: process.env.DISABLE_HMR === 'true' ? null : {},
    },
    build: {
      outDir: 'dist',
      emptyOutDir: true,
    },
  };
});
