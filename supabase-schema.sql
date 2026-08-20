-- Dima12: run this once in Supabase > SQL Editor > New query > Run
-- Replace YOUR-ADMIN-EMAIL@example.com on the final line with your email.

create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  price numeric(12,2) not null check (price > 0),
  category text not null default 'منتجات Dima12',
  description text not null default '',
  image_url text,
  colors jsonb not null default '[]'::jsonb,
  featured boolean not null default true,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  customer_name text not null,
  customer_phone text not null,
  customer_city text not null,
  customer_address text not null,
  total numeric(12,2) not null check (total >= 0),
  status text not null default 'جديد' check (status in ('جديد','تم التأكيد','قيد التوصيل','تم التسليم','ملغى')),
  created_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  unit_price numeric(12,2) not null,
  quantity integer not null check (quantity > 0),
  selected_color text
);

alter table public.admin_users enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

create policy "anyone can see active products" on public.products for select using (active = true or exists (select 1 from public.admin_users where user_id = auth.uid()));
create policy "admins manage products" on public.products for all using (exists (select 1 from public.admin_users where user_id = auth.uid())) with check (exists (select 1 from public.admin_users where user_id = auth.uid()));
create policy "admins read their role" on public.admin_users for select using (user_id = auth.uid());
create policy "customers create orders" on public.orders for insert with check (true);
create policy "admins read orders" on public.orders for select using (exists (select 1 from public.admin_users where user_id = auth.uid()));
create policy "admins update orders" on public.orders for update using (exists (select 1 from public.admin_users where user_id = auth.uid()));
create policy "customers create order items" on public.order_items for insert with check (true);
create policy "admins read order items" on public.order_items for select using (exists (select 1 from public.admin_users where user_id = auth.uid()));

insert into storage.buckets (id, name, public) values ('product-images', 'product-images', true) on conflict (id) do nothing;
create policy "public product image read" on storage.objects for select using (bucket_id = 'product-images');
create policy "admins upload product images" on storage.objects for insert with check (bucket_id = 'product-images' and exists (select 1 from public.admin_users where user_id = auth.uid()));
create policy "admins change product images" on storage.objects for update using (bucket_id = 'product-images' and exists (select 1 from public.admin_users where user_id = auth.uid()));
create policy "admins remove product images" on storage.objects for delete using (bucket_id = 'product-images' and exists (select 1 from public.admin_users where user_id = auth.uid()));

-- First create your dashboard account through the store login page, then run this line only.
-- insert into public.admin_users (user_id) select id from auth.users where email = 'YOUR-ADMIN-EMAIL@example.com';
