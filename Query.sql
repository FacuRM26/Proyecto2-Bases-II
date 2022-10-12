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
        gathering_Responsible_id serial primary key,
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
        specimen_description varchar(10000) not null,
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


create or replace procedure pr_insertar_Especimen(
	pSpecimen_ID int,pTaxon_id int,pGathering_id int ,pGathering int,pSpecimen_description varchar,pSpecimen_cost float)
	LANGUAGE 'plpgsql' as $body$DECLARE
    repetido int;
    BEGIN
    select count(*) into repetido from Specimen where specimen_id=pSpecimen_ID;
    if repetido =0 THEN
    insert into specimen values(pSpecimen_ID,pTaxon_id,pGathering_id,pSpecimen_description,pSpecimen_cost);
    end if;
    END;$body$;

create or replace procedure pr_insertar_Taxon(
    pTaxon_id int,pKingdom_name varchar,pPhylum_division_name varchar,pClass_name varchar,pOrder_name varchar,pFamily_name varchar,pGenus_name varchar,pSpecies_name varchar,pScientific_name varchar)
    LANGUAGE 'plpgsql' as $body$DECLARE
    repetido int;
    BEGIN
    select count(*) into repetido from taxon where taxon_id=pTaxon_id;
    if repetido =0 THEN
    insert into taxon values(pTaxon_id,pKingdom_name,pPhylum_division_name,pClass_name,pOrder_name,pFamily_name,pGenus_name,pSpecies_name,pScientific_name);
    end if;
    END;$body$;


    create or replace procedure pr_insertar_Gathering(
    pGathering_id int,pGathering_date date,pGathering_responsible_id int,pSite_id int)
    LANGUAGE 'plpgsql' as $body$DECLARE
    repetido int;
    BEGIN
    select count(*) into repetido from gathering where gathering_id=pGathering_id;
    if repetido =0 THEN
    insert into gathering values(pGathering_id,pGathering_date,pGathering_responsible_id,pSite_id);
    end if;
    END;$body$;

    
	create or replace procedure pr_normalizar()
    LANGUAGE 'plpgsql' as $body$DECLARE
    inbio CURSOR FOR select * from temp;
	idtemp int;
    random int;
	repetido int;
    BEGIN
    for i in inbio loop
    call pr_insertar_taxon(i.taxon_id,i.kingdom_name,i.phylum_division_name,i.class_name,i.order_name,i.family_name,i.genus_name,i.species_name,i.scientific_name);
    select count(*) into repetido from site where site_id=i.site_id;
    if repetido =0 THEN
	insert into site values(i.site_id,i.latitude,i.longitude,i.site_description);
	end if;
    insert into gathering_responsible(name) values(i.gathering_responsible);
	select gathering_Responsible_id into idtemp from gathering_responsible where name=i.gathering_responsible;
    call pr_insertar_gathering(idtemp,i.gathering_date,idtemp,i.site_id);
    SELECT floor(random() * 10000 + 1) INTO random;
    call pr_insertar_especimen(i.specimen_id,i.taxon_id,idtemp,random,i.specimen_description,random);
    end loop;
    END;$body$;
call pr_normalizar();



delete from temp where gathering_responsible is NULL;