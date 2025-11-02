const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const nodemailer = require('nodemailer');
const stripe = require('stripe')('sk_test_51SP3W4Kej0L6gzL0W09CYqR4R1hDpTCrnrTNhq5iSiLHkJudaVVbXLuE2Sv9grtcwsDDbZJZUL9QNrJjfNzOxqsD00Fwzft5w9');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(bodyParser.json());


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
  res.json({ status: 'ok', message: 'Stripe server is running' });
});

app.listen(PORT, () => {
  console.log(`🚀 Stripe server running on http://localhost:${PORT}`);
});
