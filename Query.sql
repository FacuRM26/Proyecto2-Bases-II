-- Database: Proyecto

-- DROP DATABASE IF EXISTS "Proyecto";

CREATE DATABASE "Proyecto"
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Spanish_Spain.1252'
    LC_CTYPE = 'Spanish_Spain.1252'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;
	
	create table taxon(
        taxon_id int primary key,
        kingdoom_name varchar(50),
        phylum_division_name varchar(50),
        class_name varchar(50),
        order_name varchar(50),
        family_name varchar(50),
        genus_name varchar(50),
        species_name varchar(50),
        scientific_name varchar(50)

    );
    create table gathering_Responsible(
        gathering_Responsible_id int primary key,
        name varchar(50) not NULL
    );
    create table site(
        site_id int primary key,
        latitude float not NULL,
        longitude float not NULL,
        site_description varchar(50) not NULL
    );
    create table gathering(
        gathering_id int primary key,
        gathering_date date not null,
        gathering_Responsible_id int references gathering_Responsible(gathering_Responsible_id),
        site_id int references site(site_id)
    );
	create table Specimen(
        Specimen_ID int primary key,
        taxon_id int,
        gathering_id int REFERENCES gathering(gathering_id),
        specimen_description varchar(50) not null,
        specimen_cost float not null 
    );

create table temp(
    specimen_id int,
    taxon_id int,
    gathering_date date,
    kingdom_name varchar(50),
    phylum_division_name varchar(50),
    class_name varchar(50),
    order_name varchar(50),
    family_name varchar(50),
    genus_name varchar(50),
    species_name varchar(50),
    scientific_name varchar(200),
    gathering_responsible varchar(50),
    site_id int,
    latitude float,
    longitude float,
    site_description varchar(10000),
    specimen_description varchar(10000),
    specimen_cost float
);

--recibir datos de la tabla specimen de un csv


