-- Core DDL for modular ecommerce system (MySQL 8.0)
-- Charset / collation strategy
CREATE DATABASE IF NOT EXISTS ecommerce
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE ecommerce;

-- =========================
-- 1) User Domain
-- =========================
CREATE TABLE IF NOT EXISTS user (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  mobile VARCHAR(20) NOT NULL,
  email VARCHAR(128) DEFAULT NULL,
  password_hash VARCHAR(255) NOT NULL,
  nickname VARCHAR(64) DEFAULT NULL,
  status TINYINT NOT NULL DEFAULT 1 COMMENT '1-active,0-disabled',
  level TINYINT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_user_mobile (mobile),
  UNIQUE KEY uk_user_email (email),
  KEY idx_user_created_at (created_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS user_address (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  receiver_name VARCHAR(64) NOT NULL,
  receiver_mobile VARCHAR(20) NOT NULL,
  province VARCHAR(32) NOT NULL,
  city VARCHAR(32) NOT NULL,
  district VARCHAR(32) NOT NULL,
  detail_address VARCHAR(255) NOT NULL,
  is_default TINYINT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_addr_user_id (user_id),
  CONSTRAINT fk_addr_user FOREIGN KEY (user_id) REFERENCES user(id)
) ENGINE=InnoDB;

-- =========================
-- 2) Product Domain
-- =========================
CREATE TABLE IF NOT EXISTS product_spu (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  title VARCHAR(255) NOT NULL,
  sub_title VARCHAR(255) DEFAULT NULL,
  category_id BIGINT UNSIGNED NOT NULL,
  brand_id BIGINT UNSIGNED DEFAULT NULL,
  status TINYINT NOT NULL DEFAULT 1 COMMENT '1-on shelf,0-off shelf',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_spu_category (category_id),
  KEY idx_spu_status (status)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS product_sku (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  spu_id BIGINT UNSIGNED NOT NULL,
  sku_code VARCHAR(64) NOT NULL,
  attrs_json JSON DEFAULT NULL,
  sale_price DECIMAL(10,2) NOT NULL,
  market_price DECIMAL(10,2) DEFAULT NULL,
  status TINYINT NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_sku_code (sku_code),
  KEY idx_sku_spu_id (spu_id),
  KEY idx_sku_status (status),
  CONSTRAINT fk_sku_spu FOREIGN KEY (spu_id) REFERENCES product_spu(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS inventory (
  sku_id BIGINT UNSIGNED PRIMARY KEY,
  total_stock INT NOT NULL DEFAULT 0,
  available_stock INT NOT NULL DEFAULT 0,
  locked_stock INT NOT NULL DEFAULT 0,
  version BIGINT NOT NULL DEFAULT 0,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_inventory_sku FOREIGN KEY (sku_id) REFERENCES product_sku(id)
) ENGINE=InnoDB;

-- =========================
-- 3) Coupon / Activity Domain
-- =========================
CREATE TABLE IF NOT EXISTS coupon_template (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(128) NOT NULL,
  type TINYINT NOT NULL COMMENT '1-cash,2-discount,3-threshold',
  threshold_amount DECIMAL(10,2) DEFAULT NULL,
  discount_amount DECIMAL(10,2) DEFAULT NULL,
  discount_rate DECIMAL(5,2) DEFAULT NULL,
  total_count INT NOT NULL DEFAULT 0,
  received_count INT NOT NULL DEFAULT 0,
  valid_from DATETIME NOT NULL,
  valid_to DATETIME NOT NULL,
  status TINYINT NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_coupon_tpl_status (status),
  KEY idx_coupon_tpl_valid (valid_from, valid_to)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS coupon_user (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  template_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  coupon_code VARCHAR(64) NOT NULL,
  status TINYINT NOT NULL DEFAULT 0 COMMENT '0-unused,1-locked,2-used,3-expired',
  lock_order_no VARCHAR(64) DEFAULT NULL,
  used_order_no VARCHAR(64) DEFAULT NULL,
  received_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  lock_expire_at DATETIME DEFAULT NULL,
  used_at DATETIME DEFAULT NULL,
  expire_at DATETIME NOT NULL,
  UNIQUE KEY uk_coupon_code (coupon_code),
  KEY idx_coupon_user (user_id, status),
  KEY idx_coupon_tpl_user (template_id, user_id),
  CONSTRAINT fk_coupon_user_tpl FOREIGN KEY (template_id) REFERENCES coupon_template(id),
  CONSTRAINT fk_coupon_user_user FOREIGN KEY (user_id) REFERENCES user(id)
) ENGINE=InnoDB;

-- =========================
-- 4) Order / Payment Domain
-- =========================
CREATE TABLE IF NOT EXISTS order_main (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  order_no VARCHAR(64) NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  order_status TINYINT NOT NULL COMMENT '10-created,20-pending_pay,30-paid,40-shipped,50-finished,60-closed',
  total_amount DECIMAL(10,2) NOT NULL,
  discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  payable_amount DECIMAL(10,2) NOT NULL,
  coupon_user_id BIGINT UNSIGNED DEFAULT NULL,
  address_snapshot_json JSON NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  paid_at DATETIME DEFAULT NULL,
  closed_at DATETIME DEFAULT NULL,
  UNIQUE KEY uk_order_no (order_no),
  KEY idx_order_user_id (user_id),
  KEY idx_order_status_created (order_status, created_at),
  CONSTRAINT fk_order_user FOREIGN KEY (user_id) REFERENCES user(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS order_item (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  order_no VARCHAR(64) NOT NULL,
  sku_id BIGINT UNSIGNED NOT NULL,
  sku_name VARCHAR(255) NOT NULL,
  sku_attrs_json JSON DEFAULT NULL,
  sale_price DECIMAL(10,2) NOT NULL,
  quantity INT NOT NULL,
  line_amount DECIMAL(10,2) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_order_item_order_no (order_no),
  KEY idx_order_item_sku_id (sku_id),
  CONSTRAINT fk_order_item_order_no FOREIGN KEY (order_no) REFERENCES order_main(order_no),
  CONSTRAINT fk_order_item_sku FOREIGN KEY (sku_id) REFERENCES product_sku(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS order_payment (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  pay_no VARCHAR(64) NOT NULL,
  order_no VARCHAR(64) NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  channel TINYINT NOT NULL COMMENT '1-wechat,2-alipay',
  pay_status TINYINT NOT NULL DEFAULT 10 COMMENT '10-created,20-paying,30-success,40-failed,50-refunded',
  amount DECIMAL(10,2) NOT NULL,
  third_trade_no VARCHAR(128) DEFAULT NULL,
  callback_payload JSON DEFAULT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  paid_at DATETIME DEFAULT NULL,
  UNIQUE KEY uk_pay_no (pay_no),
  UNIQUE KEY uk_order_no_channel (order_no, channel),
  KEY idx_payment_user_id (user_id),
  KEY idx_payment_status_created (pay_status, created_at),
  CONSTRAINT fk_payment_order_no FOREIGN KEY (order_no) REFERENCES order_main(order_no),
  CONSTRAINT fk_payment_user FOREIGN KEY (user_id) REFERENCES user(id)
) ENGINE=InnoDB;

-- =========================
-- 5) Reliability (Outbox + Idempotency)
-- =========================
CREATE TABLE IF NOT EXISTS outbox_event (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  aggregate_type VARCHAR(64) NOT NULL,
  aggregate_id VARCHAR(64) NOT NULL,
  event_type VARCHAR(64) NOT NULL,
  payload_json JSON NOT NULL,
  status TINYINT NOT NULL DEFAULT 0 COMMENT '0-new,1-sent,2-failed',
  retry_count INT NOT NULL DEFAULT 0,
  next_retry_at DATETIME DEFAULT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_outbox_status_retry (status, next_retry_at),
  KEY idx_outbox_aggregate (aggregate_type, aggregate_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS idempotency_record (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  idem_key VARCHAR(128) NOT NULL,
  biz_type VARCHAR(64) NOT NULL,
  biz_id VARCHAR(64) DEFAULT NULL,
  response_json JSON DEFAULT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_idem_key_biz_type (idem_key, biz_type),
  KEY idx_idem_created_at (created_at)
) ENGINE=InnoDB;
