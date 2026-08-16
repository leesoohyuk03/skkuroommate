-- 테스트용 가상 후보 4명 시드 데이터 (매칭 대시보드가 비어보이지 않도록)
-- seed_demo_user.sql(김성균 1명)을 대체하는 확장판입니다. 새 프로젝트라면 이 파일 하나만 실행하면 됩니다.
--
-- 사용 순서:
-- 1) Supabase 대시보드 > Authentication > Users > Add user 를 "4번" 반복해서
--    이메일/비밀번호를 아무거나 입력해 계정 4개를 만들고, 매번 "Auto Confirm User"를 체크하세요.
--    (실제 메일함이 필요 없는 테스트 전용 계정입니다. 이메일은 예: demo1@g.skku.edu ~ demo4@g.skku.edu)
-- 2) 생성된 사용자 목록에서 각 계정의 UID를 복사하세요.
-- 3) 아래 <DEMO_1_UID> ~ <DEMO_4_UID> 를 각각 복사한 UID로 바꾼 뒤 (한 인물당 두 군데씩, 총 8곳),
--    SQL Editor에서 이 파일 전체를 실행하세요.

-- ============================================================
-- 1) 김성균 · 남 · 22 · 소프트웨어융합대학 · 자연과학캠퍼스(율전) · 비흡연 · 부지런+깔끔+예민+예산빠듯
-- ============================================================
insert into public.profiles (id, email, name, gender, age, college, is_smoker, is_demo)
values ('a89e769e-bcb6-41e6-8318-c33ba1b898d6', 'demo1@g.skku.edu', '김성균', 'male', 22, '소프트웨어융합대학', false, true)
on conflict (id) do update set
  name = excluded.name, gender = excluded.gender, age = excluded.age,
  college = excluded.college, is_smoker = excluded.is_smoker, is_demo = true;

insert into public.lifestyle_profiles (
  id, campus, bedtime, wake_time, alarm, cleaning, dishes, call_place, earphone, guests, drinking,
  radius_km, deposit, rent_min, rent_max,
  diligence_pct, clean_pct, sensitivity_pct, tight_pct, type_code, updated_at
) values (
  'a89e769e-bcb6-41e6-8318-c33ba1b898d6', '자연과학캠퍼스(율전)',
  '24~02시', '08:20', '보통', '주 2~3회', '바로 하는 편',
  '방 안에서', '상황에 따라', '사전 협의 필수', '주 1~2회',
  1.2, 800, 35, 45,
  63, 75, 70, 91, '부깔예빠', now()
)
on conflict (id) do update set
  campus = excluded.campus,
  diligence_pct = excluded.diligence_pct, clean_pct = excluded.clean_pct,
  sensitivity_pct = excluded.sensitivity_pct, tight_pct = excluded.tight_pct,
  type_code = excluded.type_code, updated_at = now();

-- ============================================================
-- 2) 이하늘 · 여 · 21 · 경영학과 · 인문과학캠퍼스(명륜) · 비흡연 · 부지런+깔끔+무던+예산여유
-- ============================================================
insert into public.profiles (id, email, name, gender, age, college, is_smoker, is_demo)
values ('d4487974-2de9-4279-a798-8de813c8858c', 'demo2@g.skku.edu', '이하늘', 'female', 21, '경영학과', false, true)
on conflict (id) do update set
  name = excluded.name, gender = excluded.gender, age = excluded.age,
  college = excluded.college, is_smoker = excluded.is_smoker, is_demo = true;

