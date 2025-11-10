const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const nodemailer = require('nodemailer');
const stripe = require('stripe')('sk_test_51SP3W4Kej0L6gzL0W09CYqR4R1hDpTCrnrTNhq5iSiLHkJudaVVbXLuE2Sv9grtcwsDDbZJZUL9QNrJjfNzOxqsD00Fwzft5w9');
const fs = require('fs');
const path = require('path');
const multer = require('multer');
// Firebase Admin for FCM push notifications
const admin = require('firebase-admin');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(bodyParser.json());

// --------------------------
// Basic request logger (helps debug 404 on teammate machines)
// --------------------------
app.use((req, _res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.originalUrl}`);
  next();
});

// --------------------------
// Static video directory
// --------------------------
const uploadsDir = path.join(__dirname, 'uploads', 'videos');
fs.mkdirSync(uploadsDir, { recursive: true });
app.use('/videos', express.static(uploadsDir));

// --------------------------
// Simple JSON storage for video metadata
// --------------------------
const dataDir = path.join(__dirname, 'data');
fs.mkdirSync(dataDir, { recursive: true });
const videosDBPath = path.join(dataDir, 'videos.json');
if (!fs.existsSync(videosDBPath)) fs.writeFileSync(videosDBPath, '[]', 'utf8');

// --------------------------
// Firebase Admin initialization (expects serviceAccountKey.json in server root)
// --------------------------
try {
  const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
  if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log('✅ Firebase Admin initialized for FCM');
  } else {
    console.warn('⚠️  serviceAccountKey.json not found - FCM notifications disabled');
  }
} catch (e) {
  console.error('Failed to init Firebase Admin:', e);
}

function readVideos() {
  try { return JSON.parse(fs.readFileSync(videosDBPath, 'utf8')); } catch { return []; }
}
function writeVideos(list) {
  try { fs.writeFileSync(videosDBPath, JSON.stringify(list, null, 2), 'utf8'); } catch (e) { console.error('Write videos failed', e); }
}

// --------------------------
// Multer config for video uploads
// --------------------------
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadsDir),
  filename: (req, file, cb) => {
    const safe = file.originalname.replace(/[^a-zA-Z0-9_.-]/g, '_');
    cb(null, `${Date.now()}-${safe}`);
  }
});
const upload = multer({ storage });


const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'lefi.amine@esprit.tn',
    pass: 'cmle qdix mhpf fymv'
  }
});

app.post('/create-payment-intent', async (req, res) => {
  try {
    const { amount, currency } = req.body;

    if (!amount || !currency) {
      return res.status(400).json({ error: 'Amount and currency are required' });
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount: parseInt(amount),
      currency: currency,
      automatic_payment_methods: {
        enabled: true,
      },
    });

    res.json({
      clientSecret: paymentIntent.client_secret,
    });
  } catch (error) {
    console.error('Error creating payment intent:', error);
    res.status(500).json({ error: error.message });
  }
});

app.post('/send-cart-confirmation', async (req, res) => {
  try {
    const { userEmail, productName, productPrice, quantity } = req.body;

    if (!userEmail || !productName) {
      return res.status(400).json({ error: 'Email and product name are required' });
    }

    const mailOptions = {
      from: 'lefi.amine@esprit.tn',
      to: userEmail,
      subject: '🛒 Item Added to Your Cart - YourLeague',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #333;">Item Added to Cart!</h2>
          <p>Hi there,</p>
          <p>The following item has been added to your shopping cart:</p>
          <div style="background-color: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <h3 style="margin-top: 0;">${productName}</h3>
            <p><strong>Price:</strong> $${productPrice}</p>
            <p><strong>Quantity:</strong> ${quantity}</p>
          </div>
          <p>Ready to checkout? Head back to the app to complete your purchase!</p>
          <p style="color: #666; font-size: 12px; margin-top: 30px;">
            This is an automated message from YourLeague Shop.
          </p>
        </div>
      `
    };

    await transporter.sendMail(mailOptions);
    res.json({ success: true, message: 'Email sent successfully' });
  } catch (error) {
    console.error('Error sending email:', error);
    res.status(500).json({ error: error.message });
  }
});

