-- 성균 룸메 · Supabase 스키마
-- Supabase 대시보드 > SQL Editor 에서 그대로 실행하세요.

-- ============================================================
-- 1. profiles : 인증된 학생 1명당 1행 (이름 서비스용)
-- ============================================================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  name text,
  gender text check (gender in ('male', 'female')),
  age int check (age between 17 and 99),
  college text,
  is_smoker boolean,
  terms_agreed_at timestamptz, -- 최초 로그인 시 이용약관/기본 준수사항 동의 시각 (null = 미동의)
  is_demo boolean not null default false, -- 테스트용 가상 후보(예: 김성균) 표시
  created_at timestamptz not null default now()
);

-- 이미 schema.sql을 실행한 적이 있는 기존 설치에도 새 컬럼이 추가되도록 보강
alter table public.profiles add column if not exists gender text check (gender in ('male', 'female'));
alter table public.profiles add column if not exists age int check (age between 17 and 99);
alter table public.profiles add column if not exists college text;
alter table public.profiles add column if not exists is_smoker boolean;
alter table public.profiles add column if not exists terms_agreed_at timestamptz;

alter table public.profiles enable row level security;

create policy "profiles_select_all_authenticated"
  on public.profiles for select
  to authenticated
  using (true);

create policy "profiles_upsert_own"
  on public.profiles for insert
  to authenticated
  with check (auth.uid() = id);

create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id);

-- ============================================================
-- 2. lifestyle_profiles : 설문 원본 답변 + 계산된 유형(%) / 코드
-- ============================================================
create table if not exists public.lifestyle_profiles (
  id uuid primary key references public.profiles(id) on delete cascade,
  campus text,
  bedtime text,
  wake_time text,
  alarm text,
  cleaning text,
  dishes text,
  call_place text,
  earphone text,
  guests text,
  drinking text,
  radius_km numeric,
  deposit numeric,
  rent_min numeric,
  rent_max numeric,
  diligence_pct numeric not null default 50,   -- 100=부지런함 ↔ 0=게으름
  clean_pct numeric not null default 50,       -- 100=깔끔함   ↔ 0=너저분함
  sensitivity_pct numeric not null default 50, -- 100=예민함   ↔ 0=무던함
  tight_pct numeric not null default 50,       -- 100=예산 빠듯 ↔ 0=예산 여유
  type_code text,
  updated_at timestamptz not null default now()
);

-- 이미 schema.sql을 실행한 적이 있는 기존 설치에도 새 컬럼이 추가되도록 보강
alter table public.lifestyle_profiles add column if not exists campus text;

alter table public.lifestyle_profiles enable row level security;

create policy "lifestyle_select_all_authenticated"
  on public.lifestyle_profiles for select
  to authenticated
  using (true);

create policy "lifestyle_upsert_own"
  on public.lifestyle_profiles for insert
  to authenticated
  with check (auth.uid() = id);

create policy "lifestyle_update_own"
  on public.lifestyle_profiles for update
  to authenticated
  using (auth.uid() = id);

-- ============================================================
-- 3. user_blocks / user_reports : 신고 · 차단
-- ============================================================
create table if not exists public.user_blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id)
);

alter table public.user_blocks enable row level security;

-- 차단 여부는 메시지 발송 제한(양방향)에도 쓰이므로, 차단한 쪽/차단당한 쪽
-- 모두 그 관계의 존재 자체는 조회할 수 있게 허용합니다. (누가 신고했는지 사유는 별도 테이블)
create policy "blocks_select_related"
  on public.user_blocks for select
  to authenticated
  using (auth.uid() = blocker_id or auth.uid() = blocked_id);

create policy "blocks_insert_own"
  on public.user_blocks for insert
  to authenticated
  with check (auth.uid() = blocker_id);

create policy "blocks_delete_own"
  on public.user_blocks for delete
  to authenticated
  using (auth.uid() = blocker_id);

create table if not exists public.user_reports (
  id bigint generated always as identity primary key,
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reported_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null,
  detail text,
  created_at timestamptz not null default now()
);

alter table public.user_reports enable row level security;

create policy "reports_insert_own"
  on public.user_reports for insert
  to authenticated
  with check (auth.uid() = reporter_id);

create policy "reports_select_own"
  on public.user_reports for select
  to authenticated
  using (auth.uid() = reporter_id);

-- ============================================================
-- 4. messages : 1:1 실시간 채팅
-- ============================================================
create table if not exists public.messages (
  id bigint generated always as identity primary key,
  room_id text not null,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now()
);

create index if not exists messages_room_id_idx on public.messages (room_id, created_at);

alter table public.messages enable row level security;

create policy "messages_select_participant"
  on public.messages for select
  to authenticated
  using (auth.uid() = sender_id or auth.uid() = receiver_id);

create policy "messages_insert_as_sender"
  on public.messages for insert
  to authenticated
  with check (
    auth.uid() = sender_id
    and not exists (
      select 1 from public.user_blocks b
      where (b.blocker_id = sender_id and b.blocked_id = receiver_id)
         or (b.blocker_id = receiver_id and b.blocked_id = sender_id)
    )
  );

-- 테스트용: is_demo=true 계정(예: 김성균)이 보낸 것처럼 보이는 자동 응답 메시지를
-- 실사용자 세션에서 대신 기록할 수 있도록 허용합니다. 실제 사용자끼리는 영향 없음.
create policy "messages_insert_as_demo_sender"
  on public.messages for insert
  to authenticated
  with check (
    exists (select 1 from public.profiles p where p.id = sender_id and p.is_demo)
  );

-- ============================================================
-- 5. contract_requests : 계약 상호 확인 상태 + 협약서 내용
-- ============================================================
create table if not exists public.contract_requests (
  id bigint generated always as identity primary key,
  user_a uuid not null references public.profiles(id) on delete cascade, -- 두 uuid 중 사전순으로 작은 쪽
  user_b uuid not null references public.profiles(id) on delete cascade, -- 두 uuid 중 사전순으로 큰 쪽
  a_confirmed boolean not null default false,
  b_confirmed boolean not null default false,
  a_signed boolean not null default false,
  b_signed boolean not null default false,
  contract_data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  unique (user_a, user_b)
);

alter table public.contract_requests enable row level security;

create policy "contract_select_participant"
  on public.contract_requests for select
  to authenticated
  using (auth.uid() = user_a or auth.uid() = user_b);

create policy "contract_insert_participant"
  on public.contract_requests for insert
  to authenticated
  with check (auth.uid() = user_a or auth.uid() = user_b);

create policy "contract_update_participant"
  on public.contract_requests for update
  to authenticated
  using (auth.uid() = user_a or auth.uid() = user_b);

create policy "contract_delete_participant"
  on public.contract_requests for delete
  to authenticated
  using (auth.uid() = user_a or auth.uid() = user_b);

-- 테스트용: 상대가 is_demo=true 계정(예: 김성균)인 계약 건은, 실사용자가
-- 상대방 쪽 확인/서명 플래그까지 대신 갱신(자동 응답 시뮬레이션)할 수 있도록 허용합니다.
create policy "contract_update_demo_counterpart"
  on public.contract_requests for update
  to authenticated
  using (
    exists (select 1 from public.profiles p where p.id in (user_a, user_b) and p.is_demo)
  );

-- ============================================================
-- 6. Realtime 구독 활성화 (채팅 / 계약 상태 실시간 반영)
-- ============================================================
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.contract_requests;
