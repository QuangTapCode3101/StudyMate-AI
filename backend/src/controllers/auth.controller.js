const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/db');

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function formatUser(row) {
  const isPremium =
    row.plan === 'PREMIUM' &&
    row.premium_until &&
    new Date(row.premium_until) > new Date();

  return {
    id: row.id,
    email: row.email,
    displayName: row.display_name,
    plan: isPremium ? 'PREMIUM' : 'FREE',
    premiumUntil: isPremium ? new Date(row.premium_until).toISOString() : null,
  };
}

function signToken(userId) {
  return jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '30d',
  });
}

async function register(req, res) {
  try {
    const email = (req.body.email || '').trim().toLowerCase();
    const password = req.body.password || '';
    const displayName = (req.body.displayName || '').trim() || email.split('@')[0];

    if (!EMAIL_REGEX.test(email) || password.length < 6) {
      return res.status(400).json({
        error: 'INVALID_INPUT',
        message: 'Email không hợp lệ hoặc mật khẩu dưới 6 ký tự.',
      });
    }

    const exists = await db.query('SELECT id FROM users WHERE email = $1', [email]);
    if (exists.rows.length > 0) {
      return res.status(409).json({
        error: 'EMAIL_EXISTS',
        message: 'Email đã được sử dụng.',
      });
    }

    const hash = await bcrypt.hash(password, 10);
    const { rows } = await db.query(
      `INSERT INTO users (email, password_hash, display_name)
       VALUES ($1, $2, $3)
       RETURNING id, email, display_name, plan, premium_until`,
      [email, hash, displayName]
    );

    const user = formatUser(rows[0]);
    return res.status(201).json({ token: signToken(user.id), user });
  } catch (err) {
    return res.status(500).json({ error: 'SERVER_ERROR', message: err.message });
  }
}

async function login(req, res) {
  try {
    const email = (req.body.email || '').trim().toLowerCase();
    const password = req.body.password || '';

    const { rows } = await db.query(
      'SELECT id, email, password_hash, display_name, plan, premium_until FROM users WHERE email = $1',
      [email]
    );
    if (rows.length === 0) {
      return res.status(401).json({
        error: 'INVALID_CREDENTIALS',
        message: 'Email hoặc mật khẩu không đúng.',
      });
    }

    const valid = await bcrypt.compare(password, rows[0].password_hash);
    if (!valid) {
      return res.status(401).json({
        error: 'INVALID_CREDENTIALS',
        message: 'Email hoặc mật khẩu không đúng.',
      });
    }

    const user = formatUser(rows[0]);
    return res.status(200).json({ token: signToken(user.id), user });
  } catch (err) {
    return res.status(500).json({ error: 'SERVER_ERROR', message: err.message });
  }
}

async function getMe(req, res) {
  return res.status(200).json({ user: req.user });
}

async function redeemCode(req, res) {
  const code = (req.body.code || '').trim().toUpperCase();
  if (!code) {
    return res.status(400).json({ error: 'INVALID_CODE', message: 'Mã không hợp lệ.' });
  }

  const client = await db.getClient();
  try {
    await client.query('BEGIN');

    const codeRes = await client.query(
      'SELECT * FROM promo_codes WHERE code = $1',
      [code]
    );
    if (codeRes.rows.length === 0 || (codeRes.rows[0].expires_at && new Date(codeRes.rows[0].expires_at) <= new Date())) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'INVALID_CODE', message: 'Mã không tồn tại hoặc đã hết hạn.' });
    }

    const usedRes = await client.query(
      'SELECT 1 FROM promo_code_redemptions WHERE user_id = $1 AND code = $2',
      [req.user.id, code]
    );
    if (usedRes.rows.length > 0) {
      await client.query('ROLLBACK');
      return res.status(409).json({ error: 'CODE_ALREADY_USED', message: 'Bạn đã dùng mã này rồi.' });
    }

    const updCode = await client.query(
      `UPDATE promo_codes SET used_count = used_count + 1
       WHERE code = $1 AND used_count < max_uses RETURNING duration_days`,
      [code]
    );
    if (updCode.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(410).json({ error: 'CODE_EXHAUSTED', message: 'Mã đã hết lượt sử dụng.' });
    }

    const days = updCode.rows[0].duration_days;
    await client.query(
      'INSERT INTO promo_code_redemptions (user_id, code) VALUES ($1, $2)',
      [req.user.id, code]
    );

    const updUser = await client.query(
      `UPDATE users
       SET plan = 'PREMIUM',
           premium_until = GREATEST(COALESCE(premium_until, NOW()), NOW()) + ($2 || ' days')::INTERVAL
       WHERE id = $1
       RETURNING id, email, display_name, plan, premium_until`,
      [req.user.id, days]
    );

    await client.query('COMMIT');
    return res.status(200).json({
      message: `Kích hoạt gói Premium thành công (+${days} ngày).`,
      user: formatUser(updUser.rows[0]),
    });
  } catch (err) {
    await client.query('ROLLBACK');
    return res.status(500).json({ error: 'SERVER_ERROR', message: err.message });
  } finally {
    client.release();
  }
}

module.exports = { register, login, getMe, redeemCode };