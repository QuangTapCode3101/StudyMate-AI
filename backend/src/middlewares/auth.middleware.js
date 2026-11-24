const jwt = require('jsonwebtoken');
const db = require('../config/db');

const UNAUTHORIZED = {
  error: 'UNAUTHORIZED',
  message: 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn.',
};

async function authMiddleware(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json(UNAUTHORIZED);
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    const { rows } = await db.query(
      'SELECT id, email, display_name, plan, premium_until FROM users WHERE id = $1',
      [decoded.userId]
    );
    if (rows.length === 0) return res.status(401).json(UNAUTHORIZED);

    const user = rows[0];
    const isPremium =
      user.plan === 'PREMIUM' &&
      user.premium_until &&
      new Date(user.premium_until) > new Date();

    req.user = {
      id: user.id,
      email: user.email,
      displayName: user.display_name,
      plan: isPremium ? 'PREMIUM' : 'FREE',
      premiumUntil: isPremium ? user.premium_until : null,
    };
    next();
  } catch (_) {
    return res.status(401).json(UNAUTHORIZED);
  }
}

module.exports = authMiddleware;