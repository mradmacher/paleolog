CREATE TABLE choices (
    id INTEGER PRIMARY KEY NOT NULL,
    name TEXT,
    field_id INTEGER,
    FOREIGN KEY (field_id) REFERENCES fields(id)
);

CREATE TABLE comments (
    id INTEGER PRIMARY KEY NOT NULL,
    message TEXT,
    commentable_id INTEGER,
    commentable_type TEXT,
    user_id INTEGER,
    created_at DATETIME,
    updated_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE countings (
    id INTEGER PRIMARY KEY NOT NULL,
    name TEXT,
    group_id INTEGER,
    marker_id INTEGER,
    marker_count INTEGER,
    project_id INTEGER,
    FOREIGN KEY (project_id) REFERENCES projects(id),
    FOREIGN KEY (group_id) REFERENCES groups(id),
    FOREIGN KEY (marker_id) REFERENCES species(id)
);


CREATE TABLE features (
    id INTEGER PRIMARY KEY NOT NULL,
    species_id INTEGER,
    choice_id INTEGER,
    FOREIGN KEY (choice_id) REFERENCES choices(id)
    FOREIGN KEY (species_id) REFERENCES species(id)
);

CREATE TABLE fields (
    id INTEGER PRIMARY KEY NOT NULL,
    name TEXT,
    group_id INTEGER,
    FOREIGN KEY (group_id) REFERENCES groups(id)
);

CREATE TABLE groups (
    id INTEGER PRIMARY KEY NOT NULL,
    name TEXT
);

CREATE TABLE images (
    id INTEGER PRIMARY KEY NOT NULL,
    created_at DATETIME,
    updated_at DATETIME,
    species_id INTEGER,
    image_file_name TEXT,
    image_content_type TEXT,
    image_file_size INTEGER,
    sample_id INTEGER,
    ef TEXT,
    FOREIGN KEY (species_id) REFERENCES species(id)
);

CREATE TABLE occurrences (
    id INTEGER PRIMARY KEY NOT NULL,
    species_id INTEGER,
    quantity INTEGER,
    rank INTEGER,
    status INTEGER,
    uncertain BOOLEAN DEFAULT FALSE,
    sample_id INTEGER,
    counting_id INTEGER,
    FOREIGN KEY (species_id) REFERENCES species(id),
    FOREIGN KEY (sample_id) REFERENCES samples(id),
    FOREIGN KEY (counting_id) REFERENCES countings(id)
);

CREATE UNIQUE INDEX idx_unique_occurrences_on_species_id_sample_id_counting_id ON occurrences(species_id, sample_id, counting_id);

CREATE TABLE projects (
    id INTEGER PRIMARY KEY NOT NULL,
    name TEXT,
    created_at DATETIME,
    updated_at DATETIME
);


CREATE TABLE research_participations (
    id INTEGER PRIMARY KEY NOT NULL,
    user_id INTEGER,
    manager BOOLEAN DEFAULT FALSE,
    created_at DATETIME,
    updated_at DATETIME,
    project_id INTEGER,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (project_id) REFERENCES projects(id)
);

CREATE TABLE samples (
    id INTEGER PRIMARY KEY NOT NULL,
    name TEXT,
    section_id INTEGER,
    created_at DATETIME,
    updated_at DATETIME,
    bottom_depth NUMERIC,
    top_depth NUMERIC,
    description TEXT,
    weight NUMERIC,
    rank INTEGER,
    FOREIGN KEY (section_id) REFERENCES sections(id)
);

CREATE TABLE sections (
    id INTEGER PRIMARY KEY NOT NULL,
    name TEXT,
    created_at DATETIME,
    updated_at DATETIME,
    project_id INTEGER,
    FOREIGN KEY (project_id) REFERENCES projects(id)
);

CREATE TABLE species (
    id INTEGER PRIMARY KEY NOT NULL,
    name TEXT,
    verified BOOLEAN,
    description TEXT,
    environmental_preferences TEXT,
    created_at DATETIME,
    updated_at DATETIME,
    group_id INTEGER,
    FOREIGN KEY (group_id) REFERENCES groups(id)
);


CREATE TABLE users (
    id INTEGER PRIMARY KEY NOT NULL,
    name TEXT,
    email TEXT,
    password TEXT,
    created_at DATETIME,
    updated_at DATETIME,
    login TEXT,
    admin BOOLEAN DEFAULT FALSE,
    password_salt TEXT
);
