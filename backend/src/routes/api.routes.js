const express = require('express');
const router = express.Router();
const aiController = require('../controllers/ai.controller');
const {
  getQuotaStatus,
  consumeAiQuota,
  resetDeviceQuota,
} = require('../middlewares/rateLimiter.middleware');

// 1. Health check & Quản lý Quota (M1 dùng ở màn hình Home & Settings)
router.get('/health', (req, res) => {
  res.status(200).json({ success: true, status: 'OK', timestamp: new Date().toISOString() });
});
router.get('/quota/status', getQuotaStatus);
router.post('/quota/reset', resetDeviceQuota);

// 2. Các API gọi AI (Đều đi qua cổng kiểm soát consumeAiQuota)
router.post('/documents/extract-topics', consumeAiQuota, aiController.extractTopics);
router.post('/tutor/stream', consumeAiQuota, aiController.streamTutorResponse);
router.post('/quiz/generate', consumeAiQuota, aiController.generateTechnicalQuiz);
router.post('/quiz/generate-mini', consumeAiQuota, aiController.generateMiniQuiz);

module.exports = router;