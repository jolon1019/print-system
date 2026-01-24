create table public.team_notes (
  id text not null,
  a_team text null default ''::text,
  b_team text null default ''::text,
  c_team text null default ''::text,
  outbound_orders jsonb null default '[]'::jsonb,
  outbound_batches jsonb null default '[]'::jsonb,
  coil_inventory jsonb null default '[]'::jsonb,
  updated_at timestamp with time zone null default now(),
  constraint team_notes_pkey primary key (id)
) TABLESPACE pg_default;

create index IF not exists idx_team_notes_outbound_orders on public.team_notes using gin (outbound_orders) TABLESPACE pg_default;

create index IF not exists idx_team_notes_outbound_batches on public.team_notes using gin (outbound_batches) TABLESPACE pg_default;

create index IF not exists idx_team_notes_coil_inventory on public.team_notes using gin (coil_inventory) TABLESPACE pg_default;

create trigger update_team_notes_updated_at BEFORE
update on team_notes for EACH row
execute FUNCTION update_updated_at_column ();



create table public.outbound (
  outbound_order_id bigserial not null,
  inventory_id bigint not null,
  batch_no character varying(50) not null,
  material character varying(50) not null,
  specification character varying(100) not null,
  stock_weight numeric(15, 3) not null,
  out_weight numeric(15, 3) not null,
  unit_price numeric(10, 2) not null,
  total_amount numeric(12, 2) not null,
  out_type smallint null default 1,
  out_date date not null,
  vehicle_no character varying(60) null,
  remark text null,
  created_at timestamp without time zone null default CURRENT_TIMESTAMP,
  ref_no text null,
  updated_at timestamp with time zone null default now(),
  constraint outbound_pkey primary key (outbound_order_id),
  constraint fk_outbound_inventory foreign KEY (inventory_id) references inventory (id) on update CASCADE on delete RESTRICT
) TABLESPACE pg_default;

create index IF not exists idx_outbound_inventory_id on public.outbound using btree (inventory_id) TABLESPACE pg_default;

create index IF not exists idx_outbound_batch_no on public.outbound using btree (batch_no) TABLESPACE pg_default;

create index IF not exists idx_outbound_out_date on public.outbound using btree (out_date) TABLESPACE pg_default;

create index IF not exists idx_outbound_out_type on public.outbound using btree (out_type) TABLESPACE pg_default;

create index IF not exists idx_outbound_material on public.outbound using btree (material) TABLESPACE pg_default;

create index IF not exists idx_outbound_ref_no on public.outbound using btree (ref_no) TABLESPACE pg_default;

create trigger after_outbound_insert
after INSERT on outbound for EACH row
execute FUNCTION update_inventory_status ();



create table public.inventory (
  id bigserial not null,
  batch_no character varying(50) not null,
  unit character varying(20) not null,
  specification character varying(100) not null,
  material character varying(50) not null,
  weight numeric(15, 3) not null,
  vehicle_no character varying(20) null,
  transport_fee numeric(10, 2) null default 0.00,
  advance_payment numeric(10, 2) null default 0.00,
  storage_location character varying(100) not null,
  in_date date not null,
  status smallint null default 1,
  remark text null,
  created_at timestamp without time zone null default CURRENT_TIMESTAMP,
  updated_at timestamp without time zone null default CURRENT_TIMESTAMP,
  constraint inventory_pkey primary key (id),
  constraint inventory_batch_no_key unique (batch_no)
) TABLESPACE pg_default;

create index IF not exists idx_inventory_batch_no on public.inventory using btree (batch_no) TABLESPACE pg_default;

create index IF not exists idx_inventory_material on public.inventory using btree (material) TABLESPACE pg_default;

create index IF not exists idx_inventory_specification on public.inventory using btree (specification) TABLESPACE pg_default;

create index IF not exists idx_inventory_in_date on public.inventory using btree (in_date) TABLESPACE pg_default;

create index IF not exists idx_inventory_status on public.inventory using btree (status) TABLESPACE pg_default;

create index IF not exists idx_inventory_storage_location on public.inventory using btree (storage_location) TABLESPACE pg_default;



create table public.finance_ledger (
  ledger_id serial not null,
  ref_no character varying(50) not null,
  transaction_date date not null,
  transaction_time timestamp without time zone null default CURRENT_TIMESTAMP,
  transaction_type character varying(20) not null,
  transaction_category character varying(50) null,
  description text null,
  unit character varying(10) null default '元'::character varying,
  amount numeric(15, 2) not null,
  tax_amount numeric(15, 2) null default 0,
  total_amount numeric(15, 2) not null,
  outbound_order_id integer null,
  customer_supplier character varying(100) null,
  batch_no character varying(50) null,
  quantity numeric(10, 3) null,
  unit_price numeric(10, 2) null,
  debit_account character varying(50) null,
  credit_account character varying(50) null,
  payment_method character varying(20) null,
  bank_account character varying(50) null,
  status character varying(20) null default 'pending'::character varying,
  is_reconciled boolean null default false,
  created_by character varying(50) null,
  approved_by character varying(50) null,
  approved_at timestamp without time zone null,
  created_at timestamp without time zone null default CURRENT_TIMESTAMP,
  updated_at timestamp without time zone null default CURRENT_TIMESTAMP,
  modification_reason text null,
  sync_source character varying(50) null default 'manual'::character varying,
  sync_status character varying(20) null default 'pending'::character varying,
  sync_attempts integer null default 0,
  last_sync_time timestamp without time zone null,
  is_deleted boolean null default false,
  constraint finance_ledger_pkey primary key (ledger_id),
  constraint finance_ledger_ref_no_key unique (ref_no),
  constraint finance_ledger_outbound_order_id_fkey foreign KEY (outbound_order_id) references outbound (outbound_order_id)
) TABLESPACE pg_default;

create index IF not exists idx_finance_ledger_sync_source on public.finance_ledger using btree (sync_source) TABLESPACE pg_default;



create table public.daily_accounting (
  daily_id serial not null,
  accounting_date date not null,
  summary character varying(200) null,
  description text null,
  total_income numeric(15, 2) null default 0,
  total_expense numeric(15, 2) null default 0,
  total_transactions integer null default 0,
  is_closed boolean null default false,
  closed_by character varying(50) null,
  closed_at timestamp without time zone null,
  reviewed_by character varying(50) null,
  reviewed_at timestamp without time zone null,
  created_at timestamp without time zone null default CURRENT_TIMESTAMP,
  updated_at timestamp without time zone null default CURRENT_TIMESTAMP,
  constraint daily_accounting_pkey primary key (daily_id),
  constraint daily_accounting_accounting_date_key unique (accounting_date)
) TABLESPACE pg_default;