const express = require('express');
const router = express.Router();
const aiController = require('../controllers/ai.controller');
const authController = require('../controllers/auth.controller');
const authMiddleware = require('../middlewares/auth.middleware');
const {
  getQuotaStatus,
  consumeAiQuota,
  resetDeviceQuota,
} = require('../middlewares/rateLimiter.middleware');

// 0. Các API Auth mới (V2)
router.post('/auth/register', authController.register);
router.post('/auth/login', authController.login);
router.get('/auth/me', authMiddleware, authController.getMe);
router.post('/auth/redeem-code', authMiddleware, authController.redeemCode);

// 1. Health check & Quản lý Quota
router.get('/health', (req, res) => {
  res.status(200).json({ success: true, status: 'OK', timestamp: new Date().toISOString() });
});
router.get('/quota/status', authMiddleware, getQuotaStatus);
router.post('/quota/reset', authMiddleware, resetDeviceQuota);

// 2. Các API gọi AI (Bắt buộc đăng nhập + check Quota)
router.post('/documents/extract-topics', authMiddleware, consumeAiQuota, aiController.extractTopics);
router.post('/tutor/stream', authMiddleware, consumeAiQuota, aiController.streamTutorResponse);
router.post('/quiz/generate', authMiddleware, consumeAiQuota, aiController.generateTechnicalQuiz);
router.post('/quiz/generate-mini', authMiddleware, consumeAiQuota, aiController.generateMiniQuiz);

module.exports = router;