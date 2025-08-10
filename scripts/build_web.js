const fs = require('fs');
const path = require('path');

// Load environment variables from .env file
function loadEnv() {
  const envPath = path.join(__dirname, '..', '.env');
  const envContent = fs.readFileSync(envPath, 'utf8');
  const env = {};
  
  envContent.split('\n').forEach(line => {
    const [key, ...valueParts] = line.split('=');
    if (key && valueParts.length > 0) {
      env[key.trim()] = valueParts.join('=').trim();
    }
  });
  
  return env;
}

// Replace placeholders in env.js
function buildEnvJs() {
  const env = loadEnv();
  const envJsPath = path.join(__dirname, '..', 'web', 'env.js');
  let envJsContent = fs.readFileSync(envJsPath, 'utf8');
  
  // Replace placeholders with actual values
  Object.keys(env).forEach(key => {
    const placeholder = `{{${key}}}`;
    envJsContent = envJsContent.replace(new RegExp(placeholder, 'g'), env[key]);
  });
  
  fs.writeFileSync(envJsPath, envJsContent);
  console.log('✅ web/env.js built successfully');
}

// Run the build
try {
  buildEnvJs();
} catch (error) {
  console.error('❌ Error building web/env.js:', error.message);
  process.exit(1);
}
