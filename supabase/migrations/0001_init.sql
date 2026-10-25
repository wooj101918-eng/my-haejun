-- 해준이의 성장과정 : 초기 스키마
-- entries(일기) + comments(댓글) + photos(사진 저장소)

-- ========== 1. 일기 테이블 ==========
create table if not exists public.entries (
  id               text primary key,
  date             date not null,
  title            text not null default '',
  body             text not null default '',
  cover_path       text,
  attachment_paths text[] not null default '{}',
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create index if not exists entries_date_idx on public.entries (date desc);

-- ========== 2. 댓글 테이블 ==========
create table if not exists public.comments (
  id         bigint generated always as identity primary key,
  entry_id   text not null references public.entries(id) on delete cascade,
  name       text not null check (char_length(name) between 1 and 40),
  body       text not null check (char_length(body) between 1 and 1000),
  created_at timestamptz not null default now()
);

create index if not exists comments_entry_idx on public.comments (entry_id, created_at);

-- ========== 3. updated_at 자동 갱신 ==========
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists entries_touch on public.entries;
create trigger entries_touch before update on public.entries
  for each row execute function public.touch_updated_at();

-- ========== 4. RLS (행 수준 보안) ==========
alter table public.entries  enable row level security;
alter table public.comments enable row level security;

-- 일기: 누구나 읽기 / 로그인한 사람만 쓰기·수정·삭제
drop policy if exists entries_read      on public.entries;
drop policy if exists entries_write     on public.entries;
drop policy if exists entries_update    on public.entries;
drop policy if exists entries_delete    on public.entries;
create policy entries_read   on public.entries for select using (true);
create policy entries_write  on public.entries for insert to authenticated with check (true);
create policy entries_update on public.entries for update to authenticated using (true) with check (true);
create policy entries_delete on public.entries for delete to authenticated using (true);

-- 댓글: 누구나 읽기·작성(방명록) / 로그인한 사람만 삭제
drop policy if exists comments_read   on public.comments;
drop policy if exists comments_write  on public.comments;
drop policy if exists comments_delete on public.comments;
create policy comments_read   on public.comments for select using (true);
create policy comments_write  on public.comments for insert with check (true);
create policy comments_delete on public.comments for delete to authenticated using (true);
