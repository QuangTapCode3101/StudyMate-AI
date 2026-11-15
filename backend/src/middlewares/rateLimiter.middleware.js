const MAX_PER_MINUTE = parseInt(process.env.MAX_REQUESTS_PER_MINUTE || '5', 10);
const MAX_PER_DAY = parseInt(process.env.MAX_REQUESTS_PER_DAY || '20', 10);

// Lưu trạng thái theo Device ID trong RAM
const deviceQuotaMap = new Map();

function getOrInitQuota(deviceId) {
  const now = Date.now();
  const todayStr = new Date().toISOString().slice(0, 10); // YYYY-MM-DD

  let record = deviceQuotaMap.get(deviceId);
  if (!record || record.dateStr !== todayStr) {
    record = {
      dateStr: todayStr,
      dailyUsed: 0,
      minuteWindowStart: now,
      minuteUsed: 0,
    };
    deviceQuotaMap.set(deviceId, record);
  }

  // Reset cửa sổ 1 phút nếu đã qua 60 giây
  if (now - record.minuteWindowStart >= 60 * 1000) {
    record.minuteWindowStart = now;
    record.minuteUsed = 0;
  }

  return record;
}

// Middleware chỉ đọc trạng thái Quota (Không trừ lượt - Dùng cho màn hình SCR-01 Home)
const getQuotaStatus = (req, res) => {
  const deviceId = req.headers['x-device-id'] || req.ip || 'default_device';
  const record = getOrInitQuota(deviceId);

  return res.status(200).json({
    success: true,
    quota: {
      usedDaily: record.dailyUsed,
      remainingDaily: Math.max(0, MAX_PER_DAY - record.dailyUsed),
      maxDaily: MAX_PER_DAY,
      remainingMinute: Math.max(0, MAX_PER_MINUTE - record.minuteUsed),
    },
  });
};

// Middleware kiểm tra và trừ 1 lượt mỗi khi gọi các API AI
const consumeAiQuota = (req, res, next) => {
  const deviceId = req.headers['x-device-id'] || req.ip || 'default_device';
  const record = getOrInitQuota(deviceId);
  const now = Date.now();

  // 1. Kiểm tra giới hạn theo ngày (VD: 20 lượt/ngày)
  if (record.dailyUsed >= MAX_PER_DAY) {
    return res.status(429).json({
      success: false,
      error: {
        code: 'DAILY_QUOTA_EXCEEDED',
        message: `Bạn đã sử dụng hết ${MAX_PER_DAY}/${MAX_PER_DAY} lượt hỏi AI trong ngày hôm nay.`,
        retryAfterSeconds: 3600,
      },
    });
  }

  // 2. Kiểm tra giới hạn chống spam theo phút (VD: 5 lượt/phút)
  if (record.minuteUsed >= MAX_PER_MINUTE) {
    const retryAfter = Math.ceil((60 * 1000 - (now - record.minuteWindowStart)) / 1000);
    return res.status(429).json({
      success: false,
      error: {
        code: 'RATE_LIMIT_EXCEEDED',
        message: `Bạn thao tác quá nhanh (Tối đa ${MAX_PER_MINUTE} lượt/phút). Vui lòng đợi ${retryAfter} giây.`,
        retryAfterSeconds: retryAfter,
      },
    });
  }

  // Trừ 1 lượt và gắn thông tin quota vào req để Controller trả về cho Flutter
  record.dailyUsed += 1;
  record.minuteUsed += 1;

  req.quotaInfo = {
    remainingDaily: Math.max(0, MAX_PER_DAY - record.dailyUsed),
    maxDaily: MAX_PER_DAY,
  };

  next();
};

// Hàm hỗ trợ Reset Quota nhanh khi nhóm đang đứng bảo vệ đồ án
const resetDeviceQuota = (req, res) => {
  deviceQuotaMap.clear();
  return res.status(200).json({
    success: true,
    message: 'Đã reset toàn bộ hạn mức gọi AI về ban đầu (20/20 lượt).',
  });
};

module.exports = {
  getQuotaStatus,
  consumeAiQuota,
  resetDeviceQuota,
};