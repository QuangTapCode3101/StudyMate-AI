const express = require('express');
const router = express.Router();
const authMiddleware = require('../middlewares/authMiddleware');
const { getLimitsForPlan, getUserDailyUsage } = require('../middlewares/quotaLimiter');

router.get('/status', authMiddleware, async (req, res) => {
  try {
    const { id: userId, plan } = req.user;
    const limits = getLimitsForPlan(plan);
    const usedDaily = await getUserDailyUsage(userId);

    return res.status(200).json({
      success: true,
      quota: {
        plan,
        usedDaily,
        remainingDaily: Math.max(0, limits.maxDaily - usedDaily),
        maxDaily: limits.maxDaily,
      },
    });
  } catch (err) {
    console.error('Lỗi GET /quota/status:', err);
    return res.status(500).json({
      error: 'INTERNAL_SERVER_ERROR',
      message: 'Không thể lấy trạng thái hạn mức sử dụng.',
    });
  }
});

module.exports = router;