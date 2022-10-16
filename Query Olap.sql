--Tablas

create table Dim_taxon(
	    taxon_id int primary key,
        kingdoom_name varchar(50),
        phylum_division_name varchar(50),
        class_name varchar(50),
        order_name varchar(50),
        family_name varchar(50),
        genus_name varchar(50),
        species_name varchar(50),
        scientific_name varchar(200)
);
create table Dim_site(
        site_id int primary key,
        latitude float not NULL,
        longitude float not NULL,
        site_description varchar(10000) not NULL
);
create table Dim_gathering(
        gathering_id int primary key,
        año int not null,
        mes int not null,
        dia int not null
);
create table Dim_gathering_responsible(
        gathering_responsible_id int primary key,
        name varchar(50) not NULL
);
create table Fact_Specimen(
        taxon_id int references Dim_taxon(taxon_id),
        gathering_id int REFERENCES Dim_gathering(gathering_id),
        site_id int references Dim_site(site_id),
        gathering_responsible_id int references Dim_gathering_responsible(gathering_responsible_id),
        specimen_count int,
        cost_sum float,
		specimen_id int
    );

--Procedimientos
create or replace procedure pr_insertar_Dim_taxon(
    pTaxon_id int,pKingdom_name varchar,pPhylum_division_name varchar,pClass_name varchar,pOrder_name varchar,pFamily_name varchar,pGenus_name varchar,pSpecies_name varchar,pScientific_name varchar)
    LANGUAGE 'plpgsql' as $body$DECLARE
    repetido int;
    BEGIN
    select count(*) into repetido from Dim_taxon where taxon_id=pTaxon_id;
    if repetido =0 THEN
    insert into Dim_taxon values(pTaxon_id,pKingdom_name,pPhylum_division_name,pClass_name,pOrder_name,pFamily_name,pGenus_name,pSpecies_name,pScientific_name);
    end if;
    END;$body$;

create or REPLACE PROCEDURE pr_insertar_Dim_site(
    pSite_id int,pLatitude float,pLongitude float,pSite_description varchar)
    LANGUAGE 'plpgsql' as $body$DECLARE
    repetido int;
    BEGIN
    select count(*) into repetido from Dim_site where site_id=pSite_id;
    if repetido =0 THEN
    insert into Dim_site values(pSite_id,pLatitude,pLongitude,pSite_description);
    end if;
    END;$body$;

create or REPLACE PROCEDURE pr_insertar_Dim_gathering(
    pGathering_id int,pAño int,pMes int,pDia int)
    LANGUAGE 'plpgsql' as $body$DECLARE
    repetido int;
    BEGIN
    select count(*) into repetido from Dim_gathering where gathering_id=pGathering_id;
    if repetido =0 THEN
    insert into Dim_gathering values(pGathering_id,pAño,pMes,pDia);
    end if;
    END;$body$;

create or REPLACE PROCEDURE pr_insertar_Dim_gathering_responsible(
    pGathering_responsible_id int,pName varchar)
    LANGUAGE 'plpgsql' as $body$DECLARE
    repetido int;
    BEGIN
    select count(*) into repetido from Dim_gathering_responsible where gathering_responsible_id=pGathering_responsible_id;
    if repetido =0 THEN
    insert into Dim_gathering_responsible values(pGathering_responsible_id,pName);
    end if;
    END;$body$;



create or replace procedure pr_insertar_tablaHechos()
    LANGUAGE 'plpgsql' as $body$DECLARE
    inbio CURSOR FOR select s.specimen_id,si.*,t.*,g.*,gr.*,count(s.Specimen_ID) as specimen_count,sum(s.specimen_cost) as cost_sum FROM