insert into public.lifestyle_profiles (
  id, campus, bedtime, wake_time, alarm, cleaning, dishes, call_place, earphone, guests, drinking,
  radius_km, deposit, rent_min, rent_max,
  diligence_pct, clean_pct, sensitivity_pct, tight_pct, type_code, updated_at
) values (
  'd4487974-2de9-4279-a798-8de813c8858c', '인문과학캠퍼스(명륜)',
  '~24시', '07:30', '보통', '매일', '바로 하는 편',
  '방 안에서', '상황에 따라', '사전 협의 필수', '거의 안 마심',
  1.0, 1500, 55, 65,
  80, 85, 40, 25, '부깔무많', now()
)
on conflict (id) do update set
  campus = excluded.campus,
  diligence_pct = excluded.diligence_pct, clean_pct = excluded.clean_pct,
  sensitivity_pct = excluded.sensitivity_pct, tight_pct = excluded.tight_pct,
  type_code = excluded.type_code, updated_at = now();

-- ============================================================
-- 3) 박지훈 · 남 · 23 · 영어영문학과 · 인문과학캠퍼스(명륜) · 흡연 · 게으름+너저분+예민+예산빠듯
-- ============================================================
insert into public.profiles (id, email, name, gender, age, college, is_smoker, is_demo)
values ('0d39e1ed-140c-4431-bb4e-971adeeff815', 'demo3@g.skku.edu', '박지훈', 'male', 23, '영어영문학과', true, true)
on conflict (id) do update set
  name = excluded.name, gender = excluded.gender, age = excluded.age,
  college = excluded.college, is_smoker = excluded.is_smoker, is_demo = true;

insert into public.lifestyle_profiles (
  id, campus, bedtime, wake_time, alarm, cleaning, dishes, call_place, earphone, guests, drinking,
  radius_km, deposit, rent_min, rent_max,
  diligence_pct, clean_pct, sensitivity_pct, tight_pct, type_code, updated_at
) values (
  '0d39e1ed-140c-4431-bb4e-971adeeff815', '인문과학캠퍼스(명륜)',
  '02시 이후', '11:30', '잘 안 깸', '주 1회', '모아서 하는 편',
  '거실 또는 복도에서', '착용 안 함', '자유로움', '주 3회 이상',
  2.5, 500, 30, 35,
  25, 30, 60, 70, '게너예빠', now()
)
on conflict (id) do update set
  campus = excluded.campus,
  diligence_pct = excluded.diligence_pct, clean_pct = excluded.clean_pct,
  sensitivity_pct = excluded.sensitivity_pct, tight_pct = excluded.tight_pct,
  type_code = excluded.type_code, updated_at = now();

-- ============================================================
-- 4) 최유진 · 여 · 20 · 글로벌바이오메디컬공학과 · 자연과학캠퍼스(율전) · 비흡연 · 부지런+깔끔+예민+예산여유
-- ============================================================
insert into public.profiles (id, email, name, gender, age, college, is_smoker, is_demo)
values ('fa32bea6-b16a-40ee-8832-40af989bf3e4', 'demo4@g.skku.edu', '최유진', 'female', 20, '글로벌바이오메디컬공학과', false, true)
on conflict (id) do update set
  name = excluded.name, gender = excluded.gender, age = excluded.age,
  college = excluded.college, is_smoker = excluded.is_smoker, is_demo = true;

insert into public.lifestyle_profiles (
  id, campus, bedtime, wake_time, alarm, cleaning, dishes, call_place, earphone, guests, drinking,
  radius_km, deposit, rent_min, rent_max,
  diligence_pct, clean_pct, sensitivity_pct, tight_pct, type_code, updated_at
) values (
  'fa32bea6-b16a-40ee-8832-40af989bf3e4', '자연과학캠퍼스(율전)',
  '24~02시', '09:00', '보통', '주 2~3회', '바로 하는 편',
  '거실 또는 복도에서', '항상 착용', '사전 협의 필수', '주 1~2회',
  1.8, 1000, 45, 55,
  55, 60, 65, 45, '부깔예많', now()
)
on conflict (id) do update set
  campus = excluded.campus,
  diligence_pct = excluded.diligence_pct, clean_pct = excluded.clean_pct,
  sensitivity_pct = excluded.sensitivity_pct, tight_pct = excluded.tight_pct,
  type_code = excluded.type_code, updated_at = now();
