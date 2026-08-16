-- schema.sql을 이미 실행한 프로젝트에 "재학 캠퍼스" 설문 문항 컬럼만 추가하는 증분 마이그레이션.
-- SQL Editor에서 이 파일 전체를 한 번만 실행하세요.

alter table public.lifestyle_profiles add column if not exists campus text;
