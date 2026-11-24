const db = require('../config/db');

const PLAN_LIMITS = {
  FREE: {
    maxDaily: parseInt(process.env.FREE_MAX_PER_DAY || '20', 10),
    maxPerMinute: parseInt(process.env.FREE_MAX_PER_MINUTE || '5', 10),
  },
  PREMIUM: {
    maxDaily: parseInt(process.env.PREMIUM_MAX_PER_DAY || '100', 10),
    maxPerMinute: parseInt(process.env.PREMIUM_MAX_PER_MINUTE || '15', 10),
  },
};

// Cửa sổ chống spam theo phút lưu trong RAM theo userId
const userMinuteMap = new Map();

function getLimitsByPlan(plan) {
  return PLAN_LIMITS[plan] || PLAN_LIMITS.FREE;
}

function getOrInitMinuteWindow(userId) {
  const now = Date.now();
  let record = userMinuteMap.get(userId);

  if (!record || now - record.minuteWindowStart >= 60 * 1000) {
    record = {
      minuteWindowStart: now,
      minuteUsed: 0,
    };
    userMinuteMap.set(userId, record);
  }

  return record;
}

async function getDailyUsageFromDb(userId) {
  const { rows } = await db.query(
    `SELECT request_count FROM user_quotas
     WHERE user_id = $1 AND usage_date = CURRENT_DATE`,
    [userId]
  );
  return rows.length > 0 ? rows[0].request_count : 0;
}

// 1. Endpoint GET /api/v1/quota/status (Yêu cầu authMiddleware chạy trước)
const getQuotaStatus = async (req, res) => {
  try {
    const { id: userId, plan } = req.user;
    const limits = getLimitsByPlan(plan);
    const usedDaily = await getDailyUsageFromDb(userId);
    const minuteRecord = getOrInitMinuteWindow(userId);

    return res.status(200).json({
      success: true,
      quota: {
        plan,
        usedDaily,
        remainingDaily: Math.max(0, limits.maxDaily - usedDaily),
        maxDaily: limits.maxDaily,
        remainingMinute: Math.max(0, limits.maxPerMinute - minuteRecord.minuteUsed),
      },
    });
  } catch (err) {
    console.error('Lỗi getQuotaStatus:', err);
    return res.status(500).json({
      success: false,
      error: 'INTERNAL_SERVER_ERROR',
      message: 'Không thể lấy thông tin hạn mức sử dụng.',
    });
  }
};

// 2. Middleware kiểm tra hạn mức trước khi gọi Gemini (Yêu cầu authMiddleware chạy trước)
const consumeAiQuota = async (req, res, next) => {
  try {
    const { id: userId, plan } = req.user;
    const limits = getLimitsByPlan(plan);
    const now = Date.now();

    // Kiểm tra giới hạn theo ngày từ PostgreSQL
    const usedDaily = await getDailyUsageFromDb(userId);
    if (usedDaily >= limits.maxDaily) {
      return res.status(429).json({
        error: 'DAILY_QUOTA_EXCEEDED',
        message: 'Bạn đã hết lượt sử dụng AI hôm nay.',
      });
    }

    // Kiểm tra giới hạn chống spam theo phút
    const minuteRecord = getOrInitMinuteWindow(userId);
    if (minuteRecord.minuteUsed >= limits.maxPerMinute) {
      const retryAfter = Math.ceil(
        (60 * 1000 - (now - minuteRecord.minuteWindowStart)) / 1000
      );
      return res.status(429).json({
        error: 'RATE_LIMIT_EXCEEDED',
        message: `Bạn thao tác quá nhanh (Tối đa ${limits.maxPerMinute} lượt/phút). Vui lòng đợi ${retryAfter} giây.`,
        retryAfterSeconds: retryAfter,
      });
    }

    // Tăng bộ đếm phút để chặn spam ngay lập tức
    // Riêng bộ đếm ngày trong Postgres CHỈ cộng sau khi Gemini trả về thành công
    minuteRecord.minuteUsed += 1;

    req.quotaInfo = {
      usedDaily,
      remainingDaily: Math.max(0, limits.maxDaily - usedDaily),
      maxDaily: limits.maxDaily,
    };

    next();
  } catch (err) {
    console.error('Lỗi consumeAiQuota:', err);
    return res.status(500).json({
      error: 'INTERNAL_SERVER_ERROR',
      message: 'Lỗi hệ thống khi kiểm tra hạn mức AI.',
    });
  }
};

// 3. Hàm cộng 1 lượt vào PostgreSQL (Chỉ gọi trong Controller khi Gemini thành công)
const incrementUserQuota = async (userId) => {
  const { rows } = await db.query(
    `INSERT INTO user_quotas (user_id, usage_date, request_count)
     VALUES ($1, CURRENT_DATE, 1)
     ON CONFLICT (user_id, usage_date)
     DO UPDATE SET request_count = user_quotas.request_count + 1
     RETURNING request_count`,
    [userId]
  );
  return rows[0].request_count;
};

// 4. Hàm hỗ trợ Reset Quota nhanh trong DB khi demo/bảo vệ đồ án
const resetDeviceQuota = async (req, res) => {
  try {
    userMinuteMap.clear();
    if (req.user?.id) {
      await db.query(
        'DELETE FROM user_quotas WHERE user_id = $1 AND usage_date = CURRENT_DATE',
        [req.user.id]
      );
    } else {
      await db.query('DELETE FROM user_quotas WHERE usage_date = CURRENT_DATE');
    }

    return res.status(200).json({
      success: true,
      message: 'Đã reset hạn mức gọi AI hôm nay về ban đầu.',
    });
  } catch (err) {
    console.error('Lỗi resetQuota:', err);
    return res.status(500).json({
      success: false,
      message: 'Không thể reset hạn mức.',
    });
  }
};

module.exports = {
  getQuotaStatus,
  consumeAiQuota,
  incrementUserQuota,
  resetDeviceQuota,
};