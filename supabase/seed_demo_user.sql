-- 테스트용 가상 후보 "김성균" 시드 데이터
--
-- 사용 순서:
-- 1) Supabase 대시보드 > Authentication > Users > Add user 로
--    이메일/비밀번호를 아무거나 입력해 계정을 만들고 "Auto Confirm User"를 체크하세요.
--    (실제 메일함이 필요 없는 테스트 전용 계정입니다)
-- 2) 생성된 사용자 목록에서 UID를 복사하세요.
-- 3) 아래 두 군데의 <DEMO_USER_UID> 를 복사한 UID로 바꾼 뒤,
--    SQL Editor에서 이 파일 전체를 실행하세요.

insert into public.profiles (id, email, name, is_demo)
values ('68a3110e-9ecc-4bd0-b694-db2c07d20206', 'hellov@g.skku.edu', '김성균', true)
on conflict (id) do update set name = excluded.name, is_demo = true;

insert into public.lifestyle_profiles (
  id, bedtime, wake_time, alarm, cleaning, dishes, call_place, earphone, guests, drinking,
  radius_km, deposit, rent_min, rent_max,
  diligence_pct, clean_pct, sensitivity_pct, tight_pct, type_code, updated_at
) values (
  '68a3110e-9ecc-4bd0-b694-db2c07d20206',
  '24~02시', '08:20', '보통', '주 2~3회', '바로 하는 편',
  '방 안에서', '상황에 따라', '사전 협의 필수', '주 1~2회',
  1.2, 800, 35, 45,
  63, 75, 70, 91, '부깔예빠', now()
)
on conflict (id) do update set
  diligence_pct = excluded.diligence_pct,
  clean_pct = excluded.clean_pct,
  sensitivity_pct = excluded.sensitivity_pct,
  tight_pct = excluded.tight_pct,
  type_code = excluded.type_code,
  updated_at = now();
