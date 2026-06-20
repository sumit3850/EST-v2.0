/**
 * EST v2.0 — Cloudflare Worker: Payment Gateway
 *
 * Environment variables required (set via wrangler secret):
 *   RAZORPAY_KEY_ID      — Razorpay API key ID
 *   RAZORPAY_KEY_SECRET  — Razorpay API key secret
 *   JWT_PRIVATE_KEY_JWK  — ECDSA P-256 private key as JSON string (JWK format)
 *   ALLOWED_ORIGIN       — e.g. https://sumit3850.github.io
 *
 * To generate keys:
 *   node -e "
 *     const {webcrypto}=require('crypto');
 *     webcrypto.subtle.generateKey({name:'ECDSA',namedCurve:'P-256'},true,['sign','verify'])
 *     .then(async k=>{
 *       const priv=await webcrypto.subtle.exportKey('jwk',k.privateKey);
 *       const pub=await webcrypto.subtle.exportKey('jwk',k.publicKey);
 *       console.log('PRIVATE:',JSON.stringify(priv));
 *       console.log('PUBLIC:',JSON.stringify(pub));
 *     });
 *   "
 * Copy the PUBLIC key x/y values into EST_PUB_KEY_JWK in index.html.
 * Store the PRIVATE key JSON as the JWT_PRIVATE_KEY_JWK secret in Cloudflare.
 */

const PRICE_PAISE = 149900; // ₹1499 in paise

function cors(env) {
  const origin = env.ALLOWED_ORIGIN || 'https://sumit3850.github.io';
  return {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Content-Type': 'application/json',
  };
}

function json(data, status = 200, env) {
  return new Response(JSON.stringify(data), { status, headers: cors(env) });
}

async function razorpayRequest(path, body, env) {
  const creds = btoa(env.RAZORPAY_KEY_ID + ':' + env.RAZORPAY_KEY_SECRET);
  const res = await fetch('https://api.razorpay.com/v1' + path, {
    method: 'POST',
    headers: { Authorization: 'Basic ' + creds, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  return res.json();
}

async function signJWT(payload, env) {
  const privJwk = JSON.parse(env.JWT_PRIVATE_KEY_JWK);
  const key = await crypto.subtle.importKey(
    'jwk', privJwk,
    { name: 'ECDSA', namedCurve: 'P-256' },
    false, ['sign']
  );
  const header = btoa(JSON.stringify({ alg: 'ES256', typ: 'JWT' }))
    .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  const body = btoa(JSON.stringify(payload))
    .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  const sigInput = new TextEncoder().encode(header + '.' + body);
  const sigBuf = await crypto.subtle.sign({ name: 'ECDSA', hash: 'SHA-256' }, key, sigInput);
  const sig = btoa(String.fromCharCode(...new Uint8Array(sigBuf)))
    .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  return header + '.' + body + '.' + sig;
}

async function verifyRazorpaySignature(orderId, paymentId, signature, env) {
  const msg = new TextEncoder().encode(orderId + '|' + paymentId);
  const keyBytes = new TextEncoder().encode(env.RAZORPAY_KEY_SECRET);
  const key = await crypto.subtle.importKey('raw', keyBytes, { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const mac = await crypto.subtle.sign('HMAC', key, msg);
  const expected = Array.from(new Uint8Array(mac)).map(b => b.toString(16).padStart(2, '0')).join('');
  return expected === signature;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: cors(env) });
    }

    if (request.method !== 'POST') {
      return json({ error: 'Method not allowed' }, 405, env);
    }

    try {
      const body = await request.json();

      if (url.pathname === '/create-order') {
        const order = await razorpayRequest('/orders', {
          amount: PRICE_PAISE,
          currency: 'INR',
          receipt: 'est-' + Date.now(),
        }, env);
        return json({ id: order.id, amount: order.amount, key_id: env.RAZORPAY_KEY_ID }, 200, env);
      }

      if (url.pathname === '/verify-payment') {
        const { order_id, payment_id, signature } = body;
        if (!order_id || !payment_id || !signature) {
          return json({ error: 'Missing fields' }, 400, env);
        }
        const valid = await verifyRazorpaySignature(order_id, payment_id, signature, env);
        if (!valid) {
          return json({ error: 'Invalid signature' }, 403, env);
        }
        const now = Math.floor(Date.now() / 1000);
        const token = await signJWT({
          sub: 'EST-license',
          iat: now,
          exp: now + 60 * 60 * 24 * 365 * 20, // 20 years
          order_id,
          payment_id,
        }, env);
        return json({ token }, 200, env);
      }

      return json({ error: 'Not found' }, 404, env);
    } catch (e) {
      return json({ error: 'Internal error', detail: e.message }, 500, env);
    }
  },
};