app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    message: 'Stripe server is running',
    cwd: process.cwd(),
    port: PORT,
    time: new Date().toISOString()
  });
});

// --------------------------
// Debug: list registered routes
// --------------------------
app.get('/debug/routes', (req, res) => {
  try {
    const routes = [];
    app._router.stack.forEach((m) => {
      if (m.route) {
        const methods = Object.keys(m.route.methods).join(',').toUpperCase();
        routes.push({ path: m.route.path, methods });
      } else if (m.name === 'router' && m.handle?.stack) {
        m.handle.stack.forEach((s) => {
          if (s.route) {
            const methods = Object.keys(s.route.methods).join(',').toUpperCase();
            routes.push({ path: s.route.path, methods });
          }
        });
      }
    });
    res.json({ count: routes.length, routes });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// =============================
// Video API
// =============================
// Upload match video
app.post('/matches/:matchId/videos', upload.single('video'), (req, res) => {
  try {
    const { matchId } = req.params;
    const { title } = req.body;
    if (!req.file) return res.status(400).json({ error: 'Missing file field "video"' });
    const filename = req.file.filename;
    const url = `${req.protocol}://${req.get('host')}/videos/${filename}`;
    const videos = readVideos();
    const record = { id: `${Date.now()}`, matchId, title: title || null, filename, url, uploadedAt: new Date().toISOString() };
    videos.push(record);
    writeVideos(videos);
    res.status(201).json(record);
  } catch (e) {
    console.error('Upload error:', e);
    res.status(500).json({ error: e.message });
  }
});

// List videos for match
app.get('/matches/:matchId/videos', (req, res) => {
  try {
    const { matchId } = req.params;
    const videos = readVideos().filter(v => v.matchId === matchId);
    res.json(videos);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// =============================
// Match Notification API
// =============================
app.post('/matches/:matchId/notify', async (req, res) => {
  try {
    const { matchId } = req.params;
    const { recipients, subject, message } = req.body;
    if (!Array.isArray(recipients) || recipients.length === 0) {
      return res.status(400).json({ error: 'Recipients array required' });
    }
    const mails = recipients.map(to => transporter.sendMail({
      from: 'lefi.amine@esprit.tn',
      to,
      subject: subject || `Match ${matchId} Update`,
      html: message || `<p>Update for match <strong>${matchId}</strong>.</p>`
    }));
    await Promise.all(mails);
    res.json({ success: true, sent: recipients.length });
  } catch (e) {
    console.error('Notify error:', e);
    res.status(500).json({ error: e.message });
  }
});

// Lightweight ping for notify route (GET) to quickly test 200/404 from browsers
app.get('/matches/:matchId/notify/ping', (req, res) => {
  const { matchId } = req.params;
  res.json({ ok: true, matchId, route: '/matches/:matchId/notify' });
});

// =============================
// Match Push Notification API (FCM)
// =============================
// Send a push notification to a match topic: /topics/match_<matchId>
app.post('/matches/:matchId/push', async (req, res) => {
  if (!admin.apps.length) {
    return res.status(500).json({ error: 'FCM not configured (missing serviceAccountKey.json)' });
  }
  try {
    const { matchId } = req.params;
    const { title, body } = req.body;
    if (!title || !body) {
      return res.status(400).json({ error: 'title and body are required' });
    }
    const topic = `match_${matchId}`;
    const message = {
      notification: { title, body },
      topic,
    };
    const response = await admin.messaging().send(message);
    res.json({ success: true, id: response, topic });
  } catch (e) {
    console.error('Push error:', e);
    res.status(500).json({ error: e.message });
  }
});

app.listen(PORT, () => {
  console.log(`🚀 Stripe server running on http://localhost:${PORT}`);
  console.log(`📺 Video upload dir: ${uploadsDir}`);
  console.log('📢 Push endpoint: POST /matches/:matchId/push');
});
