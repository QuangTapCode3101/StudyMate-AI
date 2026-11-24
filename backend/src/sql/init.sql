-- 1. Bảng người dùng & gói cước
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    display_name VARCHAR(100) NOT NULL DEFAULT '',
    plan VARCHAR(20) NOT NULL DEFAULT 'FREE' CHECK (plan IN ('FREE', 'PREMIUM')),
    premium_until TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Bảng đếm lượt gọi AI theo ngày
CREATE TABLE IF NOT EXISTS user_quotas (
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    usage_date DATE NOT NULL DEFAULT CURRENT_DATE,
    request_count INT NOT NULL DEFAULT 0,
    PRIMARY KEY (user_id, usage_date)
);

-- 3. Bảng mã kích hoạt Premium
CREATE TABLE IF NOT EXISTS promo_codes (
    code VARCHAR(50) PRIMARY KEY,
    duration_days INT NOT NULL DEFAULT 30,
    max_uses INT NOT NULL DEFAULT 100,
    used_count INT NOT NULL DEFAULT 0,
    expires_at TIMESTAMPTZ NULL
);

-- 4. Bảng lịch sử nhập mã
CREATE TABLE IF NOT EXISTS promo_code_redemptions (
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code VARCHAR(50) NOT NULL REFERENCES promo_codes(code) ON DELETE CASCADE,
    redeemed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, code)
);

-- Dữ liệu mã mẫu phục vụ test & demo
INSERT INTO promo_codes (code, duration_days, max_uses) VALUES
('PTIT2026', 30, 100),
('VIPTEST1', 7, 1)
ON CONFLICT (code) DO NOTHING;