import express from 'express';
import { openApiSpec } from '../../docs/openapi.js';

const router = express.Router();

router.get('/openapi.json', (req, res) => {
  res.json(openApiSpec);
});

router.get('/', (req, res) => {
  res.type('html').send(`
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>HR API Docs</title>
    <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css" />
    <style>
      body { margin: 0; background: #f5f7fb; }
    </style>
  </head>
  <body>
    <div id="swagger-ui"></div>
    <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
    <script>
      window.ui = SwaggerUIBundle({
        url: '/api-docs/openapi.json',
        dom_id: '#swagger-ui'
      });
    </script>
  </body>
</html>`);
});

export default router;
