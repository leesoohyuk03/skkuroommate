-- schema.sql을 이미 실행한 프로젝트에 "계약 취소" + "최초 로그인 시 이용약관 동의" 기능만
-- 추가하는 증분 마이그레이션. SQL Editor에서 이 파일 전체를 한 번만 실행하세요.

-- 1) 계약 취소(삭제) 허용
create policy "contract_delete_participant"
  on public.contract_requests for delete
  to authenticated
  using (auth.uid() = user_a or auth.uid() = user_b);

-- 2) profiles에 이용약관 동의 시각 컬럼 추가
alter table public.profiles add column if not exists terms_agreed_at timestamptz;
