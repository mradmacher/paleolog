--
-- PostgreSQL database dump
--

-- Dumped from database version 14.8 (Debian 14.8-1.pgdg120+1)
-- Dumped by pg_dump version 15.3 (Debian 15.3-1.pgdg120+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: paleolog
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO paleolog;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: choices; Type: TABLE; Schema: public; Owner: paleolog
--

CREATE TABLE public.choices (
    id bigint NOT NULL,
    name text,
    field_id bigint
);


ALTER TABLE public.choices OWNER TO paleolog;

--
-- Name: choices_id_seq; Type: SEQUENCE; Schema: public; Owner: paleolog
--

CREATE SEQUENCE public.choices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.choices_id_seq OWNER TO paleolog;

--
-- Name: choices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: paleolog
--

ALTER SEQUENCE public.choices_id_seq OWNED BY public.choices.id;


--
-- Name: comments; Type: TABLE; Schema: public; Owner: paleolog
--

CREATE TABLE public.comments (
    id bigint NOT NULL,
    message text,
    commentable_id bigint,
    commentable_type text,
    user_id bigint,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE public.comments OWNER TO paleolog;

--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: paleolog
--

CREATE SEQUENCE public.comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.comments_id_seq OWNER TO paleolog;

--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: paleolog
--

ALTER SEQUENCE public.comments_id_seq OWNED BY public.comments.id;


--
-- Name: countings; Type: TABLE; Schema: public; Owner: paleolog
--

CREATE TABLE public.countings (
    id bigint NOT NULL,
    name text,
    group_id bigint,
    marker_id bigint,
    marker_count bigint,
    project_id bigint
);


ALTER TABLE public.countings OWNER TO paleolog;

--
-- Name: countings_id_seq; Type: SEQUENCE; Schema: public; Owner: paleolog
--

CREATE SEQUENCE public.countings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.countings_id_seq OWNER TO paleolog;

--
-- Name: countings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: paleolog
--

ALTER SEQUENCE public.countings_id_seq OWNED BY public.countings.id;


--
-- Name: features; Type: TABLE; Schema: public; Owner: paleolog
--

CREATE TABLE public.features (
    id bigint NOT NULL,
    species_id bigint,
    choice_id bigint
);


ALTER TABLE public.features OWNER TO paleolog;

--
-- Name: features_id_seq; Type: SEQUENCE; Schema: public; Owner: paleolog
--

CREATE SEQUENCE public.features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.features_id_seq OWNER TO paleolog;

--
-- Name: features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: paleolog
--

ALTER SEQUENCE public.features_id_seq OWNED BY public.features.id;


--
-- Name: fields; Type: TABLE; Schema: public; Owner: paleolog
--

CREATE TABLE public.fields (
    id bigint NOT NULL,
    name text,
    group_id bigint
);


ALTER TABLE public.fields OWNER TO paleolog;

--
-- Name: fields_id_seq; Type: SEQUENCE; Schema: public; Owner: paleolog
--

CREATE SEQUENCE public.fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.fields_id_seq OWNER TO paleolog;

--
-- Name: fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: paleolog
--

ALTER SEQUENCE public.fields_id_seq OWNED BY public.fields.id;


--
-- Name: groups; Type: TABLE; Schema: public; Owner: paleolog
--

CREATE TABLE public.groups (
    id bigint NOT NULL,
    name text
);


ALTER TABLE public.groups OWNER TO paleolog;

--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: public; Owner: paleolog
--

CREATE SEQUENCE public.groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.groups_id_seq OWNER TO paleolog;

--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: paleolog
--

ALTER SEQUENCE public.groups_id_seq OWNED BY public.groups.id;


--
-- Name: images; Type: TABLE; Schema: public; Owner: paleolog
--

CREATE TABLE public.images (
    id bigint NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    species_id bigint,
    image_file_name text,
    image_content_type text,
    image_file_size bigint,
    sample_id bigint,
    ef text
);


ALTER TABLE public.images OWNER TO paleolog;

--
-- Name: images_id_seq; Type: SEQUENCE; Schema: public; Owner: paleolog
--

CREATE SEQUENCE public.images_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.images_id_seq OWNER TO paleolog;

--
-- Name: images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: paleolog
--

ALTER SEQUENCE public.images_id_seq OWNED BY public.images.id;


--
-- Name: occurrences; Type: TABLE; Schema: public; Owner: paleolog
--

CREATE TABLE public.occurrences (
    id bigint NOT NULL,
    species_id bigint,
    quantity bigint,
    rank bigint,
    status bigint DEFAULT '0'::bigint,
    uncertain boolean DEFAULT false,
    sample_id bigint,
    counting_id bigint
);


ALTER TABLE public.occurrences OWNER TO paleolog;

--
-- Name: occurrences_id_seq; Type: SEQUENCE; Schema: public; Owner: paleolog
--

CREATE SEQUENCE public.occurrences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.occurrences_id_seq OWNER TO paleolog;

--
-- Name: occurrences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: paleolog
--

ALTER SEQUENCE public.occurrences_id_seq OWNED BY public.occurrences.id;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: paleolog
--

CREATE TABLE public.projects (
    id bigint NOT NULL,
    name text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE public.projects OWNER TO paleolog;

--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: paleolog
--

CREATE SEQUENCE public.projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.projects_id_seq OWNER TO paleolog;

--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: paleolog
--

ALTER SEQUENCE public.projects_id_seq OWNED BY public.projects.id;


--
-- Name: research_participations; Type: TABLE; Schema: public; Owner: paleolog
--

CREATE TABLE public.research_participations (
    id bigint NOT NULL,
    user_id bigint,
    manager boolean DEFAULT false,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    project_id bigint
);


ALTER TABLE public.research_participations OWNER TO paleolog;

--
-- Name: research_participations_id_seq; Type: SEQUENCE; Schema: public; Owner: paleolog
--

CREATE SEQUENCE public.research_participations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.research_participations_id_seq OWNER TO paleolog;

--
-- Name: research_participations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: paleolog
--

ALTER SEQUENCE public.research_participations_id_seq OWNED BY public.research_participations.id;


--
-- Name: samples; Type: TABLE; Schema: public; Owner: paleolog
--

CREATE TABLE public.samples (
    id bigint NOT NULL,
    name text,
    section_id bigint,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    bottom_depth numeric,
    top_depth numeric,
    description text,
    weight numeric,
    rank bigint
);


ALTER TABLE public.samples OWNER TO paleolog;

--
-- Name: samples_id_seq; Type: SEQUENCE; Schema: public; Owner: paleolog
--

CREATE SEQUENCE public.samples_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.samples_id_seq OWNER TO paleolog;

--
-- Name: samples_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: paleolog
--

ALTER SEQUENCE public.samples_id_seq OWNED BY public.samples.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: paleolog
--

CREATE TABLE public.schema_migrations (
    version text
);


ALTER TABLE public.schema_migrations OWNER TO paleolog;

--
-- Name: sections; Type: TABLE; Schema: public; Owner: paleolog
--

CREATE TABLE public.sections (
    id bigint NOT NULL,
    name text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    project_id bigint
);


ALTER TABLE public.sections OWNER TO paleolog;

--
-- Name: sections_id_seq; Type: SEQUENCE; Schema: public; Owner: paleolog
--

CREATE SEQUENCE public.sections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sections_id_seq OWNER TO paleolog;

--
-- Name: sections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: paleolog
--

ALTER SEQUENCE public.sections_id_seq OWNED BY public.sections.id;


--
-- Name: species; Type: TABLE; Schema: public; Owner: paleolog
--

CREATE TABLE public.species (
    id bigint NOT NULL,
    name text,
    verified boolean,
    description text,
    environmental_preferences text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    group_id bigint
);


ALTER TABLE public.species OWNER TO paleolog;

--
-- Name: species_id_seq; Type: SEQUENCE; Schema: public; Owner: paleolog
--

CREATE SEQUENCE public.species_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.species_id_seq OWNER TO paleolog;

--
-- Name: species_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: paleolog
--

ALTER SEQUENCE public.species_id_seq OWNED BY public.species.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: paleolog
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    name text,
    email text,
    password text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    login text,
    admin boolean DEFAULT false,
    password_salt text
);


ALTER TABLE public.users OWNER TO paleolog;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: paleolog
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO paleolog;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: paleolog
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: choices id; Type: DEFAULT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.choices ALTER COLUMN id SET DEFAULT nextval('public.choices_id_seq'::regclass);


--
-- Name: comments id; Type: DEFAULT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.comments ALTER COLUMN id SET DEFAULT nextval('public.comments_id_seq'::regclass);


--
-- Name: countings id; Type: DEFAULT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.countings ALTER COLUMN id SET DEFAULT nextval('public.countings_id_seq'::regclass);


--
-- Name: features id; Type: DEFAULT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.features ALTER COLUMN id SET DEFAULT nextval('public.features_id_seq'::regclass);


--
-- Name: fields id; Type: DEFAULT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.fields ALTER COLUMN id SET DEFAULT nextval('public.fields_id_seq'::regclass);


--
-- Name: groups id; Type: DEFAULT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.groups ALTER COLUMN id SET DEFAULT nextval('public.groups_id_seq'::regclass);


--
-- Name: images id; Type: DEFAULT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.images ALTER COLUMN id SET DEFAULT nextval('public.images_id_seq'::regclass);


--
-- Name: occurrences id; Type: DEFAULT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.occurrences ALTER COLUMN id SET DEFAULT nextval('public.occurrences_id_seq'::regclass);


--
-- Name: projects id; Type: DEFAULT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.projects ALTER COLUMN id SET DEFAULT nextval('public.projects_id_seq'::regclass);


--
-- Name: research_participations id; Type: DEFAULT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.research_participations ALTER COLUMN id SET DEFAULT nextval('public.research_participations_id_seq'::regclass);


--
-- Name: samples id; Type: DEFAULT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.samples ALTER COLUMN id SET DEFAULT nextval('public.samples_id_seq'::regclass);


--
-- Name: sections id; Type: DEFAULT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.sections ALTER COLUMN id SET DEFAULT nextval('public.sections_id_seq'::regclass);


--
-- Name: species id; Type: DEFAULT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.species ALTER COLUMN id SET DEFAULT nextval('public.species_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: comments idx_16391_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT idx_16391_comments_pkey PRIMARY KEY (id);


--
-- Name: users idx_16398_users_pkey; Type: CONSTRAINT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT idx_16398_users_pkey PRIMARY KEY (id);


--
-- Name: groups idx_16406_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT idx_16406_groups_pkey PRIMARY KEY (id);


--
-- Name: images idx_16413_images_pkey; Type: CONSTRAINT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.images
    ADD CONSTRAINT idx_16413_images_pkey PRIMARY KEY (id);


--
-- Name: fields idx_16420_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.fields
    ADD CONSTRAINT idx_16420_fields_pkey PRIMARY KEY (id);


--
-- Name: choices idx_16427_choices_pkey; Type: CONSTRAINT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.choices
    ADD CONSTRAINT idx_16427_choices_pkey PRIMARY KEY (id);


--
-- Name: features idx_16434_features_pkey; Type: CONSTRAINT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.features
    ADD CONSTRAINT idx_16434_features_pkey PRIMARY KEY (id);


--
-- Name: projects idx_16439_projects_pkey; Type: CONSTRAINT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT idx_16439_projects_pkey PRIMARY KEY (id);


--
-- Name: occurrences idx_16446_occurrences_pkey; Type: CONSTRAINT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.occurrences
    ADD CONSTRAINT idx_16446_occurrences_pkey PRIMARY KEY (id);


--
-- Name: samples idx_16453_samples_pkey; Type: CONSTRAINT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.samples
    ADD CONSTRAINT idx_16453_samples_pkey PRIMARY KEY (id);


--
-- Name: countings idx_16460_countings_pkey; Type: CONSTRAINT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.countings
    ADD CONSTRAINT idx_16460_countings_pkey PRIMARY KEY (id);


--
-- Name: research_participations idx_16467_research_participations_pkey; Type: CONSTRAINT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.research_participations
    ADD CONSTRAINT idx_16467_research_participations_pkey PRIMARY KEY (id);


--
-- Name: species idx_16473_species_pkey; Type: CONSTRAINT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.species
    ADD CONSTRAINT idx_16473_species_pkey PRIMARY KEY (id);


--
-- Name: sections idx_16480_sections_pkey; Type: CONSTRAINT; Schema: public; Owner: paleolog
--

ALTER TABLE ONLY public.sections
    ADD CONSTRAINT idx_16480_sections_pkey PRIMARY KEY (id);


--
-- Name: idx_16385_unique_schema_migrations; Type: INDEX; Schema: public; Owner: paleolog
--

CREATE UNIQUE INDEX idx_16385_unique_schema_migrations ON public.schema_migrations USING btree (version);


--
-- Name: idx_16446_unique_occurrences_on_species_id_sample_id_counting_i; Type: INDEX; Schema: public; Owner: paleolog
--

CREATE UNIQUE INDEX idx_16446_unique_occurrences_on_species_id_sample_id_counting_i ON public.occurrences USING btree (species_id, sample_id, counting_id);


--
-- Name: idx_16460_index_countings_on_project_id; Type: INDEX; Schema: public; Owner: paleolog
--

CREATE INDEX idx_16460_index_countings_on_project_id ON public.countings USING btree (project_id);


--
-- Name: idx_16467_index_research_participations_on_project_id; Type: INDEX; Schema: public; Owner: paleolog
--

CREATE INDEX idx_16467_index_research_participations_on_project_id ON public.research_participations USING btree (project_id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: paleolog
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