site  si, taxon t, gathering g, gathering_responsible gr, specimen s
where t.taxon_id=s.taxon_id 
and g.gathering_id=s.gathering_id 
and gr.gathering_responsible_id=g.gathering_responsible_id
and g.site_id=si.site_id
group by s.specimen_id,si.site_id, t.taxon_id, g.gathering_id, gr.gathering_responsible_id;
año int;
mes int;
dia int;
    BEGIN
	truncate table fact_specimen;
    for i in inbio loop
    call pr_insertar_Dim_taxon(i.taxon_id,i.kingdoom_name,i.phylum_division_name,i.class_name,i.order_name,i.family_name,i.genus_name,i.species_name,i.scientific_name);
    call pr_insertar_Dim_site(i.site_id,i.latitude,i.longitude,i.site_description);
    SELECT EXTRACT(YEAR FROM i.gathering_date) INTO año;
    SELECT EXTRACT(MONTH FROM i.gathering_date) INTO mes;
    SELECT EXTRACT(DAY FROM i.gathering_date) INTO dia;
    call pr_insertar_Dim_gathering(i.gathering_id,año,mes,dia);
    call pr_insertar_Dim_gathering_responsible(i.gathering_responsible_id,i.name);
	
    insert into Fact_Specimen values(i.taxon_id,i.gathering_id,i.site_id,i.gathering_responsible_id,i.specimen_count,i.cost_sum,i.specimen_id);
    end loop;
END;$body$;

--Funciones
--1
create or replace function pr_orden(
    pMes int) returns refcursor
    LANGUAGE 'plpgsql' as $body$DECLARE
    cursor1 refcursor;
	bEGIN
    open cursor1 FOR select t.order_name, sum(f.specimen_count) as cantidad from fact_specimen f, dim_taxon t , dim_gathering g where f.taxon_id=t.taxon_id 
    and g.gathering_id=f.gathering_id and g.mes=pMes group by t.order_name order by cantidad desc;
    
	return cursor1;
    END;$body$;

--1.1		
create or replace FUNCTION fn_sum_specimen(conjunto varchar) returns float
    LANGUAGE 'plpgsql' as $body$DECLARE
    temp varchar;
	temp2 varchar;
    suma float;
    total float :=0;
    BEGIN
	temp:=conjunto;
    while POSITION( ',' in temp )>0 loop
    temp2:=substring(conjunto,1,POSITION(  ',' in conjunto )-1);
    select sum(cost_sum) into suma from fact_specimen where specimen_id=CAST(trim(temp2) AS int);
    total:=total+suma;
	
    temp:= trim(substr(temp,POSITION(',' in temp)+1));
	RAISE NOTICE 'total:%',temp;
    end loop;
	
    select sum(cost_sum) into suma from fact_specimen where specimen_id=CAST(trim(temp) AS int);
    total:=total+suma;	
    return total;
 END;$body$;

--1.2
create or replace FUNCTION fn_count_specimen(preino varchar)returns INT
LANGUAGE 'plpgsql' as $body$DECLARE
cantidad int;
BEGIN
select sum(specimen_count) into cantidad from fact_specimen f, dim_taxon t where f.taxon_id=t.taxon_id and t.kingdoom_name=preino;
return cantidad;
END;$body$;


--Pruebas y llamadas a procedimientos y funciones
call pr_insertar_tablaHechos();

-- 2
select g.año,g.mes, sum(f.specimen_count) as cantidad, sum(f.cost_sum) as costo from fact_specimen f, 
		dim_gathering g where f.gathering_id=g.gathering_id group by rollup(año,mes);

-- 3
select g.año,t.kingdoom_name, sum(f.specimen_count) as cantidad, sum(f.cost_sum) as costo 
		from fact_specimen f, dim_gathering g, dim_taxon t where f.gathering_id=g.gathering_id 
		and f.taxon_id=t.taxon_id group by cube(año,kingdoom_name);

DO $$
DECLARE 
total float;
BEGIN
  total :=  fn_sum_specimen('1111576,1463555,1508341,1508350');
	raise notice '%', total;
END $$;
		
		
DO $$
DECLARE 
total int;
BEGIN
  total :=  fn_count_specimen('Plantae');
	raise notice '%', total;
END $$;		



DO $$
DECLARE taxones refcursor;
rec record;
BEGIN
  taxones :=  pr_orden(1);
	loop
	fetch taxones into  rec;
	
	exit when not found;
	

	raise notice '%,%', rec.order_name,rec.cantidad;

	end loop;
	
END $$;


