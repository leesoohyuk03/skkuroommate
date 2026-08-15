-- 성균 룸메 · Supabase 스키마
-- Supabase 대시보드 > SQL Editor 에서 그대로 실행하세요.

-- ============================================================
-- 1. profiles : 인증된 학생 1명당 1행 (이름 서비스용)
-- ============================================================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  name text,
  is_demo boolean not null default false, -- 테스트용 가상 후보(예: 김성균) 표시
  created_at timestamptz not null default now()
);

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
-- 3. messages : 1:1 실시간 채팅
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
  with check (auth.uid() = sender_id);

-- 테스트용: is_demo=true 계정(예: 김성균)이 보낸 것처럼 보이는 자동 응답 메시지를
-- 실사용자 세션에서 대신 기록할 수 있도록 허용합니다. 실제 사용자끼리는 영향 없음.
create policy "messages_insert_as_demo_sender"
  on public.messages for insert
  to authenticated
  with check (
    exists (select 1 from public.profiles p where p.id = sender_id and p.is_demo)
  );

-- ============================================================
-- 4. contract_requests : 계약 상호 확인 상태 + 협약서 내용
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

-- 테스트용: 상대가 is_demo=true 계정(예: 김성균)인 계약 건은, 실사용자가
-- 상대방 쪽 확인/서명 플래그까지 대신 갱신(자동 응답 시뮬레이션)할 수 있도록 허용합니다.
create policy "contract_update_demo_counterpart"
  on public.contract_requests for update
  to authenticated
  using (
    exists (select 1 from public.profiles p where p.id in (user_a, user_b) and p.is_demo)
  );

-- ============================================================
-- 5. Realtime 구독 활성화 (채팅 / 계약 상태 실시간 반영)
-- ============================================================
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.contract_requests;
