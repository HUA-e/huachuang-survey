-- 备考经历与培训支出调查 - 数据库建表脚本
-- 在 Supabase 后台 SQL Editor 里整段执行

create table if not exists public.responses (
  id              bigint generated always as identity primary key,
  created_at      timestamptz not null default now(),

  -- ===== 质控字段（这是自建系统相对问卷星的核心优势，答辩时要用）=====
  client_id       text        not null,          -- 浏览器指纹uuid，同一设备重复提交会被识别
  started_at      timestamptz not null,          -- 打开问卷的时间
  duration_sec    integer     not null,          -- 作答秒数 = created_at - started_at
  ip_hash         text,                          -- IP的sha256，脱敏存，不存明文
  user_agent      text,
  screen_size     text,
  referrer        text,                          -- 从哪个渠道进来的
  quota_cell      text,                          -- 配额归属，如 KAOYAN-3

  -- ===== 作答内容，整份JSON =====
  answers         jsonb       not null,

  -- ===== 冗余出来便于分析的常用字段（可选，分析时可直接group by）=====
  q_s1            text,
  q_s2            text,
  q_s3            text,
  q_s4            text,   -- 备考类型：决定配额
  q_s5            text,
  q6_total        numeric,        -- 总支出
  q8_class        text,   -- 是否报班
  q9_xieyi        text,   -- 是否协议班
  q10_amount      numeric,        -- 协议班金额
  q16_refund      text,   -- 退费结果
  d1_gender       text,
  d2_grade        text,
  d3_major        text,
  d4_origin       text,
  a1_trap_ok      boolean,        -- 测谎题是否答对
  a2_sincere      text,
  analysis_stage  text,           -- core=实质备考 / prospect=前瞻人群（分析分层用）

  -- ===== 清洗结果 =====
  is_valid        boolean     not null default true,
  invalid_reason  text
);

create index if not exists responses_created_idx on public.responses (created_at desc);
create index if not exists responses_valid_idx   on public.responses (is_valid);
create index if not exists responses_s4_idx      on public.responses (q_s4);

-- 行级安全：只允许匿名插入，不允许匿名读取（防止别人把你的数据扒走）
alter table public.responses enable row level security;

drop policy if exists "anon can insert" on public.responses;
create policy "anon can insert"
  on public.responses
  for insert
  to anon
  with check (true);

-- 注意：不要给 anon 开 select 策略。读取一律走后台或 service_role。
