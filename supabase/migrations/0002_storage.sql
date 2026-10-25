-- 사진 저장소(Storage) 설정
-- 버킷 이름: photos  (일기 표지 + 첨부 사진)

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'photos',
  'photos',
  true,                                  -- 링크를 아는 사람은 사진 열람 가능
  10485760,                              -- 장당 최대 10MB
  array['image/jpeg','image/png','image/webp','image/gif']
)
on conflict (id) do update
  set public             = excluded.public,
      file_size_limit    = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- 사진 접근 정책: 누구나 보기 / 로그인한 사람만 올리기·수정·삭제
drop policy if exists photos_read   on storage.objects;
drop policy if exists photos_insert on storage.objects;
drop policy if exists photos_update on storage.objects;
drop policy if exists photos_delete on storage.objects;

create policy photos_read on storage.objects
  for select using (bucket_id = 'photos');

create policy photos_insert on storage.objects
  for insert to authenticated with check (bucket_id = 'photos');

create policy photos_update on storage.objects
  for update to authenticated using (bucket_id = 'photos') with check (bucket_id = 'photos');

create policy photos_delete on storage.objects
  for delete to authenticated using (bucket_id = 'photos');
