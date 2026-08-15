-- schema.sql을 이미 실행한 프로젝트에 "데모 계정" 기능만 추가하는 증분 마이그레이션
-- SQL Editor에서 이 파일 전체를 한 번만 실행하세요.

-- 1) 데모 계정 표시 컬럼
alter table public.profiles add column if not exists is_demo boolean not null default false;

-- 2) 데모 계정(예: 김성균)이 보낸 것처럼 보이는 자동 응답 메시지를
--    실사용자 세션에서 대신 기록할 수 있도록 허용 (실제 사용자끼리는 영향 없음)
create policy "messages_insert_as_demo_sender"
  on public.messages for insert
  to authenticated
  with check (
    exists (select 1 from public.profiles p where p.id = sender_id and p.is_demo)
  );

-- 3) 상대가 데모 계정인 계약 건은, 실사용자가 상대방 쪽 확인/서명 플래그까지
--    대신 갱신(자동 응답 시뮬레이션)할 수 있도록 허용
create policy "contract_update_demo_counterpart"
  on public.contract_requests for update
  to authenticated
  using (
    exists (select 1 from public.profiles p where p.id in (user_a, user_b) and p.is_demo)
  );
