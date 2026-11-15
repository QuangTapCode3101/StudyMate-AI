require('dotenv').config();
const app = require('./src/app');

const PORT = process.env.PORT || 3000;

app.listen(PORT, '0.0.0.0', () => {
  console.log('====================================================');
  console.log(`[StudyMate AI Backend] Server running on port ${PORT}`);
  console.log(`- Local:            http://localhost:${PORT}/api/v1/health`);
  console.log(`- Android Emulator: http://10.0.2.2:${PORT}/api/v1/health`);
  console.log(`- Mock AI Mode:     ${process.env.USE_MOCK_AI === 'true' ? 'ON (Safe for UI testing)' : 'OFF (Live Gemini API)'}`);
  console.log('====================================================');
});