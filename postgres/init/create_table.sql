-- auth.users definition

-- Drop table

-- DROP TABLE auth.users;

CREATE SCHEMA auth;

CREATE TABLE auth.users (
	instance_id uuid NULL,
	id uuid NOT NULL,
	aud varchar(255) NULL,
	"role" varchar(255) NULL,
	email varchar(255) NULL,
	encrypted_password varchar(255) NULL,
	email_confirmed_at timestamptz NULL,
	invited_at timestamptz NULL,
	confirmation_token varchar(255) NULL,
	confirmation_sent_at timestamptz NULL,
	recovery_token varchar(255) NULL,
	recovery_sent_at timestamptz NULL,
	email_change_token_new varchar(255) NULL,
	email_change varchar(255) NULL,
	email_change_sent_at timestamptz NULL,
	last_sign_in_at timestamptz NULL,
	raw_app_meta_data jsonb NULL,
	raw_user_meta_data jsonb NULL,
	is_super_admin bool NULL,
	created_at timestamptz NULL,
	updated_at timestamptz NULL,
	phone text DEFAULT NULL::character varying NULL,
	phone_confirmed_at timestamptz NULL,
	phone_change text DEFAULT ''::character varying NULL,
	phone_change_token varchar(255) DEFAULT ''::character varying NULL,
	phone_change_sent_at timestamptz NULL,
	confirmed_at timestamptz GENERATED ALWAYS AS (LEAST(email_confirmed_at, phone_confirmed_at)) STORED NULL,
	email_change_token_current varchar(255) DEFAULT ''::character varying NULL,
	email_change_confirm_status int2 DEFAULT 0 NULL,
	banned_until timestamptz NULL,
	reauthentication_token varchar(255) DEFAULT ''::character varying NULL,
	reauthentication_sent_at timestamptz NULL,
	is_sso_user bool DEFAULT false NOT NULL,
	deleted_at timestamptz NULL,
	is_anonymous bool DEFAULT false NOT NULL,
	CONSTRAINT users_email_change_confirm_status_check CHECK (((email_change_confirm_status >= 0) AND (email_change_confirm_status <= 2))),
	CONSTRAINT users_phone_key UNIQUE (phone),
	CONSTRAINT users_pkey PRIMARY KEY (id)
);
CREATE UNIQUE INDEX confirmation_token_idx ON auth.users USING btree (confirmation_token) WHERE ((confirmation_token)::text !~ '^[0-9 ]*$'::text);
CREATE UNIQUE INDEX email_change_token_current_idx ON auth.users USING btree (email_change_token_current) WHERE ((email_change_token_current)::text !~ '^[0-9 ]*$'::text);
CREATE UNIQUE INDEX email_change_token_new_idx ON auth.users USING btree (email_change_token_new) WHERE ((email_change_token_new)::text !~ '^[0-9 ]*$'::text);
CREATE UNIQUE INDEX reauthentication_token_idx ON auth.users USING btree (reauthentication_token) WHERE ((reauthentication_token)::text !~ '^[0-9 ]*$'::text);
CREATE UNIQUE INDEX recovery_token_idx ON auth.users USING btree (recovery_token) WHERE ((recovery_token)::text !~ '^[0-9 ]*$'::text);
CREATE UNIQUE INDEX users_email_partial_key ON auth.users USING btree (email) WHERE (is_sso_user = false);
COMMENT ON INDEX auth.users_email_partial_key IS 'Auth: A partial unique index that applies only when is_sso_user is false';
CREATE INDEX users_instance_id_email_idx ON auth.users USING btree (instance_id, lower((email)::text));
CREATE INDEX users_instance_id_idx ON auth.users USING btree (instance_id);
CREATE INDEX users_is_anonymous_idx ON auth.users USING btree (is_anonymous);

-- public.user_tokens definition

-- Drop table

-- DROP TABLE public.user_tokens;

CREATE TABLE public.user_tokens (
	"userId" uuid NOT NULL,
	"revokedDate" timestamp NULL,
	id uuid NOT NULL,
	CONSTRAINT user_authentications_unique UNIQUE (id)
);


-- public.user_tokens foreign keys

ALTER TABLE public.user_tokens ADD CONSTRAINT user_authentications_users_fk FOREIGN KEY ("userId") REFERENCES auth.users(id);