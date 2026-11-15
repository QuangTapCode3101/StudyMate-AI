const express = require('express');
const cors = require('cors');
const apiRoutes = require('./routes/api.routes');

const app = express();

// Middlewares cơ bản
app.use(cors());
app.use(express.json({ limit: '5mb' }));

// Gắn toàn bộ routes vào tiền tố /api/v1
app.use('/api/v1', apiRoutes);

// Xử lý 404
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: { code: 'NOT_FOUND', message: `Không tìm thấy đường dẫn ${req.originalUrl}` },
  });
});

// Xử lý lỗi tập trung 500
app.use((err, req, res, next) => {
  console.error('[Backend Error]:', err);
  res.status(500).json({
    success: false,
    error: {
      code: 'INTERNAL_SERVER_ERROR',
      message: err.message || 'Đã xảy ra lỗi trên máy chủ trung gian.',
    },
  });
});

module.exports = app;