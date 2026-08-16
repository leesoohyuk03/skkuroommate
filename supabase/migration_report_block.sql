-- schema.sql을 이미 실행한 프로젝트에 "기본 프로필(성별/나이/단과대/흡연여부) + 신고/차단" 기능만
-- 추가하는 증분 마이그레이션. SQL Editor에서 이 파일 전체를 한 번만 실행하세요.

-- 1) profiles에 기본 프로필 컬럼 추가
alter table public.profiles add column if not exists gender text check (gender in ('male', 'female'));
alter table public.profiles add column if not exists age int check (age between 17 and 99);
alter table public.profiles add column if not exists college text;
alter table public.profiles add column if not exists is_smoker boolean;

-- 2) 차단 테이블
create table if not exists public.user_blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id)
);

alter table public.user_blocks enable row level security;

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

-- 3) 신고 테이블
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

-- 4) 메시지 발송을 차단 관계(양방향)에서 막도록 messages insert 정책 교체
drop policy if exists "messages_insert_as_sender" on public.messages;

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
